'use strict';

const crypto = require('node:crypto');
const { describe, it } = require('node:test');
const assert = require('node:assert/strict');

/**
 * Server-side signature verification test. Mirrors verifyRazorpayPayment.
 *
 * Razorpay signature = HMAC_SHA256(key=secret, data=order_id|payment_id)
 */
function verifyRazorpaySignature({ keySecret, orderId, paymentId, signature }) {
  const expected = crypto
    .createHmac('sha256', keySecret)
    .update(`${orderId}|${paymentId}`)
    .digest('hex');
  return expected === signature;
}

describe('Razorpay signature verification', () => {
  const SECRET = 'whsec_test_super_secret';

  it('accepts a valid signature', () => {
    const orderId = 'order_NaFrPm7m1eVkJ4';
    const paymentId = 'pay_ABC123';
    const signature = crypto
      .createHmac('sha256', SECRET)
      .update(`${orderId}|${paymentId}`)
      .digest('hex');
    assert.equal(
      verifyRazorpaySignature({ keySecret: SECRET, orderId, paymentId, signature }),
      true
    );
  });

  it('rejects a tampered signature', () => {
    assert.equal(
      verifyRazorpaySignature({
        keySecret: SECRET,
        orderId: 'order_NaFrPm7m1eVkJ4',
        paymentId: 'pay_ABC123',
        signature: 'abc123',
      }),
      false
    );
  });

  it('rejects when secret is wrong', () => {
    const orderId = 'order_NaFrPm7m1eVkJ4';
    const paymentId = 'pay_ABC123';
    const signature = crypto
      .createHmac('sha256', SECRET)
      .update(`${orderId}|${paymentId}`)
      .digest('hex');
    assert.equal(
      verifyRazorpaySignature({
        keySecret: 'wrong_secret',
        orderId,
        paymentId,
        signature,
      }),
      false
    );
  });

  it('rejects when paymentId is changed after signing', () => {
    const orderId = 'order_NaFrPm7m1eVkJ4';
    const signature = crypto
      .createHmac('sha256', SECRET)
      .update(`${orderId}|pay_ORIGINAL`)
      .digest('hex');
    assert.equal(
      verifyRazorpaySignature({
        keySecret: SECRET,
        orderId,
        paymentId: 'pay_TAMPERED',
        signature,
      }),
      false
    );
  });
});