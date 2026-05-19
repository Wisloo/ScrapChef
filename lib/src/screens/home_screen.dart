import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models.dart';
import '../state/app_state.dart';
import '../widgets/page_transitions.dart';
import '../widgets/veggie_mascots.dart';
import 'manual_verify_screen.dart';
import 'recipe_detail_screen.dart';
import 'scan_screen.dart';
import 'settings_screen.dart';
import 'splash_screen.dart';

// Modern color palette
const Color kPrimary = Color(0xFF6C5CE7);
const Color kPrimaryLight = Color(0xFFA29BFE);
const Color kSecondary = Color(0xFF00CEC9);
const Color kAccent = Color(0xFFFD79A8);
const Color kBackground = Color(0xFFF8F9FA);
const Color kSurface = Color(0xFFFFFFFF);
const Color kText = Color(0xFF2D3436);
const Color kTextLight = Color(0xFF636E72);
const Color kDivider = Color(0xFFDFE6E9);

// Dark theme colors
const Color kDarkBackground = Color(0xFF121212);
const Color kDarkSurface = Color(0xFF1E1E1E);
const Color kDarkText = Color(0xFFE0E0E0);
const Color kDarkTextLight = Color(0xFFB0B0B0);
const Color kDarkDivider = Color(0xFF2C2C2C);

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

  @override
  Widget build(BuildContext context) {
    if (_showSplash) {
      return SplashScreen(onComplete: _onSplashComplete);
    }

    final outcome = widget.appState.lastOutcome;
    final inventory = widget.appState.inventory;
    final suggestions = widget.appState.activeRecipeSuggestions;
    final latestBatchLabels = widget.appState.latestBatchLabels;
    final itemsLogged = widget.appState.itemsLogged;
    final estimatedSavings = widget.appState.estimatedSavings;

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? kDarkBackground : kBackground;
    final cardColor = isDark ? kDarkSurface : kSurface;
    final textColor = isDark ? kDarkText : kText;
    final textLightColor = isDark ? kDarkTextLight : kTextLight;
    final dividerColor = isDark ? kDarkDivider : kDivider;

    return DefaultTabController(
      length: 3,
      child: Scaffold(
        backgroundColor: bgColor,
        floatingActionButton: FloatingActionButton(
          onPressed: _showHelp,
          backgroundColor: kPrimary,
          elevation: 8,
          child: const Icon(Icons.help_outline, color: Colors.white),
        ),
        body: Container(
          decoration: BoxDecoration(
            gradient: isDark
                ? null
                : const LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      kBackground,
                      kSurface,
                    ],
                  ),
          ),
          child: NestedScrollView(
            headerSliverBuilder: (context, innerBoxIsScrolled) {
              return [
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 50, 20, 0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [kPrimary, kPrimaryLight],
                            ),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.eco, color: Colors.white, size: 20),
                              const SizedBox(width: 8),
                              Text(
                                'ScrapChef',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 16,
                                ),
                              ),
                            ],
                          ),
                        ),
                        GestureDetector(
                          onTap: _openSettings,
                          child: Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: cardColor,
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: [
                                BoxShadow(
                                  color: textColor.withAlpha(10),
                                  blurRadius: 12,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Icon(
                              Icons.settings_rounded,
                              color: textColor,
                              size: 24,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                SliverToBoxAdapter(
                  child: Container(
                    margin: const EdgeInsets.fromLTRB(20, 20, 20, 16),
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: isDark
                            ? [kDarkSurface, kDarkSurface]
                            : [kPrimary, kPrimaryLight],
                      ),
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          color: kPrimary.withAlpha(30),
                          blurRadius: 24,
                          offset: const Offset(0, 12),
                        ),
                      ],
                    ),
                    child: _HeroHeader(
                      itemsLogged: itemsLogged,
                      estimatedSavings: estimatedSavings,
                      textColor: Colors.white,
                    ),
                  ),
                ),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: _ActionPanel(
                      onScan: _openScanFlow,
                      onManualAdd: _addManualItem,
                      textColor: textColor,
                      cardColor: cardColor,
                    ),
                  ),
                ),
                SliverToBoxAdapter(
                  child: Container(
                    margin: const EdgeInsets.fromLTRB(20, 24, 20, 12),
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: cardColor,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: textColor.withAlpha(8),
                          blurRadius: 16,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: TabBar(
                      indicator: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [kPrimary, kPrimaryLight],
                        ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      indicatorSize: TabBarIndicatorSize.tab,
                      labelColor: Colors.white,
                      unselectedLabelColor: textLightColor,
                      labelStyle: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                      ),
                      unselectedLabelStyle: const TextStyle(
                        fontWeight: FontWeight.w500,
                        fontSize: 14,
                      ),
                      dividerColor: Colors.transparent,
                      tabs: const [
                        Tab(text: 'Scan'),
                        Tab(text: 'Bin'),
                        Tab(text: 'Recipes'),
                      ],
                    ),
                  ),
                ),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
                    child: Row(
                      children: [
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                            decoration: BoxDecoration(
                              color: cardColor,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: dividerColor),
                            ),
                            child: Row(
                              children: [
                                Icon(Icons.restaurant_menu_rounded, color: kPrimary, size: 22),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    'Recipe Matching',
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
                                      color: _useBatchMatching ? null : dividerColor,
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Text(
                                      _useBatchMatching ? 'Batch' : 'Individual',
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
                        ),
                      ],
                    ),
                  ),
                ),
              ];
            },
            body: TabBarView(
              children: [
                _ScanTab(
                  outcome: outcome,
                  itemsLogged: itemsLogged,
                  onScan: _openScanFlow,
                  textColor: textColor,
                ),
                _InventoryTab(
                  items: inventory,
                  onRefresh: () async {
                    await Future.delayed(const Duration(seconds: 1));
                  },
                  textColor: textColor,
                  cardColor: cardColor,
                ),
                _RecipeTab(
                  recipes: suggestions,
                  savedRecipes: widget.appState.savedRecipes,
                  batchLabels: latestBatchLabels,
                  appState: widget.appState,
                  onRecipeTap: (recipe) {
                    Navigator.of(context).push(
                      SmoothPageRoute(
                        builder: (_) => RecipeDetailScreen(recipe: recipe, appState: widget.appState),
                      ),
                    );
                  },
                  textColor: textColor,
                  cardColor: cardColor,
                  useBatchMatching: _useBatchMatching,
                ),
              ],
            ),
          ),
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
              label: '₱${estimatedSavings.toStringAsFixed(0)} saved',
              color: Colors.white,
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
            color: textColor.withAlpha(220),
          ),
        ),
      ],
    );
  }
}

class _ActionPanel extends StatelessWidget {
  const _ActionPanel({required this.onScan, required this.onManualAdd, required this.textColor, required this.cardColor});

  final VoidCallback onScan;
  final VoidCallback onManualAdd;
  final Color textColor;
  final Color cardColor;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _ActionButton(
            onPressed: onScan,
            icon: Icons.camera_alt_rounded,
              label: 'Scan Scrap',
            color: kPrimary,
            isPrimary: true,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _ActionButton(
            onPressed: onManualAdd,
            icon: Icons.add_rounded,
              label: 'Add Manually',
            color: kSecondary,
            isPrimary: false,
          ),
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

class _ScanTab extends StatelessWidget {
  const _ScanTab({
    required this.outcome,
    required this.itemsLogged,
    required this.onScan,
    required this.textColor,
  });

  final ScanOutcome? outcome;
  final int itemsLogged;
  final VoidCallback onScan;
  final Color textColor;

  @override
  Widget build(BuildContext context) {
    final lastOutcome = outcome;
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
      children: [
        _Card(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [kPrimary.withAlpha(30), kPrimaryLight.withAlpha(15)],
                      ),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Icon(
                      Icons.camera_enhance_rounded,
                      color: kPrimary,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Ready to scan',
                          style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w700,
                            color: textColor,
                          ),
                        ),
                        Text(
                          'Capture scraps, classify them, and get recipe matches',
                          style: TextStyle(
                            fontSize: 13,
                            color: textColor.withAlpha(140),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                'Use the Scan Scrap button above to capture a photo.',
                style: TextStyle(
                  fontSize: 13,
                  color: textColor.withAlpha(140),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        if (lastOutcome != null) ...[
          _Card(
            child: _LatestScanCard(outcome: lastOutcome),
          ),
          const SizedBox(height: 16),
        ],
        _Card(
          child: _ImpactLedger(itemsLogged: itemsLogged),
        ),
        const SizedBox(height: 16),
        _Card(
          child: const _HowItWorksSection(),
        ),
      ],
    );
  }
}

class _Card extends StatelessWidget {
  const _Card({required this.child, this.color, this.textColor});

  final Widget child;
  final Color? color;
  final Color? textColor;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardColor = color ?? (isDark ? kDarkSurface : kSurface);
    final effectiveTextColor = textColor ?? (isDark ? kDarkText : kText);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: effectiveTextColor.withAlpha(6),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: child,
    );
  }
}

class _LatestScanCard extends StatelessWidget {
  const _LatestScanCard({required this.outcome});

  final ScanOutcome outcome;

  String _getMessage() {
    if (outcome.requiresReview) {
      return 'Please verify the label before saving.';
    }
    return 'Great catch! This scrap can become something delicious.';
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? kDarkText : kText;
    final statusColor = outcome.requiresReview ? kAccent : kSecondary;
    final statusText = outcome.requiresReview ? 'Needs Review' : 'Saved';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Latest Scan',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: textColor.withAlpha(140),
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [statusColor, statusColor.withAlpha(200)],
                ),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                statusText,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                  fontSize: 12,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        Text(
          outcome.predictedLabel,
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w800,
            color: textColor,
          ),
        ),
        const SizedBox(height: 12),
        _ConfidenceMeter(confidence: outcome.confidence),
        const SizedBox(height: 10),
        Text(
          _getMessage(),
          style: TextStyle(
            fontSize: 13,
            color: textColor.withAlpha(160),
            fontStyle: FontStyle.italic,
          ),
        ),
      ],
    );
  }
}

class _ConfidenceMeter extends StatelessWidget {
  const _ConfidenceMeter({required this.confidence});

  final double confidence;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? kDarkText : kText;
    final percentage = (confidence * 100).toInt();
    final filledSegments = ((confidence * 10).toInt()).clamp(0, 10);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Confidence',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: textColor.withAlpha(140),
              ),
            ),
            Text(
              '$percentage%',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: kPrimary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Row(
          children: List.generate(
            10,
            (index) => Expanded(
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 400),
                height: 6,
                margin: const EdgeInsets.symmetric(horizontal: 1),
                decoration: BoxDecoration(
                  color: index < filledSegments
                      ? kPrimary
                      : textColor.withAlpha(30),
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
            ),
          ),
        ),
    );
  }
}

class _ImpactLedger extends StatelessWidget {
  const _ImpactLedger({required this.itemsLogged});

  final int itemsLogged;

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
        const SizedBox(height: 16),
        _ImpactRow(
          icon: Icons.check_circle_rounded,
          label: '$itemsLogged scraps scanned',
          color: kSecondary,
          textColor: textColor,
        ),
        const SizedBox(height: 10),
        _ImpactRow(
          icon: Icons.restaurant_rounded,
          label: '${itemsLogged * 2} recipe ideas',
          color: kPrimary,
          textColor: textColor,
        ),
        const SizedBox(height: 10),
        _ImpactRow(
          icon: Icons.spa_rounded,
          label: 'Reducing food waste',
          color: kSecondary,
          textColor: textColor,
        ),
      ],
    );
  }
}

class _ImpactRow extends StatelessWidget {
  const _ImpactRow({required this.icon, required this.label, required this.color, required this.textColor});

  final IconData icon;
  final String label;
  final Color color;
  final Color textColor;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [color.withAlpha(30), color.withAlpha(15)],
            ),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, size: 18, color: color),
        ),
        const SizedBox(width: 12),
        Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: textColor.withAlpha(180),
          ),
        ),
      ],
    );
  }
}

class _HowItWorksSection extends StatelessWidget {
  const _HowItWorksSection();

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? kDarkText : kText;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'How it works',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: textColor,
          ),
        ),
        const SizedBox(height: 16),
        _StepRow(number: '1', text: 'Tap Scan Scrap and capture a food scrap', textColor: textColor),
        const SizedBox(height: 12),
        _StepRow(number: '2', text: 'AI identifies the scrap type and logs it if confident', textColor: textColor),
        const SizedBox(height: 12),
        _StepRow(number: '3', text: 'Get recipe ideas based on your scraps and weight', textColor: textColor),
      ],
    );
  }
}

class _StepRow extends StatelessWidget {
  const _StepRow({required this.number, required this.text, required this.textColor});

  final String number;
  final String text;
  final Color textColor;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 30,
          height: 30,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [kPrimary.withAlpha(30), kPrimaryLight.withAlpha(15)],
            ),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: kPrimary.withAlpha(50)),
          ),
          child: Text(
            number,
            style: TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 14,
              color: kPrimary,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              fontSize: 13,
              color: textColor.withAlpha(170),
              height: 1.4,
            ),
          ),
        ),
      ],
    );
  }
}

class _SecondaryButton extends StatelessWidget {
  const _SecondaryButton({
    required this.onPressed,
    required this.icon,
    required this.label,
    required this.color,
  });

  final VoidCallback onPressed;
  final IconData icon;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [color.withAlpha(30), color.withAlpha(15)],
          ),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withAlpha(100)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                color: color,
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

class _InventoryTab extends StatelessWidget {
  const _InventoryTab({required this.items, required this.onRefresh, required this.textColor, required this.cardColor});

  final List<ScrapItem> items;
  final Future<void> Function() onRefresh;
  final Color textColor;
  final Color cardColor;

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return RefreshIndicator(
        onRefresh: onRefresh,
        color: kPrimary,
        backgroundColor: cardColor,
        child: ListView(
          children: [
            const SizedBox(height: 80),
            EmptyStateWithMascot(
              mascot: const EmptyBinMascot(size: 140),
              title: 'Your scrap bin is empty',
              subtitle: 'Scan food scraps and I\'ll turn them into delicious recipes!',
            ),
            const SizedBox(height: 20),
            Center(
              child: Text(
                'Pull down to refresh ↓',
                style: TextStyle(
                  fontSize: 13,
                  color: kPrimary.withAlpha(150),
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: onRefresh,
      color: kPrimary,
      backgroundColor: cardColor,
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
        itemCount: items.length,
        itemBuilder: (context, index) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: _InventoryTile(item: items[index], textColor: textColor, cardColor: cardColor),
          );
        },
      ),
    );
  }
}

class _InventoryTile extends StatelessWidget {
  const _InventoryTile({required this.item, required this.textColor, required this.cardColor});

  final ScrapItem item;
  final Color textColor;
  final Color cardColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: textColor.withAlpha(6),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [kSecondary, kSecondary.withAlpha(180)],
              ),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(
              Icons.local_florist_rounded,
              color: Colors.white,
              size: 28,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.label,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: textColor,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${item.source} • ${(item.confidence * 100).toStringAsFixed(0)}% match',
                  style: TextStyle(
                    fontSize: 13,
                    color: textColor.withAlpha(120),
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: item.manualCorrection
                  ? kAccent.withAlpha(15)
                  : kSecondary.withAlpha(15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              item.manualCorrection ? Icons.edit_rounded : Icons.check_circle_rounded,
              size: 20,
              color: item.manualCorrection ? kAccent : kSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

class _RecipeTab extends StatelessWidget {
  const _RecipeTab({
    required this.recipes,
    required this.savedRecipes,
    required this.batchLabels,
    required this.appState,
    required this.onRecipeTap,
    required this.textColor,
    required this.cardColor,
    required this.useBatchMatching,
  });

  final List<RecipeSuggestion> recipes;
  final List<SavedRecipeRecord> savedRecipes;
  final List<String> batchLabels;
  final AppState appState;
  final void Function(RecipeSuggestion) onRecipeTap;
  final bool useBatchMatching;
  final Color textColor;
  final Color cardColor;

  @override
  Widget build(BuildContext context) {
    final displaySuggestions = useBatchMatching ? recipes : recipes.take(3).toList();

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
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
                      onTap: () => appState.openRecipeDetail(savedRecipes[index]),
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 24),
        ],
        _SectionHeader(title: useBatchMatching ? 'Recipe Suggestions (Batch)' : 'Recipe Suggestions (Individual)'),
        const SizedBox(height: 12),
        if (displaySuggestions.isEmpty)
          Center(
            child: Padding(
              padding: const EdgeInsets.all(40),
              child: Column(
                children: [
                  Icon(Icons.restaurant_rounded, size: 64, color: kPrimary.withAlpha(100)),
                  const SizedBox(height: 16),
                  Text(
                    useBatchMatching
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
          ...displaySuggestions.map((recipe) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _RecipeTile(
                recipe: recipe,
                onTap: () => onRecipeTap(recipe),
                textColor: textColor,
                cardColor: cardColor,
              ),
            );
          }),
      ],
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? kDarkText : kText;

    return Text(
      title,
      style: TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w800,
        color: textColor,
        letterSpacing: -0.3,
      ),
    );
  }
}

class _SavedRecipeTile extends StatelessWidget {
  const _SavedRecipeTile({required this.savedRecipe, required this.onTap});

  final SavedRecipeRecord savedRecipe;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? kDarkText : kText;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [kPrimary.withAlpha(10), kPrimaryLight.withAlpha(10)],
          ),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: kPrimary.withAlpha(30)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.favorite_rounded, color: kAccent, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    savedRecipe.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: textColor),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              savedRecipe.summary,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(fontSize: 13, color: textColor.withAlpha(160), height: 1.4),
            ),
            const Spacer(),
            if ((savedRecipe.userNotes ?? '').isNotEmpty)
              Text(
                'Note: ${savedRecipe.userNotes}',
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(fontSize: 12, fontStyle: FontStyle.italic, color: textColor.withAlpha(120)),
              ),
          ],
        ),
      ),
    );
  }
}

class _RecipeTile extends StatelessWidget {
  const _RecipeTile({required this.recipe, required this.onTap, required this.textColor, required this.cardColor});

  final RecipeSuggestion recipe;
  final VoidCallback onTap;
  final Color textColor;
  final Color cardColor;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: textColor.withAlpha(8),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 90,
              height: 90,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [kPrimaryLight, kPrimary],
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              child: recipe.id != null && recipe.id!.isNotEmpty
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: Image.network(
                        'https://www.themealdb.com/images/ingredients/${recipe.id}.png',
                        errorBuilder: (context, error, stackTrace) {
                          return const Icon(Icons.restaurant_rounded, size: 36, color: Colors.white);
                        },
                      ),
                    )
                  : const Icon(Icons.restaurant_rounded, size: 36, color: Colors.white),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    recipe.title,
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w800,
                      color: textColor,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    recipe.summary,
                    style: TextStyle(
                      fontSize: 13,
                      color: textColor.withAlpha(140),
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: recipe.ingredients.take(3).map((ing) {
                      return Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: kPrimary.withAlpha(10),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          ing,
                          style: TextStyle(
                            fontSize: 11,
                            color: kPrimary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: kPrimary.withAlpha(10),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.arrow_forward_ios_rounded,
                color: kPrimary,
                size: 18,
              ),
            ),
          ],
        ),
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
  String? selectedLabel;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardColor = isDark ? kDarkSurface : kSurface;
    final textColor = isDark ? kDarkText : kText;

    return SafeArea(
      child: Container(
        margin: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(28),
          boxShadow: [
            BoxShadow(
              color: textColor.withAlpha(20),
              blurRadius: 30,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Padding(
          padding: EdgeInsets.only(
            left: 24,
            right: 24,
            top: 24,
            bottom: MediaQuery.of(context).viewInsets.bottom + 24,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: textColor.withAlpha(60),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'Add Scrap',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                  color: textColor,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Select the type of food scrap',
                style: TextStyle(
                  fontSize: 14,
                  color: textColor.withAlpha(140),
                ),
              ),
              const SizedBox(height: 20),
              Flexible(
                child: GridView.builder(
                  shrinkWrap: true,
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    mainAxisSpacing: 10,
                    crossAxisSpacing: 10,
                    childAspectRatio: 3,
                  ),
                  itemCount: widget.labels.length,
                  itemBuilder: (context, index) {
                    final label = widget.labels[index];
                    final isSelected = selectedLabel == label;

                    return GestureDetector(
                      onTap: () {
                        HapticFeedback.selectionClick();
                        setState(() => selectedLabel = label);
                      },
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        decoration: BoxDecoration(
                          gradient: isSelected
                              ? LinearGradient(
                                  colors: [kPrimary, kPrimaryLight],
                                )
                              : null,
                          color: isSelected ? null : textColor.withAlpha(10),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: isSelected
                                ? kPrimary
                                : textColor.withAlpha(30),
                            width: isSelected ? 2 : 1,
                          ),
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          label,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: isSelected
                                ? FontWeight.w700
                                : FontWeight.w500,
                            color: isSelected
                                ? Colors.white
                                : textColor.withAlpha(180),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 20),
              GestureDetector(
                onTap: selectedLabel == null
                    ? null
                    : () {
                        HapticFeedback.mediumImpact();
                        Navigator.of(context).pop(selectedLabel);
                      },
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 18),
                  decoration: BoxDecoration(
                    gradient: selectedLabel == null
                        ? null
                        : LinearGradient(
                            colors: [kPrimary, kPrimaryLight],
                          ),
                    color: selectedLabel == null ? textColor.withAlpha(30) : null,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(
                    'Add to Bin',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: selectedLabel == null
                          ? textColor.withAlpha(100)
                          : Colors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: 16,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
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

    return SafeArea(
      child: Container(
        margin: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(28),
          boxShadow: [
            BoxShadow(
              color: textColor.withAlpha(20),
              blurRadius: 30,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: textColor.withAlpha(60),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [kPrimary.withAlpha(30), kPrimaryLight.withAlpha(15)],
                      ),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Icon(Icons.help_outline_rounded, color: kPrimary, size: 26),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'Quick Tips',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      color: textColor,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              _TipItem(
                icon: Icons.camera_alt_rounded,
                title: 'Scan Food Scraps',
                description: 'Take photos of vegetable peels, stems, or leftovers',
                textColor: textColor,
              ),
              const SizedBox(height: 12),
              _TipItem(
                icon: Icons.check_circle_rounded,
                title: 'Auto-Detect Scraps',
                description: 'Confident detections are logged automatically',
                textColor: textColor,
              ),
              const SizedBox(height: 12),
              _TipItem(
                icon: Icons.restaurant_rounded,
                title: 'Get Recipes',
                description: 'Discover meals based on your scrap bin',
                textColor: textColor,
              ),
              const SizedBox(height: 12),
              _TipItem(
                icon: Icons.eco_rounded,
                title: 'Reduce Waste',
                description: 'Track your impact on food waste reduction',
                textColor: textColor,
              ),
              const SizedBox(height: 24),
              GestureDetector(
                onTap: () => Navigator.of(context).pop(),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 18),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [kPrimary, kPrimaryLight],
                    ),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Text(
                    'Got it!',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: 16,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TipItem extends StatelessWidget {
  const _TipItem({
    required this.icon,
    required this.title,
    required this.description,
    required this.textColor,
  });

  final IconData icon;
  final String title;
  final String description;
  final Color textColor;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [kSecondary.withAlpha(30), kSecondary.withAlpha(15)],
            ),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, size: 20, color: kSecondary),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: textColor,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                description,
                style: TextStyle(
                  fontSize: 13,
                  color: textColor.withAlpha(140),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
