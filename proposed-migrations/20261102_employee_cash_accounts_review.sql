-- CHEGALLUSS master employees and operational cash accounts
-- REVIEW ONLY. Not applied to active Supabase.
create table if not exists public.chegalluss_employees (
 id uuid primary key default gen_random_uuid(),
 employee_code text not null unique check (employee_code ~ '^[A-Z0-9_-]{2,24}$'),
 display_name text not null check (length(trim(display_name)) between 2 and 120),
 active boolean not null default true,
 created_at timestamptz not null default now()
);
create table if not exists public.chegalluss_cash_accounts (
 id uuid primary key default gen_random_uuid(),
 account_code text not null unique check (account_code ~ '^[A-Z0-9_-]{2,24}$'),
 account_name text not null check (length(trim(account_name)) between 2 and 120),
 active boolean not null default true,
 created_at timestamptz not null default now()
);
-- Opening balances must be entered as auditable opening transactions,
-- NOT stored as mutable balance fields and not assumed to be zero.
alter table public.chegalluss_employees enable row level security;
alter table public.chegalluss_cash_accounts enable row level security;
revoke all on public.chegalluss_employees from anon;
revoke all on public.chegalluss_cash_accounts from anon;
revoke insert, update, delete on public.chegalluss_employees from authenticated;
revoke insert, update, delete on public.chegalluss_cash_accounts from authenticated;
grant select on public.chegalluss_employees to authenticated;
grant select on public.chegalluss_cash_accounts to authenticated;
create policy "active_staff_read_employees" on public.chegalluss_employees
for select to authenticated using (
 exists(select 1 from public.staff_roles r where r.user_id=(select auth.uid()) and r.enabled)
);
create policy "active_staff_read_cash_accounts" on public.chegalluss_cash_accounts
for select to authenticated using (
 exists(select 1 from public.staff_roles r where r.user_id=(select auth.uid()) and r.enabled)
);
-- Before integrating post_advance, replace p_employee text with p_employee_id uuid,
-- and reference employee advances by immutable employee ID.
-- Before integrating post_cash, bind each cash movement to cash_account_id
-- and period_id, validate role and reconcile opening balances.
-- No write RPC is exposed by this draft.
