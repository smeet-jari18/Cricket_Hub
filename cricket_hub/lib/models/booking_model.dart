import 'package:cloud_firestore/cloud_firestore.dart';

/// Booking = one document in the `bookings` collection.
/// Discriminator is `kind`: 'ground' | 'umpire'.
class Booking {
  final String id;
  final String kind; // 'ground' | 'umpire'
  final String resourceId;
  final String resourceName;
  final String organizerUid;
  final String organizerName;
  final String counterpartyUid; // ground_owner_uid or umpire_uid
  final String counterpartyName;
  final String date; // 'YYYY-MM-DD'
  final String slotStart; // 'HH:mm'
  final String slotEnd; // 'HH:mm'
  final int durationMinutes;
  final int amountPaise;
  final int platformFeePaise;
  final int payoutAmountPaise;
  final String paymentMethod; // 'razorpay' | 'cod'
  final String paymentStatus; // 'pending' | 'authorized' | 'failed' | 'refunded' | 'partially_refunded'
  final String? razorpayOrderId;
  final String? razorpayPaymentId;
  final String status; // 'held' | 'pending_payment' | 'confirmed' | 'cancelled' | 'no_show' | 'completed'
  final String? qrToken;
  final String? matchId;
  final String? notes;
  final String? cancellationReason;
  final int refundAmountPaise;
  final String refundStatus; // 'none' | 'requested' | 'processed' | 'failed'
  final String? refundId;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final DateTime? confirmedAt;
  final DateTime? cancelledAt;
  final DateTime? codConfirmedAt;

  const Booking({
    required this.id,
    required this.kind,
    required this.resourceId,
    required this.resourceName,
    required this.organizerUid,
    required this.organizerName,
    required this.counterpartyUid,
    required this.counterpartyName,
    required this.date,
    required this.slotStart,
    required this.slotEnd,
    required this.durationMinutes,
    required this.amountPaise,
    required this.platformFeePaise,
    required this.payoutAmountPaise,
    required this.paymentMethod,
    required this.paymentStatus,
    required this.status,
    required this.refundAmountPaise,
    required this.refundStatus,
    this.razorpayOrderId,
    this.razorpayPaymentId,
    this.qrToken,
    this.matchId,
    this.notes,
    this.cancellationReason,
    this.refundId,
    this.createdAt,
    this.updatedAt,
    this.confirmedAt,
    this.cancelledAt,
    this.codConfirmedAt,
  });

  bool get isGroundBooking => kind == 'ground';
  bool get isUmpireBooking => kind == 'umpire';
  bool get isConfirmed => status == 'confirmed';
  bool get isHeld => status == 'held';
  bool get isPendingPayment => status == 'pending_payment';
  bool get isCancelled => status == 'cancelled';
  bool get isCompleted => status == 'completed';
  bool get hasQrCode =>
      qrToken != null && qrToken!.isNotEmpty && isConfirmed;

  String get amountDisplay {
    final rupees = amountPaise / 100.0;
    return '₹${rupees.toStringAsFixed(0)}';
  }

  String get platformFeeDisplay {
    final rupees = platformFeePaise / 100.0;
    return '₹${rupees.toStringAsFixed(0)}';
  }

  /// Refund amount in paise given current time. Policy:
  ///   >= 24h before slot: 100%
  ///   12-24h before:       50%
  ///   < 12h before:         0%
  int computeRefundAmountPaise({DateTime? now}) {
    final current = now ?? DateTime.now();
    DateTime slotStartDate;
    try {
      final datePart = DateTime.parse(date);
      final parts = slotStart.split(':');
      slotStartDate = DateTime(
        datePart.year,
        datePart.month,
        datePart.day,
        int.parse(parts[0]),
        int.parse(parts[1]),
      );
    } catch (_) {
      return 0;
    }
    final hours = slotStartDate.difference(current).inHours;
    if (hours >= 24) return amountPaise;
    if (hours >= 12) return (amountPaise / 2).round();
    return 0;
  }

  factory Booking.fromFirestore(String id, Map<String, dynamic> map) {
    return Booking(
      id: id,
      kind: (map['kind'] ?? 'ground') as String,
      resourceId: (map['resource_id'] ?? '') as String,
      resourceName: (map['resource_name'] ?? '') as String,
      organizerUid: (map['organizer_uid'] ?? '') as String,
      organizerName: (map['organizer_name'] ?? '') as String,
      counterpartyUid: (map['counterparty_uid'] ?? '') as String,
      counterpartyName: (map['counterparty_name'] ?? '') as String,
      date: (map['date'] ?? '') as String,
      slotStart: (map['slot_start'] ?? '') as String,
      slotEnd: (map['slot_end'] ?? '') as String,
      durationMinutes: (map['duration_minutes'] as num?)?.toInt() ?? 0,
      amountPaise: (map['amount_paise'] as num?)?.toInt() ?? 0,
      platformFeePaise: (map['platform_fee_paise'] as num?)?.toInt() ?? 0,
      payoutAmountPaise: (map['payout_amount_paise'] as num?)?.toInt() ?? 0,
      paymentMethod: (map['payment_method'] ?? 'razorpay') as String,
      paymentStatus: (map['payment_status'] ?? 'pending') as String,
      razorpayOrderId: (map['razorpay_order_id'] ?? '') as String?,
      razorpayPaymentId: (map['razorpay_payment_id'] ?? '') as String?,
      status: (map['status'] ?? 'held') as String,
      qrToken: (map['qr_token'] ?? '') as String?,
      matchId: (map['match_id'] ?? '') as String?,
      notes: (map['notes'] ?? '') as String?,
      cancellationReason: (map['cancellation_reason'] ?? '') as String?,
      refundAmountPaise: (map['refund_amount_paise'] as num?)?.toInt() ?? 0,
      refundStatus: (map['refund_status'] ?? 'none') as String,
      refundId: (map['refund_id'] ?? '') as String?,
      createdAt: _toDate(map['created_at']),
      updatedAt: _toDate(map['updated_at']),
      confirmedAt: _toDate(map['confirmed_at']),
      cancelledAt: _toDate(map['cancelled_at']),
      codConfirmedAt: _toDate(map['cod_confirmed_at']),
    );
  }

  /// Use when organizer creates a booking. Status starts at 'held' or
  /// 'pending_payment' depending on payment method.
  Map<String, dynamic> toCreateMap() {
    return {
      'kind': kind,
      'resource_id': resourceId,
      'resource_name': resourceName,
      'organizer_uid': organizerUid,
      'organizer_name': organizerName,
      'counterparty_uid': counterpartyUid,
      'counterparty_name': counterpartyName,
      'date': date,
      'slot_start': slotStart,
      'slot_end': slotEnd,
      'duration_minutes': durationMinutes,
      'amount_paise': amountPaise,
      'platform_fee_paise': platformFeePaise,
      'payout_amount_paise': payoutAmountPaise,
      'payment_method': paymentMethod,
      'payment_status': 'pending',
      'status': paymentMethod == 'cod' ? 'pending_payment' : 'held',
      'refund_amount_paise': 0,
      'refund_status': 'none',
      'created_at': FieldValue.serverTimestamp(),
      'updated_at': FieldValue.serverTimestamp(),
    };
  }
}

DateTime? _toDate(Object? value) {
  if (value is Timestamp) return value.toDate();
  if (value is DateTime) return value;
  if (value is String) return DateTime.tryParse(value);
  return null;
}