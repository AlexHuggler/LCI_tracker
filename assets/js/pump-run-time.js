/* PoolFlow Pump Run-Time / Turnover Calculator
 *   turnover (hours) = gallons / (flowGPM * 60)
 *   daily run hours  = turnovers * turnover
 *   water moved/day  = flowGPM * 60 * dailyRunHours  (= turnovers * gallons)
 * Volume can be entered in gallons or liters; flow is in GPM (computed in gallons).
 * Vanilla JS — matches the conventions in lsi-calculator.js.
 */
(function () {
  'use strict';

  var root = document.querySelector('[data-pump-calculator]');
  if (!root) return;

  // Localized runtime strings injected by the page (window.PF_TURNOVER_I18N); English fallbacks below.
  var I = (typeof window !== 'undefined' && window.PF_TURNOVER_I18N) || {};
  var isAu = document.documentElement.lang === 'en-AU';

  var L_PER_GAL = 3.785411784;

  var state = { gallons: 15000, flow: 60, turnovers: 2 };
  var volUnit = 'gal';

  var volNumber = root.querySelector('[data-pump-vol-number]');
  var volRange = root.querySelector('[data-pump-vol-range]');
  var volUnitBtn = root.querySelector('[data-pump-vol-unit]');
  var flowNum = root.querySelector('[data-pump-flow]');
  var flowRange = root.querySelector('[data-pump-flow-range]');
  var toNum = root.querySelector('[data-pump-turnovers]');
  var toRange = root.querySelector('[data-pump-turnovers-range]');

  var out = {
    primary: root.querySelector('[data-pump-primary]'),
    turnover: root.querySelector('[data-pump-turnover]'),
    perday: root.querySelector('[data-pump-perday]'),
    formula: root.querySelector('[data-pump-formula]')
  };

  function round(n, d) { var f = Math.pow(10, d || 0); return Math.round(n * f) / f; }
  function fmt(n) { return Math.round(n).toLocaleString('en-US'); }

  function render() {
    var turnoverHrs = state.flow > 0 ? state.gallons / (state.flow * 60) : 0;
    var daily = turnoverHrs * state.turnovers;
    var movedGal = state.turnovers * state.gallons;
    var movedL = movedGal * L_PER_GAL;

    var hrs = I.hrs || 'hrs';
    if (out.primary) out.primary.textContent = round(daily, 1);
    if (out.turnover) out.turnover.textContent = round(turnoverHrs, 1) + ' ' + hrs;
    if (out.perday) out.perday.textContent = volUnit === 'L' ? fmt(movedL) + ' L' : fmt(movedGal) + ' gal';
    if (out.formula) {
      out.formula.textContent = (isAu
        ? fmt(state.gallons * L_PER_GAL) + ' L ÷ (' + fmt(state.flow * L_PER_GAL) + ' L/min × 60) = '
        : fmt(state.gallons) + ' gal ÷ (' + state.flow + ' GPM × 60) = ') +
        round(turnoverHrs, 1) + ' ' + (I.per_turnover || 'hrs/turnover') + ' × ' + state.turnovers + ' = ' + round(daily, 1) + ' ' + (I.per_day || 'hrs/day');
    }
  }

  function setVol(v) { var n = parseFloat(v); if (isNaN(n)) return; state.gallons = volUnit === 'L' ? n / L_PER_GAL : n; render(); }
  if (volNumber) volNumber.addEventListener('input', function () { volRange.value = this.value; setVol(this.value); });
  if (volRange) volRange.addEventListener('input', function () { volNumber.value = this.value; setVol(this.value); });
  if (volUnitBtn) {
    volUnitBtn.addEventListener('click', function () {
      if (volUnit === 'gal') {
        volUnit = 'L';
        var liters = Math.round(state.gallons * L_PER_GAL);
        volNumber.min = 4000; volNumber.max = 190000; volNumber.step = 1000;
        volRange.min = 4000; volRange.max = 190000; volRange.step = 1000;
        volNumber.value = liters; volRange.value = liters;
        this.textContent = 'L';
      } else {
        volUnit = 'gal';
        var gal = Math.round(state.gallons);
        volNumber.min = 1000; volNumber.max = 100000; volNumber.step = 500;
        volRange.min = 1000; volRange.max = 50000; volRange.step = 500;
        volNumber.value = gal; volRange.value = gal;
        this.textContent = 'gal';
      }
      this.setAttribute('aria-label', volUnit === 'L'
        ? (I.vol_unit_l_aria || 'Volume unit: liters. Tap to switch.')
        : (I.vol_unit_gal_aria || 'Volume unit: gallons. Tap to switch.'));
      render();
    });
  }

  function bindPair(num, range, key) {
    if (num) num.addEventListener('input', function () { var n = parseFloat(this.value); if (isNaN(n)) return; if (range) range.value = this.value; state[key] = n; render(); });
    if (range) range.addEventListener('input', function () { var n = parseFloat(this.value); if (isNaN(n)) return; if (num) num.value = this.value; state[key] = n; render(); });
  }
  function bindFlow(num, range) {
    if (num) num.addEventListener('input', function () { var n = parseFloat(this.value); if (isNaN(n)) return; if (range) range.value = this.value; state.flow = isAu ? n / L_PER_GAL : n; render(); });
    if (range) range.addEventListener('input', function () { var n = parseFloat(this.value); if (isNaN(n)) return; if (num) num.value = this.value; state.flow = isAu ? n / L_PER_GAL : n; render(); });
  }
  bindFlow(flowNum, flowRange);
  bindPair(toNum, toRange, 'turnovers');

  if (isAu && volUnitBtn) {
    volUnitBtn.click();
    [flowNum, flowRange].forEach(function (el) { if (el) { el.min = 40; el.max = 600; el.step = 5; el.value = 225; } });
    state.flow = 225 / L_PER_GAL;
    render();
  }
  else render();
})();
