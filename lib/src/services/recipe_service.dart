import '../models.dart';
import 'mealdb_service.dart';
import 'package:http/http.dart' as http;
import 'dart:async';
import 'dart:convert';

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

  /// Fetch similar recipe recommendations from the backend ML model.
Future<List<RecipeSuggestion>> fetchSimilarRecipes(String recipeId, {int n = 5}) async {
    final uri = Uri.parse('http://192.168.100.3:8000/recommendations')
        .replace(queryParameters: {'recipe_id': recipeId, 'n': n.toString()});
    try {
      final response = await http
          .get(uri)
          .timeout(const Duration(seconds: 10), onTimeout: () {
        throw TimeoutException('Request to backend timed out');
      });
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final recs = data['recommendations'] as List<dynamic>;
        return recs.map((e) {
          final map = e as Map<String, dynamic>;
          return RecipeSuggestion(
            id: map['recipe_id'].toString(),
            title: map['title'] ?? '',
            summary: map['summary'] ?? '',
            ingredients: List<String>.from(map['ingredients'] ?? []),
            matchReason: map['matchReason'] ?? '',
            chefNote: map['chefNote'],
          );
        }).toList();
      } else {
        print('Failed to fetch recommendations: ${response.statusCode}');
        return [];
      }
    } on TimeoutException catch (e) {
      print('Timeout fetching recommendations: $e');
      return [];
    } catch (e) {
      print('Error fetching recommendations: $e');
      return [];
    }
}

  /// Fetch recipe recommendations from the backend ML model using scrap labels.
  Future<List<RecipeSuggestion>> fetchRecommendationsForLabels(Iterable<String> labels, {int n = 5}) async {
    if (labels.isEmpty) {
      return [];
    }

    final labelQuery = labels.join(',');
    final uri = Uri.parse('http://192.168.100.3:8000/recommendations/by_labels')
        .replace(queryParameters: {'labels': labelQuery, 'n': n.toString()});

    try {
      final response = await http
          .get(uri)
          .timeout(const Duration(seconds: 10), onTimeout: () {
        throw TimeoutException('Request to backend timed out');
      });

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final recs = data['recommendations'] as List<dynamic>;
        return recs.map((e) {
          final map = e as Map<String, dynamic>;
          return RecipeSuggestion(
            id: map['recipe_id'].toString(),
            title: map['title'] ?? '',
            summary: map['summary'] ?? '',
            ingredients: List<String>.from(map['ingredients'] ?? []),
            matchReason: map['matchReason'] ?? '',
            chefNote: map['chefNote'],
          );
        }).toList();
      }

      print('Failed to fetch label recommendations: ${response.statusCode}');
      return [];
    } on TimeoutException catch (e) {
      print('Timeout fetching label recommendations: $e');
      return [];
    } catch (e) {
      print('Error fetching label recommendations: $e');
      return [];
    }
  }

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
  Future<List<RecipeSuggestion>> suggestForLabels(Iterable<String> labelsIterable) async {
    final labels = labelsIterable.toList();
    final normalized = _normalizeLabels(labels);

    final backendRecipes = await fetchRecommendationsForLabels(normalized, n: 5);
    if (backendRecipes.isNotEmpty) {
      return backendRecipes;
    }

    // Try to get recipes from MealDB for each ingredient
    final mealDBRecipes = <RecipeSuggestion>[];
    final matchedIngredients = <String, String>{}; // recipeId -> ingredient
    
    for (final label in normalized) {
      // Map scrap labels to common ingredients for MealDB
      final ingredient = _mapToMealDBIngredient(label);
      if (ingredient != null) {
        final recipes = await _mealDBService.searchByIngredient(ingredient);
        for (final meal in recipes) {
          // Filter recipes to ensure they actually contain the ingredient
          if (_recipeContainsIngredient(meal, ingredient)) {
            final suggestion = _mealDBToSuggestion(meal, ingredient);
            mealDBRecipes.add(suggestion);
            matchedIngredients[meal.id] = ingredient;
          }
        }
      }
    }

    // If MealDB returned recipes, use them
    if (mealDBRecipes.isNotEmpty) {
      // Remove duplicates and limit to top 5
      final uniqueRecipes = <String, RecipeSuggestion>{};
      for (final recipe in mealDBRecipes) {
        if (recipe.id != null && !uniqueRecipes.containsKey(recipe.id)) {
          uniqueRecipes[recipe.id!] = recipe;
        }
      }
      
      // If we got some recipes but they seem unrelated, fallback to static
      if (uniqueRecipes.values.length < 2) {
        return _buildSuggestions(labels);
      }
      
      return uniqueRecipes.values.take(5).toList();
    }

    // Fallback to static recipes
    return _buildSuggestions(labels);
  }

  /// Map scrap labels to MealDB-compatible ingredient names
  String? _mapToMealDBIngredient(String label) {
    final mapping = {
      'banana_peel': 'banana',
      'banana': 'banana',
      'citrus_peel': 'lemon',
      'citrus': 'lemon',
      'orange': 'orange',
      'lemon': 'lemon',
      'lime': 'lime',
      'apple_core_peel': 'apple',
      'apple': 'apple',
      'broccoli_stem': 'broccoli',
      'broccoli': 'broccoli',
      'cabbage_core': 'cabbage',
      'cabbage': 'cabbage',
      'cauliflower_core': 'cauliflower',
      'cauliflower': 'cauliflower',
      'carrot_peel': 'carrot',
      'carrot': 'carrot',
      'cucumber_peel': 'cucumber',
      'cucumber': 'cucumber',
      'onion_skin': 'onion',
      'onion': 'onion',
      'potato_peel': 'potato',
      'potato': 'potato',
      'tomato_trimmings': 'tomato',
      'tomato': 'tomato',
      'tomato peel': 'tomato',
      'tomato peels': 'tomato',
      'leafy_trimmings': 'spinach',
      'spinach': 'spinach',
      'lettuce': 'lettuce',
      'bean_pod': 'green beans',
      'beans': 'green beans',
      'corn_husk': 'corn',
      'corn': 'corn',
      'eggshells': 'egg',
      'egg': 'egg',
      'coffee': 'coffee',
      'coffee grounds': 'coffee',
    };

    final lowerLabel = label.toLowerCase().trim();
    
    // Try exact match first
    if (mapping.containsKey(lowerLabel)) {
      return mapping[lowerLabel];
    }

    // Try partial match for compound labels
    for (final entry in mapping.entries) {
      if (lowerLabel.contains(entry.key) || entry.key.contains(lowerLabel)) {
        return entry.value;
      }
    }

    // Try direct mapping if label is a common ingredient
    if (lowerLabel.contains('chicken')) return 'chicken';
    if (lowerLabel.contains('beef')) return 'beef';
    if (lowerLabel.contains('pork')) return 'pork';
    if (lowerLabel.contains('rice')) return 'rice';
    if (lowerLabel.contains('pasta')) return 'pasta';

    return null;
  }

  /// Check if a recipe actually contains the specified ingredient
  bool _recipeContainsIngredient(MealDBRecipe meal, String ingredient) {
    final lowerIngredient = ingredient.toLowerCase();
    for (final ing in meal.ingredients) {
      if (ing.name.toLowerCase().contains(lowerIngredient) || 
          lowerIngredient.contains(ing.name.toLowerCase())) {
        return true;
      }
    }
    return false;
  }

  /// Search MealDB for recipes based on ingredient
  Future<List<RecipeSuggestion>> searchMealDB(String ingredient) async {
    try {
      final recipes = await _mealDBService.searchByIngredient(ingredient);
      return recipes.map((meal) => _mealDBToSuggestion(meal, ingredient)).toList();
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

  RecipeSuggestion _mealDBToSuggestion(MealDBRecipe meal, String matchedIngredient) {
    return RecipeSuggestion(
      id: meal.id,
      title: meal.name,
      summary: '${meal.category} • ${meal.area}',
      ingredients: meal.ingredients.map((ing) => '${ing.name} (${ing.measure})').toList(),
      matchReason: 'Contains $matchedIngredient',
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

    // Prioritize recipes that directly use available scraps
    return (tagMatches * 2.0) + (keywordMatches * 1.5) + diversityBoost;
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
    reasons.add('Uses ${keywordMatches.take(3).join(', ')} from your bin');
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
