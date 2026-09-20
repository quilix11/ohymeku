// lib/services/speech_service.dart
import 'package:speech_to_text/speech_to_text.dart';

class SpeechService {
  final SpeechToText _speechToText = SpeechToText();
  bool _isInitialized = false;

  bool get isAvailable => _isInitialized;

  Future<bool> initialize() async {
    _isInitialized = await _speechToText.initialize(
      onError: (error) {
        // Handle error silently; fallback to text input
      },
      onStatus: (status) {},
    );
    return _isInitialized;
  }

  Future<void> startListening({
    required Function(String text) onResult,
    required Function(bool isListening) onStatusChange,
  }) async {
    if (!_isInitialized) {
      await initialize();
    }
    if (!_isInitialized) return;

    await _speechToText.listen(
      onResult: (result) {
        onResult(result.recognizedWords);
      },
      listenOptions: SpeechListenOptions(
        localeId: 'en_US',
        listenFor: const Duration(seconds: 30),
        pauseFor: const Duration(seconds: 3),
        cancelOnError: false,
        partialResults: true,
      ),
    );
    onStatusChange(true);
  }

  Future<void> stopListening({
    required Function(bool isListening) onStatusChange,
  }) async {
    await _speechToText.stop();
    onStatusChange(false);
  }

  bool get isListening => _speechToText.isListening;

  void dispose() {
    _speechToText.stop();
  }
}
