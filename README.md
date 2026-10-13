# Ohymeku

Flutter mobile app for practicing spoken English through short, AI-driven role-play conversations. The current scenarios are an airport border interview with Officer Vance and a job interview with HR Hannah. The interface includes Ukrainian coaching feedback.

## Run locally

Requirements: Flutter SDK with Dart 3, Android Studio/Xcode for device builds.

```powershell
flutter pub get
flutter run
```

The app reads `GEMINI_API_KEY` from a root `.env` file. Create it with:

```dotenv
GEMINI_API_KEY=your_key_here
```

`.env` is git-ignored. The app can show a fixed opening line without a key, but sending a player turn requires Gemini. Since this is a client app and `.env` is declared as a Flutter asset, a bundled API key can be extracted; use a backend proxy for a production release.

Text requests default to `gemini-3.5-flash-lite` with minimal thinking and a
20-second deadline that cancels the request. `GEMINI_MODEL` in `.env` overrides
the default. Only a missing model (404) retries once with `gemini-flash-lite-latest`;
quota, permission and overload errors are shown immediately with HTTP code,
provider status, actual model and a redacted provider explanation. Cloud speech
continues to use its separate TTS model. [Shared server gateway](gateway/README.md)
supports a server secret and atomic usage caps; it needs hosting access to deploy.
The public build accepts an optional `GEMINI_GATEWAY_URL` Actions variable, never
a shared API key.

## Project map

- `lib/main.dart` — startup, portrait lock, dotenv/settings/progress initialization, theme.
- `lib/screens/` — splash, scenario selection, game, profile, leaderboard and settings screens.
- `lib/models/game_state.dart` — game, chat, feedback and Gemini response models.
- `lib/models/user_profile.dart` — local player progress model.
- `lib/services/ai_service.dart` — Gemini REST requests and opening-line fallback.
- `lib/services/speech_service.dart` / `tts_service.dart` — speech recognition and spoken NPC replies.
- `lib/services/progress_service.dart` / `settings_service.dart` — local `SharedPreferences` persistence.
- `lib/widgets/` — reusable chat, input, avatar, navigation and HUD components.
- `assets/images/{officer,hr}/` — character portraits by emotion.

## Notes

### AI learning tools

- Non-English drafts go to a separate English tutor; suggestions never change game scores or enter NPC history. Latin-script input is also classified by Gemini, so spelling alone does not determine the language. Classification can be imperfect; the hint button is always available.
- Words → Generate by topic: choose topic, CEFR level and 5/8/12/16 cards; preview before saving. Generated decks persist separately from manual words.
- Character selection → Add person: generate a role, personality, objective, opening and nine original emotion portraits; preview/save, then play. Meku uses the same portrait generation when creating a character. Old characters without artwork keep their bundled portrait. Each character has independently saved system/cloud voice settings. History stores their actual names and IDs.
- Settings → Gemini voices: eight named choices, three speaking styles, speed and volume. System voices remain the default; cloud speech uses the existing GEMINI_API_KEY and its quota. Speech access must be enabled for that key. No silent fallback to a different voice provider.
- Fonts Lora and Manrope are bundled locally with OFL licenses under assets/fonts.
- API references: [Gemini speech generation](https://ai.google.dev/gemini-api/docs/speech-generation), [Gemini 2.5 Flash TTS model](https://ai.google.dev/gemini-api/docs/models/gemini-2.5-flash-preview-tts), [audioplayers](https://pub.dev/packages/audioplayers).

- The current visual style uses strawberry pink (#F9D1D9), matcha olive (#838F58), dark readable ink, rounded cards and a matching dark theme.
- The Words tab offers travel/work flashcards, custom words, examples, pronunciation, repeat/known choices and persisted learning progress.
- Each character has an independently saved system voice choice. Conversation meters include actual completed replies and unique words with adaptive practice targets.

- The menu has swipeable character cards, local practice history and an editable profile. Demo leaderboard/accounts and heart gating have been removed.
- `GameSession` owns turns, retries, locally calculated outcomes and idempotent XP awards. Characters open the conversation immediately.
- Settings persist dark/light theme, animation preference, voice volume/speed, US/UK recognition, pause duration and automatic voice submission. Voice and microphone previews use the actual platform services.
- `test/` covers session behavior, persistence and widget navigation. Platform microphone/voice support still needs device validation.
- Browser preview: `flutter build web`, then serve `build/web` over localhost. Phone builds require the corresponding platform SDK.
- See [`AGENTS.md`](AGENTS.md) for a compact architecture and behavior guide intended for coding assistants.

## Learning features (2026-10-11)

- **Placement:** 15 offline grammar questions, result by band, retake from Profile. This is a starting estimate, not a validated CEFR certification; listening/speaking are not tested.
- **Contextual grammar:** valid exercises returned with conversation feedback are saved locally; tap “Закріпити граматику”, or open Grammar from the home screen/Profile. Fifteen authored exercises are bundled for offline practice.
- **Adaptation:** after 8 answers, the last 12 answers can move difficulty one band above/below the selected baseline. This controls new conversation prompts, tutor hints, generation defaults and exercise ordering. Interests and weak placement topics influence exercise ordering. The baseline remains user-editable.
- **Spaced review:** word/exercise schedules persist. Correct answers return after 1, 3, then increasing intervals; mistakes after 10 minutes (words also return to the current queue). Vocabulary undo restores the previous review schedule.
- **Dictionary:** tap an English word in chat or use Words → search. Translation, IPA, example, pronunciation, save-to-cards. 32 authored starter entries work offline; new Gemini explanations are clearly labelled and cached (latest 200). Saved cards stay available independently of cache eviction.
- **Achievements:** unlock dates persist; broken streaks do not remove earned badges. Word and grammar practice count toward activity days and XP. XP is capped per item per local calendar day, including repeated attempts.
- **Interests:** predefined and custom interests, placement/settings picker, generation topic shortcuts and NPC prompt context.
- **Reminders:** opt-in local daily notifications for Android/iOS, selectable local time, permissions and reboot restoration on Android. Timezone is read through the native device channel and recalculated on app resume. Android uses inexact scheduling; OS power settings may delay delivery. These are local reminders, not server push campaigns.
- **Offline mode:** words, grammar, placement, saved history, authored/cached dictionary entries and downloaded speech. New AI conversations/generation/uncached dictionary entries need internet. Cloud audio is stored in application support storage, bounded to 20 MB (individual clips up to 4 MB); settings can clear it. System speech requires an installed English voice.
- **Voices:** independent choice and preview per built-in/custom character, eight actual cloud voice presets and installed English system voices. Automatic selection uses different system identities when available; fewer than two installed voices is explicitly reported. No cloud speech calls were made while implementing these changes.

### Implementation map

`learner_service.dart` owns placement, contextual exercises and grammar scheduling; `vocabulary_service.dart` owns the shared vocabulary and word scheduling. Settings owns both services so saved dictionary words cannot diverge across screens. `progress_service.dart` owns activity, permanent badges and XP. `dictionary_service.dart` provides local/cache/AI lookup. `notification_service.dart` uses the native `dialect_duel/device` timezone channel. `audio_cache_io.dart` stores bounded audio on mobile; the web stub has no persistent audio cache.

Device validation remains necessary: notification permission denial/revocation, scheduled delivery/reboot/timezone changes, system voice installation, microphone permissions, cloud voice access/quota, airplane-mode use, text scaling and phone layouts. iOS builds require macOS/Xcode. This Windows workspace currently has no Android SDK path configured in `android/local.properties`.

See [IMPLEMENTATION.md](IMPLEMENTATION.md) for storage and adaptation details. Notification setup follows the installed [flutter_local_notifications documentation](https://pub.dev/packages/flutter_local_notifications/versions/22.3.1).


## Ohymeku / Meku (2026-10-11)

Головний екран — огляд навчання з практикою та історіями розмов. Чотири розділи: Головна, Слова, Прогрес, Профіль. Meku — маскот і центральна кнопка-лисичка нижньої панелі; відкриває чат поверх поточного розділу, окремої вкладки немає. Палітра: Silk Milk `#F4ECEB`, Kiss Rose `#B76E79`; темніший рожевий використовується для читабельних кнопок і тексту. Маскот — наданий користувачем аркуш поз у `assets/images/meku.png`.

Meku використовує наявний Gemini-ключ, отримує останні 20 повідомлень і навчальний контекст. Локально зберігаються до 60 повідомлень. У режимі офлайн мережеві запити заблоковані. Команди можуть змінювати рівень, тему, параметри навчання/озвучення, інтереси, ім’я, нагадування, додавати слова та відкривати розділи. Кожна дія проходить перевірку типу й допустимих значень; результат показує застосунок. Доступу до файлової системи, довільного коду або редагування XP у моделі немає.

Ручна зміна рівня починає нове вікно адаптації, зберігаючи історію повторень і результати placement. Нові відповіді знову формують адаптацію. Уже розпочаті ігрові сесії не перебудовуються.

Аудит і наступні кроки: [OHYMEKU_REVIEW.md](OHYMEKU_REVIEW.md).

## GitHub Pages and personal Gemini access

The Pages workflow builds Flutter 3.41.6 with base path `/ohymeku/` and deploys
on pushes to `main`. GitHub Settings → Pages must use **GitHub Actions** as its
source. The public build contains an empty `.env`; no repository or Actions
secret is copied into the website. In the app, open Settings → Gemini and enter
your own Google AI Studio key. It stays in memory for that browser session,
is sent only to Google's API, and must be entered again after a reload.
Local development can still use the ignored `.env` file.

New characters use Gemini Nano-Banana 2 Lite (`gemini-3.1-flash-lite-image`) through
the Interactions API. `GEMINI_IMAGE_MODEL` can override that model locally. Two
bundled character portraits serve as style references. One request creates a
3×3 sheet in this order: neutral, happy, angry, surprised, laughing, worried,
proud, shocked, sad. The app removes a flat green backdrop, checks that each cell
contains both foreground and transparency, and saves nine bounded 256px PNGs.
Prompts request no visible labels, signatures or watermarks; Google's invisible
provenance marking remains under Google's control. Actual image quality and
identity consistency still need review on the character card.

Portraits persist with the character, including archive/restore and offline use.
Character metadata saves immediately; nine portraits generate in a separate,
persisted serial queue. You can start chatting while they load. Image failures
keep the character, show the cause, and offer retry on its portrait. Pending jobs
resume after reopening with Gemini connected; they cannot run with the browser
closed. Browser storage is finite; a full store exposes an image save error.
Generation requires access to the image model, internet and available quota.
Automated tests use synthetic images and mocked API responses; they do not
establish live Google model access or generate billable portraits.
