import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../../core/app_theme.dart';
import '../../models/booking_model.dart';
import '../../providers/auth_provider.dart';
import '../../services/booking_service.dart';
import 'leave_review_screen.dart';

/// Sprint 11's `booking_detail_screen.dart`.
///
/// Single place to see a booking: status timeline, money breakdown, the QR
/// (for the venue) and the cancel action. `cancelBooking` and `getBooking`
/// existed in `BookingService` but had no caller before this screen.
class BookingDetailScreen extends StatelessWidget {
  const BookingDetailScreen({super.key});

  static const String route = '/booking-detail';

  @override
  Widget build(BuildContext context) {
    final arg = ModalRoute.of(context)?.settings.arguments;
    if (arg is! Booking) {
      return Scaffold(
        appBar: AppBar(title: const Text('Booking')),
        body: const Center(child: Text('No booking selected.')),
      );
    }

    // Live-update the booking so a status flip (webhook confirming the
    // payment) is reflected without leaving the screen.
    return StreamBuilder<Booking?>(
      stream: context.read<BookingService>().bookingStream(arg.id),
      initialData: arg,
      builder: (context, snapshot) {
        final booking = snapshot.data ?? arg;
        return _Body(booking: booking);
      },
    );
  }
}

class _Body extends StatefulWidget {
  const _Body({required this.booking});

  final Booking booking;

  @override
  State<_Body> createState() => _BodyState();
}

class _BodyState extends State<_Body> {
  bool _busy = false;

  Booking get _b => widget.booking;

  bool get _canCancel => !_b.isCancelled && !_b.isCompleted;

  String? get _uid => context.read<AuthProvider>().firebaseUser?.uid;

  /// The ground owner holding this booking, looking at an unpaid COD booking.
  /// Only they may confirm the cash, and only while it is `pending_payment`.
  /// Ground owner, booking already confirmed, match is over.
  bool get _canMarkCompleted =>
      _uid != null &&
      _uid == _b.counterpartyUid &&
      _b.isGroundBooking &&
      _b.isConfirmed;

  bool get _canConfirmCash =>
      _uid != null &&
      _uid == _b.counterpartyUid &&
      _b.isGroundBooking &&
      _b.isPendingPayment &&
      _b.paymentMethod == 'cod';

  // ---------------------------------------------------------------------------
  // Actions
  // ---------------------------------------------------------------------------

  Future<void> _confirmCash() async {
    final messenger = ScaffoldMessenger.of(context);
    setState(() => _busy = true);
    try {
      await context.read<BookingService>().confirmCodBooking(_b.id);
      messenger.showSnackBar(
        const SnackBar(content: Text('Cash received — booking confirmed.')),
      );
    } catch (e) {
      messenger.showSnackBar(
        SnackBar(content: Text('Could not confirm: $e')),
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _markCompleted() async {
    final messenger = ScaffoldMessenger.of(context);
    setState(() => _busy = true);
    try {
      await context.read<BookingService>().markBookingCompleted(_b.id);
      messenger.showSnackBar(
        const SnackBar(content: Text('Match closed. The player can rate you now.')),
      );
    } catch (e) {
      messenger.showSnackBar(
        SnackBar(content: Text('Could not close the booking: $e')),
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _cancel() async {
    final refundPaise = _b.computeRefundAmountPaise();
    final refund = '₹${(refundPaise / 100).round()}';

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Cancel this booking?'),
        content: Text(
          refundPaise > 0
              ? 'You will get $refund back, based on how close the slot is.'
              : 'This slot is less than 12 hours away, so the refund is ₹0.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Keep it'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Cancel booking',
                style: TextStyle(color: AppTheme.danger)),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    setState(() => _busy = true);
    try {
      await context
          .read<BookingService>()
          .cancelBooking(bookingId: _b.id, reason: 'Cancelled by organizer');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Booking cancelled.')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not cancel: $e')),
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _openReview() {
    Navigator.pushNamed(
      context,
      LeaveReviewScreen.route,
      arguments: LeaveReviewArgs(
        bookingId: _b.id,
        groundId: _b.resourceId,
        groundName: _b.resourceName,
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Build
  // ---------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final uid = context.watch<AuthProvider>().appUser?.uid;
    final isOrganizer = uid != null && uid == _b.organizerUid;

    return Scaffold(
      appBar: AppBar(title: const Text('Booking details')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _Header(booking: _b),
          const SizedBox(height: 16),
          _Section(
            title: 'When & where',
            rows: [
              ('Ground', _b.resourceName.isEmpty ? '—' : _b.resourceName),
              ('Date', _b.date),
              ('Time', '${_b.slotStart} – ${_b.slotEnd}'),
              ('Duration', '${_b.durationMinutes} min'),
            ],
          ),
          const SizedBox(height: 12),
          _Section(
            title: 'Money',
            rows: [
              ('Total paid', _b.amountDisplay),
              ('Platform fee', _b.platformFeeDisplay),
              ('Owner payout',
                  '₹${(_b.payoutAmountPaise / 100).round()}'),
              ('Method', _b.paymentMethod == 'cod'
                  ? 'Cash on ground'
                  : 'Razorpay (online)'),
              ('Payment', _b.paymentStatus.replaceAll('_', ' ')),
            ],
          ),
          const SizedBox(height: 12),
          _Section(
            title: 'People',
            rows: [
              ('Organizer', _b.organizerName.isEmpty ? '—' : _b.organizerName),
              ('Ground owner',
                  _b.counterpartyName.isEmpty ? '—' : _b.counterpartyName),
            ],
          ),
          if (_b.notes != null && _b.notes!.isNotEmpty) ...[
            const SizedBox(height: 12),
            _Section(title: 'Notes', rows: [('Note', _b.notes!)]),
          ],
          if (_b.refundAmountPaise > 0) ...[
            const SizedBox(height: 12),
            _Section(
              title: 'Refund',
              rows: [
                ('Amount', '₹${(_b.refundAmountPaise / 100).round()}'),
                ('Status', _b.refundStatus),
              ],
            ),
          ],
          if (_b.hasQrCode) ...[
            const SizedBox(height: 16),
            _QrCard(token: _b.qrToken!),
          ],
          const SizedBox(height: 24),
          if (isOrganizer && _b.isCompleted)
            OutlinedButton.icon(
              onPressed: _openReview,
              icon: const Icon(Icons.star_outline_rounded),
              label: const Text('Rate this ground'),
            ),
          if (_canConfirmCash) ...[
            const SizedBox(height: 8),
            FilledButton.icon(
              onPressed: _busy ? null : _confirmCash,
              icon: const Icon(Icons.payments_rounded),
              label: Text(
                _busy ? 'Confirming…' : 'Cash received — confirm booking',
              ),
            ),
            const SizedBox(height: 4),
            const Text(
              'The player pays you in cash at the ground. Confirm here so '
              'their QR becomes valid for check-in.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 11, color: AppTheme.textSecondary),
            ),
          ],
          if (_canMarkCompleted) ...[
            const SizedBox(height: 8),
            FilledButton.icon(
              onPressed: _busy ? null : _markCompleted,
              icon: const Icon(Icons.sports_cricket_rounded),
              label: Text(_busy ? 'Closing…' : 'Match played — close booking'),
            ),
          ],
          if (_canCancel) ...[
            const SizedBox(height: 8),
            OutlinedButton.icon(
              onPressed: _busy ? null : _cancel,
              icon: const Icon(Icons.close_rounded, color: AppTheme.danger),
              label: Text(
                _busy ? 'Cancelling…' : 'Cancel booking',
                style: const TextStyle(color: AppTheme.danger),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// -----------------------------------------------------------------------------
// Pieces
// -----------------------------------------------------------------------------

class _Header extends StatelessWidget {
  const _Header({required this.booking});

  final Booking booking;

  Color get _color {
    switch (booking.status) {
      case 'confirmed':
        return AppTheme.boundaryFour;
      case 'cancelled':
      case 'no_show':
        return AppTheme.danger;
      case 'completed':
        return AppTheme.primary;
      default:
        return AppTheme.accent;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: _color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _color.withValues(alpha: 0.35)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            booking.status.replaceAll('_', ' ').toUpperCase(),
            style: TextStyle(
              fontSize: 11,
              letterSpacing: 1.2,
              fontWeight: FontWeight.w800,
              color: _color,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            booking.amountDisplay,
            style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 2),
          Text(
            booking.id,
            style: const TextStyle(
              fontSize: 11,
              color: AppTheme.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

class _Section extends StatelessWidget {
  const _Section({required this.title, required this.rows});

  final String title;
  final List<(String, String)> rows;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title.toUpperCase(),
              style: const TextStyle(
                fontSize: 10,
                letterSpacing: 1,
                fontWeight: FontWeight.w800,
                color: AppTheme.textSecondary,
              ),
            ),
            const SizedBox(height: 10),
            for (final (label, value) in rows)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(
                      width: 120,
                      child: Text(
                        label,
                        style: const TextStyle(
                          fontSize: 13,
                          color: AppTheme.textSecondary,
                        ),
                      ),
                    ),
                    Expanded(
                      child: Text(
                        value,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _QrCard extends StatelessWidget {
  const _QrCard({required this.token});

  final String token;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          children: [
            const Text(
              'SHOW THIS AT THE GROUND',
              style: TextStyle(
                fontSize: 10,
                letterSpacing: 1,
                fontWeight: FontWeight.w800,
                color: AppTheme.textSecondary,
              ),
            ),
            const SizedBox(height: 14),
            QrImageView(
              data: token,
              version: QrVersions.auto,
              size: 200,
              backgroundColor: Colors.white,
            ),
            const SizedBox(height: 10),
            const Text(
              'The ground owner scans this to verify your booking.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12, color: AppTheme.textSecondary),
            ),
          ],
        ),
      ),
    );
  }
}
