# Learning implementation notes

## Navigation
- Home school icon: grammar practice, including offline.
- Profile: grammar practice, placement retake, achievements, settings.
- Words: dictionary search, manual/generate cards, spaced review.
- Chat: tap a word for dictionary; coaching can open the specific contextual exercise.
- Settings: interests, adaptive difficulty, offline mode, reminder time, separate character voice presets/previews, cached audio cleanup.

## Storage (SharedPreferences, local device only)
- `learner_v1`: placement date/score/bands/topics, personal exercises, per-exercise attempts/success/streak/next date, last 12 results.
- `words_known_v1`, `words_custom_v1`: existing compatible vocabulary data.
- `word_reviews_v1`: per-word streak/lapses/next review. Existing known words without a schedule re-enter due review; no words are deleted.
- `dictionary_cache_v1`: at most 200 additional AI entries. Authored starter entries and saved cards are independent.
- `practice_progress_v2`: existing sessions/profile plus permanent achievement timestamps and per-calendar-day/item XP. Existing XP/session dedup remains intact.
- `scenario_voices`, `scenario_cloud_voices`: independent character voice overrides. Legacy built-in voice settings remain fallback values.
- `adaptive_learning`, `offline_mode`, `reminder_hour`, `reminder_minute`, `push_notifications`: persisted preferences.
- Native audio: app-support `voice_cache_v1`, SHA-256 keys of voice/style/transcript, WAV files, 20 MB total / 4 MB per clip. No API keys in audio cache keys. Web persistence is not implemented.

## Transparent algorithms
Placement has three questions per band A1–C1. Each successive band needs >=2 correct answers and all lower bands passed; A1 is the minimum. It is a small grammar screening, not a validated general proficiency assessment.

Adaptive difficulty is baseline plus at most one band: after >=8 attempts, last-12 accuracy >=85% increases it; <50% decreases it; otherwise baseline. The baseline is never silently overwritten. Exercise priority favours personal mistakes, due reviews, weak placement topics, proximity to level and selected interests. Trust/patience and RPG wins do not measure language ability.

Vocabulary and grammar use simple expanding intervals: success 1, 3, 9, 12… days (caps 60 for words, 30 for grammar), mistake 10 minutes. This is an explicit heuristic, not FSRS/SM-2. Vocabulary has an immediate retry queue as well. Repeated daily practice grants at most 5 XP per word / 10 per exercise; wrong answers grant 1 / 2 XP, upgraded only by the difference on later success. Conversation XP remains unchanged.

## Mobile delivery
Android: POST_NOTIFICATIONS permission, boot/package receivers, desugaring, notification drawable, platform timezone MethodChannel. iOS: notification-center delegate and timezone channel registered with implicit Flutter engine. Reminders use ID 0, no exact-alarm permission and no remote push server.

Confirm notification delivery and voice availability on physical Android/iPhone. Windows cannot compile iOS. No native SDK/device validation is claimed. New Gemini-generated content and voices need working service access; no paid API requests were run during implementation.

## Known boundaries
- Offline conversation AI is not included; offline mode routes home practice to authored/saved grammar and words.
- Dictionary ships 32 starter entries, not a complete licensed offline dictionary. AI definitions can be inaccurate and are labelled.
- The grammar bank is a starter set (15 practice + 15 separate placement items). Personal exercises extend it as the learner chats.
- Timezone changes while the app stays closed are reconciled on its next resume. Android battery policies can delay inexact reminders.
- Cloud clips larger than 4 MB play but are not saved to persistent cache. System speech availability is controlled by the phone.
- Existing client-bundled Gemini key remains a development architecture; production proxy is still needed.
