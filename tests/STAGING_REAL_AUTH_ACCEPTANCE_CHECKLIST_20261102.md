# CHEGALLUSS staging REAL Auth acceptance checklist — 2026-11-02

Environment: Supabase `omyxasrvozbxzfdukaun`, GitHub Draft PR #1, `staging-test/index.html`. Do not use main database, service_role in browser, live finances, GitHub Actions, or TEVARA VPS.

## Current verified prerequisites
SQL staging inspection: password-based Auth users = **0**; enabled Admin roles = **1**; enabled Owner roles = **1**; synthetic mortality rows = **3**. Existing synthetic role records are not equivalent to sign-in-capable test accounts.
**REAL AUTH END-TO-END: BLOCKED / NOT RUN.**

## Safe provisioning and pairing (manual when an authorized staging administrator has suitable emails)
1. In the **staging** Supabase Dashboard, Authentication → Users → Add user → Send invitation, invite one Admin test email and one Owner test email; use addresses controlled by the tester, not made-up deliverable addresses.
2. After users accept, record their newly issued Auth user IDs. In staging only, pair these IDs with distinct `public.staff_roles` entries (`enabled=true`, `role='admin'` or `role='owner'`). Confirm existing synthetic account fixture IDs are not accidentally promoted or reused. Test using staging-specific email identities and do not paste passwords, tokens or secret keys into GitHub.
3. Do not enable open public signup or weaken RLS to simplify testing.

## End-to-end acceptance matrix
- Anonymous: app refuses access, authenticated-only mortality table and RPC unavailable.
- Admin: real Auth sign-in succeeds; choose open test period with positive initial_birds, enter one mortality row, refresh, see updated count. Duplicate date / negative / over-population / outside-period dates rejected; no partial write. Log out.
- Owner: real Auth sign-in succeeds; reads resulting row and period summary; cannot use or invoke the Admin-only write RPC. Log out.
- Disabled user and unknown user: no access to app or data.
- Session expiry and network loss: no false saved-success; retry safely; on invalid session application closes its content.
- Reconcile mortality with starting flock and harvest; remain UNVERIFIED until full stock/expense and sale reconciliation is done.

## Execution evidence (capture without secrets)
Record tested device, browser, UTC timestamp, Auth user ID suffix, scenario, expected and observed result, screenshot with identifying fields redacted, data row ID, and post-test clean-up. Stop on any unexpected Owner write or anonymous read.

## Release decision
**NO-GO** until real signed-in users, two-session race tests, full-cycle reconciliation, and rollback readiness are verified. Existing UI source checks and SQL claim simulations are not substitutes.
