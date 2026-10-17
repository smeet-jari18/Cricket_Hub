import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/app_theme.dart';
import '../../models/ground_model.dart';
import '../../services/ground_service.dart';

/// Sprint 9's `owner_calendar_screen.dart` — the owner's view of a ground's
/// availability, with the "block unavailable dates" half of FR-BOOK-01.
///
/// `GroundService.blockDay` / `unblockDay` and the `grounds/{id}/blocked_rules`
/// rules already existed; nothing in the app could reach them, so an owner had
/// no way to close a date.
class OwnerCalendarScreen extends StatelessWidget {
  const OwnerCalendarScreen({super.key});

  static const String route = '/owner-calendar';

  @override
  Widget build(BuildContext context) {
    final arg = ModalRoute.of(context)?.settings.arguments;
    if (arg is! Ground) {
      return Scaffold(
        appBar: AppBar(title: const Text('Availability')),
        body: const Center(child: Text('No ground selected.')),
      );
    }
    return _Body(ground: arg);
  }
}

class _Body extends StatefulWidget {
  const _Body({required this.ground});

  final Ground ground;

  @override
  State<_Body> createState() => _BodyState();
}

class _BodyState extends State<_Body> {
  static const int _daysAhead = 21;

  late final GroundService _grounds;
  final Map<String, bool> _pending = {};

  @override
  void initState() {
    super.initState();
    _grounds = context.read<GroundService>();
  }

  Ground get _ground => widget.ground;

  static String _iso(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-'
      '${d.month.toString().padLeft(2, '0')}-'
      '${d.day.toString().padLeft(2, '0')}';

  Future<void> _toggle(String dateIso, bool blocked) async {
    setState(() => _pending[dateIso] = true);

    String? reason;
    if (!blocked) {
      reason = await _askReason();
      if (reason == null) {
        if (mounted) setState(() => _pending.remove(dateIso));
        return; // user backed out
      }
    }

    try {
      if (blocked) {
        await _grounds.unblockDay(_ground.id, dateIso);
      } else {
        await _grounds.blockDay(_ground.id, dateIso, reason: reason);
      }
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(blocked ? 'Date re-opened.' : 'Date blocked.'),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not update: $e')),
      );
    } finally {
      if (mounted) setState(() => _pending.remove(dateIso));
    }
  }

  Future<String?> _askReason() {
    final controller = TextEditingController();
    return showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Block this date?'),
        content: TextField(
          controller: controller,
          maxLength: 80,
          decoration: const InputDecoration(
            labelText: 'Reason (optional)',
            hintText: 'Maintenance, private tournament…',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(
              ctx,
              controller.text.trim().isEmpty
                  ? 'Blocked by owner'
                  : controller.text.trim(),
            ),
            child: const Text('Block date'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final today = DateTime.now();
    final start = DateTime(today.year, today.month, today.day);
    final dates =
        List.generate(_daysAhead, (i) => start.add(Duration(days: i)));

    return Scaffold(
      appBar: AppBar(title: Text('${_ground.name} · availability')),
      body: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: dates.length,
        separatorBuilder: (_, __) => const SizedBox(height: 8),
        itemBuilder: (context, i) {
          final date = dates[i];
          final iso = _iso(date);
          return StreamBuilder<GroundSlotDay>(
            stream: _grounds.daySlotsStream(_ground.id, iso),
            builder: (context, snapshot) {
              final day = snapshot.data;
              final blocked = day?.blocked ?? false;
              final busy = _pending[iso] ?? false;
              final booked = day == null
                  ? 0
                  : day.slots.values
                      .where((s) => s.status == 'booked')
                      .length;

              return Card(
                child: ListTile(
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                  leading: Container(
                    width: 46,
                    height: 46,
                    decoration: BoxDecoration(
                      color: blocked
                          ? AppTheme.danger.withValues(alpha: 0.10)
                          : AppTheme.primaryContainer,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Center(
                      child: Text(
                        '${date.day}',
                        style: TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 16,
                          color: blocked
                              ? AppTheme.danger
                              : AppTheme.primary,
                        ),
                      ),
                    ),
                  ),
                  title: Text(
                    _label(date, i),
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                  subtitle: Text(
                    blocked
                        ? (day?.blockReason?.isNotEmpty ?? false)
                            ? day!.blockReason!
                            : 'Blocked'
                        : booked == 0
                            ? 'Open · no bookings yet'
                            : 'Open · $booked booked',
                    style: const TextStyle(fontSize: 12),
                  ),
                  trailing: busy
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Switch(
                          value: !blocked,
                          onChanged: (_) => _toggle(iso, blocked),
                        ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  static String _label(DateTime d, int index) {
    if (index == 0) return 'Today';
    if (index == 1) return 'Tomorrow';
    const names = [
      'Monday',
      'Tuesday',
      'Wednesday',
      'Thursday',
      'Friday',
      'Saturday',
      'Sunday',
    ];
    return names[d.weekday - 1];
  }
}
