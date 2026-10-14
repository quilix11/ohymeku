# Coding assistant context

Read this map before exploring; inspect target source before edits.

## Learning expansion (2026-10-11, supersedes older details below)
- `SettingsService` owns shared `vocabulary` and `learner`; do not create/dispose competing vocabulary instances in screens.
- `placement_screen.dart`: 15 offline questions, interests, approximate result and retake from Profile. `main.dart` gates new users on placement completion; existing completion flags remain compatible.
- `learning_exercise.dart`: independent authored placement/practice banks and validated contextual exercise JSON.
- `learner_service.dart`: saved placement, last 12 grammar answers, one-band adaptive difficulty after >=8 answers, due exercise queue, hashed contextual IDs. `settings.effectiveLevel` drives new sessions, tutor and generation defaults.
- `practice_screen.dart`: offline grammar, contextual focus from chat, saved explanations, review schedule. Word/exercise successes: 1d,3d,increasing; failures:10min. Word queue also retries immediately at end; undo restores old schedule.
- `dictionary_service.dart`/`dictionary_sheet.dart`: local starter entries, saved words, bounded 200-entry AI cache, IPA/examples/add/pronunciation. AI entries labelled. Chat recognizers now disposed.
- `progress_service.dart`: permanent achievement timestamps, historical streak migration, per-item/day XP and grammar/card activity dates.
- `interest_picker.dart`: predefined/custom interests shared by onboarding/settings; generation topic chips.
- `notification_service.dart`: Android/iOS only, user opt-in, selectable wall-clock time, inexact Android schedule. Native `dialect_duel/device` channel supplies IANA timezone; reschedule on app resume. Android manifest receivers, desugaring, white icon; iOS notification delegate.
- Separate system/cloud voice choices keyed by scenario ID; custom characters get cloud defaults from the voice pool. `audio_cache_io.dart` persists up to 20MB audio with SHA-256 filenames; web uses a stub. Offline mode forbids uncached cloud requests.
- Theme: strawberry #F9D1D9 / matcha #838F58 with darker ink; bundled Lora/Manrope. No runtime font fetch.
- No on-device validation or automated tests were performed during this expansion. See README/IMPLEMENTATION for exact offline limits and follow-up checks.


## Active architecture
- `api_credentials.dart`: personal Gemini key in session memory; local dotenv fallback. Public Pages builds include no API key; optional compile-time GEMINI_GATEWAY_URL routes shared requests to gateway/worker.mjs. Personal keys take precedence.
- `character_portrait_service.dart`: Gemini Interactions image request with two style references; nine-emotion sheet, chroma removal and bounded transparent PNGs. `SettingsService` owns a persisted serial background queue for all new characters, including Meku tools. `LearningService.generate` returns metadata immediately. Preserve portrait status/error as well as artwork; scenario writes are serialized.
- `Scenario.portraits` persists artwork; `ScenarioPortrait` renders generated emotion PNGs with legacy bundled fallback. Preserve portraits when editing/archiving/restoring a scenario.
- `services/learning_service.dart`: separate Gemini JSON calls for language routing/tutor suggestions and generating vocabulary or characters. `screens/generation_screen.dart` previews before save.
- `AiService.sendMessage` classifies Latin-script input and generates the NPC reply in ONE request. `TutorRequired` carries validated `LanguageHelp`; `GameSession` restores confirmed history without changing meters/feedback/XP and exposes `tutorHelp`. Missing classification is a retryable error. `GameScreen._prepareInput` reserves separate tutor calls for Cyrillic/other scripts and the explicit lightbulb. Both normal send and retry present tutor results; suggestions only insert drafts, never auto-send. Check offline mode even for inserted suggestions.
- Custom scenarios persist in SettingsService; optional Scenario customId/personality flow through GameScreen, GameSession, AiService. PracticeRecord stores scenarioId/scenarioName, and wins are scoped by ID. Old saves remain compatible.
- `cloud_speech_service.dart`: Gemini 2.5 Flash preview TTS, WAV/PCM decoding, audioplayers playback, request cancellation and six-item session cache. Off by default; shares existing Gemini key. Separate voice choices per existing avatar profile. Custom characters have independent saved voice settings.
- Local Lora/Manrope fonts in assets/fonts with OFL licenses. Additional saved settings: learning level, deck size, tutor coaching visibility, text scale, pitch, cloud voice/style.
- `main.dart`: dotenv, settings/progress initialization, portrait orientation, animated light/dark theme; opens MainScreen directly.
- `screens/main_screen.dart`: lazy IndexedStack for adventure, vocabulary, progress and top-bar profile; bottom Meku opens its chat overlay. Settings use a gear icon. Character library opens over the adventure, never replaces it.
- `SettingsService.journey` owns `journey_service.dart`: serialized word/challenge/test/boss saves in journey_v2. Twelve levels, three worlds; two words + two reading checks + ordered sentence + 4/5 test gate completion; levels 4/8/12 also require a boss seal. V1 completed prefixes migrate without resetting stars; partial saves still require quests. Canonical validation and persistence precede state changes. Stars cap at 36; do not duplicate XP.
- `journey_story.dart`: authored story passages, word bridges, boss dialogues and three free scenarios per boss. Free chat scenario IDs differ from boss IDs and never award a seal.
- `journey_screen.dart`: responsive trail, inline free conversation cards, finite Meku walking animation, reduced motion. `journey_level_screen.dart` / `journey_quest_screen.dart` own local word/story/grammar UI. `journey_boss_screen.dart` offers clearly distinct live AI and authored dialogue modes.
- `GameSession.savedRecord` exists only after successful history persistence; optional `GameScreen.onVictory` records the matching journey boss seal on leaving a won conversation. Failed seal writes keep the conversation open for retry. No claim of CEFR certification.
- `willow_portrait.dart`: original vector teacher illustration with emotion states; `ScenarioPortrait` uses it for the built-in journey teacher and her free scenes.
- `screens/vocabulary_screen.dart`, `services/vocabulary_service.dart`: 24 built-in travel/work/school cards plus custom cards; shared persisted known/repeat queues.
- AppThemeMode indices light=0/dark=1 are preserved; appended system=2 is the new default. MaterialApp and system UI follow platform brightness in automatic mode; manual choices remain fixed.
- `widgets/conversation_meters.dart`: trust/patience plus confirmed turn and unique English word counters. Practice targets grow with prior character wins; these counters are not language proficiency scores.
- `tts_service.dart` caches English voice discovery; `settings_service.dart` stores a separate voice ID for each character. Pitch/rate defaults differ. Voice availability depends on the OS/browser.
- Performance: no per-frame carousel builders/opacity layers, image decode width capped, no precaching all emotions, no whole-game rebuild while typing, cached themes updated only for appearance settings.
- `screens/character_selection_screen.dart`: swipe carousel, remembered selection, start button and settings entry.
- `models/scenario.dart`: Officer Vance / Hannah metadata, authored opening, portrait asset mapping.
- `services/game_session.dart`: match state, locked sends, confirmed history, retry, locally computed outcome, idempotent save/XP, restart/dispose.
- `services/ai_service.dart`: Gemini 2.5 Flash-Lite via cancellable HTTP with a 20-second text budget and redacted provider errors, JSON parsing, bounded deltas, emotion and Ukrainian feedback; key in request header.
- `screens/game_screen.dart`: chat, input, persistent character stage, audio/mic controls, inline results.
- `models/practice_record.dart`, `services/progress_service.dart`: local JSON records, profile name/avatar, XP and calendar streak from actual practice dates.
- `services/settings_service.dart`: persisted light/dark, animation toggle, TTS enabled/rate/volume, US/UK speech locale, pause and auto-send.
- `screens/settings_screen.dart`: real settings, speech preview and microphone transcript preview.
- `services/tts_service.dart`, `speech_service.dart`: lazy platform voice services; typed play works independently.
- `widgets/npc_avatar.dart`: emotion crossfade; asset pattern `assets/images/<officer|hr>/<prefix>_<emotion>.png`.
- `theme/app_theme.dart`: both themes, semantic colors and typography.

## Behavior and limitations
- NPC opening appears immediately. Player turns require GEMINI_API_KEY from optional .env.
- Trust/patience start at 50; delta clamped to [-25,15], score to [0,100]. Local loss at zero takes precedence over win at 80.
- Retry removes failed pending player text from API history. Session IDs prevent duplicate XP.
- No fake account, league, leaderboard or heart gate. Progress tab uses real local records. Legacy model/widgets still exist; active flow above is authoritative.
- Theme enum order light/dark is persisted by index; preserve it.
- Microphone locale/pause behavior and TTS voices depend on platform support. Settings are applied to subsequent utterances.
- .env is bundled as an asset: production needs server-side Gemini proxy. Do not print secrets.
- PROJECT_AUDIT.md describes the earlier implementation, not a current defect inventory.

## Development
- Flutter/Dart, dependencies/assets in pubspec.yaml.
- Web: flutter build web; serve build/web over localhost. Android/iOS requires its SDK.
- test/game_session_test.dart covers outcome/retry/persistence; test/widget_test.dart covers menus, profile and chat. Native voice needs device validation.
- Keep existing user changes and inspect source around the target before editing.
