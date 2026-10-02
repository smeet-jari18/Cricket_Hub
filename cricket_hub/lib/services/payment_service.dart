import 'dart:async';

import 'package:razorpay_flutter/razorpay_flutter.dart';

import 'booking_service.dart';

/// Wraps the Razorpay checkout flow.
///
/// Lifecycle:
/// 1. UI calls [openCheckout] after receiving a Razorpay orderId from the
///    server-side `createRazorpayOrder` Cloud Function.
/// 2. We listen for payment events: success / error / external wallet.
/// 3. On success, we forward the signature back to `verifyRazorpayPayment`
///    Cloud Function for HMAC verification.
/// 4. The user is navigated to BookingSuccess on verified payment.
class PaymentService {
  PaymentService({BookingService? bookingService})
      : _bookingService = bookingService ?? BookingService();

  final BookingService _bookingService;
  final Razorpay _razorpay = Razorpay();
  bool _initialized = false;
  String? _activeBookingId;
  PaymentSession? _lastSession;

  /// Idempotent. Safe to call multiple times.
  void initialize() {
    if (_initialized) return;
    _initialized = true;
    _razorpay.on(Razorpay.EVENT_PAYMENT_SUCCESS, _handleSuccess);
    _razorpay.on(Razorpay.EVENT_PAYMENT_ERROR, _handleError);
    _razorpay.on(Razorpay.EVENT_EXTERNAL_WALLET, _handleExternalWallet);
  }

  void dispose() {
    _razorpay.clear();
    _initialized = false;
  }

  /// Opens Razorpay checkout for [bookingId]. Caller must await the session's
  /// [PaymentSession.completion] future to receive the final [PaymentResult].
  PaymentSession openCheckout({
    required String bookingId,
    required String orderId,
    required String razorpayKeyId,
    required int amountInPaise,
    required String organizerName,
    required String organizerEmail,
    required String organizerPhone,
    required String description,
  }) {
    if (!_initialized) initialize();
    _activeBookingId = bookingId;

    final options = <String, dynamic>{
      'key': razorpayKeyId,
      'amount': amountInPaise,
      'order_id': orderId,
      'name': 'CricketHub',
      'description': description,
      'prefill': {
        'name': organizerName,
        'email': organizerEmail,
        'contact': organizerPhone,
      },
      'theme': {
        'color': '#006B5C', // matches AppTheme.primary
        'backdrop_color': '#F5F7FA',
      },
      'notes': {'booking_id': bookingId},
      'modal': {
        'confirm_close': true,
        'animation': 'slide_from_bottom',
        'ondismiss': {'method': 'getDismissedReason'},
      },
      'retry': {'enabled': true, 'max_count': 3},
    };

    final session = PaymentSession(bookingId: bookingId);
    _lastSession = session;
    _razorpay.open(options);
    return session;
  }

  void _handleSuccess(PaymentSuccessResponse response) {
    final bookingId = _activeBookingId;
    _activeBookingId = null;
    if (bookingId == null) return;

    // Forward signature to server for HMAC verification.
    _bookingService
        .verifyRazorpayPayment(
          bookingId: bookingId,
          razorpayPaymentId: response.paymentId ?? '',
          razorpayOrderId: response.orderId ?? '',
          razorpaySignature: response.signature ?? '',
        )
        .then((result) {
          _lastSession?.complete(PaymentResult(
            bookingId: bookingId,
            verified: true,
            data: result,
            reason: '',
          ));
        })
        .catchError((error) {
          _lastSession?.complete(PaymentResult(
            bookingId: bookingId,
            verified: false,
            data: const <String, dynamic>{},
            reason: 'Verification failed. Please contact support.',
          ));
        });
  }

  void _handleError(PaymentFailureResponse response) {
    final bookingId = _activeBookingId;
    _activeBookingId = null;
    _lastSession?.complete(PaymentResult(
      bookingId: bookingId ?? '',
      verified: false,
      data: const <String, dynamic>{},
      reason: response.message ?? 'Payment failed. Try again.',
    ));
  }

  void _handleExternalWallet(ExternalWalletResponse response) {
    // Razorpay will redirect to the wallet app; success/failure will arrive
    // via the standard events.
  }
}

/// A handle returned by [PaymentService.openCheckout]. The caller awaits
/// [completion] to receive the final [PaymentResult].
class PaymentSession {
  PaymentSession({required this.bookingId});

  final String bookingId;
  final Completer<PaymentResult> _completer = Completer<PaymentResult>();

  Future<PaymentResult> get completion => _completer.future;

  void complete(PaymentResult result) {
    if (!_completer.isCompleted) _completer.complete(result);
  }
}

/// Result of a Razorpay checkout attempt.
class PaymentResult {
  const PaymentResult({
    required this.bookingId,
    required this.verified,
    required this.data,
    required this.reason,
  });

  final String bookingId;
  final bool verified;
  final Map<String, dynamic> data;
  final String reason;
}