# Finance v2 implementation gate

Status: **BLOCKED FOR PRODUCTION**

## Required integration
- Kasbon: select employee ID (not free text) and display current outstanding balance.
- Kas Operasional: choose cash account, barn, and specific production period.
- Input form must retain one idempotency UUID across retries until server confirms success.
- Separate cash withdrawal, cost recognition, and repayment to prevent double counting.
- A sale credited to Ci Noni deposit is not a cash-account receipt.
- Closing balances must be reconciled against external cash/distributor records.

## Current blocker
The earlier draft `chegalluss_post_advance` accepts only a name, and
`chegalluss_post_cash` does not identify the cash account. Do not deploy
those RPCs as written. The SQL in this branch is review-only and intentionally
does not enable posting.

## Verification checklist
1. Two employees named "Budi": their advances remain isolated by ID.
2. Two cash accounts: posting to one leaves the other unchanged.
3. Replayed UUID: precisely one journal entry.
4. Concurrent repayments: cannot overdraw an outstanding advance.
5. Wrong admin role: blocked server-side.
6. Employee deactivated after UI load: blocked server-side.
7. Expense on mismatched period/kandang: blocked.
8. Payroll deduction reduces advance but not cash.
9. Negative operating cash permitted or blocked per explicit owner policy.
10. Cash and deposit ledgers never share entries or alter each other's balance.
11. No unverified BEP or profit claim.
12. Abnormal SQL/RLS errors shown as unknown, not zero.

Proceed only with isolated staging database/approved test harness before merge.
