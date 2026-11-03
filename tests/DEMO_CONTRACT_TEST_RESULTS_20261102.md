# CHEGALLUSS DEMO integration contract test - 2026-11-02

## Test execution
- Environment: isolated Node.js 22.16.0, in-memory deterministic double (not PostgreSQL).
- Command: `node --test demo-integration.test.mjs`.
- Outcome: **8 passed, 0 failed, 0 skipped**.
- Tests: first deposit credit, repeat with same request ID, changed-amount conflict, non-admin rejection, closed-period harvest rejection, open-period harvest plus duplicate sale denial, wrong-barn rejection, invalid topup amounts.
- The executed test file is available in the ChatGPT conversation artifact; it is not presently checked into GitHub.

## Limitations
No PostgreSQL server or Docker runtime available in this execution environment. This test **does not execute actual SQL**, RLS, concurrent database transactions, actual account balances, browser localStorage, or Supabase Auth. Database production was not modified.

## Important follow-on
The proposed SQL patch currently returns the current account balance on a duplicate request, not necessarily the original transaction's post-balance. The UI must not treat that as evidence of the original historical balance; show an explicitly idempotent confirmation.
Before deployment: test the SQL with the exact frontend RPC payload and actual Postgres constraints, including simultaneous duplicate requests, role authorization, and current/closed period states.
The existing `v28-test` frontend now passes `number:pending.requestId`; proposed SQL requires a stable UUID for topups. SQL and frontend must be staged together, and current app must not be changed in production until verified.
GitHub Actions are reserved for TEVARA.
