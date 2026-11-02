# CHEGALLUSS finance offline test run

Date: 2026-11-02
Source: tests/finance-invariants.test.mjs on branch fix/chegalluss-v28-dashboard-clarity
Execution: Node.js v22.16.0 in isolated working container, no GitHub Actions, no TEVARA VPS, no Supabase connection.
Command: node --test finance-invariants.test.mjs
Result: **7 pass, 0 fail, 0 skipped**, 7 tests total.

Passed:
1. Cash expense isolated by account and period.
2. Employees with same display name isolated by employee ID.
3. Duplicate request denied.
4. Overpayment denied without changing state.
5. Payroll deduction reduces receivable without cash movement.
6. Unauthorized/mismatched period input denied.
7. Cash transactions do not change distributor deposit.

Scope limitation:
These tests run a pure JS model of business invariants. They do NOT execute PostgreSQL RPC, RLS, trigger, DB concurrency, Supabase authentication, browser UI, or migration.
A direct curl download from GitHub was unavailable due to DNS in runtime. Test source was retrieved using the connected GitHub service and copied into a local test file before running.
Real write operations remain feature-gated OFF. No production migration applied.
Next: validate SQL on isolated DB, check authorization/idempotency and reconcile accounting treatment before enabling write UI.
