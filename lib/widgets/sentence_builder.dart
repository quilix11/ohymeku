import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// Token IDs keep repeated words independent while moving between both areas.
class SentenceBuilder extends StatelessWidget {
  final List<String> words;
  final List<int> bankOrder;
  final List<int> chosen;
  final bool enabled;
  final ValueChanged<List<int>> onChanged;

  const SentenceBuilder({
    super.key,
    required this.words,
    required this.bankOrder,
    required this.chosen,
    required this.onChanged,
    this.enabled = true,
  });

  void _insert(int token, int position) {
    final next = List<int>.of(chosen);
    final previous = next.indexOf(token);
    if (previous >= 0) {
      next.removeAt(previous);
      if (previous < position) position--;
    }
    next.insert(position, token);
    onChanged(next);
  }

  Widget _word(BuildContext context, int token, {required bool selected}) {
    final chip = selected
        ? InputChip(
            key: ValueKey('sentence_word_$token'),
            label: Text(words[token]),
            onPressed: enabled
                ? () => onChanged(List<int>.of(chosen)..remove(token))
                : null)
        : ActionChip(
            key: ValueKey('bank_word_$token'),
            label: Text(words[token]),
            onPressed: enabled ? () => _insert(token, chosen.length) : null);
    return LongPressDraggable<int>(
      data: token,
      dragAnchorStrategy: pointerDragAnchorStrategy,
      maxSimultaneousDrags: enabled ? 1 : 0,
      feedback: Transform.translate(
          offset: const Offset(-16, -56),
          child: Material(
              color: Colors.transparent,
              child: Chip(
                  elevation: 4,
                  backgroundColor: Theme.of(context)
                      .colorScheme
                      .primaryContainer
                      .withValues(alpha: .94),
                  label: Text(words[token])))),
      childWhenDragging: Opacity(opacity: .3, child: chip),
      child: chip,
    );
  }

  Widget _area(BuildContext context,
      {required String keyName,
      required bool sentence,
      required Widget child}) {
    final colors = Theme.of(context).colorScheme;
    return Semantics(
      container: true,
      label: sentence ? 'Речення' : 'Слова для речення',
      child: DragTarget<int>(
        key: ValueKey(keyName),
        onWillAcceptWithDetails: (details) =>
            enabled && (sentence || chosen.contains(details.data)),
        onAcceptWithDetails: (details) => sentence
            ? _insert(details.data, chosen.length)
            : onChanged(List<int>.of(chosen)..remove(details.data)),
        builder: (context, candidates, rejected) => Container(
            width: double.infinity,
            constraints: const BoxConstraints(minHeight: 72),
            padding: const EdgeInsets.all(12),
            decoration: AppVisuals.panelDecoration(context,
                    radius: AppVisuals.radiusControl)
                .copyWith(
                    gradient: candidates.isEmpty
                        ? AppVisuals.panelDecoration(context).gradient
                        : LinearGradient(colors: [
                            colors.primaryContainer.withValues(alpha: .96),
                            colors.primaryContainer.withValues(alpha: .9),
                          ]),
                    border: Border.all(
                        color: candidates.isEmpty
                            ? AppVisuals.panelBorder(context)
                            : colors.primary.withValues(alpha: .75),
                        width: 2)),
            child: child),
      ),
    );
  }

  @override
  Widget build(BuildContext context) =>
      Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        _area(context,
            keyName: 'sentence_drop_area',
            sentence: true,
            child: Wrap(spacing: 8, runSpacing: 8, children: [
              if (chosen.isEmpty)
                const Padding(
                    padding: EdgeInsets.symmetric(vertical: 10),
                    child: Text('Перетягни слова сюди або натисни на них')),
              for (var position = 0; position < chosen.length; position++)
                Builder(
                    builder: (targetContext) => DragTarget<int>(
                          onWillAcceptWithDetails: (details) => enabled,
                          onAcceptWithDetails: (details) {
                            final box =
                                targetContext.findRenderObject() as RenderBox;
                            final after =
                                box.globalToLocal(details.offset).dx >=
                                    box.size.width / 2;
                            _insert(details.data, position + (after ? 1 : 0));
                          },
                          builder: (context, candidates, rejected) =>
                              DecoratedBox(
                                  decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(
                                          AppVisuals.radiusControl),
                                      border: Border.all(
                                          color: candidates.isEmpty
                                              ? Colors.transparent
                                              : Theme.of(context)
                                                  .colorScheme
                                                  .primary,
                                          width: 2)),
                                  child: _word(context, chosen[position],
                                      selected: true)),
                        )),
            ])),
        const SizedBox(height: 16),
        _area(context,
            keyName: 'word_bank_drop_area',
            sentence: false,
            child: Wrap(spacing: 8, runSpacing: 8, children: [
              for (final token in bankOrder)
                if (!chosen.contains(token))
                  _word(context, token, selected: false),
              if (chosen.length == words.length)
                const Padding(
                    padding: EdgeInsets.symmetric(vertical: 10),
                    child: Text('Поверни слово сюди, щоб прибрати з речення')),
            ])),
      ]);
}
