const test = require('node:test');
const assert = require('node:assert/strict');

const { adjustPrice } = require('../src/admin/price');

test('adjusts prices by percentage', () => {
  assert.equal(adjustPrice(100, { type: 'percentage', direction: 'up', amount: 10 }), 110);
  assert.equal(adjustPrice(100, { type: 'percentage', direction: 'down', amount: 10 }), 90);
});

test('rejects fixed adjustments that reach zero', () => {
  assert.equal(adjustPrice(10, { type: 'fixed', direction: 'down', amount: 10 }), null);
  assert.equal(adjustPrice(10, { type: 'fixed', direction: 'down', amount: 12 }), null);
});
