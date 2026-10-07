'use strict';
const test = require('node:test');
const assert = require('node:assert/strict');
const { calculate, example } = require('../assets/js/route-cost-engine.js');
function near(actual, expected) { assert.ok(Math.abs(actual - expected) < 0.000001, `${actual} != ${expected}`); }
test('52 weekly services are allocated across 12 months and all cost categories', () => {
  const r = calculate(example);
  near(r.monthlyVisits, 520 / 3);
  near(r.chemicals, 2080 / 3);
  near(r.routeHours, 260 / 3);
  near(r.labor, 8320 / 3);
  near(r.travel, 1040 / 3);
  near(r.cost, 13540 / 3);
  near(r.surplus, 5660 / 3);
  near(r.breakEvenFee, 677 / 6);
  near(r.targetFee, 3385 / 24);
  near(r.extraVisitCost, 22);
});
test('a known two-pool route reaches its requested 25 percent margin', () => {
  const v = { pools: 2, fee: 200, visits: 4, chemicals: 10, serviceMinutes: 30, driveMinutes: 15, laborRate: 20, distance: 5, distanceCost: 1, overhead: 40, targetMargin: 25 };
  const r = calculate(v); near(r.cost, 280); near(r.surplus, 120); near(r.targetFee, 560 / 3);
  near(calculate({ ...v, fee: r.targetFee }).margin, 25);
});
test('zero revenue preserves costs without an infinite percentage', () => {
  const r = calculate({ ...example, fee: 0 }); assert.equal(r.margin, null); near(r.surplus, -r.cost); assert.ok(Number.isFinite(r.targetFee));
});
test('zero service visits preserves fixed overhead', () => {
  const r = calculate({ ...example, visits: 0 }); assert.equal(r.labor, 0); assert.equal(r.travel, 0); assert.equal(r.chemicals, 0); assert.equal(r.cost, 700);
});
test('rejects empty, nonfinite, negative and fractional pool inputs', () => {
  for (const patch of [{ pools: 0 }, { pools: 1.5 }, { fee: '' }, { overhead: NaN }, { visits: Infinity }, { chemicals: -1 }, { targetMargin: 100 }]) assert.throws(() => calculate({ ...example, ...patch }), RangeError);
});
test('owner cash and allowance are distinct rather than subtracting labor twice', () => {
  const r = calculate(example); near(r.beforeLabor - r.labor, r.surplus);
});
test('target margin is not treated as a cost markup', () => {
  const r = calculate({ ...example, targetMargin: 50 }); near(r.targetFee, r.breakEvenFee * 2);
});
