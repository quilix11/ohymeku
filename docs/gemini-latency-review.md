# Gemini request comparison

Reviewed the first commit `0b454ca` against `db3158c` on 2026-10-13.

| Path | First commit | Before this fix |
| --- | --- | --- |
| Ordinary NPC turn | 1 Gemini request | 2 sequential requests: language tutor, then NPC |
| Initial NPC opening | 1 request when a key exists | 0 requests; authored opening |
| Meku | Not implemented | 1 planning request, then additional calls only for generation actions |
| Default text model | `gemini-2.5-flash` | `gemini-3.5-flash-lite`, then Lite alias only on 404 |
| NPC output token ceiling | 1024 | 4096 |
| JSON configuration | `responseMimeType` | `responseFormat` |

Two sequential requests add a second network round trip and inference wait.
Meku has a larger instruction, tool catalogue and app context than the original
NPC-only app. Its context redundantly included the first 100 saved words, already
present in the 180-entry word catalogue. The output token ceiling is a maximum,
not the number actually generated; raising it does not prove a proportional
latency increase. Different models, credentials, quotas and networks also prevent
inferring provider timing solely from this comparison.

The current Google discovery schema supports both JSON configuration fields.
An unauthenticated OPTIONS request from the Pages origin returned HTTP 200 and
allowed `content-type,x-goog-api-key`. This checks preflight compatibility, not
model access, account quota, mobile connectivity or authenticated latency.

## Resulting changes

Ordinary turns now classify the language and produce either a tutor draft or an
NPC reply in one request. A tutor response cannot change history, meters, turn
counts, feedback or XP, even if it contains fabricated WIN/stat fields. Missing
classification or incomplete suggestions become a retryable error. Cyrillic
and explicit help retain the dedicated tutor; selecting a suggestion never sends
it. Every send checks offline mode. The tutor's loading indicator stops as soon
as its response arrives, before displaying its suggestion sheet.

Meku no longer sends a duplicate word list; ordinary replies are instructed to
use 1–3 short sentences. Model selection, secure key headers and the 20-second
text deadline remain in place. Tests exercise request counts and UI routing with
synthetic provider replies; no authenticated before/after latency benchmark was
performed.
