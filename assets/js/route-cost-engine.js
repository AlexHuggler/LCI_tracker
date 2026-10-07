(function (root) {
  'use strict';
  var limits = {
    pools: [1, 5000], fee: [0, 100000], visits: [0, 31],
    chemicals: [0, 100000], serviceMinutes: [0, 1440], driveMinutes: [0, 1440],
    laborRate: [0, 10000], distance: [0, 10000], distanceCost: [0, 1000],
    overhead: [0, 10000000], targetMargin: [0, 95]
  };
  var example = {
    pools: 40, fee: 160, visits: 52 / 12, chemicals: 4,
    serviceMinutes: 20, driveMinutes: 10, laborRate: 32,
    distance: 4, distanceCost: 0.50, overhead: 700, targetMargin: 20
  };
  function calculate(input) {
    var v = {};
    Object.keys(limits).forEach(function (key) {
      var raw = input[key];
      if (typeof raw !== 'number' || !Number.isFinite(raw) || raw < limits[key][0] || raw > limits[key][1]) {
        throw new RangeError('Check ' + key + ': enter a number from ' + limits[key][0] + ' to ' + limits[key][1] + '.');
      }
      v[key] = raw;
    });
    if (!Number.isInteger(v.pools)) throw new RangeError('Pool count must be a whole number.');
    var visits = v.pools * v.visits;
    var hours = visits * (v.serviceMinutes + v.driveMinutes) / 60;
    var revenue = v.pools * v.fee;
    var chemicals = visits * v.chemicals;
    var travel = visits * v.distance * v.distanceCost;
    var labor = hours * v.laborRate;
    var cost = chemicals + travel + labor + v.overhead;
    var surplus = revenue - cost;
    return {
      monthlyVisits: visits, routeHours: hours, revenue: revenue,
      chemicals: chemicals, travel: travel, labor: labor, overhead: v.overhead,
      cost: cost, beforeLabor: revenue - chemicals - travel - v.overhead,
      surplus: surplus, margin: revenue > 0 ? surplus / revenue * 100 : null,
      breakEvenFee: cost / v.pools,
      targetFee: cost / (1 - v.targetMargin / 100) / v.pools,
      extraVisitCost: v.chemicals + (v.serviceMinutes + v.driveMinutes) / 60 * v.laborRate + v.distance * v.distanceCost,
      targetMargin: v.targetMargin
    };
  }
  var api = { calculate: calculate, example: example, limits: limits };
  if (typeof module === 'object' && module.exports) module.exports = api;
  else root.PoolRouteCosts = api;
})(typeof globalThis !== 'undefined' ? globalThis : this);
