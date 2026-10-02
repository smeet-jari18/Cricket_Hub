'use strict';

const { describe, it } = require('node:test');
const assert = require('node:assert/strict');

/**
 * Refund policy tests. Mirrors the logic inside onBookingCancelled.
 *
 * Policy:
 *   >= 24h before slot start:  100%
 *   12-24h before:              50%
 *   < 12h before:                0%
 */
function computeRefundAmountPaise({ amountPaise, date, slotStart, now }) {
  const slotDateTime = new Date(`${date}T${slotStart}:00+05:30`);
  const hoursUntil = (slotDateTime.getTime() - now.getTime()) / 3_600_000;
  if (hoursUntil >= 24) return amountPaise;
  if (hoursUntil >= 12) return Math.round(amountPaise / 2);
  return 0;
}

describe('Refund policy', () => {
  const AMOUNT = 100_000;

  it('returns full refund when slot is 24h+ away', () => {
    const now = new Date('2025-04-15T00:00:00+05:30');
    const refund = computeRefundAmountPaise({
      amountPaise: AMOUNT,
      date: '2025-04-16',
      slotStart: '07:00',
      now,
    });
    assert.equal(refund, AMOUNT);
  });

  it('returns 50% refund when slot is 12-24h away', () => {
    const now = new Date('2025-04-15T18:00:00+05:30');
    const refund = computeRefundAmountPaise({
      amountPaise: AMOUNT,
      date: '2025-04-16',
      slotStart: '07:00',
      now,
    });
    assert.equal(refund, 50_000);
  });

  it('returns 0 refund when slot is <12h away', () => {
    const now = new Date('2025-04-16T01:00:00+05:30');
    const refund = computeRefundAmountPaise({
      amountPaise: AMOUNT,
      date: '2025-04-16',
      slotStart: '07:00',
      now,
    });
    assert.equal(refund, 0);
  });

  it('handles exactly 24h boundary (full refund)', () => {
    const now = new Date('2025-04-15T07:00:00+05:30');
    const refund = computeRefundAmountPaise({
      amountPaise: AMOUNT,
      date: '2025-04-16',
      slotStart: '07:00',
      now,
    });
    assert.equal(refund, AMOUNT);
  });

  it('handles exactly 12h boundary (50% refund)', () => {
    const now = new Date('2025-04-15T19:00:00+05:30');
    const refund = computeRefundAmountPaise({
      amountPaise: AMOUNT,
      date: '2025-04-16',
      slotStart: '07:00',
      now,
    });
    assert.equal(refund, 50_000);
  });

  it('handles slot in the past', () => {
    const now = new Date('2025-04-16T12:00:00+05:30');
    const refund = computeRefundAmountPaise({
      amountPaise: AMOUNT,
      date: '2025-04-16',
      slotStart: '07:00',
      now,
    });
    assert.equal(refund, 0);
  });
});