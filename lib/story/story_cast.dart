import 'package:flutter/material.dart';
import '../models/scenario.dart';
import '../models/game_state.dart';

final storyCast = <Scenario>[
  _person(
      'Nora',
      'Пекарка та колекціонерка марок',
      'Поговори про рецепти, листи й звичайне життя Люмена.',
      'The kettle is ready. What brings you to my bakery today?',
      'Warm, observant baker. Loves cinnamon and collecting stamps. You live in Lumen. No spoilers or hidden identities.'),
  _person(
      'Elias',
      'Провідник нічного потяга',
      'Сплануй подорож або розпитай про життя нічного вокзалу.',
      'Good evening! Where would you like to travel tonight?',
      'An anxious but kind train conductor in Lumen. Precise about tickets, loves travel stories. No spoilers about debts or family secrets.'),
  _person(
      'Iris',
      'Доглядачка маяка',
      'Допоможи Ірис підготувати маяк до нічного чергування.',
      'The sea looks calm, but we should check the lamp. Can you help?',
      'Brave practical lighthouse keeper. Warm dry humor, reads weather in ink. No plot spoilers.'),
  _person(
      'Sol',
      'Міський архіваріус',
      'Дізнайся про старі книжки й навчися шукати потрібний запис.',
      'Every letter has a story. Which one are you looking for?',
      'Quiet patient archivist in Lumen, enjoys careful questions. Never reveal plot twists or secret family history in free conversation.'),
  _person(
      'Lyra',
      'Мандрівниця зі світанкового мосту',
      'Познайомся з Лірою й запропонуй їй побачити світ.',
      'I would love to see somewhere new. Where should we go first?',
      'Curious gentle traveler, learning to enjoy ordinary life. Likes warm bread and new stories. No spoilers or claims that free chat changes the canon.'),
];
Scenario _person(String name, String role, String goal, String opening,
        String personality) =>
    Scenario(
        customId: 'cast_${name.toLowerCase()}',
        character: GameCharacter.hr,
        name: name,
        role: role,
        title: role,
        goal: goal,
        opening: opening,
        personality: personality,
        level: 'A2',
        winTitle: 'Тепла розмова',
        color: const Color(0xFF49319A),
        backdrop: const Color(0xFFE9E3FA));
