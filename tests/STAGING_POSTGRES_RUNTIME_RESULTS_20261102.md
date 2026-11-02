# CHEGALLUSS staging actual PostgreSQL test results — 2026-11-02

**Scope:** staging project `omyxasrvozbxzfdukaun` only. Main production project `chcpzczdshlioguzelvz` unchanged. All test values are synthetic. No GitHub Actions or TEVARA infrastructure.

## Confirmed PostgreSQL runtime PASS

Migrations executed successfully on staging using Supabase `apply_migration` and SQL assertions in PL/pgSQL `DO` blocks (failing any assertion would fail the migration):

1. `chegalluss_staging_runtime_regression_01`: same request UUID and same account/amount replies `duplicate=true`, does not add second credit; changed amount returns `REQUEST_ID_CONFLICT`; null amount returns `INVALID_AMOUNT`; Owner, disabled Admin, and absent identity all return `ADMIN_REQUIRED`.
2. `chegalluss_staging_runtime_reconciliation_02`: one bon for Rp1,500,000 uses Rp1,000,000 deposit, produces Rp500,000 payable; one harvest for Rp2,000,000 clears Rp500,000 payable and adds Rp1,500,000 deposit credit. A closed-period bon and harvest are rejected. Check final debt zero, settlement count one and ledger balance Rp1,500,000.
3. `chegalluss_staging_runtime_negative_03`: replay UUID on another account rejected; invalid UUID, negative, fractional and excessive topups rejected; repeated bon number and harvest reference rejected.
4. Read-only verification after: ledger `topup +1,000,000; bon -1,000,000; harvest_credit +1,500,000`; 1 bon, 1 harvest, 1 settlement, payable outstanding 0.
5. 11/11 public staging tables RLS enabled. Both demo RPCs have `anon EXECUTE=false`, `authenticated EXECUTE=true`. Authenticated RPCs additionally check enabled Admin in `staff_roles`.

## Still UNVERIFIED (release blockers)

- Two truly **parallel** independent PostgreSQL sessions racing to insert the same request UUID on same/different accounts (no independent session control provided by current Supabase SQL tool).
- Concurrent period close vs posting in two sessions.
- End-to-end browser/iPhone authenticated sessions, localStorage lost-response retry.
- Complete operational cash, employee advances, and BEP reconciliation. Staging currently contains the *11 DEMO/fixture tables*, not the complete main project schema.
- Full live Supabase Auth API/real login testing. Identity tests use synthetic `auth.users` fixtures and `request.jwt.claim.sub` set in a local SQL transaction, not issued JWTs.

**Decision:** functional DEMO posting regression substantially PASS, but project NOT FINAL / do not enable DEMO topup on branch or merge PR #1. Apply no patch to main project until blockers are resolved and owner authorizes deployment.

**Note:** An earlier repeat RPC request through the direct SQL connector was blocked by tool safety controls; retry assertions succeeded via staging-only migrations.
