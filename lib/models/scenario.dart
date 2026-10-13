import 'package:flutter/material.dart';
import 'game_state.dart';
import 'dart:convert';

class Scenario {
  final String? customId;
  final String personality;
  final Map<String, String> portraits;
  final GameCharacter character;
  final String name, role, title, goal, opening, level, winTitle;
  final Color color, backdrop;
  const Scenario(
      {this.customId,
      this.personality = '',
      this.portraits = const {},
      required this.character,
      required this.name,
      required this.role,
      required this.title,
      required this.goal,
      required this.opening,
      required this.level,
      required this.winTitle,
      required this.color,
      required this.backdrop});
  Map<String, dynamic> toJson() => {
        'id': customId,
        'character': character.name,
        'name': name,
        'role': role,
        'goal': goal,
        'opening': opening,
        'level': level,
        'personality': personality,
        if (portraits.isNotEmpty) 'portraits': portraits,
      };
  factory Scenario.fromJson(Map<String, dynamic> json) => Scenario(
      customId: json['id'] as String,
      character: GameCharacter.values.byName(json['character'] as String),
      name: json['name'] as String,
      role: json['role'] as String,
      title: json['name'] as String,
      goal: json['goal'] as String,
      opening: json['opening'] as String,
      level: json['level'] as String,
      personality: json['personality'] as String? ?? '',
      portraits: parsePortraits(json['portraits']),
      winTitle: 'Вдало поговорили!',
      color: const Color(0xFF8F4856),
      backdrop: const Color(0xFFECD6D9));

  static Map<String, String> parsePortraits(Object? value) {
    if (value is! Map) return const {};
    final images = <String, String>{};
    for (final emotion in NpcEmotion.values) {
      final image = value[emotion.name];
      if (image is! String ||
          image.length > 256000 ||
          !image.startsWith('data:image/png;base64,')) {
        continue;
      }
      try {
        final bytes = base64Decode(image.substring(22));
        if (bytes.length >= 8 &&
            bytes[0] == 137 &&
            bytes[1] == 80 &&
            bytes[2] == 78 &&
            bytes[3] == 71) {
          images[emotion.name] = image;
        }
      } on FormatException {
        /* Old or damaged artwork uses the bundled portrait. */
      }
    }
    return Map.unmodifiable(images);
  }

  String image(NpcEmotion emotion) {
    final folder = character.name;
    return 'assets/images/${folder}_cutout/${folder}_${emotion.name}.png';
  }

  static const all = [
    Scenario(
        character: GameCharacter.officer,
        name: 'Officer Vance',
        role: 'ПРИКОРДОННИК',
        title: 'Наступна зупинка —\nтвоя англійська.',
        goal:
            'Ти в аеропорту без зворотного квитка. Поясни мету подорожі та переконай офіцера пропустити тебе.',
        opening:
            'Good afternoon. Passport, please. I see you have no return ticket. What brings you here, and how long do you plan to stay?',
        level: 'Подорожі · A2–B1',
        winTitle: 'Вітаємо за кордоном!',
        color: Color(0xFF8F4856),
        backdrop: Color(0xFFF0DDE0)),
    Scenario(
        character: GameCharacter.hr,
        name: 'Hannah',
        role: 'HR-МЕНЕДЖЕРКА',
        title: 'Твоя наступна\nвелика можливість.',
        goal:
            'Ти на співбесіді на senior-позицію. Розкажи про досвід і доведи, що вмієш працювати з людьми.',
        opening:
            'Hi, I am Hannah. Thanks for coming in! Tell me about a project you are proud of and the role you played in it.',
        level: 'Кар’єра · B1–B2',
        winTitle: 'Ти справив враження!',
        color: Color(0xFF864C5B),
        backdrop: Color(0xFFECD6D9)),
  ];
  static Scenario of(GameCharacter character) =>
      all.firstWhere((scenario) => scenario.character == character);
}

String emotionLabel(NpcEmotion emotion) => switch (emotion) {
      NpcEmotion.neutral => 'Уважно слухає',
      NpcEmotion.happy => 'Задоволений',
      NpcEmotion.angry => 'Сердиться',
      NpcEmotion.surprised => 'Здивований',
      NpcEmotion.laughing => 'Сміється',
      NpcEmotion.worried => 'Сумнівається',
      NpcEmotion.proud => 'Вражений',
      NpcEmotion.shocked => 'Приголомшений',
      NpcEmotion.sad => 'Розчарований',
    };
