import '../models.dart';

class RecipeService {
  List<RecipeSuggestion> suggest(List<ScrapItem> inventory) {
    final labels = inventory.map((item) => item.label.toLowerCase()).toSet();

    final suggestions = <RecipeSuggestion>[];

    if (_hasAny(labels, const ['carrot', 'radish', 'cucumber', 'capsicum'])) {
      suggestions.add(
        const RecipeSuggestion(
          title: 'Root-to-Stem Crunch Bowl',
          summary: 'Use crisp vegetable scraps for a bright salad with toasted seeds.',
          ingredients: ['Carrot tops', 'Radish greens', 'Cucumber peels', 'Yogurt dressing'],
          matchReason: 'Works well with fresh, crunchy scraps in the inventory.',
          chefNote: 'The tender greens and peels are more flavorful than you\'d think. Toss with a sharp vinaigrette for best results.',
        ),
      );
    }

    if (_hasAny(labels, const ['broccoli', 'cauliflower', 'cabbage', 'brinjal'])) {
      suggestions.add(
        const RecipeSuggestion(
          title: 'Roasted Scrap Tray Bake',
          summary: 'Roast tougher stems and peels with oil, garlic, and herbs.',
          ingredients: ['Broccoli stems', 'Cauliflower leaves', 'Cabbage cores', 'Olive oil'],
          matchReason: 'Best for denser scraps that benefit from high heat.',
          chefNote: 'Peel the tough outer layer from broccoli stems to expose the tender interior. Roast until caramelized for sweetness.',
        ),
      );
    }

    if (_hasAny(labels, const ['potato', 'pumpkin', 'bean', 'bottle gourd', 'bitter gourd'])) {
      suggestions.add(
        const RecipeSuggestion(
          title: 'Comfort Scrap Soup',
          summary: 'Blend leftover peels and trimmings into a smooth, warming soup.',
          ingredients: ['Potato peels', 'Pumpkin trimmings', 'Bean ends', 'Vegetable stock'],
          matchReason: 'Good for mixed scraps that can be simmered and blended.',
          chefNote: 'Save this recipe for when you have a mix of scraps. Simmer slowly to develop deep flavors.',
        ),
      );
    }

    while (suggestions.length < 3) {
      suggestions.add(
        const RecipeSuggestion(
          title: 'Starter Scrap Frittata',
          summary: 'A flexible fallback recipe that works with almost any logged vegetable scrap.',
          ingredients: ['Mixed scraps', 'Eggs', 'Onion', 'Herbs'],
          matchReason: 'Fallback suggestion to keep the MVP useful even with sparse inventory.',
          chefNote: 'Frittatas are forgiving. Sauté your scraps first to soften them, then pour beaten eggs on top.',
        ),
      );
    }

    return suggestions.take(3).toList();
  }

  /// Suggest recipes given an explicit set of labels (useful for batch previews).
  List<RecipeSuggestion> suggestForLabels(Iterable<String> labelsIterable) {
    final labels = labelsIterable.map((l) => l.toLowerCase()).toSet();

    final suggestions = <RecipeSuggestion>[];

    if (_hasAny(labels, const ['carrot', 'radish', 'cucumber', 'capsicum'])) {
      suggestions.add(
        const RecipeSuggestion(
          title: 'Root-to-Stem Crunch Bowl',
          summary: 'Use crisp vegetable scraps for a bright salad with toasted seeds.',
          ingredients: ['Carrot tops', 'Radish greens', 'Cucumber peels', 'Yogurt dressing'],
          matchReason: 'Works well with fresh, crunchy scraps in the inventory.',
          chefNote: 'The tender greens and peels are more flavorful than you\'d think. Toss with a sharp vinaigrette for best results.',
        ),
      );
    }

    if (_hasAny(labels, const ['broccoli', 'cauliflower', 'cabbage', 'brinjal'])) {
      suggestions.add(
        const RecipeSuggestion(
          title: 'Roasted Scrap Tray Bake',
          summary: 'Roast tougher stems and peels with oil, garlic, and herbs.',
          ingredients: ['Broccoli stems', 'Cauliflower leaves', 'Cabbage cores', 'Olive oil'],
          matchReason: 'Best for denser scraps that benefit from high heat.',
          chefNote: 'Peel the tough outer layer from broccoli stems to expose the tender interior. Roast until caramelized for sweetness.',
        ),
      );
    }

    if (_hasAny(labels, const ['potato', 'pumpkin', 'bean', 'bottle gourd', 'bitter gourd'])) {
      suggestions.add(
        const RecipeSuggestion(
          title: 'Comfort Scrap Soup',
          summary: 'Blend leftover peels and trimmings into a smooth, warming soup.',
          ingredients: ['Potato peels', 'Pumpkin trimmings', 'Bean ends', 'Vegetable stock'],
          matchReason: 'Good for mixed scraps that can be simmered and blended.',
          chefNote: 'Save this recipe for when you have a mix of scraps. Simmer slowly to develop deep flavors.',
        ),
      );
    }

    while (suggestions.length < 3) {
      suggestions.add(
        const RecipeSuggestion(
          title: 'Starter Scrap Frittata',
          summary: 'A flexible fallback recipe that works with almost any logged vegetable scrap.',
          ingredients: ['Mixed scraps', 'Eggs', 'Onion', 'Herbs'],
          matchReason: 'Fallback suggestion to keep the MVP useful even with sparse inventory.',
          chefNote: 'Frittatas are forgiving. Sauté your scraps first to soften them, then pour beaten eggs on top.',
        ),
      );
    }

    return suggestions.take(3).toList();
  }

  bool _hasAny(Set<String> labels, List<String> candidates) {
    return candidates.any(labels.contains);
  }
}
