# Prudential Real Estate — AI Agent (Demo Dashboard & Docs)

This repo holds the demo dashboard and project documentation for the Prudential Real Estate AI agent.

- **`system-admin.html`** — the `/admin` dashboard (served by the `prudential-demo` Vercel project). Tabs: Overview, Call List, Showings, Leads, Property Matching, Seller Valuations, Re-Engagement, Follow-ups, Maintenance, Lease Renewals, Rent Arrears, Inspections, Monthly Report, How It Works. Password-gated.
- **`prudential-demo.html`** — Ash-specific demo page.
- **`supabase/migrations/`** — database migrations (messages, appointments, leases, rent_payments, inspections).
- **`CLAUDE.md` / `HANDOVER.md`** — project context and current status.

The backend API lives in a separate repo: [`prudential-realestate-agent`](https://github.com/benzac-design/prudential-realestate-agent).

Deploys automatically to Vercel (`prudential-demo` project) on push to `main`.
