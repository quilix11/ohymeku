# 🛂 DialectDuel

> Conversational RPG for English speaking and negotiation skills training

## Concept

**DialectDuel** is a mobile RPG game where you train conversational English and negotiation soft skills by competing in dialogue with an AI boss (NPC).

### Scenario: Border Control
- **Boss**: Officer Vance - a strict airport border control officer
- **Your goal**: Explain in English why you have no return ticket and convince him to let you through
- **Stats**: Trust (50/100) + Patience (50/100)
- **Lives**: 3 hearts

---

## Architecture

```
lib/
├── main.dart                    # App entry point
├── theme/
│   └── app_theme.dart           # Dark game theme, colors, text styles
├── models/
│   └── game_state.dart          # GameState, NpcResponse, ChatMessage, Feedback
├── services/
│   ├── ai_service.dart          # Gemini 2.5 Flash API integration
│   ├── speech_service.dart      # STT via speech_to_text package
│   └── tts_service.dart         # TTS via flutter_tts package
├── screens/
│   ├── splash_screen.dart       # Intro / start screen
│   └── game_screen.dart         # Main game screen
└── widgets/
    ├── game_hud.dart            # Top HUD (avatar + stat bars + lives)
    ├── npc_avatar.dart          # Officer Vance avatar with emotion indicator
    ├── stat_bar.dart            # Animated Trust/Patience bars
    ├── chat_bubble.dart         # Chat message bubbles
    ├── coaching_box.dart        # Grammar & tactical feedback box
    ├── input_panel.dart         # Mic + text input controls
    └── mic_button.dart          # Animated microphone button
```

---

## Tech Stack

| Feature | Package |
|---------|---------|
| Framework | Flutter (Dart) |
| AI | Google Gemini 2.5 Flash (HTTP) |
| Speech-to-Text | speech_to_text ^7.0.0 |
| Text-to-Speech | flutter_tts ^4.2.0 |
| Animations | flutter_animate ^4.5.0 |
| Environment | flutter_dotenv ^5.2.1 |

---

## Setup

### 1. Get a Gemini API Key
1. Go to https://aistudio.google.com/
2. Click "Get API key"
3. Create a new key (free tier)

### 2. Configure .env
```
GEMINI_API_KEY=your_actual_api_key_here
```

### 3. Install dependencies
```
flutter pub get
```

### 4. Run the app
```
flutter run
```

---

## Gameplay

### Win Conditions
- Trust >= 80 OR Patience >= 80 -> Victory modal + XP + entry stamp

### Lose Conditions
- Trust <= 0 OR Patience <= 0 -> Defeat modal + -1 life + mistake breakdown

### Stat Changes (per turn)
| Player Action | Trust | Patience |
|---------------|-------|---------|
| Clear, logical explanation | +10 to +20 | +5 to +10 |
| Vague or confusing | -5 to -15 | -5 to -10 |
| Grammar mistakes | -5 to -10 | -5 |
| Rude or aggressive | -20 to -30 | -20 to -30 |

---

## Permissions

### Android
- RECORD_AUDIO - microphone for STT
- INTERNET - Gemini API calls

### iOS
- NSMicrophoneUsageDescription
- NSSpeechRecognitionUsageDescription

---

## Security Note
The .env file is in .gitignore. Never commit your API key to version control.
