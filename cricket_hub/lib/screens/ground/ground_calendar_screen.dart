import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/app_constants.dart';
import '../../core/app_theme.dart';
import '../../models/ground_model.dart';
import '../../services/ground_service.dart';
import '../booking/booking_checkout_screen.dart';
import '../booking/checkout_args.dart';

/// Calendar + slot picker for a single ground.
///
/// This is Sprint 7's `ground_calendar_screen.dart` from the Phase-3
/// Implementation Plan and the "Ground Calendar / Slot Picker" spec in
/// `CricketHub_UI_UX_Phase3.md`.
///
/// Flow: pick a date -> see that day's slot inventory -> pick a contiguous
/// run of free slots -> checkout. Before Phase 3 the detail screen jumped
/// straight to checkout with today + the ground's opening time hard-coded,
/// so a user could never choose a day or a time.
class GroundCalendarScreen extends StatelessWidget {
  const GroundCalendarScreen({super.key});

  static const String route = '/ground-calendar';

  @override
  Widget build(BuildContext context) {
    final ground = ModalRoute.of(context)?.settings.arguments;
    if (ground is! Ground) {
      return Scaffold(
        appBar: AppBar(title: const Text('Choose a slot')),
        body: const Center(child: Text('No ground selected.')),
      );
    }
    return _CalendarBody(ground: ground);
  }
}

class _CalendarBody extends StatefulWidget {
  const _CalendarBody({required this.ground});

  final Ground ground;

  @override
  State<_CalendarBody> createState() => _CalendarBodyState();
}

class _CalendarBodyState extends State<_CalendarBody> {
  static const int _daysAhead = 14;

  late final GroundService _grounds;
  late DateTime _selectedDate;
  final Set<String> _pickedSlots = {};

  @override
  void initState() {
    super.initState();
    _grounds = context.read<GroundService>();
    final today = DateTime.now();
    _selectedDate = DateTime(today.year, today.month, today.day);
  }

  Ground get _ground => widget.ground;

  String get _dateIso =>
      '${_selectedDate.year.toString().padLeft(4, '0')}-'
      '${_selectedDate.month.toString().padLeft(2, '0')}-'
      '${_selectedDate.day.toString().padLeft(2, '0')}';

  // ---------------------------------------------------------------------------
  // Slot maths
  // ---------------------------------------------------------------------------

  /// Every bookable slot key for the day, e.g. ['06:00-08:00', '08:00-10:00'].
  ///
  /// Mirrors `generateSlotsForGround` in `functions/index.js` so the client
  /// shows exactly the windows the server will accept.
  List<String> _allSlotKeys() {
    final open = _minutes(_ground.openTime);
    final close = _minutes(_ground.closeTime);
    final step = _ground.slotDurationMinutes;
    if (open == null || close == null || step <= 0 || close <= open) {
      return const [];
    }
    final keys = <String>[];
    for (var start = open; start + step <= close; start += step) {
      keys.add('${_hhmm(start)}-${_hhmm(start + step)}');
    }
    return keys;
  }

  static int? _minutes(String hhmm) {
    final parts = hhmm.split(':');
    if (parts.length != 2) return null;
    final h = int.tryParse(parts[0]);
    final m = int.tryParse(parts[1]);
    if (h == null || m == null) return null;
    return h * 60 + m;
  }

  static String _hhmm(int totalMinutes) {
    final h = (totalMinutes ~/ 60) % 24;
    final m = totalMinutes % 60;
    return '${h.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')}';
  }

  /// True when the slot's start already passed (only matters for "today").
  bool _isPast(String key) {
    final now = DateTime.now();
    final isToday = _selectedDate.year == now.year &&
        _selectedDate.month == now.month &&
        _selectedDate.day == now.day;
    if (!isToday) return false;
    final start = _minutes(key.split('-').first);
    if (start == null) return false;
    return start <= now.hour * 60 + now.minute;
  }

  bool _isFree(String key, GroundSlotDay? day) {
    if (_isPast(key)) return false;
    if (day == null) return true; // no doc yet -> server generates on demand
    if (day.blocked) return false;
    final entry = day.slots[key];
    if (entry == null) return true;
    if (entry.status == 'booked' || entry.status == 'blocked') return false;
    if (entry.status == 'held') {
      final until = entry.heldUntil;
      // A stale hold (expired) is effectively free again.
      return until == null || until.isBefore(DateTime.now());
    }
    return true;
  }

  // ---------------------------------------------------------------------------
  // Pricing
  // ---------------------------------------------------------------------------

  int get _hourlyRate => _ground.hourlyRateFor(_selectedDate);

  /// Amount for the picked run of slots, in paise.
  int get _amountPaise {
    final hours = (_pickedSlots.length * _ground.slotDurationMinutes) / 60.0;
    return (_hourlyRate * hours * 100).round();
  }

  int get _platformFeePaise =>
      (_amountPaise * AppConstants.platformFeePct).round();

  // ---------------------------------------------------------------------------
  // Selection
  // ---------------------------------------------------------------------------

  void _toggleSlot(String key) {
    setState(() {
      if (!_pickedSlots.remove(key)) _pickedSlots.add(key);
    });
  }

  void _goToCheckout() {
    if (_pickedSlots.isEmpty) return;
    final keys = _allSlotKeys().where(_pickedSlots.contains).toList();
    final first = keys.first.split('-');
    final last = keys.last.split('-');

    Navigator.pushNamed(
      context,
      BookingCheckoutScreen.route,
      arguments: CheckoutArgs(
        ground: _ground,
        dateIso: _dateIso,
        slotStart: first.first,
        slotEnd: last.last,
        amountPaise: _amountPaise,
        platformFeePaise: _platformFeePaise,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final dates = List.generate(
      _daysAhead,
      (i) {
        final today = DateTime.now();
        return DateTime(today.year, today.month, today.day)
            .add(Duration(days: i));
      },
    );

    return Scaffold(
      appBar: AppBar(title: Text(_ground.name)),
      body: Column(
        children: [
          _DateStrip(
            dates: dates,
            selected: _selectedDate,
            onPick: (d) => setState(() {
              _selectedDate = d;
              _pickedSlots.clear();
            }),
          ),
          const Divider(height: 1),
          Expanded(
            child: StreamBuilder<GroundSlotDay>(
              stream: _grounds.daySlotsStream(_ground.id, _dateIso),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                final day = snapshot.data;
                final keys = _allSlotKeys();

                if (day?.blocked ?? false) {
                  return _EmptyState(
                    icon: Icons.block_rounded,
                    title: 'Closed on this date',
                    message: (day?.blockReason?.isNotEmpty ?? false)
                        ? day!.blockReason!
                        : 'The ground owner has blocked this date.',
                  );
                }
                if (keys.isEmpty) {
                  return const _EmptyState(
                    icon: Icons.schedule_rounded,
                    title: 'No slots configured',
                    message:
                        'This ground has no opening hours set up yet.',
                  );
                }

                return ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                  itemCount: keys.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (context, i) {
                    final key = keys[i];
                    final free = _isFree(key, day);
                    final picked = _pickedSlots.contains(key);
                    return _SlotTile(
                      slotKey: key,
                      free: free,
                      picked: picked,
                      rate: _hourlyRate,
                      onTap: free ? () => _toggleSlot(key) : null,
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
      bottomNavigationBar: _CheckoutBar(
        pickedCount: _pickedSlots.length,
        amountPaise: _amountPaise,
        onContinue: _pickedSlots.isEmpty ? null : _goToCheckout,
      ),
    );
  }
}

// -----------------------------------------------------------------------------
// Pieces
// -----------------------------------------------------------------------------

class _DateStrip extends StatelessWidget {
  const _DateStrip({
    required this.dates,
    required this.selected,
    required this.onPick,
  });

  final List<DateTime> dates;
  final DateTime selected;
  final ValueChanged<DateTime> onPick;

  static const _weekdays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

  bool _sameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 92,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        itemCount: dates.length,
        itemBuilder: (context, i) {
          final d = dates[i];
          final isSelected = _sameDay(d, selected);
          return GestureDetector(
            onTap: () => onPick(d),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              width: 60,
              margin: const EdgeInsets.symmetric(horizontal: 4),
              decoration: BoxDecoration(
                color: isSelected ? AppTheme.primary : AppTheme.surface,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: isSelected ? AppTheme.primary : AppTheme.border,
                ),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    _weekdays[d.weekday - 1],
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: isSelected
                          ? Colors.white70
                          : AppTheme.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${d.day}',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      color: isSelected ? Colors.white : AppTheme.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${d.month}/${d.year % 100}',
                    style: TextStyle(
                      fontSize: 9,
                      color: isSelected
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
    );
  }
}

class _SlotTile extends StatelessWidget {
  const _SlotTile({
    required this.slotKey,
    required this.free,
    required this.picked,
    required this.rate,
    this.onTap,
  });

  final String slotKey;
  final bool free;
  final bool picked;
  final int rate;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final parts = slotKey.split('-');
    final label = parts.length == 2 ? '${parts[0]} – ${parts[1]}' : slotKey;

    return Opacity(
      opacity: free ? 1 : 0.45,
      child: Card(
        color: picked ? AppTheme.primaryContainer : AppTheme.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(
            color: picked ? AppTheme.primary : AppTheme.border,
            width: picked ? 1.6 : 1,
          ),
        ),
        child: ListTile(
          onTap: onTap,
          leading: Icon(
            !free
                ? Icons.lock_rounded
                : picked
                    ? Icons.check_circle_rounded
                    : Icons.circle_outlined,
            color: !free
                ? AppTheme.textSecondary
                : picked
                    ? AppTheme.primary
                    : AppTheme.textSecondary,
          ),
          title: Text(
            label,
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),
          subtitle: Text(
            free ? '₹$rate / hour' : 'Already booked',
            style: const TextStyle(fontSize: 12),
          ),
          trailing: free && !picked
              ? const Icon(Icons.add_rounded, color: AppTheme.textSecondary)
              : null,
        ),
      ),
    );
  }
}

class _CheckoutBar extends StatelessWidget {
  const _CheckoutBar({
    required this.pickedCount,
    required this.amountPaise,
    this.onContinue,
  });

  final int pickedCount;
  final int amountPaise;
  final VoidCallback? onContinue;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Container(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
        decoration: const BoxDecoration(
          color: AppTheme.surface,
          border: Border(top: BorderSide(color: AppTheme.border)),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    pickedCount == 0
                        ? 'No slot selected'
                        : '$pickedCount slot${pickedCount == 1 ? '' : 's'}',
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '₹${(amountPaise / 100).round()}',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(
              width: 160,
              child: ElevatedButton(
                onPressed: onContinue,
                child: const Text('Continue'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({
    required this.icon,
    required this.title,
    required this.message,
  });

  final IconData icon;
  final String title;
  final String message;

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
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppTheme.textSecondary),
            ),
          ],
        ),
      ),
    );
  }
}
