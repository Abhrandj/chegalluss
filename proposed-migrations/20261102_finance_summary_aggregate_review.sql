-- REVIEW ONLY. Do not deploy to active CHEGALLUSS Supabase before staging verification.
-- SECURITY INVOKER ensures existing RLS staff_read policies govern rows.
-- This query uses aggregate functions in PostgreSQL and never truncates at 1,000 rows.
create or replace function public.chegalluss_finance_summary()
returns table (
 cash_movements_count bigint,
 cash_net_idr numeric,
 advance_movements_count bigint,
 advance_outstanding_idr numeric
)
language sql
stable
security invoker
set search_path = ''
as $$
 select
  (select count(*) from public.operational_cash_movements),
  (select coalesce(sum(amount_idr),0) from public.operational_cash_movements),
  (select count(*) from public.employee_advances),
  (select coalesce(sum(case when kind='advance' then amount_idr else -amount_idr end),0)
   from public.employee_advances)
 where auth.uid() is not null and exists (
   select 1 from public.staff_roles r where r.user_id=auth.uid() and r.enabled
 );
$$;
revoke all on function public.chegalluss_finance_summary() from public, anon;
grant execute on function public.chegalluss_finance_summary() to authenticated;
-- RLS visibility must be confirmed for both owner and admin.
-- No mutating SQL, opening-balance creation, or financial posting in this proposal.
