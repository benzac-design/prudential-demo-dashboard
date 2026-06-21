-- Rent ledger so the agent can monitor rent due dates, remind tenants of
-- upcoming rent, and detect arrears (overdue rent) — drives process_rent_arrears.
-- Tenant contact is denormalized onto each row so the monitor needs no join.

CREATE TABLE IF NOT EXISTS "public"."rent_payments" (
    "id"                  uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    "agent_id"            text NOT NULL,
    "lease_id"            uuid REFERENCES "public"."leases" ("id") ON DELETE CASCADE,
    "tenant_name"         text NOT NULL,
    "address"             text NOT NULL,
    "amount"              numeric NOT NULL,
    "rent_period"         text NOT NULL DEFAULT 'week',   -- week | month
    "due_date"            date NOT NULL,
    "status"             text NOT NULL DEFAULT 'pending',  -- pending | paid | overdue
    "paid_date"           date,
    "tenant_phone"        text DEFAULT '',
    "tenant_email"        text DEFAULT '',
    "reminder_sent"       boolean NOT NULL DEFAULT false,  -- upcoming-rent reminder sent
    "overdue_alert_sent"  boolean NOT NULL DEFAULT false,  -- arrears notice + agent alert sent
    "created_at"          timestamptz NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS rent_payments_agent_id_idx ON "public"."rent_payments" ("agent_id");
CREATE INDEX IF NOT EXISTS rent_payments_due_date_idx ON "public"."rent_payments" ("due_date");
CREATE INDEX IF NOT EXISTS rent_payments_status_idx   ON "public"."rent_payments" ("status");

ALTER TABLE "public"."rent_payments" ENABLE ROW LEVEL SECURITY;
