-- CHEGALLUSS: READ ONLY verification SQL for iPhone Supabase SQL Editor.
-- No INSERT, UPDATE, DELETE, CREATE, ALTER, DROP, or RPC invocation.
-- Do not interpret this as a concurrent PostgreSQL posting test.
SELECT
  EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_schema='public' AND table_name='demo_deposit_movements'
      AND column_name='topup_request_id'
  ) AS idempotency_column_installed,
  EXISTS (
    SELECT 1 FROM pg_indexes
    WHERE schemaname='public' AND tablename='demo_deposit_movements'
      AND indexname='demo_unique_topup_request'
  ) AS unique_index_installed,
  EXISTS (
    SELECT 1 FROM pg_proc p JOIN pg_namespace n ON n.oid=p.pronamespace
    WHERE n.nspname='public' AND p.proname='demo_post_harvest'
      AND pg_get_functiondef(p.oid) LIKE '%barn_id=barn and status=%'
  ) AS harvest_open_period_check_installed,
  EXISTS (
    SELECT 1 FROM pg_proc p JOIN pg_namespace n ON n.oid=p.pronamespace
    WHERE n.nspname='public' AND p.proname='demo_deposit_action'
      AND pg_get_functiondef(p.oid) LIKE '%REQUEST_ID_REQUIRED%'
  ) AS topup_uuid_check_installed;
