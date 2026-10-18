import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/app_constants.dart';
import '../../core/app_theme.dart';
import '../../models/umpire_model.dart';
import '../../providers/auth_provider.dart';
import '../../services/photo_picker.dart';
import '../../services/storage_service.dart';
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

  final PhotoPicker _picker = PhotoPicker();
  PickedPhoto? _photo;

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

  Future<void> _pickPhoto() async {
    try {
      final picked = await _picker.pickFromGallery();
      if (picked == null) return;
      final problem = PhotoRules.validate(
        sizeBytes: picked.bytes.length,
        contentType: picked.contentType,
      );
      if (problem != null) {
        if (!mounted) return;
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(problem)));
        return;
      }
      setState(() => _photo = picked);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Could not open the gallery: $e')));
    }
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final user = context.read<AuthProvider>().appUser;
    if (user == null) return;

    setState(() => _busy = true);
    final service = context.read<UmpireService>();
    final storage = context.read<StorageService>();
    try {
      // Upload first: the Storage path is umpires/{uid}/..., which does not
      // need the Firestore document to exist yet.
      String photoUrl = '';
      var photoFailed = false;
      // The photo is optional: if Storage rejects it (size, type, offline) the
      // umpire should still be able to register and add a photo later, so the
      // failure is swallowed and reported, never fatal.
      if (_photo != null) {
        try {
          final uploaded = await storage.uploadBytes(
            target: PhotoTarget.umpire,
            ownerId: user.uid,
            bytes: _photo!.bytes,
            contentType: _photo!.contentType,
            fileName: 'profile_${DateTime.now().millisecondsSinceEpoch}'
                '${PhotoRules.extensionFor(_photo!.contentType)}',
          );
          photoUrl = uploaded.downloadUrl;
        } on Exception {
          photoFailed = true;
        }
      }

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
          photoUrl: photoUrl,
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
        SnackBar(
          content: Text(photoFailed
              ? 'Profile submitted, but the photo could not be uploaded.'
              : 'Profile submitted — an admin will verify it.'),
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
            const Text(
              'Profile photo',
              style: TextStyle(fontSize: 13, color: AppTheme.textSecondary),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                ClipOval(
                  child: SizedBox(
                    width: 64,
                    height: 64,
                    child: _photo == null
                        ? Container(
                            color: AppTheme.primaryContainer,
                            child: const Icon(Icons.person_rounded,
                                color: AppTheme.primary),
                          )
                        : Image.memory(_photo!.bytes, fit: BoxFit.cover),
                  ),
                ),
                const SizedBox(width: 12),
                OutlinedButton.icon(
                  onPressed: _busy ? null : _pickPhoto,
                  icon: const Icon(Icons.add_a_photo_outlined, size: 18),
                  label: Text(_photo == null ? 'Add photo' : 'Change photo'),
                ),
              ],
            ),
            const SizedBox(height: 16),
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
