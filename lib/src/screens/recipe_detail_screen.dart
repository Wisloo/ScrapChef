import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models.dart';
import '../state/app_state.dart';
import '../constants/ui_constants.dart';
import '../services/recipe_service.dart';

class RecipeDetailScreen extends StatefulWidget {
  const RecipeDetailScreen({super.key, required this.recipe, required this.appState});

  final RecipeSuggestion recipe;
  final AppState appState;

  @override
  State<RecipeDetailScreen> createState() => _RecipeDetailScreenState();
}

class _RecipeDetailScreenState extends State<RecipeDetailScreen> {
  @override
  void initState() {
    super.initState();
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
                  _SectionTitle(
                    icon: Icons.shopping_basket_rounded,
                    title: 'Ingredients',
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
                    child: Column(
                      children: widget.recipe.ingredients.map((ingredient) {
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: Row(
                            children: [
                              Container(
                                width: 8,
                                height: 8,
                                decoration: BoxDecoration(
                                  color: secondaryColor,
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Text(
                                  ingredient,
                                  style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w500,
                                    color: textColor,
                                  ),
                                ),
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
                        child: _ActionButton(
                          icon: isSaved ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                          label: isSaved ? 'Saved' : 'Save',
                          color: isSaved ? secondaryColor : textColor,
                          cardColor: cardColor,
                          onTap: () async {
                            if (!widget.appState.isSignedIn) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Sign in to save recipes.')),
                              );
                              return;
                            }

                            await widget.appState.toggleSavedRecipe(widget.recipe);
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(widget.appState.isRecipeSaved(widget.recipe) ? 'Recipe saved!' : 'Recipe removed.'),
                                  backgroundColor: secondaryColor,
                                ),
                              );
                            }
                          },
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _ActionButton(
                          icon: Icons.note_add_rounded,
                          label: 'Note',
                          color: primaryColor,
                          cardColor: cardColor,
                          onTap: () async {
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

    return GestureDetector(
      onTap: onTap,
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