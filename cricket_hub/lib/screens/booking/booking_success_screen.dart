import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../../core/app_theme.dart';
import '../../models/booking_model.dart';
import '../../services/booking_service.dart';

/// Booking confirmation screen with QR code + action buttons.
class BookingSuccessScreen extends StatelessWidget {
  const BookingSuccessScreen({super.key, required this.bookingId});

  static const String route = '/bookings/success';
  final String bookingId;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Booking confirmed'),
        automaticallyImplyLeading: false,
      ),
      body: StreamBuilder<Booking?>(
        stream: context.read<BookingService>().bookingStream(bookingId),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final booking = snapshot.data!;

          if (!booking.isConfirmed && !booking.isPendingPayment) {
            return _pending(context, booking);
          }

          return _content(context, booking);
        },
      ),
    );
  }

  Widget _content(BuildContext context, Booking booking) {
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        const SizedBox(height: 16),
        const _SuccessHero(),
        const SizedBox(height: 20),
        Text(
          'Booking Confirmed',
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.headlineMedium,
        ),
        const SizedBox(height: 4),
        Text(
          booking.isPendingPayment
              ? 'Booking held. Pay cash at the venue.'
              : 'Show this QR code at the venue.',
          textAlign: TextAlign.center,
          style: Theme.of(context)
              .textTheme
              .bodyMedium
              ?.copyWith(color: AppTheme.textSecondary),
        ),
        const SizedBox(height: 24),
        if (booking.hasQrCode) _qrCard(booking),
        const SizedBox(height: 24),
        _detailsCard(context, booking),
        const SizedBox(height: 24),
        _actionsRow(context, booking),
        const SizedBox(height: 16),
        OutlinedButton(
          onPressed: () {
            Navigator.popUntil(context, (route) => route.isFirst);
          },
          child: const Text('Back to home'),
        ),
      ],
    );
  }

  Widget _qrCard(Booking booking) {
    return Center(
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppTheme.border),
        ),
        child: Column(
          children: [
            QrImageView(
              data: booking.qrToken!,
              version: QrVersions.auto,
              size: 220,
              backgroundColor: Colors.white,
              eyeStyle: const QrEyeStyle(
                eyeShape: QrEyeShape.square,
                color: AppTheme.textPrimary,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              booking.id,
              style: const TextStyle(
                fontWeight: FontWeight.w700,
                letterSpacing: 1,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _detailsCard(BuildContext context, Booking booking) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              booking.resourceName,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 12),
            _detail('Date', booking.date),
            _detail('Time', '${booking.slotStart} – ${booking.slotEnd}'),
            _detail('Total', booking.amountDisplay),
            _detail(
              'Status',
              booking.isConfirmed ? 'Confirmed' : 'Pending cash payment',
            ),
          ],
        ),
      ),
    );
  }

  Widget _detail(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: AppTheme.textSecondary,
              fontSize: 13,
            ),
          ),
          Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }

  Widget _actionsRow(BuildContext context, Booking booking) {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton.icon(
            onPressed: () {
              // Add to calendar.
            },
            icon: const Icon(Icons.event_rounded, size: 16),
            label: const Text('Add to calendar'),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: OutlinedButton.icon(
            onPressed: () {
              // Open directions.
            },
            icon: const Icon(Icons.directions_rounded, size: 16),
            label: const Text('Directions'),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: OutlinedButton.icon(
            onPressed: () {
              // Share booking.
            },
            icon: const Icon(Icons.ios_share_rounded, size: 16),
            label: const Text('Share'),
          ),
        ),
      ],
    );
  }

  Widget _pending(BuildContext context, Booking booking) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.hourglass_top_rounded,
              size: 56,
              color: AppTheme.primary,
            ),
            const SizedBox(height: 12),
            Text(
              'Booking is processing',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 4),
            Text(
              'Status: ${booking.status}',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }
}

class _SuccessHero extends StatelessWidget {
  const _SuccessHero();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        width: 96,
        height: 96,
        decoration: const BoxDecoration(
          color: AppTheme.primaryContainer,
          shape: BoxShape.circle,
        ),
        child: const Icon(
          Icons.check_rounded,
          size: 64,
          color: AppTheme.primary,
        ),
      ),
    );
  }
}