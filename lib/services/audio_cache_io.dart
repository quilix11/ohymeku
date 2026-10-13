import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:crypto/crypto.dart';
import 'package:path_provider/path_provider.dart';

Future<Directory> _directory() async {
  final root = await getApplicationSupportDirectory();
  return Directory('${root.path}/voice_cache_v1').create(recursive: true);
}

String _name(String key) => sha256.convert(utf8.encode(key)).toString();
Future<Uint8List?> readAudio(String key) async {
  try {
    final dir = await _directory(), name = _name(key);
    final file = File('${dir.path}/$name.wav');
    if (!await file.exists()) return null;
    return await file.readAsBytes();
  } catch (_) {
    return null;
  }
}

Future<void> writeAudio(String key, Uint8List bytes) async {
  if (bytes.length > 4 * 1024 * 1024) return;
  try {
    final dir = await _directory();
    final file = File('${dir.path}/${_name(key)}.wav');
    await file.writeAsBytes(bytes, flush: true);
    final files = await dir
        .list()
        .where((e) => e is File && e.path.endsWith('.wav'))
        .cast<File>()
        .toList();
    final stats = <File, FileStat>{};
    for (final f in files) {
      stats[f] = await f.stat();
    }
    files.sort((a, b) => stats[a]!.modified.compareTo(stats[b]!.modified));
    var total = stats.values.fold<int>(0, (sum, s) => sum + s.size);
    for (final f in files) {
      if (total <= 20 * 1024 * 1024) break;
      total -= stats[f]!.size;
      await f.delete();
    }
  } catch (_) {/* A full disk must not prevent speech playback. */}
}

Future<void> clearAudio() async {
  final dir = await _directory();
  await for (final entry in dir.list()) {
    if (entry is File && entry.path.endsWith('.wav')) await entry.delete();
  }
}
