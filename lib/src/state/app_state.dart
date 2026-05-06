import 'package:flutter/foundation.dart';

import '../models.dart';
import '../services/mock_classifier_service.dart';
import '../services/recipe_service.dart';
import '../services/sound_service.dart';

class AppState extends ChangeNotifier {
  AppState({
    required MockClassifierService classifierService,
    required RecipeService recipeService,
  })  : _classifierService = classifierService,
        _recipeService = recipeService {
    // Start with empty inventory to show cute mascots!
    // _seedDemoInventory();
  }

  final MockClassifierService _classifierService;
  final RecipeService _recipeService;

  final List<ScrapItem> _inventory = <ScrapItem>[];
  final List<String> _latestBatchLabels = <String>[];
  ScanOutcome? _lastOutcome;

  List<String> get supportedLabels => MockClassifierService.supportedLabels;

  List<ScrapItem> get inventory => List.unmodifiable(_inventory);

  ScanOutcome? get lastOutcome => _lastOutcome;

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

  List<RecipeSuggestion> get recipeSuggestions => _recipeService.suggest(_inventory);

  List<String> get latestBatchLabels => List.unmodifiable(_latestBatchLabels);

  /// Recipes prioritize the latest scanned batch when available.
  List<RecipeSuggestion> get activeRecipeSuggestions {
    if (_latestBatchLabels.isNotEmpty) {
      return _recipeService.suggestForLabels(_latestBatchLabels);
    }
    return recipeSuggestions;
  }

  /// Suggest recipes for an explicit set of labels (useful for previewing a batch before committing).
  List<RecipeSuggestion> suggestForLabels(Iterable<String> labels) {
    return _recipeService.suggestForLabels(labels);
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
    final outcome = _classifierService.classifySample(sampleLabel);
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

  void addManualItem(String label) {
    _lastOutcome = ScanOutcome(
      predictedLabel: label,
      confidence: 1.0,
      recommendedAction: 'Manually added item.',
      requiresReview: false,
      note: 'Added without scan.',
    );
    _logItem(label: label, confidence: 1.0, source: 'manual-entry', manualCorrection: true);

    _latestBatchLabels
      ..clear()
      ..add(label);
    
    // Play success sound
    SoundService.playSuccess();

    notifyListeners();
  }

  void _logItem({
    required String label,
    required double confidence,
    required String source,
    bool manualCorrection = false,
    double? weightGrams,
  }) {
    _inventory.insert(
      0,
      ScrapItem(
        label: label,
        weightGrams: weightGrams,
        loggedAt: DateTime.now(),
        source: source,
        confidence: confidence,
        manualCorrection: manualCorrection,
      ),
    );
  }
}
