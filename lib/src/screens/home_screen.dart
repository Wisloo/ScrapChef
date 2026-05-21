import 'package:flutter/material.dart';
import '../models.dart';
import '../state/app_state.dart';
import '../services/sound_service.dart';
import 'manual_verify_screen.dart';
import 'scan_screen.dart';
import 'settings_screen.dart';
import 'recipe_list_screen.dart';
import '../theme/app_theme.dart';

// Modern color palette - using theme colors directly

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key, required this.appState, required this.onThemeChanged, required this.isDarkMode});

  final AppState appState;
  final ValueChanged<bool> onThemeChanged;
  final bool isDarkMode;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with SingleTickerProviderStateMixin {
  late AnimationController _heroAnimationController;
  late Animation<double> _heroAnimation;

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
    // Navigate to recipes screen instead of switching tabs
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
      return;
    }

    final label = outcome.predictedLabel;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Logged $label — tap Find Recipes for ideas.'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _openSettings() {
    SoundService.playClick();
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => SettingsScreen(
          appState: widget.appState,
          onThemeChanged: widget.onThemeChanged,
          isDarkMode: widget.isDarkMode,
        ),
      ),
    );
  }

  void _openRecipes(List<String> labels) {
    SoundService.playClick();
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => RecipeListScreen(
          appState: widget.appState,
          labels: labels,
        ),
      ),
    );
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
        body: CustomScrollView(
          slivers: <Widget>[
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
                child: FadeTransition(
                  opacity: _heroAnimation,
                  child: _HeroHeader(
                    itemsLogged: itemsLogged,
                    estimatedSavings: estimatedSavings,
                    onSettingsTap: _openSettings,
                  ),
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: _ActionPanel(
                  onScan: _openScanFlow,
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: const SizedBox(height: 12),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: TabBar(
                  labelColor: Theme.of(context).colorScheme.primary,
                  unselectedLabelColor: Theme.of(context).colorScheme.onSurface.withAlpha(153),
                  indicatorColor: Theme.of(context).colorScheme.secondary,
                  indicatorWeight: 3,
                  tabs: const <Widget>[
                    Tab(text: 'Scan'),
                    Tab(text: 'Bin'),
                  ],
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: const SizedBox(height: 12),
            ),
            SliverFillRemaining(
              child: TabBarView(
                children: <Widget>[
                  _ScanTab(outcome: outcome, itemsLogged: itemsLogged),
                  _InventoryTab(items: inventory, onBatchSelect: _onBatchSelect, appState: widget.appState, onOpenRecipes: _openRecipes),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HeroHeader extends StatelessWidget {
  const _HeroHeader({required this.itemsLogged, required this.estimatedSavings, required this.onSettingsTap});

  final int itemsLogged;
  final double estimatedSavings;
  final VoidCallback onSettingsTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
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
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        'ScrapChef',
                        style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                              color: Theme.of(context).colorScheme.primary,
                              fontWeight: FontWeight.w800,
                            ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Turn scraps into suppers',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Theme.of(context).colorScheme.onSurface.withAlpha(153),
                              fontStyle: FontStyle.italic,
                            ),
                      ),
                    ],
                  ),
                ),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.primary.withAlpha(30),
                        border: Border.all(
                          color: Theme.of(context).colorScheme.primary,
                          width: 1.2,
                        ),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        '$itemsLogged',
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.primary,
                          fontWeight: FontWeight.w700,
                          fontSize: 16,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    TextButton(
                      onPressed: onSettingsTap,
                      child: Icon(
                        Icons.settings_outlined,
                        color: Theme.of(context).colorScheme.onSurface,
                        size: 20,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 16),
            Divider(
              color: Theme.of(context).colorScheme.onSurface.withAlpha(15),
              thickness: 1,
              indent: 4,
              endIndent: 4,
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
                              color: Theme.of(context).colorScheme.onSurface,
                            ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '✓ Estimated ₱${estimatedSavings.toStringAsFixed(0)} saved',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Theme.of(context).colorScheme.onSurface,
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
    return FilledButton(
      onPressed: onScan,
      style: FilledButton.styleFrom(
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Theme.of(context).colorScheme.onPrimary,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),
      child: Text(
        'Open camera',
        style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
            ),
      ),
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

class _InventoryTab extends StatefulWidget {
  const _InventoryTab({required this.items, required this.onBatchSelect, required this.appState, required this.onOpenRecipes});

  final List<ScrapItem> items;
  final Function(List<String>) onBatchSelect;
  final AppState appState;
  final Function(List<String>) onOpenRecipes;

  @override
  State<_InventoryTab> createState() => _InventoryTabState();
}

class _InventoryTabState extends State<_InventoryTab> {
  final Set<String> _selectedItems = {};

  void _toggleSelection(String label) {
    setState(() {
      if (_selectedItems.contains(label)) {
        _selectedItems.remove(label);
      } else {
        _selectedItems.add(label);
      }
    });
  }

  void _clearSelection() {
    setState(() {
      _selectedItems.clear();
    });
  }

  void _findRecipesForSelected() {
    if (_selectedItems.isNotEmpty) {
      SoundService.playClick();
      widget.onOpenRecipes(_selectedItems.toList());
    }
  }

  void _findRecipesForAll() {
    if (widget.items.isNotEmpty) {
      SoundService.playClick();
      final labels = widget.items.map((item) => item.label).toList();
      widget.onOpenRecipes(labels);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 12, 24, 8),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  widget.items.isEmpty ? 'Scrap bin is empty' : '${widget.items.length} items',
                  style: TextStyle(
                    color: kSketchCharcoal,
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                  ),
                ),
              ),
              if (widget.items.isNotEmpty) ...[
                TextButton(
                  onPressed: () {
                    showDialog(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: const Text('Clear Scrap Bin?'),
                        content: const Text('This will remove all items from your scrap bin.'),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: const Text('Cancel'),
                          ),
                          TextButton(
                            onPressed: () {
                              widget.appState.clearBin();
                              Navigator.pop(context);
                              _clearSelection();
                            },
                            child: const Text('Clear', style: TextStyle(color: Colors.red)),
                          ),
                        ],
                      ),
                    );
                  },
                  child: Text(
                    'Clear All',
                    style: TextStyle(color: kCookingTerracotta, fontWeight: FontWeight.w600),
                  ),
                ),
                const SizedBox(width: 12),
                FilledButton(
                  onPressed: _findRecipesForAll,
                  style: FilledButton.styleFrom(
                    backgroundColor: Theme.of(context).colorScheme.primary,
                    foregroundColor: Theme.of(context).colorScheme.onPrimary,
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: Text(
                    'Find Recipes',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                ),
              ],
            ],
          ),
        ),
        if (_selectedItems.isNotEmpty)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    '${_selectedItems.length} item${_selectedItems.length == 1 ? '' : 's'} selected',
                    style: TextStyle(
                      color: kCookingTerracotta,
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                    ),
                  ),
                ),
                TextButton(
                  onPressed: _clearSelection,
                  child: Text(
                    'Clear Selection',
                    style: TextStyle(color: kCaptionGray),
                  ),
                ),
                const SizedBox(width: 8),
                FilledButton(
                  onPressed: _findRecipesForSelected,
                  style: FilledButton.styleFrom(
                    backgroundColor: Theme.of(context).colorScheme.primary,
                    foregroundColor: Theme.of(context).colorScheme.onPrimary,
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: Text(
                    'Find Recipes',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                ),
              ],
            ),
          ),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            children: <Widget>[
              _SectionCard(
                title: 'Scrap bin',
                subtitle: _selectedItems.isEmpty
                    ? 'Tap items to select multiple for batch recipe matching.'
                    : 'Select more items or tap "Find Recipes".',
                child: widget.items.isEmpty
                    ? const Text('No scraps logged yet. Use the camera tab to add one.')
                    : Column(
                        children: widget.items
                            .map(
                              (item) => Padding(
                                padding: const EdgeInsets.only(bottom: 10),
                                child: _InventoryTile(
                                  item: item,
                                  isSelected: _selectedItems.contains(item.label),
                                  onTap: () => _toggleSelection(item.label),
                                ),
                              ),
                            )
                            .toList(),
                      ),
              ),
            ],
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
          child: Text(number, style: const TextStyle(fontWeight: FontWeight.w700, color: kSketchCharcoal)),
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
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
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
            const SizedBox(height: 12),
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
                  color: Theme.of(context).colorScheme.surface.withAlpha(50),
                  border: Border.all(
                    color: Theme.of(context).colorScheme.onSurface.withAlpha(10),
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
      ),
    );
  }
}

class _InventoryTile extends StatelessWidget {
  const _InventoryTile({required this.item, this.isSelected = false, this.onTap});

  final ScrapItem item;
  final bool isSelected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isSelected ? kCookingTerracotta.withAlpha(20) : Colors.white,
          border: Border.all(
            color: isSelected ? kCookingTerracotta : const Color.fromRGBO(107, 93, 79, 0.12),
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
                color: isSelected ? kCookingTerracotta : kHerbSage,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: const Color.fromRGBO(139, 115, 85, 0.2),
                  width: 1,
                ),
              ),
              child: Icon(
                isSelected ? Icons.check_circle : Icons.local_florist_outlined,
                color: isSelected ? Colors.white : kRecipeWarmBrown,
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
                          fontWeight: FontWeight.w600,
                          color: isSelected ? kCookingTerracotta : kRecipeWarmBrown,
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
        color: Theme.of(context).cardColor,
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
                    color: kSuccess.withAlpha(100),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(Icons.eco, size: 18, color: kSuccess),
                ),
                const SizedBox(width: 12),
                Text(
                  'Your impact so far',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                        color: Theme.of(context).colorScheme.primary,
                        letterSpacing: -0.3,
                      ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _ImpactRow(icon: Icons.check_circle, label: '$itemsLogged scraps scanned', color: kSuccess),
            const SizedBox(height: 12),
            _ImpactRow(
              icon: Icons.restaurant_menu,
              label: '${itemsLogged > 0 ? (itemsLogged * 2) : 0} recipe ideas discovered',
              color: Theme.of(context).colorScheme.secondary,
            ),
            const SizedBox(height: 12),
            const _ImpactRow(
              icon: Icons.savings,
              label: 'Help reducing food waste',
              color: kSuccess,
            ),
          ],
        ),
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
