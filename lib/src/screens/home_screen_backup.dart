import 'package:flutter/material.dart';

import '../models.dart';
import '../state/app_state.dart';
import 'manual_verify_screen.dart';
import 'scan_screen.dart';

// Food-inspired warm palette
const Color kRecipeWarmBrown = Color(0xFF8B7355);    // Primary
const Color kCookingTerracotta = Color(0xFFC17A4A);  // Secondary
const Color kSketchCharcoal = Color(0xFF6B5D4F);     // Accent
const Color kPaperCream = Color(0xFFFAF8F5);         // Background
const Color kHerbSage = Color(0xFFD4E5D0);           // Success
const Color kCaptionGray = Color(0xFF9A8B7E);        // Muted text
const Color kInkDark = Color(0xFF3C3C3C);            // Very dark

// Legacy names for compatibility
const Color kPrimaryGreen = kRecipeWarmBrown;
const Color kDarkGreen = kSketchCharcoal;
const Color kAccentOrange = kCookingTerracotta;
const Color kLightBeige = kPaperCream;
const Color kMintGreen = kHerbSage;

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key, required this.appState, required this.onThemeChanged});

  final AppState appState;
  final ValueChanged<bool> onThemeChanged;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  void initState() {
    super.initState();
    widget.appState.addListener(_onAppStateChanged);
  }

  @override
  void dispose() {
    widget.appState.removeListener(_onAppStateChanged);
    super.dispose();
  }

  void _onAppStateChanged() {
    if (mounted) {
      setState(() {});
    }
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

    if (outcome.requiresReview) {
      await Navigator.of(context).push(
        MaterialPageRoute(
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

  @override
  Widget build(BuildContext context) {
    final outcome = widget.appState.lastOutcome;
    final inventory = widget.appState.inventory;
    final suggestions = widget.appState.activeRecipeSuggestions;
    final latestBatchLabels = widget.appState.latestBatchLabels;
    final itemsLogged = widget.appState.itemsLogged;
    final estimatedSavings = widget.appState.estimatedSavings;

    return DefaultTabController(
      length: 3,
      child: Scaffold(
        backgroundColor: kPaperCream,
        body: SafeArea(
          child: Column(
            children: <Widget>[
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
                child: _HeroHeader(
                  itemsLogged: itemsLogged,
                  estimatedSavings: estimatedSavings,
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: _ActionPanel(
                  onScan: _openScanFlow,
                  onManualAdd: _addManualItem,
                ),
              ),
              const SizedBox(height: 12),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16),
                child: TabBar(
                  labelColor: kRecipeWarmBrown,
                  unselectedLabelColor: kCaptionGray,
                  indicatorColor: kCookingTerracotta,
                  indicatorWeight: 3,
                  tabs: <Widget>[
                    Tab(text: 'Scan'),
                    Tab(text: 'Bin'),
                    Tab(text: 'Recipes'),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              Expanded(
                child: TabBarView(
                  children: <Widget>[
                    _ScanTab(outcome: outcome, itemsLogged: itemsLogged),
                    _InventoryTab(items: inventory),
                    _RecipeTab(recipes: suggestions, batchLabels: latestBatchLabels),
                  ],
                ),
              ),
            ],
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
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(
          color: kSketchCharcoal,
          width: 1.5,
          strokeAlign: BorderSide.strokeAlignOutside,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: const <BoxShadow>[
          BoxShadow(
            color: Color.fromRGBO(0, 0, 0, 0.08),
            blurRadius: 12,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      'ScrapChef',
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                            color: kRecipeWarmBrown,
                            fontWeight: FontWeight.w800,
                            fontFamily: 'serif',
                          ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Turn scraps into suppers',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: kCaptionGray,
                            fontStyle: FontStyle.italic,
                          ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: const Color.fromRGBO(193, 122, 74, 0.12),
                  border: Border.all(
                    color: kCookingTerracotta,
                    width: 1.2,
                  ),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '$itemsLogged',
                  style: const TextStyle(
                    color: kCookingTerracotta,
                    fontWeight: FontWeight.w700,
                    fontSize: 16,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            height: 1,
            color: const Color.fromRGBO(107, 93, 79, 0.15),
            margin: const EdgeInsets.symmetric(vertical: 4),
          ),
          const SizedBox(height: 12),
          Row(
            children: <Widget>[
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      '✓ $itemsLogged scraps scanned',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: kSketchCharcoal,
                          ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '✓ Estimated ₱${estimatedSavings.toStringAsFixed(0)} saved',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: kSketchCharcoal,
                          ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
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
      children: <Widget>[
        Expanded(
          child: GestureDetector(
            onTap: onScan,
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
              decoration: BoxDecoration(
                color: kCookingTerracotta,
                border: Border.all(
                  color: const Color.fromRGBO(107, 93, 79, 0.3),
                  width: 1.5,
                ),
                borderRadius: BorderRadius.circular(12),
                boxShadow: const <BoxShadow>[
                  BoxShadow(
                    color: Color.fromRGBO(193, 122, 74, 0.3),
                    blurRadius: 8,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  const Icon(Icons.photo_camera_outlined, color: Colors.white, size: 22),
                  const SizedBox(width: 10),
                  Text(
                    'Open camera',
                    style: Theme.of(context).textTheme.labelLarge?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: GestureDetector(
            onTap: onManualAdd,
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
              decoration: BoxDecoration(
                color: const Color.fromRGBO(193, 122, 74, 0.06),
                border: Border.all(
                  color: kCookingTerracotta,
                  width: 1.5,
                  strokeAlign: BorderSide.strokeAlignCenter,
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  const Icon(Icons.add_circle_outline, color: kCookingTerracotta, size: 22),
                  const SizedBox(width: 10),
                  Text(
                    'Add scrap',
                    style: Theme.of(context).textTheme.labelLarge?.copyWith(
                          color: kCookingTerracotta,
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _ScanTab extends StatelessWidget {
  const _ScanTab({required this.outcome, required this.itemsLogged});

  final ScanOutcome? outcome;
  final int itemsLogged;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      children: <Widget>[
        _SectionCard(
          title: 'Scan first',
          subtitle: 'Camera capture is the main action.',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                'Take a photo of a food scrap, then confirm the label.',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(height: 1.4),
              ),
              const SizedBox(height: 12),
              Row(
                children: <Widget>[
                  Expanded(child: _MetricCard(label: 'Logged', value: '$itemsLogged', hint: 'items')),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _MetricCard(
                      label: 'Status',
                      value: outcome == null ? 'Ready' : (outcome!.requiresReview ? 'Review' : 'Saved'),
                      hint: 'scan flow',
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        if (outcome != null) ...<Widget>[
          _LatestScanCard(outcome: outcome!),
          const SizedBox(height: 14),
        ],
        _ImpactLedger(itemsLogged: itemsLogged),
        const SizedBox(height: 14),
        const _SectionCard(
          title: 'How it works',
          subtitle: 'A shorter interaction focused on scanning.',
          child: Column(
            children: <Widget>[
              _StepRow(number: '1', text: 'Open the camera and take a photo'),
              SizedBox(height: 10),
              _StepRow(number: '2', text: 'Confirm the scrap label'),
              SizedBox(height: 10),
              _StepRow(number: '3', text: 'Save to your scrap bin and get recipe ideas'),
            ],
          ),
        ),
      ],
    );
  }
}

class _InventoryTab extends StatelessWidget {
  const _InventoryTab({required this.items});

  final List<ScrapItem> items;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      children: <Widget>[
        _SectionCard(
          title: 'Scrap bin',
          subtitle: 'What you have logged so far.',
          child: items.isEmpty
              ? const Text('No scraps logged yet. Use the camera tab to add one.')
              : Column(
                  children: items
                      .map(
                        (item) => Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: _InventoryTile(item: item),
                        ),
                      )
                      .toList(),
                ),
        ),
      ],
    );
  }
}

class _RecipeTab extends StatelessWidget {
  const _RecipeTab({required this.recipes, required this.batchLabels});

  final List<RecipeSuggestion> recipes;
  final List<String> batchLabels;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      children: <Widget>[
        _SectionCard(
          title: 'Recipe ideas',
          subtitle: batchLabels.isEmpty
              ? 'Simple matches based on what is in the bin.'
              : 'Based on your latest batch: ${batchLabels.join(', ')}',
          child: recipes.isEmpty
              ? const Text('Log a scrap to unlock recipe ideas.')
              : Column(
                  children: recipes
                      .map(
                        (recipe) => Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: _RecipeTile(recipe: recipe),
                        ),
                      )
                      .toList(),
                ),
        ),
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
            color: const Color.fromRGBO(139, 115, 85, 0.12),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(number, style: const TextStyle(fontWeight: FontWeight.w700, color: kDarkGreen)),
        ),
        const SizedBox(width: 10),
        Expanded(child: Text(text, style: Theme.of(context).textTheme.bodyMedium)),
      ],
    );
  }
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({required this.label, required this.value, required this.hint});

  final String label;
  final String value;
  final String hint;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(
          color: const Color.fromRGBO(107, 93, 79, 0.12),
          width: 1,
        ),
        borderRadius: BorderRadius.circular(14),
        boxShadow: const <BoxShadow>[
          BoxShadow(
            color: Color.fromRGBO(0, 0, 0, 0.05),
            blurRadius: 6,
            offset: Offset(0, 1),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: kCaptionGray,
                  fontWeight: FontWeight.w600,
                ),
          ),
          const SizedBox(height: 10),
          Text(
            value,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: kRecipeWarmBrown,
                  letterSpacing: -0.3,
                ),
          ),
          const SizedBox(height: 4),
          Text(
            hint,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: kCaptionGray,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }
}

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
                    color: kSketchCharcoal,
                    fontWeight: FontWeight.w600,
                  ),
            ),
            Text(
              '$percentage%',
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: kCookingTerracotta,
                    fontWeight: FontWeight.w700,
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
                  color: index < filledSegments ? kCookingTerracotta : const Color.fromRGBO(154, 139, 126, 0.2),
                  borderRadius: BorderRadius.circular(2),
                  border: Border.all(
                    color: const Color.fromRGBO(107, 93, 79, 0.1),
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
  const _SectionCard({required this.title, required this.subtitle, required this.child});

  final String title;
  final String subtitle;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(
          color: const Color.fromRGBO(107, 93, 79, 0.15),
          width: 1.5,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: const <BoxShadow>[
          BoxShadow(
            color: Color.fromRGBO(0, 0, 0, 0.06),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            title,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: kRecipeWarmBrown,
                  letterSpacing: -0.3,
                ),
          ),
          const SizedBox(height: 6),
          Text(
            subtitle,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: kCaptionGray,
                  fontStyle: FontStyle.italic,
                ),
          ),
          const SizedBox(height: 18),
          child,
        ],
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
    final statusColor = outcome.requiresReview ? kCookingTerracotta : kHerbSage;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: statusColor.withAlpha(18),
        border: Border.all(
          color: statusColor.withAlpha(64),
          width: 1.5,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: statusColor.withAlpha(25),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: <Widget>[
              Text(
                'Latest scan',
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: kRecipeWarmBrown,
                      fontWeight: FontWeight.w700,
                    ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: statusColor,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  outcome.requiresReview ? 'Review' : 'Saved',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
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
                  fontWeight: FontWeight.w800,
                  color: kRecipeWarmBrown,
                  letterSpacing: -0.3,
                ),
          ),
          const SizedBox(height: 12),
          _SketchConfidenceMeter(confidence: outcome.confidence),
          const SizedBox(height: 12),
          Text(
            _getEncouragementMessage(outcome.requiresReview),
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: kSketchCharcoal,
                  fontStyle: FontStyle.italic,
                ),
          ),
          if (outcome.note != null) ...<Widget>[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color.fromRGBO(255, 255, 255, 0.5),
                border: Border.all(
                  color: const Color.fromRGBO(107, 93, 79, 0.1),
                  width: 1,
                ),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                outcome.note!,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: kSketchCharcoal,
                    ),
              ),
            ),
          ],
        ],
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
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(
          color: const Color.fromRGBO(107, 93, 79, 0.12),
          width: 1.5,
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
              color: kHerbSage,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: const Color.fromRGBO(139, 115, 85, 0.2),
                width: 1,
              ),
            ),
            child: const Icon(Icons.local_florist_outlined, color: kRecipeWarmBrown, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  item.label,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: kRecipeWarmBrown,
                      ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${item.source} • ${(item.confidence * 100).toStringAsFixed(0)}%',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: kCaptionGray,
                      ),
                ),
              ],
            ),
          ),
          Icon(
            item.manualCorrection ? Icons.edit : Icons.check_circle,
            color: item.manualCorrection ? kCookingTerracotta : kHerbSage,
            size: 20,
          ),
        ],
      ),
    );
  }
}

class _RecipeTile extends StatelessWidget {
  const _RecipeTile({required this.recipe});

  final RecipeSuggestion recipe;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color.fromRGBO(212, 229, 208, 0.25),
        border: Border.all(
          color: const Color.fromRGBO(139, 115, 85, 0.2),
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
                        fontWeight: FontWeight.w800,
                        color: kRecipeWarmBrown,
                        letterSpacing: -0.3,
                      ),
                ),
              ),
              const SizedBox(width: 10),
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: const Color.fromRGBO(193, 122, 74, 0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.restaurant_menu, size: 18, color: kCookingTerracotta),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            recipe.summary,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: kSketchCharcoal,
                  height: 1.5,
                ),
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: recipe.ingredients
                .map(
                  (ingredient) => Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: const Color.fromRGBO(255, 255, 255, 0.7),
                      border: Border.all(
                        color: const Color.fromRGBO(139, 115, 85, 0.15),
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
                            color: kRecipeWarmBrown,
                            fontWeight: FontWeight.w500,
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
                color: const Color.fromRGBO(193, 122, 74, 0.2),
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
                        color: kCookingTerracotta,
                        fontWeight: FontWeight.w600,
                      ),
                ),
                const SizedBox(height: 4),
                Text(
                  recipe.matchReason,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: kSketchCharcoal,
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
                color: const Color.fromRGBO(193, 122, 74, 0.1),
                border: Border.all(
                  color: const Color.fromRGBO(193, 122, 74, 0.25),
                  width: 1,
                ),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Row(
                    children: <Widget>[
                      const Icon(Icons.note_outlined, size: 16, color: kCookingTerracotta),
                      const SizedBox(width: 8),
                      Text(
                        'Chef note',
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                              color: kCookingTerracotta,
                              fontWeight: FontWeight.w700,
                            ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    recipe.chefNote!,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: kSketchCharcoal,
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
    );
  }
}

class _ImpactLedger extends StatelessWidget {
  const _ImpactLedger({required this.itemsLogged});

  final int itemsLogged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(
          color: kHerbSage,
          width: 2,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: const <BoxShadow>[
          BoxShadow(
            color: Color.fromRGBO(212, 229, 208, 0.12),
            blurRadius: 10,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: const Color.fromRGBO(212, 229, 208, 0.4),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.eco, size: 18, color: kHerbSage),
              ),
              const SizedBox(width: 12),
              Text(
                'Your impact so far',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                      color: kRecipeWarmBrown,
                      letterSpacing: -0.3,
                    ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _ImpactRow(icon: Icons.check_circle, label: '$itemsLogged scraps scanned', color: kHerbSage),
          const SizedBox(height: 12),
          _ImpactRow(
            icon: Icons.restaurant_menu,
            label: '${itemsLogged > 0 ? (itemsLogged * 2) : 0} recipe ideas discovered',
            color: kCookingTerracotta,
          ),
          const SizedBox(height: 12),
          const _ImpactRow(
            icon: Icons.savings,
            label: 'Help reducing food waste',
            color: kHerbSage,
          ),
        ],
      ),
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
                  color: kSketchCharcoal,
                  fontWeight: FontWeight.w500,
                ),
          ),
        ),
      ],
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
        padding: EdgeInsets.only(
          left: 16,
          right: 16,
          top: 16,
          bottom: MediaQuery.of(context).viewInsets.bottom + 16,
        ),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              'Add manually',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 8),
            Text(
              'Choose a scrap type if you do not want to use the camera.',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.grey),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 220,
              child: GridView.builder(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  mainAxisSpacing: 8,
                  crossAxisSpacing: 8,
                  childAspectRatio: 3.4,
                ),
                itemCount: widget.labels.length,
                itemBuilder: (context, index) {
                  final label = widget.labels[index];
                  return Align(
                    alignment: Alignment.centerLeft,
                    child: ChoiceChip(
                      label: Text(label),
                      selected: selectedLabel == label,
                      onSelected: (_) => setState(() => selectedLabel = label),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: selectedLabel == null
                    ? null
                    : () {
                        Navigator.of(context).pop(selectedLabel);
                      },
                child: const Text('Add to scrap bin'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
