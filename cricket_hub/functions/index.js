'use strict';

/**
 * CricketHub Phase 3 — Marketplace & Bookings Cloud Functions.
 *
 * This file extends cricket_hub/functions/index.js (Phase 2) by adding:
 *   createBookingHold, createRazorpayOrder, verifyRazorpayPayment,
 *   razorpayWebhook, onBookingCancelled, validateBookingQR,
 *   expireStaleHolds, aggregateGroundRating, weeklyPayoutDigest,
 *   onBookingCompleted.
 *
 * Phase 1/2 exports (auth, tournaments, stats, push) live in
 * cricket_hub/functions/index.js — merge the contents during deployment.
 *
 * References:
 *   docs/CricketHub_TRD_Phase3.md
 *   docs/CricketHub_Backend_Schema_Phase3.md
 */

const crypto = require('node:crypto');
const { initializeApp } = require('firebase-admin/app');
const { FieldValue, getFirestore, Timestamp } = require('firebase-admin/firestore');
const { getMessaging } = require('firebase-admin/messaging');
const { logger } = require('firebase-functions');
const { defineSecret } = require('firebase-functions/params');
const { setGlobalOptions } = require('firebase-functions/v2');
const { HttpsError, onCall, onRequest } = require('firebase-functions/v2/https');
const {
  onDocumentCreated,
  onDocumentUpdated,
} = require('firebase-functions/v2/firestore');
const { onSchedule } = require('firebase-functions/v2/scheduler');

const Razorpay = require('razorpay');
const jwt = require('jsonwebtoken');

setGlobalOptions({ region: 'asia-south1', maxInstances: 30 });
initializeApp();
const db = getFirestore();

// Secrets — set via `firebase functions:secrets:set`.
const RAZORPAY_KEY_ID = defineSecret('RAZORPAY_KEY_ID');
const RAZORPAY_KEY_SECRET = defineSecret('RAZORPAY_KEY_SECRET');
const RAZORPAY_WEBHOOK_SECRET = defineSecret('RAZORPAY_WEBHOOK_SECRET');
const QR_JWT_SECRET = defineSecret('QR_JWT_SECRET');

const PLATFORM_FEE_PCT = 0.05;
const HOLD_DURATION_MIN = 10;

// ===========================================================================
// UTILITIES
// ===========================================================================

function requireUid(request) {
  const uid = request.auth?.uid;
  if (!uid) throw new HttpsError('unauthenticated', 'Sign in to continue.');
  return uid;
}

function isoDate(d) {
  const date = d instanceof Date ? d : new Date(d);
  const y = date.getUTCFullYear();
  const m = String(date.getUTCMonth() + 1).padStart(2, '0');
  const dd = String(date.getUTCDate()).padStart(2, '0');
  return `${y}-${m}-${dd}`;
}

function parseTimeToMinutes(s) {
  const [h, m] = String(s).split(':').map((v) => parseInt(v, 10));
  if (Number.isNaN(h) || Number.isNaN(m)) {
    throw new HttpsError('invalid-argument', `Invalid time: ${s}`);
  }
  return h * 60 + m;
}

function minutesToTime(mins) {
  return `${String(Math.floor(mins / 60)).padStart(2, '0')}:${String(mins % 60).padStart(2, '0')}`;
}

function generateSlotsForGround(ground) {
  const openM = parseTimeToMinutes(ground.open_time);
  const closeM = parseTimeToMinutes(ground.close_time);
  const dur = Number(ground.slot_duration_minutes || 120);
  const slots = {};
  for (let t = openM; t + dur <= closeM; t += dur) {
    const start = minutesToTime(t);
    const end = minutesToTime(t + dur);
    slots[`${start}-${end}`] = { status: 'available' };
  }
  return slots;
}

async function sendTopicNotification(topic, title, bodyText, data) {
  try {
    await getMessaging().send({
      topic,
      notification: { title, body: bodyText },
      data: Object.fromEntries(
        Object.entries(data || {}).map(([k, v]) => [k, String(v)])
      ),
      android: {
        priority: 'high',
        notification: {
          channelId: 'crickethub_match_alerts',
          sound: 'default',
        },
      },
      apns: { payload: { aps: { sound: 'default' } } },
    });
  } catch (error) {
    logger.warn('FCM send failed', { topic, error: error.message });
  }
}

// ===========================================================================
// CALLABLE: createBookingHold
// ===========================================================================
exports.createBookingHold = onCall(
  { enforceAppCheck: false, secrets: [QR_JWT_SECRET] },
  async (request) => {
    const organizerUid = requireUid(request);
    const data = request.data || {};

    const kind = String(data.kind || '');
    if (!['ground', 'umpire'].includes(kind)) {
      throw new HttpsError('invalid-argument', 'kind must be "ground" or "umpire"');
    }
    const resourceId = String(data.resourceId || '');
    const date = String(data.date || '');
    const slotStart = String(data.slotStart || '');
    const slotEnd = String(data.slotEnd || '');
    const slotKey = `${slotStart}-${slotEnd}`;
    const paymentMethod = String(data.paymentMethod || 'razorpay');
    const amountPaise = Number(data.amountPaise || 0);
    const platformFeePaise = Number(data.platformFeePaise || 0);
    const payoutAmountPaise = Number(
      data.payoutAmountPaise || amountPaise - platformFeePaise
    );
    const notes = String(data.notes || '');

    if (!resourceId || !date || !slotStart || !slotEnd) {
      throw new HttpsError('invalid-argument', 'resourceId, date, slotStart and slotEnd are required.');
    }
    if (amountPaise <= 0) {
      throw new HttpsError('invalid-argument', 'amountPaise must be > 0.');
    }

    // Idempotency: if there's already a held booking for the same
    // (organizer, resource, date, slot) and the hold is still fresh,
    // return it instead of creating a new one.
    const existing = await db.collection('bookings')
      .where('organizer_uid', '==', organizerUid)
      .where('resource_id', '==', resourceId)
      .where('date', '==', date)
      .where('slot_start', '==', slotStart)
      .where('slot_end', '==', slotEnd)
      .where('status', 'in', ['held', 'pending_payment'])
      .orderBy('created_at', 'desc')
      .limit(1)
      .get();

    if (!existing.empty) {
      const doc = existing.docs[0];
      const data = doc.data();
      const holdUntil = data.hold_until?.toDate?.() ?? null;
      if (holdUntil && holdUntil > new Date() && data.organizer_uid === organizerUid) {
        return { bookingId: doc.id, held: true };
      }
    }

    // Atomic slot reservation via Firestore transaction.
    const slotRef = db
      .collection(kind === 'ground' ? 'grounds' : 'umpires')
      .doc(resourceId)
      .collection(kind === 'ground' ? 'slots' : 'availability')
      .doc(date);

    const result = await db.runTransaction(async (tx) => {
      const slotDoc = await tx.get(slotRef);
      let slotMap;
      let blocked = false;

      if (!slotDoc.exists) {
        // First read for this date — generate the slot map on the fly.
        if (kind === 'ground') {
          const groundDoc = await tx.get(db.collection('grounds').doc(resourceId));
          if (!groundDoc.exists) {
            throw new HttpsError('not-found', 'Ground not found.');
          }
          const ground = groundDoc.data();
          if (ground.status !== 'active' || !ground.verified) {
            throw new HttpsError('failed-precondition', 'Ground is not bookable.');
          }
          slotMap = generateSlotsForGround(ground);
          tx.create(slotRef, {
            date,
            slots: slotMap,
            blocked: false,
            generated_at: FieldValue.serverTimestamp(),
            updated_at: FieldValue.serverTimestamp(),
          });
        } else {
          slotMap = {};
          tx.create(slotRef, {
            date,
            slots: slotMap,
            blocked: false,
            updated_at: FieldValue.serverTimestamp(),
          });
        }
      } else {
        const data = slotDoc.data();
        blocked = Boolean(data.blocked);
        slotMap = data.slots || {};
      }

      if (blocked) {
        throw new HttpsError('failed-precondition', 'This date is blocked.');
      }

      const entry = slotMap[slotKey];
      const status = entry?.status || 'available';
      if (status === 'booked') {
        throw new HttpsError('aborted', 'This slot is already booked.');
      }
      if (status === 'blocked') {
        throw new HttpsError('aborted', 'This slot is closed.');
      }
      if (status === 'held' && entry.held_by !== organizerUid) {
        const heldUntil = entry.held_until?.toDate?.() ?? new Date(0);
        if (heldUntil > new Date()) {
          throw new HttpsError('aborted', 'Someone else is booking this slot. Try again in 10 minutes.');
        }
      }

      const newEntry = {
        status: 'held',
        held_by: organizerUid,
        held_until: Timestamp.fromDate(new Date(Date.now() + HOLD_DURATION_MIN * 60_000)),
      };
      tx.update(slotRef, {
        [`slots.${slotKey}`]: newEntry,
        updated_at: FieldValue.serverTimestamp(),
      });

      const bookingRef = db.collection('bookings').doc();
      const qrToken = jwt.sign(
        {
          booking_id: bookingRef.id,
          resource_id: resourceId,
          organizer_uid: organizerUid,
          date,
          slot_start: slotStart,
          slot_end: slotEnd,
        },
        QR_JWT_SECRET.value(),
        { algorithm: 'HS256', expiresIn: '24h' }
      );

      tx.create(bookingRef, {
        kind,
        resource_id: resourceId,
        resource_name: String(data.resourceName || 'Ground'),
        organizer_uid: organizerUid,
        organizer_name: String(data.organizerName || ''),
        counterparty_uid: String(data.counterpartyUid || ''),
        counterparty_name: String(data.counterpartyName || ''),
        date,
        slot_start: slotStart,
        slot_end: slotEnd,
        duration_minutes: Number(data.durationMinutes || 120),
        amount_paise: amountPaise,
        platform_fee_paise: platformFeePaise,
        payout_amount_paise: payoutAmountPaise,
        payment_method: paymentMethod,
        payment_status: 'pending',
        status: paymentMethod === 'cod' ? 'pending_payment' : 'held',
        qr_token: qrToken,
        notes: notes.slice(0, 500),
        refund_amount_paise: 0,
        refund_status: 'none',
        created_at: FieldValue.serverTimestamp(),
        updated_at: FieldValue.serverTimestamp(),
      });

      tx.create(bookingRef.collection('audit').doc(), {
        actor_uid: organizerUid,
        action: 'hold_created',
        from_status: null,
        to_status: paymentMethod === 'cod' ? 'pending_payment' : 'held',
        ts: FieldValue.serverTimestamp(),
      });

      return { bookingId: bookingRef.id };
    });

    return { bookingId: result.bookingId, held: false };
  },
);

// ===========================================================================
// CALLABLE: createRazorpayOrder
// ===========================================================================
exports.createRazorpayOrder = onCall(
  { enforceAppCheck: false, secrets: [RAZORPAY_KEY_ID, RAZORPAY_KEY_SECRET] },
  async (request) => {
    const uid = requireUid(request);
    const bookingId = String(request.data?.bookingId || '');
    if (!bookingId) throw new HttpsError('invalid-argument', 'bookingId is required.');

    const bookingRef = db.collection('bookings').doc(bookingId);
    const bookingDoc = await bookingRef.get();
    if (!bookingDoc.exists) throw new HttpsError('not-found', 'Booking not found.');
    const booking = bookingDoc.data();
    if (booking.organizer_uid !== uid) {
      throw new HttpsError('permission-denied', 'Only the booking organizer can pay.');
    }
    if (booking.status !== 'held') {
      throw new HttpsError('failed-precondition', `Booking is ${booking.status}, not in 'held' state.`);
    }

    const razorpay = new Razorpay({
      key_id: RAZORPAY_KEY_ID.value(),
      key_secret: RAZORPAY_KEY_SECRET.value(),
    });

    const order = await razorpay.orders.create({
      amount: booking.amount_paise,
      currency: 'INR',
      receipt: bookingId,
      notes: {
        booking_id: bookingId,
        kind: booking.kind,
        resource_id: booking.resource_id,
      },
    });

    await bookingRef.update({
      razorpay_order_id: order.id,
      updated_at: FieldValue.serverTimestamp(),
    });

    return {
      orderId: order.id,
      amountInPaise: order.amount,
      currency: order.currency,
      razorpayKeyId: RAZORPAY_KEY_ID.value(),
    };
  },
);

// ===========================================================================
// CALLABLE: verifyRazorpayPayment
// ===========================================================================
exports.verifyRazorpayPayment = onCall(
  { enforceAppCheck: false, secrets: [RAZORPAY_KEY_SECRET] },
  async (request) => {
    const uid = requireUid(request);
    const { bookingId, razorpayPaymentId, razorpayOrderId, razorpaySignature } = request.data || {};
    if (!bookingId || !razorpayPaymentId || !razorpayOrderId || !razorpaySignature) {
      throw new HttpsError('invalid-argument', 'Missing required Razorpay fields.');
    }

    // 1. Server-side HMAC signature verification.
    const expected = crypto
      .createHmac('sha256', RAZORPAY_KEY_SECRET.value())
      .update(`${razorpayOrderId}|${razorpayPaymentId}`)
      .digest('hex');

    if (expected !== razorpaySignature) {
      logger.error('Razorpay signature mismatch', { bookingId });
      throw new HttpsError('permission-denied', 'Invalid payment signature.');
    }

    const bookingRef = db.collection('bookings').doc(bookingId);
    const summary = await db.runTransaction(async (tx) => {
      const snap = await tx.get(bookingRef);
      if (!snap.exists) throw new HttpsError('not-found', 'Booking not found.');
      const b = snap.data();
      if (b.organizer_uid !== uid) {
        throw new HttpsError('permission-denied', 'Not your booking.');
      }
      if (b.status !== 'held') {
        return { ok: true, alreadyFinal: true, booking: b };
      }

      tx.update(bookingRef, {
        razorpay_payment_id: razorpayPaymentId,
        payment_status: 'authorized',
        status: 'confirmed',
        confirmed_at: FieldValue.serverTimestamp(),
        updated_at: FieldValue.serverTimestamp(),
      });

      const slotRef = db
        .collection(b.kind === 'ground' ? 'grounds' : 'umpires')
        .doc(b.resource_id)
        .collection(b.kind === 'ground' ? 'slots' : 'availability')
        .doc(b.date);
      tx.update(slotRef, {
        [`slots.${b.slot_start}-${b.slot_end}.status`]: 'booked',
        [`slots.${b.slot_start}-${b.slot_end}.booking_id`]: bookingId,
        [`slots.${b.slot_start}-${b.slot_end}.held_by`]: FieldValue.delete(),
        [`slots.${b.slot_start}-${b.slot_end}.held_until`]: FieldValue.delete(),
        updated_at: FieldValue.serverTimestamp(),
      });

      tx.create(bookingRef.collection('audit').doc(), {
        actor_uid: uid,
        action: 'payment_verified',
        from_status: 'held',
        to_status: 'confirmed',
        ts: FieldValue.serverTimestamp(),
      });

      return { ok: true, alreadyFinal: false, booking: b };
    });

    if (!summary.alreadyFinal) {
      const topic = `bookings_${bookingId}`;
      await sendTopicNotification(
        topic,
        'New booking',
        `Booking confirmed for ${summary.booking.date} at ${summary.booking.slot_start}.`,
        { type: 'booking_confirmed', bookingId }
      );

      const counterRef = db
        .collection(summary.booking.kind === 'ground' ? 'grounds' : 'umpires')
        .doc(summary.booking.resource_id);
      await counterRef.set(
        {
          booking_count: FieldValue.increment(1),
          ground_stats: {
            total_bookings: FieldValue.increment(1),
            total_revenue_paise: FieldValue.increment(summary.booking.amount_paise),
            last_booked_at: FieldValue.serverTimestamp(),
          },
        },
        { merge: true }
      );

      await db
        .collection('users')
        .doc(summary.booking.organizer_uid)
        .collection('bookings')
        .doc(bookingId)
        .set({
          booking_id: bookingId,
          kind: summary.booking.kind,
          resource_id: summary.booking.resource_id,
          resource_name: summary.booking.resource_name,
          status: 'confirmed',
          date: summary.booking.date,
          slot_start: summary.booking.slot_start,
          slot_end: summary.booking.slot_end,
          amount_paise: summary.booking.amount_paise,
          saved_at: FieldValue.serverTimestamp(),
        });
    }

    return { verified: true, bookingId };
  },
);

// ===========================================================================
// HTTP: razorpayWebhook
// ===========================================================================
exports.razorpayWebhook = onRequest(
  { region: 'asia-south1', cors: false, secrets: [RAZORPAY_WEBHOOK_SECRET] },
  async (req, res) => {
    if (req.method !== 'POST') {
      res.status(405).send('Method Not Allowed');
      return;
    }

    const signature = req.headers['x-razorpay-signature'];
    const body = JSON.stringify(req.body);
    const expected = crypto
      .createHmac('sha256', RAZORPAY_WEBHOOK_SECRET.value())
      .update(body)
      .digest('hex');

    if (signature !== expected) {
      logger.error('Invalid webhook signature');
      res.status(400).send('Invalid signature');
      return;
    }

    const event = req.body?.event;
    const eventId = req.body?.id || `${event}_${Date.now()}`;
    const eventRef = db.collection('razorpay_events').doc(eventId);
    const existing = await eventRef.get();
    if (existing.exists) {
      res.status(200).json({ received: true, deduped: true });
      return;
    }

    await eventRef.set({
      event_type: event,
      payload: req.body,
      received_at: FieldValue.serverTimestamp(),
      processed: false,
    });

    try {
      const payment = req.body?.payload?.payment?.entity;
      const orderId = payment?.order_id;
      const paymentId = payment?.id;

      if (event === 'payment.captured' && orderId && paymentId) {
        const snap = await db.collection('bookings')
          .where('razorpay_order_id', '==', orderId)
          .limit(1)
          .get();
        if (!snap.empty) {
          await snap.docs[0].ref.update({
            razorpay_payment_id: paymentId,
            payment_status: 'captured',
            updated_at: FieldValue.serverTimestamp(),
          });
        }
      } else if (event === 'payment.failed' && orderId) {
        const snap = await db.collection('bookings')
          .where('razorpay_order_id', '==', orderId)
          .limit(1)
          .get();
        if (!snap.empty) {
          const doc = snap.docs[0];
          await doc.ref.update({
            payment_status: 'failed',
            status: 'cancelled',
            cancellation_reason: 'payment_failed',
            updated_at: FieldValue.serverTimestamp(),
          });
          const b = doc.data();
          const slotRef = db
            .collection(b.kind === 'ground' ? 'grounds' : 'umpires')
            .doc(b.resource_id)
            .collection(b.kind === 'ground' ? 'slots' : 'availability')
            .doc(b.date);
          await slotRef.update({
            [`slots.${b.slot_start}-${b.slot_end}.status`]: 'available',
            [`slots.${b.slot_start}-${b.slot_end}.held_by`]: FieldValue.delete(),
            [`slots.${b.slot_start}-${b.slot_end}.held_until`]: FieldValue.delete(),
            [`slots.${b.slot_start}-${b.slot_end}.booking_id`]: FieldValue.delete(),
            updated_at: FieldValue.serverTimestamp(),
          });
        }
      } else if (event === 'refund.processed' && paymentId) {
        const refund = req.body?.payload?.refund?.entity;
        const refundId = refund?.id;
        const snap = await db.collection('bookings')
          .where('razorpay_payment_id', '==', paymentId)
          .limit(1)
          .get();
        if (!snap.empty) {
          await snap.docs[0].ref.update({
            refund_status: 'processed',
            refund_id: refundId,
            updated_at: FieldValue.serverTimestamp(),
          });
        }
      }

      await eventRef.update({
        processed: true,
        processed_at: FieldValue.serverTimestamp(),
      });
      res.status(200).json({ received: true });
    } catch (error) {
      logger.error('Webhook processing error', { event, error: error.message });
      res.status(500).json({ received: false, error: error.message });
    }
  },
);

// ===========================================================================
// CALLABLE: onBookingCancelled
// ===========================================================================
exports.onBookingCancelled = onCall(
  { enforceAppCheck: false, secrets: [RAZORPAY_KEY_ID, RAZORPAY_KEY_SECRET] },
  async (request) => {
    const uid = requireUid(request);
    const bookingId = String(request.data?.bookingId || '');
    const reason = String(request.data?.reason || 'user_requested');
    if (!bookingId) throw new HttpsError('invalid-argument', 'bookingId is required.');

    const bookingRef = db.collection('bookings').doc(bookingId);
    const result = await db.runTransaction(async (tx) => {
      const snap = await tx.get(bookingRef);
      if (!snap.exists) throw new HttpsError('not-found', 'Booking not found.');
      const b = snap.data();
      if (b.organizer_uid !== uid) {
        throw new HttpsError('permission-denied', 'Not your booking.');
      }
      if (['cancelled', 'completed', 'no_show'].includes(b.status)) {
        return { ok: true, alreadyCancelled: true, booking: b };
      }

      // Refund policy: >=24h = 100%, 12-24h = 50%, <12h = 0%.
      const slotDateTime = new Date(`${b.date}T${b.slot_start}:00+05:30`);
      const hoursUntil = (slotDateTime.getTime() - Date.now()) / 3_600_000;
      let refundAmountPaise = 0;
      if (hoursUntil >= 24) refundAmountPaise = b.amount_paise;
      else if (hoursUntil >= 12) refundAmountPaise = Math.round(b.amount_paise / 2);

      tx.update(bookingRef, {
        status: 'cancelled',
        cancelled_at: FieldValue.serverTimestamp(),
        cancellation_reason: reason,
        refund_amount_paise: refundAmountPaise,
        refund_status: refundAmountPaise > 0 ? 'requested' : 'none',
        updated_at: FieldValue.serverTimestamp(),
      });

      tx.create(bookingRef.collection('audit').doc(), {
        actor_uid: uid,
        action: 'cancelled',
        from_status: b.status,
        to_status: 'cancelled',
        refund_amount_paise: refundAmountPaise,
        ts: FieldValue.serverTimestamp(),
      });

      const slotRef = db
        .collection(b.kind === 'ground' ? 'grounds' : 'umpires')
        .doc(b.resource_id)
        .collection(b.kind === 'ground' ? 'slots' : 'availability')
        .doc(b.date);
      tx.update(slotRef, {
        [`slots.${b.slot_start}-${b.slot_end}.status`]: 'available',
        [`slots.${b.slot_start}-${b.slot_end}.booking_id`]: FieldValue.delete(),
        [`slots.${b.slot_start}-${b.slot_end}.held_by`]: FieldValue.delete(),
        [`slots.${b.slot_start}-${b.slot_end}.held_until`]: FieldValue.delete(),
        updated_at: FieldValue.serverTimestamp(),
      });

      return { ok: true, alreadyCancelled: false, booking: b, refundAmountPaise };
    });

    if (
      !result.alreadyCancelled &&
      result.refundAmountPaise > 0 &&
      result.booking.payment_method === 'razorpay'
    ) {
      try {
        const razorpay = new Razorpay({
          key_id: RAZORPAY_KEY_ID.value(),
          key_secret: RAZORPAY_KEY_SECRET.value(),
        });
        const refund = await razorpay.payments.refund(
          result.booking.razorpay_payment_id,
          {
            amount: result.refundAmountPaise,
            speed: 'optimum',
          }
        );
        await bookingRef.update({
          refund_status: 'processed',
          refund_id: refund.id,
          updated_at: FieldValue.serverTimestamp(),
        });
      } catch (error) {
        logger.error('Razorpay refund failed', { bookingId, error: error.message });
        await bookingRef.update({
          refund_status: 'failed',
          updated_at: FieldValue.serverTimestamp(),
        });
      }
    }

    return { cancelled: true, refundAmountPaise: result.refundAmountPaise };
  },
);

// ===========================================================================
// CALLABLE: validateBookingQR
// ===========================================================================
exports.validateBookingQR = onCall(
  { enforceAppCheck: false, secrets: [QR_JWT_SECRET] },
  async (request) => {
    const uid = requireUid(request);
    const token = String(request.data?.qrToken || '');
    if (!token) throw new HttpsError('invalid-argument', 'qrToken is required.');

    let decoded;
    try {
      decoded = jwt.verify(token, QR_JWT_SECRET.value(), { algorithms: ['HS256'] });
    } catch (e) {
      throw new HttpsError('permission-denied', 'Invalid or expired QR.');
    }

    const bookingRef = db.collection('bookings').doc(decoded.booking_id);
    const snap = await bookingRef.get();
    if (!snap.exists) throw new HttpsError('not-found', 'Booking not found.');
    const b = snap.data();
    if (b.counterparty_uid !== uid) {
      throw new HttpsError('permission-denied', 'You are not the counterparty for this booking.');
    }
    if (b.status !== 'confirmed') {
      throw new HttpsError('failed-precondition', `Booking is ${b.status}.`);
    }

    return {
      valid: true,
      booking: {
        id: b.resource_id,
        name: b.resource_name,
        date: b.date,
        slot_start: b.slot_start,
        slot_end: b.slot_end,
        organizer_name: b.organizer_name,
      },
    };
  },
);

// ===========================================================================
// SCHEDULE: expireStaleHolds (every 5 minutes)
// ===========================================================================
exports.expireStaleHolds = onSchedule(
  { schedule: 'every 5 minutes', region: 'asia-south1', timeZone: 'Asia/Kolkata' },
  async () => {
    const now = new Date();
    let released = 0;

    const days = [];
    for (let i = -1; i < 7; i += 1) {
      const d = new Date(now);
      d.setUTCDate(d.getUTCDate() + i);
      days.push(isoDate(d));
    }

    const groundsSnapshot = await db.collection('grounds').get();
    for (const groundDoc of groundsSnapshot.docs) {
      for (const date of days) {
        const slotRef = groundDoc.ref.collection('slots').doc(date);
        const slotDoc = await slotRef.get();
        if (!slotDoc.exists) continue;
        const data = slotDoc.data();
        const slots = data.slots || {};
        const updates = {};
        for (const [key, entry] of Object.entries(slots)) {
          if (entry?.status === 'held' && entry.held_until?.toDate?.() < now) {
            updates[`slots.${key}.status`] = 'available';
            updates[`slots.${key}.held_by`] = FieldValue.delete();
            updates[`slots.${key}.held_until`] = FieldValue.delete();
            updates[`slots.${key}.booking_id`] = FieldValue.delete();
            released += 1;
          }
        }
        if (Object.keys(updates).length > 0) {
          await slotRef.update({ ...updates, updated_at: FieldValue.serverTimestamp() });
        }
      }
    }

    logger.info(`expireStaleHolds: released ${released} stale slots`);
    return { released };
  },
);

// ===========================================================================
// FIRESTORE: aggregateGroundRating
// ===========================================================================
exports.aggregateGroundRating = onDocumentCreated(
  { document: 'ground_reviews/{reviewId}', region: 'asia-south1' },
  async (event) => {
    const review = event.data?.data();
    if (!review?.ground_id) return;
    const groundId = review.ground_id;

    const reviews = await db.collection('ground_reviews')
      .where('ground_id', '==', groundId)
      .get();
    if (reviews.empty) return;

    const total = reviews.docs.reduce((sum, doc) => sum + (doc.data().rating || 0), 0);
    const avg = total / reviews.size;

    await db.collection('grounds').doc(groundId).update({
      avg_rating: avg,
      review_count: reviews.size,
      updated_at: FieldValue.serverTimestamp(),
    });
  },
);

// ===========================================================================
// SCHEDULE: weeklyPayoutDigest (Monday 09:00 IST)
// ===========================================================================
exports.weeklyPayoutDigest = onSchedule(
  { schedule: '0 9 * * 1', region: 'asia-south1', timeZone: 'Asia/Kolkata' },
  async () => {
    const now = new Date();
    const dayOfWeek = now.getUTCDay();
    const monday = new Date(now);
    const offset = (dayOfWeek + 6) % 7;
    monday.setUTCDate(monday.getUTCDate() - offset);
    monday.setUTCHours(0, 0, 0, 0);
    const weekStartIso = isoDate(monday);

    const lastWeekStart = new Date(monday);
    lastWeekStart.setUTCDate(lastWeekStart.getUTCDate() - 7);

    const bookings = await db.collection('bookings')
      .where('status', '==', 'confirmed')
      .where('confirmed_at', '>=', Timestamp.fromDate(lastWeekStart))
      .where('confirmed_at', '<', Timestamp.fromDate(monday))
      .get();

    const ledger = {};
    bookings.docs.forEach((doc) => {
      const b = doc.data();
      if (!b.counterparty_uid) return;
      if (!ledger[b.counterparty_uid]) {
        ledger[b.counterparty_uid] = {
          booking_count: 0,
          gross: 0,
          fee: 0,
          net: 0,
          ids: [],
        };
      }
      ledger[b.counterparty_uid].booking_count += 1;
      ledger[b.counterparty_uid].gross += b.amount_paise || 0;
      ledger[b.counterparty_uid].fee += b.platform_fee_paise || 0;
      ledger[b.counterparty_uid].net += b.payout_amount_paise || 0;
      ledger[b.counterparty_uid].ids.push(b.id);
    });

    const batch = db.batch();
    for (const [ownerUid, data] of Object.entries(ledger)) {
      const ref = db
        .collection('payout_ledger')
        .doc(ownerUid)
        .collection('weeks')
        .doc(weekStartIso);
      batch.set(
        ref,
        {
          owner_uid: ownerUid,
          week_start: weekStartIso,
          booking_count: data.booking_count,
          gross_amount_paise: data.gross,
          platform_fee_paise: data.fee,
          net_payout_paise: data.net,
          bookings: data.ids,
          settlement_status: 'pending',
          created_at: FieldValue.serverTimestamp(),
        },
        { merge: true }
      );
    }
    await batch.commit();

    logger.info(`weeklyPayoutDigest: wrote ${Object.keys(ledger).length} payout entries`);
  },
);

// ===========================================================================
// FIRESTORE: onBookingCompleted (review prompt)
// ===========================================================================
exports.onBookingCompleted = onDocumentUpdated(
  { document: 'bookings/{bookingId}', region: 'asia-south1' },
  async (event) => {
    const before = event.data?.before.data();
    const after = event.data?.after.data();
    if (!before || !after) return;
    if (after.status === 'completed' && before.status !== 'completed') {
      const bookingId = event.params.bookingId;
      await sendTopicNotification(
        `bookings_${bookingId}`,
        'Rate your experience',
        'How was the ground? Leave a review to help the community.',
        { type: 'review_prompt', bookingId }
      );
    }
  },
);