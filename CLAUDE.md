# Real Estate AI Agent — Project Context

## Goal
Get the AI agent fully live for a demo with Ash at Prudential Real Estate Macquarie Fields. The business target is $600 by 2026-07-27 ($200/month × 2-3 clients). Ash's focus is rental portfolio management.

## What's Built (live & deployed)
- FastAPI backend deployed on **Vercel** at `https://realestate-agent-three.vercel.app` (auto-deploys from GitHub `benzac-design/prudential-realestate-agent`)
- Backend code lives at `/Users/rgetgetrtgertgeegte/Documents/Ai agent/realestate-agent/` (NOT this folder — this folder is docs + demo HTML)
- Routes: leads, conversations, follow-ups, clients, listings, appointments, maintenance, renewals, rent, inspections, valuation, reports, stats
- APScheduler — `process_pending_followups` + `send_appointment_reminders`
- Supabase DB — tables: leads, listings, buyer_clients, followup_schedules, **messages, appointments, leases, rent_payments, inspections** (last five added 2026-06-21)
- Automated lease-renewal monitor — `process_lease_renewals()` runs daily (via the `/api/process-followups` cron), drafts a retention-focused offer for any active lease 60–90 days from expiry, emails the agent, and flags it once. Routes: `POST /api/renewals/leases` (register), `GET /api/renewals/leases/{agent_id}`, `GET /api/renewals/due`, `POST /api/renewals/run`.
- Automated rent arrears monitor — `process_rent_arrears()` runs daily (same cron): reminds tenants of rent due within 3 days, and detects overdue rent (arrears) → messages the tenant (SMS, falls back to email) and alerts the agent. Each payment actioned once. Routes: `POST /api/rent/payments`, `GET /api/rent/payments/{agent_id}`, `GET /api/rent/arrears`, `PATCH /api/rent/payments/{id}/paid`, `POST /api/rent/run`.
- Routine inspection scheduler — `process_inspections()` runs daily (same cron): for inspections due within 14 days, drafts a compliant advance notice (NSW ≥7 days), messages the tenant (SMS→email fallback), alerts the agent, actioned once. Completing an inspection auto-schedules the next one `frequency_months` out (default 6). Routes: `POST /api/inspections`, `GET /api/inspections/{agent_id}`, `GET /api/inspections/due`, `POST /api/inspections/{id}/complete`, `POST /api/inspections/run`.
- On-demand AI draft endpoints (used by the demo "Try It Live" buttons + agent review): `POST /api/renewals/draft`, `POST /api/rent/draft-notice`, `POST /api/inspections/draft-notice`.
- Monthly report includes a **Rental Portfolio** section (arrears count + $ outstanding, inspections due next 30 days, renewals due next 90 days) via `get_rental_stats()`. Routes: `GET /api/reports/{agent_id}/monthly` (preview), `POST /api/reports/{agent_id}/monthly/send`.
- Frontend: dashboard, sales site, Ash-specific demo (`prudential-demo.html`), overview, `system-admin.html` (the `/admin` page, served by the separate `prudential-demo` Vercel project). Admin tabs now include Rent Arrears + Inspections (with live AI buttons), the Overview surfaces rental-portfolio counts, and the Monthly Report tab shows the rental breakdown.

## AI provider
The app uses **MiniMax** (`MiniMax-Text-01` via the OpenAI client, key `MINIMAX_API_KEY`).
It does NOT use Anthropic or Google — those references have been removed. See `app/services/claude_service.py` (name is legacy; it calls MiniMax).

## Status (2026-06-21)
- ✅ Database — working. (Fix: `SUPABASE_KEY` must be the **legacy `service_role` JWT**, not the new `sb_secret_` key — `supabase-py==2.7.4` rejects the new format.)
- ✅ AI features — listing description, maintenance triage, lease renewal, Fair Housing audit (`POST /api/listings/audit`)
- ✅ Lease-date monitoring — automated (see What's Built). Fixed a latent `timedelta` import bug that would have crashed the 24h appointment reminders.
- ✅ Email (Resend) — key valid; `FROM_EMAIL=onboarding@resend.dev` (sandbox, reaches account owner only)
- ❌ SMS (Twilio) — BLOCKED on Twilio account upgrade (see HANDOVER.md). Owned number is voice-only; alphanumeric sender blocked on trial.

## Env vars (set in Vercel production)
SUPABASE_URL, SUPABASE_KEY (legacy service_role JWT), MINIMAX_API_KEY, RESEND_API_KEY, FROM_EMAIL,
TWILIO_ACCOUNT_SID, TWILIO_AUTH_TOKEN, TWILIO_PHONE_NUMBER, SECRET_KEY, APP_URL, DASHBOARD_PASSWORD.
Local copy in `realestate-agent/.env`; template in `realestate-agent/.env.example`.

## Next Steps
1. Unblock Twilio SMS — upgrade account, set `TWILIO_PHONE_NUMBER` (e.g. alphanumeric `Prudential`), run live test to +61493968875
2. For real-lead email — verify a domain at resend.com and switch `FROM_EMAIL`
3. Review `prudential-demo.html` for demo-readiness
4. Demo with Ash

## Login protection
Both dashboards (backend `index.html` at `/`, and the `/admin` demo page) have a shared-password login gate. Password is validated server-side via `POST /api/auth/login` against `DASHBOARD_PASSWORD` (a strong random value, set in Vercel `realestate-agent` + local `.env`; not stored in this repo — see your password manager). To rotate: update `DASHBOARD_PASSWORD` in Vercel + local `.env` and redeploy; no code/frontend change needed. On success the gate stores `dash_auth=1` + `dash_pw` in sessionStorage and a `window.fetch` wrapper attaches `X-Dashboard-Auth: <password>` to every `/api/*` call.

**API auth:** `app/auth.py::require_dashboard_auth` enforces the header on all dashboard data routers (listings, followups, clients, appointments, stats, reports, maintenance, renewals, rent, inspections) plus the private leads endpoints (`GET /leads/{agent_id}`, `PATCH /leads/{id}/status`, `POST /leads/reengage`). Missing/wrong header → 401. Fails OPEN if `DASHBOARD_PASSWORD` is unset (so local dev isn't blocked).

**Deliberately left PUBLIC** (no auth — website/Twilio/cron call them): `POST /api/leads/new`, `POST /api/valuation/request`, `POST /api/conversations/sms/inbound`, `GET /api/process-followups` (cron), `GET /health`, `POST /api/auth/login`.

NOTE: still a shared-password scheme; the static demo HTML is in page source. For stronger protection use Vercel Deployment Protection.

## Open Decisions
- Calendly/Cal.com booking — `BOOKING_LINK` env var; note as "coming soon" or integrate

## Key Files (in realestate-agent/)
- `app/main.py` — FastAPI entry, CORS, routes, static serving (`BASE_DIR = Path(__file__).resolve().parent.parent`)
- `app/scheduler.py` — APScheduler follow-ups + reminders
- `app/services/claude_service.py` — AI functions (MiniMax)
- `app/services/supabase_service.py` — DB operations
- `app/services/resend_service.py` / `twilio_service.py` — email / SMS
- `app/routes/` — all API routes (incl. `rent.py`, `inspections.py`)
- `app/routes/reports.py` — monthly report HTML incl. Rental Portfolio section
- Two Vercel projects: `realestate-agent` (backend/API, `realestate-agent-three.vercel.app`) and `prudential-demo` (the `/admin` + demo pages, deploy from THIS folder)
- `.env.example` — env var template
- Migrations: `Prudential Real Estate/supabase/migrations/20260621000000_add_messages_appointments.sql`, `20260621010000_add_leases.sql`, `20260621020000_add_rent_payments.sql`, `20260621030000_add_inspections.sql`
