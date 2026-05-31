/* PoolFlow LSI Calculator
 * Mirrors the methodology in /blog/langelier-saturation-index-explained/ so the
 * tool and the published explainer always agree:
 *   LSI = pH + TF + CF + AF - TDS_constant
 *   adjustedAlkalinity = max(0, TotalAlkalinity - CYA / 3)
 * TF/CF/AF come from the blog's lookup tables with linear interpolation.
 * Vanilla JS, no dependencies — matches the conventions in main.js.
 */
(function () {
  'use strict';

  var root = document.querySelector('[data-lsi-calculator]');
  if (!root) return;

  // Localized runtime strings injected by the page (window.PF_LSI_I18N); English fallbacks below.
  var I = (typeof window !== 'undefined' && window.PF_LSI_I18N) || {};

  // --- Lookup tables (°F / ppm -> factor), from the LSI explainer blog post ---
  var TF = [[32, 0.0], [37, 0.1], [46, 0.2], [53, 0.3], [60, 0.4], [66, 0.5], [76, 0.6], [84, 0.7], [94, 0.8], [105, 0.9]];
  var CF = [[25, 1.0], [50, 1.3], [75, 1.5], [100, 1.6], [150, 1.8], [200, 1.9], [250, 2.0], [300, 2.1], [400, 2.2], [500, 2.3], [800, 2.5], [1000, 2.6]];
  var AF = [[25, 1.4], [50, 1.7], [75, 1.9], [100, 2.0], [120, 2.1], [150, 2.2], [200, 2.3], [250, 2.4], [300, 2.5], [400, 2.6]];

  function interp(table, x) {
    if (x <= table[0][0]) return table[0][1];
    var last = table[table.length - 1];
    if (x >= last[0]) return last[1];
    for (var i = 0; i < table.length - 1; i++) {
      var a = table[i], b = table[i + 1];
      if (x >= a[0] && x <= b[0]) {
        return a[1] + (b[1] - a[1]) * (x - a[0]) / (b[0] - a[0]);
      }
    }
    return last[1];
  }

  function tdsConstant(tds) { return tds >= 3000 ? 12.2 : 12.1; }
  function cToF(c) { return c * 9 / 5 + 32; }
  function round(n, d) { var f = Math.pow(10, d || 0); return Math.round(n * f) / f; }

  // --- State ---
  var state = { pH: 7.5, tempF: 80, ch: 300, ta: 100, cya: 50, tds: 1000 };
  var tempUnit = 'F'; // 'F' or 'C'

  // --- Elements ---
  var els = {};
  ['pH', 'temp', 'ch', 'ta', 'cya', 'tds'].forEach(function (key) {
    els[key] = {
      range: root.querySelector('[data-lsi-range="' + key + '"]'),
      number: root.querySelector('[data-lsi-number="' + key + '"]')
    };
  });
  var out = {
    value: root.querySelector('[data-lsi-value]'),
    badge: root.querySelector('[data-lsi-status]'),
    statusText: root.querySelector('[data-lsi-status-text]'),
    guidance: root.querySelector('[data-lsi-guidance]'),
    formula: root.querySelector('[data-lsi-formula]'),
    bTf: root.querySelector('[data-lsi-tf]'),
    bCf: root.querySelector('[data-lsi-cf]'),
    bAf: root.querySelector('[data-lsi-af]'),
    bAdj: root.querySelector('[data-lsi-adj]'),
    bK: root.querySelector('[data-lsi-k]'),
    tempUnit: root.querySelector('[data-lsi-temp-unit]')
  };

  function compute() {
    var adj = Math.max(0, state.ta - state.cya / 3);
    var tf = interp(TF, state.tempF);
    var cf = interp(CF, state.ch);
    var af = interp(AF, adj);
    var k = tdsConstant(state.tds);
    var lsi = state.pH + tf + cf + af - k;
    return { lsi: lsi, tf: tf, cf: cf, af: af, adj: adj, k: k };
  }

  function classify(lsi) {
    if (lsi < -0.3) return 'corrosive';
    if (lsi > 0.3) return 'scaling';
    return 'balanced';
  }

  function guidanceFor(stateKey, lsi) {
    var signed = (lsi > 0 ? '+' : '') + round(lsi, 2);
    if (stateKey === 'balanced') {
      return I.guidance_balanced ||
        'Your water is balanced (LSI between −0.3 and +0.3). It won’t corrode surfaces or form scale — maintain these levels.';
    }
    if (stateKey === 'corrosive') {
      return (I.guidance_corrosive ||
        'Water is corrosive (LSI %LSI%). Low LSI water can etch plaster, dissolve grout, and corrode metal fittings and heaters. To raise LSI, increase pH, total alkalinity, or calcium hardness.').replace('%LSI%', signed);
    }
    return (I.guidance_scaling ||
      'Water is scale-forming (LSI %LSI%). High LSI water can deposit calcium scale on surfaces, salt cells, and heat exchangers, and cloud the water. To lower LSI, reduce pH, total alkalinity, or calcium hardness.').replace('%LSI%', signed);
  }

  function render() {
    var r = compute();
    var lsiDisplay = (r.lsi > 0 ? '+' : '') + round(r.lsi, 2).toFixed(2);
    var kind = classify(r.lsi);

    if (out.value) out.value.textContent = lsiDisplay;
    if (out.badge) out.badge.setAttribute('data-state', kind);
    if (out.statusText) out.statusText.textContent = I['status_' + kind] || (kind.charAt(0).toUpperCase() + kind.slice(1));
    if (out.guidance) out.guidance.textContent = guidanceFor(kind, r.lsi);

    if (out.bTf) out.bTf.textContent = '+' + r.tf.toFixed(2);
    if (out.bCf) out.bCf.textContent = '+' + r.cf.toFixed(2);
    if (out.bAf) out.bAf.textContent = '+' + r.af.toFixed(2);
    if (out.bAdj) out.bAdj.textContent = round(r.adj, 0) + ' ppm';
    if (out.bK) out.bK.textContent = '−' + r.k.toFixed(1);
    if (out.formula) {
      out.formula.textContent = 'LSI = ' + state.pH.toFixed(1) + ' (' + (I.f_ph || 'pH') + ') + ' + r.tf.toFixed(2) +
        ' (' + (I.f_temp || 'temp') + ') + ' + r.cf.toFixed(2) + ' (' + (I.f_calcium || 'calcium') + ') + ' + r.af.toFixed(2) +
        ' (' + (I.f_alkalinity || 'alkalinity') + ') − ' + r.k.toFixed(1) + ' = ' + lsiDisplay;
    }
  }

  // --- Sync a slider/number pair to a state key ---
  function bindPair(key, stateKey, parse) {
    var pair = els[key];
    if (!pair.range || !pair.number) return;
    function update(v) {
      var n = parse ? parse(v) : parseFloat(v);
      if (isNaN(n)) return;
      pair.range.value = n;
      pair.number.value = n;
      if (key === 'temp') {
        state.tempF = tempUnit === 'C' ? cToF(n) : n;
      } else {
        state[stateKey] = n;
      }
      render();
    }
    pair.range.addEventListener('input', function () { update(this.value); });
    pair.number.addEventListener('input', function () { update(this.value); });
  }

  bindPair('pH', 'pH');
  bindPair('temp', 'tempF');
  bindPair('ch', 'ch');
  bindPair('ta', 'ta');
  bindPair('cya', 'cya');
  bindPair('tds', 'tds');

  // --- Temperature unit toggle (°F <-> °C) ---
  if (out.tempUnit) {
    out.tempUnit.addEventListener('click', function () {
      var pair = els.temp;
      var current = parseFloat(pair.number.value);
      if (tempUnit === 'F') {
        tempUnit = 'C';
        var c = Math.round((current - 32) * 5 / 9);
        pair.range.min = 0; pair.range.max = 40; pair.range.step = 1;
        pair.number.min = 0; pair.number.max = 40; pair.number.step = 1;
        pair.range.value = c; pair.number.value = c;
        state.tempF = cToF(c);
        this.textContent = '°C';
      } else {
        tempUnit = 'F';
        var f = Math.round(cToF(current));
        pair.range.min = 32; pair.range.max = 105; pair.range.step = 1;
        pair.number.min = 32; pair.number.max = 105; pair.number.step = 1;
        pair.range.value = f; pair.number.value = f;
        state.tempF = f;
        this.textContent = '°F';
      }
      this.setAttribute('aria-label', 'Temperature unit: ' + (tempUnit === 'F' ? 'Fahrenheit' : 'Celsius') + '. Tap to switch.');
      render();
    });
  }

  render();
})();
