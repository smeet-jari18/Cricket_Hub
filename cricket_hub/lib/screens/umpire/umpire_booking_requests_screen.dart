import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/app_theme.dart';
import '../../models/booking_model.dart';
import '../../providers/auth_provider.dart';
import '../../services/booking_service.dart';
import '../../l10n/generated/app_localizations.dart';

/// The umpire's inbox: every `kind == 'umpire'` booking where they are the
/// counterparty.
///
/// Umpire bookings are cash-to-umpire, so they land in `pending_payment`.
/// Nothing else in the app can move them forward for an umpire (the organizer
/// side only handles ground bookings), so this screen is the only place the
/// umpire can say "I got the cash".
class UmpireBookingRequestsScreen extends StatelessWidget {
  const UmpireBookingRequestsScreen({super.key});

  static const String route = '/umpire-booking-requests';

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final uid = context.watch<AuthProvider>().appUser?.uid;
    if (uid == null) {
      return Scaffold(
        appBar: AppBar(title: Text(l10n.booking_requests)),
        body: Center(child: Text(l10n.commonPleaseSignIn)),
      );
    }

    return Scaffold(
      appBar: AppBar(title: Text(l10n.booking_requests)),
      body: StreamBuilder<List<Booking>>(
        stream: context.read<BookingService>().counterpartyBookingsStream(uid),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  l10n.errCouldNotLoadBookings('${snapshot.error}'),
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: AppTheme.danger),
                ),
              ),
            );
          }

          // Filtering happens client-side on purpose: `kind` + `status` would
          // need another composite index on bookings, and an umpire only ever
          // has a handful of bookings.
          final mine = (snapshot.data ?? const <Booking>[])
              .where((b) => b.isUmpireBooking)
              .toList();
          final pending =
              mine.where((b) => b.isPendingPayment).toList(growable: false);
          final confirmed = mine.where((b) => b.isConfirmed).toList()
            ..sort((a, b) => b.date.compareTo(a.date));

          if (mine.isEmpty) {
            return const _Empty();
          }

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              if (pending.isNotEmpty) ...[
                const _SectionLabel('AWAITING CASH'),
                const SizedBox(height: 10),
                for (final b in pending)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: _RequestCard(booking: b, actionable: true),
                  ),
                const SizedBox(height: 12),
              ] else
                Card(
                  color: AppTheme.primaryContainer,
                  child: Padding(
                    padding: const EdgeInsets.all(14),
                    child: Row(
                      children: [
                        const Icon(Icons.check_circle_outline_rounded, size: 18),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            l10n.noPendingRequestsHelp,
                            style: const TextStyle(fontSize: 13),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              if (confirmed.isNotEmpty) ...[
                const SizedBox(height: 12),
                const _SectionLabel('CONFIRMED'),
                const SizedBox(height: 10),
                for (final b in confirmed)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: _RequestCard(booking: b, actionable: false),
                  ),
              ],
            ],
          );
        },
      ),
    );
  }
}

class _Empty extends StatelessWidget {
  const _Empty();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.inbox_outlined, size: 48, color: AppTheme.textSecondary),
            const SizedBox(height: 16),
            Text(
              l10n.no_booking_requests_yet,
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            Text(
              l10n.umpireRequestHelp,
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppTheme.textSecondary),
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 10,
        letterSpacing: 1,
        fontWeight: FontWeight.w800,
        color: AppTheme.textSecondary,
      ),
    );
  }
}

class _RequestCard extends StatefulWidget {
  const _RequestCard({required this.booking, required this.actionable});

  final Booking booking;
  final bool actionable;

  @override
  State<_RequestCard> createState() => _RequestCardState();
}

class _RequestCardState extends State<_RequestCard> {
  bool _busy = false;

  Booking get _b => widget.booking;

  Future<void> _decline() async {
    final l10n = AppLocalizations.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.decline_this_request),
        content: Text(
          l10n.declineRequestHelp,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(l10n.keep_it),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(l10n.decline,
                style: const TextStyle(color: AppTheme.danger)),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    final messenger = ScaffoldMessenger.of(context);
    setState(() => _busy = true);
    try {
      await context.read<BookingService>().declineUmpireBooking(_b.id);
      messenger.showSnackBar(
        SnackBar(content: Text(l10n.request_declined)),
      );
    } catch (e) {
      messenger.showSnackBar(
        SnackBar(content: Text(l10n.errCouldNotDecline('$e'))),
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _confirmCash() async {
    final l10n = AppLocalizations.of(context);
    final messenger = ScaffoldMessenger.of(context);
    setState(() => _busy = true);
    try {
      // NOTE: confirmUmpireCodBooking (not confirmCodBooking) — the rules for
      // an umpire booking only allow the `status` + `updated_at` fields.
      await context.read<BookingService>().confirmUmpireCodBooking(_b.id);
      messenger.showSnackBar(
        SnackBar(content: Text(l10n.cash_received_booking_confirmed)),
      );
    } catch (e) {
      messenger.showSnackBar(
        SnackBar(content: Text(l10n.errCouldNotConfirm('$e'))),
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final color = _b.isConfirmed ? AppTheme.boundaryFour : AppTheme.accent;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    _b.organizerName.isEmpty ? 'Organizer' : _b.organizerName,
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    _b.status.replaceAll('_', ' '),
                    style: TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.w800,
                      color: color,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            _row(Icons.event_rounded, '${_b.date} · ${_b.slotStart}–${_b.slotEnd}'),
            _row(Icons.timer_outlined, '${_b.durationMinutes} min'),
            _row(Icons.payments_outlined, '${_b.amountDisplay} · cash on ground'),
            if (widget.actionable) ...[
              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: _busy ? null : _confirmCash,
                  icon: const Icon(Icons.check_rounded, size: 18),
                  label: Text(
                    _busy ? 'Confirming…' : 'Cash received — confirm',
                  ),
                ),
              ),
              const SizedBox(height: 6),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: _busy ? null : _decline,
                  icon: const Icon(Icons.close_rounded,
                      size: 18, color: AppTheme.danger),
                  label: Text(
                    l10n.decline,
                    style: const TextStyle(color: AppTheme.danger),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  static Widget _row(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Icon(icon, size: 14, color: AppTheme.textSecondary),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                fontSize: 12,
                color: AppTheme.textSecondary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
