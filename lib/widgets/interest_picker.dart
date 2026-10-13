import 'package:flutter/material.dart';
import '../services/settings_service.dart';

const interestLabels = {
  'Travel': 'Подорожі',
  'Food': 'Їжа й кава',
  'IT': 'Технології',
  'Business': 'Робота',
  'Movies': 'Кіно',
  'Music': 'Музика',
  'Sport': 'Спорт',
  'Art': 'Мистецтво'
};

class InterestPicker extends StatefulWidget {
  final SettingsService settings;
  const InterestPicker({super.key, required this.settings});
  @override
  State<InterestPicker> createState() => _InterestPickerState();
}

class _InterestPickerState extends State<InterestPicker> {
  final _custom = TextEditingController();
  @override
  void dispose() {
    _custom.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => ListenableBuilder(
      listenable: widget.settings,
      builder: (context, _) =>
          Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            Wrap(
                spacing: 8,
                runSpacing: 4,
                children: {...interestLabels.keys, ...widget.settings.interests}
                    .map((id) => FilterChip(
                        label: Text(interestLabels[id] ?? id),
                        selected: widget.settings.interests.contains(id),
                        onSelected: (_) => widget.settings.toggleInterest(id)))
                    .toList()),
            const SizedBox(height: 8),
            TextField(
                // ExpansionTile stores a bool under its PageStorageKey. Give
                // the editable's scroll offset a separate storage identity.
                key: const PageStorageKey('custom_interest_input'),
                controller: _custom,
                maxLength: 40,
                decoration: InputDecoration(
                    labelText: 'Свій інтерес',
                    suffixIcon: IconButton(
                        tooltip: 'Додати інтерес',
                        icon: const Icon(Icons.add),
                        onPressed: () {
                          final value = _custom.text.trim();
                          if (value.isNotEmpty &&
                              !widget.settings.interests.contains(value)) {
                            widget.settings.toggleInterest(value);
                          }
                          _custom.clear();
                        })),
                onSubmitted: (v) {
                  if (v.trim().isNotEmpty &&
                      !widget.settings.interests.contains(v.trim())) {
                    widget.settings.toggleInterest(v.trim());
                  }
                  _custom.clear();
                }),
          ]));
}
