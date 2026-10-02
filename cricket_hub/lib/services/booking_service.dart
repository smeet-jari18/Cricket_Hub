import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';

import '../core/app_constants.dart';
import '../models/booking_model.dart';

/// Booking orchestration. Wraps Firestore reads and Cloud Function calls for
/// slot reservation, payment, cancellation.
/// Matches CricketHub_Backend_Schema_Phase3.md -> Collection: bookings.
class BookingService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseFunctions _functions =
      FirebaseFunctions.instanceFor(region: 'asia-south1');

  CollectionReference<Map<String, dynamic>> get _bookings =>
      _db.collection(AppConstants.bookingsCol);

  // ---------------------------------------------------------------------------
  // Slot reservation
  // ---------------------------------------------------------------------------

  /// Creates a 10-minute hold on the slot for [uid]. Returns the new bookingId.
  /// Cloud Function `createBookingHold` performs the Firestore transaction.
  Future<String> createHold({
    required String groundId,
    required String groundName,
    required String ownerUid,
    required String ownerName,
    required String organizerUid,
    required String organizerName,
    required String date,
    required String slotStart,
    required String slotEnd,
    required int durationMinutes,
    required int amountPaise,
    required int platformFeePaise,
    String paymentMethod = 'razorpay',
    String? notes,
  }) async {
    final callable = _functions.httpsCallable('createBookingHold');
    final response = await callable.call({
      'kind': 'ground',
      'resourceId': groundId,
      'resourceName': groundName,
      'counterpartyUid': ownerUid,
      'counterpartyName': ownerName,
      'organizerUid': organizerUid,
      'organizerName': organizerName,
      'date': date,
      'slotStart': slotStart,
      'slotEnd': slotEnd,
      'durationMinutes': durationMinutes,
      'amountPaise': amountPaise,
      'platformFeePaise': platformFeePaise,
      'payoutAmountPaise': amountPaise - platformFeePaise,
      'notes': notes ?? '',
      'paymentMethod': paymentMethod,
    });
    final data = Map<String, dynamic>.from(response.data as Map);
    return data['bookingId'] as String;
  }

  // ---------------------------------------------------------------------------
  // Payment lifecycle
  // ---------------------------------------------------------------------------

  /// Creates a Razorpay order for an existing 'held' booking.
  /// Returns `{orderId, amountInPaise, currency, razorpayKeyId}`.
  Future<Map<String, dynamic>> createRazorpayOrder(String bookingId) async {
    final callable = _functions.httpsCallable('createRazorpayOrder');
    final response = await callable.call({'bookingId': bookingId});
    return Map<String, dynamic>.from(response.data as Map);
  }

  /// Verifies Razorpay signature server-side and transitions booking to 'confirmed'.
  Future<Map<String, dynamic>> verifyRazorpayPayment({
    required String bookingId,
    required String razorpayPaymentId,
    required String razorpayOrderId,
    required String razorpaySignature,
  }) async {
    final callable = _functions.httpsCallable('verifyRazorpayPayment');
    final response = await callable.call({
      'bookingId': bookingId,
      'razorpayPaymentId': razorpayPaymentId,
      'razorpayOrderId': razorpayOrderId,
      'razorpaySignature': razorpaySignature,
    });
    return Map<String, dynamic>.from(response.data as Map);
  }

  /// Cash-on-Ground alternative. Skips Razorpay; owner confirms cash receipt.
  Future<void> createCashOnGroundBooking({
    required String groundId,
    required String groundName,
    required String ownerUid,
    required String ownerName,
    required String organizerUid,
    required String organizerName,
    required String date,
    required String slotStart,
    required String slotEnd,
    required int durationMinutes,
    required int amountPaise,
    required int platformFeePaise,
    String? notes,
  }) async {
    final callable = _functions.httpsCallable('createBookingHold');
    await callable.call({
      'kind': 'ground',
      'resourceId': groundId,
      'resourceName': groundName,
      'counterpartyUid': ownerUid,
      'counterpartyName': ownerName,
      'organizerUid': organizerUid,
      'organizerName': organizerName,
      'date': date,
      'slotStart': slotStart,
      'slotEnd': slotEnd,
      'durationMinutes': durationMinutes,
      'amountPaise': amountPaise,
      'platformFeePaise': platformFeePaise,
      'payoutAmountPaise': amountPaise - platformFeePaise,
      'notes': notes ?? '',
      'paymentMethod': 'cod',
    });
  }

  // ---------------------------------------------------------------------------
  // Cancellation
  // ---------------------------------------------------------------------------

  /// Cancels a booking. Cloud Function `onBookingCancelled` enforces refund policy.
  Future<Map<String, dynamic>> cancelBooking({
    required String bookingId,
    required String reason,
  }) async {
    final callable = _functions.httpsCallable('onBookingCancelled');
    final response = await callable.call({
      'bookingId': bookingId,
      'reason': reason,
    });
    return Map<String, dynamic>.from(response.data as Map);
  }

  // ---------------------------------------------------------------------------
  // Reads
  // ---------------------------------------------------------------------------

  Stream<Booking?> bookingStream(String bookingId) {
    return _bookings.doc(bookingId).snapshots().map(
          (snap) => snap.exists
              ? Booking.fromFirestore(snap.id, snap.data()!)
              : null,
        );
  }

  Future<Booking?> getBooking(String bookingId) async {
    final snap = await _bookings.doc(bookingId).get();
    if (!snap.exists) return null;
    return Booking.fromFirestore(snap.id, snap.data()!);
  }

  /// All bookings for an organizer (most recent first).
  Stream<List<Booking>> organizerBookingsStream(String uid, {int limit = 50}) {
    return _bookings
        .where('organizer_uid', isEqualTo: uid)
        .orderBy('created_at', descending: true)
        .limit(limit)
        .snapshots()
        .map((snap) => snap.docs
            .map((doc) => Booking.fromFirestore(doc.id, doc.data()))
            .toList());
  }

  /// All bookings on grounds owned by [uid].
  Stream<List<Booking>> counterpartyBookingsStream(String uid, {int limit = 100}) {
    return _bookings
        .where('counterparty_uid', isEqualTo: uid)
        .orderBy('date', descending: false)
        .limit(limit)
        .snapshots()
        .map((snap) => snap.docs
            .map((doc) => Booking.fromFirestore(doc.id, doc.data()))
            .toList());
  }

  /// Today's bookings on grounds owned by [uid].
  Future<List<Booking>> todayBookings(String uid) async {
    final today = _isoDate(DateTime.now());
    final snap = await _bookings
        .where('counterparty_uid', isEqualTo: uid)
        .where('date', isEqualTo: today)
        .get();
    return snap.docs.map((doc) => Booking.fromFirestore(doc.id, doc.data())).toList();
  }

  // ---------------------------------------------------------------------------
  // QR validation (server-side)
  // ---------------------------------------------------------------------------

  /// Owner-side validation of a booking QR (returns booking summary if valid).
  Future<Map<String, dynamic>> validateQr(String qrToken) async {
    final callable = _functions.httpsCallable('validateBookingQR');
    final response = await callable.call({'qrToken': qrToken});
    return Map<String, dynamic>.from(response.data as Map);
  }

  String _isoDate(DateTime dt) {
    final y = dt.year.toString().padLeft(4, '0');
    final m = dt.month.toString().padLeft(2, '0');
    final d = dt.day.toString().padLeft(2, '0');
    return '$y-$m-$d';
  }
}