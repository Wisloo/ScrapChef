import 'dart:math';

import '../models.dart';

class MockClassifierService {
  static const List<String> supportedLabels = <String>[
    'Broccoli',
    'Cabbage',
    'Carrot',
    'Cauliflower',
    'Capsicum',
    'Cucumber',
    'Potato',
    'Pumpkin',
    'Radish',
    'Tomato',
    'Brinjal',
    'Bottle Gourd',
    'Bitter Gourd',
    'Bean',
  ];

  final Random _random = Random();

  ScanOutcome classifySample(String sampleLabel) {
    final normalized = sampleLabel.toLowerCase().trim();
    final isKnown = supportedLabels.any((label) => label.toLowerCase() == normalized);
    final confidence = _confidenceForSample(isKnown);
    final predictedLabel = isKnown ? _titleCase(sampleLabel) : 'Unknown scrap';
    final action = isKnown
        ? 'Add to Scrap Bin and suggest recipes.'
        : 'Ask the user to verify the item before logging.';

    return ScanOutcome(
      predictedLabel: predictedLabel,
      confidence: confidence,
      recommendedAction: action,
      requiresReview: confidence < 0.70,
      note: isKnown
          ? 'This is a mock classifier for the MVP. Replace it with the on-device model later.'
          : 'No confident match found in the current label set.',
    );
  }

  double _confidenceForSample(bool isKnown) {
    if (!isKnown) {
      return 0.34 + _random.nextDouble() * 0.24;
    }

    return 0.62 + _random.nextDouble() * 0.33;
  }

  String _titleCase(String value) {
    return value
        .split(' ')
        .where((part) => part.isNotEmpty)
        .map((part) => part[0].toUpperCase() + part.substring(1).toLowerCase())
        .join(' ');
  }
}
