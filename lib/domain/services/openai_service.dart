import 'dart:convert';
import 'dart:io';
import 'package:openai_dart/openai_dart.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:what_can_i_make/domain/models/measurement_unit.dart';
import '../models/ingredient.dart';
import '../models/ingredient_category.dart';
import 'package:dartz/dartz.dart';
import '../../core/error/failures/failure.dart';
import '../../core/utils/generate_unique_id.dart';

/// Service to handle OpenAI API interactions for ingredient analysis
class OpenAIService {
  late final OpenAIClient _client;

  // Maximum number of images to process in a single request
  static const int _maxImagesPerRequest = 3;

  static const String UNIT_PROMPT = '''
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

  static const String CATEGORY_PROMPT = '''
Return one of these exact categories:
- "Vegetables"
- "Fruits"
- "Grains & Legumes"
- "Meat & Seafood"
- "Dairy & Eggs"
- "Oils & Fats"
- "Sweeteners & Baking Essentials"
- "Condiments, Herbs & Spices"
- "Other"
''';

  static const _analyzePrompt = '''
Analyze the given image of a refrigerator and extract details in JSON format. Your response should contain a single key: `"ingredients"`, which holds a list of objects. Each object should represent an ingredient and include the following keys:  

- `"name"`: The specific name of the ingredient (e.g., `"Whole Milk"`, `"Cherry Tomato"`, `"Ground Beef"`, `"Cheddar Cheese"`, `"Strawberry Yogurt"`). Avoid general terms like `"Fruits"`, `"Vegetables"`, or `"Desserts"`. IMPORTANT: If brand is visible include it in the name.
- `"quantity"`: A numerical value representing the amount of the ingredient. If the quantity is unclear, return `0`.  
- `"unit"`: The unit of measurement for the ingredient, if the unit is unclear return `"Unknown"`. $UNIT_PROMPT
- `"category"`: The category this ingredient belongs to. $CATEGORY_PROMPT

Ensure the JSON is properly formatted and contains only relevant data from the image. Example response format:  

{
  "ingredients": [
    {
      "name": "Whole Milk",
      "quantity": 2,
      "unit": "L",
      "category": "Dairy & Eggs"
    },
    {
      "name": "Cherry Tomatoes",
      "quantity": 200,
      "unit": "g",
      "category": "Vegetables"
    },
    {
      "name": "Cheddar Cheese",
      "quantity": 500,
      "unit": "g",
      "category": "Dairy & Eggs"
    },
    {
      "name": "Strawberry Yogurt",
      "quantity": 4,
      "unit": "cups",
      "category": "Dairy & Eggs"
    }
  ]
}

This ensures structured, detailed outputs while avoiding vague or generalized ingredient names.
''';

  static const _categorizePrompt = '''
Categorize the given ingredient into one of the following categories:
$CATEGORY_PROMPT

Return only the category name, nothing else.
''';

  OpenAIService() {
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
                '$_categorizePrompt\n\nIngredient: $ingredientName',
              ),
            ),
          ],
        ),
      );

      final content = response.choices.first.message.content;
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

  /// Analyzes kitchen inventory images and returns a list of identified ingredients
  ///
  /// [imagePaths] is a list of paths to image files to analyze
  /// Returns Either a Failure or a list of [Ingredient] objects
  Future<Either<Failure, List<Ingredient>>> analyzeKitchenInventory(
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
    final allItems = <Ingredient>[];

    for (final result in results) {
      if (result.isLeft()) {
        // Return the first error encountered
        return result;
      }

      // Extract items from the successful result
      final items = result.getOrElse(() => []);
      allItems.addAll(items);
    }

    return Right(allItems);
  }

  /// Processes a batch of images (up to _maxImagesPerRequest)
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
                'You are a helpful assistant that analyzes kitchen images and returns data in strict JSON format. Always include an "items" array in your response, even if empty. Never include markdown formatting, code block tags, or any text outside the JSON object.',
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
