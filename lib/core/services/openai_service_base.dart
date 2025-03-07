import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:openai_dart/openai_dart.dart';
import 'package:what_can_i_make/core/services/token_usage_service.dart';

/// Base class for OpenAI services
abstract class OpenAIServiceBase {
  late final OpenAIClient _client;
  final TokenUsageService? tokenUsageService;

  OpenAIServiceBase({this.tokenUsageService}) {
    final apiKey = dotenv.env['OPENAI_API_KEY'];
    if (apiKey == null) {
      throw Exception('OpenAI API key not found in .env file');
    }
    _client = OpenAIClient(apiKey: apiKey);
  }

  Future<bool> checkTokenLimit() async {
    if (tokenUsageService == null) {
      return true; // No token service, so no limit
    }

    if (tokenUsageService!.hasExceededLimit) {
      return false; // Limit exceeded
    }

    return true; // Under limit
  }

  Future<CreateChatCompletionResponse> sendRequest(
    List<ChatCompletionMessage> messages,
    String model, {
    double? temperature,
    int? maxTokens,
  }) async {
    // Check if we've exceeded the token limit
    final canProceed = await checkTokenLimit();
    if (!canProceed) {
      throw Exception('Token usage limit exceeded. Please upgrade your plan.');
    }

    final response = await _client.createChatCompletion(
      request: CreateChatCompletionRequest(
        model: ChatCompletionModel.modelId(model),
        messages: messages,
        temperature: temperature,
        maxTokens: maxTokens,
      ),
    );

    // Track token usage if service is available
    if (tokenUsageService != null) {
      // Use the actual token count from the API response
      final totalTokens = tokenUsageService!.tokensUsed;
      await tokenUsageService!.recordTokenUsage(totalTokens + 1);
    }

    return response;
  }

  String cleanResponse(String response) {
    return response.replaceAll(RegExp(r'```json\n'), '').replaceAll('```', '');
  }

  void dispose() {
    _client.endSession();
  }
}
