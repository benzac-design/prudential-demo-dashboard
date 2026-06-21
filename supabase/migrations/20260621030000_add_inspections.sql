-- Routine rental inspections so the agent can monitor when inspections are due
-- and auto-draft the tenant notice (NSW requires >=7 days written notice,
-- max 4 routine inspections per 12 months). Drives process_inspections.

CREATE TABLE IF NOT EXISTS "public"."inspections" (
    "id"                    uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    "agent_id"              text NOT NULL,
    "lease_id"              uuid REFERENCES "public"."leases" ("id") ON DELETE CASCADE,
    "tenant_name"           text NOT NULL,
    "address"               text NOT NULL,
    "next_inspection_date"  date NOT NULL,
    "frequency_months"      integer NOT NULL DEFAULT 6,   -- how often to repeat
    "status"               text NOT NULL DEFAULT 'scheduled',  -- scheduled | notice_sent | completed
    "notice_sent"           boolean NOT NULL DEFAULT false,
    "last_completed"        date,
    "tenant_phone"          text DEFAULT '',
    "tenant_email"          text DEFAULT '',
    "created_at"            timestamptz NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS inspections_agent_id_idx ON "public"."inspections" ("agent_id");
CREATE INDEX IF NOT EXISTS inspections_next_date_idx ON "public"."inspections" ("next_inspection_date");

ALTER TABLE "public"."inspections" ENABLE ROW LEVEL SECURITY;
