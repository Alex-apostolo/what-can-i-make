import 'package:dartz/dartz.dart';
import 'package:what_can_i_make/core/error/failures/failure.dart';
import 'package:what_can_i_make/features/inventory/models/ingredient_category.dart';
import 'package:what_can_i_make/core/services/openai_service_base.dart';
import 'package:openai_dart/openai_dart.dart';

/// Service to handle ingredient categorization using OpenAI
class CategoryService extends OpenAIServiceBase {
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

  Future<Either<Failure, IngredientCategory>> categorizeIngredient(
    String ingredientName,
  ) async {
    try {
      final response = await sendRequest([
        ChatCompletionMessage.system(
          content:
              'You are a helpful assistant that categorizes food ingredients. Return only the category name, nothing else.',
        ),
        ChatCompletionMessage.user(
          content: ChatCompletionUserMessageContent.string(
            '$categoryPrompt\n\nIngredient: $ingredientName',
          ),
        ),
      ], 'gpt-4o-mini');

      final content = response.choices.first.message.content;
      if (content == null) {
        return Left(OpenAIEmptyResponseFailure(Exception(response)));
      }

      final cleanedContent = cleanResponse(content);
      return Right(IngredientCategory.fromString(cleanedContent));
    } on Exception catch (e) {
      return Left(GenericFailure(e));
    }
  }
}
