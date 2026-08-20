/* PoolFlow Saltwater Salt Calculator
 *   lbs of salt = (target_ppm - current_ppm) * gallons * 8.34 / 1,000,000
 *   8.34 = weight (lb) of one US gallon of water; ppm = mg/L.
 *   40-lb bags = lbs / 40.  If current >= target, no salt is needed.
 * Vanilla JS — matches the conventions in lsi-calculator.js.
 */
(function () {
  'use strict';

  var root = document.querySelector('[data-salt-calculator]');
  if (!root) return;

  // Localized runtime strings injected by the page (window.PF_SALT_I18N); English fallbacks below.
  var I = (typeof window !== 'undefined' && window.PF_SALT_I18N) || {};
  var isAu = document.documentElement.lang === 'en-AU';

  var L_PER_GAL = 3.785411784;
  var LB_PER_GAL = 8.34;
  var KG_PER_LB = 0.45359237;
  var BAG_LB = 40;

  var state = { gallons: 15000, current: 0, target: 3200 };
  var volUnit = 'gal';

  var volNumber = root.querySelector('[data-salt-vol-number]');
  var volRange = root.querySelector('[data-salt-vol-range]');
  var volUnitBtn = root.querySelector('[data-salt-vol-unit]');
  var curNum = root.querySelector('[data-salt-current]');
  var curRange = root.querySelector('[data-salt-current-range]');
  var tgtNum = root.querySelector('[data-salt-target]');
  var tgtRange = root.querySelector('[data-salt-target-range]');

  var out = {
    primary: root.querySelector('[data-salt-primary]'),
    secondary: root.querySelector('[data-salt-secondary]'),
    guidance: root.querySelector('[data-salt-guidance]'),
    formula: root.querySelector('[data-salt-formula]')
  };

  function fmt(n) { return Math.round(n).toLocaleString('en-US'); }

  function render() {
    var delta = state.target - state.current;
    if (delta <= 0) {
      if (out.primary) out.primary.textContent = '0';
      if (out.secondary) out.secondary.textContent = isAu ? 'kg — no salt needed' : (I.secondary_none || 'lb — no salt needed');
      if (out.guidance) {
        out.guidance.textContent = delta === 0
          ? (I.guidance_at_target || 'You’re right at target. No salt needed.')
          : (I.guidance_over ||
              'You’re above target by %PPM% ppm. Salt can’t be removed chemically — partially drain and refill with fresh water to dilute.')
              .replace('%PPM%', fmt(-delta));
      }
      if (out.formula) out.formula.textContent = '';
      return;
    }

    var lbs = delta * state.gallons * LB_PER_GAL / 1000000;
    var bags = lbs / BAG_LB;
    var kg = lbs * KG_PER_LB;

    if (out.primary) out.primary.textContent = isAu ? fmt(kg) : fmt(lbs);
    if (out.secondary) {
      out.secondary.innerHTML = isAu
        ? 'kg &nbsp;·&nbsp; ≈ ' + (Math.round((kg / 20) * 10) / 10) + ' bags (20 kg)'
        : (I.secondary || 'lb &nbsp;·&nbsp; ≈ %BAGS% bags (40 lb) &nbsp;·&nbsp; %KG% kg')
          .replace('%BAGS%', (Math.round(bags * 10) / 10))
          .replace('%KG%', fmt(kg));
    }
    if (out.guidance) {
      out.guidance.textContent = (I.guidance_add ||
        'Raise salinity by %PPM% ppm. Add in stages with the pump running, then re-test after ~24 hours.')
        .replace('%PPM%', fmt(delta));
    }
    if (out.formula) {
      out.formula.textContent = isAu
        ? '(' + fmt(state.target) + ' − ' + fmt(state.current) + ') ppm × ' + fmt(state.gallons * L_PER_GAL) + ' L ÷ 1,000,000 = ' + fmt(kg) + ' kg'
        : (I.formula || '(%TARGET% − %CURRENT%) ppm × %GAL% gal × 8.34 ÷ 1,000,000 = %LBS% lb')
          .replace('%TARGET%', fmt(state.target))
          .replace('%CURRENT%', fmt(state.current))
          .replace('%GAL%', fmt(state.gallons))
          .replace('%LBS%', fmt(lbs));
    }
  }

  // Volume
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
      var unitName = volUnit === 'L' ? (I.unit_l || 'liters') : (I.unit_gal || 'gallons');
      this.setAttribute('aria-label', (I.unit_aria || 'Volume unit: %UNIT%. Tap to switch.').replace('%UNIT%', unitName));
      render();
    });
  }

  // Salinity pairs
  function bindPair(num, range, key) {
    if (num) num.addEventListener('input', function () { var n = parseFloat(this.value); if (isNaN(n)) return; if (range) range.value = this.value; state[key] = n; render(); });
    if (range) range.addEventListener('input', function () { var n = parseFloat(this.value); if (isNaN(n)) return; if (num) num.value = this.value; state[key] = n; render(); });
  }
  bindPair(curNum, curRange, 'current');
  bindPair(tgtNum, tgtRange, 'target');

  if (isAu && volUnitBtn) volUnitBtn.click();
  else render();
})();
