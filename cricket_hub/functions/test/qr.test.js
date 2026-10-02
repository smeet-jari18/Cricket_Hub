'use strict';

const jwt = require('jsonwebtoken');
const { describe, it } = require('node:test');
const assert = require('node:assert/strict');

describe('Booking QR JWT', () => {
  const SECRET = 'test_qr_secret_super_long';

  it('signs and verifies a token round-trip', () => {
    const payload = {
      booking_id: 'Bk_abc123',
      resource_id: 'Gr_xyz789',
      organizer_uid: 'uid_xxx',
      date: '2025-04-15',
      slot_start: '07:00',
      slot_end: '09:00',
    };
    const token = jwt.sign(payload, SECRET, { algorithm: 'HS256', expiresIn: '24h' });
    const decoded = jwt.verify(token, SECRET);
    assert.equal(decoded.booking_id, payload.booking_id);
    assert.equal(decoded.resource_id, payload.resource_id);
  });

  it('rejects a token signed with a different secret', () => {
    const token = jwt.sign({ booking_id: 'Bk_1' }, 'wrong_secret', { algorithm: 'HS256' });
    assert.throws(() => jwt.verify(token, SECRET));
  });

  it('rejects an expired token', () => {
    const token = jwt.sign({ booking_id: 'Bk_1' }, SECRET, { algorithm: 'HS256', expiresIn: '-1s' });
    assert.throws(() => jwt.verify(token, SECRET), /expired/);
  });

  it('rejects a token with tampered payload', () => {
    const token = jwt.sign({ booking_id: 'Bk_1' }, SECRET, { algorithm: 'HS256' });
    const tampered = token.slice(0, -5) + 'AAAAA';
    assert.throws(() => jwt.verify(tampered, SECRET));
  });
});