import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/app_constants.dart';
import '../../core/app_theme.dart';
import '../../models/umpire_model.dart';
import '../../providers/auth_provider.dart';
import '../../services/umpire_service.dart';

/// Sprint 10's `umpire_onboarding_screen.dart`.
///
/// `UmpireService.registerUmpire` and `submitForVerification` existed but were
/// unreachable, so nobody could actually become an umpire in the app.
class UmpireOnboardingScreen extends StatefulWidget {
  const UmpireOnboardingScreen({super.key});

  static const String route = '/umpire-onboarding';

  @override
  State<UmpireOnboardingScreen> createState() => _UmpireOnboardingScreenState();
}

class _UmpireOnboardingScreenState extends State<UmpireOnboardingScreen> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _phone = TextEditingController();
  final _experience = TextEditingController(text: '1');
  final _hourly = TextEditingController(text: '500');
  final _day = TextEditingController(text: '3000');
  final _bio = TextEditingController();

  String _city = AppConstants.supportedCities.first;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    final user = context.read<AuthProvider>().appUser;
    if (user != null) {
      _name.text = user.displayName;
      _phone.text = user.phoneNumber;
    }
  }

  @override
  void dispose() {
    _name.dispose();
    _phone.dispose();
    _experience.dispose();
    _hourly.dispose();
    _day.dispose();
    _bio.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final user = context.read<AuthProvider>().appUser;
    if (user == null) return;

    setState(() => _busy = true);
    final service = context.read<UmpireService>();
    try {
      await service.registerUmpire(
        Umpire(
          uid: user.uid,
          displayName: _name.text.trim(),
          phoneNumber: _phone.text.trim(),
          city: _city,
          experienceYears: int.tryParse(_experience.text.trim()) ?? 0,
          certifications: const [],
          dayRate: int.tryParse(_day.text.trim()) ?? 0,
          hourlyRate: int.tryParse(_hourly.text.trim()) ?? 0,
          bio: _bio.text.trim(),
          photoUrl: '',
          verified: false,
          avgRating: 0,
          reviewCount: 0,
          matchesOfficiated: 0,
          status: 'draft',
        ),
      );
      await service.submitForVerification(user.uid);
      if (!mounted) return;
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Profile submitted — an admin will verify it.'),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not save: $e')),
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Become an umpire')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            const Text(
              'List yourself so organizers can book you for matches.',
              style: TextStyle(color: AppTheme.textSecondary),
            ),
            const SizedBox(height: 20),
            TextFormField(
              controller: _name,
              textCapitalization: TextCapitalization.words,
              decoration: const InputDecoration(labelText: 'Full name'),
              validator: (v) =>
                  (v == null || v.trim().length < 3) ? 'Enter your name' : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _phone,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(labelText: 'Phone number'),
              validator: (v) =>
                  (v == null || v.trim().length < 10) ? 'Enter a phone' : null,
            ),
            const SizedBox(height: 12),
            InputDecorator(
              decoration: const InputDecoration(labelText: 'City'),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  isExpanded: true,
                  value: _city,
                  items: [
                    for (final c in AppConstants.supportedCities)
                      DropdownMenuItem(value: c, child: Text(c)),
                  ],
                  onChanged: (v) => setState(() => _city = v ?? _city),
                ),
              ),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _experience,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Years of experience',
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _hourly,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Hourly ₹',
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: TextFormField(
                    controller: _day,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: 'Day ₹'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _bio,
              maxLines: 4,
              maxLength: 300,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(
                labelText: 'About you',
                alignLabelWithHint: true,
                hintText: 'Leagues officiated, playing background…',
              ),
            ),
            const SizedBox(height: 8),
            ElevatedButton(
              onPressed: _busy ? null : _submit,
              child: Text(_busy ? 'Submitting…' : 'Submit for verification'),
            ),
          ],
        ),
      ),
    );
  }
}
