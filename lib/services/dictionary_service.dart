import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'learning_service.dart';
import 'vocabulary_service.dart';
import 'ai_service.dart';

const wordIpa = {
  'boarding pass': '/ˈbɔːrdɪŋ pæs/',
  'purpose': '/ˈpɜːrpəs/',
  'accommodation': '/əˌkɑːməˈdeɪʃən/',
  'return ticket': '/rɪˈtɜːrn ˈtɪkɪt/',
  'luggage': '/ˈlʌɡɪdʒ/',
  'departure': '/dɪˈpɑːrtʃər/',
  'declare': '/dɪˈkler/',
  'stay': '/steɪ/',
  'experience': '/ɪkˈspɪriəns/',
  'responsibility': '/rɪˌspɑːnsəˈbɪləti/',
  'achievement': '/əˈtʃiːvmənt/',
  'deadline': '/ˈdedlaɪn/',
  'strength': '/streŋθ/',
  'challenge': '/ˈtʃælɪndʒ/',
  'improve': '/ɪmˈpruːv/',
  'teamwork': '/ˈtiːmwɜːrk/',
};
const offlineDictionary = [
  WordCard(
      'd1', 'coffee', 'кава', 'Could I have a coffee, please?', 'Їжа й кава',
      transcription: '/ˈkɔːfi/'),
  WordCard('d2', 'water', 'вода', 'A glass of water, please.', 'Їжа й кава',
      transcription: '/ˈwɔːtər/'),
  WordCard('d3', 'menu', 'меню', 'May I see the menu?', 'Їжа й кава',
      transcription: '/ˈmenjuː/'),
  WordCard('d4', 'bill', 'рахунок', 'Could we have the bill?', 'Їжа й кава',
      transcription: '/bɪl/'),
  WordCard('d5', 'order', 'замовляти; замовлення', 'Are you ready to order?',
      'Їжа й кава',
      transcription: '/ˈɔːrdər/'),
  WordCard('d6', 'please', 'будь ласка', 'One tea, please.', 'Основи',
      transcription: '/pliːz/'),
  WordCard('d7', 'hello', 'привіт', 'Hello! How are you?', 'Основи',
      transcription: '/həˈloʊ/'),
  WordCard('d8', 'thanks', 'дякую', 'Thanks for your help.', 'Основи',
      transcription: '/θæŋks/'),
  WordCard('d9', 'help', 'допомога; допомагати', 'Could you help me?', 'Основи',
      transcription: '/help/'),
  WordCard('d10', 'passport', 'паспорт', 'Here is my passport.', 'Подорож',
      transcription: '/ˈpæspɔːrt/'),
  WordCard('d11', 'ticket', 'квиток', 'I need a train ticket.', 'Подорож',
      transcription: '/ˈtɪkɪt/'),
  WordCard('d12', 'visit', 'відвідувати; візит', 'I want to visit London.',
      'Подорож',
      transcription: '/ˈvɪzɪt/'),
  WordCard('d13', 'project', 'проєкт', 'Tell me about your project.', 'Робота',
      transcription: '/ˈprɑːdʒekt/'),
  WordCard('d14', 'meeting', 'зустріч', 'Our meeting starts at nine.', 'Робота',
      transcription: '/ˈmiːtɪŋ/'),
  WordCard('d15', 'proud', 'гордий', 'I am proud of my team.', 'Робота',
      transcription: '/praʊd/'),
  WordCard(
      'd16', 'work', 'робота; працювати', 'I work with a small team.', 'Робота',
      transcription: '/wɜːrk/'),
];

class DictionaryService {
  final VocabularyService vocabulary;
  final _ai = LearningService();
  DictionaryService(this.vocabulary);
  Future<({WordCard card, String source})> lookup(String input,
      {bool offline = false}) async {
    final word = input.trim().toLowerCase().replaceAll("’", "'");
    if (word.isEmpty ||
        word.length > 80 ||
        !RegExp(r"^[a-z][a-z '\-]*$").hasMatch(word)) {
      throw const AiException('Введи англійське слово або коротку фразу.');
    }
    for (final card in [...offlineDictionary, ...vocabulary.cards]) {
      if (card.word.toLowerCase() == word &&
          (card.transcription.isNotEmpty || wordIpa.containsKey(word))) {
        return (
          card: WordCard(
              card.id, card.word, card.translation, card.example, card.deck,
              transcription: card.transcription.isEmpty
                  ? wordIpa[word]!
                  : card.transcription),
          source: 'На пристрої'
        );
      }
    }
    final prefs = await SharedPreferences.getInstance();
    Map<String, dynamic> cache = {};
    try {
      cache = Map<String, dynamic>.from(
          jsonDecode(prefs.getString('dictionary_cache_v1') ?? '{}'));
    } catch (_) {}
    Map<String, dynamic>? data;
    if (cache[word] is Map) data = Map<String, dynamic>.from(cache[word]);
    if (data == null && offline) {
      final saved = vocabulary.cards.where((c) => c.word.toLowerCase() == word);
      if (saved.isNotEmpty) {
        return (
          card: saved.first,
          source: 'Твоя картка · транскрипцію можна додати вручну'
        );
      }
    }
    if (data == null) {
      if (offline) {
        throw const AiException(
            'Цього слова ще немає офлайн. Шукай слова з базового набору або вимкни офлайн-режим, щоб завантажити нове.');
      }
      data = await _ai.request(
          'Act as an English–Ukrainian learner dictionary. Return {"translation":"concise Ukrainian meaning","transcription":"IPA pronunciation in slashes","example":"short natural English sentence"}. For an unrecognised word return {"not_found":true}. Never invent definitions of unknown words.',
          {'word': word});
      if (data['not_found'] == true) {
        throw const AiException('Слово не знайдено. Перевір написання.');
      }
      for (final key in ['translation', 'transcription', 'example']) {
        if (data[key] is! String ||
            (data[key] as String).trim().isEmpty ||
            (data[key] as String).length > 500) {
          throw const AiException(
              'Неповна словникова відповідь. Спробуй ще раз.');
        }
      }
      if (cache.length >= 200) cache.remove(cache.keys.first);
      cache[word] = data;
      if (!await prefs.setString('dictionary_cache_v1', jsonEncode(cache))) {
        throw const AiException(
            'Не вдалося зберегти слово офлайн. Спробуй ще раз.');
      }
    }
    return (
      card: WordCard('lookup:$word', word, data['translation'], data['example'],
          'Мої слова',
          transcription: data['transcription']),
      source: 'Пояснення ШІ · збережено офлайн'
    );
  }

  void dispose() => _ai.dispose();
}
