(function () {
  'use strict';
  var form = document.getElementById('route-cost-form');
  if (!form || !window.PoolRouteCosts) return;
  var engine = window.PoolRouteCosts;
  var currency = document.getElementById('rc-currency');
  var error = document.getElementById('rc-error');
  var results = document.getElementById('rc-results');
  var lastResult = null;
  var lastInput = null;
  var labels = {
    pools: 'Pools on your route', fee: 'Service fee per pool / month', visits: 'Visits per pool / month',
    chemicals: 'Chemical cost per visit', serviceMinutes: 'Service minutes per visit',
    driveMinutes: 'Drive minutes per visit', laborRate: 'Labor allowance per hour',
    distance: 'Distance per visit', distanceCost: 'Vehicle cost per distance unit',
    overhead: 'Other overhead / month', targetMargin: 'Target margin (%)'
  };
  function readInput() {
    var input = {};
    Object.keys(engine.limits).forEach(function (key) {
      var field = form.elements.namedItem(key);
      if (field.value.trim() === '' || !field.validity.valid) throw new RangeError('Check ' + labels[key].toLowerCase() + '.');
      input[key] = field.valueAsNumber;
    });
    return input;
  }
  function money(value) {
    return new Intl.NumberFormat('en-US', { style: 'currency', currency: currency.value, maximumFractionDigits: 2 }).format(value);
  }
  function set(id, text) { document.getElementById(id).textContent = text; }
  function render() {
    try {
      lastInput = readInput();
      lastResult = engine.calculate(lastInput);
      error.hidden = true;
      results.hidden = false;
      document.getElementById('rc-export').disabled = false;
      set('rc-surplus', money(lastResult.surplus));
      document.getElementById('rc-surplus').classList.toggle('rc-negative', lastResult.surplus < 0);
      set('rc-margin', lastResult.margin === null ? 'No revenue entered' : lastResult.margin.toFixed(1) + '% of service revenue');
      ['revenue', 'chemicals', 'travel', 'labor', 'overhead', 'cost', 'beforeLabor', 'breakEvenFee', 'targetFee', 'extraVisitCost'].forEach(function (key) { set('rc-output-' + key, money(lastResult[key])); });
      set('rc-routeHours', lastResult.routeHours.toFixed(1) + ' hours / month');
      set('rc-targetLabel', 'Fee for your ' + lastResult.targetMargin + '% target margin');
      set('rc-unit-label', document.getElementById('rc-unit').value === 'km' ? 'Vehicle cost / km' : 'Vehicle cost / mile');
      set('rc-distance-label', document.getElementById('rc-unit').value === 'km' ? 'Kilometers per visit' : 'Miles per visit');
      set('rc-note', lastResult.surplus < 0 ? 'Your entered fee does not cover the costs and labor allowance in this scenario. Check missing costs and the accounts that need review.' : 'Compare this estimate with your actual service records. Seasonal chemistry, access delays and extra visits can change the result.');
    } catch (err) {
      lastResult = null;
      lastInput = null;
      error.textContent = err.message;
      error.hidden = false;
      results.hidden = true;
      document.getElementById('rc-export').disabled = true;
    }
  }
  form.addEventListener('input', render);
  form.addEventListener('change', render);
  form.addEventListener('submit', function (event) { event.preventDefault(); render(); });
  document.getElementById('rc-example').addEventListener('click', function () {
    Object.keys(engine.example).forEach(function (key) {
      form.elements.namedItem(key).value = key === 'visits' ? '4.333333' : String(engine.example[key]);
    });
    currency.value = 'USD';
    document.getElementById('rc-unit').value = 'mi';
    render();
  });
  document.getElementById('rc-export').addEventListener('click', function () {
    if (!lastResult || !lastInput) return;
    var rows = [['PoolFlow route cost planning estimate', 'Value'], ['Currency', currency.value], ['Distance unit', document.getElementById('rc-unit').value]];
    Object.keys(lastInput).forEach(function (key) { rows.push([labels[key], String(lastInput[key])]); });
    rows.push(['--- Monthly estimates ---', '']);
    Object.keys(lastResult).forEach(function (key) { rows.push([key, lastResult[key] === null ? 'undefined (zero revenue)' : String(lastResult[key])]); });
    rows.push(['Scope', 'Before taxes, debt payments, major repairs and capital purchases; includes only entered costs.'], ['Privacy', 'Created on your device; inputs are not sent to PoolFlow.']);
    var csv = rows.map(function (row) { return row.map(function (value) { return '"' + value.replace(/"/g, '""') + '"'; }).join(','); }).join('\r\n');
    var url = URL.createObjectURL(new Blob([csv], { type: 'text/csv;charset=utf-8' }));
    var link = document.createElement('a');
    link.href = url; link.download = 'pool-route-cost-estimate.csv'; link.click();
    setTimeout(function () { URL.revokeObjectURL(url); }, 1000);
  });
  render();
})();
