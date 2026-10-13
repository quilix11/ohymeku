# Meku: personality, emotions and transparent assets

Implemented 2026-10-12 from the user's answers: playful, funny, clever, ironic and mildly tsundere. Teases situations gently, gives concrete help, does not shame the learner's mistakes. Reasonable frustration or criticism gets empathy and a sad expression. Gratuitous personal attacks get an offended expression and a short witty boundary, followed by help. Quotations and translation exercises are not personal attacks.

The model selects one of eight bounded emotions for each reply. Each assistant message stores its own emotion in the existing local chat history. The header and launcher show the latest mood; old histories and unknown values fall back to `smug`. Action receipts remain separate and come from the app's actual execution.

| Emotion | Drawing | Typical response |
| --- | --- | --- |
| happy | jumping fox | friendly help, a small success |
| excited | paws at cheeks, sparkles | breakthrough or a new goal |
| smug | half-lidded eyes | clever explanation, gentle irony |
| shy | paw at mouth, sweat droplets | own mistake or uncertainty |
| affectionate | hearts | gratitude, reassurance |
| playful | dancing, music notes | banter or a fun challenge |
| annoyed | narrowed eyes, steam | gratuitous personal insults |
| sad | tears | justified frustration or distress |

Asset editing used the built-in `image_gen.imagegen` tool with `transparent_background: true`. The exact initial and selected final prompts, source output paths and workspace destinations are in [EMOTION_ASSETS.json](EMOTION_ASSETS.json). All requested final assets are saved in the workspace:

- `assets/images/meku/meku_<emotion>.png`: eight poses, including the previously approved happy cutout.
- `assets/images/officer_cutout/officer_<emotion>.png`: nine active NPC states.
- `assets/images/hr_cutout/hr_<emotion>.png`: nine active NPC states.

Original portraits remain available. Each original neutral portrait was byte-identical to its angry counterpart, so those pairs share the same cutout contents. No new expression was invented for that alias.

All 26 final PNGs have real RGBA transparency (alpha extrema 0 and 255). Portraits use `BoxFit.contain` so ears, hats and hair buns remain inside their reserved space. Only visible images are decoded at capped widths. Motion honors the inherited reduced-motion setting; the settings row “Плавні анімації” was removed.

The generation request now supplies required structured fields for scenarios and exact array lengths for word sets, joins non-thinking text parts, decodes UTF-8 explicitly, accepts complete JSON code fences and optional finish metadata, and retries malformed/truncated output once. Partial scenario descriptions are still rejected before preview or save. Quota, network and blocked requests have separate messages and are not immediately retried. Reference: [Google's structured output documentation for Generate Content](https://ai.google.dev/gemini-api/docs/generate-content/structured-output).

Verification: 34 distinct service/widget checks passed, including generation preview/save/retry, emotion history, old chat compatibility, both themes and a 320px screen at 200% text with a keyboard. Dart analyzer passed; Flutter web build succeeded. Browser inspection confirmed transparent portraits and the removed animation row. The live synthetic request returned HTTP 429; actual model generation and nuanced sentiment behavior could not be evaluated while that external quota was exhausted. Mock responses verify the emotion rendering and persistence contract, not model understanding of tone.
