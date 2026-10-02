'use strict';

const { describe, it } = require('node:test');
const assert = require('node:assert/strict');

/**
 * Slot-grid generation tests. Mirrors the helper in functions/index.js.
 */
function parseTimeToMinutes(s) {
  const [h, m] = String(s).split(':').map((v) => parseInt(v, 10));
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

describe('Slot generation', () => {
  it('generates 2-hour slots from 06:00 to 22:00', () => {
    const slots = generateSlotsForGround({
      open_time: '06:00',
      close_time: '22:00',
      slot_duration_minutes: 120,
    });
    assert.deepEqual(Object.keys(slots), [
      '06:00-08:00',
      '08:00-10:00',
      '10:00-12:00',
      '12:00-14:00',
      '14:00-16:00',
      '16:00-18:00',
      '18:00-20:00',
      '20:00-22:00',
    ]);
  });

  it('handles odd close time (drops last slot if incomplete)', () => {
    const slots = generateSlotsForGround({
      open_time: '07:00',
      close_time: '13:00',
      slot_duration_minutes: 180,
    });
    assert.deepEqual(Object.keys(slots), [
      '07:00-10:00',
      '10:00-13:00',
    ]);
  });

  it('handles 1-hour slots', () => {
    const slots = generateSlotsForGround({
      open_time: '09:00',
      close_time: '12:00',
      slot_duration_minutes: 60,
    });
    assert.deepEqual(Object.keys(slots), [
      '09:00-10:00',
      '10:00-11:00',
      '11:00-12:00',
    ]);
  });

  it('returns empty map when slot_duration > open-close window', () => {
    const slots = generateSlotsForGround({
      open_time: '08:00',
      close_time: '09:00',
      slot_duration_minutes: 120,
    });
    assert.deepEqual(slots, {});
  });

  it('handles non-zero start minutes (e.g. 06:30 open)', () => {
    const slots = generateSlotsForGround({
      open_time: '06:30',
      close_time: '10:30',
      slot_duration_minutes: 120,
    });
    assert.deepEqual(Object.keys(slots), [
      '06:30-08:30',
      '08:30-10:30',
    ]);
  });
});