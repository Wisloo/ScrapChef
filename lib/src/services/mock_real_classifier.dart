import 'dart:io';
import 'dart:math';
import 'package:flutter/services.dart';

/// Mock real classifier for testing without TFLite issues
class MockRealClassifier {
  static const String MODEL_PATH = 'assets/models/food_classifier_full.tflite';
  static const String LABELS_PATH = 'assets/models/class_names_full.txt';
  
  List<String>? _labels;
  bool _isLoaded = false;
  
  bool get isLoaded => _isLoaded;
  List<String>? get labels => _labels;
  
  /// Initialize the classifier by loading labels
  Future<void> initialize() async {
    try {
      await _loadLabels();
      _isLoaded = true;
      print('MockRealClassifier initialized successfully');
    } catch (e) {
      throw Exception('Failed to initialize classifier: $e');
    }
  }
  
  /// Load class labels
  Future<void> _loadLabels() async {
    final labelData = await rootBundle.loadString(LABELS_PATH);
    _labels = labelData.split('\n').where((s) => s.isNotEmpty).toList();
  }
  
  /// Mock classify an image file (simulates AI classification)
  Future<ClassificationResult> classifyImage(File imageFile) async {
    if (!_isLoaded) {
      throw Exception('Classifier not initialized');
    }
    
    // Simulate processing delay
    await Future.delayed(const Duration(milliseconds: 500));
    
    // Mock classification with realistic food items
    final mockClasses = [
      'Apple', 'Banana', 'Carrot', 'Tomato', 'Lettuce',
      'Orange', 'Potato', 'Onion', 'Broccoli', 'Spinach',
      'Strawberry', 'Grape', 'Cucumber', 'Pepper', 'Cabbage',
      'food_waste' // Include food waste class
    ];
    
    final random = Random();
    final selectedClass = mockClasses[random.nextInt(mockClasses.length)];
    final confidence = 0.7 + random.nextDouble() * 0.3; // 70-100% confidence
    
    return ClassificationResult(
      topPrediction: Prediction(
        label: selectedClass,
        confidence: confidence,
      ),
      allPredictions: [
        Prediction(label: selectedClass, confidence: confidence),
        Prediction(label: mockClasses[(random.nextInt(mockClasses.length))], confidence: confidence * 0.8),
        Prediction(label: mockClasses[(random.nextInt(mockClasses.length))], confidence: confidence * 0.6),
      ],
    );
  }
  
  /// Mock classify image from bytes
  Future<ClassificationResult> classifyBytes(List<int> imageBytes) async {
    if (!_isLoaded) {
      throw Exception('Classifier not initialized');
    }
    
    // Simulate processing delay
    await Future.delayed(const Duration(milliseconds: 500));
    
    // Mock classification
    final mockClasses = [
      'Apple', 'Banana', 'Carrot', 'Tomato', 'Lettuce',
      'Orange', 'Potato', 'Onion', 'Broccoli', 'Spinach',
      'Strawberry', 'Grape', 'Cucumber', 'Pepper', 'Cabbage',
      'food_waste' // Include food waste class
    ];
    
    final random = Random();
    final selectedClass = mockClasses[random.nextInt(mockClasses.length)];
    final confidence = 0.7 + random.nextDouble() * 0.3;
    
    return ClassificationResult(
      topPrediction: Prediction(
        label: selectedClass,
        confidence: confidence,
      ),
      allPredictions: [
        Prediction(label: selectedClass, confidence: confidence),
        Prediction(label: mockClasses[(random.nextInt(mockClasses.length))], confidence: confidence * 0.8),
        Prediction(label: mockClasses[(random.nextInt(mockClasses.length))], confidence: confidence * 0.6),
      ],
    );
  }
  
  /// Release resources
  void dispose() {
    _isLoaded = false;
  }
}

/// Result of image classification
class ClassificationResult {
  final Prediction topPrediction;
  final List<Prediction> allPredictions;
  
  ClassificationResult({
    required this.topPrediction,
    required this.allPredictions,
  });
  
  bool get isConfident => topPrediction.confidence > 0.7;
  
  @override
  String toString() {
    return 'ClassificationResult(top: ${topPrediction.label} @ ${(topPrediction.confidence * 100).toStringAsFixed(1)}%)';
  }
}

/// Single prediction with label and confidence
class Prediction {
  final String label;
  final double confidence;
  
  Prediction({required this.label, required this.confidence});
  
  String get displayConfidence => '${(confidence * 100).toStringAsFixed(1)}%';
}
