import '../models.dart';
import 'mealdb_service.dart';

class RecipeService {
  RecipeService();

  final MealDBService _mealDBService = MealDBService();

  /// Friendly labels for manual pickers and fallbacks.
  static const List<String> supportedLabels = [
    'Banana peel',
    'Citrus peel',
    'Apple core & peel',
    'Broccoli stem',
    'Cabbage core',
    'Cauliflower core',
    'Carrot peel',
    'Cucumber peel',
    'Onion skin',
    'Potato peel',
    'Tomato trimmings',
    'Leafy trimmings',
    'Bean pod',
    'Corn husk',
    'Coffee grounds',
    'Eggshells',
    'Mixed fruit scraps',
    'Mixed vegetable scraps',
  ];

  static const Map<String, String> _labelAliases = {
    'orange peels': 'citrus_peel',
    'orange peel': 'citrus_peel',
    'orange': 'citrus_peel',
    'lemon peels': 'citrus_peel',
    'lemon peel': 'citrus_peel',
    'lemon': 'citrus_peel',
    'lime peels': 'citrus_peel',
    'lime peel': 'citrus_peel',
    'lime': 'citrus_peel',
    'grapefruit peel': 'citrus_peel',
    'citrus peels': 'citrus_peel',
    'citrus peel': 'citrus_peel',
    'banana peels': 'banana_peel',
    'banana peel': 'banana_peel',
    'banana': 'banana_peel',
    'apple cores': 'apple_core_peel',
    'apple core': 'apple_core_peel',
    'apple peels': 'apple_core_peel',
    'apple peel': 'apple_core_peel',
    'coffee grounds': 'food_waste',
    'coffee ground': 'food_waste',
    'eggshells': 'food_waste',
    'eggshell': 'food_waste',
    'potato peels': 'potato_peel',
    'potato peel': 'potato_peel',
    'potato skins': 'potato_peel',
    'onion skins': 'onion_skin',
    'onion skin': 'onion_skin',
    'carrot peels': 'carrot_peel',
    'carrot peel': 'carrot_peel',
    'broccoli stems': 'broccoli_stem',
    'broccoli stem': 'broccoli_stem',
    'leafy greens': 'leafy_trimmings',
    'salad trimmings': 'leafy_trimmings',
    'mixed scraps': 'food_waste',
    'food scraps': 'food_waste',
    'food scrap': 'food_waste',
    'apple core & peel': 'apple_core_peel',
    'cabbage core': 'cabbage_core',
    'cauliflower core': 'cauliflower_core',
    'cucumber peel': 'cucumber_peel',
    'tomato trimmings': 'tomato_trimmings',
    'bean pod': 'bean_pod',
    'corn husk': 'corn_husk',
    'mixed fruit scraps': 'fruit_scraps',
    'mixed vegetable scraps': 'vegetable_scraps',
    'vegetable scraps': 'vegetable_scraps',
    'fruit scraps': 'fruit_scraps',
  };

  List<RecipeSuggestion> suggest(List<ScrapItem> inventory) {
    final labels = inventory.map((item) => item.label).toList();
    return _buildSuggestions(labels);
  }

  /// Suggest recipes given an explicit set of labels (useful for batch previews).
  List<RecipeSuggestion> suggestForLabels(Iterable<String> labelsIterable) {
    return _buildSuggestions(labelsIterable.toList());
  }

  /// Search MealDB for recipes based on ingredient
  Future<List<RecipeSuggestion>> searchMealDB(String ingredient) async {
    try {
      final recipes = await _mealDBService.searchByIngredient(ingredient);
      return recipes.map((meal) => _mealDBToSuggestion(meal)).toList();
    } catch (e) {
      print('Failed to search MealDB: $e');
      return [];
    }
  }

  List<RecipeSuggestion> _buildSuggestions(List<String> labels) {
    final normalized = _normalizeLabels(labels);
    final labelTags = _collectTags(normalized);

    final scored = _recipes.map((recipe) {
      final score = _scoreRecipe(recipe, normalized, labelTags);
      return (recipe: recipe, score: score);
    }).toList();

    scored.sort((a, b) => b.score.compareTo(a.score));

    final top = scored.where((s) => s.score > 0).take(3).map((s) {
      return _toSuggestion(s.recipe, normalized, labelTags);
    }).toList();

    if (top.length >= 3) {
      return top;
    }

    final fallback = _fallbacks.take(3 - top.length).map((r) {
      return _toSuggestion(r, normalized, labelTags);
    }).toList();

    return [...top, ...fallback];
  }

  RecipeSuggestion _toSuggestion(
    _RecipeProfile recipe,
    Set<String> labels,
    Set<String> tags,
  ) {
    final matchReason = _buildMatchReason(recipe, labels, tags);
    return RecipeSuggestion(
      title: recipe.title,
      summary: recipe.summary,
      ingredients: recipe.ingredients,
      matchReason: matchReason,
      chefNote: recipe.chefNote,
    );
  }

  RecipeSuggestion _mealDBToSuggestion(MealDBRecipe meal) {
    return RecipeSuggestion(
      id: meal.id,
      title: meal.name,
      summary: '${meal.category} • ${meal.area}',
      ingredients: meal.ingredients.map((ing) => '${ing.name} (${ing.measure})').toList(),
      matchReason: 'From MealDB database',
      chefNote: meal.instructions,
    );
  }

  String _canonicalizeLabel(String label) {
    final value = label.toLowerCase().trim();
    if (value.isEmpty) return value;
    return _labelAliases[value] ?? value;
  }

  Set<String> _normalizeLabels(Iterable<String> labels) {
    final normalized = <String>{};
    for (final label in labels) {
      final value = label.toLowerCase().trim();
      if (value.isEmpty) continue;

      final canonical = _canonicalizeLabel(value);
      normalized.add(value);
      normalized.add(canonical);
      normalized.addAll(value.split(RegExp(r'[\s\-_]+')));
      normalized.addAll(canonical.split(RegExp(r'[\s\-_]+')));
    }
    if (normalized.contains('food') && normalized.contains('waste')) {
      normalized.add('food_waste');
    }
    if (normalized.contains('peel') || normalized.contains('peels')) {
      normalized.add('citrus_peel');
    }
    return normalized;
  }

  Set<String> _collectTags(Set<String> labels) {
    final tags = <String>{};
    for (final label in labels) {
      tags.addAll(_tagsForLabel(label));
    }
    if (tags.isEmpty && labels.contains('food_waste')) {
      tags.addAll(const ['mixed', 'scrap', 'simmer']);
    }
    return tags;
  }

  Set<String> _tagsForLabel(String label) {
    const mapping = {
      'banana_peel': ['sweet', 'soft', 'bake'],
      'citrus_peel': ['bright', 'aromatic', 'zest'],
      'apple_core_peel': ['sweet', 'fruity', 'bake'],
      'broccoli_stem': ['brassica', 'roast', 'savory'],
      'cabbage_core': ['brassica', 'simmer', 'savory'],
      'cauliflower_core': ['brassica', 'roast', 'savory'],
      'carrot_peel': ['root', 'sweet', 'crunch'],
      'cucumber_peel': ['fresh', 'crunch', 'bright'],
      'onion_skin': ['aromatic', 'stock', 'savory'],
      'potato_peel': ['starchy', 'crisp', 'comfort'],
      'tomato_trimmings': ['juicy', 'simmer', 'bright'],
      'leafy_trimmings': ['leafy', 'quick', 'tender'],
      'bean_pod': ['green', 'simmer', 'savory'],
      'corn_husk': ['aromatic', 'stock', 'savory'],
      'fruit_scraps': ['mixed', 'sweet', 'bake'],
      'vegetable_scraps': ['mixed', 'savory', 'simmer'],
      'carrot': ['root', 'sweet', 'crunch'],
      'radish': ['root', 'peppery', 'crunch'],
      'cucumber': ['watery', 'fresh', 'crunch'],
      'capsicum': ['fresh', 'sweet', 'crunch'],
      'broccoli': ['brassica', 'roast', 'savory'],
      'cauliflower': ['brassica', 'roast', 'savory'],
      'cabbage': ['brassica', 'simmer', 'savory'],
      'brinjal': ['roast', 'savory', 'tender'],
      'potato': ['starchy', 'simmer', 'comfort'],
      'pumpkin': ['starchy', 'sweet', 'simmer'],
      'bean': ['green', 'simmer', 'savory'],
      'bottle': ['gourd', 'simmer', 'light'],
      'bitter': ['gourd', 'bitter', 'simmer'],
      'gourd': ['gourd', 'simmer', 'light'],
      'tomato': ['juicy', 'simmer', 'bright'],
      'onion': ['aromatic', 'simmer', 'savory'],
      'spinach': ['leafy', 'quick', 'tender'],
      'lettuce': ['leafy', 'fresh', 'crunch'],
      'food_waste': ['mixed', 'scrap', 'simmer'],
      'orange': ['bright', 'aromatic', 'zest'],
      'lemon': ['bright', 'aromatic', 'zest'],
      'lime': ['bright', 'aromatic', 'zest'],
      'peel': ['bright', 'aromatic', 'zest'],
      'peels': ['bright', 'aromatic', 'zest'],
      'core': ['sweet', 'fruity', 'bake'],
      'cores': ['sweet', 'fruity', 'bake'],
      'grounds': ['mixed', 'scrap', 'simmer'],
      'eggshell': ['mixed', 'scrap', 'simmer'],
      'eggshells': ['mixed', 'scrap', 'simmer'],
      'coffee': ['mixed', 'scrap', 'simmer'],
      'stem': ['brassica', 'roast', 'savory'],
      'stems': ['brassica', 'roast', 'savory'],
      'skin': ['aromatic', 'stock', 'savory'],
      'skins': ['aromatic', 'stock', 'savory'],
      'trimmings': ['leafy', 'quick', 'tender'],
    };

    for (final entry in mapping.entries) {
      if (label.contains(entry.key)) {
        return entry.value.toSet();
      }
    }

    return {};
  }

  double _scoreRecipe(
    _RecipeProfile recipe,
    Set<String> labels,
    Set<String> tags,
  ) {
    final tagMatches = recipe.tags.intersection(tags).length;
    final keywordMatches = recipe.keywords.intersection(labels).length;
    final diversityBoost = (labels.length.clamp(0, 6)) * 0.2;

    return (tagMatches * 2.0) + (keywordMatches * 1.0) + diversityBoost;
  }

  String _buildMatchReason(
    _RecipeProfile recipe,
    Set<String> labels,
    Set<String> tags,
  ) {
    final tagMatches = recipe.tags.intersection(tags);
    final keywordMatches = recipe.keywords.intersection(labels);

    if (tagMatches.isEmpty && keywordMatches.isEmpty) {
      return 'A versatile recipe that works well with mixed scraps.';
    }

    final reasons = <String>[];
    if (keywordMatches.isNotEmpty) {
      reasons.add('Matches ${keywordMatches.take(3).join(', ')} in your scraps');
    }
    if (tagMatches.isNotEmpty) {
      reasons.add('Fits ${tagMatches.take(2).join(' & ')} style cooking');
    }

    return reasons.join(' • ');
  }
}

class _RecipeProfile {
  const _RecipeProfile({
    required this.title,
    required this.summary,
    required this.ingredients,
    required this.tags,
    required this.keywords,
    this.chefNote,
  });

  final String title;
  final String summary;
  final List<String> ingredients;
  final Set<String> tags;
  final Set<String> keywords;
  final String? chefNote;
}

const List<_RecipeProfile> _recipes = [
  _RecipeProfile(
    title: 'Citrus Peel Syrup',
    summary: 'Turn orange and citrus peels into a fragrant syrup for drinks and desserts.',
    ingredients: ['Citrus peels', 'Sugar', 'Water', 'Ginger'],
    tags: {'bright', 'zest', 'sweet'},
    keywords: {'citrus_peel', 'orange', 'clementine'},
    chefNote: 'Simmer the peels briefly so the syrup stays bright, not bitter.',
  ),
  _RecipeProfile(
    title: 'Banana Peel Muffins',
    summary: 'Use soft banana peels in a naturally sweet breakfast bake.',
    ingredients: ['Banana peels', 'Flour', 'Eggs', 'Cinnamon'],
    tags: {'sweet', 'bake'},
    keywords: {'banana_peel', 'banana'},
    chefNote: 'Blend the peels finely so the texture stays tender.',
  ),
  _RecipeProfile(
    title: 'Broccoli Stem Stir-Fry',
    summary: 'Quickly cook broccoli stems and brassica cores until crisp-tender.',
    ingredients: ['Broccoli stems', 'Garlic', 'Soy sauce', 'Sesame oil'],
    tags: {'savory', 'quick'},
    keywords: {'broccoli_stem', 'broccoli', 'cabbage_core'},
    chefNote: 'Slice stems thinly so they cook at the same speed as the florets.',
  ),
  _RecipeProfile(
    title: 'Potato Peel Chips',
    summary: 'Bake potato skins into a salty, crunchy snack.',
    ingredients: ['Potato peels', 'Olive oil', 'Paprika', 'Salt'],
    tags: {'crisp', 'snack'},
    keywords: {'potato_peel', 'potato'},
    chefNote: 'Spread the peels in a single layer for maximum crispiness.',
  ),
  _RecipeProfile(
    title: 'Onion Skin Stock',
    summary: 'Use onion skins and corn husks for a deep, golden stock.',
    ingredients: ['Onion skins', 'Corn husks', 'Water', 'Peppercorns'],
    tags: {'stock', 'savory'},
    keywords: {'onion_skin', 'corn_husk'},
    chefNote: 'Strain well before using so the broth stays clean and clear.',
  ),
  _RecipeProfile(
    title: 'Leafy Trimmings Pesto',
    summary: 'Blend greens into a bright sauce for pasta or toast.',
    ingredients: ['Leafy trimmings', 'Nuts', 'Olive oil', 'Lemon'],
    tags: {'fresh', 'quick'},
    keywords: {'leafy_trimmings', 'spinach', 'lettuce'},
  ),
];

const List<_RecipeProfile> _fallbacks = [
  _RecipeProfile(
    title: 'Everyday Scrap Frittata',
    summary: 'A flexible fallback that works with nearly any scraps.',
    ingredients: ['Mixed scraps', 'Eggs', 'Onion', 'Herbs'],
    tags: {'mixed', 'comfort'},
    keywords: {'food_waste', 'scrap', 'banana_peel', 'citrus_peel', 'broccoli_stem'},
    chefNote: 'Sauté scraps first to soften them, then pour beaten eggs on top.',
  ),
  _RecipeProfile(
    title: 'Quick Scrap Fried Rice',
    summary: 'Toss chopped scraps into a sizzling rice stir-fry.',
    ingredients: ['Mixed scraps', 'Cooked rice', 'Soy sauce'],
    tags: {'quick', 'savory'},
    keywords: {'food_waste', 'scrap', 'potato_peel', 'cabbage_core'},
  ),
  _RecipeProfile(
    title: 'Herby Scrap Pesto',
    summary: 'Blend tender greens into a punchy sauce.',
    ingredients: ['Leafy scraps', 'Nuts', 'Olive oil'],
    tags: {'fresh', 'quick'},
    keywords: {'leafy', 'spinach', 'lettuce', 'leafy_trimmings'},
  ),
];
