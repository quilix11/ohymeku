class LanguageHelp {
  final bool isEnglish;
  final String explanation;
  final List<({String english, String translation})> suggestions;
  const LanguageHelp(this.isEnglish, this.explanation, this.suggestions);

  factory LanguageHelp.fromJson(Map<String, dynamic> json,
      {bool requireSuggestions = false}) {
    if (json['is_english'] is! bool) {
      throw const FormatException('Missing language classification');
    }
    final suggestions = <({String english, String translation})>[];
    for (final item in json['suggestions'] is List ? json['suggestions'] : []) {
      if (item is Map &&
          item['english'] is String &&
          item['translation'] is String &&
          (item['english'] as String).trim().isNotEmpty &&
          (item['translation'] as String).trim().isNotEmpty) {
        suggestions
            .add((english: item['english'], translation: item['translation']));
      }
    }
    if ((requireSuggestions || json['is_english'] == false) &&
        suggestions.isEmpty) {
      throw const FormatException('Missing tutor suggestions');
    }
    return LanguageHelp(
        json['is_english'],
        json['explanation'] is String ? json['explanation'] : '',
        suggestions.take(3).toList());
  }
}
