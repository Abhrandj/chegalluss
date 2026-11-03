# CHEGALLUSS staging finance integrity regression

Date: 2026-11-02
Project: omyxasrvozbxzfdukaun (staging only)
Scope: read-only queries against synthetic DEMO fixtures; not real financial records.

## Runtime checks (11/11 passed)
- No payables with remaining amount below zero or above original: 0.
- No bon debit journal entries with nonnegative amount: 0.
- No positive-credit journal entries with nonpositive amount: 0.
- No orphan bon lines: 0.
- No orphan payable settlements: 0.
- No cash entries allocated to a period belonging to another barn: 0.
- No discrepancies between (original minus remaining) payables and settlement journal sums: 0.
- No discrepancies between bon header amount and summed bon lines: 0.
- No harvest sales with nonpositive weight/price: 0.
- Aggregate operating cash is IDR 8,550,000 (matches prior fixture).
- Employee advance outstanding is IDR 200,000 (matches prior fixture).

## Outstanding release blockers
- Independent concurrent PostgreSQL sessions must race topup and period closing.
- Real authenticated Owner/Admin login and RLS using issued JWTs; browser/iPhone UI and interrupted requests.
- Full production-cycle fixture with operational cost category completeness, mortality, stocked count and closed-period reconciliation.
- Staging period readiness only supports checks of presence; cannot certify absence of unentered costs.
- No production migration or merge is authorized. Keep finance writes disabled and PR #1 Draft.

**Decision: NO-GO for production or operational financial reporting.**
