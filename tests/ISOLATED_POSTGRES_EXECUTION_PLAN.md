# Isolated PostgreSQL execution checklist (NOT YET EXECUTED)

**Status: BLOCKED: no isolated PostgreSQL is available to the current runner.**

Environment checks on 2026-11-02:
- `postgres`, `initdb`, `pg_ctl`, `psql`, and Docker executables: missing.
- Debian package mirror update timed out; npm registry DNS lookup failed.
- No separate paid Supabase project has been created.
- Main project `chcpzczdshlioguzelvz` **must not be used as staging**.

## Required prerequisites
1. An ephemeral PostgreSQL >=17 cluster *not connected to the CHEGALLUSS Supabase project*, with a schema dump containing tables, constraints, indexes, grants, `auth.uid()` equivalent, sample roles, and fixture data.
2. Two distinct database sessions for simultaneous insert tests.
3. An authenticated Admin fixture and disabled Admin, Owner and anonymous fixtures.
4. No actual customer/personal information; synthetic test data only.

## Commands (run only in the isolated environment)

```bash
set -euo pipefail
test "${CHEGALLUSS_ISOLATED_TEST:-}" = "YES"
test "${PGHOST:-}" = "127.0.0.1"
test "${PGDATABASE:-}" = "chegalluss_isolated_test"
psql -X -v ON_ERROR_STOP=1 -f staging_schema_and_auth_fixture.sql
psql -X -v ON_ERROR_STOP=1 -f proposed-migrations/20261102_demo_security_hardening_review.sql
node --test tests/demo-security-patch.test.mjs
```

## Execution cases, not merely source-string assertions
1. Admin topup: new UUID credited exactly once.
2. Identical UUID + same account + same amount: duplicate=true and ledger unchanged.
3. Identical UUID + changed amount: REQUEST_ID_CONFLICT and ledger unchanged.
4. Identical UUID + different account: REQUEST_ID_CONFLICT, or unique-violation rejection, and ledger unchanged.
5. Concurrent sessions, same UUID and account: exactly one committed credit.
6. Concurrent sessions, same UUID across different accounts: at most one committed credit.
7. Null/invalid UUID, null/zero/negative/fractional/oversized amount: rejected.
8. No user, Owner, disabled Admin: rejected; active Admin: permitted.
9. Bon and harvest for OPEN period: accepted with correct debt settlement and deposit journal; CLOSED and barn mismatch: rejected.
10. Close period concurrently with bon/harvest: one operation must wait; no posting after the close is committed.
11. Browser iPhone: lost response, retry same UUID, stale localStorage, refresh failure.
12. Finance report reconciliation and BEP integrity across multiple barns.

For every case, save SQL state before and after, SQLSTATE for failures, resulting account ledger count and saldo, and timings for concurrent sessions.

## Release gate
Do not set `CHEGALLUSS_DEMO_TOPUP_V2_ENABLED=true`, merge PR #1, or apply migrations to the existing Supabase project until every above runtime test is observed PASS, reviewed, and coordinated with the frontend.
