import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/app_theme.dart';
import '../../models/umpire_model.dart';
import '../../services/umpire_service.dart';

/// Edits the fields an umpire is allowed to change on their own document.
///
/// `firestore.rules` (match /umpires/{uid}, owner update) permits exactly:
/// display_name, phone_number, city, experience_years, certifications,
/// day_rate, hourly_rate, bio, photo_url, status, updated_at — and requires
/// verified / avg_rating / review_count / matches_officiated to stay as they
/// are. This screen only sends the fields below, which is a strict subset.
class UmpireEditScreen extends StatelessWidget {
  const UmpireEditScreen({super.key});

  static const String route = '/umpire-edit';

  @override
  Widget build(BuildContext context) {
    final arg = ModalRoute.of(context)?.settings.arguments;
    if (arg is! Umpire) {
      return Scaffold(
        appBar: AppBar(title: const Text('Edit profile')),
        body: const Center(child: Text('No umpire profile loaded.')),
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
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _name =
      TextEditingController(text: widget.umpire.displayName);
  late final TextEditingController _bio =
      TextEditingController(text: widget.umpire.bio);
  late final TextEditingController _experience =
      TextEditingController(text: '${widget.umpire.experienceYears}');
  late final TextEditingController _hourly =
      TextEditingController(text: '${widget.umpire.hourlyRate}');
  late final TextEditingController _day =
      TextEditingController(text: '${widget.umpire.dayRate}');

  bool _busy = false;

  @override
  void dispose() {
    _name.dispose();
    _bio.dispose();
    _experience.dispose();
    _hourly.dispose();
    _day.dispose();
    super.dispose();
  }

  // Pure validation lives as top-level functions at the bottom of this
  // file, so it can be unit-tested without a widget or Firestore.

  Future<void> _save() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    setState(() => _busy = true);
    final messenger = ScaffoldMessenger.of(context);
    try {
      await context.read<UmpireService>().updateUmpire(
        widget.umpire.uid,
        {
          'display_name': _name.text.trim(),
          'bio': _bio.text.trim(),
          'experience_years': int.parse(_experience.text.trim()),
          'hourly_rate': int.parse(_hourly.text.trim()),
          'day_rate': int.parse(_day.text.trim()),
        },
      );
      if (!mounted) return;
      Navigator.pop(context);
      messenger.showSnackBar(
        const SnackBar(content: Text('Profile updated.')),
      );
    } catch (e) {
      if (!mounted) return;
      messenger.showSnackBar(
        SnackBar(content: Text('Could not save: $e')),
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Edit profile')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            TextFormField(
              controller: _name,
              textCapitalization: TextCapitalization.words,
              decoration: const InputDecoration(labelText: 'Display name'),
              validator: validateUmpireName,
            ),
            const SizedBox(height: 14),
            TextFormField(
              controller: _bio,
              maxLines: 4,
              maxLength: 500,
              decoration: const InputDecoration(
                labelText: 'Bio',
                alignLabelWithHint: true,
              ),
            ),
            const SizedBox(height: 4),
            TextFormField(
              controller: _experience,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Experience (years)',
              ),
              validator: validateUmpireExperience,
            ),
            const SizedBox(height: 14),
            TextFormField(
              controller: _hourly,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Hourly rate (₹)',
                prefixText: '₹ ',
              ),
              validator: validateUmpireHourly,
            ),
            const SizedBox(height: 14),
            TextFormField(
              controller: _day,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Day rate (₹)',
                prefixText: '₹ ',
                helperText: '0 = full-day booking not offered',
              ),
              validator: validateUmpireDay,
            ),
            const SizedBox(height: 12),
            const Text(
              'Verified status, ratings and match counts are managed by '
              'CricketHub — they are not editable here.',
              style: TextStyle(fontSize: 11, color: AppTheme.textSecondary),
            ),
          ],
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: ElevatedButton(
            onPressed: _busy ? null : _save,
            child: Text(_busy ? 'Saving…' : 'Save changes'),
          ),
        ),
      ),
    );
  }
}


// -----------------------------------------------------------------------------
// Pure validators (tested in test/edit_forms_validation_test.dart)
// -----------------------------------------------------------------------------

/// Display name: required, up to 60 characters.
String? validateUmpireName(String? value) {
  if (value == null || value.trim().isEmpty) return 'Name is required.';
  if (value.trim().length > 60) return 'Keep it under 60 characters.';
  return null;
}

/// Experience: whole years, 0–60.
String? validateUmpireExperience(String? value) {
  final n = int.tryParse((value ?? '').trim());
  if (n == null) return 'Enter a whole number.';
  if (n < 0 || n > 60) return 'Between 0 and 60 years.';
  return null;
}

/// Hourly rate: whole rupees, strictly positive.
String? validateUmpireHourly(String? value) {
  final n = int.tryParse((value ?? '').trim());
  if (n == null) return 'Enter a whole number.';
  if (n <= 0) return 'Hourly rate must be more than 0.';
  if (n > 100000) return 'That looks too high.';
  return null;
}

/// Day rate: whole rupees, 0 allowed (full-day bookings not offered).
String? validateUmpireDay(String? value) {
  final n = int.tryParse((value ?? '').trim());
  if (n == null) return 'Enter a whole number.';
  if (n < 0) return 'Cannot be negative.';
  if (n > 500000) return 'That looks too high.';
  return null;
}
