import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:async';

import '../models.dart';

class FirebaseScrapStore {
  static const String _usersCollection = 'users';
  static const String _scrapsSubcollection = 'scraps';

  final _firestore = FirebaseFirestore.instance;

  /// Save a scrap for the current user
  Future<void> saveScrap(String userId, ScrapItem scrap) async {
    try {
      final docRef = await _firestore
          .collection(_usersCollection)
          .doc(userId)
          .collection(_scrapsSubcollection)
          .add(scrap.toJson());
      print('Scrap saved with ID: ${docRef.id}');
    } catch (e) {
      print('Failed to save scrap: $e');
      throw Exception('Failed to save scrap: $e');
    }
  }

  /// Load all scraps for a user
  Future<List<ScrapItem>> loadScraps(String userId) async {
    try {
      print('Loading scraps for user: $userId');
      final snapshot = await _firestore
          .collection(_usersCollection)
          .doc(userId)
          .collection(_scrapsSubcollection)
          .orderBy('loggedAt', descending: true)
          .get()
          .timeout(const Duration(seconds: 8));

      print('Loaded ${snapshot.docs.length} scraps');
      return snapshot.docs
          .map((doc) => ScrapItem.fromJson(doc.data()))
          .toList();
    } catch (e) {
      print('Failed to load scraps: $e');
      // Return empty list instead of throwing to prevent app from getting stuck
      return <ScrapItem>[];
    }
  }

  /// Listen to scraps in real-time
  Stream<List<ScrapItem>> watchScraps(String userId) {
    return _firestore
        .collection(_usersCollection)
        .doc(userId)
        .collection(_scrapsSubcollection)
        .orderBy('loggedAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => ScrapItem.fromJson(doc.data()))
            .toList());
  }

  /// Delete a scrap
  Future<void> deleteScrap(String userId, String scrapId) async {
    try {
      await _firestore
          .collection(_usersCollection)
          .doc(userId)
          .collection(_scrapsSubcollection)
          .doc(scrapId)
          .delete();
    } catch (e) {
      throw Exception('Failed to delete scrap: $e');
    }
  }

  /// Clear all scraps for a user
  Future<void> clearAllScraps(String userId) async {
    try {
      final snapshot = await _firestore
          .collection(_usersCollection)
          .doc(userId)
          .collection(_scrapsSubcollection)
          .get();

      for (final doc in snapshot.docs) {
        await doc.reference.delete();
      }
    } catch (e) {
      throw Exception('Failed to clear scraps: $e');
    }
  }
}
