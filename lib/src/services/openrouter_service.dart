import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'sbert_inference.dart';
import 'package:logging/logging.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class OpenRouterService {
  final Logger _logger = Logger('OpenRouterService');
  final String _apiKey = dotenv.env['OPENROUTER_API_KEY'] ?? '';
  final String _model = 'openai/gpt-4o-mini'; // Free model that supports vision

  OpenRouterService() {
    if (_apiKey.isEmpty) {
      throw Exception('OPENROUTER_API_KEY not found in .env');
    }
  }

  Future<String> analyzeFoodScraps(String imagePath) async {
    try {
      final imageFile = File(imagePath);
      if (!await imageFile.exists()) {
        throw Exception('Image not found: $imagePath');
      }

      final imageBytes = await imageFile.readAsBytes();
      final base64Image = base64Encode(imageBytes);

      final uri = Uri.parse('https://openrouter.ai/api/v1/chat/completions');
      final headers = {
        'Authorization': 'Bearer $_apiKey',
        'Content-Type': 'application/json',
        'HTTP-Referer': 'https://scrapchef.app',
        'X-Title': 'ScrapChef',
      };

      final prompt = '''
Classify the food scrap in the image.
Return ONLY a JSON object with keys: label, confidence.
Use a short scrap-specific noun phrase (examples: "banana peel", "onion skin", "apple core", "carrot tops").
Confidence must be a number between 0 and 1.
If unsure, return label "unknown scrap" with low confidence.
''';

      final payload = {
        'model': _model,
        'messages': [
          {
            'role': 'user',
            'content': [
              {
                'type': 'text',
                'text': prompt,
              },
              {
                'type': 'image_url',
                'image_url': {
                  'url': 'data:image/jpeg;base64,$base64Image',
                },
              },
            ],
          },
        ],
        'max_tokens': 100,
        'temperature': 0.0,
      };

      final response = await http.post(
        uri,
        headers: headers,
        body: jsonEncode(payload),
      );

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        final message = decoded['choices'][0]['message']['content'];
        final cleaned = message.trim().replaceAll(RegExp(r'```json|```'), '');
        final result = jsonDecode(cleaned);
        
        return jsonEncode({
          'label': result['label'] ?? 'unknown scrap',
          'confidence': (result['confidence'] ?? 0.1).toDouble(),
        });
      } else {
        _logger.warning('OpenRouter API error: ${response.statusCode} - ${response.body}');
        return 'Error: ${_extractError(response.body) ?? response.reasonPhrase}';
      }
    } catch (e) {
      _logger.severe('OpenRouter classification error: $e');
      return 'Error: $e';
    }
  }

  Future<String> getRecipeRecommendation(String query) async {
    try {
      // Retrieve relevant recipes using SBERT
      final recipes = await SBertInference.retrieveRelevantRecipes(query);
      if (recipes.isEmpty) {
        return 'No similar recipes found.';
      }

      // Build a concise context string
      final context = recipes.map((r) {
        final meta = r['metadata'] as Map<String, dynamic>;
        final title = meta['title'] ?? '';
        final summary = meta['summary'] ?? '';
        return '- $title: $summary';
      }).join('\n');

      final prompt = '''
You are a helpful cooking assistant. Based on the following similar recipes, answer the user’s request.

Recipes:
$context

User query: $query

Provide a concise recipe suggestion or answer.
''';

      final uri = Uri.parse('https://openrouter.ai/api/v1/chat/completions');
      final headers = {
        'Authorization': 'Bearer $_apiKey',
        'Content-Type': 'application/json',
        'HTTP-Referer': 'https://scrapchef.app',
        'X-Title': 'ScrapChef',
      };
      final payload = {
        'model': _model,
        'messages': [
          {
            'role': 'user',
            'content': prompt,
          },
        ],
        'max_tokens': 300,
        'temperature': 0.7,
      };

      final response = await http.post(uri, headers: headers, body: jsonEncode(payload));
      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        final message = decoded['choices'][0]['message']['content'];
        return message.trim();
      } else {
        _logger.warning('OpenRouter API error: \${response.statusCode} - \${response.body}');
        return 'Error: \${_extractError(response.body) ?? response.reasonPhrase}';
      }
    } catch (e) {
      _logger.severe('OpenRouter recommendation error: \$e');
      return 'Error: \$e';
    }
  }

  String? _extractError(String responseBody) {
    try {
      final decoded = jsonDecode(responseBody);
      if (decoded is Map<String, dynamic> && decoded['error'] != null) {
        return decoded['error']['message']?.toString() ?? decoded['error'].toString();
      }
    } catch (_) {}
    return null;
  }
}