import 'dart:io';
import 'package:http/http.dart' as http;
import 'dart:convert';

class VisionApiService {
  final String apiKey;

  VisionApiService(this.apiKey);

  Future<String> identifyPokemon(File imageFile) async {
    final imageBytes = await imageFile.readAsBytes();
    final base64Image = base64Encode(imageBytes);

    final response = await http.post(
      Uri.parse('https://api.openai.com/v1/chat/completions'),
      headers: {
        'Authorization': 'Bearer $apiKey',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'model': 'gpt-3.5-turbo',
        'messages': [
          {
            'role': 'system',
            'content': 'You are a helpful assistant that can analyze images.'
          },
          {
            'role': 'user',
            'content': 'Identify this Pokémon.',
            'attachments': [
              {
                'type': 'image',
                'data': base64Image
              }
            ]
          }
        ]
      }),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data['choices'][0]['message']['content'];
    } else if (response.statusCode == 402) {
      throw Exception('Insufficient quota. Please check your plan and billing details.');
    } else {
      print('Failed to identify Pokémon with status code: ${response.statusCode}');
      print('Response body: ${response.body}');
      throw Exception('Failed to identify Pokémon');
    }
  }
}
