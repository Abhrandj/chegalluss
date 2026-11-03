# CHEGALLUSS PR #1 - closing verification (2026-11-02)

## Verified
- `v28-test/index.html` parsed as ECMAScript after wrapping top-level await in async wrapper and omitting its static ESM import for syntax validation: **PASS**.
- Report now uses `db.rpc('chegalluss_finance_summary')`, instead of summing limited client-side transaction lists.
- When SQL RPC is missing, denied, or yields incomplete/unsafe numbers, totals remain **Belum tersedia**.
- Recent history is limited to 10 items solely for display; totals are never calculated from it.
- `CHEGALLUSS_FINANCE_WRITES_ENABLED=false` remains unchanged.
- No GitHub Actions, no TEVARA services, no database writes.

## Not yet complete
- Proposed server summary SQL has NOT been applied to production or tested in isolated PostgreSQL.
- Draft posting functions were NOT deployed and are NOT ready for real money.
- Employee IDs, cash accounts, opening balance journal and accounting reconciliation remain to be integrated and tested.
- Browser end-to-end and SQL/RLS privilege tests have NOT been executed.
- PR #1 intentionally remains Draft, with no merge or website deployment.

## Safe next release criteria
1. Isolated Postgres test of schema and summary function under Owner, Admin, unauthenticated, and disabled staff roles.
2. Validate large data aggregate, date boundaries, amount precision, and missing/denied RPC error states.
3. Review opening balance, cashbook postings, payroll deduction, and account/period allocation.
4. Require explicit human approval to apply migration and merge website changes.
5. Only after independent reconciliation, enable posting; never equate cash balance with BEP.
