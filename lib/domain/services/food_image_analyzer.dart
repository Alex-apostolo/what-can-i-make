import 'dart:convert';
import 'dart:io';
import 'package:openai_dart/openai_dart.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:what_can_i_make/domain/models/measurement_unit.dart';
import 'package:what_can_i_make/domain/services/category_service.dart';
import '../models/ingredient.dart';
import '../models/ingredient_category.dart';
import 'package:dartz/dartz.dart';
import '../../core/error/failures/failure.dart';
import '../../core/utils/generate_unique_id.dart';

/// Service to analyze food images and extract ingredients using OpenAI
class FoodImageAnalyzer {
  late final OpenAIClient _client;

  // Maximum number of images to process in a single request
  static const int _maxImagesPerRequest = 3;

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
      "unit": "L"
    },
    {
      "name": "Cherry Tomatoes",
      "quantity": 200,
      "unit": "g"
    },
    {
      "name": "Cheddar Cheese",
      "quantity": 500,
      "unit": "g"
    },
    {
      "name": "Strawberry Yogurt",
      "quantity": 4,
      "unit": "cups"
    }
  ]
}

This ensures structured, detailed outputs while avoiding vague or generalized ingredient names.
''';

  FoodImageAnalyzer() {
    final apiKey = dotenv.env['OPENAI_API_KEY'];
    if (apiKey == null) {
      throw Exception('OpenAI API key not found in .env file');
    }
    _client = OpenAIClient(apiKey: apiKey);
  }

  /// Analyzes kitchen inventory images and returns a list of identified ingredients
  ///
  /// [imagePaths] is a list of paths to image files to analyze
  /// Returns Either a Failure or a list of [Ingredient] objects
  Future<Either<Failure, List<Ingredient>>> analyzeInventory(
    List<String> imagePaths,
  ) async {
    if (imagePaths.isEmpty) {
      return const Right([]);
    }

    try {
      // Create batches of images to process in parallel
      final batches = _createBatches(imagePaths);

      // Process all batches in parallel
      final results = await Future.wait(batches.map(_processBatch));

      return _combineResults(results);
    } catch (e) {
      return Left(OpenAIRequestFailure(e.toString()));
    }
  }

  /// Creates batches of images for parallel processing
  List<List<String>> _createBatches(List<String> imagePaths) {
    final batches = <List<String>>[];

    for (int i = 0; i < imagePaths.length; i += _maxImagesPerRequest) {
      final end =
          (i + _maxImagesPerRequest < imagePaths.length)
              ? i + _maxImagesPerRequest
              : imagePaths.length;

      final batchPaths = imagePaths.sublist(i, end);
      batches.add(batchPaths);
    }

    return batches;
  }

  /// Combines results from multiple batches, handling errors
  Either<Failure, List<Ingredient>> _combineResults(
    List<Either<Failure, List<Ingredient>>> results,
  ) {
    final allIngredients = <Ingredient>[];
    final failures = <Failure>[];

    for (final result in results) {
      result.fold(
        (failure) => failures.add(failure),
        (ingredients) => allIngredients.addAll(ingredients),
      );
    }

    // If all batches failed, return the first failure
    if (allIngredients.isEmpty && failures.isNotEmpty) {
      return Left(failures.first);
    }

    // Otherwise return all successfully parsed ingredients
    return Right(allIngredients);
  }

  /// Processes a batch of images
  Future<Either<Failure, List<Ingredient>>> _processBatch(
    List<String> batchPaths,
  ) async {
    try {
      final imageParts = await _prepareImageParts(batchPaths);
      final response = await _sendApiRequest(imageParts);

      if (response.choices.isEmpty ||
          response.choices.first.message.content == null) {
        return Left(OpenAIRequestFailure('Empty response from OpenAI'));
      }

      final content = response.choices.first.message.content!;
      print("content: $content");
      final cleanedContent = _cleanJsonContent(content);

      return _parseResponse(cleanedContent);
    } on FormatException catch (e) {
      return Left(ParsingFailure('Format error: ${e.message}', ''));
    } catch (e) {
      return Left(
        OpenAIRequestFailure('Error processing batch: ${e.toString()}'),
      );
    }
  }

  /// Prepares image parts for the API request
  Future<List<ChatCompletionMessageContentPart>> _prepareImageParts(
    List<String> batchPaths,
  ) async {
    final imageParts = <ChatCompletionMessageContentPart>[];

    // Add the prompt
    imageParts.add(ChatCompletionMessageContentPart.text(text: _analyzePrompt));

    // Add each image as a part
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

  /// Sends the API request to OpenAI
  Future<CreateChatCompletionResponse> _sendApiRequest(
    List<ChatCompletionMessageContentPart> imageParts,
  ) {
    return _client.createChatCompletion(
      request: CreateChatCompletionRequest(
        model: ChatCompletionModel.modelId('gpt-4o'),
        messages: [
          ChatCompletionMessage.system(
            content:
                'You are a helpful assistant that analyzes kitchen images and returns data in strict JSON format. Always include an "ingredients" array in your response, even if empty. Never include markdown formatting, code block tags, or any text outside the JSON object.',
          ),
          ChatCompletionMessage.user(
            content: ChatCompletionUserMessageContent.parts(imageParts),
          ),
        ],
      ),
    );
  }

  /// Cleans the content to ensure it's valid JSON without markdown or code tags
  String _cleanJsonContent(String content) {
    String cleaned = content;

    // Remove ```json and ``` markers
    cleaned = cleaned.replaceAll(RegExp(r'```json\s*'), '');
    cleaned = cleaned.replaceAll(RegExp(r'```\s*$'), '');
    cleaned = cleaned.replaceAll('```', '');

    // Remove any leading/trailing whitespace
    return cleaned.trim();
  }

  /// Parses the OpenAI response and converts it to a list of Ingredients
  Either<Failure, List<Ingredient>> _parseResponse(String content) {
    try {
      // Parse the JSON string into a Map
      final Map<String, dynamic> jsonData = jsonDecode(content);

      // Extract the "ingredients" list from the JSON object
      final List<dynamic> ingredients = jsonData['ingredients'] ?? [];

      final parsedIngredients =
          ingredients.map<Ingredient>((item) {
            // Handle quantity - ensure it's an integer
            int quantity = 0;
            if (item['quantity'] != null) {
              if (item['quantity'] is int) {
                quantity = item['quantity'];
              } else if (item['quantity'] is double) {
                quantity = item['quantity'].toInt();
              } else if (item['quantity'] is String) {
                quantity = int.tryParse(item['quantity']) ?? 0;
              }
            }

            return Ingredient(
              id: generateUniqueIdWithTimestamp(),
              name: item['name'] ?? '',
              quantity: quantity,
              unit: MeasurementUnit.fromString(item['unit'] ?? 'piece'),
              category: IngredientCategory.fromString(
                item['category'] ?? 'Other',
              ),
            );
          }).toList();

      return Right(parsedIngredients);
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
