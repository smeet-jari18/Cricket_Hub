import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/app_theme.dart';
import '../../models/payout_model.dart';
import '../../providers/auth_provider.dart';
import '../../services/payout_service.dart';
import '../../l10n/generated/app_localizations.dart';

/// Sprint 9's `owner_earnings_screen.dart`.
///
/// Reads the ledger `weeklyPayoutDigest` fills in every Monday. Before this,
/// payouts were written to Firestore but invisible to the owner.
class OwnerEarningsScreen extends StatelessWidget {
  const OwnerEarningsScreen({super.key});

  static const String route = '/owner-earnings';

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final uid = context.watch<AuthProvider>().appUser?.uid;

    return Scaffold(
      appBar: AppBar(title: Text(l10n.earnings)),
      body: uid == null
          ? Center(child: Text(l10n.commonPleaseSignIn))
          : StreamBuilder<List<PayoutWeek>>(
              stream: context.read<PayoutService>().payoutWeeksStream(uid),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return _msg(Icons.error_outline_rounded, 'Could not load',
                      '${snapshot.error}');
                }
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                final weeks = snapshot.data ?? const <PayoutWeek>[];
                if (weeks.isEmpty) {
                  return _msg(
                    Icons.account_balance_wallet_outlined,
                    'No payouts yet',
                    'Your weekly settlement appears here every Monday once '
                        'you have confirmed bookings.',
                  );
                }

                final totalNet = weeks.fold<int>(
                    0, (s, w) => s + w.netPayoutPaise);
                final pending = weeks
                    .where((w) => !w.isSettled)
                    .fold<int>(0, (s, w) => s + w.netPayoutPaise);

                return ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    _TotalsCard(
                      totalNetPaise: totalNet,
                      pendingPaise: pending,
                      weeks: weeks.length,
                    ),
                    const SizedBox(height: 18),
                    Text(
                      l10n.weekly_settlements,
                      style: const TextStyle(
                        fontSize: 10,
                        letterSpacing: 1,
                        fontWeight: FontWeight.w800,
                        color: AppTheme.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 10),
                    for (final w in weeks)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: _WeekCard(week: w),
                      ),
                  ],
                );
              },
            ),
    );
  }

  static Widget _msg(IconData icon, String title, String body) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 48, color: AppTheme.textSecondary),
            const SizedBox(height: 16),
            Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
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

class _TotalsCard extends StatelessWidget {
  const _TotalsCard({
    required this.totalNetPaise,
    required this.pendingPaise,
    required this.weeks,
  });

  final int totalNetPaise;
  final int pendingPaise;
  final int weeks;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppTheme.primaryContainer,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.primary.withValues(alpha: 0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.total_net_payout,
            style: const TextStyle(
              fontSize: 10,
              letterSpacing: 1.2,
              fontWeight: FontWeight.w800,
              color: AppTheme.primary,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            '₹${(totalNetPaise / 100).round()}',
            style: const TextStyle(fontSize: 32, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _Mini(label: l10n.weeks, value: '$weeks'),
              const SizedBox(width: 24),
              _Mini(
                label: l10n.pending_settlement,
                value: '₹${(pendingPaise / 100).round()}',
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _Mini extends StatelessWidget {
  const _Mini({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          value,
          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800),
        ),
        Text(
          label,
          style: const TextStyle(
            fontSize: 11,
            color: AppTheme.textSecondary,
          ),
        ),
      ],
    );
  }
}

class _WeekCard extends StatelessWidget {
  const _WeekCard({required this.week});

  final PayoutWeek week;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final color = week.isSettled ? AppTheme.boundaryFour : AppTheme.accent;

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
                    l10n.weekOf(week.weekStart),
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
                    week.isSettled ? 'PAID' : 'PENDING',
                    style: TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.w800,
                      color: color,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _Cell('Bookings', '${week.bookingCount}'),
                _Cell('Gross', week.grossDisplay),
                _Cell('Fee', week.feeDisplay),
                _Cell('Net', week.netDisplay, bold: true),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _Cell extends StatelessWidget {
  const _Cell(this.label, this.value, {this.bold = false});

  final String label;
  final String value;
  final bool bold;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 10, color: AppTheme.textSecondary),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: TextStyle(
            fontSize: 13,
            fontWeight: bold ? FontWeight.w800 : FontWeight.w600,
            color: bold ? AppTheme.primary : AppTheme.textPrimary,
          ),
        ),
      ],
    );
  }
}
