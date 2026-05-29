import 'package:flutter/foundation.dart';
import 'dart:async';

import '../models.dart';
import '../services/firebase_auth_service.dart';
import '../services/firebase_recipe_store.dart';
import '../services/firebase_scrap_store.dart';
import '../services/gemini_service.dart';
import '../services/recipe_service.dart';
import '../services/sound_service.dart';
import 'package:flutter/foundation.dart';

class AppState extends ChangeNotifier {
  static const double scanConfidenceThreshold = 0.70;
  AppState({
    required GeminiService classifierService,
    required RecipeService recipeService,
  })  : _classifierService = classifierService,
        _recipeService = recipeService,
        _authService = FirebaseAuthService(),
        _recipeStore = FirebaseRecipeStore(),
        _scrapStore = FirebaseScrapStore() {
    // Initialize the classifier
    debugPrint('[AppState] Constructor called, starting _bootstrap');
    _bootstrap();
    debugPrint('[AppState] _bootstrap completed');
  }

  final GeminiService _classifierService;
  final FirebaseAuthService _authService;
  final FirebaseRecipeStore _recipeStore;
  final FirebaseScrapStore _scrapStore;
  StreamSubscription<List<ScrapItem>>? _scrapSubscription;

  // Public getter to access classifier from screens
  GeminiService get classifierService => _classifierService;
  final RecipeService _recipeService;

  final List<ScrapItem> _inventory = <ScrapItem>[];
  final List<String> _latestBatchLabels = <String>[];
  final List<SavedRecipeRecord> _savedRecipes = <SavedRecipeRecord>[];
  ScanOutcome? _lastOutcome;
  bool _isBootstrapping = true;
  bool _isLoadingRecipes = false;
  bool _authFailed = false;
  
  // Track recent items to prevent duplicates
  final Map<String, DateTime> _recentlyAddedItems = <String, DateTime>{};

  List<String> get supportedLabels => RecipeService.supportedLabels;

  List<ScrapItem> get inventory => List.unmodifiable(_inventory);

  bool get isReady => !_isBootstrapping;

  bool get isSignedIn => _authService.isSignedIn;
  bool get authFailed => _authFailed;

  String? get currentUserEmail => _authService.userEmail;

  bool get isLoadingRecipes => _isLoadingRecipes;

  ScanOutcome? get lastOutcome => _lastOutcome;

  List<SavedRecipeRecord> get savedRecipes => List.unmodifiable(_savedRecipes);

  double get divertedWasteKg {
    return _inventory
        .where((item) => item.weightGrams != null)
        .fold(0.0, (sum, item) => sum + (item.weightGrams ?? 0.0)) /
        1000.0;
  }

  /// Estimated savings (placeholder: assumes avg weight and local vegetable cost)
  /// Real MVP should track actual user input weights or item count only
  double get estimatedSavings {
    final itemCount = _inventory.length;
    // Conservative estimate: ~150g per scrap × ₱8 per kg ≈ ₱1.20 per item
    return itemCount * 1.2;
  }

  /// Simple item count (more realistic for MVP without weight data)
  int get itemsLogged => _inventory.length;

  /// Number of scans in the past 7 days (for user level calculation)
  int get weeklyScanCount {
    final oneWeekAgo = DateTime.now().subtract(const Duration(days: 7));
    final count = _inventory.where((item) =>
      item.loggedAt.isAfter(oneWeekAgo) &&
      item.source == 'auto-scan' // Only count auto-scans for weekly activity
    ).length;
    return count;
  }

  List<RecipeSuggestion> get recipeSuggestions => _recipeService.suggest(_inventory);

  List<String> get latestBatchLabels => List.unmodifiable(_latestBatchLabels);

  bool isRecipeSaved(RecipeSuggestion recipe) {
    return _savedRecipes.any((saved) => saved.recipeId == recipe.stableId);
  }

  /// Recipes use full inventory plus the latest scan for better matches.
  List<RecipeSuggestion> get activeRecipeSuggestions {
    final labels = [
      ..._inventory.map((item) => item.label),
      ..._latestBatchLabels,
    ];
    if (labels.isEmpty) {
      return recipeSuggestions;
    }
    // Use static suggestions for now since suggestForLabels is async
    return _recipeService.suggest(_inventory);
  }

  /// Suggest recipes for an explicit set of labels (useful for previewing a batch before committing).
  Future<List<RecipeSuggestion>> suggestForLabels(Iterable<String> labels) async {
    return await _recipeService.suggestForLabels(labels);
  }

  Future<void> signUp(String email, String password) async {
    final normalizedEmail = email.trim();
    if (normalizedEmail.isEmpty) {
      throw Exception('Email is required.');
    }
    if (password.isEmpty || password.length < 6) {
      throw Exception('Password must be at least 6 characters.');
    }

    try {
      await _authService.signUp(normalizedEmail, password);
      await _reloadSavedRecipes();
      notifyListeners();
    } catch (e) {
      rethrow;
    }
  }

  Future<void> signIn(String email, String password) async {
    final normalizedEmail = email.trim();
    if (normalizedEmail.isEmpty) {
      throw Exception('Email is required.');
    }
    if (password.isEmpty) {
      throw Exception('Password is required.');
    }

    try {
      await _authService.signIn(normalizedEmail, password);
      await _reloadSavedRecipes();
      notifyListeners();
    } catch (e) {
      rethrow;
    }
  }

  Future<void> signOut() async {
    _savedRecipes.clear();
    _inventory.clear();
    // Cancel scrap listener on sign out
    _scrapSubscription?.cancel();
    _scrapSubscription = null;
    await _authService.signOut();
    notifyListeners();
  }

  Future<void> toggleSavedRecipe(RecipeSuggestion recipe, {String? notes}) async {
    if (!isSignedIn || currentUserEmail == null) {
      throw Exception('Sign in first to save recipes.');
    }

    final existingIndex = _savedRecipes.indexWhere((saved) => saved.recipeId == recipe.stableId);
    if (existingIndex >= 0) {
      _savedRecipes.removeAt(existingIndex);
      await _recipeStore.deleteRecipe(currentUserEmail!, recipe.stableId);
    } else {
      final record = SavedRecipeRecord(
        recipeId: recipe.stableId,
        title: recipe.title,
        summary: recipe.summary,
        ingredients: recipe.ingredients,
        matchReason: recipe.matchReason,
        savedAt: DateTime.now(),
        chefNote: recipe.chefNote,
        userNotes: notes,
      );
      _savedRecipes.insert(0, record);
      await _recipeStore.upsertRecipe(currentUserEmail!, record);
    }

    notifyListeners();
  }

  Future<void> updateSavedRecipeNotes(String recipeId, String notes) async {
    if (!isSignedIn || currentUserEmail == null) {
      throw Exception('Sign in first to save recipes.');
    }

    final index = _savedRecipes.indexWhere((saved) => saved.recipeId == recipeId);
    if (index < 0) {
      return;
    }

    final updated = _savedRecipes[index].copyWith(userNotes: notes);
    _savedRecipes[index] = updated;
    await _recipeStore.updateRecipeNotes(currentUserEmail!, recipeId, notes);
    notifyListeners();
  }

  Future<void> removeSavedRecipe(String recipeId) async {
    if (!isSignedIn || currentUserEmail == null) {
      throw Exception('Sign in first to save recipes.');
    }

    _savedRecipes.removeWhere((saved) => saved.recipeId == recipeId);
    await _recipeStore.deleteRecipe(currentUserEmail!, recipeId);
    notifyListeners();
  }

  /// Add multiple items at once (batch scan). Each label will be logged with full confidence.
  void addBatchItems(List<String> labels, {String source = 'batch-scan'}) {
    if (labels.isEmpty) {
      return;
    }

    for (final label in labels) {
      _logItem(
        label: label,
        confidence: 1.0,
        source: source,
      );
    }

    _latestBatchLabels
      ..clear()
      ..addAll(labels);

    _lastOutcome = ScanOutcome(
      predictedLabel: labels.first,
      confidence: 1.0,
      recommendedAction: 'Batch saved: ${labels.length} scraps added to Scrap Bin.',
      requiresReview: false,
      note: 'Latest batch: ${labels.join(', ')}',
    );

    notifyListeners();
  }

  void simulateScan(String sampleLabel) {
    // Create a mock outcome for testing since we removed classifySample
    final outcome = ScanOutcome(
      predictedLabel: sampleLabel,
      confidence: 0.95,
      recommendedAction: 'Test classification completed',
      requiresReview: false,
      note: 'Mock result for testing',
    );
    _lastOutcome = outcome;

    if (!outcome.requiresReview) {
      _logItem(
        label: outcome.predictedLabel,
        confidence: outcome.confidence,
        source: 'auto-scan',
      );

      _latestBatchLabels
        ..clear()
        ..add(outcome.predictedLabel);
      
      // Play success sound
      SoundService.playSuccess();
    }

    notifyListeners();
  }

  void confirmManualClassification(String label, {required double confidence}) {
    _lastOutcome = ScanOutcome(
      predictedLabel: label,
      confidence: confidence,
      recommendedAction: 'Manually confirmed and logged to Scrap Bin.',
      requiresReview: false,
      note: 'User corrected the scan result.',
    );
    _logItem(
      label: label,
      confidence: confidence,
      source: 'manual-verification',
      manualCorrection: true,
    );

    _latestBatchLabels
      ..clear()
      ..add(label);
    
    // Play success sound
    SoundService.playSuccess();

    notifyListeners();
  }

  void handleAutoClassification(String label, {required double confidence}) {
    final normalized = label.toLowerCase().trim();
    final isFoodWaste = normalized != 'not_food_waste' && normalized != 'unknown';
    final isConfident = confidence >= scanConfidenceThreshold;

    if (isFoodWaste && isConfident) {
      _lastOutcome = ScanOutcome(
        predictedLabel: label,
        confidence: confidence,
        recommendedAction: 'Food scrap detected and logged automatically.',
        requiresReview: false,
        note: 'Auto scan: ${(confidence * 100).toStringAsFixed(1)}% confidence.',
      );
      _logItem(
        label: label,
        confidence: confidence,
        source: 'auto-scan',
      );

      _latestBatchLabels
        ..clear()
        ..add(label);

      SoundService.playSuccess();
    } else {
      _lastOutcome = ScanOutcome(
        predictedLabel: label,
        confidence: confidence,
        recommendedAction: isConfident
            ? 'No food scraps detected.'
            : 'Low confidence. Try another photo.',
        requiresReview: false,
        note: 'Auto scan skipped logging.',
      );
    }

    notifyListeners();
  }

  void clearBin() {
    _inventory.clear();
    _latestBatchLabels.clear();
    
    // Clear from Firebase if user is signed in
    if (_authService.isSignedIn && _authService.userId != null) {
      _scrapStore.clearAllScraps(_authService.userId!).catchError((e) {
        print('Failed to clear scraps from Firebase: $e');
      });
    }
    // Cancel listener as bin is cleared
    _scrapSubscription?.cancel();
    _scrapSubscription = null;
    
    notifyListeners();
  }

  Future<void> _bootstrap() async {
    try {
      // No explicit initialize for GeminiService, as it's initialized in constructor
      // Listen to auth state changes with a timeout
      final Completer<void> authCompleter = Completer<void>();
      _authService.authStateChanges.listen((user) {
        // Complete the completer only once on first auth state change
        if (!authCompleter.isCompleted) {
          authCompleter.complete();
        }
        if (user != null) {
          // Load data asynchronously without blocking app startup
          _reloadSavedRecipes();
          // Set up real-time listener for scraps
          _setupScrapListener(user.uid);
        } else {
          // User signed out - clear listener and data
          _scrapSubscription?.cancel();
          _scrapSubscription = null;
          _inventory.clear();
          _savedRecipes.clear();
          notifyListeners();
        }
      });
      
      // Timeout after 5 seconds if auth state never fires
      Future.delayed(const Duration(seconds: 5), () {
        if (!authCompleter.isCompleted) {
          print("Warning: Auth state change listener timed out after 5s - proceeding without auth.");
          _authFailed = true;
          authCompleter.complete();
        }
      });
      
      // Wait for auth to complete (either by firing or by timeout)
      await authCompleter.future;

      // Don't wait for Firebase data loading - let it happen in background
      // The app should become ready immediately
      if (_authService.isSignedIn) {
        // Start loading data asynchronously without blocking
        _reloadSavedRecipes();
        // Real-time listener will handle initial load
        _setupScrapListener(_authService.userId!);
      }

      // No isLoaded check for GeminiService
      print("GeminiService initialized successfully.");
    } catch (e) {
      print("Failed to initialize app: $e");
    } finally {
      _isBootstrapping = false;
      notifyListeners();
    }
  
  }

  /// Clears all locally saved recipes and scrap inventory without affecting authentication state.
  Future<void> clearLocalData() async {
    _savedRecipes.clear();
    _inventory.clear();
    notifyListeners();
  }

  Future<void> _reloadSavedRecipes() async {
    if (!_authService.isSignedIn || _authService.userId == null) {
      _savedRecipes.clear();
      return;
    }

    try {
      _isLoadingRecipes = true;
      notifyListeners();

      _savedRecipes.clear();
      
      // Add timeout to prevent indefinite waiting
      final recipes = await _recipeStore.loadRecipes(_authService.userId!)
          .timeout(const Duration(seconds: 10), onTimeout: () {
        print('[_reloadSavedRecipes] Timeout loading recipes from Firebase');
        return <SavedRecipeRecord>[]; // Return empty list on timeout
      });
      
      _savedRecipes.addAll(recipes);
    } catch (e) {
      print('Failed to load saved recipes: $e');
    } finally {
      _isLoadingRecipes = false;
      notifyListeners();
    }
  }

  // Real-time scrap listener setup
  void _setupScrapListener(String userId) {
    // Cancel any existing subscription
    _scrapSubscription?.cancel();
    _scrapSubscription = _scrapStore.watchScraps(userId).listen((scraps) {
      // Update inventory based on remote data. If the snapshot is empty, clear the local inventory.
      if (scraps.isNotEmpty) {
        _inventory
          ..clear()
          ..addAll(scraps);
      } else {
        // Clear local inventory when no scraps are present in Firestore.
        _inventory.clear();
      }
      notifyListeners();
    }, onError: (e) {
      print('Error watching scraps: $e');
    });
  }

  Future<void> _reloadScraps() async {
    if (!_authService.isSignedIn || _authService.userId == null) {
      _inventory.clear();
      return;
    }

    try {
      print('[_reloadScraps] Loading scraps from Firebase...');
      _inventory.clear();
      
      // Add timeout to prevent indefinite waiting
      final scraps = await _scrapStore.loadScraps(_authService.userId!)
          .timeout(const Duration(seconds: 10), onTimeout: () {
        print('[_reloadScraps] Timeout loading scraps from Firebase');
        return <ScrapItem>[]; // Return empty list on timeout
      });
      
      print('[_reloadScraps] Loaded ${scraps.length} scraps from Firebase');
      _inventory.addAll(scraps);
      notifyListeners();
    } catch (e) {
      print('Failed to load scraps: $e');
    }
  }

  void _logItem({
    required String label,
    required double confidence,
    required String source,
    bool manualCorrection = false,
    double? weightGrams,
  }) {
    final normalizedLabel = label.toLowerCase().trim();
    final now = DateTime.now();
    
    // Check if this item was recently added (within 5 seconds)
    if (_recentlyAddedItems.containsKey(normalizedLabel)) {
      final lastAdded = _recentlyAddedItems[normalizedLabel]!;
      final timeSinceLastAdd = now.difference(lastAdded);
      if (timeSinceLastAdd.inSeconds < 5) {
        print('[_logItem] Skipping duplicate item: label="$label" was added ${timeSinceLastAdd.inSeconds} seconds ago');
        return;
      }
    }
    
    // Added logging for debugging UI layout issues
    debugPrint('[_logItem] Adding item: label="$label", source="$source", confidence=$confidence, manualCorrection=$manualCorrection');
    
    final scrap = ScrapItem(
      label: label,
      weightGrams: weightGrams,
      loggedAt: now,
      source: source,
      confidence: confidence,
      manualCorrection: manualCorrection,
    );
    _inventory.insert(0, scrap);
    
    // Track this item as recently added
    _recentlyAddedItems[normalizedLabel] = now;
    
    // Clean up old entries (older than 10 seconds)
    _recentlyAddedItems.removeWhere((key, value) => now.difference(value).inSeconds > 10);

    // Save to Firebase if user is signed in
    if (_authService.isSignedIn && _authService.userId != null) {
      _scrapStore.saveScrap(_authService.userId!, scrap).catchError((e) {
        print('Failed to save scrap to Firebase: $e');
      });
    }
  }
}
