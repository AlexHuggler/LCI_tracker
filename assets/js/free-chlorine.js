/* PoolFlow Free Chlorine Calculator
 * Uses the FC/CYA ratio from /blog/cya-cyanuric-acid-management/:
 *   manual pools — target FC ≈ 7.5% of CYA, minimum ≈ 5% of CYA
 *   saltwater (SWG) — target FC ≈ 5% of CYA, minimum ≈ 4% of CYA
 *   shock (SLAM) level ≈ 40% of CYA (both)
 * Small floors keep targets sensible at very low CYA (e.g. indoor pools).
 * Vanilla JS — matches the conventions in lsi-calculator.js.
 */
(function () {
  'use strict';

  var root = document.querySelector('[data-chlorine-calculator]');
  if (!root) return;

  var RATIOS = {
    manual: { min: 0.05, target: 0.075, shock: 0.40 },
    swg:    { min: 0.04, target: 0.05,  shock: 0.40 }
  };

  var state = { cya: 50, type: 'manual' };

  var cyaNum = root.querySelector('[data-fc-cya]');
  var cyaRange = root.querySelector('[data-fc-cya-range]');
  var out = {
    primary: root.querySelector('[data-fc-primary]'),
    min: root.querySelector('[data-fc-min]'),
    target: root.querySelector('[data-fc-target]'),
    shock: root.querySelector('[data-fc-shock]'),
    formula: root.querySelector('[data-fc-formula]')
  };

  // Round to nearest 0.5 for readable FC values
  function half(n) { return Math.round(n * 2) / 2; }
  function trim(n) { return (Math.round(n * 10) / 10).toString(); }

  function render() {
    var r = RATIOS[state.type];
    var minFc = Math.max(half(state.cya * r.min), 1);
    var targetFc = Math.max(half(state.cya * r.target), 2);
    if (targetFc < minFc) targetFc = minFc;
    var shockFc = Math.max(half(state.cya * r.shock), 10);

    if (out.primary) out.primary.textContent = trim(minFc) + '–' + trim(targetFc);
    if (out.min) out.min.textContent = trim(minFc) + ' ppm';
    if (out.target) out.target.textContent = trim(targetFc) + ' ppm';
    if (out.shock) out.shock.textContent = trim(shockFc) + ' ppm';
    if (out.formula) {
      var pct = (r.target * 100).toFixed(1).replace(/\.0$/, '');
      out.formula.textContent = 'Target ≈ ' + pct + '% of ' + state.cya + ' ppm CYA' +
        (state.type === 'swg' ? ' (saltwater)' : '') + ' = ' + trim(targetFc) + ' ppm. Shock at ~40% of CYA.';
    }
  }

  function setCya(v) { var n = parseFloat(v); if (isNaN(n)) return; state.cya = n; render(); }
  if (cyaNum) cyaNum.addEventListener('input', function () { if (cyaRange) cyaRange.value = this.value; setCya(this.value); });
  if (cyaRange) cyaRange.addEventListener('input', function () { if (cyaNum) cyaNum.value = this.value; setCya(this.value); });

  root.querySelectorAll('[data-fc-type]').forEach(function (btn) {
    btn.addEventListener('click', function () {
      state.type = this.getAttribute('data-fc-type');
      root.querySelectorAll('[data-fc-type]').forEach(function (b) {
        b.setAttribute('aria-pressed', b.getAttribute('data-fc-type') === state.type ? 'true' : 'false');
      });
      render();
    });
  });

  render();
})();
