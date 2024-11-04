import 'dart:io';
import 'package:google_generative_ai/google_generative_ai.dart';

class GeminiService {
  final String apiKey = 'AIzaSyAVc67WKSONvgO91BiaXB2KustvMzY6mfM';
  late GenerativeModel model;

  GeminiService() {
    model = GenerativeModel(model: 'gemini-1.5-flash-latest', apiKey: apiKey);
  }

  Future<String> identifyPokemon(String imagePath) async {
    try {
      final imageBytes = await File(imagePath).readAsBytes();
      final content = [
        Content.multi([
          TextPart('Identify this Pokémon'),
          DataPart('image/png', imageBytes),
        ])
      ];
      final response = await model.generateContent(content);
      if (response.text != null && response.text!.isNotEmpty) {
        return _extractPokemonName(response.text!);
      } else {
        return 'No identification result found';
      }
    } catch (e) {
      return 'Error identifying Pokémon: $e';
    }
  }

  String _extractPokemonName(String responseText) {
    // List of possible patterns
    final patterns = [
      RegExp(r'\b(?:This is|That pokemon is|It is|The Pokémon is)\s+(\w+)\b', caseSensitive: false),
      RegExp(r'\b(?:This looks like|It looks like|Appears to be|Looks like)\s+(\w+)\b', caseSensitive: false),
      RegExp(r'\b(?:Identified as|Recognized as)\s+(\w+)\b', caseSensitive: false)
    ];

    for (var pattern in patterns) {
      final match = pattern.firstMatch(responseText);
      if (match != null) {
        return match.group(1)!.replaceAll('.', '');
      }
    }

    // If no pattern matches, return the response text without periods
    return responseText.replaceAll('.', '');
  }
}
