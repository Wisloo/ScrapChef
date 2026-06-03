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
        body: Column(
          children: [
            // Fixed top section with logo and title (reduced height)
            Container(
              height: 100,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    UIConstants.kPrimaryDark.withOpacity(0.3),
                    UIConstants.kPrimary.withOpacity(0.5),
                    UIConstants.kPrimaryLight.withOpacity(0.2),
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
                      Image.asset(
                        'lib/image/ScrapChefLogo.jpg',
                        width: 32,
                        height: 32,
                        fit: BoxFit.contain,
                      ),
                      const SizedBox(width: 10),
                      Text(
                        'ScrapChef',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
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
                child: _HeroHeader(
                  itemsLogged: itemsLogged,
                  estimatedSavings: estimatedSavings,
                  onSettingsTap: _openSettings,
                ),
              ),
            ),
            // Tab bar (fixed)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: TabBar(
                labelColor: Theme.of(context).colorScheme.secondary,
                unselectedLabelColor: Theme.of(context).colorScheme
                    .onSurface
                    .withAlpha(153),
                indicatorColor: Theme.of(context).colorScheme.secondary,
                indicatorWeight: 3,
                labelStyle: Theme.of(context)
                    .textTheme
                    .titleMedium
                    ?.copyWith(fontWeight: FontWeight.bold),
                unselectedLabelStyle:
                    Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.normal),
                tabs: const <Widget>[
                  Tab(text: 'Scan'),
                  Tab(text: 'Bin'),
                ],
              ),
            ),
            // Scrollable tab content
            Expanded(
              child: TabBarView(
                children: <Widget>[
                  Container(
                    padding: const EdgeInsets.all(UIConstants.kVerticalGap),
                    child: _ScanTab(appState: widget.appState, outcome: outcome, itemsLogged: itemsLogged, weeklyScanCount: widget.appState.weeklyScanCount),
                  ),
                  Container(
                    padding: const EdgeInsets.all(UIConstants.kVerticalGap),
                    child: _InventoryTab(
                      items: inventory,
                      onBatchSelect: _onBatchSelect,
                      appState: widget.appState,
                      onOpenRecipes: _openRecipes,
                    ),
                  ),
                ],
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
      ),
    );
  }
}

class _HeroHeader extends StatelessWidget {
  const _HeroHeader({
    required this.itemsLogged,
    required this.estimatedSavings,
    required this.onSettingsTap,
  });

  final int itemsLogged;
  final double estimatedSavings;
  final VoidCallback onSettingsTap;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.all(24),
      child: Container(
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(20),
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
                        'Turn scraps into suppers',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: Theme.of(context).colorScheme
                                  .onSurface
                                  .withAlpha(160),
                              fontStyle: FontStyle.normal,
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                            ),
                      ),
                    ],
                  ),
                ),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 10),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.primary,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Theme.of(context)
                                .colorScheme
                                .primary
                                .withOpacity(0.3),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Text(
                        '$itemsLogged',
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.onPrimary,
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
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
              color: Theme.of(context).colorScheme.onSurface.withAlpha(10),
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
                      Row(
                        children: [
                          Icon(Icons.check_circle,
                              size: 16,
                              color: Theme.of(context).colorScheme.primary),
                          const SizedBox(width: 6),
                          Text(
                            '$itemsLogged scraps scanned',
                            style: Theme.of(context)
                                .textTheme
                                .bodyMedium
                                ?.copyWith(
                                  color: Theme.of(context)
                                      .colorScheme
                                      .onSurface,
                                  fontWeight: FontWeight.normal,
                                ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Icon(Icons.attach_money,
                              size: 16,
                              color: Theme.of(context).colorScheme.secondary),
                          const SizedBox(width: 6),
                          Text(
                            'Estimated ₱${estimatedSavings.toStringAsFixed(0)} saved',
                            style: Theme.of(context)
                                .textTheme
                                .bodyMedium
                                ?.copyWith(
                                  color: Theme.of(context)
                                      .colorScheme
                                      .onSurface,
                                  fontWeight: FontWeight.normal,
                                ),
                          ),
                        ],
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

class _InventoryTab extends StatefulWidget {
  const _InventoryTab({
    required this.items,
    required this.onBatchSelect,
    required this.appState,
    required this.onOpenRecipes,
  });

  final List<ScrapItem> items;
  final Function(List<String>) onBatchSelect;
  final AppState appState;
  final Function(List<String>) onOpenRecipes;

  @override
  State<_InventoryTab> createState() => _InventoryTabState();
}

class _InventoryTabState extends State<_InventoryTab> {
  final Set<String> _selectedItems = {};
  final RecipeService _recipeService = RecipeService();

  String _itemKey(ScrapItem item) {
    return item.id ?? '${item.label}_${item.loggedAt.millisecondsSinceEpoch}';
  }

  void _toggleSelection(ScrapItem item) {
    final key = _itemKey(item);
    setState(() {
      if (_selectedItems.contains(key)) {
        _selectedItems.remove(key);
      } else {
        _selectedItems.add(key);
      }
    });
  }

  void _clearSelection() {
    setState(() {
      _selectedItems.clear();
    });
  }

  Future<void> _findRecipesForSelected() async {
    if (_selectedItems.isNotEmpty) {
      SoundService.playClick();
      final labels = widget.items
          .where((item) => _selectedItems.contains(_itemKey(item)))
          .map((item) => item.label)
          .toList();
      
      // Use RAG API to find recipes based on natural language query
      final query = 'Recipes using ${labels.join(', ')}';
      final recipes = await _recipeService.findRecipes(query);
      
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
  }

  Future<void> _findRecipesForAll() async {
    if (widget.items.isNotEmpty) {
      SoundService.playClick();
      final labels = widget.items.map((item) => item.label).toList();
      
      // Use RAG API to find recipes based on natural language query
      final query = 'Recipes using ${labels.join(', ')}';
      final recipes = await _recipeService.findRecipes(query);
      
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
  }

  void _deleteItem(ScrapItem item) {
    final key = _itemKey(item);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Item?'),
        content: Text('Remove "${item.label}" from your scrap bin?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              widget.appState.deleteItem(item);
              _selectedItems.remove(key);
              Navigator.pop(context);
            },
            child: const Text('Delete',
                style: TextStyle(
                    color: Colors.red,
                    fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
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
                  widget.items.isEmpty
                      ? 'Scrap bin is empty'
                      : '${widget.items.length} items',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurface,
                    fontWeight: FontWeight.normal,
                    fontSize: 14,
                  ),
                ),
              ),
              if (widget.items.isNotEmpty && _selectedItems.isEmpty) ...[
                TextButton(
                  onPressed: () {
                    showDialog(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: const Text('Clear Scrap Bin?'),
                        content: const Text(
                            'This will remove all items from your scrap bin.'),
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
                            child: const Text('Clear',
                                style: TextStyle(
                                    color: Colors.red,
                                    fontWeight: FontWeight.bold)),
                          ),
                        ],
                      ),
                    );
                  },
                  child: Text(
                    'Clear All',
                    style: TextStyle(
                        color: Theme.of(context).colorScheme.primary,
                        fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(width: 12),
                animated.AnimatedButton(
                  onPressed: () => _findRecipesForAll(),
                  color: Theme.of(context).colorScheme.primary,
                  borderRadius: 16,
                  height: 56,
                  shadow: true,
                  child: Text(
                    'Find Recipes',
                    style: Theme.of(context)
                        .textTheme
                        .titleMedium
                        ?.copyWith(
                          color: Theme.of(context)
                              .colorScheme
                              .onPrimary,
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
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
                      color: Theme.of(context).colorScheme.primary,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                ),
                TextButton(
                  onPressed: _clearSelection,
                  child: Text(
                    'Clear Selection',
                    style: TextStyle(
                        color: Theme.of(context)
                            .colorScheme
                            .onSurface
                            .withAlpha(140)),
                  ),
                ),
                const SizedBox(width: 8),
                animated.AnimatedButton(
                  onPressed: () => _findRecipesForSelected(),
                  color: Theme.of(context).colorScheme.primary,
                  borderRadius: 16,
                  height: 56,
                  shadow: true,
                  child: Text(
                    'Find Recipes',
                    style: Theme.of(context)
                        .textTheme
                        .titleMedium
                        ?.copyWith(
                          color: Theme.of(context)
                              .colorScheme
                              .onPrimary,
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                  ),
                ),
              ],
            ),
          ),
        Flexible(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            children: <Widget>[
              _SectionCard(
                title: 'Scrap bin',
                subtitle: _selectedItems.isEmpty
                    ? 'Tap items to select multiple for batch recipe matching.'
                    : 'Select more items or tap "Find Recipes".',
                child: widget.items.isEmpty
                    ? const Text(
                        'No scraps logged yet. Use the camera tab to add one.')
                    : Column(
                        children: widget.items
                            .map((item) => Padding(
                              padding: const EdgeInsets.only(bottom: 10),
                              child: _InventoryTile(
                                item: item,
                                isSelected:
                                    _selectedItems.contains(_itemKey(item)),
                                onTap: () => _toggleSelection(item),
                                onDelete: () => _deleteItem(item),
                              ),
                            ))
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
  const _RecipeTile({required this.recipe});

  final RecipeSuggestion recipe;

  @override
  Widget build(BuildContext context) {
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
            child: _RecipeTile(recipe: recipe),
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

