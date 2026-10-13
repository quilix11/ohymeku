import 'package:flutter/material.dart' hide Feedback;
import '../models/practice_record.dart';
import '../models/scenario.dart';
import '../services/progress_service.dart';
import '../widgets/ohymeku_design.dart';

class ProgressScreen extends StatelessWidget {
  final ProgressService progress;
  final VoidCallback onStart;
  const ProgressScreen(
      {super.key, required this.progress, required this.onStart});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context), c = theme.colorScheme;
    final today = ProgressService.day(DateTime.now());
    return ListView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
        children: [
          const ScreenIntro(
              title: 'Твій прогрес',
              subtitle: 'Кожна спроба має значення.',
              icon: Icons.insights_outlined),
          const SizedBox(height: 20),
          Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                  color: c.primary, borderRadius: BorderRadius.circular(16)),
              child: Row(children: [
                Expanded(
                    child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                      Text('ДОСВІД НАВЧАННЯ',
                          style: theme.textTheme.labelMedium
                              ?.copyWith(color: c.onPrimary, letterSpacing: 1)),
                      const SizedBox(height: 8),
                      Text('${progress.profile.xp} XP',
                          style: theme.textTheme.headlineLarge
                              ?.copyWith(color: c.onPrimary)),
                    ])),
                Icon(Icons.bolt_rounded, size: 40, color: c.onPrimary),
              ])),
          const SectionTitle('Твій ритм'),
          SilkPanel(
              rose: true,
              padding: const EdgeInsets.all(16),
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(children: [
                      Icon(Icons.local_fire_department_outlined,
                          color: c.secondary),
                      const SizedBox(width: 8),
                      Expanded(
                          child: Text(
                              '${progress.profile.streakDays} днів поспіль',
                              style: theme.textTheme.titleMedium))
                    ]),
                    const SizedBox(height: 20),
                    LayoutBuilder(
                        builder: (context, box) => Wrap(
                            spacing: 8,
                            runSpacing: 12,
                            children: List.generate(7, (index) {
                              final date =
                                  today.subtract(Duration(days: 6 - index));
                              final active =
                                  progress.practiceDays.contains(date);
                              return SizedBox(
                                  width: MediaQuery.textScalerOf(context)
                                              .scale(16) >
                                          26
                                      ? 80
                                      : (box.maxWidth - 48) / 7,
                                  child: Semantics(
                                      label:
                                          '${date.day}.${date.month}: ${active ? "Практикувався" : "Без практики"}',
                                      child: Column(children: [
                                        Container(
                                            height: 32,
                                            alignment: Alignment.center,
                                            decoration: BoxDecoration(
                                                color: active
                                                    ? c.primary
                                                    : c.surface,
                                                borderRadius:
                                                    BorderRadius.circular(8)),
                                            child: Icon(
                                                active
                                                    ? Icons.check_rounded
                                                    : Icons.remove_rounded,
                                                size: 18,
                                                color: active
                                                    ? c.onPrimary
                                                    : c.onSurfaceVariant)),
                                        const SizedBox(height: 8),
                                        Text('${date.day}',
                                            style: theme.textTheme.labelMedium),
                                      ])));
                            }))),
                    const SizedBox(height: 16),
                    Text('Останні 7 днів · відмічено дні практики',
                        style: theme.textTheme.bodySmall),
                  ])),
          const SectionTitle('Що вже зроблено'),
          LayoutBuilder(
              builder: (context, box) =>
                  Wrap(spacing: 12, runSpacing: 12, children: [
                    for (final stat in [
                      (
                        '${progress.records.length}',
                        'Розмов',
                        Icons.forum_outlined
                      ),
                      (
                        '${progress.studiedWords}',
                        'Повторень слів',
                        Icons.style_outlined
                      ),
                      (
                        '${progress.grammarAttempts}',
                        'Граматичних спроб',
                        Icons.edit_note_rounded
                      ),
                    ])
                      SizedBox(
                          width: MediaQuery.textScalerOf(context).scale(16) > 24
                              ? box.maxWidth
                              : (box.maxWidth - 12) / 2,
                          child: SilkPanel(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(children: [
                                      Icon(stat.$3, color: c.primary),
                                      const SizedBox(width: 12),
                                      Expanded(
                                          child: Text(stat.$1,
                                              style: theme
                                                  .textTheme.headlineMedium))
                                    ]),
                                    const SizedBox(height: 12),
                                    Text(stat.$2,
                                        style: theme.textTheme.bodyMedium),
                                  ]))),
                  ])),
          const SectionTitle('Історія розмов'),
          if (progress.records.isEmpty)
            SilkPanel(
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                  Text('Почни свою першу розмову',
                      style: theme.textTheme.titleLarge),
                  const SizedBox(height: 8),
                  const Text('Її результат і поради з’являться тут.'),
                  const SizedBox(height: 20),
                  FilledButton.icon(
                      onPressed: onStart,
                      icon: const Icon(Icons.play_arrow_rounded),
                      label: const Text('Обрати персонажа')),
                ]))
          else
            ...progress.records.map((record) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Material(
                    color: c.surface,
                    borderRadius: BorderRadius.circular(14),
                    clipBehavior: Clip.antiAlias,
                    child: ListTile(
                        contentPadding: const EdgeInsets.all(16),
                        leading: Icon(
                            record.won
                                ? Icons.emoji_events_outlined
                                : Icons.chat_outlined,
                            color: c.primary),
                        title: Text(record.scenarioName ??
                            Scenario.of(record.character).name),
                        subtitle: Text(
                            '${record.date.day}.${record.date.month} · ${record.resultLabel} · ${record.turns} реплік'),
                        trailing: const Icon(Icons.chevron_right_rounded),
                        onTap: () => showPracticeRecord(context, record))))),
        ]);
  }
}

void showPracticeRecord(BuildContext context, PracticeRecord record) {
  showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (context) => SafeArea(
          child: SizedBox(
              height: MediaQuery.sizeOf(context).height * 0.8,
              child: ListView(
                  padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                  children: [
                    Text(
                        (record.scenarioName ??
                            Scenario.of(record.character).name),
                        style: Theme.of(context).textTheme.headlineMedium),
                    const SizedBox(height: 8),
                    Text(
                        '${record.resultLabel} · +${record.xp} XP\nДовіра ${record.trust}/100 · Терпіння ${record.patience}/100'),
                    const SizedBox(height: 24),
                    Text('Розмова й поради',
                        style: Theme.of(context).textTheme.titleLarge),
                    const SizedBox(height: 12),
                    ...record.messages.asMap().entries.map((entry) {
                      final message = entry.value;
                      final feedbackIndex = (entry.key - 2) ~/ 2;
                      final feedback = !message.isPlayer &&
                              entry.key >= 2 &&
                              feedbackIndex < record.feedback.length
                          ? record.feedback[feedbackIndex]
                          : null;
                      return Padding(
                          padding: const EdgeInsets.only(bottom: 16),
                          child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                    message.isPlayer
                                        ? 'Ти'
                                        : (record.scenarioName ??
                                            Scenario.of(record.character).name),
                                    style:
                                        Theme.of(context).textTheme.labelLarge),
                                const SizedBox(height: 4),
                                SelectableText(message.text),
                                if (feedback != null &&
                                    (feedback.grammarCorrection.isNotEmpty ||
                                        feedback.tacticalAdvice.isNotEmpty))
                                  Padding(
                                      padding: const EdgeInsets.only(top: 8),
                                      child: Text(
                                          [
                                            feedback.grammarCorrection,
                                            feedback.tacticalAdvice
                                          ]
                                              .where((s) => s.isNotEmpty)
                                              .join('\n'),
                                          style: TextStyle(
                                              color: Theme.of(context)
                                                  .colorScheme
                                                  .primary))),
                              ]));
                    }),
                  ]))));
}
