import 'dart:convert';
import 'package:http/http.dart' as http;

class MealDBService {
  static const String _baseUrl = 'https://www.themealdb.com/api/json/v1/1';

  /// Search recipes by ingredient (e.g., "chicken", "rice")
  Future<List<MealDBRecipe>> searchByIngredient(String ingredient) async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/filter.php?i=${Uri.encodeComponent(ingredient)}'),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['meals'] != null) {
          return (data['meals'] as List)
              .map((meal) => MealDBRecipe.fromJson(meal))
              .toList();
        }
      }
      return [];
    } catch (e) {
      print('Failed to search recipes by ingredient: $e');
      return [];
    }
  }

  /// Get recipe details by ID
  Future<MealDBRecipe?> getRecipeDetails(String id) async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/lookup.php?i=$id'),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['meals'] != null && data['meals'].isNotEmpty) {
          return MealDBRecipe.fromJson(data['meals'][0]);
        }
      }
      return null;
    } catch (e) {
      print('Failed to get recipe details: $e');
      return null;
    }
  }

  /// Search recipes by name
  Future<List<MealDBRecipe>> searchByName(String name) async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/search.php?s=${Uri.encodeComponent(name)}'),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['meals'] != null) {
          return (data['meals'] as List)
              .map((meal) => MealDBRecipe.fromJson(meal))
              .toList();
        }
      }
      return [];
    } catch (e) {
      print('Failed to search recipes by name: $e');
      return [];
    }
  }

  /// Get random recipe
  Future<MealDBRecipe?> getRandomRecipe() async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/random.php'),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['meals'] != null && data['meals'].isNotEmpty) {
          return MealDBRecipe.fromJson(data['meals'][0]);
        }
      }
      return null;
    } catch (e) {
      print('Failed to get random recipe: $e');
      return null;
    }
  }
}

class MealDBRecipe {
  const MealDBRecipe({
    required this.id,
    required this.name,
    required this.category,
    required this.area,
    required this.thumbnail,
    required this.instructions,
    required this.ingredients,
  });

  final String id;
  final String name;
  final String category;
  final String area;
  final String thumbnail;
  final String instructions;
  final List<MealDBIngredient> ingredients;

  factory MealDBRecipe.fromJson(Map<String, dynamic> json) {
    final ingredients = <MealDBIngredient>[];
    
    // Parse ingredients and measures
    for (int i = 1; i <= 20; i++) {
      final ingredient = json['strIngredient$i'] as String?;
      final measure = json['strMeasure$i'] as String?;
      
      if (ingredient != null && ingredient.isNotEmpty) {
        ingredients.add(MealDBIngredient(
          name: ingredient,
          measure: measure ?? '',
        ));
      }
    }

    return MealDBRecipe(
      id: json['idMeal'] as String? ?? '',
      name: json['strMeal'] as String? ?? '',
      category: json['strCategory'] as String? ?? '',
      area: json['strArea'] as String? ?? '',
      thumbnail: json['strMealThumb'] as String? ?? '',
      instructions: json['strInstructions'] as String? ?? '',
      ingredients: ingredients,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'idMeal': id,
      'strMeal': name,
      'strCategory': category,
      'strArea': area,
      'strMealThumb': thumbnail,
      'strInstructions': instructions,
    };
  }
}

class MealDBIngredient {
  const MealDBIngredient({
    required this.name,
    required this.measure,
  });

  final String name;
  final String measure;
}
