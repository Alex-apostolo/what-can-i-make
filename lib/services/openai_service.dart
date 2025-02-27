import 'dart:convert';
import 'dart:io';
import 'package:openai_dart/openai_dart.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../models/kitchen_item.dart';
import 'package:uuid/uuid.dart';

/// Service to handle OpenAI API interactions for kitchen inventory analysis
class OpenAIService {
  late final OpenAIClient _client;
  final _uuid = Uuid();

  static const _analyzePrompt =
      '''Analyze this image of a kitchen space and identify:
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
}''';

  OpenAIService() {
    final apiKey = dotenv.env['OPENAI_API_KEY'];
    if (apiKey == null) {
      throw Exception('OpenAI API key not found in .env file');
    }
    _client = OpenAIClient(apiKey: apiKey);
  }

  /// Analyzes an image of kitchen inventory and returns a list of identified items
  ///
  /// [imagePath] is the path to the image file to analyze
  /// Returns a list of [KitchenItem] objects, or empty list if analysis fails
  Future<List<KitchenItem>> analyzeKitchenInventory(String imagePath) async {
    try {
      final bytes = await File(imagePath).readAsBytes();
      final base64Image = base64Encode(bytes);
      final base64Uri = 'data:image/jpeg;base64,$base64Image';

      final response = await _client.createChatCompletion(
        request: CreateChatCompletionRequest(
          model: ChatCompletionModel.modelId('gpt-4o'),
          messages: [
            ChatCompletionMessage.user(
              content: ChatCompletionUserMessageContent.parts([
                ChatCompletionMessageContentPart.text(text: _analyzePrompt),
                ChatCompletionMessageContentPart.image(
                  imageUrl: ChatCompletionMessageImageUrl(url: base64Uri),
                ),
              ]),
            ),
          ],
        ),
      );

      final content = response.choices.first.message.content;
      if (content == null) return [];

      return _parseResponse(content);
    } catch (e) {
      print('Error analyzing kitchen inventory: $e');
      return [];
    }
  }

  /// Parses the OpenAI response and converts it to a list of KitchenItems
  List<KitchenItem> _parseResponse(String content) {
    try {
      final jsonStartIndex = content.indexOf('{');
      final jsonEndIndex = content.lastIndexOf('}') + 1;

      if (jsonStartIndex == -1 || jsonEndIndex == -1) {
        print('Error: No valid JSON found in response');
        return [];
      }

      final jsonStr = content.substring(jsonStartIndex, jsonEndIndex);
      final Map<String, dynamic> jsonResponse = json.decode(jsonStr);

      if (!jsonResponse.containsKey('items')) {
        print('Error: Invalid response format - missing items array');
        return [];
      }

      final items = jsonResponse['items'];
      if (items is! List) {
        print('Error: Invalid response format - items is not an array');
        return [];
      }

      return items
          .map((item) => KitchenItem.fromMap({...item, 'id': _uuid.v4()}))
          .toList();
    } catch (e) {
      print('Error parsing OpenAI response: $e');
      return [];
    }
  }

  /// Closes the OpenAI client session
  void dispose() {
    _client.endSession();
  }
}
