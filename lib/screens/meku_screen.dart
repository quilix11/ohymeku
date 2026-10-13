import 'package:flutter/material.dart';
import '../services/meku_service.dart';
import '../widgets/meku_avatar.dart';
import '../models/meku_emotion.dart';
import '../models/meku_route.dart';

class MekuScreen extends StatefulWidget {
  final MekuService meku;
  final VoidCallback? onClose;
  final void Function(String) navigate;
  final MekuRouteHandler? route;
  const MekuScreen(
      {super.key,
      required this.meku,
      required this.navigate,
      this.onClose,
      this.route});
  @override
  State<MekuScreen> createState() => _MekuScreenState();
}

class _MekuScreenState extends State<MekuScreen> {
  final _input = TextEditingController();
  final _scroll = ScrollController();
  Future<void> _send([String? suggestion]) async {
    final text = suggestion ?? _input.text;
    if (text.trim().isEmpty || widget.meku.busy) return;
    await widget.meku
        .send(text, navigate: widget.navigate, route: widget.route);
    if (!mounted) return;
    if (widget.meku.error == null &&
        suggestion == null &&
        _input.text == text) {
      _input.clear();
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && _scroll.hasClients) {
        _scroll.jumpTo(_scroll.position.maxScrollExtent);
      }
    });
  }

  Widget _messageField(bool compact) => TextField(
      controller: _input,
      minLines: 1,
      maxLines: compact ? 2 : 3,
      maxLength: 2000,
      decoration: const InputDecoration(
          hintText: 'Твоє запитання…',
          labelText: 'Повідомлення Meku',
          counterText: ''),
      textInputAction: TextInputAction.send,
      onSubmitted: (_) => _send());

  Widget _sendButton(bool compact) => ValueListenableBuilder<TextEditingValue>(
      valueListenable: _input,
      builder: (context, input, _) {
        final send = widget.meku.busy || input.text.trim().isEmpty
            ? null
            : () => _send();
        return Tooltip(
            message: 'Надіслати Meku',
            child: compact
                ? IconButton.filled(
                    onPressed: send, icon: const Icon(Icons.send_rounded))
                : FilledButton.icon(
                    onPressed: send,
                    icon: const Icon(Icons.send_rounded),
                    label: const Text('Надіслати')));
      });

  @override
  void dispose() {
    _input.dispose();
    _scroll.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => ListenableBuilder(
      listenable: Listenable.merge(
          [widget.meku, widget.meku.settings, widget.meku.settings.learner]),
      builder: (context, _) {
        final theme = Theme.of(context),
            c = theme.colorScheme,
            meku = widget.meku;
        final keyboard = MediaQuery.viewInsetsOf(context).bottom > 0;
        return Column(children: [
          Padding(
              padding: EdgeInsets.symmetric(
                  horizontal: 16, vertical: keyboard ? 8 : 16),
              child: Row(children: [
                MekuAvatar(size: keyboard ? 40 : 56, emotion: meku.emotion),
                const SizedBox(width: 12),
                Expanded(
                    child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                      Text('Meku',
                          style: keyboard
                              ? theme.textTheme.titleMedium
                              : theme.textTheme.titleLarge),
                      if (!keyboard)
                        Text(
                            '${meku.emotion.label} · ${meku.settings.effectiveLevel}',
                            style: theme.textTheme.bodySmall),
                    ])),
                if (widget.onClose != null)
                  IconButton(
                      tooltip: 'Закрити Meku',
                      onPressed: widget.onClose,
                      icon: const Icon(Icons.close_rounded)),
              ])),
          const Divider(height: 1),
          Expanded(
              child: ListView(
                  controller: _scroll,
                  padding: const EdgeInsets.all(20),
                  children: [
                if (meku.messages.isEmpty) ...[
                  Text('Ну що, здивуєш мене?',
                      style: theme.textTheme.headlineMedium),
                  const SizedBox(height: 8),
                  const Text(
                      'Я Meku. Гострий розум, м’які лапки. Розберемо англійську разом — тільки не звикай, що я така добра.'),
                  const SizedBox(height: 20),
                  for (final action in [
                    (
                      'Створити картки',
                      Icons.style_outlined,
                      'Створи 8 карток про каву.'
                    ),
                    (
                      'Новий персонаж',
                      Icons.person_add_outlined,
                      'Створи персонажа баристу для розмови в кав’ярні.'
                    ),
                    (
                      'Знайти статтю',
                      Icons.menu_book_outlined,
                      'Знайди статті про музику для читання.'
                    ),
                    (
                      'Пояснити правило',
                      Icons.school_outlined,
                      'Поясни граматичну тему для мого рівня з прикладом.'
                    ),
                    (
                      'Переглянути прогрес',
                      Icons.insights_outlined,
                      'Розкажи про мій прогрес і порадь наступний крок.'
                    ),
                    (
                      'Підняти рівень',
                      Icons.trending_up_rounded,
                      'Я краще розумію англійську. Підніми мій рівень на один ступінь.'
                    ),
                  ])
                    Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: OutlinedButton.icon(
                            onPressed:
                                meku.busy ? null : () => _send(action.$3),
                            icon: Icon(action.$2),
                            label: Text(action.$1))),
                ],
                for (final message in meku.messages)
                  Align(
                      alignment: message['role'] == 'user'
                          ? Alignment.centerRight
                          : Alignment.centerLeft,
                      child: Container(
                          margin: EdgeInsets.fromLTRB(
                              message['role'] == 'user' ? 24 : 0,
                              0,
                              message['role'] == 'user' ? 0 : 24,
                              14),
                          padding: const EdgeInsets.all(16),
                          constraints: const BoxConstraints(maxWidth: 480),
                          decoration: BoxDecoration(
                              color: message['role'] == 'user'
                                  ? c.primary
                                  : message['role'] == 'result'
                                      ? (message['status'] == 'error'
                                          ? c.errorContainer
                                          : c.primaryContainer)
                                      : c.surface,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: c.outlineVariant)),
                          child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                if (message['role'] == 'assistant')
                                  Row(children: [
                                    MekuAvatar(
                                        size: 40,
                                        emotion: MekuEmotion.parse(
                                            message['emotion'])),
                                    const SizedBox(width: 8),
                                    Expanded(
                                        child: Text(
                                            'Meku · ${MekuEmotion.parse(message['emotion']).label}',
                                            style: theme.textTheme.labelLarge
                                                ?.copyWith(color: c.primary))),
                                  ])
                                else
                                  Text(
                                      message['role'] == 'user'
                                          ? 'Ти'
                                          : message['role'] == 'result'
                                              ? (message['status'] == 'error'
                                                  ? 'Дію не виконано'
                                                  : 'Результат дії')
                                              : 'Meku',
                                      style: theme.textTheme.labelLarge
                                          ?.copyWith(
                                              color: message['role'] == 'user'
                                                  ? c.onPrimary
                                                  : c.primary)),
                                const SizedBox(height: 8),
                                SelectableText(message['text']!,
                                    style: theme.textTheme.bodyLarge?.copyWith(
                                        color: message['role'] == 'user'
                                            ? c.onPrimary
                                            : c.onSurface)),
                              ]))),
                if (meku.busy)
                  const Padding(
                      padding: EdgeInsets.all(12),
                      child: Row(children: [
                        SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2)),
                        SizedBox(width: 12),
                        Expanded(child: Text('Meku думає…')),
                      ])),
                if (meku.error != null)
                  Semantics(
                      liveRegion: true,
                      child:
                          Text(meku.error!, style: TextStyle(color: c.error))),
                const SizedBox(height: 20),
                Text(
                    'ШІ може помилятися. Повідомлення й навчальний контекст надсилаються Gemini.',
                    style: theme.textTheme.bodySmall),
              ])),
          Material(
              color: c.surface,
              child: SafeArea(
                top: false,
                child: Padding(
                    padding: EdgeInsets.symmetric(
                        horizontal: 16, vertical: keyboard ? 8 : 16),
                    child: keyboard
                        ? Row(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                                Expanded(child: _messageField(true)),
                                const SizedBox(width: 8),
                                _sendButton(true),
                              ])
                        : Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                                _messageField(false),
                                const SizedBox(height: 10),
                                _sendButton(false),
                              ])),
              )),
        ]);
      });
}
