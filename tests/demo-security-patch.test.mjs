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
