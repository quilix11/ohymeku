import 'learning_exercise.dart';

const mountainDirections = [
  LearningExercise(
      'm-g1',
      'Напрямки',
      'Ти біля вокзалу.',
      'Walk ___ the station to reach the trail.',
      ['past', 'since', 'among'],
      0,
      'Walk past означає пройти повз.',
      difficulty: 1),
  LearningExercise(
      'm-g2',
      'Непрямі запитання',
      'Запитай про стежку ввічливо.',
      'Could you tell me ___?',
      [
        'where the trail starts',
        'where does the trail start',
        'where starts the trail'
      ],
      0,
      'Після Could you tell me? зберігаємо прямий порядок слів: the trail starts.',
      difficulty: 1),
  LearningExercise(
      'm-g3',
      'Прийменники місця',
      'Зустріч біля вказівника.',
      'Meet me ___ the signpost.',
      ['onto', 'at', 'since'],
      1,
      'At вказує на конкретне місце зустрічі.',
      difficulty: 1),
];

const mountainShelter = [
  LearningExercise(
      'm-g4',
      'Ввічливі прохання',
      'Попроси ковдру.',
      '___ I have an extra blanket, please?',
      ['Did', 'Am', 'Could'],
      2,
      'Could I have…? — ввічливий спосіб попросити річ.',
      difficulty: 1),
  LearningExercise(
      'm-g5',
      'Some та any',
      'Уточни наявність вільних місць.',
      'Are there ___ beds left?',
      ['any', 'much', 'every'],
      0,
      'У нейтральному питанні про наявність вживаємо any.',
      difficulty: 1),
  LearningExercise(
      'm-g6',
      'Правила',
      'У притулку заборонено палити.',
      'You ___ smoke inside the shelter.',
      ['might', 'must not', 'do not have to'],
      1,
      'Must not означає заборону. Do not have to означає, що дія необов’язкова.',
      difficulty: 1),
];

const mountainWeather = [
  LearningExercise(
      'm-g7',
      'Умова',
      'Вирішуєш, що робити за туману.',
      'If the fog gets thicker, we ___ here.',
      ['waited', 'will wait', 'had waited'],
      1,
      'Для можливої майбутньої умови використовуємо present simple після if і will у результаті.',
      difficulty: 2),
  LearningExercise(
      'm-g8',
      'Прогноз',
      'Небо вже потемніло.',
      'Look at those clouds! It ___ rain.',
      ['is going to', 'has', 'used to'],
      0,
      'Be going to доречно, коли прогноз спирається на видимі ознаки.',
      difficulty: 2),
  LearningExercise(
      'm-g9',
      'Порівняння',
      'Нижня стежка безпечніша.',
      'The lower trail is ___ than the upper one.',
      ['safest', 'more safer', 'safer'],
      2,
      'Короткий прикметник safe має порівняльну форму safer.',
      difficulty: 2),
];

const mountainSignal = [
  LearningExercise(
      'm-g10',
      'Непряма мова',
      'Учора Ірис сказала: «I am at the bridge».',
      'Iris said she ___ at the bridge.',
      ['is being', 'was', 'will be'],
      1,
      'Коли переповідаємо минуле повідомлення про минулу ситуацію, am стає was.',
      difficulty: 2),
  LearningExercise(
      'm-g11',
      'Підтвердження',
      'Попроси повторити час зустрічі.',
      'Could you repeat what time ___?',
      ['do we meet', 'meet we', 'we meet'],
      2,
      'У вкладеному запитанні після what time підмет стоїть перед дієсловом.',
      difficulty: 2),
  LearningExercise(
      'm-g12',
      'Займенники',
      'Сигнал адресовано двом друзям.',
      'Send the signal to ___ when you arrive.',
      ['they', 'them', 'their'],
      1,
      'Після to потрібна об’єктна форма them.',
      difficulty: 2),
];

const mountainWorkshop = [
  LearningExercise(
      'm-g13',
      'Present perfect',
      'Приймач щойно запрацював.',
      'We ___ just repaired the receiver.',
      ['have', 'are', 'did'],
      0,
      'Have + repaired передає нещодавню дію з результатом зараз.',
      difficulty: 3),
  LearningExercise(
      'm-g14',
      'Пасивний стан',
      'Описуєш ремонт учора.',
      'The clock ___ by the technician yesterday.',
      ['has repairing', 'was repaired', 'repaired'],
      1,
      'Пасив у минулому часі: was + repaired.',
      difficulty: 3),
  LearningExercise(
      'm-g15',
      'Yet та already',
      'Запасну батарею ще не перевірили.',
      'We have not tested the spare battery ___.',
      ['already', 'ever since', 'yet'],
      2,
      'У запереченні yet означає «ще» і зазвичай стоїть наприкінці.',
      difficulty: 3),
];

const mountainBroadcast = [
  LearningExercise(
      'm-g16',
      'Уточнення',
      'Повтори час, щоб перевірити, чи ти правильно почув.',
      'Did you say the broadcast ___ at six?',
      ['starts', 'start it', 'does start it'],
      0,
      'У вкладеній частині the broadcast starts порядок слів прямий.',
      difficulty: 3),
  LearningExercise(
      'm-g17',
      'Зв’язок думок',
      'Сигнал слабкий, тому повторюєш останній рядок.',
      'The signal is weak, ___ I will repeat the last line.',
      ['although', 'so', 'unless'],
      1,
      'So вводить наслідок: «тому».',
      difficulty: 3),
  LearningExercise(
      'm-g18',
      'Умова',
      'Без підтвердження передачі не буде.',
      'We will not broadcast ___ both teams confirm.',
      ['since', 'despite', 'unless'],
      2,
      'Unless означає «якщо тільки не». Передача буде за умови підтвердження.',
      difficulty: 3),
];

const mountainGrammar = [
  ...mountainDirections,
  ...mountainShelter,
  ...mountainWeather,
  ...mountainSignal,
  ...mountainWorkshop,
  ...mountainBroadcast,
];
