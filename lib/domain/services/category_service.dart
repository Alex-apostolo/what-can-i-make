import 'package:openai_dart/openai_dart.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:dartz/dartz.dart';
import '../models/ingredient_category.dart';
import '../../core/error/failures/failure.dart';

/// Service to handle ingredient categorization using OpenAI
class CategoryService {
  late final OpenAIClient _client;

  static const String CATEGORY_PROMPT = '''
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
          model: ChatCompletionModel.modelId('gpt-4o'),
          messages: [
            ChatCompletionMessage.system(
              content:
                  'You are a helpful assistant that categorizes food ingredients. Return only the category name, nothing else.',
            ),
            ChatCompletionMessage.user(
              content: ChatCompletionUserMessageContent.string(
                '$CATEGORY_PROMPT\n\nIngredient: $ingredientName',
              ),
            ),
          ],
        ),
      );

      final content = response.choices.first.message.content;
      print("Category response: $content");
      if (content == null) {
        return Left(OpenAIRequestFailure('Empty response from OpenAI'));
      }

      // Clean up the response (remove quotes, trim whitespace)
      final cleanedContent =
          content.replaceAll('"', '').replaceAll("'", '').trim();

      // Convert to IngredientCategory
      final category = IngredientCategory.fromString(cleanedContent);
      return Right(category);
    } catch (e) {
      return Left(OpenAIRequestFailure(e.toString()));
    }
  }

  /// Closes the OpenAI client session
  void dispose() {
    _client.endSession();
  }
}
