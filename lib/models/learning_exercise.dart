class LearningExercise {
  final String id, topic, situation, question, explanation, interest;
  final List<String> options;
  final int answer, difficulty;
  const LearningExercise(this.id, this.topic, this.situation, this.question,
      this.options, this.answer, this.explanation,
      {this.difficulty = 0, this.interest = 'Travel'});

  Map<String, dynamic> toJson() => {
        'id': id,
        'topic': topic,
        'situation': situation,
        'question': question,
        'options': options,
        'answer': answer,
        'explanation': explanation,
        'difficulty': difficulty,
        'interest': interest,
      };
  static LearningExercise? parse(dynamic data) {
    if (data is! Map) return null;
    final options = data['options'];
    if (options is! List ||
        options.length < 2 ||
        options.length > 4 ||
        options
            .any((v) => v is! String || v.trim().isEmpty || v.length > 250) ||
        options.toSet().length != options.length) {
      return null;
    }
    final answer = data['answer'];
    if (answer is! int || answer < 0 || answer >= options.length) return null;
    if (data['difficulty'] != null && data['difficulty'] is! int) return null;
    if (data['interest'] != null && data['interest'] is! String) return null;
    for (final key in ['id', 'topic', 'situation', 'question', 'explanation']) {
      if (data[key] is! String ||
          (data[key] as String).trim().isEmpty ||
          (data[key] as String).length > 1500) {
        return null;
      }
    }
    return LearningExercise(
        data['id'],
        data['topic'],
        data['situation'],
        data['question'],
        List<String>.from(options),
        answer,
        data['explanation'],
        difficulty: ((data['difficulty'] as num?)?.toInt() ?? 1).clamp(0, 4),
        interest: data['interest'] as String? ?? 'Personal');
  }
}

// Authored, bundled exercises; no network or generated answers needed.
const practiceExercises = [
  LearningExercise('g1', 'be', 'Знайомишся в кав’ярні.', 'I ___ from Ukraine.',
      ['am', 'is', 'are'], 0, 'З I вживаємо am: I am from Ukraine.',
      interest: 'Food'),
  LearningExercise(
      'g2',
      'articles',
      'Замовляєш перекус.',
      'I would like ___ apple.',
      ['a', 'an', 'some'],
      1,
      'Перед голосним звуком вживаємо an: an apple.',
      interest: 'Food'),
  LearningExercise(
      'g3',
      'present',
      'Розповідаєш про подругу.',
      'She ___ English every day.',
      ['study', 'studies', 'studying'],
      1,
      'У Present Simple після she додаємо -s: studies.',
      interest: 'Movies'),
  LearningExercise(
      'g4',
      'past',
      'Ділишся вчорашнім враженням.',
      'We ___ a film last night.',
      ['watch', 'watched', 'watching'],
      1,
      'Last night вказує на завершене минуле: watched.',
      difficulty: 1,
      interest: 'Movies'),
  LearningExercise(
      'g5',
      'questions',
      'Питаєш про автобус.',
      'Where ___ this bus stop?',
      ['do', 'is', 'does'],
      2,
      'Питання у Present Simple: Where does this bus stop?',
      difficulty: 1),
  LearningExercise(
      'g6',
      'comparatives',
      'Обираєш транспорт.',
      'The train is ___ than the bus.',
      ['fast', 'faster', 'fastest'],
      1,
      'Порівняння двох речей: faster than.',
      difficulty: 1),
  LearningExercise(
      'g7',
      'perfect',
      'Пояснюєш досвід на співбесіді.',
      'I ___ here since 2022.',
      ['worked', 'am working', 'have worked'],
      2,
      'Since + початок періоду до тепер: have worked.',
      difficulty: 2,
      interest: 'Business'),
  LearningExercise(
      'g8',
      'conditionals',
      'Плануєш поїздку.',
      'If it rains, we ___ indoors.',
      ['will stay', 'would stay', 'stayed'],
      0,
      'Реальна майбутня умова: if + Present Simple, will + дієслово.',
      difficulty: 2),
  LearningExercise(
      'g9',
      'modals',
      'Даєш пораду колезі.',
      'You ___ back up your files regularly.',
      ['should', 'must to', 'ought'],
      0,
      'Порада: should + дієслово без to.',
      difficulty: 2,
      interest: 'IT'),
  LearningExercise(
      'g10',
      'past-perfect',
      'Пояснюєш пропущену зустріч.',
      'By the time I arrived, the meeting ___.',
      ['has ended', 'had ended', 'ends'],
      1,
      'Попередня дія в минулому: had ended.',
      difficulty: 3,
      interest: 'Business'),
  LearningExercise(
      'g11',
      'passive',
      'Обговорюєш нову функцію.',
      'The update ___ tomorrow.',
      ['will release', 'will be released', 'has releasing'],
      1,
      'Пасивний стан: will be + past participle.',
      difficulty: 3,
      interest: 'IT'),
  LearningExercise(
      'g12',
      'reported',
      'Передаєш слова колеги.',
      'She said she ___ the report the next day.',
      ['will send', 'would send', 'sends'],
      1,
      'У непрямій мові після said: will → would.',
      difficulty: 3,
      interest: 'Business'),
  LearningExercise(
      'g13',
      'inversion',
      'Підкреслюєш незвичайний досвід.',
      'Never ___ such a moving film.',
      ['I have seen', 'have I seen', 'I saw'],
      1,
      'Після Never на початку — інверсія: have I seen.',
      difficulty: 4,
      interest: 'Movies'),
  LearningExercise(
      'g14',
      'mixed-conditional',
      'Аналізуєш наслідки навчання.',
      'If I had learned to code, I ___ a developer now.',
      ['would be', 'would have been', 'will be'],
      0,
      'Минула умова та теперішній результат: had learned → would be now.',
      difficulty: 4,
      interest: 'IT'),
  LearningExercise(
      'g15',
      'concession',
      'Оцінюєш результат проєкту.',
      '___ the tight deadline, we delivered on time.',
      ['Although', 'Despite', 'Even'],
      1,
      'Despite + іменникова група; although потребує підрядного речення.',
      difficulty: 4,
      interest: 'Business'),
];

// A separate item bank avoids immediately practising memorised placement answers.
const placementExercises = [
  LearningExercise('p1', 'be', 'Представся.', 'My name ___ Alex.',
      ['are', 'is', 'am'], 1, 'My name is Alex.'),
  LearningExercise('p2', 'articles', 'В аеропорту.', 'This is ___ passport.',
      ['a', 'an', 'some'], 0, 'A passport.'),
  LearningExercise(
      'p3',
      'present',
      'Щоденна звичка.',
      'He ___ coffee every morning.',
      ['drink', 'drinking', 'drinks'],
      2,
      'He drinks.',
      interest: 'Food'),
  LearningExercise(
      'p4',
      'past',
      'Учора в місті.',
      'Yesterday I ___ to the museum.',
      ['go', 'went', 'gone'],
      1,
      'Yesterday I went.',
      difficulty: 1),
  LearningExercise(
      'p5',
      'questions',
      'Уточни час.',
      'What time ___ the shop open?',
      ['does', 'do', 'is'],
      0,
      'What time does the shop open?',
      difficulty: 1),
  LearningExercise(
      'p6',
      'comparatives',
      'Порівняй два готелі.',
      'This hotel is ___ than that one.',
      ['cheap', 'cheapest', 'cheaper'],
      2,
      'Cheaper than.',
      difficulty: 1),
  LearningExercise(
      'p7',
      'perfect',
      'Опиши тривалість роботи.',
      'She has worked here ___ five years.',
      ['since', 'for', 'during'],
      1,
      'For + тривалість.',
      difficulty: 2),
  LearningExercise(
      'p8',
      'conditionals',
      'Запропонуй план.',
      'If I ___ time tomorrow, I will call you.',
      ['have', 'had', 'will have'],
      0,
      'If + present, will + verb.',
      difficulty: 2),
  LearningExercise(
      'p9',
      'modals',
      'Порадь другові.',
      'You look tired. You ___ get some rest.',
      ['should to', 'should', 'can to'],
      1,
      'Should + verb.',
      difficulty: 2),
  LearningExercise(
      'p10',
      'past-perfect',
      'Поясни, чому запізнився.',
      'The train ___ before we reached the station.',
      ['has left', 'leaves', 'had left'],
      2,
      'Had left: дія перед іншою минулою дією.',
      difficulty: 3),
  LearningExercise(
      'p11',
      'passive',
      'Оголоси зміну.',
      'The office ___ next month.',
      ['will be renovated', 'will renovate', 'renovates'],
      0,
      'Will be + past participle.',
      difficulty: 3),
  LearningExercise(
      'p12',
      'reported',
      'Передай прохання.',
      'He asked me where I ___.',
      ['did live', 'lived', 'do live'],
      1,
      'У непрямому питанні прямий порядок слів.',
      difficulty: 3),
  LearningExercise(
      'p13',
      'inversion',
      'Наголоси на рідкісності.',
      'Rarely ___ such dedication.',
      ['we encounter', 'we have encounter', 'do we encounter'],
      2,
      'Інверсія після rarely.',
      difficulty: 4),
  LearningExercise(
      'p14',
      'mixed-conditional',
      'Уяви інший результат.',
      'Had she accepted the offer, she ___ in Paris now.',
      ['would be living', 'would have lived', 'will live'],
      0,
      'Умова в минулому, результат тепер.',
      difficulty: 4),
  LearningExercise(
      'p15',
      'concession',
      'Продовж думку.',
      '___ difficult it may be, we must try.',
      ['Despite', 'However', 'Although'],
      1,
      'However + adjective + subject + verb.',
      difficulty: 4),
];
