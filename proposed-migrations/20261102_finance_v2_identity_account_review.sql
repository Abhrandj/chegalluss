-- CHEGALLUSS finance v2: REVIEW-ONLY superseding design
-- DO NOT APPLY until isolated test and accounting sign-off.
-- Depends on 20261102_employee_cash_accounts_review.sql
-- Existing draft RPC with p_employee text and no account_id MUST NOT be deployed.

alter table public.operational_cash_movements
 add column if not exists cash_account_id uuid references public.chegalluss_cash_accounts(id),
 add column if not exists employee_id uuid references public.chegalluss_employees(id);
alter table public.employee_advances
 add column if not exists employee_id uuid references public.chegalluss_employees(id);

-- Existing records must be backfilled and reconciled before NOT NULL constraints.
-- Do not automatically match legacy employee_name to ID or assume missing cash account.
create unique index if not exists operational_cash_request_unique
 on public.operational_cash_movements(request_id) where request_id is not null;
create unique index if not exists employee_advances_request_unique
 on public.employee_advances(request_id) where request_id is not null;

-- Rules for a replacement SECURITY DEFINER posting RPC:
-- 1) revoked from PUBLIC and anon, EXECUTE granted authenticated only;
--    check auth.uid() against active staff_roles admin INSIDE procedure.
-- 2) validate UUID account and employee are ACTIVE and currently registered.
-- 3) reject barn/period mismatch, missing period allocation for production costs.
-- 4) use unique stable request_id from persistent client idempotency key.
-- 5) lock per employee ID (not name) before checking outstanding receivable;
--    prevent repayment/deduction larger than outstanding amount.
-- 6) account opening uses explicit signed journal event plus owner approval.
-- 7) cash movements have signed amount; expense classification is separate.
-- 8) post both advance receivable and cash effect in ONE database transaction;
--    payroll deduction settles receivable without cash movement.
-- 9) implement immutable audit events/adjustments, not unrestricted UPDATE.
-- 10) verify negative tests for two employees with identical names.
-- 11) server aggregates must page reliably; avoid computing totals with
--     a client SELECT limited to the first 1,000 records.
-- 12) refuse real posting until period close, payroll, and account
--     reconciliation semantics are approved.

-- REVIEW: The earlier draft RPC is incomplete and SHOULD NOT be activated.
