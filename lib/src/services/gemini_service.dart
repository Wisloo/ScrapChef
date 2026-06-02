import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:logging/logging.dart';

class QwenService {
  final String backendUrl;
  final Logger _logger = Logger('QwenService');

  QwenService(this.backendUrl);

  Future<String> analyzeFoodScraps(String imagePath) async {
    try {
      final uri = Uri.parse('$backendUrl/classify-food-scrap');
      final imageFile = File(imagePath);
      
      final request = http.MultipartRequest('POST', uri);
      request.files.add(await http.MultipartFile.fromPath('image', imagePath));
      
      final response = await request.send();
      final responseBody = await response.stream.bytesToString();

      if (response.statusCode == 200) {
        final decoded = jsonDecode(responseBody);
        if (decoded['classification'] != null) {
          final classification = decoded['classification'];
          return jsonEncode({
            'label': classification['label'],
            'confidence': classification['confidence']
          });
        }
      }

      _logger.warning('Backend classification failed: ${response.statusCode} - $responseBody');
      return 'Error: ${_extractError(responseBody) ?? response.reasonPhrase}';
    } catch (e) {
      _logger.severe('Backend classification error: $e');
      return 'Error: $e';
    }
  }

  String _buildPrompt() {
    return (
        'Classify the food scrap in the image. '
        'Return ONLY a JSON object with keys: label, confidence. '
        'Use a short scrap-specific noun phrase (examples: "banana peel", "onion skin", "apple core", "carrot tops"). '
        'Confidence must be a number between 0 and 1. '
        'If unsure, return label "unknown scrap" with low confidence.'
    );
  }

  String? _extractError(String responseBody) {
    try {
      final decoded = jsonDecode(responseBody);
      if (decoded is Map<String, dynamic> && decoded['error'] != null) {
        return decoded['error'].toString();
      }
    } catch (_) {}
    return null;
  }
}
