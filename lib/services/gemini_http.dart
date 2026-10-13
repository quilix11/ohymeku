import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'ai_service.dart';
import 'api_credentials.dart';

class GeminiHttp {
  static Future<http.Response> post(http.Client client, Uri upstream,
      Map<String, dynamic> payload, String key,
      {required String route,
      Duration timeout = const Duration(seconds: 20)}) async {
    final useGateway = key.isEmpty && ApiCredentials.useGateway;
    final endpoint =
        useGateway ? ApiCredentials.gateway!.resolve('/api/$route') : upstream;
    final abort = Completer<void>();
    final request =
        http.AbortableRequest('POST', endpoint, abortTrigger: abort.future)
          ..headers.addAll({
            'Content-Type': 'application/json',
            if (!useGateway) 'x-goog-api-key': key
          })
          ..body = jsonEncode(useGateway
              ? {
                  'model': upstream.path.split('/').last.split(':').first,
                  'payload': payload,
                }
              : payload);
    try {
      return await (() async =>
              http.Response.fromStream(await client.send(request)))()
          .timeout(timeout, onTimeout: () {
        if (!abort.isCompleted) abort.complete();
        throw const AiException(
            'Gemini не відповів вчасно. Запит скасовано; спробуй ще раз.');
      });
    } on http.ClientException {
      throw const AiException(
          'Немає зв’язку з Gemini: перевір інтернет. У браузері причиною також може бути блокування запиту мережею або CORS.');
    }
  }

  static AiException error(http.Response response, String model, String key) {
    String details = '', status = '';
    try {
      final body = jsonDecode(utf8.decode(response.bodyBytes));
      final error = body is Map ? body['error'] : null;
      if (error is Map) {
        if (error['message'] is String) details = error['message'];
        if (error['status'] is String) status = error['status'];
      }
    } catch (_) {/* A proxy may return HTML instead of Google's JSON. */}
    String sanitize(String value) {
      if (key.isNotEmpty) value = value.replaceAll(key, '[приховано]');
      return value
          .replaceAll(
              RegExp(r'AIza[A-Za-z0-9_-]+|AQ\.[A-Za-z0-9_.-]+'), '[приховано]')
          .replaceAll(RegExp(r'[\r\n]+'), ' ')
          .trim();
    }

    details = sanitize(details);
    status = sanitize(status);
    if (status.length > 80) status = status.substring(0, 80);
    if (details.length > 280) details = '${details.substring(0, 280)}…';
    final reason = switch (response.statusCode) {
      400 => 'Запит або параметри моделі не підтримуються',
      401 => 'Ключ Gemini недійсний',
      403 => 'Доступ заборонено: перевір права ключа, API та доступ до моделі',
      404 => 'Модель не знайдена або недоступна для цього ключа',
      429 => 'Вичерпано квоту або перевищено частоту запитів',
      500 ||
      502 ||
      503 ||
      504 =>
        'Сервіс Gemini або шлюз тимчасово недоступний',
      _ => 'Gemini відхилив запит',
    };
    final actualModel = sanitize(response.headers['x-gemini-model'] ?? model);
    return AiException(
        '$reason (HTTP ${response.statusCode}${status.isEmpty ? '' : ', $status'}, $actualModel).${details.isEmpty ? '' : ' $details'}');
  }
}
