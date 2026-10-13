import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'package:audioplayers/audioplayers.dart';
import 'api_credentials.dart';
import 'package:http/http.dart' as http;
import 'ai_service.dart';
import 'audio_cache_stub.dart' if (dart.library.io) 'audio_cache_io.dart'
    as disk;

const cloudVoiceNames = [
  'Charon',
  'Kore',
  'Puck',
  'Aoede',
  'Fenrir',
  'Leda',
  'Orus',
  'Zephyr'
];

class CloudSpeechService {
  AudioPlayer? _player;
  http.Client? _client;
  final Map<String, Uint8List> _cache = {};
  int _generation = 0;
  Completer<void>? _finished;
  bool _disposed = false;
  Future<void> speak(
      String text, String voice, String style, double speed, double volume,
      {bool offline = false}) async {
    final generation = _generation + 1;
    await stop();
    if (_disposed || generation != _generation) return;
    final key = ApiCredentials.geminiKey;
    final cacheKey = '$voice|$style|$text';
    Uint8List? wav = _cache[cacheKey] ?? await disk.readAudio(cacheKey);
    if (wav == null) {
      if (offline) {
        throw const AiException(
            'Це озвучення ще не завантажене. Вибери системний голос для офлайн-вимови.');
      }
      if (key.isEmpty) {
        throw const AiException('Для голосів Gemini потрібен ключ API.');
      }
      final client = http.Client();
      _client = client;
      try {
        final tone = switch (style) {
          'friendly' => 'warm and friendly',
          'expressive' => 'expressive but natural',
          _ => 'calm and clear'
        };
        final response = await client
            .post(
                Uri.parse(
                    'https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-flash-preview-tts:generateContent'),
                headers: {
                  'Content-Type': 'application/json',
                  'x-goog-api-key': key
                },
                body: jsonEncode({
                  'contents': [
                    {
                      'parts': [
                        {
                          'text':
                              'Read the following English transcript exactly, in a $tone voice. Do not add any words. Transcript:\n$text'
                        }
                      ]
                    }
                  ],
                  'generationConfig': {
                    'responseModalities': ['AUDIO'],
                    'speechConfig': {
                      'voiceConfig': {
                        'prebuiltVoiceConfig': {'voiceName': voice}
                      }
                    }
                  },
                }))
            .timeout(const Duration(seconds: 35));
        if (generation != _generation || _disposed) return;
        if (response.statusCode != 200) {
          throw const AiException(
              'Голос Gemini недоступний або вичерпано ліміт. Можна вибрати системні голоси в налаштуваннях.');
        }
        final json = jsonDecode(response.body);
        final parts = json['candidates'][0]['content']['parts'] as List;
        final audio = parts.map((p) => p['inlineData']).whereType<Map>().first;
        final bytes = base64Decode(audio['data'] as String);
        final mime = audio['mimeType'] as String? ?? '';
        if (mime.contains('wav')) {
          wav = bytes;
        } else if (mime.toLowerCase().contains('l16') ||
            mime.toLowerCase().contains('pcm')) {
          final rate = int.tryParse(
                  RegExp(r'rate=(\d+)').firstMatch(mime)?.group(1) ?? '') ??
              24000;
          wav = _wave(bytes, rate);
        } else {
          throw const AiException('Непідтримуваний формат голосу.');
        }
        if (_cache.length >= 6) _cache.remove(_cache.keys.first);
        _cache[cacheKey] = wav;
        await disk.writeAudio(cacheKey, wav);
      } on AiException {
        rethrow;
      } catch (_) {
        if (generation != _generation || _disposed) return;
        throw const AiException(
            'Не вдалося завантажити голос Gemini. Перевір з’єднання або вибери системний голос.');
      } finally {
        client.close();
        if (identical(_client, client)) _client = null;
      }
    }
    if (generation != _generation || _disposed) return;
    final player = _player ??= AudioPlayer();
    final done = Completer<void>();
    _finished = done;
    final subscription = player.onPlayerComplete.listen((_) {
      if (!done.isCompleted) done.complete();
    });
    try {
      await player.play(BytesSource(wav, mimeType: 'audio/wav'),
          volume: volume.clamp(0, 1));
      if (generation != _generation || _disposed) {
        await player.stop();
        return;
      }
      await player.setPlaybackRate((speed / .5).clamp(.5, 1.6));
      await done.future.timeout(const Duration(seconds: 90));
    } finally {
      await subscription.cancel();
      if (identical(_finished, done)) _finished = null;
      if (generation == _generation) await player.stop();
    }
  }

  static Uint8List _wave(Uint8List pcm, int rate) {
    final data = ByteData(44 + pcm.length);
    void text(int at, String s) {
      for (var i = 0; i < s.length; i++) {
        data.setUint8(at + i, s.codeUnitAt(i));
      }
    }

    text(0, 'RIFF');
    data.setUint32(4, 36 + pcm.length, Endian.little);
    text(8, 'WAVEfmt ');
    data.setUint32(16, 16, Endian.little);
    data.setUint16(20, 1, Endian.little);
    data.setUint16(22, 1, Endian.little);
    data.setUint32(24, rate, Endian.little);
    data.setUint32(28, rate * 2, Endian.little);
    data.setUint16(32, 2, Endian.little);
    data.setUint16(34, 16, Endian.little);
    text(36, 'data');
    data.setUint32(40, pcm.length, Endian.little);
    data.buffer.asUint8List().setRange(44, 44 + pcm.length, pcm);
    return data.buffer.asUint8List();
  }

  Future<void> stop() async {
    _generation++;
    _client?.close();
    _client = null;
    final done = _finished;
    _finished = null;
    if (done != null && !done.isCompleted) done.complete();
    if (_player != null) {
      try {
        await _player!.stop();
      } catch (_) {}
    }
  }

  Future<void> clearCache() async {
    _cache.clear();
    await disk.clearAudio();
  }

  void dispose() {
    _disposed = true;
    unawaited(stop().then((_) async {
      await _player?.dispose();
    }));
    _cache.clear();
  }
}
