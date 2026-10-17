import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/app_theme.dart';
import '../../models/booking_model.dart';
import '../../providers/auth_provider.dart';
import '../../services/booking_service.dart';
import 'booking_detail_screen.dart';

/// "My bookings" — everything the signed-in user booked as an organizer, plus
/// every booking made on their grounds (they might be an owner too).
///
/// Until now `organizerBookingsStream` / `counterpartyBookingsStream` existed
/// but nothing called them, so a user had no way to see a booking again after
/// leaving the success screen.
class MyBookingsScreen extends StatelessWidget {
  const MyBookingsScreen({super.key});

  static const String route = '/my-bookings';

  @override
  Widget build(BuildContext context) {
    final uid = context.watch<AuthProvider>().appUser?.uid;

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('My bookings'),
          bottom: const TabBar(
            labelColor: AppTheme.primary,
            unselectedLabelColor: AppTheme.textSecondary,
            indicatorColor: AppTheme.primary,
            tabs: [
              Tab(text: 'As organizer'),
              Tab(text: 'On my grounds'),
            ],
          ),
        ),
        body: uid == null
            ? const Center(child: Text('Please sign in.'))
            : TabBarView(
                children: [
                  _BookingList(
                    stream: context
                        .read<BookingService>()
                        .organizerBookingsStream(uid),
                    emptyTitle: 'No bookings yet',
                    emptyMessage:
                        'Browse grounds from the menu and book your first slot.',
                  ),
                  _BookingList(
                    stream: context
                        .read<BookingService>()
                        .counterpartyBookingsStream(uid),
                    emptyTitle: 'No incoming bookings',
                    emptyMessage:
                        'Bookings made on grounds you own will show up here.',
                  ),
                ],
              ),
      ),
    );
  }
}

class _BookingList extends StatelessWidget {
  const _BookingList({
    required this.stream,
    required this.emptyTitle,
    required this.emptyMessage,
  });

  final Stream<List<Booking>> stream;
  final String emptyTitle;
  final String emptyMessage;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<Booking>>(
      stream: stream,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return _Message(
            icon: Icons.error_outline_rounded,
            title: 'Could not load bookings',
            body: '${snapshot.error}',
          );
        }
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        final bookings = snapshot.data ?? const <Booking>[];
        if (bookings.isEmpty) {
          return _Message(
            icon: Icons.event_note_rounded,
            title: emptyTitle,
            body: emptyMessage,
          );
        }
        return ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: bookings.length,
          separatorBuilder: (_, __) => const SizedBox(height: 10),
          itemBuilder: (context, i) => _BookingCard(booking: bookings[i]),
        );
      },
    );
  }
}

class _BookingCard extends StatelessWidget {
  const _BookingCard({required this.booking});

  final Booking booking;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        onTap: () => Navigator.pushNamed(
          context,
          BookingDetailScreen.route,
          arguments: booking,
        ),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      booking.resourceName.isEmpty
                          ? 'Booking'
                          : booking.resourceName,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ),
                  _StatusChip(status: booking.status),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(Icons.event_rounded,
                      size: 15, color: AppTheme.textSecondary),
                  const SizedBox(width: 6),
                  Text(
                    '${booking.date} · ${booking.slotStart}–${booking.slotEnd}',
                    style: const TextStyle(
                      fontSize: 13,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    booking.amountDisplay,
                    style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 15,
                    ),
                  ),
                  Text(
                    booking.paymentStatus.replaceAll('_', ' '),
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.status});

  final String status;

  Color get _color {
    switch (status) {
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
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: _color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        status.replaceAll('_', ' '),
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w800,
          color: _color,
        ),
      ),
    );
  }
}

class _Message extends StatelessWidget {
  const _Message({required this.icon, required this.title, required this.body});

  final IconData icon;
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 48, color: AppTheme.textSecondary),
            const SizedBox(height: 16),
            Text(title, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            Text(
              body,
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppTheme.textSecondary),
            ),
          ],
        ),
      ),
    );
  }
}
