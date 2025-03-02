import 'dart:convert';
import 'dart:io';
import 'package:openai_dart/openai_dart.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../models/ingredient.dart';
import 'package:dartz/dartz.dart';
import '../../core/error/failures/failure.dart';
import '../../core/utils/generate_unique_id.dart';

/// Service to handle OpenAI API interactions for ingredient analysis
class OpenAIService {
  late final OpenAIClient _client;

  // Maximum number of images to process in a single request
  static const int _maxImagesPerRequest = 3;

  static const _analyzePrompt = '''
Analyze the given image of a refrigerator and extract details in JSON format. Your response should contain a single key: `"ingredients"`, which holds a list of objects. Each object should represent an ingredient and include the following keys:  

- `"name"`: The specific name of the ingredient (e.g., `"Whole Milk"`, `"Cherry Tomato"`, `"Ground Beef"`, `"Cheddar Cheese"`, `"Strawberry Yogurt"`). Avoid general terms like `"Fruits"`, `"Vegetables"`, or `"Desserts"`.  
- `"brand"`: The brand of the product if visible (e.g., `"Tropicana"`, `"Peroni"`, `"Heinz"`). If the brand is not visible, return `"Unknown"`.  
- `"quantity"`: A numerical value representing the amount of the ingredient. If the quantity is unclear, return `0`.  
- `"unit"`: The unit of measurement for the ingredient (e.g., `"pieces"`, `"g"`, `"kg"`, `"ml"`, `"L"`, `"tbsp"`, `"tsp"`, `"cups"`). If the unit is unclear, return `"Unknown"`.  

Ensure the JSON is properly formatted and contains only relevant data from the image. Example response format:  

{
  "ingredients": [
    {
      "name": "Whole Milk",
      "brand": "DairyPure",
      "quantity": 2,
      "unit": "L"
    },
    {
      "name": "Cherry Tomatoes",
      "brand": "Unknown",
      "quantity": 200,
      "unit": "g"
    },
    {
      "name": "Cheddar Cheese",
      "brand": "Kraft",
      "quantity": 500,
      "unit": "g"
    },
    {
      "name": "Strawberry Yogurt",
      "brand": "Chobani",
      "quantity": 4,
      "unit": "cups"
    }
  ]
}

This ensures structured, detailed outputs while avoiding vague or generalized ingredient names.
''';

  OpenAIService() {
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

      final content = response.choices.first.message.content;
      print("content: $content");
      if (content == null) {
        return Left(OpenAIEmptyResponseFailure());
      }

      final cleanedContent = _cleanJsonContent(content);
      return _parseResponse(cleanedContent);
    } on SocketException {
      return Left(OpenAIConnectionFailure());
    } on HttpException catch (e) {
      return Left(OpenAIRequestFailure('HTTP error: ${e.message}'));
    } on FormatException catch (e) {
      return Left(OpenAIRequestFailure('Format error: ${e.message}'));
    } on OpenAIClientException catch (e) {
      return Left(OpenAIRequestFailure('OpenAI API error: ${e.message}'));
    } catch (e) {
      return Left(OpenAIRequestFailure(e.toString()));
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

            // Handle brand - set to null if "unknown"
            String? brand = item['brand'];
            if (brand != null &&
                (brand.isEmpty || brand.toLowerCase() == 'unknown')) {
              brand = null;
            }

            return Ingredient(
              id: generateUniqueId(),
              name: item['name'] ?? '',
              brand: brand,
              quantity: quantity,
              unit: item['unit'] ?? 'piece',
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
