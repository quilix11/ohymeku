import 'package:dialect_duel/models/game_state.dart';

const fixturePng =
    'data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAAAIAAAACCAYAAABytg0kAAAAFElEQVR4nGNcleL2n4GBgYGJAQoAI8wCVx/wue4AAAAASUVORK5CYII=';
final fixturePortraits = {
  for (final emotion in NpcEmotion.values) emotion.name: fixturePng
};
Future<Map<String, String>> fakePortraits(Map<String, dynamic> _) async =>
    fixturePortraits;
