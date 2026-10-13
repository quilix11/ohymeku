import '../widgets/ohymeku_design.dart';
import 'package:flutter/material.dart';
import '../widgets/interest_picker.dart';
import '../services/learning_service.dart';
import '../services/ai_service.dart';
import '../models/scenario.dart';
import '../models/game_state.dart';
import '../widgets/scenario_portrait.dart';

class GenerationScreen extends StatefulWidget {
  final bool boss;
  final String level;
  final int count;
  final List<String> interests;
  final LearningService? service;
  final Future<void> Function(
          Map<String, dynamic> result, String topic, String level, bool warm)
      onSave;
  const GenerationScreen(
      {super.key,
      required this.boss,
      required this.onSave,
      this.level = 'A2',
      this.interests = const [],
      this.service,
      this.count = 8});
  @override
  State<GenerationScreen> createState() => _GenerationScreenState();
}

class _GenerationScreenState extends State<GenerationScreen> {
  final _topic = TextEditingController();
  late final _ai = widget.service ?? LearningService();
  late String _level = widget.level;
  late int _count = widget.count;
  bool _busy = false, _saving = false, _warm = true;
  String? _error, _generatedTopic, _generatedLevel;
  bool _generatedWarm = true;
  Map<String, dynamic>? _result;
  Future<void> _generate() async {
    if (_busy || _saving) return;
    final topic = _topic.text.trim();
    if (topic.isEmpty) {
      setState(() => _error = 'Впиши тему, наприклад «кав’ярня».');
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final result = await _ai.generate(topic, _level, _count, widget.boss,
          warm: widget.boss ? _warm : null);
      if (mounted) {
        setState(() {
          _result = result;
          _generatedTopic = topic;
          _generatedLevel = _level;
          _generatedWarm = _warm;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _error = e is AiException
            ? e.message
            : 'Не вдалося згенерувати. Повтори спробу.');
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _save() async {
    if (_result == null || _saving || _busy) return;
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      await widget.onSave(
          _result!, _generatedTopic!, _generatedLevel!, _generatedWarm);
      if (mounted) Navigator.pop(context, true);
    } catch (_) {
      if (mounted) {
        setState(() => _error = 'Не вдалося зберегти. Спробуй ще раз.');
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  void dispose() {
    _topic.dispose();
    _ai.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context), c = theme.colorScheme;
    final preview = widget.boss && _result != null
        ? Scenario.fromJson({
            ..._result!,
            'id': 'preview',
            'character': _generatedWarm ? 'hr' : 'officer',
            'level': _generatedLevel,
            'personality': _result!['description']
          })
        : null;
    return PopScope(
        canPop: !_saving,
        child: Scaffold(
          appBar: AppBar(
              title: Text(widget.boss ? 'Створити ситуацію' : 'Новий набір')),
          body: SilkBackground(
              child: SafeArea(
                  top: false,
                  child: Center(
                    child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 680),
                        child: ListView(
                            padding: const EdgeInsets.all(20),
                            children: [
                              ScreenIntro(
                                  title: widget.boss
                                      ? 'Твоя власна історія'
                                      : 'Вивчай те, що цікаво',
                                  subtitle: widget.boss
                                      ? 'Опиши співрозмовника й ситуацію розмови.'
                                      : 'Обери тему для персонального набору слів.',
                                  icon: Icons.auto_awesome_outlined),
                              const SectionTitle('01 · Тема'),
                              SilkPanel(
                                  child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.stretch,
                                      children: [
                                    TextField(
                                        controller: _topic,
                                        enabled: !_busy && !_saving,
                                        maxLength: 200,
                                        maxLines: 2,
                                        decoration: const InputDecoration(
                                            labelText: 'Тема або ситуація',
                                            hintText:
                                                'Наприклад: замовлення кави')),
                                    if (widget.interests.isNotEmpty)
                                      Wrap(
                                          spacing: 8,
                                          runSpacing: 8,
                                          children: widget.interests
                                              .map((v) => ActionChip(
                                                  label: Text(
                                                      interestLabels[v] ?? v),
                                                  onPressed: _busy || _saving
                                                      ? null
                                                      : () {
                                                          _topic.text =
                                                              interestLabels[
                                                                      v] ??
                                                                  v;
                                                        }))
                                              .toList()),
                                  ])),
                              const SectionTitle('02 · Складність'),
                              SilkPanel(
                                  child: Column(children: [
                                DropdownButtonFormField<String>(
                                    initialValue: _level,
                                    decoration: const InputDecoration(
                                        labelText: 'Рівень англійської'),
                                    items: ['A1', 'A2', 'B1', 'B2', 'C1']
                                        .map((v) => DropdownMenuItem(
                                            value: v, child: Text(v)))
                                        .toList(),
                                    onChanged: _busy || _saving
                                        ? null
                                        : (v) => setState(() => _level = v!)),
                                const SizedBox(height: 16),
                                if (widget.boss)
                                  SwitchListTile(
                                      contentPadding: EdgeInsets.zero,
                                      title: const Text('М’яка манера голосу'),
                                      subtitle: const Text(
                                          'Голосовий профіль Hannah. Вимкнено — профіль Vance. Нові портрети генеруються автоматично.'),
                                      value: _warm,
                                      onChanged: _busy || _saving
                                          ? null
                                          : (v) => setState(() => _warm = v))
                                else
                                  DropdownButtonFormField<int>(
                                      initialValue: _count,
                                      decoration: const InputDecoration(
                                          labelText: 'Кількість карток'),
                                      items: [5, 8, 12, 16]
                                          .map((v) => DropdownMenuItem(
                                              value: v,
                                              child: Text('$v карток')))
                                          .toList(),
                                      onChanged: _busy || _saving
                                          ? null
                                          : (v) => setState(() => _count = v!)),
                              ])),
                              const SizedBox(height: 20),
                              FilledButton.icon(
                                  onPressed:
                                      _busy || _saving ? null : _generate,
                                  icon: _busy
                                      ? SizedBox(
                                          width: 20,
                                          height: 20,
                                          child: CircularProgressIndicator(
                                              strokeWidth: 2,
                                              color: c.onPrimary))
                                      : const Icon(Icons.auto_awesome_outlined),
                                  label: Text(_busy
                                      ? widget.boss
                                          ? 'Генерую персонажа…'
                                          : 'Генерую…'
                                      : _result == null
                                          ? 'Створити'
                                          : 'Інший варіант')),
                              if (_error != null)
                                Padding(
                                    padding: const EdgeInsets.symmetric(
                                        vertical: 16),
                                    child: Text(_error!,
                                        style: TextStyle(color: c.error))),
                              if (_result != null) ...[
                                const SectionTitle(
                                    '03 · Перегляд і збереження'),
                                Text('$_generatedTopic · $_generatedLevel',
                                    style: theme.textTheme.labelLarge),
                                const SizedBox(height: 12),
                                if (widget.boss)
                                  SilkPanel(
                                      rose: true,
                                      child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(_result!['name'],
                                                style: theme
                                                    .textTheme.headlineMedium),
                                            const SizedBox(height: 8),
                                            Text(_result!['role']),
                                            const SizedBox(height: 16),
                                            Text(_result!['goal']),
                                            const SizedBox(height: 12),
                                            Text(_result!['description']),
                                            const SizedBox(height: 12),
                                            const Text(
                                                '9 портретів генеруватимуться у фоні після збереження. Можна одразу почати розмову.'),
                                            if (preview!
                                                .portraits.isNotEmpty) ...[
                                              const SizedBox(height: 16),
                                              const Text(
                                                  '9 емоцій · прозорі портрети'),
                                              const SizedBox(height: 8),
                                              Wrap(
                                                  spacing: 8,
                                                  runSpacing: 8,
                                                  children: [
                                                    for (final emotion
                                                        in NpcEmotion.values)
                                                      Tooltip(
                                                          message: emotionLabel(
                                                              emotion),
                                                          child:
                                                              ScenarioPortrait(
                                                                  scenario:
                                                                      preview,
                                                                  emotion:
                                                                      emotion,
                                                                  width: 76,
                                                                  height: 76,
                                                                  cacheWidth:
                                                                      160)),
                                                  ]),
                                            ],
                                            const Divider(),
                                            Text(_result!['opening'],
                                                style:
                                                    theme.textTheme.bodyLarge),
                                          ]))
                                else
                                  ...(_result!['cards'] as List)
                                      .asMap()
                                      .entries
                                      .map((entry) => Padding(
                                          padding:
                                              const EdgeInsets.only(bottom: 10),
                                          child: SilkPanel(
                                              padding: const EdgeInsets.all(16),
                                              child: Row(
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.start,
                                                  children: [
                                                    Text('${entry.key + 1}',
                                                        style: theme.textTheme
                                                            .titleLarge
                                                            ?.copyWith(
                                                                color:
                                                                    c.primary)),
                                                    const SizedBox(width: 16),
                                                    Expanded(
                                                        child: Column(
                                                            crossAxisAlignment:
                                                                CrossAxisAlignment
                                                                    .start,
                                                            children: [
                                                          Text(
                                                              entry.value[
                                                                  'word'],
                                                              style: theme
                                                                  .textTheme
                                                                  .titleMedium),
                                                          const SizedBox(
                                                              height: 4),
                                                          Text(entry.value[
                                                              'translation']),
                                                          const SizedBox(
                                                              height: 8),
                                                          Text(
                                                              entry.value[
                                                                  'example'],
                                                              style: theme
                                                                  .textTheme
                                                                  .bodySmall),
                                                        ])),
                                                  ])))),
                                const SizedBox(height: 20),
                                FilledButton.icon(
                                    onPressed: _busy || _saving ? null : _save,
                                    icon: const Icon(Icons.save_outlined),
                                    label: Text(_saving
                                        ? 'Зберігаю…'
                                        : widget.boss
                                            ? 'Додати співрозмовника'
                                            : 'Зберегти набір')),
                              ],
                            ])),
                  ))),
        ));
  }
}
