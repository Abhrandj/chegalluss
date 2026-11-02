// Pure, offline finance invariants. No Supabase connectivity or data writes.
// Run: node --test tests/finance-invariants.test.mjs
import test from 'node:test';
import assert from 'node:assert/strict';

function newLedger() { return { cash: new Map(), advances: new Map(), requests: new Set(), expenses: new Map(), deposit: 0 }; }
function post(l, t) {
  if (!t || !t.request || !t.admin || !Number.isSafeInteger(t.amount) || t.amount <= 0) throw Error('INVALID_OR_UNAUTHORIZED');
  if (l.requests.has(t.request)) throw Error('DUPLICATE_REQUEST');
  const k = String(t.employeeId ?? '');
  const account = String(t.accountId ?? '');
  if (t.type === 'expense') {
    if (!account || !t.barnId || !t.periodId || t.periodBarnId !== t.barnId) throw Error('INVALID_ALLOCATION');
    l.cash.set(account, (l.cash.get(account) ?? 0) - t.amount);
    const key = t.barnId + '/' + t.periodId;
    l.expenses.set(key,(l.expenses.get(key) ?? 0) + t.amount);
  } else if (t.type === 'advance' || t.type === 'repayment' || t.type === 'payroll_deduction') {
    if (!k || !account) throw Error('MISSING_EMPLOYEE_OR_ACCOUNT');
    const current = l.advances.get(k) ?? 0;
    if (t.type !== 'advance' && current < t.amount) throw Error('ADVANCE_EXCEEDS_BALANCE');
    l.advances.set(k, current + (t.type === 'advance' ? t.amount : -t.amount));
    if (t.type !== 'payroll_deduction') l.cash.set(account,(l.cash.get(account) ?? 0) + (t.type === 'advance' ? -t.amount : t.amount));
  } else throw Error('UNKNOWN_TRANSACTION');
  l.requests.add(t.request);
}
test('expense decreases only its own cash account and allocates by period', () => {
 const l=newLedger();post(l,{request:'a',admin:true,type:'expense',amount:750000,accountId:'ops',barnId:'toto',periodId:'p3',periodBarnId:'toto'});
 assert.equal(l.cash.get('ops'),-750000);assert.equal(l.cash.get('other')??0,0);assert.equal(l.expenses.get('toto/p3'),750000);assert.equal(l.deposit,0);
});
test('two workers with same display name remain separate by employee ID', () => {
 const l=newLedger();for (const [request,employeeId] of [['a','empA'],['b','empB']]) post(l,{request,admin:true,type:'advance',amount:100000,employeeId,accountId:'ops'});
 post(l,{request:'c',admin:true,type:'repayment',amount:60000,employeeId:'empA',accountId:'ops'});
 assert.equal(l.advances.get('empA'),40000);assert.equal(l.advances.get('empB'),100000);
});
test('duplicate request blocks any second cash or advance posting',()=>{
 const l=newLedger();const t={request:'fixed-uuid',admin:true,type:'advance',amount:30000,employeeId:'emp',accountId:'ops'};
 post(l,t);assert.throws(()=>post(l,t),/DUPLICATE_REQUEST/);assert.equal(l.advances.get('emp'),30000);
});
test('repayment over balance rejects without mutating data',()=>{
 const l=newLedger();post(l,{request:'a',admin:true,type:'advance',amount:50000,employeeId:'emp',accountId:'ops'});
 assert.throws(()=>post(l,{request:'b',admin:true,type:'repayment',amount:50001,employeeId:'emp',accountId:'ops'}),/ADVANCE_EXCEEDS_BALANCE/);
 assert.equal(l.advances.get('emp'),50000);assert.equal(l.cash.get('ops'),-50000);assert.equal(l.requests.has('b'),false);
});
test('payroll deduction reduces advance, not cash',()=>{
 const l=newLedger();post(l,{request:'a',admin:true,type:'advance',amount:50000,employeeId:'emp',accountId:'ops'});
 post(l,{request:'b',admin:true,type:'payroll_deduction',amount:20000,employeeId:'emp',accountId:'ops'});
 assert.equal(l.advances.get('emp'),30000);assert.equal(l.cash.get('ops'),-50000);
});
test('unauthorized and mismatched period submissions fail closed',()=>{
 const l=newLedger();assert.throws(()=>post(l,{request:'bad',admin:false,type:'expense',amount:100,accountId:'ops',barnId:'toto',periodId:'p3',periodBarnId:'toto'}),/INVALID_OR_UNAUTHORIZED/);
 assert.throws(()=>post(l,{request:'bad2',admin:true,type:'expense',amount:100,accountId:'ops',barnId:'toto',periodId:'p3',periodBarnId:'suncang'}),/INVALID_ALLOCATION/);
 assert.equal(l.cash.size,0);assert.equal(l.requests.size,0);
});
test('cash and advance postings never modify distributor deposit',()=>{
 const l=newLedger();l.deposit=9000000;
 post(l,{request:'a',admin:true,type:'advance',amount:10000,employeeId:'e',accountId:'ops'});
 assert.equal(l.deposit,9000000);
});
