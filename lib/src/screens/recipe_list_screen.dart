import 'package:flutter/material.dart';

import '../models.dart';
import '../state/app_state.dart';
import 'recipe_detail_screen.dart';

class RecipeListScreen extends StatefulWidget {
  const RecipeListScreen({
    super.key,
    required this.appState,
    required this.labels,
    this.ragRecipes,
    this.selectedItemKeys,
  });

  final AppState appState;
  final List<String> labels;
  final List<RecipeSuggestion>? ragRecipes;
  final List<String>? selectedItemKeys;

  @override
  State<RecipeListScreen> createState() => _RecipeListScreenState();
}

class _RecipeListScreenState extends State<RecipeListScreen> {
  List<RecipeSuggestion> recipes = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadRecipes();
  }

  Future<void> _loadRecipes() async {
    // Use RAG recipes if provided, otherwise fall back to label-based suggestions
    if (widget.ragRecipes != null) {
      if (mounted) {
        setState(() {
          recipes = widget.ragRecipes!;
          isLoading = false;
        });
      }
    } else {
      final loadedRecipes = await widget.appState.suggestForLabels(widget.labels);
      if (mounted) {
        setState(() {
          recipes = loadedRecipes;
          isLoading = false;
        });
      }
    }

    // If no recipes found and inventory is empty, show fallback recipes for testing
    if (mounted && recipes.isEmpty && widget.labels.isEmpty) {
      setState(() {
        recipes = widget.appState.recipeService.suggest([]);
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_rounded, color: Theme.of(context).colorScheme.onSurface),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          'Recipe Ideas',
          style: TextStyle(
            color: Theme.of(context).colorScheme.primary,
            fontWeight: FontWeight.w800,
            fontSize: 24,
            letterSpacing: -0.5,
          ),
        ),
        centerTitle: true,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary.withAlpha(10),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                children: [
                  Icon(Icons.auto_awesome, size: 16, color: Theme.of(context).colorScheme.primary),
                  const SizedBox(width: 4),
                  Text(
                    '${recipes.length}',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.primary,
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : recipes.isEmpty
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.restaurant_menu_outlined,
                          size: 64,
                          color: Theme.of(context).colorScheme.onSurface.withAlpha(140),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No recipes found',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: Theme.of(context).colorScheme.onSurface,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Try adding more scraps to your bin',
                          style: TextStyle(
                            fontSize: 14,
                            color: Theme.of(context).colorScheme.onSurface.withAlpha(140),
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: recipes.length,
                  itemBuilder: (context, index) {
                    final recipe = recipes[index];
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 20),
                      child: GestureDetector(
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => RecipeDetailScreen(
                                recipe: recipe,
                                appState: widget.appState,
                                selectedLabels: widget.labels,
                                selectedItemKeys: widget.selectedItemKeys,
                              ),
                            ),
                          );
                        },
                        child: _RecipeCard(recipe: recipe, index: index, appState: widget.appState, labels: widget.labels, selectedItemKeys: widget.selectedItemKeys),
                      ),
                    );
                  },
                ),
    );
  }
}

class _RecipeCard extends StatelessWidget {
  const _RecipeCard({required this.recipe, required this.index, required this.appState, required this.labels, required this.selectedItemKeys});

  final RecipeSuggestion recipe;
  final int index;
  final AppState appState;
  final List<String> labels;
  final List<String>? selectedItemKeys;

  /// Mapping from scrap types to their base ingredient names
  static const Map<String, String> _scrapToBaseIngredient = {
    'carrot peel': 'carrot',
    'carrot peels': 'carrot',
    'potato peel': 'potato',
    'potato peels': 'potato',
    'potato skin': 'potato',
    'potato skins': 'potato',
    'onion skin': 'onion',
    'onion skins': 'onion',
    'banana peel': 'banana',
    'banana peels': 'banana',
    'orange peel': 'orange',
    'orange peels': 'orange',
    'lemon peel': 'lemon',
    'lemon peels': 'lemon',
    'apple core': 'apple',
    'apple core & peel': 'apple',
    'apple peel': 'apple',
    'apple peels': 'apple',
    'broccoli stem': 'broccoli',
    'broccoli stems': 'broccoli',
    'cabbage core': 'cabbage',
    'cauliflower core': 'cauliflower',
    'cucumber peel': 'cucumber',
    'cucumber peels': 'cucumber',
    'tomato trimmings': 'tomato',
    'leafy trimmings': 'leafy greens',
    'bean pod': 'bean',
    'bean pods': 'bean',
    'corn husk': 'corn',
  };

  /// Get the base ingredient name for a scrap type
  String _getBaseIngredient(String scrapType) {
    final scrapLower = scrapType.toLowerCase().trim();
    return _scrapToBaseIngredient[scrapLower] ?? scrapLower;
  }

  /// Check if user has ingredients available
  Map<String, dynamic> _checkOverallAvailability() {
    // Use the selected labels passed to this widget, not the entire inventory
    final selectedLabels = labels.map((l) => l.toLowerCase().trim()).toSet();
    final ingredients = recipe.ingredients;
    
    if (ingredients.isEmpty) {
      return {'availableCount': 0, 'totalCount': 0};
    }

    int availableCount = 0;
    int totalCount = ingredients.length;

    for (final ingredient in ingredients) {
      final ingredientLower = ingredient.toLowerCase().trim();
      
      // Check if any selected scrap type matches this ingredient
      bool hasMatch = false;
      for (final scrapLabel in selectedLabels) {
        final baseIngredient = _getBaseIngredient(scrapLabel);
        
        // Check for exact match
        if (scrapLabel == ingredientLower || baseIngredient == ingredientLower) {
          hasMatch = true;
          break;
        }
        // Check if scrap contains ingredient (e.g., "carrot peels" contains "carrot")
        if (scrapLabel.contains(ingredientLower) || ingredientLower.contains(scrapLabel)) {
          hasMatch = true;
          break;
        }
        // Check if base ingredient contains ingredient or vice versa
        if (baseIngredient.contains(ingredientLower) || ingredientLower.contains(baseIngredient)) {
          hasMatch = true;
          break;
        }
      }
      
      if (hasMatch) {
        availableCount++;
      }
    }

    return {
      'availableCount': availableCount,
      'totalCount': totalCount,
    };
  }

  @override
  Widget build(BuildContext context) {
    // Generate food emoji based on index for visual variety
    final foodEmojis = ['🍳', '🥗', '🍜', '🥘', '🍲', '🥙', '🌮', '🍕'];
    final emoji = foodEmojis[index % foodEmojis.length];
    
    // Parse match reason to extract similarity score
    final similarityMatch = RegExp(r'(\d+\.?\d*)%').firstMatch(recipe.matchReason);
    final similarityScore = similarityMatch != null ? similarityMatch.group(1) : null;
    
    // Check ingredient availability
    final availability = _checkOverallAvailability();
    final availableCount = availability['availableCount'] as int;
    final totalCount = availability['totalCount'] as int;

    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).colorScheme.onSurface.withAlpha(12),
            blurRadius: 28,
            offset: const Offset(0, 12),
          ),
          BoxShadow(
            color: Theme.of(context).colorScheme.primary.withAlpha(6),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Image header
          Stack(
            children: [
              Container(
                height: 200,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Theme.of(context).colorScheme.primary.withAlpha(120),
                      Theme.of(context).colorScheme.primary.withAlpha(60),
                      Theme.of(context).scaffoldBackgroundColor,
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(24),
                    topRight: Radius.circular(24),
                  ),
                ),
                child: recipe.imageUrl != null && recipe.imageUrl!.isNotEmpty
                    ? ClipRRect(
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(24),
                          topRight: Radius.circular(24),
                        ),
                        child: Image.network(
                          recipe.imageUrl!,
                          width: double.infinity,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return Center(
                              child: Container(
                                padding: const EdgeInsets.all(20),
                                decoration: BoxDecoration(
                                  color: Theme.of(context).cardColor,
                                  borderRadius: BorderRadius.circular(20),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Theme.of(context).colorScheme.onSurface.withAlpha(15),
                                      blurRadius: 16,
                                      offset: const Offset(0, 8),
                                    ),
                                  ],
                                ),
                                child: Text(
                                  emoji,
                                  style: const TextStyle(fontSize: 48),
                                ),
                              ),
                            );
                          },
                          loadingBuilder: (context, child, loadingProgress) {
                            if (loadingProgress == null) return child;
                            return Center(
                              child: CircularProgressIndicator(
                                value: loadingProgress.expectedTotalBytes != null
                                    ? loadingProgress.cumulativeBytesLoaded /
                                        loadingProgress.expectedTotalBytes!
                                    : null,
                                color: Theme.of(context).colorScheme.primary,
                              ),
                            );
                          },
                        ),
                      )
                    : Center(
                        child: Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: Theme.of(context).cardColor,
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [
                              BoxShadow(
                                color: Theme.of(context).colorScheme.onSurface.withAlpha(15),
                                blurRadius: 16,
                                offset: const Offset(0, 8),
                              ),
                            ],
                          ),
                          child: Text(
                            emoji,
                            style: const TextStyle(fontSize: 48),
                          ),
                        ),
                      ),
              ),
              // Similarity badge overlay
              if (similarityScore != null)
                Positioned(
                  top: 16,
                  right: 16,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.white.withAlpha(240),
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withAlpha(25),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.auto_awesome, size: 16, color: Theme.of(context).colorScheme.secondary),
                        const SizedBox(width: 6),
                        Text(
                          '$similarityScore',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w800,
                            color: Theme.of(context).colorScheme.secondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              // Availability badge overlay
              Positioned(
                top: 16,
                left: 16,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primary.withAlpha(240),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withAlpha(25),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.shopping_basket,
                        size: 14,
                        color: Colors.white,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '$availableCount/$totalCount',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          // Recipe title
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
            child: Text(
              recipe.title,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: Theme.of(context).colorScheme.primary,
                height: 1.2,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          // Ingredients preview
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.shopping_basket_outlined, size: 18, color: Theme.of(context).colorScheme.primary),
                    const SizedBox(width: 8),
                    Text(
                      'Key Ingredients',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: recipe.ingredients.take(4).map((ingredient) {
                    return Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.primary.withAlpha(20),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: Theme.of(context).colorScheme.primary.withAlpha(30)),
                      ),
                      child: Text(
                        ingredient.length > 20 ? '${ingredient.substring(0, 20)}...' : ingredient,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      ),
                    );
                  }).toList(),
                ),
                if (recipe.ingredients.length > 4) ...[
                  const SizedBox(height: 8),
                  Text(
                    '+ ${recipe.ingredients.length - 4} more ingredients',
                    style: TextStyle(
                      fontSize: 12,
                      color: Theme.of(context).colorScheme.onSurface.withAlpha(140),
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
              ],
            ),
          ),
          // View recipe button
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => RecipeDetailScreen(
                        recipe: recipe,
                        appState: appState,
                        selectedLabels: labels,
                        selectedItemKeys: selectedItemKeys,
                      ),
                    ),
                  );
                },
                icon: const Icon(Icons.arrow_forward, size: 18),
                label: const Text('View Recipe'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).colorScheme.primary,
                  foregroundColor: Theme.of(context).colorScheme.onPrimary,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 2,
                  shadowColor: Theme.of(context).colorScheme.primary.withAlpha(50),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFallbackHeader(BuildContext context, String emoji, RecipeSuggestion recipe, String? similarityScore) {
    return Container(
      height: 200,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Theme.of(context).colorScheme.primary.withAlpha(120),
            Theme.of(context).colorScheme.secondary.withAlpha(80),
            Theme.of(context).scaffoldBackgroundColor,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: Theme.of(context).colorScheme.onSurface.withAlpha(15),
                  blurRadius: 16,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Text(
              emoji,
              style: const TextStyle(fontSize: 42),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            recipe.title,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: Theme.of(context).colorScheme.primary,
              letterSpacing: -0.3,
            ),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}
