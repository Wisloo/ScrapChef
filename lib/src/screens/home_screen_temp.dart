import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models.dart';
import '../state/app_state.dart';
import '../widgets/page_transitions.dart';
import '../widgets/veggie_mascots.dart'
  hide kPrimary, kPrimaryLight, kSecondary, kAccent, kBackground, kSurface, kText, kTextLight, kDivider, kDarkBackground, kDarkSurface, kDarkText, kDarkTextLight, kDarkDivider;
import 'manual_verify_screen.dart';
import 'recipe_detail_screen.dart';
import 'scan_screen.dart';
import 'settings_screen.dart';
import 'splash_screen.dart';
import '../theme/app_theme.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key, required this.appState, required this.onThemeChanged});

  final AppState appState;
  final ValueChanged<bool> onThemeChanged;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  bool _showSplash = true;
  bool _useBatchMatching = true;
  _RecipeViewMode _recipeViewMode = _RecipeViewMode.bestMatch;

  @override
  void initState() {
    super.initState();
    widget.appState.addListener(_onAppStateChanged);
    _animController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _animController.forward();
  }

  @override
  void dispose() {
    widget.appState.removeListener(_onAppStateChanged);
    _animController.dispose();
    super.dispose();
  }

  void _onAppStateChanged() {
    if (mounted) setState(() {});
  }

  void _onSplashComplete() {
    setState(() => _showSplash = false);
  }

  Future<void> _openScanFlow() async {
    HapticFeedback.mediumImpact();
    final outcome = await Navigator.of(context).push<ScanOutcome>(
      SmoothPageRoute(
        builder: (_) => ScanScreen(appState: widget.appState),
      ),
    );

    if (!mounted || outcome == null) return;

    if (outcome.requiresReview) {
      await Navigator.of(context).push(
        SmoothPageRoute(
          builder: (_) => ManualVerifyScreen(
            appState: widget.appState,
            predictedLabel: outcome.predictedLabel,
            confidence: outcome.confidence,
          ),
        ),
      );
    }
  }

  Future<void> _addManualItem() async {
    HapticFeedback.mediumImpact();
    final label = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _ManualAddSheet(labels: widget.appState.supportedLabels),
    );

    if (label != null && label.isNotEmpty) {
      widget.appState.addManualItem(label);
    }
  }

  void _openSettings() {
    HapticFeedback.mediumImpact();
    Navigator.of(context).push(
      SlideUpPageRoute(
        builder: (_) => SettingsScreen(
          appState: widget.appState,
          onThemeChanged: widget.onThemeChanged,
        ),
      ),
    );
  }

  void _showHelp() {
    HapticFeedback.mediumImpact();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const _HelpSheet(),
    );
  }

  List<RecipeSuggestion> _rankSuggestions(
    List<RecipeSuggestion> suggestions,
    Set<String> inventoryLabels,
  ) {
    if (suggestions.isEmpty || _recipeViewMode == _RecipeViewMode.bestMatch) {
      return suggestions;
    }

    final ranked = List<RecipeSuggestion>.from(suggestions);
    if (_recipeViewMode == _RecipeViewMode.quickWins) {
      ranked.sort((a, b) => a.ingredients.length.compareTo(b.ingredients.length));
      return ranked;
    }

    ranked.sort((a, b) {
      final overlapA = a.ingredients
          .where((ingredient) => inventoryLabels.contains(ingredient.toLowerCase().trim()))
          .length;
      final overlapB = b.ingredients
          .where((ingredient) => inventoryLabels.contains(ingredient.toLowerCase().trim()))
          .length;
      return overlapB.compareTo(overlapA);
    });
    return ranked;
  }

  @override
  Widget build(BuildContext context) {
    if (_showSplash) {
      return SplashScreen(onComplete: _onSplashComplete);
    }

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? kDarkBackground : kBackground;
    final cardColor = isDark ? kDarkSurface : kSurface;
    final textColor = isDark ? kDarkText : kText;

    final inventory = widget.appState.inventory;
    final savedRecipes = widget.appState.savedRecipes;
    final itemsLogged = inventory.length;
    final estimatedSavings = widget.appState.estimatedSavings;
    final inventoryLabels = inventory.map((item) => item.label.toLowerCase().trim()).toSet();

    final displaySuggestions = _useBatchMatching
      ? widget.appState.activeRecipeSuggestions
      : widget.appState.recipeSuggestions;
    final rankedSuggestions = _rankSuggestions(displaySuggestions, inventoryLabels);

    return Scaffold(
      backgroundColor: bgColor,
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverAppBar(
              floating: true,
              backgroundColor: bgColor,
              elevation: 0,
              title: Row(
                children: [
                  Text(
                    'ScrapChef',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w800,
                      color: textColor,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Icon(Icons.eco_rounded, color: kSecondary, size: 24),
                ],
              ),
              actions: [
                IconButton(
                  icon: Icon(Icons.settings_rounded, color: textColor),
                  onPressed: () {
                    HapticFeedback.lightImpact();
                    Navigator.of(context).push(
                      SmoothPageRoute(
                        builder: (_) => SettingsScreen(
                          appState: widget.appState,
                          onThemeChanged: widget.onThemeChanged,
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [kPrimary.withAlpha(18), kSecondary.withAlpha(10)],
                        ),
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(color: kPrimary.withAlpha(24)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: kPrimary.withAlpha(14),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Icon(Icons.info_rounded, color: kPrimary, size: 20),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                itemsLogged == 0 ? 'Start with one scrap' : 'You are building momentum',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                  color: textColor,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            itemsLogged == 0
                                ? 'Scan one ingredient, or add it manually if you are not near the camera. ScrapChef will handle the rest.'
                                : 'Keep adding scraps to unlock better matches and easier recipe choices.',
                            style: TextStyle(
                              fontSize: 14,
                              color: textColor.withAlpha(165),
                              height: 1.4,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: const [
                              _StatusChip(label: 'Scan first'),
                              _StatusChip(label: 'Review if unsure'),
                              _StatusChip(label: 'Save recipes'),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    Row(
                      children: [
                        Expanded(
                          child: _QuickActionButton(
                            icon: Icons.camera_alt_rounded,
                            label: 'Scan Scrap',
                            color: kPrimary,
                            onTap: _openScanFlow,
                            textColor: textColor,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _QuickActionButton(
                            icon: Icons.add_circle_rounded,
                            label: 'Add Manually',
                            color: kSecondary,
                            onTap: _addManualItem,
                            textColor: textColor,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    _FeatureRail(
                      onScanTap: _openScanFlow,
                      onManualAddTap: _addManualItem,
                      onHelpTap: _showHelp,
                    ),
                    const SizedBox(height: 20),
                    _ImpactLedger(itemsLogged: itemsLogged, estimatedSavings: estimatedSavings),
                    const SizedBox(height: 24),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      decoration: BoxDecoration(
                        color: cardColor,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: kDivider),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.restaurant_menu_rounded, color: kPrimary, size: 22),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'How should recipes be matched?',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: textColor,
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          GestureDetector(
                            onTap: () {
                              setState(() => _useBatchMatching = !_useBatchMatching);
                              HapticFeedback.selectionClick();
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                              decoration: BoxDecoration(
                                gradient: _useBatchMatching
                                    ? const LinearGradient(
                                        colors: [kPrimary, kPrimaryLight],
                                      )
                                    : null,
                                color: _useBatchMatching ? null : kDivider,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                _useBatchMatching ? 'Batch' : 'Single',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                  color: _useBatchMatching ? Colors.white : textColor,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),
                    _RecipeModeSelector(
                      mode: _recipeViewMode,
                      onModeChanged: (mode) {
                        setState(() => _recipeViewMode = mode);
                        HapticFeedback.selectionClick();
                      },
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
                child: Column(
                  children: [
                    if (savedRecipes.isNotEmpty) ...[
                      _SectionHeader(title: 'Saved Recipes'),
                      const SizedBox(height: 12),
                      SizedBox(
                        height: 160,
                        child: ListView.builder(
                          scrollDirection: Axis.horizontal,
                          itemCount: savedRecipes.length,
                          itemBuilder: (context, index) {
                            return Padding(
                              padding: const EdgeInsets.only(right: 12),
                              child: SizedBox(
                                width: 280,
                                child: _SavedRecipeTile(
                                  savedRecipe: savedRecipes[index],
                                  onTap: () {
                                    final recipe = RecipeSuggestion(
                                      title: savedRecipes[index].title,
                                      summary: savedRecipes[index].summary,
                                      ingredients: savedRecipes[index].ingredients,
                                      matchReason: savedRecipes[index].matchReason,
                                      chefNote: savedRecipes[index].chefNote,
                                    );
                                    Navigator.of(context).push(
                                      MaterialPageRoute(
                                        builder: (context) => RecipeDetailScreen(
                                          recipe: recipe,
                                          appState: widget.appState,
                                        ),
                                      ),
                                    );
                                  },
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                      const SizedBox(height: 24),
                    ],
                    _SectionHeader(title: _useBatchMatching ? 'Recipe Suggestions (Batch)' : 'Recipe Suggestions (Individual)'),
                    const SizedBox(height: 12),
                    _RecentScrapsRow(inventory: inventory),
                    const SizedBox(height: 16),
                    if (rankedSuggestions.isEmpty)
                      Center(
                        child: Padding(
                          padding: const EdgeInsets.all(40),
                          child: Column(
                            children: [
                              Icon(Icons.restaurant_rounded, size: 64, color: kPrimary.withAlpha(100)),
                              const SizedBox(height: 16),
                              Text(
                                _useBatchMatching
                                    ? 'No recipes match your batch'
                                    : 'No recipes match this scrap',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: textColor.withAlpha(140),
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Add more scraps to get better matches',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: textColor.withAlpha(120),
                                ),
                              ),
                            ],
                          ),
                        ),
                      )
                    else
                      ...rankedSuggestions.map((recipe) {
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 16),
                          child: _RecipeSuggestionCard(
                            recipe: recipe,
                            onTap: () {
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (context) => RecipeDetailScreen(
                                    recipe: recipe,
                                    appState: widget.appState,
                                  ),
                                ),
                              );
                            },
                            textColor: textColor,
                            cardColor: cardColor,
                            useBatchMatching: _useBatchMatching,
                          ),
                        );
                      }),
                    const SizedBox(height: 40),
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
  const _HeroHeader({required this.itemsLogged, required this.estimatedSavings, required this.textColor});

  final int itemsLogged;
  final double estimatedSavings;
  final Color textColor;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'ScrapChef',
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.w800,
                      color: textColor,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Turn scraps into delicious meals',
                    style: TextStyle(
                      fontSize: 15,
                      color: textColor.withAlpha(180),
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.white.withAlpha(30),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.white.withAlpha(50)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.eco_rounded, size: 18, color: Colors.white),
                  const SizedBox(width: 8),
                  Text(
                    '$itemsLogged',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: 18,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),
        Row(
          children: [
            _StatItem(
              icon: Icons.check_circle_rounded,
              label: '$itemsLogged scraps tracked',
              color: Colors.white,
              textColor: textColor,
            ),
            const SizedBox(width: 24),
            _StatItem(
              icon: Icons.savings_rounded,
              label: 'â‚±${estimatedSavings.toStringAsFixed(0)} saved',
              color: Colors.white,
              textColor: textColor,
            ),
          ],
        ),
      ],
    );
  }
}

class _ActionButton extends StatefulWidget {
  const _ActionButton({
    required this.onPressed,
    required this.icon,
    required this.label,
    required this.color,
    required this.isPrimary,
  });

  final VoidCallback onPressed;
  final IconData icon;
  final String label;
  final Color color;
  final bool isPrimary;

  @override
  State<_ActionButton> createState() => _ActionButtonState();
}

class _ActionButtonState extends State<_ActionButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _pressController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _pressController = AnimationController(
      duration: const Duration(milliseconds: 100),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 1, end: 0.97).animate(
      CurvedAnimation(parent: _pressController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pressController.dispose();
    super.dispose();
  }

  void _onTapDown(_) => _pressController.forward();
  void _onTapUp(_) => _pressController.reverse();
  void _onTapCancel() => _pressController.reverse();

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: _onTapDown,
      onTapUp: _onTapUp,
      onTapCancel: _onTapCancel,
      onTap: widget.onPressed,
      child: AnimatedBuilder(
        animation: _scaleAnimation,
        builder: (context, child) => Transform.scale(
          scale: _scaleAnimation.value,
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 18),
            decoration: BoxDecoration(
              gradient: widget.isPrimary
                  ? LinearGradient(
                      colors: [widget.color, widget.color.withAlpha(200)],
                    )
                  : null,
              color: widget.isPrimary ? null : Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: widget.isPrimary
                  ? null
                  : Border.all(color: widget.color.withAlpha(100)),
              boxShadow: [
                BoxShadow(
                  color: widget.color.withAlpha(widget.isPrimary ? 40 : 20),
                  blurRadius: 16,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  widget.icon,
                  color: widget.isPrimary ? Colors.white : widget.color,
                  size: 24,
                ),
                const SizedBox(width: 10),
                Text(
                  widget.label,
                  style: TextStyle(
                    color: widget.isPrimary ? Colors.white : widget.color,
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _QuickActionButton extends StatelessWidget {
  const _QuickActionButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
    required this.textColor,
  });

  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;
  final Color textColor;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          gradient: LinearGradient(colors: [color, color.withAlpha(200)]),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: color.withAlpha(40),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: Colors.white, size: 22),
            const SizedBox(width: 10),
            Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w700,
                fontSize: 15,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.w800,
        color: kText,
      ),
    );
  }
}

class _ImpactLedger extends StatelessWidget {
  const _ImpactLedger({required this.itemsLogged, required this.estimatedSavings});

  final int itemsLogged;
  final double estimatedSavings;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? kDarkText : kText;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [kSecondary.withAlpha(30), kSecondary.withAlpha(15)],
                ),
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Icon(Icons.eco_rounded, size: 22, color: kSecondary),
            ),
            const SizedBox(width: 12),
            Text(
              'Your Impact',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: textColor,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            _StatItem(
              icon: Icons.check_circle_rounded,
              label: '$itemsLogged scraps tracked',
              color: kSecondary,
              textColor: textColor,
            ),
            const SizedBox(width: 24),
            _StatItem(
              icon: Icons.savings_rounded,
              label: 'â‚±${estimatedSavings.toStringAsFixed(0)} saved',
              color: kPrimary,
              textColor: textColor,
            ),
          ],
        ),
      ],
    );
  }
}

class _StatItem extends StatelessWidget {
  const _StatItem({required this.icon, required this.label, required this.color, required this.textColor});

  final IconData icon;
  final String label;
  final Color color;
  final Color textColor;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 20, color: color),
        const SizedBox(width: 8),
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: textColor.withAlpha(180),
          ),
        ),
      ],
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: kPrimary.withAlpha(10),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: kPrimary.withAlpha(20)),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: kText,
          fontSize: 12,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

enum _RecipeViewMode {
  bestMatch,
  pantryFirst,
  quickWins,
}

class _RecipeModeSelector extends StatelessWidget {
  const _RecipeModeSelector({
    required this.mode,
    required this.onModeChanged,
  });

  final _RecipeViewMode mode;
  final ValueChanged<_RecipeViewMode> onModeChanged;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? kDarkText : kText;
    final bgColor = isDark ? kDarkSurface : kSurface;

    Widget modePill(_RecipeViewMode value, String label) {
      final isActive = mode == value;
      return Expanded(
        child: GestureDetector(
          onTap: () => onModeChanged(value),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            padding: const EdgeInsets.symmetric(vertical: 10),
            decoration: BoxDecoration(
              color: isActive ? kPrimary : Colors.transparent,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              label,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: isActive ? Colors.white : textColor.withAlpha(170),
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: kDivider),
      ),
      child: Row(
        children: [
          modePill(_RecipeViewMode.bestMatch, 'Best Match'),
          modePill(_RecipeViewMode.pantryFirst, 'Pantry-First'),
          modePill(_RecipeViewMode.quickWins, 'Quick Wins'),
        ],
      ),
    );
  }
}

class _RecentScrapsRow extends StatelessWidget {
  const _RecentScrapsRow({required this.inventory});

  final List<ScrapItem> inventory;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? kDarkText : kText;

    if (inventory.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: (isDark ? kDarkSurface : kSurface).withAlpha(220),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: kDivider),
        ),
        child: Text(
          'No scraps yet. Start with Scan Scrap or Add Manually.',
          style: TextStyle(
            fontSize: 13,
            color: textColor.withAlpha(170),
            fontWeight: FontWeight.w600,
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Recent scraps',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: textColor,
          ),
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: inventory.take(6).map((item) {
            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              decoration: BoxDecoration(
                color: kSecondary.withAlpha(18),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: kSecondary.withAlpha(38)),
              ),
              child: Text(
                item.label,
                style: TextStyle(
                  color: textColor,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
}

class _FeatureRail extends StatelessWidget {
  const _FeatureRail({
    required this.onScanTap,
    required this.onManualAddTap,
    required this.onHelpTap,
  });

  final VoidCallback onScanTap;
  final VoidCallback onManualAddTap;
  final VoidCallback onHelpTap;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardColor = isDark ? kDarkSurface : kSurface;

    Widget item({
      required IconData icon,
      required String title,
      required String subtitle,
      required Color color,
      required VoidCallback onTap,
    }) {
      return Expanded(
        child: GestureDetector(
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: cardColor,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: kDivider),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(icon, color: color, size: 20),
                const SizedBox(height: 8),
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                    color: kText,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontWeight: FontWeight.w500,
                    fontSize: 11,
                    color: (isDark ? kDarkTextLight : kTextLight).withAlpha(200),
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Row(
      children: [
        item(
          icon: Icons.document_scanner_rounded,
          title: 'Smart Scan',
          subtitle: 'Fast camera add',
          color: kPrimary,
          onTap: onScanTap,
        ),
        const SizedBox(width: 10),
        item(
          icon: Icons.edit_note_rounded,
          title: 'Quick Add',
          subtitle: 'No camera needed',
          color: kSecondary,
          onTap: onManualAddTap,
        ),
        const SizedBox(width: 10),
        item(
          icon: Icons.tips_and_updates_rounded,
          title: 'How it works',
          subtitle: 'Simple 4-step guide',
          color: kAccent,
          onTap: onHelpTap,
        ),
      ],
    );
  }
}

class _SavedRecipeTile extends StatelessWidget {
  const _SavedRecipeTile({
    required this.savedRecipe,
    required this.onTap,
  });

  final SavedRecipeRecord savedRecipe;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardColor = isDark ? kDarkSurface : kSurface;
    final textColor = isDark ? kDarkText : kText;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: kDivider),
          boxShadow: [
            BoxShadow(
              color: textColor.withAlpha(8),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              savedRecipe.title,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: textColor,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 6),
            Text(
              savedRecipe.summary,
              style: TextStyle(
                fontSize: 13,
                color: textColor.withAlpha(140),
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}

class _RecipeSuggestionCard extends StatelessWidget {
  const _RecipeSuggestionCard({
    required this.recipe,
    required this.onTap,
    required this.textColor,
    required this.cardColor,
    required this.useBatchMatching,
  });

  final RecipeSuggestion recipe;
  final VoidCallback onTap;
  final Color textColor;
  final Color cardColor;
  final bool useBatchMatching;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: kDivider),
          boxShadow: [
            BoxShadow(
              color: textColor.withAlpha(10),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [kPrimary.withAlpha(20), kPrimaryLight.withAlpha(10)],
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(Icons.restaurant_menu_rounded, color: kPrimary, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    recipe.title,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: textColor,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              recipe.summary,
              style: TextStyle(
                fontSize: 14,
                color: textColor.withAlpha(140),
                height: 1.4,
              ),
            ),
            const SizedBox(height: 12),
            _MatchBadge(matchReason: recipe.matchReason),
          ],
        ),
      ),
    );
  }
}

class _MatchBadge extends StatelessWidget {
  const _MatchBadge({required this.matchReason});

  final String matchReason;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [kSecondary.withAlpha(20), kSecondary.withAlpha(10)],
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: kSecondary.withAlpha(40)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.auto_awesome_rounded, size: 14, color: kSecondary),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              matchReason,
              style: const TextStyle(
                color: kSecondary,
                fontWeight: FontWeight.w600,
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ManualAddSheet extends StatefulWidget {
  const _ManualAddSheet({required this.labels});

  final List<String> labels;

  @override
  State<_ManualAddSheet> createState() => _ManualAddSheetState();
}

class _ManualAddSheetState extends State<_ManualAddSheet> {
  String? _selectedLabel;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardColor = isDark ? kDarkSurface : kSurface;
    final textColor = isDark ? kDarkText : kText;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Add Scrap Manually',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: textColor,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Select the type of scrap:',
            style: TextStyle(
              fontSize: 14,
              color: textColor.withAlpha(140),
            ),
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: widget.labels.map((label) {
              final isSelected = _selectedLabel == label;
              return GestureDetector(
                onTap: () {
                  setState(() => _selectedLabel = label);
                  HapticFeedback.selectionClick();
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    gradient: isSelected
                        ? LinearGradient(colors: [kPrimary, kPrimaryLight.withAlpha(200)])
                        : null,
                    color: isSelected ? null : cardColor,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isSelected ? kPrimary : kDivider,
                    ),
                  ),
                  child: Text(
                    label,
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: isSelected ? Colors.white : textColor,
                      fontSize: 14,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Cancel'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: FilledButton(
                  onPressed: _selectedLabel != null
                      ? () => Navigator.of(context).pop(_selectedLabel)
                      : null,
                  child: const Text('Add'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _HelpSheet extends StatelessWidget {
  const _HelpSheet();

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardColor = isDark ? kDarkSurface : kSurface;
    final textColor = isDark ? kDarkText : kText;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'How to Use ScrapChef',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: textColor,
            ),
          ),
          const SizedBox(height: 16),
          _HelpStep(
            icon: Icons.camera_alt_rounded,
            title: 'Scan a scrap',
            description: 'Take a photo of your food scrap to identify it',
          ),
          const SizedBox(height: 12),
          _HelpStep(
            icon: Icons.check_circle_rounded,
            title: 'Confirm the label',
            description: 'Review and confirm the AI classification',
          ),
          const SizedBox(height: 12),
          _HelpStep(
            icon: Icons.restaurant_menu_rounded,
            title: 'Get recipes',
            description: 'Discover recipes based on your scraps',
          ),
          const SizedBox(height: 12),
          _HelpStep(
            icon: Icons.add_circle_rounded,
            title: 'Add manually',
            description: 'Add scraps manually if scanning fails',
          ),
          const SizedBox(height: 24),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Got it'),
          ),
        ],
      ),
    );
  }
}

class _HelpStep extends StatelessWidget {
  const _HelpStep({
    required this.icon,
    required this.title,
    required this.description,
  });

  final IconData icon;
  final String title;
  final String description;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [kPrimary.withAlpha(20), kPrimaryLight.withAlpha(10)],
            ),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: kPrimary, size: 20),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            title,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: textColor,
            ),
          ),
        ),
      ],
    );
  }
}
