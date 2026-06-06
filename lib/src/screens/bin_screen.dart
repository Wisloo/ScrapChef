import 'package:flutter/material.dart';
import '../models.dart';
import '../services/recipe_service.dart';
import '../services/sound_service.dart';
import '../widgets/animated_button.dart' as animated;
import '../state/app_state.dart';
import 'recipe_list_screen.dart';
import '../widgets/app_card.dart';
import '../constants/ui_constants.dart';

class BinScreen extends StatefulWidget {
  const BinScreen({
    super.key,
    required this.appState,
  });

  final AppState appState;

  @override
  State<BinScreen> createState() => _BinScreenState();
}

class _BinScreenState extends State<BinScreen> {
  final Set<String> _selectedItems = {};
  final RecipeService _recipeService = RecipeService();
  bool _isLoading = false;

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
    print('🔵 _findRecipesForSelected called');
    if (_selectedItems.isNotEmpty) {
      setState(() {
        _isLoading = true;
      });
      SoundService.playClick();
      final labels = widget.appState.inventory
          .where((item) => _selectedItems.contains(_itemKey(item)))
          .map((item) => item.label)
          .toList();
      print('🔵 Labels: $labels');

      // Use RAG API to find recipes based on natural language query
      final query = 'Recipes using ${labels.join(', ')}';
      print('🔵 Query: $query');
      final recipes = await _recipeService.findRecipes(query, userIngredients: labels);
      print('🔵 Got ${recipes.length} recipes');

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
  }

  Future<void> _findRecipesForAll() async {
    if (widget.appState.inventory.isNotEmpty) {
      setState(() {
        _isLoading = true;
      });
      SoundService.playClick();
      final labels = widget.appState.inventory.map((item) => item.label).toList();

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
    final inventory = widget.appState.inventory;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          'Scrap Bin',
          style: TextStyle(
            color: Theme.of(context).colorScheme.onSurface,
            fontSize: 24,
            fontWeight: FontWeight.w800,
          ),
        ),
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Theme.of(context).colorScheme.onSurface),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Stack(
        children: [
          Column(
            children: [
              // Header with item count and actions
              Padding(
            padding: const EdgeInsets.fromLTRB(24, 12, 24, 8),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    inventory.isEmpty
                        ? 'Scrap bin is empty'
                        : '${inventory.length} items',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onSurface,
                      fontWeight: FontWeight.normal,
                      fontSize: 14,
                    ),
                  ),
                ),
                if (inventory.isNotEmpty && _selectedItems.isEmpty) ...[
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
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
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
                              fontSize: 13,
                            ),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
          // Selected items actions
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
                      overflow: TextOverflow.ellipsis,
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
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
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
                              fontSize: 13,
                            ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          // Inventory list
          Flexible(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 160),
              children: <Widget>[
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Theme.of(context).cardColor,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Theme.of(context).colorScheme.onSurface.withAlpha(8),
                        blurRadius: 24,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Scrap bin',
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.onSurface,
                          fontWeight: FontWeight.w700,
                          fontSize: 18,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _selectedItems.isEmpty
                            ? 'Tap items to select multiple for batch recipe matching.'
                            : 'Select more items or tap "Find Recipes".',
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.onSurface.withAlpha(140),
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 16),
                      if (inventory.isEmpty)
                        Text(
                          'No scraps logged yet. Use the camera tab to add one.',
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.onSurface.withAlpha(120),
                            fontSize: 14,
                          ),
                        )
                      else
                        Column(
                          children: inventory
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
                    ],
                  ),
                ),
              ],
            ),
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
    );
  }
}

class _InventoryTile extends StatelessWidget {
  const _InventoryTile({
    required this.item,
    required this.isSelected,
    required this.onTap,
    required this.onDelete,
  });

  final ScrapItem item;
  final bool isSelected;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: isSelected
            ? Theme.of(context).colorScheme.primary.withAlpha(15)
            : Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isSelected
              ? Theme.of(context).colorScheme.primary
              : Theme.of(context).colorScheme.onSurface.withAlpha(8),
          width: isSelected ? 2 : 1,
        ),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Icon(
          isSelected ? Icons.check_circle : Icons.circle_outlined,
          color: isSelected
              ? Theme.of(context).colorScheme.primary
              : Theme.of(context).colorScheme.onSurface.withAlpha(120),
        ),
        title: Text(
          item.label,
          style: TextStyle(
            color: Theme.of(context).colorScheme.onSurface,
            fontWeight: FontWeight.w600,
            fontSize: 15,
          ),
        ),
        trailing: IconButton(
          icon: Icon(Icons.delete_outline, 
              color: Theme.of(context).colorScheme.onSurface.withAlpha(120)),
          onPressed: onDelete,
        ),
        onTap: onTap,
      ),
    );
  }
}
