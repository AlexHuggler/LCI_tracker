/* PoolFlow Chemical Dosing Calculator
 * Uses the same dosing rates as PoolFlow's in-app engine and the published
 * guide at /blog/chemical-dosing-calculations-pool-service/:
 *   Lower pH  — muriatic acid 31.45%: 26 fl oz / 0.2 pH / 10,000 gal
 *   Raise pH  — soda ash:              6 oz   / 0.2 pH / 10,000 gal
 *   Raise TA  — sodium bicarbonate:   24 oz   / 10 ppm / 10,000 gal
 *   Raise CH  — calcium chloride 77%: 20 oz   / 10 ppm / 10,000 gal
 * volumeFactor = gallons / 10,000. Doses round up to the nearest ounce.
 * Lowering TA (acid + aeration) and CH (dilution) are flagged, not dosed.
 * Vanilla JS — matches the conventions in lsi-calculator.js.
 */
(function () {
  'use strict';

  var root = document.querySelector('[data-dosing-calculator]');
  if (!root) return;

  // Localized runtime strings injected by the page (window.PF_DOSING_I18N); English fallbacks below.
  var I = (typeof window !== 'undefined' && window.PF_DOSING_I18N) || {};
  var isAu = document.documentElement.lang === 'en-AU';

  var L_PER_GAL = 3.785411784;

  // Per-ounce cost estimates (USD), typical retail for a service tech
  var COST = { acid: 0.05, sodaAsh: 0.09, bicarb: 0.04, calcium: 0.07 };

  var state = {
    gallons: 20000,
    ph: { cur: 7.8, tgt: 7.5 },
    ta: { cur: 70, tgt: 100 },
    ch: { cur: 200, tgt: 300 }
  };
  var volUnit = 'gal'; // 'gal' or 'L'

  var volNumber = root.querySelector('[data-dose-vol-number]');
  var volRange = root.querySelector('[data-dose-vol-range]');
  var volUnitBtn = root.querySelector('[data-dose-vol-unit]');
  var resultsEl = root.querySelector('[data-dose-results]');
  var emptyEl = root.querySelector('[data-dose-empty]');
  var totalEl = root.querySelector('[data-dose-total]');

  function ceil(n) { return Math.ceil(n - 1e-9); }
  function money(n) { return '$' + n.toFixed(2); }

  // Friendly secondary unit for a dose given as ounces
  function liquidNote(floz) {
    if (floz >= 128) return (floz / 128).toFixed(2) + ' gal';
    if (floz >= 8) return (floz / 8).toFixed(1) + ' cups';
    return null;
  }
  function dryNote(oz) {
    if (oz >= 16) return (oz / 16).toFixed(2) + ' lb';
    return null;
  }

  function compute() {
    var vf = state.gallons / 10000;
    var doses = [];
    var notes = [];

    var unitFloz = I.unit_floz || 'fl oz';
    var unitOz = I.unit_oz || 'oz';

    // pH
    var dPh = state.ph.cur - state.ph.tgt;
    if (dPh > 0.001) {
      var floz = ceil(26 * (dPh / 0.2) * vf);
      doses.push({ name: isAu ? 'Hydrochloric acid' : (I.name_acid || 'Muriatic acid'), sub: I.sub_acid || 'to lower pH', amount: floz, unit: unitFloz, extra: liquidNote(floz), cost: floz * COST.acid });
    } else if (dPh < -0.001) {
      var ozS = ceil(6 * (-dPh / 0.2) * vf);
      doses.push({ name: I.name_soda_ash || 'Soda ash', sub: I.sub_soda_ash || 'to raise pH', amount: ozS, unit: unitOz, extra: dryNote(ozS), cost: ozS * COST.sodaAsh });
    }

    // Total alkalinity
    var dTa = state.ta.tgt - state.ta.cur;
    if (dTa > 0.001) {
      var ozB = ceil(24 * (dTa / 10) * vf);
      doses.push({ name: I.name_bicarb || 'Baking soda', sub: I.sub_bicarb || 'sodium bicarbonate, to raise alkalinity', amount: ozB, unit: unitOz, extra: dryNote(ozB), cost: ozB * COST.bicarb });
    } else if (dTa < -0.001) {
      notes.push(I.note_alkalinity || 'Lower alkalinity with muriatic acid + aeration (a repeated cycle, not a single dose).');
    }

    // Calcium hardness
    var dCh = state.ch.tgt - state.ch.cur;
    if (dCh > 0.001) {
      var ozC = ceil(20 * (dCh / 10) * vf);
      doses.push({ name: I.name_calcium || 'Calcium chloride', sub: I.sub_calcium || '77%, to raise hardness', amount: ozC, unit: unitOz, extra: dryNote(ozC), cost: ozC * COST.calcium });
    } else if (dCh < -0.001) {
      notes.push(I.note_calcium || 'Calcium hardness can only be lowered by partial draining and refilling with softer water.');
    }

    return { doses: doses, notes: notes };
  }

  function render() {
    var r = compute();
    resultsEl.innerHTML = '';
    var total = 0;

    r.doses.forEach(function (d) {
      total += d.cost;
      var displayAmount = d.amount;
      var displayUnit = d.unit;
      var displayExtra = d.extra;
      if (isAu && d.unit === (I.unit_floz || 'fl oz')) {
        var millilitres = d.amount * 29.5735;
        displayAmount = millilitres >= 1000 ? (millilitres / 1000).toFixed(2) : Math.round(millilitres);
        displayUnit = millilitres >= 1000 ? 'L' : 'mL';
        displayExtra = null;
      } else if (isAu) {
        var grams = d.amount * 28.3495;
        displayAmount = grams >= 1000 ? (grams / 1000).toFixed(2) : Math.round(grams);
        displayUnit = grams >= 1000 ? 'kg' : 'g';
        displayExtra = null;
      }
      var amount = Number(displayAmount).toLocaleString(isAu ? 'en-AU' : 'en-US', { maximumFractionDigits: 2 });
      var extra = displayExtra ? ' <span class="text-gray-400">(' + displayExtra + ')</span>' : '';
      var row = document.createElement('div');
      row.className = 'flex items-start justify-between gap-3 bg-white rounded-lg p-3 border border-gray-200';
      row.innerHTML =
        '<div class="min-w-0">' +
          '<p class="font-semibold text-pool-dark">' + d.name + '</p>' +
          '<p class="text-xs text-gray-500">' + d.sub + '</p>' +
        '</div>' +
        '<div class="text-right flex-shrink-0">' +
          '<p class="font-bold text-pool-dark tabular-nums">' + amount + ' ' + displayUnit + extra + '</p>' +
          (isAu ? '' : '<p class="text-xs text-gray-500 tabular-nums">' + money(d.cost) + '</p>') +
        '</div>';
      resultsEl.appendChild(row);
    });

    r.notes.forEach(function (n) {
      var note = document.createElement('p');
      note.className = 'text-xs text-amber-700 bg-amber-50 border border-amber-200 rounded-lg p-3';
      note.textContent = n;
      resultsEl.appendChild(note);
    });

    if (emptyEl) emptyEl.hidden = (r.doses.length > 0 || r.notes.length > 0);
    if (totalEl && !isAu) totalEl.textContent = money(total);
  }

  // Volume binding
  function setVolFromDisplay(v) {
    var n = parseFloat(v);
    if (isNaN(n)) return;
    state.gallons = volUnit === 'L' ? n / L_PER_GAL : n;
    render();
  }
  if (volNumber) volNumber.addEventListener('input', function () { volNumber.value = this.value; volRange.value = this.value; setVolFromDisplay(this.value); });
  if (volRange) volRange.addEventListener('input', function () { volNumber.value = this.value; setVolFromDisplay(this.value); });

  if (volUnitBtn) {
    volUnitBtn.addEventListener('click', function () {
      if (volUnit === 'gal') {
        volUnit = 'L';
        var liters = Math.round(state.gallons * L_PER_GAL);
        [volNumber, volRange].forEach(function (el) { el.min = 4000; el.max = 190000; el.step = 1000; });
        volRange.max = 190000;
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
      this.setAttribute('aria-label', 'Volume unit: ' + (volUnit === 'L' ? 'liters' : 'gallons') + '. Tap to switch.');
      render();
    });
  }

  // Reading bindings
  ['ph', 'ta', 'ch'].forEach(function (key) {
    var cur = root.querySelector('[data-dose-current="' + key + '"]');
    var tgt = root.querySelector('[data-dose-target="' + key + '"]');
    if (cur) cur.addEventListener('input', function () { var n = parseFloat(this.value); if (!isNaN(n)) { state[key].cur = n; render(); } });
    if (tgt) tgt.addEventListener('input', function () { var n = parseFloat(this.value); if (!isNaN(n)) { state[key].tgt = n; render(); } });
  });

  if (isAu && volUnitBtn) volUnitBtn.click();
  else render();
})();
