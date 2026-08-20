/* PoolFlow Pool Volume Calculator
 * Mirrors the formulas in /blog/chemical-dosing-calculations-pool-service/:
 *   rect  = L * W * avgDepth * 7.48
 *   round = D * D * avgDepth * 5.9
 *   oval  = longD * shortD * avgDepth * 5.9
 *   free  = L * W * avgDepth * 7.48 * shapeFactor
 *   avgDepth = (shallow + deep) / 2
 * Dimensions are kept internally in FEET; the unit toggle converts the visible
 * fields to/from meters and shows the result in gallons or liters.
 * Vanilla JS, no dependencies — matches the conventions in lsi-calculator.js.
 */
(function () {
  'use strict';

  var root = document.querySelector('[data-volume-calculator]');
  if (!root) return;

  // Localized runtime strings injected by the page (window.PF_VOLUME_I18N); English fallbacks below.
  var I = (typeof window !== 'undefined' && window.PF_VOLUME_I18N) || {};

  var FT_PER_M = 3.280839895;
  var L_PER_GAL = 3.785411784;

  // Which fields each shape uses (besides the always-on depth fields)
  var SHAPE_FIELDS = {
    rect:  ['length', 'width'],
    round: ['diameter'],
    oval:  ['longD', 'shortD'],
    free:  ['length', 'width', 'factor']
  };
  var CONSTANT = { rect: 7.48, round: 5.9, oval: 5.9, free: 7.48 };

  // Imperial (ft) and metric (m) slider bounds per field
  var BOUNDS = {
    length:   { us: [5, 80, 1],    m: [1.5, 24, 0.5] },
    width:    { us: [5, 50, 1],    m: [1.5, 15, 0.5] },
    diameter: { us: [5, 50, 1],    m: [1.5, 15, 0.5] },
    longD:    { us: [8, 60, 1],    m: [2.5, 18, 0.5] },
    shortD:   { us: [5, 40, 1],    m: [1.5, 12, 0.5] },
    shallow:  { us: [1, 9, 0.5],   m: [0.3, 3, 0.1] },
    deep:     { us: [1, 15, 0.5],  m: [0.3, 4.5, 0.1] }
  };
  var DIM_KEYS = ['length', 'width', 'diameter', 'longD', 'shortD', 'shallow', 'deep'];

  var shape = 'rect';
  var unit = 'us'; // 'us' (feet/gallons) or 'm' (meters/liters)

  // Values stored in FEET (factor is unitless)
  var ft = { length: 32, width: 16, diameter: 24, longD: 32, shortD: 16, shallow: 3.5, deep: 6, factor: 0.5 };

  var els = {};
  DIM_KEYS.concat(['factor']).forEach(function (k) {
    els[k] = {
      number: root.querySelector('[data-vol-number="' + k + '"]'),
      range:  root.querySelector('[data-vol-range="' + k + '"]'),
      field:  root.querySelector('[data-field="' + k + '"]')
    };
  });
  var out = {
    primary:   root.querySelector('[data-vol-primary]'),
    secondary: root.querySelector('[data-vol-secondary]'),
    avgdepth:  root.querySelector('[data-vol-avgdepth]'),
    constant:  root.querySelector('[data-vol-constant]'),
    formula:   root.querySelector('[data-vol-formula]'),
    unitBtn:   root.querySelector('[data-vol-unit]')
  };

  function round(n, d) { var f = Math.pow(10, d || 0); return Math.round(n * f) / f; }
  function fmt(n) { return Math.round(n).toLocaleString(I.locale || 'en-US'); }
  function toDisp(valFt) { return unit === 'm' ? valFt / FT_PER_M : valFt; }      // ft -> displayed
  function fromDisp(v) { return unit === 'm' ? v * FT_PER_M : v; }                // displayed -> ft

  function compute() {
    var avgFt = (ft.shallow + ft.deep) / 2;
    var k = CONSTANT[shape];
    var gallons;
    if (shape === 'rect')  gallons = ft.length * ft.width * avgFt * k;
    else if (shape === 'round') gallons = ft.diameter * ft.diameter * avgFt * k;
    else if (shape === 'oval')  gallons = ft.longD * ft.shortD * avgFt * k;
    else gallons = ft.length * ft.width * avgFt * k * ft.factor;
    return { gallons: gallons, avgFt: avgFt, k: k };
  }

  function render() {
    var r = compute();
    var liters = r.gallons * L_PER_GAL;
    var avgDisp = toDisp(r.avgFt);
    var depthUnit = unit === 'm' ? (I.unit_m || 'm') : (I.unit_ft || 'ft');
    var gallonsWord = I.gallons || 'gallons';
    var litersWord = I.liters || 'liters';

    if (unit === 'm') {
      if (out.primary) out.primary.textContent = fmt(liters);
      if (out.secondary) out.secondary.textContent = '≈ ' + fmt(r.gallons) + ' ' + gallonsWord;
    } else {
      if (out.primary) out.primary.textContent = fmt(r.gallons);
      if (out.secondary) out.secondary.textContent = '≈ ' + fmt(liters) + ' ' + litersWord;
    }
    if (out.avgdepth) out.avgdepth.textContent = round(avgDisp, 2) + ' ' + depthUnit;
    if (out.constant) out.constant.textContent = '× ' + r.k + (shape === 'free' ? ' × ' + ft.factor.toFixed(2) : '');

    if (out.formula) {
      var dims;
      if (shape === 'rect') dims = round(toDisp(ft.length), 1) + ' × ' + round(toDisp(ft.width), 1);
      else if (shape === 'round') dims = round(toDisp(ft.diameter), 1) + ' × ' + round(toDisp(ft.diameter), 1);
      else if (shape === 'oval') dims = round(toDisp(ft.longD), 1) + ' × ' + round(toDisp(ft.shortD), 1);
      else dims = round(toDisp(ft.length), 1) + ' × ' + round(toDisp(ft.width), 1);
      var primaryUnit = unit === 'm' ? (' ' + litersWord) : (' ' + gallonsWord);
      var primaryVal = unit === 'm' ? fmt(liters) : fmt(r.gallons);
      out.formula.textContent = dims + ' × ' + round(avgDisp, 2) + ' (' + (I.avg_depth || 'avg depth') + ') → ' + primaryVal + primaryUnit;
    }
  }

  function applyShape() {
    var active = SHAPE_FIELDS[shape];
    DIM_KEYS.concat(['factor']).forEach(function (k) {
      if (!els[k].field) return;
      var show = (k === 'shallow' || k === 'deep') || active.indexOf(k) !== -1;
      els[k].field.hidden = !show;
    });
    root.querySelectorAll('[data-shape-btn]').forEach(function (b) {
      b.setAttribute('aria-pressed', b.getAttribute('data-shape-btn') === shape ? 'true' : 'false');
    });
    render();
  }

  // Set a field's displayed value + slider bounds for the current unit
  function syncFieldDisplay(k) {
    var pair = els[k];
    if (!pair.number || !pair.range) return;
    if (k === 'factor') { pair.number.value = ft.factor; pair.range.value = ft.factor; return; }
    var b = BOUNDS[k][unit];
    var disp = round(toDisp(ft[k]), unit === 'm' ? 1 : 1);
    [pair.number, pair.range].forEach(function (el) {
      el.min = b[0]; el.max = b[1]; el.step = b[2]; el.value = disp;
    });
  }

  function bind(k) {
    var pair = els[k];
    if (!pair.number || !pair.range) return;
    function update(v) {
      var n = parseFloat(v);
      if (isNaN(n)) return;
      pair.number.value = n;
      pair.range.value = n;
      ft[k] = (k === 'factor') ? n : fromDisp(n);
      render();
    }
    pair.range.addEventListener('input', function () { update(this.value); });
    pair.number.addEventListener('input', function () { update(this.value); });
  }
  DIM_KEYS.concat(['factor']).forEach(bind);

  root.querySelectorAll('[data-shape-btn]').forEach(function (btn) {
    btn.addEventListener('click', function () {
      shape = this.getAttribute('data-shape-btn');
      applyShape();
    });
  });

  if (out.unitBtn) {
    out.unitBtn.addEventListener('click', function () {
      unit = unit === 'us' ? 'm' : 'us';
      DIM_KEYS.forEach(syncFieldDisplay);
      var label = unit === 'm' ? (I.unit_m || 'm') : (I.unit_ft || 'ft');
      root.querySelectorAll('[data-unit-label]').forEach(function (el) { el.textContent = label; });
      this.textContent = unit === 'm' ? (I.toggle_metric || 'm / L') : (I.toggle_us || 'ft / gal');
      this.setAttribute('aria-label', unit === 'm'
        ? (I.aria_metric || 'Unit system: metric (meters & liters). Tap to switch to US.')
        : (I.aria_us || 'Unit system: US (feet & gallons). Tap to switch to metric.'));
      render();
    });
  }

  applyShape();
  if (document.documentElement.lang === 'en-AU' && out.unitBtn) out.unitBtn.click();
})();
