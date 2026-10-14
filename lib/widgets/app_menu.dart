import 'dart:math';
import 'package:flutter/material.dart';
import '../models/journey_level.dart';
import '../services/settings_service.dart';
import '../services/progress_service.dart';
import 'scenario_portrait.dart';

class AppMenu extends StatelessWidget {
  final SettingsService settings;
  final ProgressService progress;
  final void Function(String) navigate;
  final void Function(JourneyLevel) chat;
  final VoidCallback dictionary, meku, close;
  const AppMenu(
      {super.key,
      required this.settings,
      required this.progress,
      required this.navigate,
      required this.chat,
      required this.dictionary,
      required this.meku,
      required this.close});
  @override
  Widget build(BuildContext context) => Drawer(
      width: min(380, MediaQuery.sizeOf(context).width * .9),
      child: SafeArea(
          child: ListenableBuilder(
              listenable: Listenable.merge([settings, progress]),
              builder: (context, _) => Column(children: [
                    Padding(
                        padding: const EdgeInsets.fromLTRB(20, 12, 12, 12),
                        child: Row(children: [
                          Expanded(
                              child: Text('Твій простір',
                                  style:
                                      Theme.of(context).textTheme.titleLarge)),
                          IconButton(
                              tooltip: 'Закрити меню',
                              onPressed: close,
                              icon: const Icon(Icons.close_rounded))
                        ])),
                    const Divider(height: 1),
                    Expanded(
                        child: ListView(
                            padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                            children: [
                          _section(context, 'Пригода й розмови'),
                          _item(context, 'Карта пригоди', Icons.route_rounded,
                              () => navigate('journey')),
                          for (final boss in journeyLevels.where((l) => l.boss))
                            _item(
                                context,
                                boss.opponent!.name,
                                Icons.chat_bubble_outline_rounded,
                                () => chat(boss),
                                key: Key('menu_chat_${boss.id}'),
                                subtitle: boss.id == 'j12'
                                    ? 'Історії, уроки та клуб допитливих'
                                    : boss.id == 'j4'
                                        ? 'Подорожі та аеропорт'
                                        : 'Робота й команда',
                                portrait: ScenarioPortrait(
                                    scenario: boss.opponent!,
                                    width: 36,
                                    height: 44,
                                    cacheWidth: 100,
                                    excludeFromSemantics: true)),
                          _item(
                              context,
                              'Інші персонажі та ситуації',
                              Icons.people_outline_rounded,
                              () => navigate('conversations'),
                              key: const Key('open_conversations')),
                          _section(context, 'Навчання'),
                          _item(context, 'Слова', Icons.style_outlined,
                              () => navigate('words'),
                              key: const Key('menu_words')),
                          _item(context, 'Словник', Icons.search_rounded,
                              dictionary,
                              key: const Key('menu_dictionary')),
                          _item(context, 'Читання', Icons.auto_stories_rounded,
                              () => navigate('reading'),
                              key: const Key('menu_reading')),
                          _item(
                              context,
                              'Граматична практика',
                              Icons.edit_note_rounded,
                              () => navigate('practice'),
                              key: const Key('menu_practice')),
                          _item(context, 'Перевірити свій рівень',
                              Icons.quiz_outlined, () => navigate('placement'),
                              key: const Key('menu_placement')),
                          _section(context, 'Творча майстерня'),
                          _item(
                              context,
                              'Згенерувати слова',
                              Icons.auto_awesome_rounded,
                              () => navigate('generation'),
                              key: const Key('menu_generation')),
                          _item(
                              context,
                              'Створити персонажа',
                              Icons.person_add_alt_1_rounded,
                              () => navigate('character_generation'),
                              key: const Key('menu_character_generation')),
                          _section(context, 'Твої результати'),
                          _item(context, 'Прогрес', Icons.insights_outlined,
                              () => navigate('progress'),
                              key: const Key('menu_progress')),
                          _item(
                              context,
                              'Профіль',
                              Icons.person_outline_rounded,
                              () => navigate('profile'),
                              subtitle: progress.name,
                              key: const Key('menu_profile')),
                          _item(context, 'Поговорити з Meku',
                              Icons.pets_rounded, meku,
                              key: const Key('menu_meku')),
                        ])),
                  ]))));
  Widget _section(BuildContext context, String title) => Padding(
      padding: const EdgeInsets.fromLTRB(8, 20, 8, 12),
      child: Text(title, style: Theme.of(context).textTheme.titleSmall));
  Widget _item(BuildContext context, String title, IconData icon,
          VoidCallback action,
          {String? subtitle, Widget? portrait, Key? key}) =>
      Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Material(
              color: Theme.of(context).colorScheme.surfaceContainerLow,
              borderRadius: BorderRadius.circular(14),
              clipBehavior: Clip.antiAlias,
              child: ListTile(
                  key: key,
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  minVerticalPadding: 12,
                  horizontalTitleGap: 12,
                  leading: portrait ?? Icon(icon),
                  title: Text(title),
                  subtitle: subtitle == null
                      ? null
                      : Padding(
                          padding: const EdgeInsets.only(top: 6),
                          child: Text(subtitle)),
                  trailing: const Icon(Icons.chevron_right_rounded, size: 18),
                  onTap: () {
                    close();
                    action();
                  })));
}
