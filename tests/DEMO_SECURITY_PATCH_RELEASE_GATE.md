# DEMO security patch: coordinated review and testing

Status: **PROPOSED ONLY, NOT DEPLOYED**. No production SQL mutation.

## Fixed in proposed SQL
1. Harvest refuses barn/period combinations unless the period is `open`.
2. Topups require `number` to carry a stable UUID request ID, checked against a unique `topup_request_id` index.
3. Retry with same UUID, account and amount returns success without another deposit movement; reused UUID with changed amount/account throws REQUEST_ID_CONFLICT.
4. Staff admin check, deposit account locking, bon uniqueness and sale uniqueness are retained.

## Important coordinated client dependency
The current `v28-test/index.html` topup RPC sends no `number`. Deploying the SQL alone would make topups fail with REQUEST_ID_REQUIRED. The client MUST first be tested with a stable UUID per intended action. Preserve the same UUID on network retries/reload, discard it only after server-confirmed success, and block a changed amount using a previously pending UUID. Do not auto-submit payments on page reload. A new topup requires a new UUID.

## Required integration test before approval
- Non-admin and anonymous topup/harvest denied.
- First topup posts once; double click and timed-out retry post once and return same balance.
- Retry with changed amount or account rejected.
- Concurrent same-key posting never creates duplicate rows.
- Closed period harvest rejected; open period harvest accepted only in isolated test DB.
- Existing bon, harvest idempotency, payable settlement and account row lock regressions.
- API RPC argument mapping and iPhone button behavior verified after coordinated client update.

Run offline static checks: `node --test tests/demo-security-patch.test.mjs`.
These tests inspect source, NOT database transaction behavior.

Do NOT paste the patch into the live Supabase SQL Editor or merge PR #1 before isolated PostgreSQL end-to-end testing and explicit approval.
