import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/app_constants.dart';
import '../../core/app_theme.dart';
import '../../models/ground_model.dart';
import '../../providers/auth_provider.dart';
import '../../services/ground_service.dart';

/// Sprint 9's `owner_create_ground_screen.dart` — the 4-step wizard described
/// in `CricketHub_Implementation_Plan_Phase3.md` ("Ground owner onboarding
/// drop-off" risk -> "4-step wizard with autosave").
///
/// Step 1 Basics · Step 2 Pricing & hours · Step 3 Pitch & amenities ·
/// Step 4 Review & submit.
///
/// On submit it calls the previously-unreachable `GroundService.createGround`
/// and then `submitForVerification`, so the listing lands in
/// `pending_verification` for an admin to approve.
class OwnerCreateGroundScreen extends StatefulWidget {
  const OwnerCreateGroundScreen({super.key});

  static const String route = '/owner-create-ground';

  @override
  State<OwnerCreateGroundScreen> createState() =>
      _OwnerCreateGroundScreenState();
}

class _OwnerCreateGroundScreenState extends State<OwnerCreateGroundScreen> {
  static const int _steps = 4;

  final _formKey = GlobalKey<FormState>();

  int _step = 0;
  bool _busy = false;

  // Step 1
  final _name = TextEditingController();
  final _city = TextEditingController(text: 'Ahmedabad');
  final _address = TextEditingController();

  // Step 2
  final _weekday = TextEditingController(text: '1200');
  final _weekend = TextEditingController(text: '1500');
  final _fullDay = TextEditingController(text: '0');
  TimeOfDay _open = const TimeOfDay(hour: 6, minute: 0);
  TimeOfDay _close = const TimeOfDay(hour: 22, minute: 0);
  int _slotMinutes = 120;

  // Step 3
  String _pitchType = 'turf';
  final Set<String> _amenities = {'floodlights'};

  @override
  void dispose() {
    _name.dispose();
    _city.dispose();
    _address.dispose();
    _weekday.dispose();
    _weekend.dispose();
    _fullDay.dispose();
    super.dispose();
  }

  // ---------------------------------------------------------------------------

  static String _hhmm(TimeOfDay t) =>
      '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';

  bool get _hoursValid {
    final open = _open.hour * 60 + _open.minute;
    final close = _close.hour * 60 + _close.minute;
    return close > open && (close - open) >= _slotMinutes;
  }

  bool _validateStep() {
    if (_step == 0) {
      return _formKey.currentState?.validate() ?? false;
    }
    if (_step == 1) {
      if (!_hoursValid) {
        _snack('Closing time must be after opening, with room for one slot.');
        return false;
      }
      for (final c in [_weekday, _weekend]) {
        if ((int.tryParse(c.text.trim()) ?? 0) <= 0) {
          _snack('Hourly rates must be greater than zero.');
          return false;
        }
      }
    }
    return true;
  }

  void _snack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  Future<void> _submit() async {
    final user = context.read<AuthProvider>().appUser;
    if (user == null) return;

    setState(() => _busy = true);
    final service = context.read<GroundService>();
    try {
      final ground = Ground(
        id: '', // assigned by Firestore
        name: _name.text.trim(),
        ownerUid: user.uid,
        city: _city.text.trim(),
        address: _address.text.trim(),
        lat: 0,
        lng: 0,
        pitchType: _pitchType,
        amenities: _amenities.toList(),
        photos: const [],
        coverPhotoUrl: '',
        priceWeekdayHourly: int.tryParse(_weekday.text.trim()) ?? 0,
        priceWeekendHourly: int.tryParse(_weekend.text.trim()) ?? 0,
        priceFullDay: int.tryParse(_fullDay.text.trim()) ?? 0,
        openTime: _hhmm(_open),
        closeTime: _hhmm(_close),
        slotDurationMinutes: _slotMinutes,
        status: 'draft',
        verified: false,
        avgRating: 0,
        reviewCount: 0,
        bookingCount: 0,
        groundStats: const {},
      );

      final id = await service.createGround(ground);
      await service.submitForVerification(id);

      if (!mounted) return;
      Navigator.pop(context);
      _snack('Ground submitted — an admin will verify it shortly.');
    } catch (e) {
      if (!mounted) return;
      _snack('Could not save: $e');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  // ---------------------------------------------------------------------------
  // Build
  // ---------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('List your ground')),
      body: Column(
        children: [
          _StepBar(step: _step, steps: _steps),
          Expanded(
            child: Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.all(20),
                children: [_buildStep()],
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Container(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
          decoration: const BoxDecoration(
            color: AppTheme.surface,
            border: Border(top: BorderSide(color: AppTheme.border)),
          ),
          child: Row(
            children: [
              if (_step > 0)
                Expanded(
                  child: OutlinedButton(
                    onPressed: _busy
                        ? null
                        : () => setState(() => _step -= 1),
                    child: const Text('Back'),
                  ),
                ),
              if (_step > 0) const SizedBox(width: 10),
              Expanded(
                flex: 2,
                child: ElevatedButton(
                  onPressed: _busy
                      ? null
                      : () {
                          if (!_validateStep()) return;
                          if (_step == _steps - 1) {
                            _submit();
                          } else {
                            setState(() => _step += 1);
                          }
                        },
                  child: Text(
                    _busy
                        ? 'Saving…'
                        : _step == _steps - 1
                            ? 'Submit for verification'
                            : 'Next',
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStep() {
    switch (_step) {
      case 0:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const _StepTitle('Basics'),
            TextFormField(
              controller: _name,
              textCapitalization: TextCapitalization.words,
              decoration: const InputDecoration(labelText: 'Ground name'),
              validator: (v) => (v == null || v.trim().length < 3)
                  ? 'Enter at least 3 characters'
                  : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _city,
              decoration: const InputDecoration(labelText: 'City'),
              validator: (v) => (v == null || v.trim().isEmpty)
                  ? 'City is required'
                  : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _address,
              maxLines: 2,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(
                labelText: 'Address',
                alignLabelWithHint: true,
              ),
              validator: (v) => (v == null || v.trim().length < 8)
                  ? 'Enter the full address'
                  : null,
            ),
          ],
        );

      case 1:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const _StepTitle('Pricing & hours'),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _weekday,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Weekday ₹/hr',
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: TextFormField(
                    controller: _weekend,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Weekend ₹/hr',
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _fullDay,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Full-day rate ₹ (0 = not offered)',
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: _TimeField(
                    label: 'Opens',
                    value: _open,
                    onPick: (t) => setState(() => _open = t),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _TimeField(
                    label: 'Closes',
                    value: _close,
                    onPick: (t) => setState(() => _close = t),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            const Text(
              'Slot length',
              style: TextStyle(fontSize: 13, color: AppTheme.textSecondary),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: [
                for (final m in AppConstants.slotDurationPresets)
                  ChoiceChip(
                    label: Text('$m min'),
                    selected: _slotMinutes == m,
                    onSelected: (_) => setState(() => _slotMinutes = m),
                  ),
              ],
            ),
          ],
        );

      case 2:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const _StepTitle('Pitch & amenities'),
            const Text(
              'Pitch type',
              style: TextStyle(fontSize: 13, color: AppTheme.textSecondary),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: [
                for (final p in AppConstants.pitchTypes)
                  ChoiceChip(
                    label: Text(p[0].toUpperCase() + p.substring(1)),
                    selected: _pitchType == p,
                    onSelected: (_) => setState(() => _pitchType = p),
                  ),
              ],
            ),
            const SizedBox(height: 22),
            const Text(
              'Amenities',
              style: TextStyle(fontSize: 13, color: AppTheme.textSecondary),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 4,
              children: [
                for (final a in AppConstants.standardAmenities)
                  FilterChip(
                    label: Text(a.replaceAll('_', ' ')),
                    selected: _amenities.contains(a),
                    onSelected: (on) => setState(() {
                      if (on) {
                        _amenities.add(a);
                      } else {
                        _amenities.remove(a);
                      }
                    }),
                  ),
              ],
            ),
            const SizedBox(height: 24),
            const Card(
              child: Padding(
                padding: EdgeInsets.all(14),
                child: Row(
                  children: [
                    Icon(Icons.info_outline_rounded,
                        size: 18, color: AppTheme.textSecondary),
                    SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Photos can be added after the ground is verified.',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppTheme.textSecondary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        );

      default:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const _StepTitle('Review & submit'),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    _ReviewRow('Name', _name.text.trim()),
                    _ReviewRow('City', _city.text.trim()),
                    _ReviewRow('Address', _address.text.trim()),
                    _ReviewRow('Weekday', '₹${_weekday.text.trim()} / hr'),
                    _ReviewRow('Weekend', '₹${_weekend.text.trim()} / hr'),
                    _ReviewRow('Hours', '${_hhmm(_open)} – ${_hhmm(_close)}'),
                    _ReviewRow('Slot length', '$_slotMinutes min'),
                    _ReviewRow('Pitch', _pitchType),
                    _ReviewRow(
                      'Amenities',
                      _amenities.isEmpty ? 'None' : _amenities.join(', '),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Your ground goes to an admin for verification. You can take '
              'bookings once it is approved.',
              style: TextStyle(fontSize: 12, color: AppTheme.textSecondary),
            ),
          ],
        );
    }
  }
}

// -----------------------------------------------------------------------------

class _StepBar extends StatelessWidget {
  const _StepBar({required this.step, required this.steps});

  final int step;
  final int steps;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 12),
      child: Row(
        children: [
          for (var i = 0; i < steps; i++) ...[
            Expanded(
              child: Container(
                height: 4,
                decoration: BoxDecoration(
                  color: i <= step ? AppTheme.primary : AppTheme.border,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            if (i != steps - 1) const SizedBox(width: 6),
          ],
        ],
      ),
    );
  }
}

class _StepTitle extends StatelessWidget {
  const _StepTitle(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 18),
      child: Text(text, style: Theme.of(context).textTheme.titleLarge),
    );
  }
}

class _TimeField extends StatelessWidget {
  const _TimeField({
    required this.label,
    required this.value,
    required this.onPick,
  });

  final String label;
  final TimeOfDay value;
  final ValueChanged<TimeOfDay> onPick;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () async {
        final picked = await showTimePicker(context: context, initialTime: value);
        if (picked != null) onPick(picked);
      },
      child: InputDecorator(
        decoration: InputDecoration(labelText: label),
        child: Text(
          '${value.hour.toString().padLeft(2, '0')}:'
          '${value.minute.toString().padLeft(2, '0')}',
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
      ),
    );
  }
}

class _ReviewRow extends StatelessWidget {
  const _ReviewRow(this.label, this.value);

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 110,
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
              value.isEmpty ? '—' : value,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
