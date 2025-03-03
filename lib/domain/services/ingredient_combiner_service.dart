import 'dart:convert';

import 'package:dartz/dartz.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:openai_dart/openai_dart.dart';
import '../../core/error/failures/failure.dart';
import '../models/ingredient.dart';
import 'shared/clean_json.dart';

class IngredientCombinerService {
  late final OpenAIClient _client;

  IngredientCombinerService() {
    final apiKey = dotenv.env['OPENAI_API_KEY'];
    if (apiKey == null) {
      throw Exception('OpenAI API key not found in .env file');
    }
    _client = OpenAIClient(apiKey: apiKey);
  }

  Future<Either<Failure, List<Ingredient>>> combineIngredients(
    List<Ingredient> existingInventory,
  ) async {
    print("BREAK");
    print("existingInventory length: ${existingInventory.length}");
    print("BREAK");

    final existingInventoryString = existingInventory
        .map((ingredient) => ingredient.toJson().toString())
        .join("\n");

    final prompt = '''
You are an AI assistant that helps process food ingredients for a cooking app.

$existingInventoryString

Combine the ingredients which have a similar name and add their quantities. Use fuzzy matching to determine if the names match and choose the most descriptive name for the ingredient. Make sure to be smart about adding the quantities because the units can be different (e.g. kg and pieces) choose the most appropriate metric.

IMPORTANT: Your response must be ONLY a valid JSON array of objects, even if there's just one ingredient.

''';

    try {
      // Make the API request
      final response = await _client.createChatCompletion(
        request: CreateChatCompletionRequest(
          model: ChatCompletionModel.modelId('gpt-4o-mini'),
          messages: [
            ChatCompletionMessage.user(
              content: ChatCompletionUserMessageContent.string(prompt),
            ),
          ],
        ),
      );

      // Extract the content from the response
      final content = response.choices.first.message.content;
      if (content == null) {
        return Left(OpenAIEmptyResponseFailure());
      }

      final cleanedContent = cleanJsonContent(content);
      return _parseResponse(cleanedContent);
    } catch (e) {
      return Left(OpenAIRequestFailure());
    }
  }

  Either<Failure, List<Ingredient>> _parseResponse(String content) {
    try {
      print("content: $content");
      final jsonData = jsonDecode(content) as List;
      print("jsonData length: ${jsonData.length}");

      final ingredients =
          jsonData
              .map((item) => Ingredient.fromJson(item as Map<String, dynamic>))
              .toList();

      return Right(ingredients);
    } catch (e) {
      print("Error parsing JSON: $e");
      return Left(ParsingFailure());
    }
  }
}
