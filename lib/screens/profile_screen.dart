import 'package:flutter/material.dart';
import '../services/settings_service.dart';
import '../services/progress_service.dart';
import '../widgets/app_components.dart';
import 'settings_screen.dart';
import 'placement_screen.dart';
import 'practice_screen.dart';
import '../widgets/ohymeku_design.dart';

class ProfileScreen extends StatelessWidget {
  final ProgressService progress;
  final SettingsService settings;
  const ProfileScreen(
      {super.key, required this.progress, required this.settings});
  @override
  Widget build(BuildContext context) => ListenableBuilder(
      listenable: Listenable.merge([settings, settings.learner, progress]),
      builder: (context, _) => _content(context));
  Widget _content(BuildContext context) {
    final theme = Theme.of(context);
    final achievements = [
      (
        'Перша розмова',
        'Заверши одну розмову',
        progress.achievements.containsKey('first_chat'),
        Icons.chat_bubble_outline_rounded
      ),
      (
        'Переконливий аргумент',
        'Здобудь першу перемогу',
        progress.achievements.containsKey('first_win'),
        Icons.emoji_events_outlined
      ),
      (
        'Звичка говорити',
        'Практикуйся 3 дні поспіль',
        progress.achievements.containsKey('streak3'),
        Icons.local_fire_department_outlined
      ),
      (
        'Є що сказати',
        'Надішли 25 реплік у збережених розмовах',
        progress.achievements.containsKey('turns25'),
        Icons.record_voice_over_outlined
      ),
      (
        'Слова щодня',
        '10 зарахованих повторень слів',
        progress.achievements.containsKey('words10'),
        Icons.style_outlined
      ),
      (
        'Відчуваю граматику',
        '10 зарахованих граматичних завдань',
        progress.achievements.containsKey('grammar10'),
        Icons.school_outlined
      ),
    ];
    final c = theme.colorScheme;
    void open(Widget screen) => Navigator.push(
        context, MaterialPageRoute<void>(builder: (_) => screen));

    return ListView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
        children: [
          SilkPanel(
              rose: true,
              padding: const EdgeInsets.all(16),
              child: Row(children: [
                Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                        color: c.surface,
                        borderRadius: BorderRadius.circular(12)),
                    child: Icon(profileIcons[progress.avatar],
                        size: 28, color: c.primary)),
                const SizedBox(width: 14),
                Expanded(
                    child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                      Text(progress.name, style: theme.textTheme.titleLarge),
                      const SizedBox(height: 4),
                      Text(
                          'З нами з ${progress.joined.day}.${progress.joined.month}.${progress.joined.year}',
                          style: theme.textTheme.bodySmall),
                    ])),
                const SizedBox(width: 8),
                IconButton(
                    tooltip: 'Редагувати профіль',
                    onPressed: () => showDialog<void>(
                        context: context,
                        builder: (_) => _EditProfile(progress: progress)),
                    icon: const Icon(Icons.edit_outlined)),
              ])),
          const SectionTitle('Навчальний профіль'),
          SilkPanel(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                Row(children: [
                  Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                          color: c.primaryContainer,
                          borderRadius: BorderRadius.circular(12)),
                      child: Text(settings.effectiveLevel,
                          style: theme.textTheme.titleLarge
                              ?.copyWith(color: c.primary))),
                  const SizedBox(width: 16),
                  Expanded(
                      child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                        Text('Поточна складність',
                            style: theme.textTheme.titleMedium),
                        const SizedBox(height: 4),
                        Text('Вправи й розмови під тебе',
                            style: theme.textTheme.bodySmall),
                      ])),
                ]),
                const SizedBox(height: 20),
                if (settings.interests.isNotEmpty)
                  Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: settings.interests
                          .map((interest) => Chip(label: Text(interest)))
                          .toList()),
                const SizedBox(height: 8),
                TextButton.icon(
                    onPressed: () => open(SettingsScreen(settings: settings)),
                    icon: const Icon(Icons.add_rounded),
                    label: Text(settings.interests.isEmpty
                        ? 'Додати інтереси'
                        : 'Змінити інтереси')),
              ])),
          const SectionTitle('Швидкий доступ'),
          LearningTile(
              title: 'Граматика в контексті',
              subtitle:
                  '${settings.learner.due(settings.effectiveLevel, settings.interests).length} завдань до повторення',
              icon: Icons.edit_note_rounded,
              onTap: () =>
                  open(PracticeScreen(settings: settings, progress: progress))),
          const SizedBox(height: 10),
          LearningTile(
              title: 'Перевірити свій рівень',
              subtitle: settings.learner.placement == null
                  ? 'Короткий вступний тест'
                  : 'Останній результат: ${settings.learner.placement?["level"]}',
              icon: Icons.quiz_outlined,
              onTap: () => open(PlacementScreen(
                  settings: settings, progress: progress, retake: true))),
          const SizedBox(height: 10),
          SectionTitle('Досягнення',
              trailing: Text(
                  '${achievements.where((item) => item.$3).length} / ${achievements.length}',
                  style: theme.textTheme.labelLarge)),
          for (final item in achievements)
            Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: SilkPanel(
                    padding: const EdgeInsets.all(16),
                    rose: item.$3,
                    child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(item.$3 ? item.$4 : Icons.lock_outline_rounded,
                              color: item.$3 ? c.primary : c.onSurfaceVariant),
                          const SizedBox(width: 16),
                          Expanded(
                              child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                Text(item.$1,
                                    style: theme.textTheme.titleMedium),
                                const SizedBox(height: 4),
                                Text(item.$2, style: theme.textTheme.bodySmall),
                              ])),
                          if (item.$3) ...[
                            const SizedBox(width: 8),
                            Icon(Icons.check_rounded, color: c.primary)
                          ],
                        ]))),
          const SizedBox(height: 16),
          Text('Твій прогрес зберігається на цьому пристрої.',
              style: theme.textTheme.bodySmall, textAlign: TextAlign.center),
        ]);
  }
}

class _EditProfile extends StatefulWidget {
  final ProgressService progress;
  const _EditProfile({required this.progress});
  @override
  State<_EditProfile> createState() => _EditProfileState();
}

class _EditProfileState extends State<_EditProfile> {
  late final TextEditingController _name;
  late int _avatar;
  bool _saving = false;
  String? _error;
  @override
  void initState() {
    super.initState();
    _name = TextEditingController(text: widget.progress.editableName);
    _avatar = widget.progress.avatar;
  }

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_name.text.trim().isEmpty) {
      setState(() => _error = 'Введи своє ім’я');
      return;
    }
    setState(() => _saving = true);
    try {
      await widget.progress.saveProfile(_name.text, _avatar);
      if (mounted) Navigator.pop(context);
    } catch (_) {
      if (mounted) {
        setState(() {
          _saving = false;
          _error = 'Не вдалося зберегти. Спробуй ще раз.';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
        title: const Text('Твій профіль'),
        content: SingleChildScrollView(
            child: Column(mainAxisSize: MainAxisSize.min, children: [
          TextField(
              key: const Key('profile_name'),
              controller: _name,
              maxLength: 24,
              decoration: InputDecoration(
                  labelText: 'Як тебе звати?', errorText: _error)),
          const SizedBox(height: 16),
          Wrap(
              spacing: 8,
              runSpacing: 8,
              children: List.generate(
                  profileIcons.length,
                  (i) => IconButton.filledTonal(
                      isSelected: _avatar == i,
                      tooltip: 'Аватар ${i + 1}',
                      onPressed: () => setState(() => _avatar = i),
                      icon: Icon(profileIcons[i])))),
        ])),
        actions: [
          TextButton(
              onPressed: _saving ? null : () => Navigator.pop(context),
              child: const Text('Скасувати')),
          FilledButton(
              onPressed: _saving ? null : _save,
              child: Text(_saving ? 'Збереження…' : 'Зберегти')),
        ],
      );
}
