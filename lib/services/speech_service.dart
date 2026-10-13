import 'package:speech_to_text/speech_to_text.dart';

class SpeechService {
  final SpeechToText _speech = SpeechToText();
  bool _ready = false, _disposed = false;
  void Function(bool)? _onStatus;
  void Function(String)? _onError;

  Future<bool> initialize() async {
    if (_disposed) return false;
    _ready = await _speech.initialize(
      onStatus: (status) {
        if (_disposed) return;
        if (status == 'listening') _onStatus?.call(true);
        if (status == 'done' || status == 'notListening') {
          _onStatus?.call(false);
        }
      },
      onError: (error) {
        if (_disposed) return;
        _onStatus?.call(false);
        _onError?.call(
            'Не вдалося розпізнати голос. Спробуй ще раз або введи текст.');
      },
    );
    return _ready;
  }

  Future<void> startListening(
      {required void Function(String, bool) onResult,
      String locale = 'en_US',
      int pauseSeconds = 3,
      required void Function(bool) onStatusChange,
      required void Function(String) onError}) async {
    _onStatus = onStatusChange;
    _onError = onError;
    try {
      if (!_ready) await initialize();
      if (_disposed) return;
      if (!_ready) {
        onError(
            'Мікрофон недоступний. Перевір дозвіл у налаштуваннях пристрою або введи текст.');
        return;
      }
      await _speech.listen(
          onResult: (result) {
            if (!_disposed) {
              onResult(result.recognizedWords, result.finalResult);
            }
          },
          listenOptions: SpeechListenOptions(
              localeId: locale,
              listenFor: const Duration(seconds: 30),
              pauseFor: Duration(seconds: pauseSeconds),
              partialResults: true,
              cancelOnError: true));
      if (!_disposed) onStatusChange(_speech.isListening);
    } catch (_) {
      if (!_disposed) {
        onStatusChange(false);
        onError('Запис недоступний. Текстове введення працює.');
      }
    }
  }

  Future<void> stopListening() async {
    await _speech.stop();
    if (!_disposed) _onStatus?.call(false);
  }

  Future<void> cancel() async {
    if (!_ready) return;
    await _speech.cancel();
    if (!_disposed) _onStatus?.call(false);
  }

  void dispose() {
    _disposed = true;
    _onStatus = null;
    _onError = null;
    if (_ready) _speech.cancel();
  }
}
