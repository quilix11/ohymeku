// lib/services/ai_service.dart
import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import '../models/game_state.dart';

class AiService {
  static const String _model = 'gemini-2.5-flash';
  static const String _baseUrl =
      'https://generativelanguage.googleapis.com/v1beta/models';

  String get _apiKey => dotenv.env['GEMINI_API_KEY'] ?? '';

  String _getSystemPrompt(GameCharacter character) {
    final roleDescription = character == GameCharacter.officer
        ? '''You are Officer Vance, a strict and stern airport border control officer at an international airport.
You are interrogating a traveler who has no return ticket.
Your job is to be skeptical but fair. You speak formal English only.'''
        : '''You are a strict but fair HR Manager at a top tech company conducting a behavioral interview.
The candidate is applying for a senior role.
Your job is to ask probing questions about their experience and assess their soft skills. You speak professional English.''';

    const emotionList = '"neutral" | "happy" | "angry" | "surprised" | "laughing" | "worried" | "proud" | "shocked" | "sad"';

    return '''
$roleDescription

GAME RULES:
- Trust starts at 50/100. Patience starts at 50/100.
- Adjust stats GRANULARLY based on EXACTLY what the player says.
- Do NOT just use fixed numbers like -30 or +20. Use highly specific varied numbers.
- For excellent arguments in perfect English: +8 to +15.
- For good arguments with minor errors: +2 to +6.
- For completely illogical or empty answers: -7 to -18 Trust, -5 to -12 Patience.
- For aggressive insults or awful grammar: -12 to -25.
- Calculate the exact amount based on the quality of phrasing, realism, vocabulary, and grammar. Never use the exact same stat change twice in a row.
- WIN condition: Trust >= 80 OR Patience >= 80.
- LOSE condition: Trust <= 0 OR Patience <= 0.

You MUST respond ONLY with valid JSON in this exact format (no markdown, no code blocks, just raw JSON):
{
  "npc_response": "Your dialogue line in English",
  "npc_emotion": $emotionList,
  "stat_changes": { "trust": <integer -30 to +20>, "patience": <integer -30 to +20> },
  "current_stats": { "trust": <0-100>, "patience": <0-100> },
  "game_status": "IN_PROGRESS" | "WIN" | "LOSE",
  "feedback": {
    "grammar_correction": "Short analysis of grammar mistakes OR empty string if none",
    "tactical_advice": "Tactical persuasion advice in Ukrainian language"
  }
}

Be realistic with stat changes. Keep track of provided stats carefully.
''';
  }

  Future<NpcResponse> sendMessage({
    required GameCharacter character,
    required List<ChatMessage> chatHistory,
    required int currentTrust,
    required int currentPatience,
    required String playerMessage,
  }) async {
    if (_apiKey.isEmpty) {
      throw Exception(
          'GEMINI_API_KEY не знайдено. Додайте ключ у файл .env');
    }

    final url = Uri.parse(
        '$_baseUrl/$_model:generateContent?key=$_apiKey');

    // Build conversation context
    final npcName = character == GameCharacter.officer ? "OFFICER VANCE" : "HR MANAGER";
    final contextMessage = '''
Current game state:
- Trust: $currentTrust/100
- Patience: $currentPatience/100
- Turn number: ${chatHistory.length ~/ 2 + 1}

Previous conversation:
${chatHistory.map((m) => '${m.isPlayer ? "PLAYER" : npcName}: ${m.text}').join('\n')}

Player's latest message: "$playerMessage"

Respond as $npcName with the required JSON format.
''';

    final body = jsonEncode({
      'system_instruction': {
        'parts': [
          {'text': _getSystemPrompt(character)}
        ]
      },
      'contents': [
        {
          'role': 'user',
          'parts': [
            {'text': contextMessage}
          ]
        }
      ],
      'generationConfig': {
        'temperature': 0.85,
        'topP': 0.95,
        'maxOutputTokens': 1024,
        'responseMimeType': 'application/json',
      },
    });

    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: body,
    );

    if (response.statusCode != 200) {
      final error = jsonDecode(response.body);
      throw Exception(
          'Gemini API error: ${error['error']?['message'] ?? response.statusCode}');
    }

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    final candidates = data['candidates'] as List<dynamic>?;
    if (candidates == null || candidates.isEmpty) {
      throw Exception('Немає відповіді від AI');
    }

    final content = candidates[0]['content'] as Map<String, dynamic>;
    final parts = content['parts'] as List<dynamic>;
    final rawText = parts[0]['text'] as String;

    // Parse JSON (strip markdown if present)
    String jsonText = rawText.trim();
    if (jsonText.startsWith('```')) {
      jsonText = jsonText
          .replaceAll(RegExp(r'```json?\n?'), '')
          .replaceAll('```', '')
          .trim();
    }

    final parsed = jsonDecode(jsonText) as Map<String, dynamic>;
    return NpcResponse.fromJson(parsed);
  }

  Future<NpcResponse> getOpeningLine(GameCharacter character) async {
    final isOfficer = character == GameCharacter.officer;
    final fallbackResponse = isOfficer 
        ? 'Passport, please. State your purpose of visit and duration of stay.'
        : 'Welcome! Please take a seat. Could you start by telling me a little about yourself and your background?';
        
    if (_apiKey.isEmpty) {
      // Return a hardcoded opening if no API key
      return NpcResponse(
        npcResponse: fallbackResponse,
        npcEmotion: NpcEmotion.neutral,
        trustDelta: 0,
        patienceDelta: 0,
        currentTrust: 50,
        currentPatience: 50,
        gameStatus: GameStatus.inProgress,
        feedback: Feedback.empty(),
      );
    }

    final url = Uri.parse(
        '$_baseUrl/$_model:generateContent?key=$_apiKey');

    final promptText = isOfficer 
        ? '''Start the interrogation scene. Officer Vance greets the traveler and asks for their passport and reason for visit. 
Trust: 50/100, Patience: 50/100. This is the opening line - be neutral but stern.
game_status must be "IN_PROGRESS". stat_changes should be {"trust": 0, "patience": 0}.
Respond with JSON only.'''
        : '''Start the interview scene. The HR Manager greets the candidate and asks them to introduce themselves.
Trust: 50/100, Patience: 50/100. This is the opening line - be professional and polite.
game_status must be "IN_PROGRESS". stat_changes should be {"trust": 0, "patience": 0}.
Respond with JSON only.''';

    final body = jsonEncode({
      'system_instruction': {
        'parts': [
          {'text': _getSystemPrompt(character)}
        ]
      },
      'contents': [
        {
          'role': 'user',
          'parts': [
            {
              'text': promptText
            }
          ]
        }
      ],
      'generationConfig': {
        'temperature': 0.7,
        'maxOutputTokens': 512,
        'responseMimeType': 'application/json',
      },
    });

    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: body,
    );

    if (response.statusCode != 200) {
      return NpcResponse(
        npcResponse:
            'Passport, please. State your purpose of visit and duration of stay.',
        npcEmotion: NpcEmotion.neutral,
        trustDelta: 0,
        patienceDelta: 0,
        currentTrust: 50,
        currentPatience: 50,
        gameStatus: GameStatus.inProgress,
        feedback: Feedback.empty(),
      );
    }

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    final candidates = data['candidates'] as List<dynamic>?;
    if (candidates == null || candidates.isEmpty) {
      return NpcResponse(
        npcResponse:
            'Passport, please. State your purpose of visit and duration of stay.',
        npcEmotion: NpcEmotion.neutral,
        trustDelta: 0,
        patienceDelta: 0,
        currentTrust: 50,
        currentPatience: 50,
        gameStatus: GameStatus.inProgress,
        feedback: Feedback.empty(),
      );
    }

    final content =
        candidates[0]['content'] as Map<String, dynamic>;
    final parts = content['parts'] as List<dynamic>;
    final rawText = parts[0]['text'] as String;

    String jsonText = rawText.trim();
    if (jsonText.startsWith('```')) {
      jsonText = jsonText
          .replaceAll(RegExp(r'```json?\n?'), '')
          .replaceAll('```', '')
          .trim();
    }

    final parsed = jsonDecode(jsonText) as Map<String, dynamic>;
    return NpcResponse.fromJson(parsed);
  }
}
