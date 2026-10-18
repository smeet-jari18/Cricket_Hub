import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/app_constants.dart';
import '../../core/app_theme.dart';
import '../../models/umpire_model.dart';
import '../../providers/auth_provider.dart';
import '../../services/booking_service.dart';

/// One bookable window for an umpire.
///
/// Morning / Afternoon / Evening are 3-hour windows billed at the umpire's
/// hourly rate; Full day is a 12-hour window billed at the day rate (falling
/// back to 12 × hourly when the umpire has not set a day rate).
///
/// Kept as a plain class with pure maths so the pricing can be unit-tested
/// without a Firebase connection — see `test/umpire_booking_price_test.dart`.
class UmpireBookingWindow {
  const UmpireBookingWindow({
    required this.id,
    required this.label,
    required this.start,
    required this.end,
    required this.durationMinutes,
    required this.isFullDay,
  });

  final String id;
  final String label;
  final String start; // 'HH:mm'
  final String end; // 'HH:mm'
  final int durationMinutes;
  final bool isFullDay;

  static const List<UmpireBookingWindow> all = [
    UmpireBookingWindow(
      id: 'morning',
      label: 'Morning',
      start: '06:00',
      end: '09:00',
      durationMinutes: 180,
      isFullDay: false,
    ),
    UmpireBookingWindow(
      id: 'afternoon',
      label: 'Afternoon',
      start: '12:00',
      end: '15:00',
      durationMinutes: 180,
      isFullDay: false,
    ),
    UmpireBookingWindow(
      id: 'evening',
      label: 'Evening',
      start: '17:00',
      end: '20:00',
      durationMinutes: 180,
      isFullDay: false,
    ),
    UmpireBookingWindow(
      id: 'full_day',
      label: 'Full day',
      start: '08:00',
      end: '20:00',
      durationMinutes: 720,
      isFullDay: true,
    ),
  ];

  int get hours => durationMinutes ~/ 60;

  String get labelWithTime => '$label · $start–$end';

  /// Base price in paise, before the platform fee.
  ///
  /// Full day prefers [dayRate]; a 0 day rate means "not offered", in which
  /// case 12 × [hourlyRate] is used so the booking is never silently free.
  int basePricePaise({required int hourlyRate, required int dayRate}) {
    if (isFullDay && dayRate > 0) return dayRate * 100;
    return hourlyRate * hours * 100;
  }

  /// CricketHub's 5% platform fee, rounded to the nearest paise.
  int platformFeePaise({required int hourlyRate, required int dayRate}) {
    return (basePricePaise(hourlyRate: hourlyRate, dayRate: dayRate) *
            AppConstants.platformFeePct)
        .round();
  }

  /// What the umpire actually receives.
  int payoutPaise({required int hourlyRate, required int dayRate}) {
    return basePricePaise(hourlyRate: hourlyRate, dayRate: dayRate) -
        platformFeePaise(hourlyRate: hourlyRate, dayRate: dayRate);
  }
}

/// Books an umpire for a date + window. Cash-to-umpire (`cod`) only — the
/// umpire confirms the cash from `UmpireBookingRequestsScreen`.
class UmpireBookingScreen extends StatelessWidget {
  const UmpireBookingScreen({super.key});

  static const String route = '/umpire-booking';

  @override
  Widget build(BuildContext context) {
    final arg = ModalRoute.of(context)?.settings.arguments;
    if (arg is! Umpire) {
      return Scaffold(
        appBar: AppBar(title: const Text('Book umpire')),
        body: const Center(child: Text('No umpire selected.')),
      );
    }
    return _BookingBody(umpire: arg);
  }
}

class _BookingBody extends StatefulWidget {
  const _BookingBody({required this.umpire});

  final Umpire umpire;

  @override
  State<_BookingBody> createState() => _BookingBodyState();
}

class _BookingBodyState extends State<_BookingBody> {
  int _dayOffset = 0;
  UmpireBookingWindow _window = UmpireBookingWindow.all.first;
  bool _busy = false;

  static const int _daysShown = 14;

  Umpire get _umpire => widget.umpire;

  static String _iso(DateTime dt) =>
      '${dt.year.toString().padLeft(4, '0')}-'
      '${dt.month.toString().padLeft(2, '0')}-'
      '${dt.day.toString().padLeft(2, '0')}';

  static const List<String> _weekdayShort = [
    'Mon',
    'Tue',
    'Wed',
    'Thu',
    'Fri',
    'Sat',
    'Sun',
  ];

  static const List<String> _monthShort = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];

  int get _basePaise => _window.basePricePaise(
        hourlyRate: _umpire.hourlyRate,
        dayRate: _umpire.dayRate,
      );

  String get _rupees => '₹${(_basePaise / 100).round()}';

  Future<void> _book() async {
    final user = context.read<AuthProvider>().appUser;
    if (user == null) {
      _snack('Please sign in first.');
      return;
    }
    final date = _iso(DateTime.now().add(Duration(days: _dayOffset)));
    final base = _basePaise;
    if (base <= 0) {
      _snack('This umpire has no rate set for this window.');
      return;
    }
    final fee = _window.platformFeePaise(
      hourlyRate: _umpire.hourlyRate,
      dayRate: _umpire.dayRate,
    );

    setState(() => _busy = true);
    try {
      await context.read<BookingService>().createUmpireBooking(
            umpireId: _umpire.uid,
            umpireName: _umpire.displayName,
            organizerUid: user.uid,
            organizerName: user.displayName,
            date: date,
            slotStart: _window.start,
            slotEnd: _window.end,
            durationMinutes: _window.durationMinutes,
            amountPaise: base,
            platformFeePaise: fee,
          );
      if (!mounted) return;
      await showDialog<void>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Umpire requested'),
          content: Text(
            'Pay $_rupees in cash to ${_umpire.displayName} on the day. '
            'They will confirm the booking in the app once they receive it.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Got it'),
            ),
          ],
        ),
      );
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      _snack('Could not book: $e');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _snack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  @override
  Widget build(BuildContext context) {
    final umpire = _umpire;
    final base = _basePaise;
    final fee = _window.platformFeePaise(
      hourlyRate: umpire.hourlyRate,
      dayRate: umpire.dayRate,
    );
    final today = DateTime.now();

    return Scaffold(
      appBar: AppBar(title: Text('Book ${umpire.displayName}')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text(
            'PICK A DATE',
            style: TextStyle(
              fontSize: 10,
              letterSpacing: 1,
              fontWeight: FontWeight.w800,
              color: AppTheme.textSecondary,
            ),
          ),
          const SizedBox(height: 10),
          SizedBox(
            height: 76,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: _daysShown,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (context, i) {
                final day = today.add(Duration(days: i));
                final selected = i == _dayOffset;
                return InkWell(
                  onTap: () => setState(() => _dayOffset = i),
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    width: 60,
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    decoration: BoxDecoration(
                      color: selected ? AppTheme.primary : AppTheme.surfaceSoft,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: selected ? AppTheme.primary : AppTheme.border,
                      ),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          _weekdayShort[day.weekday - 1],
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: selected
                                ? Colors.white70
                                : AppTheme.textSecondary,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${day.day}',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            color: selected
                                ? Colors.white
                                : AppTheme.textPrimary,
                          ),
                        ),
                        Text(
                          _monthShort[day.month - 1],
                          style: TextStyle(
                            fontSize: 10,
                            color: selected
                                ? Colors.white70
                                : AppTheme.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            'PICK A WINDOW',
            style: TextStyle(
              fontSize: 10,
              letterSpacing: 1,
              fontWeight: FontWeight.w800,
              color: AppTheme.textSecondary,
            ),
          ),
          const SizedBox(height: 10),
          for (final w in UmpireBookingWindow.all)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: _WindowTile(
                window: w,
                hourlyRate: umpire.hourlyRate,
                dayRate: umpire.dayRate,
                selected: w.id == _window.id,
                onTap: () => setState(() => _window = w),
              ),
            ),
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'PRICE BREAKDOWN',
                    style: TextStyle(
                      fontSize: 10,
                      letterSpacing: 1,
                      fontWeight: FontWeight.w800,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 10),
                  _moneyRow(
                    '${_window.label} (${_window.hours}h × ₹${umpire.hourlyRate})',
                    '₹${(base / 100).round()}',
                  ),
                  _moneyRow(
                    'Platform fee (${(AppConstants.platformFeePct * 100).round()}%)',
                    '₹${(fee / 100).round()}',
                  ),
                  const Divider(height: 18),
                  _moneyRow(
                    'Pay in cash',
                    '₹${(base / 100).round()}',
                    bold: true,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Umpire receives ₹${((base - fee) / 100).round()} after the '
                    'platform fee.',
                    style: const TextStyle(
                      fontSize: 11,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          const Card(
            color: AppTheme.accentContainer,
            child: Padding(
              padding: EdgeInsets.all(14),
              child: Row(
                children: [
                  Icon(Icons.payments_outlined, size: 18),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Cash on ground: nothing is charged online. The umpire '
                      'confirms the cash in the app, then this booking is '
                      'locked in.',
                      style: TextStyle(fontSize: 12),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: ElevatedButton(
            onPressed: _busy || base <= 0 ? null : _book,
            child: Text(_busy ? 'Booking…' : 'Book for $_rupees · pay cash'),
          ),
        ),
      ),
    );
  }

  static Widget _moneyRow(String label, String value, {bool bold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 13,
                color: bold ? AppTheme.textPrimary : AppTheme.textSecondary,
                fontWeight: bold ? FontWeight.w700 : FontWeight.w400,
              ),
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: bold ? 16 : 13,
              fontWeight: bold ? FontWeight.w800 : FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _WindowTile extends StatelessWidget {
  const _WindowTile({
    required this.window,
    required this.hourlyRate,
    required this.dayRate,
    required this.selected,
    required this.onTap,
  });

  final UmpireBookingWindow window;
  final int hourlyRate;
  final int dayRate;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final price = window.basePricePaise(
      hourlyRate: hourlyRate,
      dayRate: dayRate,
    );
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: selected ? AppTheme.primaryContainer : AppTheme.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected ? AppTheme.primary : AppTheme.border,
            width: selected ? 1.5 : 1,
          ),
        ),
        child: Row(
          children: [
            Icon(
              selected
                  ? Icons.radio_button_checked_rounded
                  : Icons.radio_button_off_rounded,
              color: selected ? AppTheme.primary : AppTheme.textSecondary,
              size: 20,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    window.label,
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${window.start}–${window.end} · ${window.hours}h',
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            Text(
              '₹${(price / 100).round()}',
              style: const TextStyle(fontWeight: FontWeight.w800),
            ),
          ],
        ),
      ),
    );
  }
}
