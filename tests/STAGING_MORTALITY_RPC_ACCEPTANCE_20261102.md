# Staging mortality RPC acceptance checks — 2026-11-02

Project: `omyxasrvozbxzfdukaun`. All examples are synthetic. Main database unchanged.

## Executed
- Migration `staging_mortality_rpc_negative_access_checks`: PASS. Simulated PostgreSQL JWT claim contexts verified that enabled Admin cannot write without initial flock population, cannot write to closed period, Owner cannot write, and disabled Admin cannot write. No rows inserted.
- Migration `staging_mortality_rpc_valid_rollback_check`: PASS. Temporarily set initial flock to 500 for open test period, invoked RPC as synthetic enabled Admin for seven deaths, verified JSON status OK and 493 estimated survivors, then rolled back both fixture and write. Original initial_birds remained NULL and no test mortality row persisted.

## Limits
These are database-local tests with synthetic request.jwt.claim.sub settings, NOT authenticated browser sessions or API-issued JWT verification. No iPhone E2E performed. Financial writes remain off; mortalities recorded by Admin through real UI are not yet browser-tested. Real concurrency and full-cycle verified BEP are pending.

Decision: partial RPC acceptance PASS; project overall NO-GO.
