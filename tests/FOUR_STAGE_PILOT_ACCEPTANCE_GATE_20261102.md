# CHEGALLUSS CONTROL v1.0 — Four-stage Pilot Acceptance Gate
Date: 2026-11-02
Repo: Abhrandj/chegalluss — Draft PR #1
Target: Supabase isolated staging `omyxasrvozbxzfdukaun`.
No GitHub Actions; no production changes; do not touch TEVARA.

## Stage 1 — Full flock operational cycle
- Confirmed test-only staging flock mortality table, 500 birds / 10 recorded deaths / theoretical 490 survivors. Negative duplicate/date and negative deaths constraints passed.
- Previous staging DEMO ledger and operational cost tests passed on separate example periods.
- BLOCKER: Mortality entry is NOT wired into UI; bird count inventory, harvest head-count, production costs by category and closing reconciliation not yet modeled end-to-end. Do not mix separate fixture periods and imply one complete cycle.
- BEP is not VERIFIED. Presence checks cannot establish all costs actually incurred have been recorded.

## Stage 2 — Owner/Admin interface
- Updated `v28-test/index.html` on PR branch to show explicit UNVERIFIED status per period with missing fields: initial birds, harvest date, closure, bon and sales. All-complete still needs mortality/inventory/cost verification.
- Static source inspection: 6/6 checks for code presence and disabled real finance writes, not browser E2E.
- BLOCKER: No real Auth-issued Owner/Admin login, no iPhone run or usability acceptance. Existing staging mortality table is isolated and not available through application UI.
- DEMO topup and live finance writes remain false/off.

## Stage 3 — Final acceptance tests
- Prior PostgreSQL staging tests cover transaction idempotency replay (sequential), bon/harvest/payables, negative cash updates and close-before-cash (same session), and 13 read policies.
- BLOCKER: true 2-session race (same UUID setoran; close vs post), authenticated API RLS with issued JWT, login recovery and intermittent connectivity not tested.
- Run tests with independently managed connections and real test Auth users only once supported by available controlled test infrastructure.

## Stage 4 — Release candidate and GO/NO-GO
Current recommendation: **NO-GO** for operational deployment and finance write enablement.
To reach READY FOR PILOT:
1. Complete a *single* closed flock cycle fixture with full costs, stock and mortality/harvest reconciliation.
2. Validate Owner read-only/Admin data entry via real Auth and iPhone, including lost network.
3. Verify two independent concurrent SQL sessions and failed write rollback.
4. Review migrations, RLS, database backups/rollback and deployment configuration.
5. Confirm all runtime tests passed and approve pilot separately. Keep Draft PR #1 until then.

Do not call static code assertions equivalent to Node.js test execution or user acceptance. No production deployment is authorized.
