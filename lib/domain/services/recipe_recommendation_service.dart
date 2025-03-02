import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:openai_dart/openai_dart.dart';
import '../../core/error/failures/failure.dart';
import '../models/ingredient.dart';
import '../models/recipe.dart';
import 'package:dartz/dartz.dart';

class RecipeRecommendationService {
  late final OpenAIClient _client;

  RecipeRecommendationService() {
    final apiKey = dotenv.env['OPENAI_API_KEY'];
    if (apiKey == null) {
      throw Exception('OpenAI API key not found in .env file');
    }
    _client = OpenAIClient(apiKey: apiKey);
  }

  String _generateRecipesPrompt({
    required String availableIngredients,
    required bool strictMode,
  }) => '''
Generate 3 recipe recommendations using these ingredients: $availableIngredients.
${strictMode ? 'Only use the listed ingredients.' : 'You can suggest additional ingredients if needed.'}
Format the response as a JSON array with the following structure for each recipe:
[
  {
    "id": "unique_id",
    "name": "Recipe Name",
    "ingredients": ["ingredient1", "ingredient2", ...],
    "instructions": "Step-by-step cooking instructions",
    "prepTime": preparation_time_in_minutes,
  }
]
''';

  Future<Either<Failure, List<Recipe>>> getRecommendedRecipes({
    required List<Ingredient> availableIngredients,
    bool strictMode = false,
  }) async {
    // Format the ingredients list for the prompt
    final ingredientNames = availableIngredients.map((i) => i.name).join(', ');

    try {
      // Make the API request
      final response = await _client.createChatCompletion(
        request: CreateChatCompletionRequest(
          model: ChatCompletionModel.modelId('gpt-4o'),
          messages: [
            ChatCompletionMessage.system(
              content:
                  'You are a helpful cooking assistant that generates recipe recommendations based on available ingredients.',
            ),
            ChatCompletionMessage.user(
              content: ChatCompletionUserMessageContent.string(
                _generateRecipesPrompt(
                  availableIngredients: ingredientNames,
                  strictMode: strictMode,
                ),
              ),
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

      return _parseResponse(content);
    } on OpenAIClientException {
      return Left(OpenAIRequestFailure());
    }
  }

  Either<Failure, List<Recipe>> _parseResponse(String content) {
    try {
      final jsonMatch = RegExp(
        r'\[\s*\{.*\}\s*\]',
        dotAll: true,
      ).firstMatch(content);

      if (jsonMatch == null) {
        return Left(ParsingFailure());
      }

      final jsonStr = jsonMatch.group(0);
      final List<dynamic> recipesJson = jsonDecode(jsonStr!);

      return Right(recipesJson.map((json) => Recipe.fromJson(json)).toList());
    } on FormatException {
      return Left(ParsingFailure());
    }
  }
}
