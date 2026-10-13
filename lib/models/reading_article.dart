import 'dart:convert';
import 'package:crypto/crypto.dart';

class ReadingQuestion {
  final String question, explanation, evidence;
  final List<String> options;
  final int answer;
  const ReadingQuestion(this.question, this.options, this.answer,
      this.explanation, this.evidence);
  Map<String, dynamic> toJson() => {
        'question': question,
        'options': options,
        'answer': answer,
        'explanation': explanation,
        'evidence': evidence
      };
  factory ReadingQuestion.fromJson(Map<String, dynamic> data) {
    final choices = data['options'];
    for (final field in ['question', 'explanation', 'evidence']) {
      if (data[field] is! String ||
          (data[field] as String).trim().isEmpty ||
          (data[field] as String).length > 1000) {
        throw const FormatException('Invalid reading question');
      }
    }
    if (choices is! List ||
        choices.length != 4 ||
        choices
            .any((v) => v is! String || v.trim().isEmpty || v.length > 400) ||
        choices.toSet().length != 4 ||
        data['answer'] is! int ||
        data['answer'] < 0 ||
        data['answer'] > 3) {
      throw const FormatException('Invalid reading answers');
    }
    return ReadingQuestion(data['question'], choices.cast<String>(),
        data['answer'], data['explanation'], data['evidence']);
  }
}

class ReadingArticle {
  final String id, title, text, topic, level, source, url, license;
  final List<ReadingQuestion> authoredQuestions;
  const ReadingArticle(
      {required this.id,
      required this.title,
      required this.text,
      required this.topic,
      this.level = 'Оригінал',
      this.source = 'Навчальний текст',
      this.url = '',
      this.license = '',
      this.authoredQuestions = const []});
  String get fingerprint => sha256.convert(utf8.encode(text)).toString();
  int get words =>
      RegExp(r"\b[A-Za-z]+(?:['’-][A-Za-z]+)*\b").allMatches(text).length;
  int get minutes => (words / 110).ceil().clamp(1, 30);
  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'text': text,
        'topic': topic,
        'level': level,
        'source': source,
        'url': url,
        'license': license,
      };
  factory ReadingArticle.fromJson(Map<String, dynamic> data) {
    for (final field in [
      'id',
      'title',
      'text',
      'topic',
      'level',
      'source',
      'url',
      'license'
    ]) {
      if (data[field] is! String) {
        throw const FormatException('Invalid article');
      }
    }
    if ((data['text'] as String).length < 80 ||
        (data['text'] as String).length > 16000 ||
        (data['title'] as String).isEmpty ||
        (data['title'] as String).length > 250 ||
        (data['id'] as String).length > 160) {
      throw const FormatException('Invalid article bounds');
    }
    final uri = Uri.tryParse(data['url']);
    if ((data['url'] as String).isNotEmpty &&
        (uri == null ||
            uri.scheme != 'https' ||
            uri.userInfo.isNotEmpty ||
            !['simple.wikipedia.org', 'en.wikipedia.org'].contains(uri.host))) {
      throw const FormatException('Invalid article source');
    }
    return ReadingArticle(
        id: data['id'],
        title: data['title'],
        text: data['text'],
        topic: data['topic'],
        level: data['level'],
        source: data['source'],
        url: data['url'],
        license: data['license']);
  }
}

class ReadingQuiz {
  final String articleId, fingerprint, kind;
  final List<ReadingQuestion> questions;
  const ReadingQuiz(
      this.articleId, this.fingerprint, this.questions, this.kind);
  Map<String, dynamic> toJson() => {
        'article_id': articleId,
        'fingerprint': fingerprint,
        'kind': kind,
        'questions': questions.map((q) => q.toJson()).toList()
      };
  factory ReadingQuiz.fromJson(Map<String, dynamic> data) => ReadingQuiz(
      data['article_id'] as String,
      data['fingerprint'] as String,
      (data['questions'] as List)
          .map((q) => ReadingQuestion.fromJson(Map<String, dynamic>.from(q)))
          .toList(),
      data['kind'] as String);
}

const starterReadings = [
  ReadingArticle(
      id: 'starter:cafe',
      title: 'More than a cup of coffee',
      topic: 'Food',
      level: 'A2',
      text:
          '''When Mia opened her small cafe, she wanted to sell good coffee. During the first month, most customers bought a drink and left. Then she put a large table near the window. She also added books and a board where people could leave messages.

Soon, customers started staying longer. A student helped an older neighbour with his phone. Two musicians made plans for a concert. Every Friday, people could practise English at the large table. Nobody needed to buy an expensive drink to join.

Mia still served coffee, but the cafe had become a meeting place. She learned that a useful space is not only about what it sells. Sometimes, it is about the people who feel welcome there.''',
      authoredQuestions: [
        ReadingQuestion(
            'What did Mia first want to do?',
            [
              'Sell good coffee',
              'Teach music',
              'Repair phones',
              'Open a library'
            ],
            0,
            'Спочатку Mia хотіла продавати хорошу каву.',
            'she wanted to sell good coffee'),
        ReadingQuestion(
            'When could people practise English?',
            ['Every Monday', 'Every Friday', 'Only in summer', 'Every morning'],
            1,
            'Розмовна практика відбувалася щоп’ятниці.',
            'Every Friday, people could practise English'),
        ReadingQuestion(
            'What is the main idea of the story?',
            [
              'A cafe must sell expensive drinks',
              'Books are better than coffee',
              'A welcoming place can bring people together',
              'Customers never stay in cafes'
            ],
            2,
            'Кав’ярня стала місцем зустрічей і спільноти.',
            'the cafe had become a meeting place'),
      ]),
  ReadingArticle(
      id: 'starter:travel',
      title: 'A slower weekend in a new city',
      topic: 'Travel',
      level: 'A2',
      text:
          '''Leo planned a weekend in a city he had never visited. His first list had twelve museums, three markets and two long tours. His friend asked a simple question: would he have time to enjoy any of them?

Leo changed his plan. He chose one museum for Saturday morning and left the afternoon free. At a market, he asked a seller about a local dish. The seller showed him a small park nearby. Leo sat there, ate his lunch and watched people walk their dogs.

On Sunday, he missed a bus and walked instead. He found a quiet street full of colourful buildings. He took fewer photos than he expected, but remembered more conversations. When he returned home, he decided that a good trip did not need a full timetable.''',
      authoredQuestions: [
        ReadingQuestion(
            'Why did Leo change his first plan?',
            [
              'The museums were closed',
              'He wanted time to enjoy the city',
              'He lost his money',
              'He disliked walking'
            ],
            1,
            'Друг звернув увагу на занадто щільний план.',
            'would he have time to enjoy any of them'),
        ReadingQuestion(
            'Who told Leo about a nearby park?',
            ['A bus driver', 'His friend', 'A market seller', 'A museum guide'],
            2,
            'Парк порадив продавець на ринку.',
            'The seller showed him a small park nearby'),
        ReadingQuestion(
            'What did Leo decide at the end?',
            [
              'A trip needs a full timetable',
              'Conversation is a waste of time',
              'He should never use buses',
              'A good trip can leave room for discovery'
            ],
            3,
            'Вільний час залишив місце для несподіваних відкриттів.',
            'a good trip did not need a full timetable'),
      ]),
  ReadingArticle(
      id: 'starter:technology',
      title: 'Small habits for a clearer digital day',
      topic: 'IT',
      level: 'B1',
      text:
          '''Nora used to check every message as soon as her phone made a sound. At work, she often started a task, answered a message and then forgot what she had been doing. She did not want to stop using technology. She wanted to use it with a purpose.

She tried three small changes for a week. First, she turned off notifications from shopping apps. Second, she checked personal messages during breaks. Third, she wrote down her next step before leaving a task.

The changes did not make every day perfect. Important calls could still interrupt her, and some tasks took longer than expected. However, she spent less time remembering where to start again. For Nora, better focus was not about finding a new app. It was about choosing a few habits she could repeat.''',
      authoredQuestions: [
        ReadingQuestion(
            'What problem did Nora have?',
            [
              'Her phone had no sound',
              'Messages interrupted her tasks',
              'She could not use apps',
              'She never took breaks'
            ],
            1,
            'Після повідомлень Nora забувала, над чим працювала.',
            'forgot what she had been doing'),
        ReadingQuestion(
            'What did she do before leaving a task?',
            [
              'Bought a new phone',
              'Deleted every message',
              'Wrote down her next step',
              'Called a colleague'
            ],
            2,
            'Запис наступного кроку допомагав повернутися до роботи.',
            'wrote down her next step'),
        ReadingQuestion(
            'Which statement matches the ending?',
            [
              'The habits made every day perfect',
              'Nora stopped using technology',
              'Every call became unimportant',
              'Repeatable habits helped her focus'
            ],
            3,
            'Невеликі повторювані звички допомогли, хоча перешкоди залишилися.',
            'a few habits she could repeat'),
      ]),
  ReadingArticle(
      id: 'starter:work',
      title: 'A meeting with a purpose',
      topic: 'Business',
      level: 'B1',
      text:
          '''A team at a small company met every Monday. The meetings usually lasted an hour, but nobody knew exactly what had been decided. People often discussed the same problem again the following week.

One day, Sam suggested a different approach. Before each meeting, the team would write one question they needed to answer. During the meeting, someone would record the decision, the person responsible and a date for the next step. Topics without enough information would go onto a separate list.

The first new meeting finished in twenty minutes. The team still disagreed about some ideas, but the disagreement led to a clear choice. After a month, they kept the new method. They had learned that a shorter meeting was useful only when people knew what to do afterwards.''',
      authoredQuestions: [
        ReadingQuestion(
            'What was wrong with the old meetings?',
            [
              'Nobody attended',
              'They were always too short',
              'Decisions were unclear',
              'They happened every day'
            ],
            2,
            'Люди не розуміли, які рішення було ухвалено.',
            'nobody knew exactly what had been decided'),
        ReadingQuestion(
            'What did the team prepare before a meeting?',
            [
              'One question to answer',
              'A long shopping list',
              'A new office',
              'An hour of music'
            ],
            0,
            'Спочатку команда формулювала одне потрібне питання.',
            'write one question they needed to answer'),
        ReadingQuestion(
            'When is a shorter meeting useful?',
            [
              'When no one speaks',
              'When people know the next action',
              'When all ideas are the same',
              'When no decision is recorded'
            ],
            1,
            'Важливо знати, що робити після зустрічі.',
            'people knew what to do afterwards'),
      ]),
  ReadingArticle(
      id: 'starter:music',
      title: 'Learning a song together',
      topic: 'Music',
      level: 'A2',
      text:
          '''Three friends wanted to play a song at a neighbourhood party. Eva could sing, Daniel played the guitar and Kate had just started learning the drums. At their first practice, everyone played at a different speed.

Instead of starting the whole song again, they chose one short section. Daniel played it slowly, and Kate listened before joining. Eva waited until both instruments had the same rhythm. They practised the section several times and then added the next part.

At the party, Kate made a small mistake. The other two kept playing, so she found the rhythm again. Most people did not notice. After the song, the friends agreed that listening to each other had helped more than trying to play perfectly alone.''',
      authoredQuestions: [
        ReadingQuestion(
            'Which instrument was Kate learning?',
            ['Piano', 'Guitar', 'Violin', 'Drums'],
            3,
            'Kate тільки почала вчитися грати на барабанах.',
            'Kate had just started learning the drums'),
        ReadingQuestion(
            'How did the friends solve the speed problem?',
            [
              'They stopped listening',
              'They practised one short section slowly',
              'They changed the song every minute',
              'They cancelled the party'
            ],
            1,
            'Вони розділили пісню на короткі частини й тренувалися повільно.',
            'they chose one short section'),
        ReadingQuestion(
            'What helped them most?',
            [
              'Playing perfectly alone',
              'Buying new instruments',
              'Listening to each other',
              'Avoiding all mistakes'
            ],
            2,
            'Взаємне слухання було важливішим за самостійну бездоганність.',
            'listening to each other had helped more'),
      ]),
];
