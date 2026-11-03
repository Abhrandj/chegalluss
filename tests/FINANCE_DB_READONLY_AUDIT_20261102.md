# CHEGALLUSS: production read-only finance gate audit (2026-11-02)

## Verified against active Supabase database
Queries were SELECT-only against PostgreSQL metadata. No DDL, test inserts, RPC write calls, GitHub Actions, or VPS TEVARA usage.

| Check | Result |
|---|---|
| public.operational_cash_movements RLS | ENABLED |
| public.employee_advances RLS | ENABLED |
| public.audit_events RLS | ENABLED |
| authenticated INSERT/UPDATE/DELETE on each above | FALSE |
| active public.chegalluss_post_cash RPC | NOT PRESENT |
| active public.chegalluss_post_advance RPC | NOT PRESENT |
| demo_deposit_action and demo_post_harvest | PRESENT; SECURITY DEFINER |
| Proposed employee and account master migration | NOT DEPLOYED |

### Audited queries
```sql
select p.proname,p.prosecdef,pg_get_function_identity_arguments(p.oid) as args
from pg_proc p join pg_namespace n on n.oid=p.pronamespace
where n.nspname='public'
and (p.proname like 'chegalluss_%' or p.proname like 'demo_%')
order by p.proname;

select c.relname as table_name,c.relrowsecurity,
has_table_privilege('authenticated',c.oid,'INSERT') as auth_insert,
has_table_privilege('authenticated',c.oid,'UPDATE') as auth_update,
has_table_privilege('authenticated',c.oid,'DELETE') as auth_delete
from pg_class c join pg_namespace n on n.oid=c.relnamespace
where n.nspname='public'
and c.relname in ('operational_cash_movements','employee_advances','staff_roles','audit_events')
order by c.relname;
```

## Blockers / next actions
1. Build temporary isolated PostgreSQL test database outside production to run migrations and enforce rollback, concurrency, permissions, and idempotency tests.
2. Replace name-based employee advance RPC before any deployment; use immutable employee IDs and cash-account IDs.
3. Review SECURITY DEFINER demo RPC privilege checks separately before production promotion.
4. Add transaction journal and opening-balance reconciliation; ensure advance is receivable, not expense.
5. Verify client retries persist the SAME idempotency key instead of generating a new key each click.
6. Add audited correction and owner signoff before any period can claim verified BEP.

**Status: BLOCKED FOR PRODUCTION.** UI finance write feature gate remains false. GitHub Actions are reserved exclusively for TEVARA.
