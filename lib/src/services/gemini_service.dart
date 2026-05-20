import 'dart:io';
import 'dart:typed_data';
import 'dart:developer';

import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:image/image.dart' as img;

class GeminiService {
  late final GenerativeModel _model;

   static const String _prompt =
       'Identify food scraps in this image. Reply with ONLY valid JSON, no markdown: '
       '{"food_scraps":[{"item":"<scrap name>"}]}. '
       'Use short common names (e.g. orange peels, banana peels, coffee grounds). '
       'If none, use {"food_scraps":[]}.';

   GeminiService({String? apiKey}) {
     final key = apiKey ?? 'AIzaSyDagI2DoJllJumvfV2pZWYuJNwoFrw381A';
     print('Gemini API key configured: ${key.isNotEmpty ? key.substring(0, key.length > 10 ? 10 : key.length) : 'empty'}...');
     _model = GenerativeModel(
       model: 'gemini-2.5-flash',
       apiKey: key,
     );
   }

   Future<Uint8List> _prepareImageBytes(String imagePath) async {
     final rawBytes = await File(imagePath).readAsBytes();
     final decoded = img.decodeImage(rawBytes);
     if (decoded == null) {
       return rawBytes;
     }

     const maxEdge = 1024;
     final resized = decoded.width > maxEdge || decoded.height > maxEdge
         ? img.copyResize(
             decoded,
             width: decoded.width >= decoded.height ? maxEdge : null,
             height: decoded.height > decoded.width ? maxEdge : null,
           )
         : decoded;

     return Uint8List.fromList(img.encodeJpg(resized, quality: 80));
   }

   bool _isNonRetryableError(Object e) {
     final message = e.toString().toLowerCase();
     return message.contains('api key') ||
         message.contains('api_key') ||
         message.contains('permission') ||
         message.contains('invalid') ||
         message.contains('quota');
   }

   Future<String> analyzeFoodScraps(String imagePath) async {
     final imageFile = File(imagePath);
     if (!imageFile.existsSync()) {
       return 'Error: Image file not found at $imagePath';
     }

     late final Uint8List imageBytes;
     try {
       imageBytes = await _prepareImageBytes(imagePath);
     } catch (e) {
       return 'Error: Could not process image: $e';
     }

     final content = [
       Content.multi([
         TextPart(_prompt),
         DataPart('image/jpeg', imageBytes),
       ]),
     ];

     const maxAttempts = 2;
     var delay = const Duration(milliseconds: 500);

     for (var attempt = 0; attempt < maxAttempts; attempt++) {
       try {
         final response = await _model.generateContent(content);
         final text = response.text ?? 'No analysis found.';

         final jsonPattern = RegExp(r'```json\s*([\s\S]*?)\s*```');
         final match = jsonPattern.firstMatch(text);

         if (match != null) {
           return match.group(1) ?? text;
         }

         return text;
       } catch (e) {
         if (_isNonRetryableError(e) || attempt == maxAttempts - 1) {
           if (e.toString().contains('resource_exhausted') ||
               e.toString().contains('model provider')) {
             return 'Error: Gemini API is currently overloaded. Please try again in a few moments.';
           }
           if (e.toString().contains('API key')) {
             return 'Error: Invalid API key. Please check your Gemini API key configuration.';
           }
           return 'Error during API call: $e';
         }

         await Future.delayed(delay);
         delay *= 2;
       }
     }

     return 'Error: Failed after $maxAttempts attempts';
   }
}
