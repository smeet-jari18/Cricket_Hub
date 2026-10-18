const test = require('node:test');
const assert = require('node:assert/strict');

const { bookingCreatedNotification } = require('../domain');

const ground = {
  kind: 'ground',
  counterparty_uid: 'owner_1',
  resource_name: 'Sardar Patel Cricket Ground',
  date: '2026-10-21',
  slot_start: '06:00',
  slot_end: '08:00',
  amount_paise: 120000,
  payment_method: 'cod',
};

test('bookingCreatedNotification — targets the counterparty topic', () => {
  const p = bookingCreatedNotification('b1', ground);
  assert.equal(p.topic, 'user_owner_1');
  assert.equal(p.data.type, 'booking_created');
  assert.equal(p.data.bookingId, 'b1');
  assert.equal(p.data.kind, 'ground');
});

test('bookingCreatedNotification — body carries ground, slot and cash amount', () => {
  const p = bookingCreatedNotification('b1', ground);
  assert.equal(p.title, 'New ground booking');
  assert.match(p.body, /Sardar Patel Cricket Ground/);
  assert.match(p.body, /2026-10-21 · 06:00-08:00/);
  assert.match(p.body, /₹1200/);
  assert.match(p.body, /\(cash\)/);
});

test('bookingCreatedNotification — online payment is labelled online', () => {
  const p = bookingCreatedNotification('b2', {
    ...ground,
    payment_method: 'razorpay',
  });
  assert.match(p.body, /\(online\)/);
});

test('bookingCreatedNotification — umpire bookings read differently', () => {
  const p = bookingCreatedNotification('b3', {
    ...ground,
    kind: 'umpire',
    resource_name: 'Ramesh Bhai',
  });
  assert.equal(p.title, 'New umpire booking');
  assert.match(p.body, /Ramesh Bhai/);
});

test('bookingCreatedNotification — no counterparty means no push', () => {
  assert.equal(bookingCreatedNotification('b4', { ...ground, counterparty_uid: '' }), null);
  assert.equal(bookingCreatedNotification('b5', { ...ground, counterparty_uid: undefined }), null);
});

test('bookingCreatedNotification — no booking id means no push', () => {
  assert.equal(bookingCreatedNotification('', ground), null);
});

test('bookingCreatedNotification — tolerates missing optional fields', () => {
  const p = bookingCreatedNotification('b6', { counterparty_uid: 'u9' });
  assert.equal(p.topic, 'user_u9');
  assert.equal(p.title, 'New ground booking');
  assert.ok(p.body.length > 0);
  assert.doesNotMatch(p.body, /₹/);
});

test('bookingCreatedNotification — never emits the string "undefined"', () => {
  const p = bookingCreatedNotification('b7', {
    counterparty_uid: 'u9',
    kind: 'umpire',
    date: '2026-10-22',
  });
  assert.doesNotMatch(p.body, /undefined/);
  assert.doesNotMatch(p.title, /undefined/);
});
