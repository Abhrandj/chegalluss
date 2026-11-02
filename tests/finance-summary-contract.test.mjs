import test from 'node:test';
import assert from 'node:assert/strict';

// Mirrors the dashboard's strict server-aggregate validation contract.
function validFinanceSummary(error, raw) {
  const aggregate = Array.isArray(raw) ? raw[0] : raw;
  const keys = ['cash_movements_count','cash_net_idr','advance_movements_count','advance_outstanding_idr'];
  return !error && Boolean(aggregate) &&
    keys.every(k => aggregate[k] !== null && aggregate[k] !== undefined &&
      Number.isFinite(Number(aggregate[k])) && Number.isSafeInteger(Number(aggregate[k]))) &&
    Number(aggregate.cash_movements_count) >= 0 &&
    Number(aggregate.advance_movements_count) >= 0 &&
    Number(aggregate.advance_outstanding_idr) >= 0;
}
const good = {cash_movements_count:1005,cash_net_idr:-175000,advance_movements_count:1005,advance_outstanding_idr:120000};
test('large counts pass without a 1000-row limit',()=>assert.equal(validFinanceSummary(null,[good]),true));
test('missing RPC response fails closed',()=>assert.equal(validFinanceSummary(null,null),false));
test('RPC authorization error fails closed',()=>assert.equal(validFinanceSummary({message:'permission denied'},[good]),false));
test('empty response fails closed',()=>assert.equal(validFinanceSummary(null,[]),false));
test('negative counts rejected',()=>assert.equal(validFinanceSummary(null,[{...good,cash_movements_count:-1}]),false));
test('negative employee advance balance rejected',()=>assert.equal(validFinanceSummary(null,[{...good,advance_outstanding_idr:-50}]),false));
test('unsafe numeric precision rejected',()=>assert.equal(validFinanceSummary(null,[{...good,cash_net_idr:'9007199254740993'}]),false));
test('null aggregates rejected',()=>assert.equal(validFinanceSummary(null,[{...good,cash_net_idr:null}]),false));
test('negative cash net permitted because it is a signed movement total',()=>assert.equal(validFinanceSummary(null,[good]),true));
