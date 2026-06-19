import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models.dart';
import '../state/app_state.dart';
import '../constants/ui_constants.dart';
import '../services/recipe_service.dart';

class RecipeDetailScreen extends StatefulWidget {
  const RecipeDetailScreen({super.key, required this.recipe, required this.appState, this.selectedLabels, this.selectedItemKeys});

  final RecipeSuggestion recipe;
  final AppState appState;
  final List<String>? selectedLabels;
  final List<String>? selectedItemKeys;

  @override
  State<RecipeDetailScreen> createState() => _RecipeDetailScreenState();
}

class _RecipeDetailScreenState extends State<RecipeDetailScreen> {
  String _itemKey(ScrapItem item) {
    return item.id ?? '${item.label}_${item.loggedAt.millisecondsSinceEpoch}';
  }

  @override
  void initState() {
    super.initState();
  }

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

  /// Check if user has the ingredient type available
  Map<String, dynamic> _checkIngredientAvailability(String ingredient) {
    // Use selected item keys if provided, otherwise use entire inventory
    final inventory = widget.appState.inventory;
    final selectedItemKeys = widget.selectedItemKeys?.toSet();
    
    print('🔍 Weight Debug: Ingredient: "$ingredient"');
    print('🔍 Weight Debug: Selected item keys: $selectedItemKeys');
    
    // Calculate available weight by summing only selected matching scrap items
    double availableWeight = 0.0;
    final ingredientLower = ingredient.toLowerCase();
    
    // Extract base ingredient name (remove plurals, common words)
    final ingredientBase = _extractBaseIngredient(ingredientLower);
    
    for (final scrap in inventory) {
      if (scrap.weightGrams == null) continue;
      
      final itemKey = _itemKey(scrap);
      
      // If selected item keys are provided, only count those specific items
      if (selectedItemKeys != null && selectedItemKeys.isNotEmpty) {
        if (!selectedItemKeys.contains(itemKey)) {
          print('🔍 Weight Debug:   Skipping scrap: "$itemKey" (${scrap.weightGrams}g) - not in selected keys');
          continue;
        }
        print('🔍 Weight Debug:   Including scrap: "$itemKey" (${scrap.weightGrams}g) - in selected keys');
      } else {
        print('🔍 Weight Debug:   Including scrap: "$itemKey" (${scrap.weightGrams}g) - no selection filter');
      }
      
      final scrapLower = scrap.label.toLowerCase().trim();
      final scrapBase = _extractBaseIngredient(scrapLower);
      
      // Check if scrap type matches ingredient directly
      if (scrapLower.contains(ingredientLower) || ingredientLower.contains(scrapLower)) {
        availableWeight += scrap.weightGrams!;
        print('🔍 Weight Debug:     Matched (direct): +${scrap.weightGrams}g');
      }
      // Check if base ingredients match (more flexible matching)
      else if (scrapBase.contains(ingredientBase) || ingredientBase.contains(scrapBase)) {
        availableWeight += scrap.weightGrams!;
        print('🔍 Weight Debug:     Matched (base): +${scrap.weightGrams}g');
      }
    }
    
    print('🔍 Weight Debug: Final weight for "$ingredient": ${availableWeight}g');
    
    // Get required weight from recipe if available
    final requiredWeight = widget.recipe.ingredientWeights?[ingredient];
    
    return {
      'isAvailable': availableWeight > 0,
      'availableWeight': availableWeight,
      'requiredWeight': requiredWeight,
    };
  }
  
  /// Calculate overall ingredient availability count
  Map<String, int> _calculateIngredientCount() {
    int availableCount = 0;
    final totalIngredients = widget.recipe.ingredients.length;
    
    for (final ingredient in widget.recipe.ingredients) {
      final availability = _checkIngredientAvailability(ingredient);
      final isAvailable = availability['isAvailable'] as bool;
      if (isAvailable) {
        availableCount++;
      }
    }
    
    return {
      'availableCount': availableCount,
      'totalCount': totalIngredients,
    };
  }
  
  /// Extract base ingredient name by removing plurals and common words
  String _extractBaseIngredient(String ingredient) {
    // Remove common words
    final clean = ingredient
        .replaceAll(RegExp(r'\b(peels|peel|skin|skins|pulp|flesh|seeds|seed|core|cores)\b'), '')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
    
    // Remove trailing 's' for plurals (simple approach)
    if (clean.endsWith('s') && clean.length > 2) {
      return clean.substring(0, clean.length - 1);
    }
    return clean;
  }

  Widget _parseInstructions(String instructions) {
    // Split instructions by sentence endings or step markers
    final steps = instructions
        .split(RegExp(r'\.\s+|Step\s+\d+:|,\s+'))
        .where((step) => step.trim().isNotEmpty)
        .toList();
    
    final primaryColor = Theme.of(context).colorScheme.primary;
    final textColor = Theme.of(context).colorScheme.onSurface;
    
    return Column(
      children: steps.asMap().entries.map((entry) {
        final index = entry.key;
        final step = entry.value.trim();
        return Padding(
          padding: const EdgeInsets.only(bottom: 14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 32,
                height: 32,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [primaryColor.withAlpha(20), primaryColor.withAlpha(10)],
                  ),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: primaryColor.withAlpha(40)),
                ),
                child: Text(
                  '${index + 1}',
                  style: TextStyle(fontWeight: FontWeight.w700, color: primaryColor),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  step.endsWith('.') ? step : '$step.',
                  style: TextStyle(fontSize: 15, color: textColor, height: 1.5),
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildFallbackHeader(Color primaryColor) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [primaryColor, primaryColor.withAlpha(220)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Center(
        child: Icon(
          Icons.restaurant_menu_rounded,
          size: 84,
          color: Colors.white.withAlpha(90),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bgColor = Theme.of(context).scaffoldBackgroundColor;
    final cardColor = Theme.of(context).cardColor;
    final textColor = Theme.of(context).colorScheme.onSurface;
    final primaryColor = Theme.of(context).colorScheme.primary;
    final secondaryColor = Theme.of(context).colorScheme.secondary;

    final isSaved = widget.appState.isRecipeSaved(widget.recipe);
    print('🏗️ [RecipeDetailScreen] Building recipe: "${widget.recipe.title}", isSaved: $isSaved');

    return Scaffold(
      backgroundColor: bgColor,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 280,
            pinned: true,
            backgroundColor: primaryColor,
            flexibleSpace: FlexibleSpaceBar(
              title: Text(
                widget.recipe.title,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                  fontSize: 18,
                  letterSpacing: -0.3,
                ),
              ),
              background: widget.recipe.imageUrl != null && widget.recipe.imageUrl!.isNotEmpty
                  ? Image.network(
                      widget.recipe.imageUrl!,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return _buildFallbackHeader(primaryColor);
                      },
                      loadingBuilder: (context, child, loadingProgress) {
                        if (loadingProgress == null) return child;
                        return Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [primaryColor, primaryColor.withAlpha(220)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                          ),
                          child: Center(
                            child: CircularProgressIndicator(
                              value: loadingProgress.expectedTotalBytes != null
                                  ? loadingProgress.cumulativeBytesLoaded /
                                      loadingProgress.expectedTotalBytes!
                                  : null,
                              color: Colors.white,
                            ),
                          ),
                        );
                      },
                    )
                  : _buildFallbackHeader(primaryColor),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 24),
                  Text(
                    widget.recipe.summary,
                    style: TextStyle(
                      fontSize: 16,
                      color: textColor.withAlpha(180),
                      height: 1.6,
                    ),
                  ),
                  const SizedBox(height: 28),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _SectionTitle(
                        icon: Icons.shopping_basket_rounded,
                        title: 'Ingredients',
                        color: primaryColor,
                        textColor: textColor,
                      ),
                      Builder(
                        builder: (context) {
                          final count = _calculateIngredientCount();
                          return Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: primaryColor.withAlpha(16),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              '${count['availableCount']}/${count['totalCount']} available',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: primaryColor,
                              ),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: cardColor,
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          color: textColor.withAlpha(15),
                          blurRadius: 20,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Column(
                      children: widget.recipe.ingredients.map((ingredient) {
                        final availability = _checkIngredientAvailability(ingredient);
                        final isAvailable = availability['isAvailable'] as bool;
                        final availableWeight = availability['availableWeight'] as double;
                        final requiredWeight = availability['requiredWeight'] as double?;
                        
                        // Determine if we have enough weight
                        final hasEnough = requiredWeight != null && availableWeight >= requiredWeight;
                        final weightColor = hasEnough ? Colors.green : (requiredWeight != null ? Colors.orange : Colors.green);
                        
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: Row(
                            children: [
                              Container(
                                width: 8,
                                height: 8,
                                decoration: BoxDecoration(
                                  color: isAvailable ? weightColor : Colors.grey,
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      ingredient,
                                      style: TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.w500,
                                        color: textColor,
                                      ),
                                    ),
                                    if (isAvailable) ...[
                                      const SizedBox(height: 4),
                                      if (requiredWeight != null)
                                        Text(
                                          'Have ${availableWeight.toStringAsFixed(0)}g / Need ${requiredWeight.toStringAsFixed(0)}g',
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: weightColor,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        )
                                      else
                                        Text(
                                          'Available: ${availableWeight.toStringAsFixed(0)}g',
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: Colors.green,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                    ],
                                  ],
                                ),
                              ),
                              if (isAvailable)
                                Icon(
                                  hasEnough ? Icons.check_circle : Icons.warning,
                                  color: weightColor,
                                  size: 20,
                                ),
                            ],
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                  const SizedBox(height: 28),
                  _SectionTitle(
                    icon: Icons.format_list_numbered_rounded,
                    title: 'Instructions',
                    color: primaryColor,
                    textColor: textColor,
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: cardColor,
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          color: textColor.withAlpha(15),
                          blurRadius: 20,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: widget.recipe.chefNote != null
                        ? _parseInstructions(widget.recipe.chefNote!)
                        : Text(
                            'No instructions available.',
                            style: TextStyle(
                              fontSize: 15,
                              color: textColor,
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                  ),
                  const SizedBox(height: 32),
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () async {
                            try {
                              print('💾 [Save Button] Save button clicked');
                              print('💾 [Save Button] isSignedIn: ${widget.appState.isSignedIn}');
                              
                              if (!widget.appState.isSignedIn) {
                                print('❌ [Save Button] User not signed in - showing error');
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('Sign in to save recipes.')),
                                );
                                return;
                              }

                              print('✅ [Save Button] Calling toggleSavedRecipe...');
                              await widget.appState.toggleSavedRecipe(widget.recipe);
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(widget.appState.isRecipeSaved(widget.recipe) ? 'Recipe saved!' : 'Recipe removed.'),
                                    backgroundColor: secondaryColor,
                                  ),
                                );
                              }
                            } catch (e, stackTrace) {
                              print('❌ [Save Button] Error: $e');
                              print('❌ [Save Button] Stack trace: $stackTrace');
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text('Error saving recipe: $e')),
                                );
                              }
                            }
                          },
                          icon: Icon(isSaved ? Icons.favorite_rounded : Icons.favorite_border_rounded),
                          label: Text(isSaved ? 'Saved' : 'Save'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: isSaved ? secondaryColor : cardColor,
                            foregroundColor: isSaved ? Colors.white : textColor,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(18),
                              side: BorderSide(color: isSaved ? secondaryColor : textColor.withAlpha(30)),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () async {
                            if (!widget.appState.isSignedIn) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Sign in to add notes.')),
                              );
                              return;
                            }

                            final existing = widget.appState.savedRecipes.firstWhere(
                              (saved) => saved.recipeId == widget.recipe.stableId,
                              orElse: () => SavedRecipeRecord(
                                recipeId: widget.recipe.stableId,
                                title: widget.recipe.title,
                                summary: widget.recipe.summary,
                                ingredients: widget.recipe.ingredients,
                                matchReason: widget.recipe.matchReason,
                                savedAt: DateTime.now(),
                                chefNote: widget.recipe.chefNote,
                              ),
                            );
                            final controller = TextEditingController(text: existing.userNotes ?? '');

                            final note = await showModalBottomSheet<String>(
                              context: context,
                              isScrollControlled: true,
                              backgroundColor: Colors.transparent,
                              builder: (sheetContext) => Padding(
                                padding: EdgeInsets.only(
                                    bottom: MediaQuery.of(sheetContext).viewInsets.bottom),
                                child: Container(
                                  padding: const EdgeInsets.all(20),
                                  decoration: BoxDecoration(
                                    color: cardColor,
                                    borderRadius: const BorderRadius.vertical(
                                        top: Radius.circular(24)),
                                  ),
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Recipe note',
                                        style: TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.w700,
                                          color: textColor),
                                      ),
                                      const SizedBox(height: 12),
                                      TextField(
                                        controller: controller,
                                        minLines: 3,
                                        maxLines: 6,
                                        decoration: const InputDecoration(
                                          hintText:
                                              'Add tweaks, substitutions, or portion notes...',
                                        ),
                                      ),
                                      const SizedBox(height: 16),
                                      Row(
                                        children: [
                                          Expanded(
                                            child: OutlinedButton(
                                              onPressed: () =>
                                                  Navigator.of(sheetContext).pop(),
                                              child: const Text('Cancel'),
                                            ),
                                          ),
                                          const SizedBox(width: 12),
                                          Expanded(
                                            child: FilledButton(
                                              onPressed: () =>
                                                  Navigator.of(sheetContext)
                                                      .pop(controller.text.trim()),
                                              child: const Text('Save note'),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            );

                            if (note != null) {
                              if (!widget.appState.isRecipeSaved(widget.recipe)) {
                                await widget.appState.toggleSavedRecipe(
                                    widget.recipe, notes: note.isEmpty ? null : note);
                              } else if (note.isNotEmpty) {
                                await widget.appState.updateSavedRecipeNotes(
                                    widget.recipe.stableId, note);
                              }
                            }
                          },
                          icon: const Icon(Icons.note_add_rounded),
                          label: const Text('Note'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: cardColor,
                            foregroundColor: primaryColor,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(18),
                              side: BorderSide(color: primaryColor.withAlpha(30)),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({
    required this.icon,
    required this.title,
    required this.color,
    required this.textColor,
  });

  final IconData icon;
  final String title;
  final Color color;
  final Color textColor;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(width: 8),
        Text(
          title,
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: textColor),
        ),
      ],
    );
  }
}

class _Step extends StatelessWidget {
  const _Step({required this.number, required this.text});

  final String number;
  final String text;

  @override
  Widget build(BuildContext context) {
    final primaryColor = Theme.of(context).colorScheme.primary;
    final textColor = Theme.of(context).colorScheme.onSurface;
    
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 32,
            height: 32,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [primaryColor.withAlpha(20), primaryColor.withAlpha(10)],
              ),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: primaryColor.withAlpha(40)),
            ),
            child: Text(
              number,
              style: TextStyle(fontWeight: FontWeight.w700, color: primaryColor),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              text,
              style: TextStyle(fontSize: 15, color: textColor, height: 1.5),
            ),
          ),
        ],
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.icon,
    required this.label,
    required this.onTap,
    required this.color,
    required this.cardColor,
  });

  final IconData icon;
  final String label;
  final Color color;
  final Color cardColor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final textColor = UIConstants.kText;

    return InkWell(
      onTap: () {
        print('🔘 [_ActionButton] onTap triggered');
        onTap();
      },
      borderRadius: BorderRadius.circular(18),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: color.withAlpha(30)),
          boxShadow: [
            BoxShadow(
              color: textColor.withAlpha(10),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color),
            const SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(fontWeight: FontWeight.w700, color: color),
            ),
          ],
        ),
      ),
    );
  }
}