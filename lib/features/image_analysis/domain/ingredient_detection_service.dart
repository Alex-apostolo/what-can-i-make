import 'dart:convert';
import 'dart:io';
import 'package:openai_dart/openai_dart.dart';
import 'package:what_can_i_make/core/models/ingredient.dart';
import 'package:what_can_i_make/core/services/openai_service_base.dart';
import 'package:dartz/dartz.dart';
import 'package:what_can_i_make/core/error/failures/failure.dart';
import 'package:what_can_i_make/features/categories/domain/category_service.dart';

/// Service to analyze food images and extract ingredients using OpenAI
class IngredientDetectionService extends OpenAIServiceBase {
  static const int _maxImagesPerRequest = 1;

  static const String _unitPrompt = '''
Return one of these exact units (singular or plural form):
Volume (Metric):
- "ml" (milliliter/milliliters)
- "L" (liter/liters)

Volume (Imperial):
- "tsp" (teaspoon/teaspoons)
- "tbsp" (tablespoon/tablespoons)
- "fl oz" (fluid ounce/fluid ounces)
- "cup/cups"
- "pt" (pint/pints)
- "qt" (quart/quarts)
- "gal" (gallon/gallons)

Weight (Metric):
- "g" (gram/grams)
- "kg" (kilogram/kilograms)

Weight (Imperial):
- "oz" (ounce/ounces)
- "lb" (pound/pounds)

Count/Whole:
- "piece/pieces"
- "dozen/dozens"
- "pair/pairs"

Packaging:
- "can/cans"
- "bottle/bottles"
- "box/boxes"
- "package/packages"
- "bag/bags"
- "carton/cartons"
- "container/containers"
- "jar/jars"
- "tube/tubes"
- "tin/tins"
- "bowl/bowls"

Produce:
- "bunch/bunches"
- "head/heads"
- "clove/cloves"
- "sprig/sprigs"
- "stalk/stalks"
- "slice/slices"
- "wedge/wedges"
''';

  static const String _categoryPrompt = CategoryService.categoryPrompt;

  static const _analyzePrompt = '''
Analyze the given image of a refrigerator and extract details in JSON format. Your response should contain a single key: `"ingredients"`, which holds a list of objects. Each object should represent an ingredient and include the following keys:  

- `"name"`: The specific name of the ingredient (e.g., `"Whole Milk"`, `"Cherry Tomato"`, `"Ground Beef"`, `"Cheddar Cheese"`, `"Strawberry Yogurt"`). Avoid general terms like `"Fruits"`, `"Vegetables"`, or `"Desserts"`. IMPORTANT: If brand is visible include it in the name.
- `"quantity"`: A numerical value representing the amount of the ingredient. If the quantity is unclear, return `1`.  
- `"unit"`: The unit of measurement for the ingredient, if the unit is unclear return `"piece"`. $_unitPrompt
- `"category"`: The category this ingredient belongs to. $_categoryPrompt

Ensure the JSON is properly formatted and contains only relevant data from the image. Example response format:  

{
  "ingredients": [
    {
      "name": "Whole Milk",
      "quantity": 2,
      "unit": "L",
      "category": "Dairy"
    },
    {
      "name": "Cherry Tomatoes",
      "quantity": 200,
      "unit": "g",
      "category": "Produce"
    },
    {
      "name": "Cheddar Cheese",
      "quantity": 500,
      "unit": "g",
      "category": "Dairy"
    },
    {
      "name": "Strawberry Yogurt",
      "quantity": 4,
      "unit": "cups",
      "category": "Dairy"
    }
  ]
}

This ensures structured, detailed outputs while avoiding vague or generalized ingredient names.
''';

  /// Analyzes kitchen inventory images and returns a list of identified ingredients
  ///
  /// [imagePaths] is a list of paths to image files to analyze
  /// Returns Either a Failure or a list of [Ingredient] objects
  Future<Either<Failure, List<IngredientInput>>> analyzeImages(
    List<String> imagePaths,
  ) async {
    if (imagePaths.isEmpty) return const Right([]);

    final batches = _createBatches(imagePaths);
    final results = await Future.wait(batches.map(_processBatch));
    return _combineResults(results);
  }

  List<List<String>> _createBatches(List<String> imagePaths) {
    return [
      for (int i = 0; i < imagePaths.length; i += _maxImagesPerRequest)
        imagePaths.sublist(
          i,
          i + _maxImagesPerRequest < imagePaths.length
              ? i + _maxImagesPerRequest
              : imagePaths.length,
        ),
    ];
  }

  Either<Failure, List<IngredientInput>> _combineResults(
    List<Either<Failure, List<IngredientInput>>> results,
  ) {
    final allIngredients = <IngredientInput>[];
    final failures = <Failure>[];

    for (final result in results) {
      result.fold(
        (failure) => failures.add(failure),
        (ingredients) => allIngredients.addAll(ingredients),
      );
    }

    return allIngredients.isEmpty && failures.isNotEmpty
        ? Left(failures.first)
        : Right(allIngredients);
  }

  Future<Either<Failure, List<IngredientInput>>> _processBatch(
    List<String> batchPaths,
  ) async {
    try {
      final imageParts = await _prepareImageParts(batchPaths);
      final response = await sendRequest([
        ChatCompletionMessage.system(content: _analyzePrompt),
        ChatCompletionMessage.user(
          content: ChatCompletionUserMessageContent.parts(imageParts),
        ),
      ], 'gpt-4o');

      final content = response.choices.first.message.content;
      if (content == null) {
        return Left(OpenAIEmptyResponseFailure(Exception(response)));
      }

      final cleanedContent = cleanResponse(content);
      final jsonContent = jsonDecode(cleanedContent);
      final ingredients =
          (jsonContent['ingredients'] as List)
              .map((item) => IngredientInput.fromJson(item))
              .toList();

      return Right(ingredients);
    } on Exception catch (e) {
      return Left(GenericFailure(e));
    }
  }

  Future<List<ChatCompletionMessageContentPart>> _prepareImageParts(
    List<String> batchPaths,
  ) async {
    final imageParts = <ChatCompletionMessageContentPart>[
      ChatCompletionMessageContentPart.text(text: _analyzePrompt),
    ];

    for (final path in batchPaths) {
      final bytes = await File(path).readAsBytes();
      final base64Image = base64Encode(bytes);
      final base64Uri = 'data:image/jpeg;base64,$base64Image';
      imageParts.add(
        ChatCompletionMessageContentPart.image(
          imageUrl: ChatCompletionMessageImageUrl(url: base64Uri),
        ),
      );
    }
    return imageParts;
  }
}
