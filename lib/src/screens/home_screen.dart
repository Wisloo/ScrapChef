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

// Warm earthy solid color palette
const Color kCream = Color(0xFFF6F1E8);
const Color kTerracotta = Color(0xFFB86137);
const Color kSage = Color(0xFF58765C);
const Color kDeepBrown = Color(0xFF2D1F16);
const Color kWarmBrown = Color(0xFF7B5A2A);
const Color kCardBg = Color(0xFFFDFBF7);
const Color kLightSage = Color(0xFFE5EFE4);
const Color kLightTerracotta = Color(0xFFF3E1D3);

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key, required this.appState});

  final AppState appState;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  bool _showSplash = true;

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
        builder: (_) => SettingsScreen(appState: widget.appState),
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

    return DefaultTabController(
      length: 3,
      child: Scaffold(
        backgroundColor: kCream,
        floatingActionButton: FloatingActionButton(
          onPressed: _showHelp,
          backgroundColor: kTerracotta,
          child: const Icon(Icons.help_outline, color: Colors.white),
        ),
        body: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Color(0xFFF7F2E8),
                Color(0xFFFDFBF7),
                Color(0xFFF3EEE4),
              ],
            ),
          ),
          child: NestedScrollView(
            headerSliverBuilder: (context, innerBoxIsScrolled) {
              return [
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 40, 16, 0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        GestureDetector(
                          onTap: _openSettings,
                          child: Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: kCardBg,
                              borderRadius: BorderRadius.circular(12),
                              boxShadow: [
                                BoxShadow(
                                  color: kDeepBrown.withAlpha(15),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: const Icon(
                              Icons.settings,
                              color: kDeepBrown,
                              size: 22,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                SliverToBoxAdapter(
                  child: Container(
                    margin: const EdgeInsets.fromLTRB(16, 12, 16, 12),
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: kCardBg,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: kDeepBrown.withAlpha(20),
                          blurRadius: 20,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: _HeroHeader(
                      itemsLogged: itemsLogged,
                      estimatedSavings: estimatedSavings,
                    ),
                  ),
                ),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: _ActionPanel(
                      onScan: _openScanFlow,
                      onManualAdd: _addManualItem,
                    ),
                  ),
                ),
                SliverToBoxAdapter(
                  child: Container(
                    margin: const EdgeInsets.fromLTRB(16, 20, 16, 8),
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: kCardBg,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: kDeepBrown.withAlpha(15),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: TabBar(
                      indicator: BoxDecoration(
                        color: kTerracotta,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      indicatorSize: TabBarIndicatorSize.tab,
                      labelColor: Colors.white,
                      unselectedLabelColor: kDeepBrown.withAlpha(160),
                      labelStyle: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                      ),
                      unselectedLabelStyle: const TextStyle(
                        fontWeight: FontWeight.w500,
                        fontSize: 13,
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
              ];
            },
            body: TabBarView(
              children: [
                _ScanTab(
                  outcome: outcome,
                  itemsLogged: itemsLogged,
                  onScan: _openScanFlow,
                ),
                _InventoryTab(
                  items: inventory,
                  onRefresh: () async {
                    await Future.delayed(const Duration(seconds: 1));
                  },
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
  const _HeroHeader({required this.itemsLogged, required this.estimatedSavings});

  final int itemsLogged;
  final double estimatedSavings;

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
                  const Text(
                    'ScrapChef',
                    style: TextStyle(
                      fontSize: 30,
                      fontWeight: FontWeight.w800,
                      color: kDeepBrown,
                      letterSpacing: -0.8,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Turn scraps into suppers',
                    style: TextStyle(
                      fontSize: 14,
                      color: kDeepBrown.withAlpha(140),
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: kLightTerracotta,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: kTerracotta.withAlpha(100)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.eco, size: 16, color: kTerracotta),
                  const SizedBox(width: 6),
                  Text(
                    '$itemsLogged',
                    style: const TextStyle(
                      color: kTerracotta,
                      fontWeight: FontWeight.w700,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Divider(color: kDeepBrown.withAlpha(16), thickness: 1),
        const SizedBox(height: 12),
        Row(
          children: [
            _StatItem(
              icon: Icons.check_circle,
              label: '$itemsLogged scraps tracked',
              color: kSage,
            ),
            const SizedBox(width: 24),
            _StatItem(
              icon: Icons.savings,
              label: '₱${estimatedSavings.toStringAsFixed(0)} saved',
              color: kTerracotta,
            ),
          ],
        ),
      ],
    );
  }
}

class _StatItem extends StatelessWidget {
  const _StatItem({required this.icon, required this.label, required this.color});

  final IconData icon;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: color.withAlpha(30),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, size: 14, color: color),
        ),
        const SizedBox(width: 8),
        Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: kDeepBrown.withAlpha(200),
          ),
        ),
      ],
    );
  }
}

class _ActionPanel extends StatelessWidget {
  const _ActionPanel({required this.onScan, required this.onManualAdd});

  final VoidCallback onScan;
  final VoidCallback onManualAdd;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _ActionButton(
            onPressed: onScan,
            icon: Icons.camera_alt,
              label: 'Scan Scrap',
            color: kTerracotta,
            isPrimary: true,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _ActionButton(
            onPressed: onManualAdd,
            icon: Icons.add,
              label: 'Add Manually',
            color: kSage,
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
            padding: const EdgeInsets.symmetric(vertical: 16),
            decoration: BoxDecoration(
              color: widget.isPrimary ? widget.color : Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: widget.isPrimary
                  ? null
                  : Border.all(color: widget.color.withAlpha(150)),
              boxShadow: [
                BoxShadow(
                  color: widget.color.withAlpha(widget.isPrimary ? 60 : 30),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  widget.icon,
                  color: widget.isPrimary ? Colors.white : widget.color,
                  size: 22,
                ),
                const SizedBox(width: 8),
                Text(
                  widget.label,
                  style: TextStyle(
                    color: widget.isPrimary ? Colors.white : widget.color,
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
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
  });

  final ScanOutcome? outcome;
  final int itemsLogged;
  final VoidCallback onScan;

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
                      color: kTerracotta.withAlpha(30),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Icon(
                      Icons.camera_enhance,
                      color: kTerracotta,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Ready to scan',
                          style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w700,
                            color: kDeepBrown,
                          ),
                        ),
                        Text(
                          'Capture scraps, classify them, and get recipe matches',
                          style: TextStyle(
                            fontSize: 13,
                            color: kDeepBrown.withAlpha(140),
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
                  color: kDeepBrown.withAlpha(140),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        if (lastOutcome != null) ...[
          _Card(
            color: lastOutcome.requiresReview ? kLightTerracotta : kLightSage,
            child: _LatestScanCard(outcome: lastOutcome),
          ),
          const SizedBox(height: 16),
        ],
        _Card(
          color: kLightSage,
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
  const _Card({required this.child, this.color});

  final Widget child;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: color ?? kCardBg,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: kDeepBrown.withAlpha(15),
            blurRadius: 16,
            offset: const Offset(0, 6),
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
    final statusColor = outcome.requiresReview ? kTerracotta : kSage;
    final statusText = outcome.requiresReview ? 'Needs Review' : 'Saved';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Latest Scan',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: kDeepBrown,
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: statusColor,
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
          style: const TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w800,
            color: kDeepBrown,
          ),
        ),
        const SizedBox(height: 12),
        _ConfidenceMeter(confidence: outcome.confidence),
        const SizedBox(height: 10),
        Text(
          _getMessage(),
          style: TextStyle(
            fontSize: 13,
            color: kDeepBrown.withAlpha(160),
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
                color: kDeepBrown.withAlpha(140),
              ),
            ),
            Text(
              '$percentage%',
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: kTerracotta,
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
                      ? kTerracotta
                      : kDeepBrown.withAlpha(30),
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _ImpactLedger extends StatelessWidget {
  const _ImpactLedger({required this.itemsLogged});

  final int itemsLogged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: kSage.withAlpha(30),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.eco, size: 20, color: kSage),
            ),
            const SizedBox(width: 12),
            const Text(
              'Your Impact',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: kDeepBrown,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        _ImpactRow(
          icon: Icons.check_circle,
          label: '$itemsLogged scraps scanned',
          color: kSage,
        ),
        const SizedBox(height: 10),
        _ImpactRow(
          icon: Icons.restaurant,
          label: '${itemsLogged * 2} recipe ideas',
          color: kTerracotta,
        ),
        const SizedBox(height: 10),
        _ImpactRow(
          icon: Icons.spa,
          label: 'Reducing food waste',
          color: kSage,
        ),
      ],
    );
  }
}

class _ImpactRow extends StatelessWidget {
  const _ImpactRow({required this.icon, required this.label, required this.color});

  final IconData icon;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: color.withAlpha(25),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, size: 16, color: color),
        ),
        const SizedBox(width: 12),
        Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: kDeepBrown.withAlpha(180),
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'How it works',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: kDeepBrown,
          ),
        ),
        const SizedBox(height: 16),
        const _StepRow(number: '1', text: 'Tap Scan Scrap and capture a food scrap'),
        const SizedBox(height: 12),
        const _StepRow(number: '2', text: 'AI identifies the scrap type and logs it if confident'),
        const SizedBox(height: 12),
        const _StepRow(number: '3', text: 'Get recipe ideas based on your scraps and weight'),
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
      children: [
        Container(
          width: 28,
          height: 28,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: kTerracotta.withAlpha(30),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: kTerracotta.withAlpha(80)),
          ),
          child: Text(
            number,
            style: const TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 13,
              color: kTerracotta,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              fontSize: 13,
              color: kDeepBrown.withAlpha(170),
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
          color: color.withAlpha(30),
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
  const _InventoryTab({required this.items, required this.onRefresh});

  final List<ScrapItem> items;
  final Future<void> Function() onRefresh;

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return RefreshIndicator(
        onRefresh: onRefresh,
        color: kTerracotta,
        backgroundColor: kCardBg,
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
                  color: kTerracotta.withAlpha(150),
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
      color: kTerracotta,
      backgroundColor: kCardBg,
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
        itemCount: items.length,
        itemBuilder: (context, index) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: _InventoryTile(item: items[index]),
          );
        },
      ),
    );
  }
}

class _InventoryTile extends StatelessWidget {
  const _InventoryTile({required this.item});

  final ScrapItem item;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: kCardBg,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: kDeepBrown.withAlpha(12),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: kSage.withAlpha(40),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(
              Icons.local_florist,
              color: kSage,
              size: 26,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.label,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: kDeepBrown,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${item.source} • ${(item.confidence * 100).toStringAsFixed(0)}% match',
                  style: TextStyle(
                    fontSize: 13,
                    color: kDeepBrown.withAlpha(130),
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: item.manualCorrection
                  ? kTerracotta.withAlpha(30)
                  : kSage.withAlpha(30),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              item.manualCorrection ? Icons.edit : Icons.check,
              size: 18,
              color: item.manualCorrection ? kTerracotta : kSage,
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
  });

  final List<RecipeSuggestion> recipes;
  final List<SavedRecipeRecord> savedRecipes;
  final List<String> batchLabels;
  final AppState appState;
  final void Function(RecipeSuggestion) onRecipeTap;

  @override
  Widget build(BuildContext context) {
    if (recipes.isEmpty && savedRecipes.isEmpty) {
      return Center(
        child: EmptyStateWithMascot(
          mascot: const NoRecipesMascot(size: 140),
          title: 'No recipes yet',
          subtitle: 'Scan some scraps and I\'ll cook up recipe ideas for you!',
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
      children: [
        if (savedRecipes.isNotEmpty) ...[
          _SectionHeader(title: 'Saved recipes'),
          const SizedBox(height: 12),
          SizedBox(
            height: 180,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: savedRecipes.length,
              separatorBuilder: (_, __) => const SizedBox(width: 12),
              itemBuilder: (context, index) {
                final saved = savedRecipes[index];
                return SizedBox(
                  width: 250,
                  child: _SavedRecipeTile(
                    savedRecipe: saved,
                    onTap: () {
                      onRecipeTap(
                        RecipeSuggestion(
                          id: saved.recipeId,
                          title: saved.title,
                          summary: saved.summary,
                          ingredients: saved.ingredients,
                          matchReason: saved.matchReason,
                          chefNote: saved.chefNote,
                        ),
                      );
                    },
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 18),
          _SectionHeader(title: 'Recommended for you'),
          const SizedBox(height: 12),
        ],
        ...recipes.map((recipe) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 14),
            child: _RecipeTile(
              recipe: recipe,
              onTap: () => onRecipeTap(recipe),
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
    return Text(
      title,
      style: const TextStyle(
        fontSize: 15,
        fontWeight: FontWeight.w800,
        color: kDeepBrown,
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
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: kLightSage,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: kSage.withAlpha(50)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.favorite, color: kTerracotta, size: 18),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    savedRecipe.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: kDeepBrown),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              savedRecipe.summary,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(fontSize: 13, color: kDeepBrown.withAlpha(170), height: 1.4),
            ),
            const Spacer(),
            if ((savedRecipe.userNotes ?? '').isNotEmpty)
              Text(
                'Note: ${savedRecipe.userNotes}',
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(fontSize: 12, fontStyle: FontStyle.italic, color: kDeepBrown.withAlpha(140)),
              ),
          ],
        ),
      ),
    );
  }
}

class _RecipeTile extends StatelessWidget {
  const _RecipeTile({required this.recipe, required this.onTap});

  final RecipeSuggestion recipe;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: kCardBg,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: kDeepBrown.withAlpha(15),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        recipe.title,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: kDeepBrown,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        recipe.matchReason,
                        style: TextStyle(
                          fontSize: 13,
                          color: kDeepBrown.withAlpha(140),
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: kTerracotta.withAlpha(30),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.restaurant,
                    size: 20,
                    color: kTerracotta,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Text(
              recipe.summary,
              style: TextStyle(
                fontSize: 14,
                color: kDeepBrown.withAlpha(160),
                height: 1.5,
              ),
            ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: recipe.ingredients.map((ingredient) {
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: kCream,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: kDeepBrown.withAlpha(20)),
                ),
                child: Text(
                  ingredient,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: kDeepBrown.withAlpha(180),
                  ),
                ),
              );
            }).toList(),
          ),
          if (recipe.chefNote != null) ...[
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: kLightTerracotta,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: kTerracotta.withAlpha(50)),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.lightbulb,
                    size: 18,
                    color: kTerracotta.withAlpha(200),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      recipe.chefNote!,
                      style: TextStyle(
                        fontSize: 13,
                        fontStyle: FontStyle.italic,
                        color: kDeepBrown.withAlpha(160),
                        height: 1.5,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
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
    return SafeArea(
      child: Container(
        margin: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: kCardBg,
          borderRadius: BorderRadius.circular(28),
          boxShadow: [
            BoxShadow(
              color: kDeepBrown.withAlpha(30),
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
                    color: kDeepBrown.withAlpha(60),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'Add Scrap',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                  color: kDeepBrown,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Select the type of food scrap',
                style: TextStyle(
                  fontSize: 14,
                  color: kDeepBrown.withAlpha(140),
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
                          color: isSelected ? kTerracotta : kCream,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: isSelected
                                ? kTerracotta
                                : kDeepBrown.withAlpha(30),
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
                                : kDeepBrown.withAlpha(180),
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
                    color: selectedLabel == null
                        ? kDeepBrown.withAlpha(30)
                        : kTerracotta,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(
                    'Add to Bin',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: selectedLabel == null
                          ? kDeepBrown.withAlpha(100)
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
    return SafeArea(
      child: Container(
        margin: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: kCardBg,
          borderRadius: BorderRadius.circular(28),
          boxShadow: [
            BoxShadow(
              color: kDeepBrown.withAlpha(30),
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
                    color: kDeepBrown.withAlpha(60),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: kTerracotta.withAlpha(30),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.help, color: kTerracotta, size: 24),
                  ),
                  const SizedBox(width: 12),
                  const Text(
                    'Quick Tips',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      color: kDeepBrown,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              _TipItem(
                icon: Icons.camera_alt,
                title: 'Scan Food Scraps',
                description: 'Take photos of vegetable peels, stems, or leftovers',
              ),
              const SizedBox(height: 12),
              _TipItem(
                icon: Icons.check_circle,
                title: 'Auto-Detect Scraps',
                description: 'Confident detections are logged automatically',
              ),
              const SizedBox(height: 12),
              _TipItem(
                icon: Icons.restaurant,
                title: 'Get Recipes',
                description: 'Discover meals based on your scrap bin',
              ),
              const SizedBox(height: 12),
              _TipItem(
                icon: Icons.eco,
                title: 'Reduce Waste',
                description: 'Track your impact on food waste reduction',
              ),
              const SizedBox(height: 24),
              GestureDetector(
                onTap: () => Navigator.of(context).pop(),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  decoration: BoxDecoration(
                    color: kSage,
                    borderRadius: BorderRadius.circular(14),
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
  });

  final IconData icon;
  final String title;
  final String description;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: kSage.withAlpha(30),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, size: 18, color: kSage),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: kDeepBrown,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                description,
                style: TextStyle(
                  fontSize: 13,
                  color: kDeepBrown.withAlpha(140),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
