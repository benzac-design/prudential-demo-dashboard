# Handover — Prudential Real Estate AI Agent

**Date:** 2026-06-21  
**Next session goal:** Upgrade Twilio (or buy an SMS-capable number) to unblock SMS, then prepare and run the demo with Ash at Prudential Real Estate Macquarie Fields.

---

## Goal of Next Session

Resolve the Twilio SMS blocker (see TODO LATER below), then demo the product to Ash. Database, AI features, Fair Housing audit, and email-to-owner are all already working.

---

## State of Play

### Done
- FastAPI backend deployed and live at `https://realestate-agent-three.vercel.app`
- `/health` returns `{"status":"ok"}` — backend is fully running
- All routes working: `/`, `/prudential-demo`, `/sales`, `/overview`, `/api/*`
- All env vars set in Vercel production (Supabase, Twilio, Resend, MiniMax, etc.)
- GitHub repo connected to Vercel at `benzac-design/prudential-realestate-agent` — auto-deploys on every push
- Absolute path fix deployed (`BASE_DIR = Path(__file__).resolve().parent.parent`)
- `frontend/static/` directories tracked in git via `.gitkeep` files
- `bypassPermissions` set in `~/.claude/settings.json` — no more permission prompts

### Verified Working (2026-06-21)
- **Database** — Supabase fully working. Root cause of earlier "Invalid API key" was `supabase-py==2.7.4` rejecting the new `sb_secret_` key format. Fixed by switching `SUPABASE_KEY` to the **legacy `service_role` JWT** key (set in Vercel + local `.env`).
- **Missing tables created** — `messages` and `appointments` (migration `supabase/migrations/20260621000000_add_messages_appointments.sql`). The 4 core tables (leads, listings, buyer_clients, followup_schedules) already existed.
- **AI features (MiniMax)** — listing description, maintenance triage, lease renewal all return real output. Note: app uses **MiniMax-Text-01** via OpenAI client, NOT Gemini/Anthropic.
- **Fair Housing audit** — was coded but had no API route; added `POST /api/listings/audit`, deployed and verified (correctly flags violations + passes clean copy).
- **Automated lease-date monitoring** — built & verified. New `leases` table (migration `20260621010000_add_leases.sql`) + `process_lease_renewals()` scheduler job wired into the daily `/api/process-followups` cron. Drafts a retention-focused renewal offer for any active lease 60–90 days from expiry, emails the agent, flags it once (idempotent). Routes: `POST /api/renewals/leases`, `GET /api/renewals/leases/{agent_id}`, `GET /api/renewals/due`, `POST /api/renewals/run`. Also fixed a latent `timedelta` import bug that would have crashed the 24h appointment reminders.
- **Automated rent arrears monitor** — built & verified. New `rent_payments` table (migration `20260621020000_add_rent_payments.sql`) + `process_rent_arrears()` job on the daily cron. Reminds tenants of rent due within 3 days; detects overdue rent → messages tenant (SMS, falls back to email) + alerts agent; each payment actioned once. Routes: `POST /api/rent/payments`, `GET /api/rent/payments/{agent_id}`, `GET /api/rent/arrears`, `PATCH /api/rent/payments/{id}/paid`, `POST /api/rent/run`. NOTE: tenant SMS still blocked by Twilio (dad to fix); email fallback works to owner only until Resend domain verified.
- **Routine inspection scheduler** — built & verified. New `inspections` table (migration `20260621030000_add_inspections.sql`) + `process_inspections()` job on the daily cron. For inspections due within 14 days, drafts an NSW-compliant advance notice (≥7 days), messages tenant (SMS→email fallback) + alerts agent, actioned once. Completing an inspection auto-schedules the next one `frequency_months` out (default 6; verified reschedule). Routes: `POST /api/inspections`, `GET /api/inspections/{agent_id}`, `GET /api/inspections/due`, `POST /api/inspections/{id}/complete`, `POST /api/inspections/run`. Same SMS/email delivery caveat as above.
- **Dashboard login protection + API auth** — both dashboards (backend `index.html` at `/`, and `/admin` demo page) have a shared-password gate validated via `POST /api/auth/login` against `DASHBOARD_PASSWORD` (strong random value, in Vercel + local `.env`, NOT in this repo — see password manager). On login the page stores the password and a `fetch` wrapper attaches `X-Dashboard-Auth` to all `/api/*` calls. Server-side, `app/auth.py::require_dashboard_auth` now enforces that header on all data routers + private leads endpoints (401 without it; verified). Public intake endpoints stay open: `leads/new`, `valuation/request`, `conversations/sms/inbound`, `process-followups` (cron), `health`, `auth/login`. Still a shared-password scheme (demo HTML in source) — Vercel Deployment Protection for stronger.
- **Monthly report — Rental Portfolio section** — `get_rental_stats()` added; report (`/api/reports/{agent_id}/monthly` + emailed) now shows arrears count + $ outstanding, inspections due (30 days), renewals due (90 days). Verified in live report HTML.
- **Admin dashboard (`/admin`, project `prudential-demo`, file `system-admin.html`)** — added Rent Arrears + Inspections tabs (each with a live "Try It Live" AI button hitting `POST /api/rent/draft-notice` and `POST /api/inspections/draft-notice`), surfaced rental-portfolio counts on the Overview tab, and added the Rental Portfolio breakdown to the Monthly Report tab. NOTE: deploy this folder to the `prudential-demo` project; backend changes deploy to `realestate-agent`.
- **Email (Resend)** — API key is valid; verified a real send. `FROM_EMAIL` set to `onboarding@resend.dev` (sandbox) so it works for demos. ⚠️ Sandbox sender can ONLY email the Resend account owner (`bennystcatherine@gmail.com`).
- **Removed all Google AI Studio references** (env var, docs) — project never actually used Google.

### ⏳ TODO LATER — remaining blockers
- **[ ] Twilio SMS — BLOCKED on Twilio account upgrade.** Credentials are valid and set in Vercel (SID `AC1f8cf9…`, auth token set). Recipient `+61493968875` is verified. BUT:
    - The owned number `+61253013362` is **voice-only** (Australian local Twilio numbers can't send SMS).
    - Alphanumeric Sender ID (the AU workaround) is **blocked on trial accounts**.
    - **Fix:** Upgrade Twilio to paid → then set `TWILIO_PHONE_NUMBER=Prudential` (alphanumeric sender, no number needed). OR buy an SMS-capable number. After that, ping Claude to set `TWILIO_PHONE_NUMBER` in Vercel and run the live SMS test.
- **[ ] Email for real leads** — verify a real domain at resend.com/domains and switch `FROM_EMAIL` to e.g. `agent@yourdomain.com` (sandbox only reaches the owner address).
- **[ ] `prudential-demo.html`** — content not reviewed for demo-readiness.

---

## Open Decisions

1. **Resend sender verification** — does `bennystcatherine@gmail.com` need to be changed to a professional email for Ash's demo?
2. **Login protection** — dashboard has no auth. Decide before showing Ash whether this matters.
3. **Twilio verified numbers** — add Ash's phone number to Twilio Verified Caller IDs for SMS demo to work.
4. **Demo page polish** — `prudential-demo.html` may need content updates before showing Ash.

---

## Skills to Use

- `vercel:env-vars` — if env vars need updating (e.g. `MINIMAX_API_KEY`)
- `realestate` — for polishing the demo page content for Ash
- `email` — if Resend sender email needs to be changed to something more professional
- `handoff:handoff` — to write next handover at end of next session

---

## Artifacts

- **Live URL:** `https://realestate-agent-three.vercel.app`
- **Demo page:** `https://realestate-agent-three.vercel.app/prudential-demo`
- **GitHub repo:** `https://github.com/benzac-design/prudential-realestate-agent`
- **Backend code:** `/Users/rgetgetrtgertgeegte/Documents/Ai agent/realestate-agent/`
- **Project instructions:** `/Users/rgetgetrtgertgeegte/Documents/Ai agent/Prudential Real Estate/CLAUDE.md`
- **Env vars template:** `/Users/rgetgetrtgertgeegte/Documents/Ai agent/realestate-agent/.env.example`
- **Key file:** `app/main.py` — FastAPI entry, routes, static file serving
- **AI service:** `app/services/claude_service.py` — uses `MiniMax-Text-01` via the OpenAI client (`MINIMAX_API_KEY`)

---

## Immediate Next Steps (in order)

1. Confirm `MINIMAX_API_KEY` is set in Vercel, then test Generate Description on `https://realestate-agent-three.vercel.app`
2. Verify Resend sender email in Resend dashboard
3. Add Ash's phone number to Twilio Verified Caller IDs
4. Open `https://realestate-agent-three.vercel.app/prudential-demo` and walk through the demo flow
5. Demo with Ash
