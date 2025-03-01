import 'dart:convert';
import 'dart:io';
import 'package:openai_dart/openai_dart.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../models/kitchen_item.dart';
import 'package:dartz/dartz.dart';
import '../../core/error/failures/failure.dart';
import '../../core/utils/uuid_generator.dart';

/// Service to handle OpenAI API interactions for kitchen inventory analysis
class OpenAIService {
  late final OpenAIClient _client;

  // Maximum number of images to process in a single request
  static const int _maxImagesPerRequest = 3;

  static const _analyzePrompt = '''Analyze the kitchen image(s) and identify:
1. Ingredients (foods, spices, etc.)
2. Utensils (pots, pans, cutlery, etc.)
3. Equipment (appliances, tools, etc.)

If multiple images are provided, combine all items into a single comprehensive list.
The quantity should be a number, not a string.

The response must be in this exact JSON format without any markdown formatting or code tags:
{
  "items": [
    {
      "name": "item name",
      "category": "ingredient/utensil/equipment",
      "quantity": 1
    }
  ]
}

Important: Return only the raw JSON with no additional text, no ```json tags, and no formatting.''';

  OpenAIService() {
    final apiKey = dotenv.env['OPENAI_API_KEY'];
    if (apiKey == null) {
      throw Exception('OpenAI API key not found in .env file');
    }
    _client = OpenAIClient(apiKey: apiKey);
  }

  /// Analyzes kitchen inventory images and returns a list of identified items
  ///
  /// [imagePaths] is a list of paths to image files to analyze
  /// Returns Either a Failure or a list of [KitchenItem] objects
  Future<Either<Failure, List<KitchenItem>>> analyzeKitchenInventory(
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
  Either<Failure, List<KitchenItem>> _combineResults(
    List<Either<Failure, List<KitchenItem>>> results,
  ) {
    final allItems = <KitchenItem>[];

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
  Future<Either<Failure, List<KitchenItem>>> _processBatch(
    List<String> batchPaths,
  ) async {
    try {
      final imageParts = await _prepareImageParts(batchPaths);
      final response = await _sendApiRequest(imageParts);

      final content = response.choices.first.message.content;
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
        model: ChatCompletionModel.modelId('gpt-4-turbo'),
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

  /// Parses the OpenAI response and converts it to a list of KitchenItems
  Either<Failure, List<KitchenItem>> _parseResponse(String content) {
    try {
      // Parse the JSON string into a Map
      final Map<String, dynamic> jsonData = jsonDecode(content);

      // Extract the "items" list from the JSON object
      final List<dynamic> items = jsonData['items'] ?? [];

      final kitchenItems =
          items
              .map<KitchenItem>(
                (item) => KitchenItem.fromMap({
                  ...item,
                  'id': UuidGenerator.generate(),
                }),
              )
              .toList();

      return Right(kitchenItems);
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