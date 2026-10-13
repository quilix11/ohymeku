enum MekuEmotion {
  happy,
  excited,
  smug,
  shy,
  affectionate,
  playful,
  annoyed,
  sad;

  static MekuEmotion parse(Object? value) =>
      values.firstWhere((emotion) => emotion.name == value, orElse: () => smug);

  String get asset => 'assets/images/meku/meku_$name.png';
  String get label => switch (this) {
        happy => 'Радіє',
        excited => 'У захваті',
        smug => 'Хитро усміхається',
        shy => 'Ніяковіє',
        affectionate => 'Підтримує',
        playful => 'Пустує',
        annoyed => 'Ображена',
        sad => 'Співчуває',
      };
}
