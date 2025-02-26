import 'dart:convert';
import 'dart:io';
import 'package:openai_dart/openai_dart.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class KitchenItem {
  final String name;
  final String category; // 'ingredient', 'utensil', or 'equipment'
  final String? quantity; // Optional quantity/amount
  final String? notes; // Additional observations

  KitchenItem({
    required this.name,
    required this.category,
    this.quantity,
    this.notes,
  });

  Map<String, dynamic> toJson() => {
    'name': name,
    'category': category,
    'quantity': quantity,
    'notes': notes,
  };

  factory KitchenItem.fromJson(Map<String, dynamic> json) {
    return KitchenItem(
      name: json['name'],
      category: json['category'],
      quantity: json['quantity'],
      notes: json['notes'],
    );
  }
}

class OpenAIService {
  late final OpenAIClient _client;

  OpenAIService() {
    final apiKey = dotenv.env['OPENAI_API_KEY'];
    if (apiKey == null) {
      throw Exception('OpenAI API key not found in .env file');
    }
    _client = OpenAIClient(apiKey: apiKey);
  }

  Future<List<KitchenItem>> analyzeKitchenInventory(String imagePath) async {
    final bytes = await File(imagePath).readAsBytes();
    final base64Image = base64Encode(bytes);
    final base64Uri = 'data:image/jpeg;base64,$base64Image';

    final response = await _client.createChatCompletion(
      request: CreateChatCompletionRequest(
        model: ChatCompletionModel.modelId('gpt-4o'),
        messages: [
          ChatCompletionMessage.user(
            content: ChatCompletionUserMessageContent.parts([
              ChatCompletionMessageContentPart.text(
                text: '''Analyze this image of a kitchen space and identify:
1. Ingredients (foods, spices, etc.)
2. Utensils (pots, pans, cutlery, etc.)
3. Equipment (appliances, tools, etc.)

Provide the response in the following JSON format:
{
  "items": [
    {
      "name": "item name",
      "category": "ingredient/utensil/equipment",
      "quantity": "estimated amount if visible",
      "notes": "any relevant observations"
    }
  ]
}''',
              ),
              ChatCompletionMessageContentPart.image(
                imageUrl: ChatCompletionMessageImageUrl(url: base64Uri),
              ),
            ]),
          ),
        ],
        maxTokens: 1000,
      ),
    );

    final content = response.choices.first.message.content;
    if (content == null) return [];

    try {
      // Extract the JSON part from the response
      final jsonStr = content.substring(
        content.indexOf('{'),
        content.lastIndexOf('}') + 1,
      );
      final Map<String, dynamic> jsonResponse = json.decode(jsonStr);

      return (jsonResponse['items'] as List)
          .map((item) => KitchenItem.fromJson(item))
          .toList();
    } catch (e) {
      print('Error parsing OpenAI response: $e');
      return [];
    }
  }

  void dispose() {
    _client.endSession();
  }
}
