# Deploying Agilance

Three deployables, matching the two git repos:

| Piece | Repo | Where | How |
|---|---|---|---|
| API (FastAPI) | `backend/` → `infiniterende/agilance-backend` | Render web service (Docker) | `backend/render.yaml` |
| Voice agent (LiveKit) | same repo | Render background worker | `backend/render.yaml` |
| Web app (Next.js) | `frontend/` → `infiniterende/agilance-frontend` | Vercel | `vercel` CLI or Git integration |

Database is Supabase Postgres (already provisioned). The API creates any
missing tables on startup (`pathway_evaluations`, `appointments`,
`doctor_notes` are new), so there is no separate migration step.

## 0. Before the first deploy

- Commit and push each repo (`backend/` and `frontend/` are separate git repos).
- Never put secrets in a `NEXT_PUBLIC_*` variable — those are shipped to the browser. Only `NEXT_PUBLIC_API_ENDPOINT` and `NEXT_PUBLIC_LIVEKIT_URL` belong there.
- Rotate any key that was ever committed or prefixed `NEXT_PUBLIC_`.

## 1. Backend on Render

1. Render dashboard → **New → Blueprint** → pick `agilance-backend`. Render reads `render.yaml` and creates `agilance-api` (web) and `agilance-voice-agent` (worker).
2. Fill in the secrets it asks for: `SUPABASE_DATABASE_URL`, `OPENAI_API_KEY`, `LIVEKIT_URL`, `LIVEKIT_API_KEY`, `LIVEKIT_API_SECRET`, `SECRET_KEY`.
3. Deploy. Check `https://<your-api>.onrender.com/api/pathway/catalog` returns JSON.
4. Add your Vercel domain to the CORS `origins` list in `backend/main.py` (it currently allows `*`; tighten it for production).

Every push to `main` redeploys (`autoDeploy: true`).

## 2. Frontend on Vercel

Set these in **Project → Settings → Environment Variables** (Production):

| Variable | Value |
|---|---|
| `NEXT_PUBLIC_API_ENDPOINT` | `https://<your-api>.onrender.com` |
| `NEXT_PUBLIC_LIVEKIT_URL` | `wss://<project>.livekit.cloud` |
| `DATABASE_URL` / `DIRECT_URL` | Supabase pooler / direct URLs (Prisma) |
| `NEXTAUTH_URL` | `https://<your-app>.vercel.app` |
| `NEXTAUTH_SECRET` | long random string (`openssl rand -base64 32`) |
| `LIVEKIT_API_KEY` / `LIVEKIT_API_SECRET` | server-side only, no `NEXT_PUBLIC_` |

Then either connect the GitHub repo (Vercel builds on every push) or deploy from the CLI:

```bash
cd frontend && vercel --prod
```

`NEXT_PUBLIC_*` values are baked in at build time, so changing them requires a redeploy.

## 3. Self-hosted alternative (one VM with Docker)

```bash
export NEXT_PUBLIC_API_ENDPOINT=https://api.example.org
export NEXTAUTH_URL=https://app.example.org
make prod-up            # builds images, runs backend :8000 + frontend :3000
make prod-down
```

Put a reverse proxy with TLS (Caddy, nginx, or the cloud load balancer) in
front of both ports. `backend/.env` and `frontend/.env.local` are read by
compose exactly as in development.

## Smoke test after deploy

1. `GET /api/pathway/catalog` on the API → 200.
2. Open the app → `/assessment` → finish a text assessment → result card renders.
3. `/dashboard` lists the new patient with a pathway pill.
4. `/assessment?mode=voice` connects (requires the worker to be running).
