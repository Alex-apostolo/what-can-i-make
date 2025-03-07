import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:openai_dart/openai_dart.dart';

/// Base class for OpenAI services
abstract class OpenAIServiceBase {
  late final OpenAIClient _client;

  OpenAIServiceBase() {
    final apiKey = dotenv.env['OPENAI_API_KEY'];
    if (apiKey == null) {
      throw Exception('OpenAI API key not found in .env file');
    }
    _client = OpenAIClient(apiKey: apiKey);
  }

  Future<CreateChatCompletionResponse> sendRequest(
    List<ChatCompletionMessage> messages,
    String model, {
    double? temperature,
    int? maxTokens,
  }) {
    return _client.createChatCompletion(
      request: CreateChatCompletionRequest(
        model: ChatCompletionModel.modelId(model),
        messages: messages,
        temperature: temperature,
        maxTokens: maxTokens,
      ),
    );
  }

  String cleanResponse(String response) {
    return response.replaceAll(RegExp(r'```json\n'), '').replaceAll('```', '');
  }

  void dispose() {
    _client.endSession();
  }
}
