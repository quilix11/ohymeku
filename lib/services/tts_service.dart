// lib/services/tts_service.dart
import 'package:flutter_tts/flutter_tts.dart';

class TtsService {
  final FlutterTts _tts = FlutterTts();
  bool _isInitialized = false;

  Future<void> initialize() async {
    if (_isInitialized) return;
    await _tts.setLanguage('en-US');
    await _tts.setSpeechRate(0.55); // Faster speech rate
    await _tts.setVolume(1.0);
    await _tts.setPitch(1.0); // Natural pitch
    // Try to use a male voice for Officer Vance
    final voices = await _tts.getVoices as List?;
    if (voices != null) {
      final maleVoice = voices.firstWhere(
        (v) =>
            (v['name'] as String?)?.toLowerCase().contains('male') ==
                true ||
            (v['name'] as String?)?.toLowerCase().contains('en-us') ==
                true,
        orElse: () => null,
      );
      if (maleVoice != null) {
        await _tts.setVoice({
          'name': maleVoice['name'],
          'locale': maleVoice['locale'],
        });
      }
    }
    _isInitialized = true;
  }

  Future<void> speak(String text) async {
    if (!_isInitialized) await initialize();
    await _tts.stop();
    await _tts.speak(text);
  }

  Future<void> stop() async {
    await _tts.stop();
  }

  void dispose() {
    _tts.stop();
  }
}
