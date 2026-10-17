import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/app_theme.dart';
import '../../models/booking_model.dart';
import '../../models/ground_model.dart';
import '../../providers/auth_provider.dart';
import '../../services/booking_service.dart';
import '../../services/ground_service.dart';
import 'owner_calendar_screen.dart';
import 'owner_create_ground_screen.dart';
import 'owner_earnings_screen.dart';
import 'owner_qr_scanner_screen.dart';

/// Sprint 9's `owner_dashboard.dart` — the ground owner's home.
///
/// Before this screen existed a ground owner had no entry point at all:
/// `ownerGroundsStream`, `createGround` and `submitForVerification` were all
/// written but nothing in the app could reach them.
class OwnerDashboard extends StatelessWidget {
  const OwnerDashboard({super.key});

  static const String route = '/owner-dashboard';

  @override
  Widget build(BuildContext context) {
    final uid = context.watch<AuthProvider>().appUser?.uid;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Ground owner'),
        actions: [
          IconButton(
            tooltip: 'Scan a booking QR',
            onPressed: () =>
                Navigator.pushNamed(context, OwnerQrScannerScreen.route),
            icon: const Icon(Icons.qr_code_scanner_rounded),
          ),
        ],
      ),
      body: uid == null
          ? const Center(child: Text('Please sign in.'))
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _TodayCard(ownerUid: uid),
                const SizedBox(height: 16),
                const _QuickActions(),
                const SizedBox(height: 20),
                const Text(
                  'MY GROUNDS',
                  style: TextStyle(
                    fontSize: 10,
                    letterSpacing: 1,
                    fontWeight: FontWeight.w800,
                    color: AppTheme.textSecondary,
                  ),
                ),
                const SizedBox(height: 10),
                _GroundList(ownerUid: uid),
              ],
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.pushNamed(
          context,
          OwnerCreateGroundScreen.route,
        ),
        icon: const Icon(Icons.add_rounded),
        label: const Text('Add ground'),
      ),
    );
  }
}

class _TodayCard extends StatelessWidget {
  const _TodayCard({required this.ownerUid});

  final String ownerUid;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<Booking>>(
      stream: context
          .read<BookingService>()
          .counterpartyBookingsStream(ownerUid),
      builder: (context, snapshot) {
        final all = snapshot.data ?? const <Booking>[];
        final today = _isoDate(DateTime.now());
        final todayBookings = all.where((b) => b.date == today).toList();
        final confirmed =
            all.where((b) => b.isConfirmed || b.isCompleted).toList();
        final revenuePaise = confirmed.fold<int>(
            0, (sum, b) => sum + b.payoutAmountPaise);

        return Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [AppTheme.primary, AppTheme.primaryBright],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'TODAY',
                style: TextStyle(
                  fontSize: 10,
                  letterSpacing: 1.2,
                  fontWeight: FontWeight.w800,
                  color: Colors.white70,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                '${todayBookings.length} booking'
                '${todayBookings.length == 1 ? '' : 's'}',
                style: const TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  _MiniStat(
                    label: 'Confirmed',
                    value: '${confirmed.length}',
                  ),
                  const SizedBox(width: 24),
                  _MiniStat(
                    label: 'Payout earned',
                    value: '₹${(revenuePaise / 100).round()}',
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  static String _isoDate(DateTime dt) =>
      '${dt.year.toString().padLeft(4, '0')}-'
      '${dt.month.toString().padLeft(2, '0')}-'
      '${dt.day.toString().padLeft(2, '0')}';
}

class _MiniStat extends StatelessWidget {
  const _MiniStat({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          value,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: Colors.white,
          ),
        ),
        Text(
          label,
          style: const TextStyle(fontSize: 11, color: Colors.white70),
        ),
      ],
    );
  }
}

class _QuickActions extends StatelessWidget {
  const _QuickActions();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _ActionTile(
            icon: Icons.qr_code_scanner_rounded,
            label: 'Scan QR',
            onTap: () =>
                Navigator.pushNamed(context, OwnerQrScannerScreen.route),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _ActionTile(
            icon: Icons.account_balance_wallet_rounded,
            label: 'Earnings',
            onTap: () =>
                Navigator.pushNamed(context, OwnerEarningsScreen.route),
          ),
        ),
      ],
    );
  }
}

class _ActionTile extends StatelessWidget {
  const _ActionTile({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 18),
          child: Column(
            children: [
              Icon(icon, color: AppTheme.primary, size: 26),
              const SizedBox(height: 8),
              Text(
                label,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _GroundList extends StatelessWidget {
  const _GroundList({required this.ownerUid});

  final String ownerUid;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<Ground>>(
      stream: context.read<GroundService>().ownerGroundsStream(ownerUid),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Padding(
            padding: EdgeInsets.all(24),
            child: Center(child: CircularProgressIndicator()),
          );
        }
        final grounds = snapshot.data ?? const <Ground>[];
        if (grounds.isEmpty) {
          return Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  const Icon(Icons.stadium_outlined,
                      size: 40, color: AppTheme.textSecondary),
                  const SizedBox(height: 12),
                  const Text(
                    'No grounds yet',
                    style: TextStyle(fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'List your ground and start taking bookings.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 13,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 14),
                  OutlinedButton(
                    onPressed: () => Navigator.pushNamed(
                      context,
                      OwnerCreateGroundScreen.route,
                    ),
                    child: const Text('Create your first ground'),
                  ),
                ],
              ),
            ),
          );
        }
        return Column(
          children: [
            for (final g in grounds)
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: _GroundRow(ground: g),
              ),
          ],
        );
      },
    );
  }
}

class _GroundRow extends StatelessWidget {
  const _GroundRow({required this.ground});

  final Ground ground;

  Color get _statusColor {
    if (ground.isActive) return AppTheme.boundaryFour;
    if (ground.status == 'pending_verification') return AppTheme.accent;
    return AppTheme.textSecondary;
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        onTap: () => Navigator.pushNamed(
          context,
          OwnerCalendarScreen.route,
          arguments: ground,
        ),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: AppTheme.primaryContainer,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.stadium_rounded,
                    color: AppTheme.primary, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      ground.name,
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${ground.city} · ₹${ground.priceWeekdayHourly}/hr',
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppTheme.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: _statusColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  ground.status.replaceAll('_', ' '),
                  style: TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.w800,
                    color: _statusColor,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
