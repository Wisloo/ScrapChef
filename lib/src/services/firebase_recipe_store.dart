import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:async';

import '../models.dart';

class FirebaseRecipeStore {
  static const String _usersCollection = 'users';
  static const String _recipesSubcollection = 'savedRecipes';

  final _firestore = FirebaseFirestore.instance;

  /// Save or update a recipe for the current user
  Future<void> upsertRecipe(String userId, SavedRecipeRecord record) async {
    try {
      await _firestore
          .collection(_usersCollection)
          .doc(userId)
          .collection(_recipesSubcollection)
          .doc(record.recipeId)
          .set(record.toJson());
    } catch (e) {
      throw Exception('Failed to save recipe: $e');
    }
  }

  /// Load all saved recipes for a user
  Future<List<SavedRecipeRecord>> loadRecipes(String userId) async {
    try {
      final snapshot = await _firestore
          .collection(_usersCollection)
          .doc(userId)
          .collection(_recipesSubcollection)
          .orderBy('savedAt', descending: true)
          .get()
          .timeout(const Duration(seconds: 8));

      return snapshot.docs
          .map((doc) => SavedRecipeRecord.fromJson(doc.data()))
          .toList();
    } catch (e) {
      print('Failed to load recipes: $e');
      // Return empty list instead of throwing to prevent app from getting stuck
      return <SavedRecipeRecord>[];
    }
  }

  /// Listen to saved recipes in real-time
  Stream<List<SavedRecipeRecord>> watchRecipes(String userId) {
    return _firestore
        .collection(_usersCollection)
        .doc(userId)
        .collection(_recipesSubcollection)
        .orderBy('savedAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => SavedRecipeRecord.fromJson(doc.data()))
            .toList());
  }

  /// Delete a saved recipe
  Future<void> deleteRecipe(String userId, String recipeId) async {
    try {
      await _firestore
          .collection(_usersCollection)
          .doc(userId)
          .collection(_recipesSubcollection)
          .doc(recipeId)
          .delete();
    } catch (e) {
      throw Exception('Failed to delete recipe: $e');
    }
  }

  /// Update recipe notes
  Future<void> updateRecipeNotes(String userId, String recipeId, String notes) async {
    try {
      await _firestore
          .collection(_usersCollection)
          .doc(userId)
          .collection(_recipesSubcollection)
          .doc(recipeId)
          .update({'userNotes': notes});
    } catch (e) {
      throw Exception('Failed to update recipe notes: $e');
    }
  }
}
