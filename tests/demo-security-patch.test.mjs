// Run locally: node --test tests/demo-security-patch.test.mjs
// Static regression checks. These are NOT PostgreSQL execution tests.
import test from 'node:test';
import assert from 'node:assert/strict';
import {readFileSync} from 'node:fs';
const sql=readFileSync(new URL('../proposed-migrations/20261102_demo_security_hardening_review.sql',import.meta.url),'utf8');
test('harvest requires OPEN period in SQL',()=>assert.match(sql,/barn_id=barn and status='open'/));
test('topup requires stable request ID',()=>assert.match(sql,/REQUEST_ID_REQUIRED/));
test('topup dedupe has DB unique index',()=>assert.match(sql,/CREATE UNIQUE INDEX IF NOT EXISTS demo_unique_topup_request/));
test('topup inserts ID into journal',()=>assert.match(sql,/topup_request_id\) values\(account,'topup',amount,uid,request_uuid\)/));
test('mismatched retry must be rejected',()=>assert.match(sql,/REQUEST_ID_CONFLICT/));
test('admin authorization retained in both functions',()=>assert.equal((sql.match(/raise exception 'ADMIN_REQUIRED'/g)||[]).length,2));
test('account row locking retained in both functions',()=>assert.equal((sql.match(/for update;/g)||[]).length>=2,true));
test('migration explicitly wrapped in transaction',()=>{assert.match(sql,/\bBEGIN;/);assert.match(sql,/\bCOMMIT;/)});

test('topup amount is validated before replay lookup',()=>{
 const topup=sql.slice(sql.indexOf("if action='topup' then"),sql.indexOf("if number is null or length(trim(number))"));
 assert.ok(topup.indexOf('INVALID_AMOUNT')>=0);
 assert.ok(topup.indexOf('INVALID_AMOUNT')<topup.indexOf('select m.account_id'));
});

test('SQL has exactly two complete function definitions',()=>{
 assert.equal((sql.match(/CREATE OR REPLACE FUNCTION/g)||[]).length,2);
 assert.equal((sql.match(/end \$function\$;/g)||[]).length,2);
});
test('topup retry is scoped to same account AND amount',()=>{
 assert.match(sql,/previous_account<>account or previous_amount<>amount/);
});
test('unique UUID index is global, so same request cannot post to another account',()=>{
 assert.match(sql,/demo_unique_topup_request ON public\.demo_deposit_movements\(topup_request_id\)/);
});
test('migration never changes staff role grants',()=>{
 assert.doesNotMatch(sql,/GRANT\s+(?:ALL|INSERT|UPDATE|DELETE)/i);
});
