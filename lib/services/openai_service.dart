import 'dart:convert';
import 'dart:io';
import 'package:openai_dart/openai_dart.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../models/kitchen_item.dart';
import 'package:uuid/uuid.dart';

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

      final uuid = Uuid();
      return (jsonResponse['items'] as List).map((item) {
        // Add an ID to each item before creating KitchenItem
        item['id'] = uuid.v4();
        return KitchenItem.fromMap(item);
      }).toList();
    } catch (e) {
      print('Error parsing OpenAI response: $e');
      return [];
    }
  }

  void dispose() {
    _client.endSession();
  }
}
