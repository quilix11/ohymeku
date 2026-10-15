/// Story data is validated identically for authored, generated and saved chapters.
class StoryScene {
  final String speaker, text, english, question, clue;
  final List<String> options, choices, consequences;
  final int answer;
  const StoryScene(
      {required this.speaker,
      required this.text,
      required this.english,
      required this.question,
      required this.options,
      required this.answer,
      required this.clue,
      required this.choices,
      required this.consequences});
  Map<String, dynamic> toJson() => {
        'speaker': speaker,
        'text': text,
        'english': english,
        'question': question,
        'options': options,
        'answer': answer,
        'clue': clue,
        'choices': choices,
        'consequences': consequences
      };
  factory StoryScene.fromJson(Map<String, dynamic> j) {
    String text(String key, int max) {
      final value = j[key];
      if (value is! String || value.trim().isEmpty || value.length > max) {
        throw const FormatException('Неповна сцена');
      }
      return value.trim();
    }

    List<String> list(String key, int length) {
      final value = j[key];
      if (value is! List ||
          value.length != length ||
          value
              .any((v) => v is! String || v.trim().isEmpty || v.length > 400)) {
        throw const FormatException('Неповні варіанти');
      }
      final result = List<String>.from(value);
      if (key != 'consequences' &&
          result.map((s) => s.trim().toLowerCase()).toSet().length != length) {
        throw const FormatException('Варіанти не повинні повторюватися');
      }
      return result;
    }

    final answer = j['answer'];
    if (answer is! int || answer < 0 || answer > 2) {
      throw const FormatException();
    }
    return StoryScene(
        speaker: text('speaker', 50),
        text: text('text', 1800),
        english: text('english', 600),
        question: text('question', 250),
        options: list('options', 3),
        answer: answer,
        clue: text('clue', 250),
        choices: list('choices', 2),
        consequences: list('consequences', 2));
  }
}

class StoryChapter {
  final String id, title, location, summary;
  final bool generated;
  final List<StoryScene> scenes;
  const StoryChapter(
      {required this.id,
      required this.title,
      required this.location,
      required this.summary,
      required this.scenes,
      this.generated = false});
  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'location': location,
        'summary': summary,
        'generated': generated,
        'scenes': scenes.map((s) => s.toJson()).toList()
      };
  factory StoryChapter.fromJson(Map<String, dynamic> j, {String? id}) {
    String field(String key, int max) {
      final v = j[key];
      if (v is! String || v.trim().isEmpty || v.length > max) {
        throw const FormatException();
      }
      return v.trim();
    }

    final scenes = j['scenes'];
    if (scenes is! List || scenes.length < 3 || scenes.length > 5) {
      throw const FormatException();
    }
    return StoryChapter(
        id: id ?? field('id', 100),
        title: field('title', 100),
        location: field('location', 100),
        summary: field('summary', 700),
        generated: id != null || j['generated'] == true,
        scenes: scenes
            .map(
                (s) => StoryScene.fromJson(Map<String, dynamic>.from(s as Map)))
            .toList());
  }
}
