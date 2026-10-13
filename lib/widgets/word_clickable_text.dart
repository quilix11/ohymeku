import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

class WordClickableText extends StatefulWidget {
  final String text;
  final TextStyle? style;
  final ValueChanged<String>? onWordTap;

  const WordClickableText(
      {super.key, required this.text, this.style, this.onWordTap});

  @override
  State<WordClickableText> createState() => _WordClickableTextState();
}

class _WordClickableTextState extends State<WordClickableText> {
  late List<_WordItem> _words;
  final Map<_WordItem, TapGestureRecognizer> _recognizers = {};
  void _clear() {
    for (final r in _recognizers.values) {
      r.dispose();
    }
    _recognizers.clear();
  }

  @override
  void dispose() {
    _clear();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _parseText();
  }

  @override
  void didUpdateWidget(WordClickableText oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.text != widget.text) {
      _parseText();
    }
  }

  void _parseText() {
    _clear();
    final regex = RegExp(r"(\b[\w']+\b)(.*?)");
    final matches = regex.allMatches(widget.text);
    _words = [];
    int lastEnd = 0;

    for (final match in matches) {
      if (match.start > lastEnd) {
        _words
            .add(_WordItem(widget.text.substring(lastEnd, match.start), false));
      }
      final word = match.group(1)!;
      final trailing = match.group(2) ?? '';
      _words.add(_WordItem(word, true));
      if (trailing.isNotEmpty) {
        _words.add(_WordItem(trailing, false));
      }
      lastEnd = match.end;
    }
    if (lastEnd < widget.text.length) {
      _words.add(_WordItem(widget.text.substring(lastEnd), false));
    }
  }

  @override
  Widget build(BuildContext context) {
    return SelectableText.rich(
      TextSpan(
        children: _words.map((item) {
          if (!item.isWord || widget.onWordTap == null) {
            return TextSpan(text: item.text, style: widget.style);
          }
          return TextSpan(
            text: item.text,
            style: widget.style?.copyWith(
              decoration: TextDecoration.underline,
              decorationStyle: TextDecorationStyle.dotted,
            ),
            recognizer: _recognizers.putIfAbsent(
                item,
                () => TapGestureRecognizer()
                  ..onTap = () => widget.onWordTap?.call(item.text)),
          );
        }).toList(),
      ),
    );
  }
}

class _WordItem {
  final String text;
  final bool isWord;
  _WordItem(this.text, this.isWord);
}
