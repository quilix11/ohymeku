# Shared Gemini gateway

This Worker keeps `GEMINI_API_KEY` on the server. The Pages app sends requests to
`GEMINI_GATEWAY_URL` when the user has no personal session key. No shared key is
bundled in Flutter, Pages assets, GitHub variables, or this repository.

The gateway is implemented and tested locally. It is **not deployed**: this task
has GitHub Pages access but no Cloudflare account or deployment credentials.
GitHub Pages serves static files and cannot run this gateway.

When hosting access exists, deploy from this directory with Cloudflare Wrangler:

```sh
npx wrangler secret put GEMINI_API_KEY
npx wrangler deploy
```

Enter a newly issued key through Wrangler's secret prompt, never in a command,
source file, or GitHub Pages build. Set repository Actions **variable**
`GEMINI_GATEWAY_URL` to the resulting HTTPS Worker URL, then rerun Pages deployment.
`GET /health` reports whether the server bindings are configured; it does not
make a paid Gemini request or verify the provider key.

The allowed browser origin is `https://quilix11.github.io`. CORS is not user
authentication: requests from other HTTP clients can forge Origin. Atomic quotas
bound shared use: daily caps of 200 text, 20 image and 80 speech requests across
all users; per-IP caps of 24 text/minute, 3 images/hour and 10 speech/minute.
Unsuccessful provider attempts consume quota as well. IP addresses are hashed
before storage and counters expire at midnight UTC. Limits are intentionally
fixed in server code; client input cannot select expensive models or disable them.

Text uses `gemini-2.5-flash-lite` with thinking disabled and a 20-second deadline.
A missing text model (404) falls back once to `gemini-flash-lite-latest` within
the same deadline; quota and permission failures never retry.
Portraits use `gemini-3.1-flash-lite-image` with a 120-second deadline.
Speech remains `gemini-2.5-flash-preview-tts`. Gemini billing, quota and model
availability still depend on the server key's project.

Character metadata saves immediately. The app owns a persisted, serial portrait
queue and supports retry without regenerating metadata. Generation continues
while the app is open and resumes pending jobs after reopening and reconnecting;
it does not keep running after the browser is closed. Image quality is checked
locally. Visible watermarks are excluded by the prompt; Gemini's invisible
SynthID cannot be removed or guaranteed absent.

Run gateway validation with `node --test gateway/worker.test.mjs` from repository
root. Tests simulate the provider; live Gemini and Cloudflare deployment require
working credentials.
