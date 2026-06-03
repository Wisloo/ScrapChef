/// Local SBERT inference wrapper for on-device recommendation generation.
/// Uses TensorFlow Lite to run inference and compute recipe similarity.

import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:tflite_flutter/tflite_flutter.dart';

class SBertInference {
  static bool _initialized = false;
  static Interpreter? _interpreter;

  // Recipe data loaded from assets
  static List<String> _recipeIds = [];
  static List<List<double>> _recipeEmbeddings = [];
  static List<Map<String, dynamic>> _recipeMetadata = [];

  /// Initializes the inference module. Must be called before other methods.
  static Future<void> initialize() async {
    if (_initialized) return;

    try {
      // Load the TFLite model from assets
      final modelData = await rootBundle.load('assets/models/sbert.tflite');
      final tempDir = await getTemporaryDirectory();
      final modelFile = File('${tempDir.path}/sbert.tflite');
      await modelFile.writeAsBytes(modelData.buffer.asUint8List());
      _interpreter = await Interpreter.fromFile(modelFile);

      // Load pre-computed recipe embeddings
      await _loadRecipeData();

      _initialized = true;
    } catch (e) {
      print('Failed to initialize SBERT: $e');
      rethrow;
    }
  }

  /// Loads recipe embeddings and metadata from assets.
  static Future<void> _loadRecipeData() async {
    try {
      final jsonString = await rootBundle.loadString('assets/recipe_embeddings.json');
      final data = jsonDecode(jsonString) as Map<String, dynamic>;

      _recipeIds = List<String>.from(data['ids'] as List);
      _recipeMetadata = (data['metadata'] as List).cast<Map<String, dynamic>>();

      // Parse embeddings (list of lists)
      final rawEmbeddings = data['embeddings'] as List;
      _recipeEmbeddings = rawEmbeddings.map((e) {
        return List<double>.from(e as List);
      }).toList();
    } catch (e) {
      print('Failed to load recipe data: $e');
    }
  }

  /// Runs inference on a single text input and returns the embedding vector.
  static Future<List<double>> runInference(String text) async {
    if (!_initialized) {
      await initialize();
    }
    if (_interpreter == null) {
      throw StateError('SBERT interpreter not initialized');
    }

    try {
      // Tokenize input (simplified - in production use proper tokenizer)
      final tokens = _tokenize(text);

      // Prepare input tensor
      final input = [tokens];

      // Prepare output tensor
      final output = List<List<double>>.filled(1, List<double>.filled(768, 0));

      // Run inference
      _interpreter!.run(input, output);

      return output[0];
    } catch (e) {
      print('Inference failed: $e');
      return List<double>.filled(768, 0);
    }
  }

  /// Retrieves the top-N most similar recipes for a query embedding.
  static List<Map<String, dynamic>> getTopNRecipes(List<double> queryEmbedding, {int n = 5}) {
    if (_recipeEmbeddings.isEmpty) {
      throw StateError('Recipe embeddings not loaded');
    }

    final scored = <Map<String, dynamic>>[];
    for (int i = 0; i < _recipeEmbeddings.length; i++) {
      final similarity = cosineSimilarity(queryEmbedding, _recipeEmbeddings[i]);
      scored.add({
        'index': i,
        'similarity': similarity,
        'metadata': _recipeMetadata[i],
      });
    }

    // Sort by similarity descending
    scored.sort((a, b) => (b['similarity'] as double).compareTo(a['similarity'] as double));

    return scored.take(n).toList();
  }

  /// Retrieves relevant recipes for a free‑text query.
  static Future<List<Map<String, dynamic>>> retrieveRelevantRecipes(String query, {int n = 5}) async {
    final queryEmbedding = await runInference(query);
    return getTopNRecipes(queryEmbedding, n: n);
  }

  /// Disposes of resources.
  static void dispose() {
    _interpreter?.close();
    _interpreter = null;
    _initialized = false;
  }

  /// Simple tokenization (placeholder - replace with proper BERT tokenizer).
  static List<int> _tokenize(String text) {
    // This is a simplified placeholder.
    // In production, implement proper WordPiece tokenization.
    final words = text.toLowerCase().split(RegExp(r'\s+'));
    return words.map((w) => w.hashCode % 30000).toList();
  }

  /// Computes cosine similarity between two embedding vectors.
  static double cosineSimilarity(List<double> a, List<double> b) {
    if (a.length != b.length) return 0.0;

    double dot = 0.0, normA = 0.0, normB = 0.0;
    for (int i = 0; i < a.length; i++) {
      dot += a[i] * b[i];
      normA += a[i] * a[i];
      normB += b[i] * b[i];
    }

    if (normA == 0 || normB == 0) return 0.0;
    return dot / (math.sqrt(normA) * math.sqrt(normB));
  }
}