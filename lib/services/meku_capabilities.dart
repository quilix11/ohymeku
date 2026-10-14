/// One catalogue for the assistant's real app tools. The executor still
/// validates every argument; model text never directly mutates app state.
const mekuCapabilities = [
  {
    'type': 'create_cards',
    'description':
        'Actually generate and save vocabulary FLASHCARDS / карточки / картки / слова / a deck for a topic. These are the same app feature, not separate unsupported objects.',
    'value':
        '{topic:string (required), count:integer 1..50 (default app.card_count), level:A1/A2/B1/B2/C1 (default app.level)}'
  },
  {
    'type': 'create_character',
    'description':
        'Actually generate and save a custom conversation character and situation.',
    'value':
        '{topic:string (required), level:A1/A2/B1/B2/C1 (default app.level), warm:boolean (default true)}'
  },
  {
    'type': 'start_conversation',
    'description':
        'Open a conversation with an existing built-in or custom character.',
    'value': 'scenario_id from app.characters'
  },
  {
    'type': 'review_words',
    'description':
        'Start flashcard practice, optionally for a particular saved deck, including known cards if requested.',
    'value':
        '{deck:string from app.decks (default all), all:boolean (default false)}'
  },
  {
    'type': 'dictionary',
    'description':
        'Look up an English word, translate it, show IPA and pronunciation in the dictionary.',
    'value': 'English word or phrase'
  },
  {
    'type': 'add_word',
    'description':
        'Save one English word/phrase with its Ukrainian meaning and example.',
    'value':
        '{word:string,translation:string,example:string,transcription:string optional}'
  },
  {
    'type': 'edit_word',
    'description':
        'Edit a custom saved flashcard. Built-in entries cannot be overwritten.',
    'value':
        '{id:custom word id,word:string,translation:string,example:string,transcription:string optional}'
  },
  {
    'type': 'delete_word',
    'description': 'Move one custom flashcard to the recoverable archive.',
    'value': 'custom word id'
  },
  {
    'type': 'restore_word',
    'description': 'Restore a flashcard from the archive.',
    'value': 'archived word id'
  },
  {
    'type': 'word_known',
    'description':
        'Mark one word as known or needing review; this does not award practice XP.',
    'value': '{id:word id,known:boolean}'
  },
  {
    'type': 'edit_character',
    'description':
        'Edit the name, role, goal, opening, personality or level of a saved custom character.',
    'value':
        '{id:custom scenario id,name:string optional,role:string optional,goal:string optional,opening:string optional,personality:string optional,level:string optional}'
  },
  {
    'type': 'delete_character',
    'description': 'Move one custom character to the recoverable archive.',
    'value': 'custom scenario id'
  },
  {
    'type': 'restore_character',
    'description': 'Restore a custom character from the archive.',
    'value': 'archived scenario id'
  },
  {
    'type': 'reading_search',
    'description':
        'Find real articles and open the reading library. Translate the desired topic to a short English search query.',
    'value': 'English search query'
  },
  {
    'type': 'read_article',
    'description':
        'Open a downloaded or authored article; words can be translated and saved, then a quiz checks comprehension.',
    'value': 'article_id from app.articles'
  },
  {
    'type': 'reading_bookmark',
    'description': 'Save or remove a reading bookmark for an existing article.',
    'value': '{id:article_id,saved:boolean}'
  },
  {
    'type': 'navigate',
    'description': 'Open a section of the app.',
    'value':
        'journey/conversations/words/progress/profile/settings/practice/placement/generation/character_generation/reading'
  },
  {
    'type': 'level',
    'description':
        'Set learning level; raise/lower one band from app.level, clamp at A1/C1.',
    'value': 'A1/A2/B1/B2/C1'
  },
  {
    'type': 'card_count',
    'description': 'Set default size for new vocabulary sets.',
    'value': '5/8/12/16'
  },
  {
    'type': 'adaptive',
    'description': 'Enable/disable adaptive exercise difficulty.',
    'value': 'boolean'
  },
  {
    'type': 'coaching',
    'description': 'Show/hide explanations and coaching.',
    'value': 'boolean'
  },
  {
    'type': 'offline_mode',
    'description':
        'Enable/disable offline mode. Network features require false.',
    'value': 'boolean'
  },
  {
    'type': 'tts',
    'description': 'Enable/disable spoken character replies.',
    'value': 'boolean'
  },
  {
    'type': 'auto_send',
    'description': 'Enable/disable sending after microphone silence.',
    'value': 'boolean'
  },
  {
    'type': 'cloud_voices',
    'description': 'Use Gemini voices or system voices.',
    'value': 'boolean'
  },
  {
    'type': 'animations',
    'description': 'Set the existing saved motion preference.',
    'value': 'boolean'
  },
  {
    'type': 'tts_speed',
    'description': 'Set speech speed.',
    'value': 'number 0.25..0.8'
  },
  {
    'type': 'tts_volume',
    'description': 'Set speech volume.',
    'value': 'number 0..1'
  },
  {
    'type': 'voice_pitch',
    'description': 'Set system voice pitch.',
    'value': 'number 0.7..1.3'
  },
  {
    'type': 'text_scale',
    'description': 'Set app text size, e.g. 1.2 for 120%.',
    'value': 'number 0.9..1.3'
  },
  {
    'type': 'voice_style',
    'description': 'Set cloud speech expression.',
    'value': 'calm/friendly/expressive'
  },
  {
    'type': 'character_voice',
    'description':
        'Choose a per-character voice. For cloud use app.cloud_voice_options; for system use an exact id from app.system_voice_options, or null for the default.',
    'value': '{id:scenario_id,cloud:boolean,voice:string or null}'
  },
  {
    'type': 'speech_locale',
    'description': 'Set microphone English dialect.',
    'value': 'en_US/en_GB'
  },
  {
    'type': 'pause_seconds',
    'description': 'Set microphone silence pause.',
    'value': 'integer 2..5'
  },
  {
    'type': 'interest_add',
    'description':
        'Add one interest. Built-in IDs: Travel/Food/IT/Business/Movies/Music/Sport/Art; custom interests also allowed.',
    'value': 'string'
  },
  {
    'type': 'interest_remove',
    'description': 'Remove one existing interest.',
    'value': 'string'
  },
  {
    'type': 'interests_set',
    'description': 'Replace all interests with the requested list.',
    'value': 'array of 0..20 strings'
  },
  {
    'type': 'profile_name',
    'description': 'Change the local profile name.',
    'value': 'string 1..60 characters'
  },
  {
    'type': 'profile_avatar',
    'description': 'Choose a local profile icon.',
    'value': 'integer 0..3'
  },
  {
    'type': 'reminder_time',
    'description': 'Set local reminder time.',
    'value': 'HH:MM'
  },
  {
    'type': 'reminders',
    'description':
        'Enable/disable daily reminders. Enabling may ask the OS for permission; supported on Android/iOS only.',
    'value': 'boolean'
  },
];

const mekuNavigationTypes = {
  'navigate',
  'start_conversation',
  'review_words',
  'dictionary',
  'reading_search',
  'read_article'
};
