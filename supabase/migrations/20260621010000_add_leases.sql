-- Lease/tenancy records so the agent can monitor lease end dates and
-- auto-flag renewals 60-90 days out (drives process_lease_renewals scheduler job).

CREATE TABLE IF NOT EXISTS "public"."leases" (
    "id"               uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    "agent_id"         text NOT NULL,
    "tenant_name"      text NOT NULL,
    "address"          text NOT NULL,
    "current_rent"     numeric NOT NULL,
    "rent_period"      text NOT NULL DEFAULT 'week',   -- week | month
    "lease_end"        date NOT NULL,
    "tenure"           text DEFAULT '',
    "market_context"   text DEFAULT '',
    "tenant_phone"     text DEFAULT '',
    "tenant_email"     text DEFAULT '',
    "status"           text NOT NULL DEFAULT 'active',  -- active | renewed | ended
    "renewal_flagged"  boolean NOT NULL DEFAULT false,  -- set true once a renewal offer has been drafted
    "created_at"       timestamptz NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS leases_agent_id_idx  ON "public"."leases" ("agent_id");
CREATE INDEX IF NOT EXISTS leases_lease_end_idx ON "public"."leases" ("lease_end");

ALTER TABLE "public"."leases" ENABLE ROW LEVEL SECURITY;
