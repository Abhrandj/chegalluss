# Finance aggregate test plan (NO GitHub Actions)
Status: SQL proposed, **NOT DEPLOYED**. Production data unchanged.

Source: `proposed-migrations/20261102_finance_summary_aggregate_review.sql`.

## Preconditions
- Create disposable isolated PostgreSQL/Supabase test environment using separate credentials and no customer data.
- Load relevant RLS policies and master schema for staff_roles, operational_cash_movements, employee_advances.
- Verify function privileges: anon must not execute; only enabled staff may obtain a row.
- Use real auth JWTs for Owner/Admin and disabled staff, not database superuser.

## Acceptance cases
1. 0 rows: enabled staff sees count 0 and aggregate 0 (not proof of available opening balance).
2. 1,005 cash movements: result count=1005 and sum matches independent SQL aggregate.
3. 1,005 advances: count=1005 and outstanding equals advances minus repayments/deductions.
4. Owner: can read identical eligible ledger totals, cannot write.
5. Admin: can read; writing depends on separate approved RPC.
6. Disabled staff: returns no row; UI must display Tidak tersedia/UNKNOWN, never Rp0.
7. Anon: EXECUTE denied.
8. Concurrent reader under updates: one statement consistent snapshot.
9. Negative/positive cash signed amounts retain correct cash flow meaning.
10. Accounting: cash_net is movement sum, not certified bank balance or profit.
11. Deposit Ci Noni DEMO unaffected.
12. Missing RLS or insufficient GRANT: fail closed, never fallback to partial totals.

## Release gate
Do not enable production deployment until a staging test report identifies actual test IDs, PostgreSQL version, exact schema version, observed outputs, and an independent reviewer approves role/privilege controls.
GitHub Actions remain reserved for TEVARA.
