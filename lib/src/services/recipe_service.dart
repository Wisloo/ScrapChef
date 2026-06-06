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

  'Orange peel',

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



  /// Find recipes using the RAG API based on a natural language query.

  Future<List<RecipeSuggestion>> findRecipes(String query, {int topK = 5, List<String>? userIngredients}) async {

    print('🔍 findRecipes called with query: "$query"');

    // Use Hugging Face Spaces URL
    final uri = Uri.parse('https://wisloo-recipe-rag-api.hf.space/recommend');

    

    try {

      final response = await http

          .post(

            uri,

            headers: {'Content-Type': 'application/json'},

            body: jsonEncode({
              'query': query, 
              'top_k': topK, 
              'use_scrap_mapping': true,
              'user_ingredients': userIngredients ?? [],
            }),

          )

          .timeout(const Duration(seconds: 30), onTimeout: () {

        throw TimeoutException('Request to RAG API timed out');

      });



      if (response.statusCode == 200) {
        print('✅ RAG API success: ${response.statusCode}');
        final data = jsonDecode(response.body) as List<dynamic>;
        print('✅ RAG API returned ${data.length} recipes');

        

        return data.map((e) {

          final map = e as Map<String, dynamic>;

          return RecipeSuggestion(

            id: map['title']?.toString(),

            title: map['title'] ?? '',

            summary: 'AI-recommended based on your query',

            ingredients: (map['ingredients'] as String).split(',').map((s) => s.trim()).toList(),

            matchReason: 'Similarity: ${((map['similarity_score'] as num? ?? 0.0) * 100).toStringAsFixed(1)}%',

            chefNote: map['instructions'] as String?,

            imageUrl: map['image_url'] as String?,

          );

        }).toList();

      } else {
        print('❌ RAG API failed with status: ${response.statusCode}');
        print('❌ Response body: ${response.body}');
        return [];

      }

    } on TimeoutException catch (e) {

      print('Timeout finding recipes: $e');

      return [];

    } catch (e) {

      print('Error finding recipes: $e');

      return [];

    }

  }



  /// Fetch recipe recommendations from the backend ML model using scrap labels.

  Future<List<RecipeSuggestion>> fetchRecommendationsForLabels(Iterable<String> labels, {int n = 5}) async {

    if (labels.isEmpty) {

      return [];

    }



    // Use RAG API endpoint
    final uri = Uri.parse('http://192.168.100.3:8000/recommend-from-scraps');



    try {

      final response = await http

          .post(
            uri,
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({'scraps': labels.toList(), 'top_k': n}),
          )

          .timeout(const Duration(seconds: 30), onTimeout: () {

        throw TimeoutException('Request to RAG API timed out');

      });



      if (response.statusCode == 200) {

        final data = jsonDecode(response.body) as List<dynamic>;

        return data.map((e) {

          final map = e as Map<String, dynamic>;

          return RecipeSuggestion(

            id: map['title']?.toString(),

            title: map['title'] ?? '',

            summary: 'AI-recommended based on your scraps',

            ingredients: (map['ingredients'] as String).split(',').map((s) => s.trim()).toList(),

            matchReason: 'Similarity: ${((map['similarity_score'] as num? ?? 0.0) * 100).toStringAsFixed(1)}%',

            chefNote: map['instructions'] as String?,

            imageUrl: map['image_url'] as String?,

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
      print('✅ Using RAG API recipes: ${backendRecipes.length} recipes');
      return backendRecipes;

    }
    print('❌ RAG API returned empty, trying MealDB...');



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
      print('✅ Using MealDB recipes: ${mealDBRecipes.length} recipes');

      // Remove duplicates and limit to top 5

      final uniqueRecipes = <String, RecipeSuggestion>{};

      for (final recipe in mealDBRecipes) {

        if (recipe.id != null && !uniqueRecipes.containsKey(recipe.id)) {

          uniqueRecipes[recipe.id!] = recipe;

        }

      }

      

      // If we got some recipes but they seem unrelated, fallback to static

      if (uniqueRecipes.values.length < 2) {
        print('❌ MealDB returned < 2 recipes, falling back to static');
        return _buildSuggestions(labels);

      }

      

      return uniqueRecipes.values.take(5).toList();

    }



    // Fallback to static recipes
    print('❌ MealDB failed, falling back to static recipes');
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

    summary: 'Transform citrus peels into a vibrant, naturally sweet syrup perfect for cocktails, lemonade, or drizzling over pancakes. The zesty flavor intensifies with gentle simmering.',

    ingredients: ['Citrus peels (orange, lemon, lime)', 'Sugar', 'Water', 'Cinnamon stick (optional)'],

    tags: {'bright', 'zest', 'sweet', 'preserves'},

    keywords: {'citrus_peel', 'orange', 'clementine', 'lemon', 'lime'},

    chefNote: 'Step 1: Rinse peels thoroughly and remove white pith. Step 2: Simmer peels with 1 cup water for 10 minutes. Step 3: Add sugar (1:1 ratio), simmer 5 more minutes. Step 4: Cool and strain. Store refrigerated for up to 2 weeks.',

  ),

  _RecipeProfile(

    title: 'Banana Peel Muffins',

    summary: 'Create moist, naturally sweet muffins using banana peels instead of bananas. The peels add subtle sweetness and fiber without overpowering the classic muffin flavor.',

    ingredients: ['Banana peels (well-rinsed)', 'All-purpose flour', 'Eggs', 'Baking powder', 'Cinnamon', 'Vanilla extract'],

    tags: {'sweet', 'bake', 'breakfast'},

    keywords: {'banana_peel', 'banana', 'muffin'},

    chefNote: 'Step 1: Steam or boil peels for 10 minutes until soft. Step 2: Blend cooked peels into a smooth paste. Step 3: Mix with wet ingredients (eggs, vanilla). Step 4: Fold into dry ingredients. Step 5: Bake at 375°F for 20-25 minutes.',

  ),

  _RecipeProfile(

    title: 'Broccoli Stem Stir-Fry',

    summary: 'Give broccoli stems new life with this quick stir-fry that highlights their crunch and flavor. Ready in under 10 minutes with minimal prep.',

    ingredients: ['Broccoli stems', 'Garlic', 'Soy sauce', 'Sesame oil', 'Ginger', 'Red pepper flakes (optional)'],

    tags: {'savory', 'quick', 'vegetable'},

    keywords: {'broccoli_stem', 'broccoli', 'cabbage_core', 'stir-fry'},

    chefNote: 'Step 1: Peel outer fibrous layer from stems. Step 2: Cut into matchsticks or thin slices. Step 3: Heat oil in wok, add garlic and ginger. Step 4: Stir-fry stems 3-4 minutes until tender-crisp. Step 5: Add sauce and serve immediately.',

  ),

  _RecipeProfile(

    title: 'Potato Peel Chips',

    summary: 'Crispy baked chips made entirely from potato peels. A zero-waste snack that delivers all the flavor with none of the oil absorption of frying.',

    ingredients: ['Potato peels (cleaned)', 'Olive oil', 'Sea salt', 'Black pepper', 'Paprika or garlic powder'],

    tags: {'crisp', 'snack', 'vegetable', 'appetizer'},

    keywords: {'potato_peel', 'potato', 'chips', 'crispy'},

    chefNote: 'Step 1: Rinse peels thoroughly and pat dry. Step 2: Toss with oil and seasonings. Step 3: Arrange in single layer on baking sheet. Step 4: Bake at 400°F for 15-20 minutes, flip halfway. Step 5: Cool 5 minutes until crisp.',

  ),

  _RecipeProfile(

    title: 'Onion Skin Stock',

    summary: 'Create a rich, golden broth using only onion skins and aromatics. This zero-waste stock adds depth to soups, stews, and grain dishes without any waste.',

    ingredients: ['Onion skins (from yellow/white onions)', 'Corn husks', 'Garlic cloves', 'Peppercorns', 'Bay leaf', 'Water'],

    tags: {'stock', 'savory', 'vegetable', 'broth'},

    keywords: {'onion_skin', 'corn_husk', 'stock', 'broth'},

    chefNote: 'Step 1: Collect and rinse skins/husks. Step 2: Bring 8 cups water to boil with skins. Step 3: Reduce heat, simmer 30 minutes. Step 4: Add aromatics for last 10 minutes. Step 5: Strain through fine mesh, cool, refrigerate.',

  ),

  _RecipeProfile(

    title: 'Leafy Trimmings Pesto',

    summary: 'Whip up a vibrant green pesto using any leafy vegetable scraps. Perfect for pasta, grain bowls, or as a sandwich spread. The flavor is fresh and herbaceous.',

    ingredients: ['Leafy trimmings (spinach, kale, beet greens)', 'Nuts or seeds (pine, walnuts)', 'Olive oil', 'Lemon juice', 'Salt', 'Garlic (optional)'],

    tags: {'fresh', 'quick', 'vegetable', 'sauce'},

    keywords: {'leafy_trimmings', 'spinach', 'lettuce', 'pesto'},

    chefNote: 'Step 1: Blanch leafy greens for 30 seconds, then ice bath. Step 2: Squeeze out excess water. Step 3: Blend with nuts, garlic, and lemon juice. Step 4: Slowly add oil while blending. Step 5: Season and use immediately or store refrigerated.',

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

