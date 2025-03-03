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

  Future<Either<Failure, List<Ingredient>>> getCombinedIngredients({
    required List<Ingredient> newIngredients,
    required List<Ingredient> existingInventory,
  }) async {
    // Format the ingredients list for the prompt
    final newIngredientsString = newIngredients
        .map((ingredient) => ingredient.toJson().toString())
        .join("\n");
    final existingInventoryString = existingInventory
        .map((ingredient) => ingredient.toJson().toString())
        .join("\n");

    print("newIngredientsString: $newIngredientsString");
    print("existingInventoryString: $existingInventoryString");

    final prompt = '''
You are an AI assistant that helps process food ingredients for a cooking app.

EXISTING INVENTORY:
$existingInventoryString

NEW INGREDIENT:
$newIngredientsString

Please analyze the new ingredient and:
1. Normalize the name (proper capitalization, remove unnecessary words)
2. Assign the most appropriate category
3. Suggest the best unit for this ingredient if the current one is inappropriate
4. Check if this ingredient might be a duplicate of something in the inventory
5. Return the processed ingredient as a JSON object with the same structure

Your response should be ONLY a valid JSON object with the following fields:
{
  "id": "same as input",
  "name": "normalized name",
  "category": "appropriate category",
  "quantity": number,
  "unit": "appropriate unit",
}
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
          temperature: 0.7,
          maxTokens: 1000,
        ),
      );

      // Extract the content from the response
      final content = response.choices.first.message.content;
      if (content == null) {
        return Left(OpenAIEmptyResponseFailure());
      }

      final cleanedContent = cleanJsonContent(content);

      try {
        // Parse the JSON content
        final jsonData = jsonDecode(cleanedContent);

        // Check if the response is a single object or an array
        if (jsonData is Map<String, dynamic>) {
          // Single ingredient response
          final ingredient = Ingredient.fromJson(jsonData);
          return Right([ingredient]);
        } else if (jsonData is List) {
          // List of ingredients response
          final ingredients =
              jsonData
                  .map(
                    (item) => Ingredient.fromJson(item as Map<String, dynamic>),
                  )
                  .toList();
          return Right(ingredients);
        } else {
          return Left(OpenAIConnectionFailure());
        }
      } catch (e) {
        print("JSON parsing error: $e");
        return Left(OpenAIConnectionFailure());
      }
    } catch (e) {
      print("error: $e");
      return Left(OpenAIRequestFailure());
    }
  }
}
