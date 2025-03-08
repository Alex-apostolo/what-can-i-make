import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:openai_dart/openai_dart.dart';
import 'package:what_can_i_make/features/user/domain/request_limit_service.dart';
import 'package:what_can_i_make/core/error/exceptions/api_exceptions.dart';

/// Base class for OpenAI services
abstract class OpenAIServiceBase {
  late final OpenAIClient _client;
  final RequestLimitService? requestLimitService;

  OpenAIServiceBase({this.requestLimitService}) {
    final apiKey = dotenv.env['OPENAI_API_KEY'];
    if (apiKey == null) {
      throw Exception('OpenAI API key not found in .env file');
    }
    _client = OpenAIClient(apiKey: apiKey);
  }

  Future<bool> checkRequestLimit() async {
    if (requestLimitService == null) {
      return true; // No request limit service, so no limit
    }

    if (requestLimitService!.hasExceededLimit) {
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
    // Check if we've exceeded the request limit
    final canProceed = await checkRequestLimit();
    if (!canProceed) {
      throw ApiLimitExceededException(
        'API request limit exceeded. Please upgrade your plan.',
      );
    }

    final response = await _client.createChatCompletion(
      request: CreateChatCompletionRequest(
        model: ChatCompletionModel.modelId(model),
        messages: messages,
        temperature: temperature,
        maxTokens: maxTokens,
      ),
    );

    // Record the request if service is available
    if (requestLimitService != null) {
      await requestLimitService!.recordRequest();
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
