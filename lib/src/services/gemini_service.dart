
import 'dart:io';
import 'package:flutter/services.dart';
import 'package:google_generative_ai/google_generative_ai.dart';

class GeminiService {
  final GenerativeModel _model;

  GeminiService() : _model = GenerativeModel(
          model: 'gemini-2.5-flash', // Use gemini-2.5-flash for multimodal tasks
          apiKey: const String.fromEnvironment('GEMINI_API_KEY'), // Replace with your actual API key
        );

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

    try {
      final response = await _model.generateContent(content);
      return response.text ?? 'No analysis found.';
    } catch (e) {
      return 'Error during API call: $e';
    }
  }
}
