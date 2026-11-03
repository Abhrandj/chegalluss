# CHEGALLUSS Finance acceptance & negative tests
Status: REVIEW ONLY. Do not apply SQL to active production for testing.

## Preconditions
- Verify RLS policy/GRANT inventory and functions in a disposable isolated database.
- Admin and Owner test identities; no shared credentials.
- Use actual employee IDs in production, not names, to avoid merging different people with identical names.
- Store separate bank/cash source or operating cash account and use proper opening balances.
- Establish an idempotency contract for HTTP retries; duplicate requests must return a stable record or a deterministic duplicate error.
- Consider a separate immutable accounting journal for cashbon and expense recognition.

## Required negative cases
1. Anonymous caller -> ADMIN_REQUIRED, zero rows.
2. Owner caller -> ADMIN_REQUIRED, zero rows.
3. Disabled admin -> ADMIN_REQUIRED, zero rows.
4. Zero/negative/overflow amount -> INVALID_INPUT, zero rows.
5. Missing/mismatched barn & period -> rejected, zero rows.
6. Replayed request UUID -> rejected, no duplicate cash movement.
7. Two concurrent payroll deductions/repayments against the same balance -> at most available balance.
8. Payroll deduction -> kasbon reduced, cash movement unchanged, payroll liability tracked separately.
9. Advance issuance -> kas decreases, receivable increases, P&L remains unchanged.
10. Repayment -> cash increases, receivable decreases, P&L remains unchanged.
11. Expense -> cash decreases, matching expense appears only once in the specified barn and period.
12. Failed second write in compound RPC -> entire transaction rolled back.
13. Owner visibility of all balances without INSERT/UPDATE/DELETE.
14. Admin cannot mutate posted rows directly or forge another actor.
15. Simulate 1,001+ rows -> dashboard refuses incomplete total, use server-side aggregates.
16. Cross-device retries and rapid double taps -> exactly one logical posting.
17. Date, amount formatting (45.000 / 45000), and UTC/local date consistency.
18. Deposit Ci Noni DEMO balance remains untouched by cash and employee advance actions.

## Blockers before production
- SQL has NOT been deployed and functions have NOT been tested.
- Operational cash currently lacks explicit account balances and dependable expense recognition.
- Employee names are not stable primary identifiers.
- Unique request UUID is generated on every submit and is not persisted across retries.
- Cashbon payroll deduction requires payroll ledger integration before financial signoff.
- No real BEP certification until inventory, rent, payroll and sales reconciliation are complete.
