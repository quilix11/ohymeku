import 'dart:math';
import 'learning_exercise.dart';
import 'mountain_grammar.dart';
import 'journey_story.dart';
import 'scenario.dart';
import '../services/vocabulary_service.dart';

class JourneyQuestion {
  final String id, question, explanation;
  final List<String> options;
  final int answer;
  final LearningExercise? grammar;
  const JourneyQuestion(
      this.id, this.question, this.options, this.answer, this.explanation,
      {this.grammar});
}

class JourneyLevel {
  final String id, title, world, guide;
  final int number, difficulty;
  final List<String> wordIds;
  final List<LearningExercise>? grammar;
  final bool boss;
  const JourneyLevel(this.id, this.number, this.title, this.world, this.guide,
      this.wordIds, this.difficulty,
      {this.boss = false, this.grammar});
  JourneyStory get story => journeyStories[id]!;
  Scenario? get opponent => journeyBosses[id];
  bool get hasExtraPractice => journeyStories.containsKey(id);
  List<String> get challengeIds =>
      hasExtraPractice ? const ['read:0', 'read:1', 'order'] : const [];
  List<WordCard> get worldWords => journeyLevels
      .where((l) => l.world == world)
      .expand((l) => l.words)
      .toList();
  List<WordCard> get words =>
      [for (final id in wordIds) starterCards.firstWhere((w) => w.id == id)];
  List<String> choices(WordCard word) => [
        word.translation,
        ...starterCards
            .where((w) => w.id != word.id && w.deck == word.deck)
            .take(2)
            .map((w) => w.translation)
      ];

  List<JourneyQuestion> questions({Random? random}) {
    final rng = random ?? Random();
    final result = <JourneyQuestion>[
      for (final word in words)
        JourneyQuestion(
            'word:${word.id}',
            'Що означає «${word.word}»?',
            choices(word),
            0,
            '${word.word} — ${word.translation}. ${word.example}'),
      for (final e in grammar ??
          practiceExercises.where((e) => e.difficulty == difficulty).take(3))
        JourneyQuestion(e.id, e.question, e.options, e.answer, e.explanation,
            grammar: e),
    ];
    // Shuffle choices while retaining the answer mapping for this attempt.
    return result.map((q) {
      final order = List.generate(q.options.length, (i) => i)..shuffle(rng);
      return JourneyQuestion(
          q.id,
          q.question,
          [for (final i in order) q.options[i]],
          order.indexOf(q.answer),
          q.explanation,
          grammar: q.grammar);
    }).toList();
  }
}

const journeyWorldTitles = {
  'Подорож': 'Долина подорожей',
  'Робота': 'Місто команди',
  'Школа': 'Сад історій',
  'Гори': 'Перевал відлунь',
};

const journeyLevels = [
  JourneyLevel(
      'j1',
      1,
      'Перший крок',
      'Подорож',
      'Привіт, мандрівнику! Почнемо з двох слів. Потім перевіримо їх у маленькому тесті.',
      ['a1', 'a2'],
      0),
  JourneyLevel(
      'j2',
      2,
      'План поїздки',
      'Подорож',
      'Куди їдемо й де житимемо? Збирай слова для свого плану.',
      ['a3', 'a4'],
      0),
  JourneyLevel(
      'j3',
      3,
      'Збираємо валізу',
      'Подорож',
      'Валіза готова? Вивчимо слова й потренуємо минулий час та запитання.',
      ['a5', 'a6'],
      1),
  JourneyLevel(
      'j4',
      4,
      'Бос: аеропорт',
      'Подорож',
      'Vance чекає біля останнього турнікета. Збери підказки та підготуйся пояснити свою подорож.',
      ['a7', 'a8'],
      1,
      boss: true),
  JourneyLevel(
      'j5',
      5,
      'Нова команда',
      'Робота',
      'Новий світ! Поговоримо про досвід та обов’язки. Я поруч.',
      ['h1', 'h2'],
      2),
  JourneyLevel(
      'j6',
      6,
      'Твій проєкт',
      'Робота',
      'Досягнення й дедлайни — звучить серйозно. Розберемо їх крок за кроком.',
      ['h3', 'h4'],
      2),
  JourneyLevel(
      'j7',
      7,
      'Приймаємо виклик',
      'Робота',
      'Трохи складніша граматика й твої сильні сторони. Помилки допоможуть зрозуміти, що повторити.',
      ['h5', 'h6'],
      3),
  JourneyLevel(
      'j8',
      8,
      'Бос: сила команди',
      'Робота',
      'Hannah чекає на співбесіді. Розбери лист від команди й підготуй розповідь про свої сильні сторони.',
      ['h7', 'h8'],
      4,
      boss: true),
  JourneyLevel(
      'j9',
      9,
      'Лист із бібліотеки',
      'Школа',
      'Пані Willow загубила сторінку своєї історії. Читай лист і знайди першу підказку!',
      ['s1', 's2'],
      0),
  JourneyLevel('j10', 10, 'Таємний розклад', 'Школа',
      'Розшифруй записку й допоможи Meku встигнути на урок.', ['s3', 's4'], 1),
  JourneyLevel(
      'j11',
      11,
      'Загадка в саду',
      'Школа',
      'За останніми дверима — вчителька. Спершу знайдемо відповідь у маленькій історії.',
      ['s5', 's6'],
      2),
  JourneyLevel(
      'j12',
      12,
      'Бос: пані Willow',
      'Школа',
      'Пані Willow хоче почути твою історію. Підготуй слова, прочитай записку й увійди до класу.',
      ['s7', 's8'],
      3,
      boss: true),
  JourneyLevel(
      'j13',
      13,
      'Маршрут до перевалу',
      'Гори',
      'Потренуйся питати дорогу й перевіряти, куди веде стежка.',
      ['m1', 'm2'],
      1,
      grammar: mountainDirections),
  JourneyLevel('j14', 14, 'Ніч у притулку', 'Гори',
      'Попроси теплу ковдру й домовся про нічліг.', ['m3', 'm4'], 1,
      grammar: mountainShelter),
  JourneyLevel('j15', 15, 'Зміна погоди', 'Гори',
      'Склади план на випадок туману та попередь друзів.', ['m5', 'm6'], 2,
      grammar: mountainWeather),
  JourneyLevel(
      'j16',
      16,
      'Сигнал для команди',
      'Гори',
      'Передай почуте англійською, зберігши зміст і час події.',
      ['m7', 'm8'],
      2,
      grammar: mountainSignal),
  JourneyLevel('j17', 17, 'Майстерня годинників', 'Гори',
      'Поясни, що вже полагодили, а що ще треба перевірити.', ['m9', 'm10'], 3,
      grammar: mountainWorkshop),
  JourneyLevel(
      'j18',
      18,
      'Голос із долини',
      'Гори',
      'Уточни, чи правильно тебе почули, та підсумуй домовленість.',
      ['m11', 'm12'],
      3,
      grammar: mountainBroadcast),
];
