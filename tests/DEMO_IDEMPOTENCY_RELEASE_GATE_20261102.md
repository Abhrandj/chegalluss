# DEMO Deposit: regression audit, 2026-11-02

Scope: PR #1 on branch `fix/chegalluss-v28-dashboard-clarity`.
Database: NO schema changes, NO data changes. No GitHub Actions. No deployment.

## Evidence
- SQL patch blob: `079cb7ed9aa6deaf66031a18d713d350fe812536`
- Static test blob: `e33bd560f1ec10b3ecf3f9994d9be0269028c670`
- 13/13 assertions evaluated against the SQL text using an independent JavaScript check in ChatGPT code execution. This was NOT a `node --test` run and NOT PostgreSQL integration testing.
- Previous Supabase read-only inspection: migration's `topup_request_id` column and `demo_unique_topup_request` index NOT installed.

## Remaining hard gates before enabling topups
1. Run migration in an **isolated PostgreSQL/Supabase staging database** mirroring schema and role privileges.
2. Verify ADMIN_REQUIRED rejects anonymous, disabled Admin, and Owner; live auth.uid() behavior.
3. In separate sessions concurrently post same UUID, same account and amount. Expect exactly one journal credit, and a replay response without double credit.
4. Reuse UUID for different amount AND for different account. Expect fail-closed conflict, never another credit. Observe unique-violation behavior when concurrent requests lock different account rows.
5. Confirm stale/invalid UUID and malformed amount are rejected; reconnect with same pending UUID after lost response.
6. Verify harvest cannot post to closed period or mismatched barn; verify behavior while period is being closed concurrently.
7. Record results and perform a coordinated SQL + frontend release. Only then enable `CHEGALLUSS_DEMO_TOPUP_V2_ENABLED`.
8. Keep `CHEGALLUSS_FINANCE_WRITES_ENABLED=false` until separately approved.

Until then: SQL patch is **REVIEW ONLY**, PR stays Draft, DEMO topup gate stays off on test branch. Do not run unreviewed writes against the existing Supabase project.
