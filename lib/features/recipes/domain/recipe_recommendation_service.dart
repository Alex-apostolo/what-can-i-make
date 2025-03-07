import 'dart:convert';
import 'package:dartz/dartz.dart';
import 'package:openai_dart/openai_dart.dart';
import 'package:what_can_i_make/core/error/failures/failure.dart';
import 'package:what_can_i_make/core/models/ingredient.dart';
import 'package:what_can_i_make/core/models/recipe.dart';
import 'package:what_can_i_make/core/services/openai_service_base.dart';

class RecipeRecommendationService extends OpenAIServiceBase {
  RecipeRecommendationService({required super.requestLimitService});

  String _generateRecipesPrompt({
    required String availableIngredients,
    required bool strictMode,
  }) => '''
Generate 3 recipe recommendations using these ingredients: $availableIngredients.
${strictMode ? 'Only use the listed ingredients.' : 'You can suggest additional ingredients if needed.'}
 Assume that the user has basic ingredients like salt, pepper, water dont include these in the response.
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
      final response = await sendRequest(
        [
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
        'gpt-4o',
        temperature: 0.7,
        maxTokens: 1000,
      );

      // Extract the content from the response
      final content = response.choices.first.message.content;
      if (content == null) {
        return Left(OpenAIEmptyResponseFailure(Exception(response)));
      }

      return _parseResponse(content);
    } on OpenAIClientException catch (e) {
      return Left(OpenAIRequestFailure(e));
    } on Exception catch (e) {
      return Left(GenericFailure(e));
    }
  }

  Either<Failure, List<Recipe>> _parseResponse(String content) {
    try {
      final jsonMatch = RegExp(
        r'\[\s*\{.*\}\s*\]',
        dotAll: true,
      ).firstMatch(content);

      if (jsonMatch == null) {
        return Left(ParsingFailure(Exception(content)));
      }

      final jsonStr = jsonMatch.group(0);
      final List<dynamic> recipesJson = jsonDecode(jsonStr!);

      return Right(recipesJson.map((json) => Recipe.fromJson(json)).toList());
    } on FormatException catch (e) {
      return Left(ParsingFailure(e));
    }
  }
}
