import 'dart:io';

import '../models.dart';
import 'mock_classifier_service.dart';

class ImageClassifierService {
  ImageClassifierService(this._mockClassifier);

  final MockClassifierService _mockClassifier;

  /// Classify an image file. For MVP, this asks user to identify the scrap visually.
  /// A real model would process the image bytes here.
  Future<ScanOutcome> classifyImage(File imageFile) async {
    // In a real MVP with a trained model, you'd:
    // 1. Convert imageFile to bytes or tensor
    // 2. Run inference on the model
    // 3. Return the top prediction with confidence
    
    // For now, return a placeholder outcome that shows the flow works
    // and asks user to verify what's in the photo
    return ScanOutcome(
      predictedLabel: 'Unknown scrap (awaiting model)',
      confidence: 0.0,
      recommendedAction: 'Photo captured. Please select the correct scrap type below.',
      requiresReview: true,
      note: 'Live model integration coming next. For now, select from the list.',
    );
  }

  /// Get suggestions based on what the user visually identified
  ScanOutcome getSuggestionsForLabel(String label) {
    return _mockClassifier.classifySample(label);
  }
}
