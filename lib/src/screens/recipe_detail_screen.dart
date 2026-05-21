import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models.dart';
import '../state/app_state.dart';
import '../constants/ui_constants.dart';

class RecipeDetailScreen extends StatelessWidget {
  const RecipeDetailScreen({super.key, required this.recipe, required this.appState});

  final RecipeSuggestion recipe;
  final AppState appState;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? UIConstants.kDarkBackground : UIConstants.kBackground;
    final cardColor = isDark ? UIConstants.kDarkSurface : UIConstants.kSurface;
    final textColor = isDark ? UIConstants.kDarkText : UIConstants.kText;

    final isSaved = appState.isRecipeSaved(recipe);

    return Scaffold(
      backgroundColor: bgColor,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 220,
            pinned: true,
            backgroundColor: UIConstants.kPrimary,
            flexibleSpace: FlexibleSpaceBar(
              title: Text(
                recipe.title,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                  fontSize: 18,
                ),
              ),
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [UIConstants.kPrimary, UIConstants.kPrimaryLight.withAlpha(220)],
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
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _MatchBadge(matchReason: recipe.matchReason),
                  const SizedBox(height: 24),
                  Text(
                    recipe.summary,
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
                    color: UIConstants.kPrimary,
                    textColor: textColor,
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: cardColor,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: textColor.withAlpha(15),
                          blurRadius: 16,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: Column(
                      children: recipe.ingredients.map((ingredient) {
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: Row(
                            children: [
                              Container(
                                width: 8,
                                height: 8,
                                decoration: const BoxDecoration(
                                  color: UIConstants.kSecondary,
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
                    title: 'Steps',
                    color: UIConstants.kPrimary,
                    textColor: textColor,
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: cardColor,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: textColor.withAlpha(15),
                          blurRadius: 16,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: Column(
                      children: const [
                        _Step(number: '1', text: 'Gather all your ingredients and clean the scraps.'),
                        _Step(number: '2', text: 'Prepare the vegetables by washing and chopping.'),
                        _Step(number: '3', text: 'Heat a pan with olive oil over medium heat.'),
                        _Step(number: '4', text: 'Add ingredients and cook until tender.'),
                        _Step(number: '5', text: 'Season to taste and serve warm.'),
                      ],
                    ),
                  ),
                  if (recipe.chefNote != null) ...[
                    const SizedBox(height: 28),
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [UIConstants.kPrimary.withAlpha(15), UIConstants.kPrimaryLight.withAlpha(8)],
                        ),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: UIConstants.kPrimary.withAlpha(30)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.lightbulb_rounded, color: UIConstants.kPrimary, size: 20),
                              const SizedBox(width: 8),
                              Text(
                                'Chef\'s Note',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                  color: textColor,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          Text(
                            recipe.chefNote!,
                            style: TextStyle(
                              fontSize: 15,
                              color: textColor.withAlpha(160),
                              fontStyle: FontStyle.italic,
                              height: 1.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                  const SizedBox(height: 32),
                  Row(
                    children: [
                      Expanded(
                        child: _ActionButton(
                          icon: isSaved ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                          label: isSaved ? 'Saved' : 'Save',
                          color: isSaved ? UIConstants.kSecondary : textColor,
                          cardColor: cardColor,
                          onTap: () async {
                            HapticFeedback.mediumImpact();
                            if (!appState.isSignedIn) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Sign in to save recipes.')),
                              );
                              return;
                            }

                            await appState.toggleSavedRecipe(recipe);
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(appState.isRecipeSaved(recipe) ? 'Recipe saved!' : 'Recipe removed.'),
                                  backgroundColor: UIConstants.kSecondary,
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
                          color: UIConstants.kPrimary,
                          cardColor: cardColor,
                          onTap: () async {
                            HapticFeedback.mediumImpact();
                            if (!appState.isSignedIn) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Sign in to add notes.')),
                              );
                              return;
                            }

                            final existing = appState.savedRecipes.firstWhere(
                              (saved) => saved.recipeId == recipe.stableId,
                              orElse: () => SavedRecipeRecord(
                                recipeId: recipe.stableId,
                                title: recipe.title,
                                summary: recipe.summary,
                                ingredients: recipe.ingredients,
                                matchReason: recipe.matchReason,
                                savedAt: DateTime.now(),
                                chefNote: recipe.chefNote,
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
                              if (!appState.isRecipeSaved(recipe)) {
                                await appState.toggleSavedRecipe(
                                    recipe, notes: note.isEmpty ? null : note);
                              } else if (note.isNotEmpty) {
                                await appState.updateSavedRecipeNotes(
                                    recipe.stableId, note);
                              }
                            }
                          },
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _ActionButton(
                          icon: Icons.share_rounded,
                          label: 'Share',
                          color: UIConstants.kPrimary,
                          cardColor: cardColor,
                          onTap: () {
                            HapticFeedback.mediumImpact();
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Share feature coming soon!'),
                                backgroundColor: UIConstants.kPrimary,
                              ),
                            );
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

class _MatchBadge extends StatelessWidget {
  const _MatchBadge({required this.matchReason});

  final String matchReason;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [UIConstants.kSecondary.withAlpha(20), UIConstants.kSecondary.withAlpha(10)],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: UIConstants.kSecondary.withAlpha(50)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.auto_awesome_rounded, size: 16, color: UIConstants.kSecondary),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              matchReason,
              style: const TextStyle(
                color: UIConstants.kSecondary,
                fontWeight: FontWeight.w600,
                fontSize: 13,
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? UIConstants.kDarkText : UIConstants.kText;

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
                colors: [UIConstants.kPrimary.withAlpha(20), UIConstants.kPrimaryLight.withAlpha(10)],
              ),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: UIConstants.kPrimary.withAlpha(40)),
            ),
            child: Text(
              number,
              style: const TextStyle(fontWeight: FontWeight.w700, color: UIConstants.kPrimary),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              text,
              style: TextStyle(fontSize: 15, color: textColor.withAlpha(170), height: 1.5),
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? UIConstants.kDarkText : UIConstants.kText;

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
