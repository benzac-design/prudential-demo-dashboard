-- Lock down all public tables with Row Level Security.
--
-- The FastAPI backend connects with the service_role key, which BYPASSES RLS,
-- so all backend operations continue to work unchanged. The frontend talks to
-- the backend (not Supabase directly), so the anon/authenticated roles do not
-- need any table access. Enabling RLS with no policies denies all access by
-- default for those roles; we also revoke the explicit grants for defense in
-- depth.

-- 1. Enable (and force) RLS on every table.
ALTER TABLE "public"."leads"               ENABLE ROW LEVEL SECURITY;
ALTER TABLE "public"."buyer_clients"       ENABLE ROW LEVEL SECURITY;
ALTER TABLE "public"."followup_schedules"  ENABLE ROW LEVEL SECURITY;
ALTER TABLE "public"."listings"            ENABLE ROW LEVEL SECURITY;

-- 2. Revoke the public-facing grants that were created by default.
--    service_role retains its grants and bypasses RLS regardless.
REVOKE ALL ON TABLE "public"."leads"              FROM "anon", "authenticated";
REVOKE ALL ON TABLE "public"."buyer_clients"      FROM "anon", "authenticated";
REVOKE ALL ON TABLE "public"."followup_schedules" FROM "anon", "authenticated";
REVOKE ALL ON TABLE "public"."listings"           FROM "anon", "authenticated";
