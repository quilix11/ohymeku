import 'package:flutter/material.dart';
import '../models/journey_level.dart';
import '../models/journey_story.dart';
import '../services/settings_service.dart';
import '../services/progress_service.dart';
import '../widgets/scenario_portrait.dart';
import 'game_screen.dart';

Future<void> showJourneyChats(BuildContext context, JourneyLevel level,
        SettingsService settings, ProgressService progress) =>
    showModalBottomSheet<void>(
        context: context,
        isScrollControlled: true,
        useSafeArea: true,
        showDragHandle: true,
        builder: (sheetContext) => SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(children: [
                    ScenarioPortrait(
                        scenario: level.opponent!,
                        width: 64,
                        height: 78,
                        cacheWidth: 150),
                    const SizedBox(width: 16),
                    Expanded(
                        child: Text('${level.opponent!.name} · Розмови',
                            style: Theme.of(context).textTheme.titleLarge))
                  ]),
                  const SizedBox(height: 12),
                  const Text(
                      'Вибери ситуацію й говори своїми словами. Ці розмови доступні окремо від босового випробування.'),
                  const SizedBox(height: 12),
                  for (final scene in freeJourneyScenes(level))
                    ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: const Icon(Icons.chat_bubble_outline_rounded),
                        title: Text(scene.title),
                        subtitle: Text(scene.opening),
                        trailing: const Icon(Icons.chevron_right_rounded),
                        onTap: () {
                          Navigator.pop(sheetContext);
                          Navigator.push(
                              context,
                              MaterialPageRoute<void>(
                                  builder: (_) => GameScreen(
                                      settings: settings,
                                      progress: progress,
                                      character: scene.character,
                                      scenario: scene)));
                        }),
                  ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: Icon(settings.journey.bossReady(level)
                          ? Icons.flag_rounded
                          : Icons.lock_outline_rounded),
                      title: const Text('Босове випробування'),
                      subtitle: Text(settings.journey.completed(level)
                          ? 'Печатку вже здобуто'
                          : settings.journey.bossReady(level)
                              ? 'Повернись на рівень ${level.number}, щоб почати дуель'
                              : 'Пройди стежку до рівня ${level.number} та заверши квести')),
                ])));
