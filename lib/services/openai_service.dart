import 'dart:convert';
import 'dart:io';
import 'package:openai_dart/openai_dart.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:uuid/uuid.dart';
import '../models/kitchen_item.dart';
import 'package:dartz/dartz.dart';
import '../core/failures/failure.dart';

/// Service to handle OpenAI API interactions for kitchen inventory analysis
class OpenAIService {
  late final OpenAIClient _client;
  final _uuid = Uuid().v4;

  static const _analyzePrompt =
      '''Analyze this image of a kitchen space and identify:
1. Ingredients (foods, spices, etc.)
2. Utensils (pots, pans, cutlery, etc.)
3. Equipment (appliances, tools, etc.)

Return a list of items with their name, category, and quantity.
The quantity should be a number, not a string.

The response must be in this exact JSON format:
{
  "items": [
    {
      "name": "item name",
      "category": "ingredient/utensil/equipment",
      "quantity": 1
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
  /// Returns Either a Failure or a list of [KitchenItem] objects
  Future<Either<Failure, List<KitchenItem>>> analyzeKitchenInventory(
    String imagePath,
  ) async {
    try {
      final bytes = await File(imagePath).readAsBytes();
      final base64Image = base64Encode(bytes);
      final base64Uri = 'data:image/jpeg;base64,$base64Image';

      final response = await _client.createChatCompletion(
        request: CreateChatCompletionRequest(
          model: ChatCompletionModel.modelId('gpt-4-turbo'),
          messages: [
            ChatCompletionMessage.system(
              content:
                  'You are a helpful assistant that analyzes kitchen images and returns data in strict JSON format. Always include an "items" array in your response, even if empty.',
            ),
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
      if (content == null) {
        return Left(OpenAIEmptyResponseFailure());
      }

      return _parseResponse(content);
    } on SocketException {
      return Left(OpenAIConnectionFailure());
    } on HttpException catch (e) {
      return Left(OpenAIRequestFailure('HTTP error: ${e.message}'));
    } on FormatException catch (e) {
      return Left(OpenAIRequestFailure('Format error: ${e.message}'));
    } on OpenAIClientException catch (e) {
      return Left(OpenAIRequestFailure('OpenAI API error: ${e.message}'));
    } catch (e) {
      return Left(OpenAIRequestFailure(e.toString()));
    }
  }

  /// Parses the OpenAI response and converts it to a list of KitchenItems
  Either<Failure, List<KitchenItem>> _parseResponse(String content) {
    try {
      // Parse the JSON string into a Map
      final Map<String, dynamic> jsonData = jsonDecode(content);

      // Extract the "items" list from the JSON object
      final List<dynamic> items = jsonData['items'] ?? [];

      final kitchenItems =
          items
              .map<KitchenItem>(
                (item) => KitchenItem.fromMap({...item, 'id': _uuid()}),
              )
              .toList();

      return Right(kitchenItems);
    } on FormatException catch (e) {
      return Left(ParsingFailure('JSON format error: ${e.message}', content));
    } on TypeError catch (e) {
      return Left(ParsingFailure('Type error: ${e.toString()}', content));
    } catch (e) {
      return Left(
        ParsingFailure('Failed to parse response: ${e.toString()}', content),
      );
    }
  }

  /// Closes the OpenAI client session
  void dispose() {
    _client.endSession();
  }
}
