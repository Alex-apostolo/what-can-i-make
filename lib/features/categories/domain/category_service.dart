import 'package:dartz/dartz.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:openai_dart/openai_dart.dart';
import 'package:what_can_i_make/core/error/failures/failure.dart';
import 'package:what_can_i_make/core/models/ingredient_category.dart';

/// Service to handle ingredient categorization using OpenAI
class CategoryService {
  late final OpenAIClient _client;

  // Prompt for categorizing ingredients
  static const String categoryPrompt = '''
Categorize the given ingredient into one of the following categories:
- "Vegetables"
- "Fruits"
- "Grains & Legumes"
- "Meat & Seafood"
- "Dairy & Eggs"
- "Oils & Fats"
- "Nuts & Seeds"
- "Sweeteners & Baking Essentials"
- "Condiments, Herbs & Spices"
- "Beverages"
- "Snacks & Desserts"
- "Prepared Foods"
- "Frozen Foods"
- "Canned & Jarred Goods"
- "International Ingredients"
- "Other"

Return only the category name, nothing else.
''';

  /// Constructor that initializes the OpenAI client
  CategoryService() {
    final apiKey = dotenv.env['OPENAI_API_KEY'];
    if (apiKey == null) {
      throw Exception('OpenAI API key not found in .env file');
    }
    _client = OpenAIClient(apiKey: apiKey);
  }

  /// Categorizes an ingredient using OpenAI
  ///
  /// [ingredientName] is the name of the ingredient to categorize
  /// Returns Either a Failure or an IngredientCategory
  Future<Either<Failure, IngredientCategory>> categorizeIngredient(
    String ingredientName,
  ) async {
    try {
      final response = await _client.createChatCompletion(
        request: CreateChatCompletionRequest(
          model: ChatCompletionModel.modelId('gpt-4o-mini'),
          messages: [
            ChatCompletionMessage.system(
              content:
                  'You are a helpful assistant that categorizes food ingredients. Return only the category name, nothing else.',
            ),
            ChatCompletionMessage.user(
              content: ChatCompletionUserMessageContent.string(
                '$categoryPrompt\n\nIngredient: $ingredientName',
              ),
            ),
          ],
        ),
      );

      final content = response.choices.first.message.content;
      if (content == null) {
        return Left(OpenAIEmptyResponseFailure());
      }

      // Clean up the response (remove quotes, trim whitespace)
      final cleanedContent =
          content.replaceAll('"', '').replaceAll("'", '').trim();

      // Convert to IngredientCategory
      final category = IngredientCategory.fromString(cleanedContent);
      return Right(category);
    } on OpenAIClientException {
      return Left(OpenAIRequestFailure());
    }
  }

  /// Closes the OpenAI client session
  void dispose() {
    _client.endSession();
  }
}
