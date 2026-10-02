import 'package:flutter_test/flutter_test.dart';

import 'package:cricket_hub/models/booking_model.dart';

void main() {
  group('Booking refund policy', () {
    final booking = Booking(
      id: 'Bk_1',
      kind: 'Booking',
      resourceId: 'Gr_1',
      resourceName: 'Suncity Turf',
      organizerUid: 'uid_1',
      organizerName: 'Organizer',
      counterpartyUid: 'uid_2',
      counterpartyName: 'Owner',
      date: '2025-04-16',
      slotStart: '07:00',
      slotEnd: '09:00',
      durationMinutes: 120,
      amountPaise: 100000, // ₹1000
      platformFeePaise: 5000,
      payoutAmountPaise: 95000,
      paymentMethod: 'razorpay',
      paymentStatus: 'pending',
      status: 'held',
      refundAmountPaise: 0,
      refundStatus: 'none',
    );

    test('returns full refund when slot is 24h+ away', () {
      final now = DateTime(2025, 4, 15, 0, 0);
      expect(booking.computeRefundAmountPaise(now: now), 100000);
    });

    test('returns 50% refund when slot is 12-24h away', () {
      final now = DateTime(2025, 4, 15, 18, 0);
      expect(booking.computeRefundAmountPaise(now: now), 50000);
    });

    test('returns 0 refund when slot is <12h away', () {
      final now = DateTime(2025, 4, 16, 1, 0);
      expect(booking.computeRefundAmountPaise(now: now), 0);
    });

    test('returns 0 refund when slot is in the past', () {
      final now = DateTime(2025, 4, 16, 12, 0);
      expect(booking.computeRefundAmountPaise(now: now), 0);
    });
  });

  group('Booking display helpers', () {
    final booking = Booking(
      id: 'Bk_1',
      kind: 'ground',
      resourceId: 'Gr_1',
      resourceName: 'Suncity Turf',
      organizerUid: 'uid_1',
      organizerName: 'Organizer',
      counterpartyUid: 'uid_2',
      counterpartyName: 'Owner',
      date: '2025-04-16',
      slotStart: '07:00',
      slotEnd: '09:00',
      durationMinutes: 120,
      amountPaise: 100000,
      platformFeePaise: 5000,
      payoutAmountPaise: 95000,
      paymentMethod: 'razorpay',
      paymentStatus: 'pending',
      status: 'held',
      refundAmountPaise: 0,
      refundStatus: 'none',
    );

    test('amountDisplay formats rupees without decimals', () {
      expect(booking.amountDisplay, '₹1000');
    });

    test('platformFeeDisplay formats rupees without decimals', () {
      expect(booking.platformFeeDisplay, '₹50');
    });

    test('isConfirmed reflects status', () {
      expect(booking.isConfirmed, isFalse);
      final confirmed = Booking.fromFirestore(
        booking.id,
        {..._bookingMap(booking), 'status': 'confirmed'},
      );
      expect(confirmed.isConfirmed, isTrue);
    });
  });
}

Map<String, dynamic> _bookingMap(Booking b) => {
      'kind': b.kind,
      'resource_id': b.resourceId,
      'resource_name': b.resourceName,
      'organizer_uid': b.organizerUid,
      'organizer_name': b.organizerName,
      'counterparty_uid': b.counterpartyUid,
      'counterparty_name': b.counterpartyName,
      'date': b.date,
      'slot_start': b.slotStart,
      'slot_end': b.slotEnd,
      'duration_minutes': b.durationMinutes,
      'amount_paise': b.amountPaise,
      'platform_fee_paise': b.platformFeePaise,
      'payout_amount_paise': b.payoutAmountPaise,
      'payment_method': b.paymentMethod,
      'payment_status': b.paymentStatus,
      'status': b.status,
      'refund_amount_paise': b.refundAmountPaise,
      'refund_status': b.refundStatus,
    };