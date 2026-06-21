-- Adds the two tables the app code requires but that are missing from the DB:
--   messages       -> two-way SMS conversation history (lead qualification loop)
--   appointments   -> viewing/call bookings + reminder scheduler
-- Columns match app/services/supabase_service.py exactly.
-- Foreign keys to leads(id) are required for PostgREST's leads(name,phone,email) joins.

-- ---- messages ----
CREATE TABLE IF NOT EXISTS "public"."messages" (
    "id"         uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    "lead_id"    uuid REFERENCES "public"."leads" ("id") ON DELETE CASCADE,
    "agent_id"   text NOT NULL,
    "direction"  text NOT NULL,                -- 'inbound' | 'outbound'
    "body"       text NOT NULL,
    "channel"    text NOT NULL DEFAULT 'sms',
    "created_at" timestamptz NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS messages_lead_id_idx  ON "public"."messages" ("lead_id");
CREATE INDEX IF NOT EXISTS messages_agent_id_idx ON "public"."messages" ("agent_id");

-- ---- appointments ----
CREATE TABLE IF NOT EXISTS "public"."appointments" (
    "id"            uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    "lead_id"       uuid REFERENCES "public"."leads" ("id") ON DELETE CASCADE,
    "agent_id"      text NOT NULL,
    "scheduled_at"  timestamptz NOT NULL,
    "location"      text DEFAULT '',
    "notes"         text DEFAULT '',
    "status"        text NOT NULL DEFAULT 'scheduled',   -- scheduled | completed | cancelled
    "reminder_sent" boolean NOT NULL DEFAULT false,
    "created_at"    timestamptz NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS appointments_agent_id_idx     ON "public"."appointments" ("agent_id");
CREATE INDEX IF NOT EXISTS appointments_scheduled_at_idx ON "public"."appointments" ("scheduled_at");

-- ---- RLS lockdown (match existing tables; the sb_secret_ service key bypasses RLS) ----
ALTER TABLE "public"."messages"     ENABLE ROW LEVEL SECURITY;
ALTER TABLE "public"."appointments" ENABLE ROW LEVEL SECURITY;
