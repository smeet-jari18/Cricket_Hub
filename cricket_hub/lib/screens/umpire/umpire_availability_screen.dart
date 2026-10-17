import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/app_constants.dart';
import '../../core/app_theme.dart';
import '../../models/ground_model.dart';
import '../../models/umpire_model.dart';
import '../../services/umpire_service.dart';

/// Sprint 10's `umpire_availability_screen.dart`.
///
/// Toggles `umpires/{uid}/availability/{dateIso}`. The document shape is the
/// same `GroundSlotDay` used by ground slots (see
/// `umpire_service.availabilityStream`), so a day is simply open or blocked.
class UmpireAvailabilityScreen extends StatelessWidget {
  const UmpireAvailabilityScreen({super.key});

  static const String route = '/umpire-availability';

  @override
  Widget build(BuildContext context) {
    final arg = ModalRoute.of(context)?.settings.arguments;
    if (arg is! Umpire) {
      return Scaffold(
        appBar: AppBar(title: const Text('Availability')),
        body: const Center(child: Text('No umpire selected.')),
      );
    }
    return _Body(umpire: arg);
  }
}

class _Body extends StatefulWidget {
  const _Body({required this.umpire});

  final Umpire umpire;

  @override
  State<_Body> createState() => _BodyState();
}

class _BodyState extends State<_Body> {
  static const int _daysAhead = 21;

  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final Set<String> _pending = {};

  CollectionReference<Map<String, dynamic>> get _col => _db
      .collection(AppConstants.umpiresCol)
      .doc(widget.umpire.uid)
      .collection(AppConstants.umpireAvailabilitySubCol);

  static String _iso(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-'
      '${d.month.toString().padLeft(2, '0')}-'
      '${d.day.toString().padLeft(2, '0')}';

  Future<void> _setBlocked(String iso, bool blocked) async {
    setState(() => _pending.add(iso));
    try {
      await _col.doc(iso).set({
        'date': iso,
        'blocked': blocked,
        'slots': const <String, dynamic>{},
        'updated_at': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not update: $e')),
      );
    } finally {
      if (mounted) setState(() => _pending.remove(iso));
    }
  }

  @override
  Widget build(BuildContext context) {
    final today = DateTime.now();
    final start = DateTime(today.year, today.month, today.day);
    final dates =
        List.generate(_daysAhead, (i) => start.add(Duration(days: i)));

    return Scaffold(
      appBar: AppBar(title: const Text('My availability')),
      body: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: dates.length,
        separatorBuilder: (_, __) => const SizedBox(height: 8),
        itemBuilder: (context, i) {
          final date = dates[i];
          final iso = _iso(date);
          return StreamBuilder<GroundSlotDay>(
            stream: context
                .read<UmpireService>()
                .availabilityStream(widget.umpire.uid, iso),
            builder: (context, snapshot) {
              final blocked = snapshot.data?.blocked ?? false;
              final busy = _pending.contains(iso);
              return Card(
                child: ListTile(
                  title: Text(
                    _label(date, i),
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                  subtitle: Text(
                    blocked ? 'Unavailable' : 'Available',
                    style: TextStyle(
                      fontSize: 12,
                      color: blocked ? AppTheme.danger : AppTheme.textSecondary,
                    ),
                  ),
                  trailing: busy
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Switch(
                          value: !blocked,
                          onChanged: (on) => _setBlocked(iso, !on),
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
    return '${names[d.weekday - 1]} · ${d.day}/${d.month}';
  }
}
