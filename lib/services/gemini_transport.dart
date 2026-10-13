import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;

/// Stable aliases avoid pinning app features to a retired model version.
/// Each owner keeps its client and closes it; this adapter owns no resources.
class GeminiTransport {
  final http.Client client;
  String? _workingModel;
  GeminiTransport(this.client);

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

  Future<http.Response> post(Map<String, dynamic> payload, String key) async {
    final configured = dotenv.isInitialized
        ? dotenv.env['GEMINI_MODEL']?.trim().replaceFirst('models/', '')
        : null;
    var model = _workingModel ??
        (configured != null &&
                RegExp(r'^gemini-[a-z0-9.-]+$').hasMatch(configured)
            ? configured
            : 'gemini-flash-latest');
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
          : {'thinkingLevel': 'low'};
      // Lite aliases have different thinking controls; their default suffices.
      if (model.contains('lite')) config.remove('thinkingConfig');
      final body = {...payload, 'generationConfig': config};
      if (body.containsKey('system_instruction')) {
        body['systemInstruction'] = body.remove('system_instruction');
      }
      final response = await client.post(
          Uri.parse(
              'https://generativelanguage.googleapis.com/v1beta/models/$model:generateContent'),
          headers: {'Content-Type': 'application/json', 'x-goog-api-key': key},
          body: jsonEncode(body));
      if (response.statusCode == 200) {
        _workingModel = model;
        return response;
      }
      if (attempt == 0 && [404, 429, 503].contains(response.statusCode)) {
        model = response.statusCode == 404 && model != 'gemini-flash-latest'
            ? 'gemini-flash-latest'
            : 'gemini-flash-lite-latest';
        continue;
      }
      return response;
    }
    throw StateError('Unreachable Gemini request state');
  }
}
