import 'package:flutter/material.dart';
import 'journey_level.dart';
import 'game_state.dart';
import 'scenario.dart';

class JourneyStory {
  final String title, text, sentence, reward;
  final List<JourneyQuestion> questions;
  const JourneyStory(
      this.title, this.text, this.questions, this.sentence, this.reward);
  List<String> get tokens => sentence.split(' ');
}

const journeyStories = <String, JourneyStory>{
  'j1': JourneyStory(
      'Загублений квиток',
      'Meku finds a boarding pass under a blue chair. It belongs to Alex. His purpose is to visit his sister. His flight leaves from gate six.',
      [
        JourneyQuestion(
            'read:0',
            'Де Meku знайшла квиток?',
            ['Under a blue chair', 'In a suitcase', 'At gate ten'],
            0,
            'У тексті: under a blue chair — під синім стільцем.'),
        JourneyQuestion(
            'read:1',
            'Навіщо Alex летить?',
            ['To visit his sister', 'To start a new job', 'To study'],
            0,
            'His purpose is to visit his sister — він летить до сестри.')
      ],
      'May I see your boarding pass?',
      'Перший слід'),
  'j2': JourneyStory(
      'Лист від господаря',
      'Hi Alex! Your accommodation is near the river. Take bus twelve from the airport. Keep your return ticket safe: you fly home on Sunday.',
      [
        JourneyQuestion(
            'read:0',
            'Що розташовано біля річки?',
            ['The accommodation', 'The airport', 'The bus station'],
            0,
            'Your accommodation is near the river.'),
        JourneyQuestion(
            'read:1',
            'Коли Alex повертається додому?',
            ['On Sunday', 'On Friday', 'On Monday'],
            0,
            'You fly home on Sunday — у неділю.')
      ],
      'I have a return ticket.',
      'Ключ від будиночка'),
  'j3': JourneyStory(
      'Оголошення на табло',
      'Attention, passengers! The departure is delayed by one hour. Please collect your luggage at desk three. Do not leave bags near the exit.',
      [
        JourneyQuestion(
            'read:0',
            'Що сталося з вильотом?',
            ['It is delayed', 'It is cancelled', 'It is early'],
            0,
            'Delayed by one hour — затриманий на годину.'),
        JourneyQuestion(
            'read:1',
            'Де забрати багаж?',
            ['At desk three', 'Near the exit', 'At gate six'],
            0,
            'Collect your luggage at desk three.')
      ],
      'Where can I collect my luggage?',
      'Перепустка до термінала'),
  'j4': JourneyStory(
      'Перед турнікетом',
      'Alex will stay for five days. He has a small gift for his sister and nothing to declare. Officer Vance asks him to explain the purpose of his visit.',
      [
        JourneyQuestion(
            'read:0',
            'Скільки днів Alex залишиться?',
            ['Five days', 'Three days', 'Two weeks'],
            0,
            'He will stay for five days.'),
        JourneyQuestion(
            'read:1',
            'Що запитує Vance?',
            [
              'The purpose of the visit',
              'The price of the gift',
              'The time of breakfast'
            ],
            0,
            'Explain the purpose of his visit — пояснити мету візиту.')
      ],
      'I have nothing to declare.',
      'Печатка мандрівника'),
  'j5': JourneyStory(
      'Запрошення в команду',
      'Hello! We need someone with experience in customer support. Your main responsibility will be helping customers by email. Our team works from nine to five.',
      [
        JourneyQuestion(
            'read:0',
            'Який досвід потрібен?',
            ['Customer support', 'Cooking', 'Driving'],
            0,
            'Experience in customer support.'),
        JourneyQuestion(
            'read:1',
            'Як допомагатимеш клієнтам?',
            ['By email', 'By taxi', 'By letter only'],
            0,
            'Helping customers by email.')
      ],
      'I have experience in customer support.',
      'Значок команди'),
  'j6': JourneyStory(
      'Повідомлення про проєкт',
      'Our deadline is Thursday. Sam has finished the design, but the report is not ready. Completing both tasks on time will be a real achievement for our team.',
      [
        JourneyQuestion(
            'read:0',
            'Що ще не готове?',
            ['The report', 'The design', 'The invitation'],
            0,
            'The report is not ready.'),
        JourneyQuestion('read:1', 'Коли кінцевий термін?',
            ['Thursday', 'Tuesday', 'Saturday'], 0, 'Our deadline is Thursday.')
      ],
      'We can finish before the deadline.',
      'Мапа проєкту'),
  'j7': JourneyStory(
      'Квест для напарника',
      'Meku is nervous about speaking in front of the team. Her strength is explaining ideas clearly. The challenge is to give a short presentation without reading every sentence.',
      [
        JourneyQuestion(
            'read:0',
            'Яка сильна сторона Meku?',
            ['Explaining ideas clearly', 'Drawing maps', 'Running fast'],
            0,
            'Her strength is explaining ideas clearly.'),
        JourneyQuestion(
            'read:1',
            'Що їй потрібно зробити?',
            [
              'Give a short presentation',
              'Write a long book',
              'Cancel the meeting'
            ],
            0,
            'The challenge is to give a short presentation.')
      ],
      'My strength is explaining ideas clearly.',
      'Ліхтар упевненості'),
  'j8': JourneyStory(
      'Лист від Hannah',
      'Dear candidate, our team wants to improve its service. We value teamwork more than perfect answers. At the interview, please describe a time you helped someone solve a problem.',
      [
        JourneyQuestion(
            'read:0',
            'Що цінує команда?',
            ['Teamwork', 'Perfect answers only', 'Working alone'],
            0,
            'We value teamwork more than perfect answers.'),
        JourneyQuestion(
            'read:1',
            'Про що треба розповісти?',
            [
              'Helping someone solve a problem',
              'Your favourite airport',
              'The weather'
            ],
            0,
            'Describe a time you helped someone solve a problem.')
      ],
      'I want to improve through teamwork.',
      'Печатка команди'),
  'j9': JourneyStory(
      'Записка між сторінками',
      'Dear Meku, you can borrow the green book from the library. Open page seven. There is a small map inside. Please return the book on Friday. — Ms Willow',
      [
        JourneyQuestion(
            'read:0',
            'Яку книжку треба позичити?',
            ['The green book', 'The red book', 'The blue book'],
            0,
            'You can borrow the green book.'),
        JourneyQuestion(
            'read:1',
            'Де захована мапа?',
            ['On page seven', 'Under the table', 'Near the window'],
            0,
            'Open page seven. There is a small map inside.')
      ],
      'May I borrow this book?',
      'Зелена книжка'),
  'j10': JourneyStory(
      'Розклад із секретом',
      'The schedule says: music at nine, English at ten, art at eleven. The English lesson is in room four. Bring the green book, but leave your paints in the art room.',
      [
        JourneyQuestion('read:0', 'Коли починається англійська?',
            ['At ten', 'At nine', 'At eleven'], 0, 'English at ten.'),
        JourneyQuestion(
            'read:1',
            'Що взяти на урок англійської?',
            ['The green book', 'Your paints', 'A suitcase'],
            0,
            'Bring the green book.')
      ],
      'Our English lesson starts at ten.',
      'Ключ від класу'),
  'j11': JourneyStory(
      'Стежка в таємний сад',
      'The map has one clue: find a place where plants drink but people stay dry. Meku walks past the fountain and discovers a greenhouse. Ms Willow is waiting beside the door.',
      [
        JourneyQuestion(
            'read:0',
            'Яке місце підходить до підказки?',
            ['A greenhouse', 'A bedroom', 'A bus stop'],
            0,
            'Рослини поливають у теплиці, а дах захищає людей.'),
        JourneyQuestion(
            'read:1',
            'Де чекає пані Willow?',
            ['Beside the door', 'Inside the fountain', 'At the library'],
            0,
            'Ms Willow is waiting beside the door.')
      ],
      'We discover a secret garden.',
      'Листок із підказкою'),
  'j12': JourneyStory(
      'Остання сторінка',
      'Ms Willow smiles: “A curious learner asks questions. Explain how you found the garden. Tell me which clue helped you, and invent a new ending for our story.” Meku opens her notebook.',
      [
        JourneyQuestion(
            'read:0',
            'Що робить допитливий учень?',
            ['Asks questions', 'Never makes mistakes', 'Always stays silent'],
            0,
            'A curious learner asks questions.'),
        JourneyQuestion(
            'read:1',
            'Що треба придумати?',
            ['A new ending', 'A new deadline', 'A return ticket'],
            0,
            'Invent a new ending for our story.')
      ],
      'Can you explain your answer?',
      'Печатка оповідача'),
};

final journeyBosses = <String, Scenario>{
  'j4': _boss(
      'j4',
      Scenario.all[0],
      'Вартовий термінала',
      'Explain the purpose of your visit, your accommodation and how long you will stay. You collected a boarding pass and return ticket on the way.',
      'Hello, traveller! Meku brought you to the last gate. What is the purpose of your visit?',
      'Fair border officer. Ask about purpose, accommodation, return ticket and luggage. Accept a coherent trip plan. Use words from the traveller’s quests.'),
  'j8': _boss(
      'j8',
      Scenario.all[1],
      'Вартова команди',
      'Describe your experience, a real or imagined achievement, how you meet a deadline and help a team.',
      'Welcome! Meku tells me you helped the team. What experience would you bring to this job?',
      'Supportive but demanding HR interviewer. Ask for concrete examples of experience, a challenge and teamwork. Accept plausible learner examples.'),
  'j12': const Scenario(
      customId: 'journey-boss-j12',
      voiceProfileId: 'willow',
      character: GameCharacter.hr,
      name: 'Ms Willow',
      role: 'ВЧИТЕЛЬКА · ВАРТОВА ІСТОРІЙ',
      title: 'Пані Willow',
      goal:
          'Discuss the library and greenhouse story. Explain which clue helped you find the garden and invent a short ending. Ask one curious question.',
      opening:
          'Hello, curious explorer! How did you and Meku discover the secret garden?',
      level: 'A2',
      personality:
          'Warm, playful English teacher. Refer to the green library book, room four and greenhouse clue. Ask one short question at a time. Help the learner tell a story; do not demand perfect grammar.',
      winTitle: 'Історію врятовано!',
      color: Color(0xFF5A756A),
      backdrop: Color(0xFFE0EBDE)),
};
Scenario _boss(String id, Scenario source, String role, String goal,
        String opening, String personality) =>
    Scenario(
        customId: 'journey-boss-$id',
        voiceProfileId: source.voiceKey,
        character: source.character,
        name: source.name,
        role: role,
        title: source.name,
        goal: goal,
        opening: opening,
        personality: personality,
        level: 'A2',
        winTitle: source.winTitle,
        color: source.color,
        backdrop: source.backdrop);

const bossDialogues = <String, List<JourneyQuestion>>{
  'j4': [
    JourneyQuestion(
        'boss:0',
        'Vance: “What is the purpose of your visit?”',
        [
          'I am visiting my sister for five days.',
          'Give me your suitcase.',
          'My deadline is Thursday.'
        ],
        0,
        'Назви мету й тривалість подорожі.'),
    JourneyQuestion(
        'boss:1',
        'Vance: “Where will you stay?”',
        [
          'I have booked accommodation near the river.',
          'I have nothing to read.',
          'I work from nine to five.'
        ],
        0,
        'Accommodation — місце проживання.'),
    JourneyQuestion(
        'boss:2',
        'Vance: “Do you have anything to declare?”',
        [
          'No, just a small gift and my clothes.',
          'Yes, your lesson starts at ten.',
          'I will borrow a library.'
        ],
        0,
        'Відповідь має стосуватися речей у багажі.')
  ],
  'j8': [
    JourneyQuestion(
        'boss:0',
        'Hannah: “What experience do you have?”',
        [
          'I helped customers by email for one year.',
          'My luggage is at desk three.',
          'I have nothing to declare.'
        ],
        0,
        'Наведи конкретний приклад досвіду.'),
    JourneyQuestion(
        'boss:1',
        'Hannah: “The deadline is tomorrow. What will you do?”',
        [
          'I will agree on priorities and ask the team for help.',
          'I will hide the report.',
          'I will wait until next week.'
        ],
        0,
        'План і домовленості допомагають встигнути.'),
    JourneyQuestion(
        'boss:2',
        'Hannah: “Why is teamwork important?”',
        [
          'We can share ideas and solve problems together.',
          'It means nobody has responsibilities.',
          'It means every task is already finished.'
        ],
        0,
        'Teamwork — спільна робота та допомога.')
  ],
  'j12': [
    JourneyQuestion(
        'boss:0',
        'Ms Willow: “Where did you find the map?”',
        [
          'Inside the green library book.',
          'Inside the airport luggage.',
          'Inside Hannah’s report.'
        ],
        0,
        'Мапа була на сьомій сторінці зеленої книжки.'),
    JourneyQuestion(
        'boss:1',
        'Ms Willow: “Why did you choose the greenhouse?”',
        [
          'Plants get water there, but the roof keeps people dry.',
          'There are no plants there.',
          'It is where planes depart.'
        ],
        0,
        'Поясни, як підказка привела до теплиці.'),
    JourneyQuestion(
        'boss:2',
        'Ms Willow: “What happens next in your story?”',
        [
          'Meku plants a seed and invites her friends to the garden.',
          'Return ticket means library.',
          'The schedule is a responsibility.'
        ],
        0,
        'Це зв’язне продовження історії про сад.')
  ],
};

List<Scenario> freeJourneyScenes(JourneyLevel level) {
  final source = level.opponent!;
  final scenes = switch (level.id) {
    'j4' => [
        (
          'Загублений багаж',
          'Find your missing suitcase. Describe its colour and where you last saw it.',
          'Hello! I hear your suitcase is missing. Can you describe it?'
        ),
        (
          'Змінився рейс',
          'Ask about a delayed flight and work out a new travel plan.',
          'Your flight is delayed. Where do you need to go today?'
        ),
        (
          'Знайомство в подорожі',
          'Have a friendly conversation about travel, places and plans.',
          'Welcome! What place would you like to visit next?'
        )
      ],
    'j8' => [
        (
          'Перший день у команді',
          'Introduce yourself, ask about responsibilities and get to know the team.',
          'Welcome to your first day! What would you like to know about our team?'
        ),
        (
          'Дедлайн під загрозою',
          'Negotiate priorities and ask for help with a project deadline.',
          'Our report is due tomorrow, but we still have work to do. What should we prioritise?'
        ),
        (
          'Твоя ідея',
          'Pitch a simple idea that improves teamwork. Explain why it would help.',
          'I would love to hear your idea for improving our team. What do you suggest?'
        )
      ],
    _ => [
        (
          'Придумай історію',
          'Co-create a story with the learner, taking turns one or two sentences at a time.',
          'Let’s invent a story! Meku finds a mysterious letter. What happens next?'
        ),
        (
          'Допомога з уроком',
          'Teach English through a friendly conversation. Ask what topic they find difficult and give a brief example.',
          'Hello! What would you like to practise together today?'
        ),
        (
          'Клуб допитливих',
          'Talk about books, discoveries and hobbies. Encourage curious questions.',
          'Welcome to our curious club! What interesting thing have you discovered recently?'
        )
      ],
  };
  return [
    for (var i = 0; i < scenes.length; i++)
      Scenario(
          customId: 'journey-free-${level.id}-$i',
          voiceProfileId: source.voiceKey,
          character: source.character,
          name: source.name,
          role: source.role,
          title: scenes[i].$1,
          goal: scenes[i].$2,
          opening: scenes[i].$3,
          personality: source.personality,
          level: 'A2',
          winTitle: 'Вдало поговорили!',
          color: source.color,
          backdrop: source.backdrop)
  ];
}
