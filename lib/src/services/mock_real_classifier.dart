import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:image/image.dart' as img;

/// Gemini-backed scrap classifier.
/// The model is used online to identify the most likely scrap type in the photo.
class MockRealClassifier {
  static const String _defaultModel = 'gemini-1.5-flash';
  static const String _apiKeyEnvironment = 'GEMINI_API_KEY';

  static const List<String> _supportedLabels = [
    'banana_peel',
    'citrus_peel',
    'apple_core_peel',
    'broccoli_stem',
    'cabbage_core',
    'carrot_peel',
    'cucumber_peel',
    'onion_skin',
    'potato_peel',
    'tomato_trimmings',
    'leafy_trimmings',
    'bean_pod',
    'corn_husk',
    'fruit_scraps',
    'vegetable_scraps',
    'not_food_waste',
  ];

  final HttpClient _httpClient = HttpClient();

  String? _apiKey;
  String _modelName = _defaultModel;
  bool _isLoaded = false;

  bool get isLoaded => _isLoaded;
  List<String> get labels => List.unmodifiable(_supportedLabels);

  /// Initialize the classifier by loading the Gemini API key.
  Future<void> initialize() async {
    try {
      _apiKey = const String.fromEnvironment(_apiKeyEnvironment);
      final overrideModel = const String.fromEnvironment('GEMINI_MODEL');
      if (overrideModel.isNotEmpty) {
        _modelName = overrideModel;
      }

      if (_apiKey == null || _apiKey!.isEmpty) {
        _isLoaded = false;
        print('Gemini API key missing. Set --dart-define=$_apiKeyEnvironment=YOUR_KEY');
        return;
      }

      _isLoaded = true;
      print('GeminiScrapClassifier initialized successfully');
    } catch (e) {
      throw Exception('Failed to initialize classifier: $e');
    }
  }

  Future<ClassificationResult> classifyImage(File imageFile) async {
    if (!_isLoaded || _apiKey == null || _apiKey!.isEmpty) {
      throw Exception('Gemini API key missing. Run with --dart-define=$_apiKeyEnvironment=YOUR_KEY');
    }

    final bytes = await imageFile.readAsBytes();
    return classifyBytes(bytes);
  }

  Future<ClassificationResult> classifyBytes(List<int> imageBytes) async {
    if (!_isLoaded || _apiKey == null || _apiKey!.isEmpty) {
      throw Exception('Gemini API key missing. Run with --dart-define=$_apiKeyEnvironment=YOUR_KEY');
    }

    final decoded = img.decodeImage(Uint8List.fromList(imageBytes));
    if (decoded == null) {
      throw Exception('Unable to decode image');
    }

    final resized = img.copyResize(
      decoded,
      width: decoded.width >= decoded.height ? 1024 : (decoded.width * 1024 / decoded.height).round(),
      height: decoded.height > decoded.width ? 1024 : (decoded.height * 1024 / decoded.width).round(),
      interpolation: img.Interpolation.average,
    );
    final jpegBytes = img.encodeJpg(resized, quality: 85);
    final prompt = _buildPrompt();
    final payload = jsonEncode({
      'contents': [
        {
          'role': 'user',
          'parts': [
            {'text': prompt},
            {
              'inlineData': {
                'mimeType': 'image/jpeg',
                'data': base64Encode(jpegBytes),
              }
            },
          ],
        },
      ],
      'generationConfig': {
        'temperature': 0.2,
        'topK': 32,
        'topP': 0.95,
        'maxOutputTokens': 256,
      },
    });

    final request = await _httpClient.postUrl(
      Uri.parse('https://generativelanguage.googleapis.com/v1beta/models/$_modelName:generateContent?key=$_apiKey'),
    );
    request.headers.contentType = ContentType.json;
    request.add(utf8.encode(payload));

    final response = await request.close().timeout(const Duration(seconds: 25));
    final responseText = await response.transform(utf8.decoder).join();
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception(_extractApiError(responseText, response.statusCode));
    }

    final decodedResponse = jsonDecode(responseText) as Map<String, dynamic>;
    final text = _extractCandidateText(decodedResponse);
    if (text == null || text.trim().isEmpty) {
      throw Exception('Gemini returned no classification text.');
    }

    final classification = _parseClassification(text);
    final label = _normalizeLabel(classification['label']?.toString() ?? 'unknown');
    final confidence = _clampConfidence(classification['confidence']);
    final note = classification['note']?.toString().trim();

    final predictionLabel = _supportedLabels.contains(label) ? label : 'fruit_scraps';
    final isNotFoodWaste = predictionLabel == 'not_food_waste';
    final topPrediction = Prediction(
      label: predictionLabel,
      confidence: confidence,
    );

    return ClassificationResult(
      topPrediction: topPrediction,
      allPredictions: [
        topPrediction,
        if (!isNotFoodWaste)
          Prediction(
            label: 'not_food_waste',
            confidence: (1.0 - confidence).clamp(0.0, 1.0),
          ),
      ],
      note: note?.isNotEmpty == true
          ? note
          : (isNotFoodWaste
              ? 'Gemini did not detect a food scrap.'
              : 'Gemini classified the scrap as $predictionLabel.'),
    );
  }

  /// Release resources.
  void dispose() {
    _httpClient.close(force: true);
    _apiKey = null;
    _isLoaded = false;
  }

  String _buildPrompt() {
    return '''
You are classifying food scraps from a photo for a waste-sorting app.
Choose exactly one label from this list:
banana_peel, citrus_peel, apple_core_peel, broccoli_stem, cabbage_core, carrot_peel, cucumber_peel, onion_skin, potato_peel, tomato_trimmings, leafy_trimmings, bean_pod, corn_husk, fruit_scraps, vegetable_scraps, not_food_waste.

Rules:
- Return strict JSON only.
- Use the closest label even if the photo is partially occluded.
- If the image is not a food scrap, use not_food_waste.
- Confidence must be a number from 0 to 1.

JSON shape:
{"label":"banana_peel","confidence":0.92,"note":"Short reason here"}
''';
  }

  String? _extractCandidateText(Map<String, dynamic> response) {
    final candidates = response['candidates'];
    if (candidates is! List || candidates.isEmpty) {
      return null;
    }

    final firstCandidate = candidates.first;
    if (firstCandidate is! Map<String, dynamic>) {
      return null;
    }

    final content = firstCandidate['content'];
    if (content is! Map<String, dynamic>) {
      return null;
    }

    final parts = content['parts'];
    if (parts is! List) {
      return null;
    }

    for (final part in parts) {
      if (part is Map<String, dynamic> && part['text'] is String) {
        return part['text'] as String;
      }
    }
    return null;
  }

  Map<String, dynamic> _parseClassification(String rawText) {
    final trimmed = rawText.trim();
    final jsonMatch = RegExp(r'\{[\s\S]*\}').firstMatch(trimmed);
    final jsonText = jsonMatch?.group(0) ?? trimmed;
    final parsed = jsonDecode(jsonText);
    if (parsed is Map<String, dynamic>) {
      return parsed;
    }
    throw Exception('Gemini returned an unexpected response format.');
  }

  String _extractApiError(String responseText, int statusCode) {
    try {
      final decoded = jsonDecode(responseText);
      if (decoded is Map<String, dynamic>) {
        final error = decoded['error'];
        if (error is Map<String, dynamic> && error['message'] is String) {
          return 'Gemini API error $statusCode: ${error['message']}';
        }
      }
    } catch (_) {
      // Fall through to the raw response.
    }
    return 'Gemini API error $statusCode: $responseText';
  }

  String _normalizeLabel(String value) {
    return value.toLowerCase().trim().replaceAll(RegExp(r'\s+'), '_');
  }

  double _clampConfidence(dynamic value) {
    final parsed = value is num ? value.toDouble() : double.tryParse('$value') ?? 0.0;
    return parsed.clamp(0.0, 1.0);
  }
}

/// Result of image classification
class ClassificationResult {
  final Prediction topPrediction;
  final List<Prediction> allPredictions;
  final String? note;
  
  ClassificationResult({
    required this.topPrediction,
    required this.allPredictions,
    this.note,
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
  final String? sourceLabel;
  
  Prediction({required this.label, required this.confidence, this.sourceLabel});
  
  String get displayConfidence => '${(confidence * 100).toStringAsFixed(1)}%';
}

class _LabelScore {
  const _LabelScore({required this.label, required this.score});

  final String label;
  final double score;
}
