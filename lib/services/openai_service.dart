import 'dart:convert';
import 'dart:io';
import 'package:openai_dart/openai_dart.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class OpenAIService {
  late final OpenAIClient _client;

  OpenAIService() {
    final apiKey = dotenv.env['OPENAI_API_KEY'];
    if (apiKey == null) {
      throw Exception('OpenAI API key not found in .env file');
    }
    _client = OpenAIClient(apiKey: apiKey);
  }

  Future<String> analyzeImageIngredients(String imagePath) async {
    final bytes = await File(imagePath).readAsBytes();
    final base64Image = base64Encode(bytes);
    final base64Uri = 'data:image/jpeg;base64,$base64Image';

    final response = await _client.createChatCompletion(
      request: CreateChatCompletionRequest(
        model: ChatCompletionModel.modelId('gpt-4o'),
        messages: [
          ChatCompletionMessage.user(
            content: ChatCompletionUserMessageContent.parts([
              ChatCompletionMessageContentPart.text(
                text: 'What ingredients can you see in this image?',
              ),
              ChatCompletionMessageContentPart.image(
                imageUrl: ChatCompletionMessageImageUrl(url: base64Uri),
              ),
            ]),
          ),
        ],
        maxTokens: 300,
      ),
    );

    return response.choices.first.message.content ??
        'No ingredients detected';
  }

  void dispose() {
    _client.endSession();
  }
}
