import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'gemini_http.dart';
import 'ai_service.dart';

/// Fast text model, with one Lite alias fallback for unavailable versions.
/// Each owner keeps its client and closes it; this adapter owns no resources.
class GeminiTransport {
  final http.Client client;
  String? _workingModel;
  final Duration timeout;
  GeminiTransport(this.client, {this.timeout = const Duration(seconds: 20)});

  static Object? _jsonSchema(Object? value) {
    if (value is List) return value.map(_jsonSchema).toList();
    if (value is Map) {
      return {
        for (final entry in value.entries)
          entry.key: entry.key == 'type' && entry.value is String
              ? (entry.value as String).toLowerCase()
              : _jsonSchema(entry.value)
      };
    }
    return value;
  }

  Future<http.Response> post(Map<String, dynamic> payload, String key,
      {Duration? budget}) async {
    final configured = dotenv.isInitialized
        ? dotenv.env['GEMINI_MODEL']?.trim().replaceFirst('models/', '')
        : null;
    var model = _workingModel ??
        (configured != null &&
                RegExp(r'^gemini-[a-z0-9.-]+$').hasMatch(configured)
            ? configured
            : 'gemini-3.5-flash-lite');
    final clock = Stopwatch()..start();
    for (var attempt = 0; attempt < 2; attempt++) {
      final config =
          Map<String, dynamic>.from(payload['generationConfig'] as Map? ?? {});
      final mime = config.remove('responseMimeType');
      final schema = config.remove('responseSchema');
      config['responseFormat'] = {
        'text': {
          'mimeType': mime == 'text/plain' ? 'TEXT_PLAIN' : 'APPLICATION_JSON',
          if (schema != null) 'schema': _jsonSchema(schema),
        }
      };
      config['thinkingConfig'] = model.startsWith('gemini-2.5')
          ? {'thinkingBudget': 0}
          : {'thinkingLevel': 'MINIMAL'};
      if (!model.startsWith('gemini-2.5') && !model.startsWith('gemini-3.')) {
        config.remove('thinkingConfig');
      }
      final body = {...payload, 'generationConfig': config};
      if (body.containsKey('system_instruction')) {
        body['systemInstruction'] = body.remove('system_instruction');
      }
      final remaining = (budget ?? timeout) - clock.elapsed;
      if (remaining <= Duration.zero) {
        throw const AiException('Gemini не відповів вчасно. Запит скасовано.');
      }
      final response = await GeminiHttp.post(
          client,
          Uri.parse(
              'https://generativelanguage.googleapis.com/v1beta/models/$model:generateContent'),
          body,
          key,
          route: 'text',
          timeout: remaining);
      if (response.statusCode == 200) {
        _workingModel = model;
        return response;
      }
      if (attempt == 0 &&
          response.statusCode == 404 &&
          model != 'gemini-flash-lite-latest') {
        model = 'gemini-flash-lite-latest';
        continue;
      }
      throw GeminiHttp.error(response, model, key);
    }
    throw StateError('Unreachable Gemini request state');
  }
}
