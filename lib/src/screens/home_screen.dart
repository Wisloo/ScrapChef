import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models.dart';
import '../state/app_state.dart';
import '../services/sound_service.dart';
import '../services/recipe_service.dart';
import 'scan_screen.dart';
import 'settings_screen.dart';
import 'recipe_list_screen.dart';
import 'bin_screen.dart';
import 'saved_recipes_screen.dart';
import '../widgets/animated_button.dart' as animated;
import '../widgets/app_card.dart';
import '../widgets/app_button.dart';
import '../constants/ui_constants.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({
    super.key,
    required this.appState,
  });

  final AppState appState;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _heroAnimationController;
  late Animation<double> _heroAnimation;
  final RecipeService _recipeService = RecipeService();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    widget.appState.addListener(_onAppStateChanged);

    _heroAnimationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _heroAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _heroAnimationController, curve: Curves.easeOut),
    );
    _heroAnimationController.forward();
  }

  @override
  void dispose() {
    widget.appState.removeListener(_onAppStateChanged);
    _heroAnimationController.dispose();
    super.dispose();
  }

  void _onAppStateChanged() {
    if (mounted) {
      setState(() {});
    }
  }

  void _onBatchSelect(List<String> selectedLabels) {
    _openRecipes(selectedLabels);
  }

  Future<void> _openScanFlow() async {
    final outcome = await Navigator.of(context).push<ScanOutcome>(
      MaterialPageRoute(
        builder: (_) => ScanScreen(appState: widget.appState),
      ),
    );

    if (!mounted || outcome == null) {
      return;
    }

    // Manual verification removed; proceed as saved.

    final label = outcome.predictedLabel;
    
    // Check if item was actually added to inventory
    final wasAdded = widget.appState.inventory.any((item) => item.label == label);
    
    if (wasAdded) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Logged $label — tap Find Recipes for ideas.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to log $label. Please try again.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  void _openSettings() {
    // SoundService.playClick(); // Haptic feedback removed
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => SettingsScreen(
          appState: widget.appState,
        ),
      ),
    );
  }

  void _openSavedRecipes() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => SavedRecipesScreen(
          appState: widget.appState,
        ),
      ),
    );
  }

  Future<void> _openRecipes(List<String> labels) async {
    setState(() {
      _isLoading = true;
    });
    SoundService.playClick();

    // Use RAG API to find recipes based on natural language query
    final query = 'Recipes using ${labels.join(', ')}';
    final recipes = await _recipeService.findRecipes(query, userIngredients: labels);

    setState(() {
      _isLoading = false;
    });

    // Navigate to recipe list with RAG results
    if (mounted) {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => RecipeListScreen(
            appState: widget.appState,
            labels: labels,
            ragRecipes: recipes,
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final outcome = widget.appState.lastOutcome;
    final inventory = widget.appState.inventory;
    final itemsLogged = widget.appState.itemsLogged;
    final estimatedSavings = widget.appState.estimatedSavings;

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        body: Stack(
          children: [
            Column(
              children: [
            // Fixed top section with logo and title (reduced height)
            Container(
              height: 100,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Theme.of(context).colorScheme.primary.withOpacity(0.85),
                    Theme.of(context).colorScheme.primary.withOpacity(0.7),
                    Theme.of(context).colorScheme.secondary.withOpacity(0.5),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: SafeArea(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.white.withAlpha(25),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Image.asset(
                          'lib/image/ScrapChefLogo.jpg',
                          width: 36,
                          height: 36,
                          fit: BoxFit.contain,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            'ScrapChef',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 24,
                              fontWeight: FontWeight.w800,
                              letterSpacing: -0.5,
                              height: 1.0,
                            ),
                          ),
                          Text(
                            'Turn scraps into suppers',
                            style: TextStyle(
                              color: Colors.white.withAlpha(180),
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                              letterSpacing: 0.2,
                            ),
                          ),
                        ],
                      ),
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.white.withAlpha(25),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: Colors.white.withAlpha(40), width: 1),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.eco_outlined, size: 14, color: Colors.white),
                            const SizedBox(width: 4),
                            Text(
                              'Eco-friendly',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            // Hero header (fixed, reduced padding)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: FadeTransition(
                opacity: _heroAnimation,
                child: Column(
                  children: [
                    _HeroHeader(
                      itemsLogged: itemsLogged,
                      estimatedSavings: estimatedSavings,
                      onSettingsTap: _openSettings,
                      onSavedRecipesTap: _openSavedRecipes,
                      appState: widget.appState,
                    ),
                    const SizedBox(height: 12),
                    _WeightDisplay(currentWeight: widget.appState.currentWeight),
                  ],
                ),
              ),
            ),
            // Non-scrollable content
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(UIConstants.kVerticalGap),
                child: Column(
                  children: <Widget>[
                    _ImpactLedger(itemsLogged: itemsLogged),
                    const SizedBox(height: 20),
                    Divider(
                      color: Theme.of(context).colorScheme.onSurface.withOpacity(0.1),
                      thickness: 1,
                      indent: 0,
                      endIndent: 0,
                    ),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ),
            // Fixed action panel at bottom - continuous without rounded borders
            Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: UIConstants.kHorizontalPadding,
                  vertical: UIConstants.kVerticalGap),
              child: _ActionPanel(onScan: _openScanFlow),
            ),
          ],
        ),
        // Loading overlay
        if (_isLoading)
          Container(
            color: Colors.black.withAlpha(128),
            child: const Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                  SizedBox(height: 16),
                  Text(
                    'Finding recipes...',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    ),
  ),
);
  }
}

class _HeroHeader extends StatelessWidget {
  const _HeroHeader({
    required this.itemsLogged,
    required this.estimatedSavings,
    required this.onSettingsTap,
    required this.onSavedRecipesTap,
    required this.appState,
  });

  final int itemsLogged;
  final double estimatedSavings;
  final VoidCallback onSettingsTap;
  final VoidCallback onSavedRecipesTap;
  final AppState appState;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.all(24),
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Theme.of(context).colorScheme.primary.withAlpha(10),
              Theme.of(context).colorScheme.secondary.withAlpha(5),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: <Widget>[
                Expanded(
                  child: Text(
                    'Your kitchen companion',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Theme.of(context).colorScheme
                              .onSurface
                              .withAlpha(180),
                          fontStyle: FontStyle.normal,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          letterSpacing: -0.1,
                          height: 1.2,
                        ),
                    maxLines: 2,
                    overflow: TextOverflow.visible,
                  ),
                ),
                Row(
                  children: [
                    animated.AnimatedIconButton(
                      onPressed: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => BinScreen(appState: appState),
                          ),
                        );
                      },
                      icon: Icons.inventory_2_outlined,
                      backgroundColor: Theme.of(context).colorScheme.primary,
                      iconColor: Theme.of(context).colorScheme.onPrimary,
                      size: 56,
                    ),
                    const SizedBox(width: 8),
                    animated.AnimatedIconButton(
                      onPressed: onSavedRecipesTap,
                      icon: Icons.bookmark_border_rounded,
                      backgroundColor: Theme.of(context).cardColor,
                      iconColor: Theme.of(context).colorScheme.onSurface,
                      size: 48,
                    ),
                    const SizedBox(width: 8),
                    animated.AnimatedIconButton(
                      onPressed: onSettingsTap,
                      icon: Icons.settings_outlined,
                      backgroundColor: Theme.of(context).cardColor,
                      iconColor: Theme.of(context).colorScheme.onSurface,
                      size: 48,
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 20),
            Divider(
              color: Theme.of(context).colorScheme.onSurface.withAlpha(8),
              thickness: 1,
              indent: 0,
              endIndent: 0,
            ),
            const SizedBox(height: 16),
            Row(
              children: <Widget>[
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              Theme.of(context).colorScheme.primary.withAlpha(12),
                              Theme.of(context).colorScheme.primary.withAlpha(6),
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: Theme.of(context).colorScheme.primary.withAlpha(20),
                            width: 1,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Theme.of(context).colorScheme.primary.withAlpha(8),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Theme.of(context).colorScheme.primary.withAlpha(20),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Icon(Icons.check_circle,
                                  size: 16,
                                  color: Theme.of(context).colorScheme.primary),
                            ),
                            const SizedBox(width: 12),
                            Text(
                              '$itemsLogged scraps scanned',
                              style: Theme.of(context)
                                  .textTheme
                                  .bodyMedium
                                  ?.copyWith(
                                    color: Theme.of(context)
                                        .colorScheme
                                        .onSurface,
                                    fontWeight: FontWeight.w700,
                                    fontSize: 15,
                                  ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              Theme.of(context).colorScheme.secondary.withAlpha(12),
                              Theme.of(context).colorScheme.secondary.withAlpha(6),
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: Theme.of(context).colorScheme.secondary.withAlpha(20),
                            width: 1,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Theme.of(context).colorScheme.secondary.withAlpha(8),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Theme.of(context).colorScheme.secondary.withAlpha(20),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Icon(Icons.attach_money,
                                  size: 16,
                                  color: Theme.of(context).colorScheme.secondary),
                            ),
                            const SizedBox(width: 12),
                            Text(
                              'Estimated ₱${estimatedSavings.toStringAsFixed(0)} saved',
                              style: Theme.of(context)
                                  .textTheme
                                  .bodyMedium
                                  ?.copyWith(
                                    color: Theme.of(context)
                                        .colorScheme
                                        .onSurface,
                                    fontWeight: FontWeight.w700,
                                    fontSize: 15,
                                  ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _ActionPanel extends StatelessWidget {
  const _ActionPanel({required this.onScan});

  final VoidCallback onScan;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
          horizontal: UIConstants.kHorizontalPadding,
          vertical: UIConstants.kVerticalGap),
      child: AppButton(
        text: 'Open camera',
        onPressed: onScan,
        elevation: 2,
      ),
    );
  }
}

class _WeightDisplay extends StatelessWidget {
  const _WeightDisplay({required this.currentWeight});

  final double? currentWeight;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.all(16),
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Theme.of(context).colorScheme.primary.withAlpha(8),
              Theme.of(context).colorScheme.secondary.withAlpha(4),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary.withAlpha(16),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                Icons.scale_outlined,
                size: 24,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Current Weight',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.onSurface.withAlpha(140),
                          fontWeight: FontWeight.w500,
                        ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    currentWeight != null ? '${currentWeight!.toStringAsFixed(1)} g' : 'No data',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                  ),
                ],
              ),
            ),
            if (currentWeight != null)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.secondary.withAlpha(16),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.sensors,
                  size: 16,
                  color: Theme.of(context).colorScheme.secondary,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _ScanTab extends StatelessWidget {
  const _ScanTab({required this.appState, required this.outcome, required this.itemsLogged, required this.weeklyScanCount});

  final AppState appState;
  final ScanOutcome? outcome;
  final int itemsLogged;
  final int weeklyScanCount;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      children: <Widget>[
        _ImpactLedger(itemsLogged: itemsLogged),
        const SizedBox(height: 20),
        Divider(
          color: Theme.of(context).colorScheme.onSurface.withOpacity(0.1),
          thickness: 1,
          indent: 0,
          endIndent: 0,
        ),
        const SizedBox(height: 16),
      ],
    );
  }
}

class _StepRow extends StatelessWidget {
  const _StepRow({required this.number, required this.text});

  final String number;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Container(
          width: 28,
          height: 28,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.primary.withOpacity(0.12),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(number, style: Theme.of(context).textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.primary,
              )),
        ),
        const SizedBox(width: 10),
        Expanded(child: Text(text, style: Theme.of(context).textTheme.bodyMedium)),
      ],
    );
  }
}

// No longer used

// Helper widget for sketch-style confidence meter
class _SketchConfidenceMeter extends StatelessWidget {
  const _SketchConfidenceMeter({required this.confidence});

  final double confidence;

  @override
  Widget build(BuildContext context) {
    final percentage = (confidence * 100).toInt();
    final filledSegments = ((confidence * 10).toInt()).clamp(0, 10);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: <Widget>[
            Text(
              'Confidence',
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurface,
                    fontWeight: FontWeight.normal,
                  ),
            ),
            Text(
              '$percentage%',
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: Theme.of(context).colorScheme.secondary,
                    fontWeight: FontWeight.bold,
                  ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Row(
          children: List.generate(
            10,
            (index) => Expanded(
              child: Container(
                height: 6,
                margin: const EdgeInsets.symmetric(horizontal: 1.5),
                decoration: BoxDecoration(
                  color: index < filledSegments
                      ? Theme.of(context).colorScheme.secondary
                      : Theme.of(context).colorScheme
                          .onSurface
                          .withAlpha(10),
                  borderRadius: BorderRadius.circular(2),
                  border: Border.all(
                    color: Theme.of(context).colorScheme
                        .onSurface
                        .withAlpha(10),
                    width: 0.5,
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({
    required this.title,
    required this.subtitle,
    required this.child,
  });

  final String title;
  final String subtitle;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              title,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.primary,
                    letterSpacing: -0.3,
                  ),
            ),
            const SizedBox(height: 6),
            Text(
              subtitle,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme
                        .onSurface
                        .withAlpha(140),
                    fontStyle: FontStyle.italic,
                  ),
            ),
            const SizedBox(height: 18),
            child,
          ],
        ),
      ),
    );
  }
}

class _LatestScanCard extends StatelessWidget {
  const _LatestScanCard({required this.outcome});

  final ScanOutcome outcome;

  String _getEncouragementMessage(bool requiresReview) {
    if (requiresReview) {
      return 'Please verify the label before saving.';
    }
    return 'Great catch! This scrap can become something delicious.';
  }

  @override
  Widget build(BuildContext context) {
    final statusColor = outcome.requiresReview
        ? Theme.of(context).colorScheme.primary
        : Theme.of(context).colorScheme.secondary;

    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      color: Theme.of(context).cardColor,
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: <Widget>[
                Text(
                  'Latest scan',
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: Theme.of(context).colorScheme.primary,
                        fontWeight: FontWeight.bold,
                      ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: statusColor,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    outcome.requiresReview ? 'Review' : 'Saved',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              outcome.predictedLabel,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.primary,
                    letterSpacing: -0.3,
                  ),
            ),
            const SizedBox(height: 12),
            _SketchConfidenceMeter(confidence: outcome.confidence),
            const SizedBox(height: 12),
            Text(
              _getEncouragementMessage(outcome.requiresReview),
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurface,
                    fontStyle: FontStyle.italic,
                  ),
            ),
            if (outcome.note != null) ...<Widget>[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surface.withAlpha(50),
                  border: Border.all(
                    color: Theme.of(context).colorScheme
                        .onSurface
                        .withAlpha(10),
                    width: 1,
                  ),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  outcome.note!,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _InventoryTile extends StatelessWidget {
  const _InventoryTile({
    required this.item,
    this.isSelected = false,
    this.onTap,
    this.onDelete,
  });

  final ScrapItem item;
  final bool isSelected;
  final VoidCallback? onTap;
  final VoidCallback? onDelete;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isSelected
              ? Theme.of(context).colorScheme.primary.withOpacity(0.1)
              : Colors.white,
          border: Border.all(
            color: isSelected
                ? Theme.of(context).colorScheme.primary
                : Theme.of(context).colorScheme.onSurface.withAlpha(10),
            width: isSelected ? 2 : 1.5,
          ),
          borderRadius: BorderRadius.circular(12),
          boxShadow: const <BoxShadow>[
            BoxShadow(
              color: Color.fromRGBO(0, 0, 0, 0.05),
              blurRadius: 4,
              offset: Offset(0, 1),
            ),
          ],
        ),
        child: Row(
          children: <Widget>[
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: isSelected
                    ? Theme.of(context).colorScheme.primary
                    : Theme.of(context).colorScheme.secondary,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: Theme.of(context).colorScheme
                      .onSurface
                      .withAlpha(10),
                  width: 1,
                ),
              ),
              child: Icon(
                isSelected ? Icons.check_circle : Icons.local_florist_outlined,
                color: isSelected ? Colors.white : Theme.of(context).colorScheme
                    .onSurface,
                size: 22,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    item.label,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: isSelected
                              ? Theme.of(context).colorScheme.primary
                              : Theme.of(context).colorScheme.onSurface,
                        ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${item.source} • ${(item.confidence * 100)
                        .toStringAsFixed(0)}%',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme
                              .onSurface
                              .withAlpha(140),
                        ),
                  ),
                ],
              ),
            ),
            if (onDelete != null)
              GestureDetector(
                onTap: onDelete,
                child: Container(
                  padding: const EdgeInsets.all(8),
                  child: Icon(
                    Icons.delete_outline,
                    color: Theme.of(context).colorScheme.error.withOpacity(0.7),
                    size: 20,
                  ),
                ),
              ),
            Icon(
              item.manualCorrection ? Icons.edit : Icons.check_circle,
              color: item.manualCorrection
                  ? Theme.of(context).colorScheme.primary
                  : Theme.of(context).colorScheme.secondary,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }
}

class _RecipeTile extends StatelessWidget {
  const _RecipeTile({required this.recipe, required this.appState, this.scrapItem});

  final RecipeSuggestion recipe;
  final AppState appState;
  final ScrapItem? scrapItem;

  @override
  Widget build(BuildContext context) {
    // Calculate if user has enough weight for the recipe based on the specific scrap
    bool isRecipeSufficient = true;
    String? insufficientIngredient;
    double? requiredWeight;
    double? availableWeight;

    if (recipe.ingredientWeights != null && scrapItem != null) {
      final scrapLabel = scrapItem!.label.toLowerCase();
      final scrapWeight = scrapItem!.weightGrams ?? 0.0;

      for (final entry in recipe.ingredientWeights!.entries) {
        final ingredient = entry.key;
        final requirement = entry.value;

        // Check if this recipe ingredient matches the scrap type
        if (ingredient.toLowerCase().contains(scrapLabel) || scrapLabel.contains(ingredient.toLowerCase())) {
          // Compare the specific scrap's weight to the recipe requirement
          if (scrapWeight < requirement) {
            isRecipeSufficient = false;
            insufficientIngredient = ingredient;
            requiredWeight = requirement;
            availableWeight = scrapWeight;
            break;
          }
        }
      }
    }

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        border: Border.all(
          color: Theme.of(context).colorScheme.onSurface.withAlpha(10),
          width: 1.5,
        ),
        borderRadius: BorderRadius.circular(14),
        boxShadow: const <BoxShadow>[
          BoxShadow(
            color: Color.fromRGBO(212, 229, 208, 0.12),
            blurRadius: 6,
            offset: Offset(0, 1),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Expanded(
                      child: Text(
                        recipe.title,
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: Theme.of(context).colorScheme.primary,
                              letterSpacing: -0.3,
                            ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.secondary
                            .withOpacity(0.15),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Icons.restaurant_menu,
                          size: 18, color: UIConstants.kSecondary),
                    ),
                  ],
                ),
          const SizedBox(height: 12),
          Text(
            recipe.summary,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurface,
                  height: 1.5,
                ),
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: recipe.ingredients
                .take(3)
                .map(
                  (ingredient) => Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: const Color.fromRGBO(255, 255, 255, 0.7),
                      border: Border.all(
                        color: Theme.of(context)
                            .colorScheme
                            .onSurface
                            .withAlpha(10),
                        width: 1,
                      ),
                      borderRadius: BorderRadius.circular(6),
                      boxShadow: const <BoxShadow>[
                        BoxShadow(
                          color: Color.fromRGBO(0, 0, 0, 0.04),
                          blurRadius: 2,
                          offset: Offset(0, 0.5),
                        ),
                      ],
                    ),
                    child: Text(
                      ingredient,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Theme.of(context).colorScheme.primary,
                            fontWeight: FontWeight.normal,
                          ),
                    ),
                  ),
                )
                .toList(),
          ),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color.fromRGBO(255, 255, 255, 0.8),
              border: Border.all(
                color: Theme.of(context).colorScheme.secondary
                    .withOpacity(0.2),
                width: 1,
              ),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  'Why this recipe',
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: Theme.of(context).colorScheme.secondary,
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 4),
                Text(
                  recipe.matchReason,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                ),
              ],
            ),
          ),
          if (recipe.chefNote != null) ...<Widget>[
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.secondary
                    .withOpacity(0.1),
                border: Border.all(
                  color: Theme.of(context).colorScheme.secondary
                      .withOpacity(0.25),
                  width: 1,
                ),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Row(
                    children: <Widget>[
                      Icon(Icons.note_outlined,
                          size: 16, color: Theme.of(context).colorScheme.secondary),
                      const SizedBox(width: 8),
                      Text(
                        'Chef note',
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                              color: Theme.of(context).colorScheme.secondary,
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    recipe.chefNote!,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.onSurface,
                          fontStyle: FontStyle.italic,
                          height: 1.4,
                        ),
                  ),
                ],
              ),
            ),
          ],
              ],
            ),
          ),
          const SizedBox(width: 12),
          // Weight sufficiency badge on the side
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: isRecipeSufficient
                  ? Theme.of(context).colorScheme.secondary.withAlpha(20)
                  : Theme.of(context).colorScheme.error.withAlpha(15),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: isRecipeSufficient
                    ? Theme.of(context).colorScheme.secondary.withAlpha(40)
                    : Theme.of(context).colorScheme.error.withAlpha(30),
                width: 1.5,
              ),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  isRecipeSufficient ? Icons.check_circle_outline : Icons.error_outline,
                  size: 20,
                  color: isRecipeSufficient
                      ? Theme.of(context).colorScheme.secondary
                      : Theme.of(context).colorScheme.error,
                ),
                const SizedBox(height: 4),
                Text(
                  isRecipeSufficient ? 'Enough' : 'Not Enough',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: isRecipeSufficient
                        ? Theme.of(context).colorScheme.secondary
                        : Theme.of(context).colorScheme.error,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ImpactLedger extends StatelessWidget {
  const _ImpactLedger({required this.itemsLogged});

  final int itemsLogged;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              children: <Widget>[
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primary
                        .withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(Icons.eco,
                      size: 18, color: Theme.of(context).colorScheme.primary),
                ),
                const SizedBox(width: 12),
                Text(
                  'Your impact so far',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.primary,
                        letterSpacing: -0.3,
                      ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _ImpactRow(
              icon: Icons.check_circle,
              label: '$itemsLogged scraps scanned',
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(height: 12),
            _ImpactRow(
              icon: Icons.restaurant_menu,
              label:
                  '${itemsLogged > 0 ? (itemsLogged * 2) : 0} recipe ideas discovered',
              color: Theme.of(context).colorScheme.secondary,
            ),
            const SizedBox(height: 12),
            _ImpactRow(
              icon: Icons.savings,
              label: 'Help reducing food waste',
              color: Theme.of(context).colorScheme.primary,
            ),
          ],
        ),
      ),
    );
  }
}

class _ImpactRow extends StatelessWidget {
  const _ImpactRow({
    required this.icon,
    required this.label,
    required this.color,
  });

  final IconData icon;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: <Widget>[
        Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: color.withAlpha(25),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Icon(icon, size: 16, color: color),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurface,
                  fontWeight: FontWeight.normal,
                ),
          ),
        ),
      ],
    );
  }
}

class _RecipeSuggestionsSection extends StatelessWidget {
  const _RecipeSuggestionsSection({required this.appState});

  final AppState appState;

  @override
  Widget build(BuildContext context) {
    final recipeSuggestions = appState.activeRecipeSuggestions;
    
    if (recipeSuggestions.isEmpty) {
      return _SectionCard(
        title: 'Recipe Ideas',
        subtitle: 'Scan some food scraps to get recipe suggestions!',
        child: const Text(
          'No scraps scanned yet. Use the camera to scan your first food scrap and get recipe ideas.',
        ),
      );
    }

    return _SectionCard(
      title: 'Recipe Ideas',
      subtitle: 'Based on your scanned scraps',
      child: Column(
        children: [
          ...recipeSuggestions.take(3).map((recipe) => Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: _RecipeTile(recipe: recipe, appState: appState, scrapItem: appState.inventory.isNotEmpty ? appState.inventory.last : null),
          )),
          if (recipeSuggestions.length > 3)
            TextButton(
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => RecipeListScreen(
                      appState: appState,
                      labels: appState.inventory.map((item) => item.label).toList(),
                    ),
                  ),
                );
              },
              child: Text(
                'View all ${recipeSuggestions.length} recipes',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.primary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

