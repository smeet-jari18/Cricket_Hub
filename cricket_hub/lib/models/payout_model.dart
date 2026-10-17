import 'package:cloud_firestore/cloud_firestore.dart';

/// One row of the owner's payout ledger.
///
/// Written by `weeklyPayoutDigest` in `functions/index.js` to
/// `payout_ledger/{ownerUid}/weeks/{weekStartIso}`.
class PayoutWeek {
  final String id; // weekStartIso
  final String ownerUid;
  final String weekStart;
  final int bookingCount;
  final int grossAmountPaise;
  final int platformFeePaise;
  final int netPayoutPaise;
  final String settlementStatus; // 'pending' | 'paid'
  final List<String> bookingIds;
  final DateTime? createdAt;

  const PayoutWeek({
    required this.id,
    required this.ownerUid,
    required this.weekStart,
    required this.bookingCount,
    required this.grossAmountPaise,
    required this.platformFeePaise,
    required this.netPayoutPaise,
    required this.settlementStatus,
    required this.bookingIds,
    this.createdAt,
  });

  factory PayoutWeek.fromFirestore(String id, Map<String, dynamic> map) {
    final raw = map['created_at'];
    return PayoutWeek(
      id: id,
      ownerUid: (map['owner_uid'] ?? '') as String,
      weekStart: (map['week_start'] ?? id) as String,
      bookingCount: (map['booking_count'] as num?)?.toInt() ?? 0,
      grossAmountPaise: (map['gross_amount_paise'] as num?)?.toInt() ?? 0,
      platformFeePaise: (map['platform_fee_paise'] as num?)?.toInt() ?? 0,
      netPayoutPaise: (map['net_payout_paise'] as num?)?.toInt() ?? 0,
      settlementStatus: (map['settlement_status'] ?? 'pending') as String,
      bookingIds:
          ((map['bookings'] as List?) ?? const []).map((e) => e.toString()).toList(),
      createdAt: raw is Timestamp ? raw.toDate() : null,
    );
  }

  String get netDisplay => '₹${(netPayoutPaise / 100).round()}';
  String get grossDisplay => '₹${(grossAmountPaise / 100).round()}';
  String get feeDisplay => '₹${(platformFeePaise / 100).round()}';
  bool get isSettled => settlementStatus == 'paid';
}
