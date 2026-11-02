-- PROPOSED FOR REVIEW ONLY: staging-tested safeguard, NOT deployed to production.
-- Existing operational_cash_movements table must exist.
CREATE OR REPLACE FUNCTION public.chegalluss_validate_cash_period()
RETURNS trigger LANGUAGE plpgsql SET search_path=public,pg_temp AS $$
BEGIN
 IF NEW.period_id IS NOT NULL THEN
  IF NEW.barn_id IS NULL OR NOT EXISTS (
   SELECT 1 FROM public.periods p
   WHERE p.id=NEW.period_id AND p.barn_id=NEW.barn_id AND p.status='open'
   FOR SHARE
  ) THEN RAISE EXCEPTION 'CASH_PERIOD_NOT_OPEN_OR_MISMATCH'; END IF;
 END IF;
 RETURN NEW;
END $$;
REVOKE ALL ON FUNCTION public.chegalluss_validate_cash_period() FROM PUBLIC,anon,authenticated;
CREATE TRIGGER chegalluss_cash_period_guard
BEFORE INSERT OR UPDATE
ON public.operational_cash_movements
FOR EACH ROW EXECUTE FUNCTION public.chegalluss_validate_cash_period();

-- Note: Staging has the equivalent trigger with staging_ names.
-- Guard validates INSERT and all UPDATE routes for period-bound rows.
-- Review period-closing workflows and multi-session lock contention before production.
