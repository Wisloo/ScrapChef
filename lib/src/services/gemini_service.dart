
import 'dart:io';
import 'package:flutter/services.dart';
import 'package:google_generative_ai/google_generative_ai.dart';

class GeminiService {
  late final GenerativeModel _model;
  static const String _defaultApiKey = 'AIzaSyBrwRO0hYMStVhsfKFLYaSmpVRGpfFgGvw';

  GeminiService({String? apiKey}) {
    final key = apiKey ?? _defaultApiKey;
    _model = GenerativeModel(
      model: 'gemini-1.5-pro', // Use pro model for better availability
      apiKey: key,
    );
  }

  Future<String> analyzeFoodScraps(String imagePath) async {
    final imageFile = File(imagePath);
    if (!imageFile.existsSync()) {
      return 'Error: Image file not found at $imagePath';
    }

    final imageBytes = await imageFile.readAsBytes();
    final content = [
      Content.multi([
        TextPart(
            "Analyze this image for food scraps. Identify each type of food scrap present, estimate their quantities, and suggest potential uses or composting methods. Provide the data in a clear, structured format, such as a list or JSON. Here are some examples of what I am looking for:\n\nIf the image contains banana peels and apple cores, output: \n```json\n{\n  \"food_scraps\": [\n    {\n      \"item\": \"banana peels\",\n      \"quantity\": \"2 peels\",\n      \"disposal_method\": \"compost\",\n      \"potential_uses\": \"fertilizer\"\n    },\n    {\n      \"item\": \"apple cores\",\n      \"quantity\": \"3 cores\",\n      \"disposal_method\": \"compost\",\n      \"potential_uses\": \"compost tea\"\n    }\n  ]\n}```\n\nIf the image contains coffee grounds and eggshells, output: \n```json\n{\n  \"food_scraps\": [\n    {\n      \"item\": \"coffee grounds\",\n      \"quantity\": \"1 cup\",\n      \"disposal_method\": \"compost\",\n      \"potential_uses\": \"garden fertilizer, odor neutralizer\"\n    },\n    {\n      \"item\": \"eggshells\",\n      \"quantity\": \"5 shells\",\n      \"disposal_method\": \"compost\",\n      \"potential_uses\": \"calcium supplement for plants\"\n    }\n  ]\n}```\n\nNow, analyze the following image:"
        ),
        DataPart('image/jpeg', imageBytes),
      ]),
    ];

    // Retry logic with exponential backoff
    int maxRetries = 3;
    Duration delay = const Duration(seconds: 1);

    for (int attempt = 0; attempt < maxRetries; attempt++) {
      try {
        final response = await _model.generateContent(content);
        final text = response.text ?? 'No analysis found.';
        
        // Extract JSON from markdown code blocks if present
        final jsonPattern = RegExp(r'```json\s*([\s\S]*?)\s*```');
        final match = jsonPattern.firstMatch(text);
        
        if (match != null) {
          return match.group(1) ?? text;
        }
        
        return text;
      } catch (e) {
        if (attempt == maxRetries - 1) {
          // Final attempt failed
          if (e.toString().contains('resource_exhausted') || 
              e.toString().contains('model provider')) {
            return 'Error: Gemini API is currently overloaded. Please try again in a few moments.';
          }
          if (e.toString().contains('API key')) {
            return 'Error: Invalid API key. Please check your Gemini API key configuration.';
          }
          return 'Error during API call: $e';
        }
        
        // Wait before retrying with exponential backoff
        await Future.delayed(delay);
        delay *= 2;
      }
    }

    return 'Error: Failed after $maxRetries attempts';
  }
}
