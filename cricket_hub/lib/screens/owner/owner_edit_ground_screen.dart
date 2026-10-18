import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/app_theme.dart';
import '../../models/ground_model.dart';
import '../../services/ground_service.dart';
import '../../services/photo_picker.dart';
import '../../services/storage_service.dart';

/// Edits the fields a ground owner may change after listing.
///
/// `firestore.rules` (match /grounds/{groundId}, owner update) allows exactly:
/// name, city, address, lat, lng, pitch_type, amenities, photos,
/// cover_photo_url, price_weekday_hourly, price_weekend_hourly,
/// price_full_day, open_time, close_time, slot_duration_minutes, status,
/// updated_at — and requires verified / avg_rating / review_count /
/// booking_count to stay untouched.
///
/// This screen sends only name, address, the three prices and the two times —
/// all inside that allow-list, so `updateGround` can never be rejected for
/// touching a forbidden key.
class OwnerEditGroundScreen extends StatefulWidget {
  const OwnerEditGroundScreen({super.key, required this.ground});

  static const String route = '/owner-edit-ground';

  final Ground ground;

  @override
  State<OwnerEditGroundScreen> createState() => _OwnerEditGroundScreenState();
}

class _OwnerEditGroundScreenState extends State<OwnerEditGroundScreen> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _name =
      TextEditingController(text: widget.ground.name);
  late final TextEditingController _address =
      TextEditingController(text: widget.ground.address);
  late final TextEditingController _weekday =
      TextEditingController(text: '${widget.ground.priceWeekdayHourly}');
  late final TextEditingController _weekend =
      TextEditingController(text: '${widget.ground.priceWeekendHourly}');
  late final TextEditingController _fullDay =
      TextEditingController(text: '${widget.ground.priceFullDay}');

  late TimeOfDay _open = _parse(widget.ground.openTime, const TimeOfDay(hour: 6, minute: 0));
  late TimeOfDay _close =
      _parse(widget.ground.closeTime, const TimeOfDay(hour: 22, minute: 0));

  bool _busy = false;

  final PhotoPicker _picker = PhotoPicker();
  PickedPhoto? _newCover;
  late final List<String> _photoUrls =
      List<String>.from(widget.ground.photos);

  static TimeOfDay _parse(String hhmm, TimeOfDay fallback) {
    final parts = hhmm.split(':');
    if (parts.length != 2) return fallback;
    final h = int.tryParse(parts[0]);
    final m = int.tryParse(parts[1]);
    if (h == null || m == null || h < 0 || h > 23 || m < 0 || m > 59) {
      return fallback;
    }
    return TimeOfDay(hour: h, minute: m);
  }

  static String _hhmm(TimeOfDay t) =>
      '${t.hour.toString().padLeft(2, '0')}:'
      '${t.minute.toString().padLeft(2, '0')}';

  @override
  void dispose() {
    _name.dispose();
    _address.dispose();
    _weekday.dispose();
    _weekend.dispose();
    _fullDay.dispose();
    super.dispose();
  }

  // Pure validation lives as top-level functions (see bottom of this file) so
  // it can be unit-tested without a widget or a Firestore connection.

  Widget _coverPlaceholder() => Container(
        color: AppTheme.surfaceSoft,
        child: const Icon(Icons.image_outlined, color: AppTheme.textSecondary),
      );

  Future<void> _pickCover() async {
    final messenger = ScaffoldMessenger.of(context);
    try {
      final picked = await _picker.pickFromGallery();
      if (picked == null) return;
      final problem = PhotoRules.validate(
        sizeBytes: picked.bytes.length,
        contentType: picked.contentType,
      );
      if (problem != null) {
        messenger.showSnackBar(SnackBar(content: Text(problem)));
        return;
      }
      setState(() => _newCover = picked);
    } catch (e) {
      messenger.showSnackBar(SnackBar(content: Text('Could not open the gallery: $e')));
    }
  }

  Future<void> _pickTime({required bool isOpen}) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: isOpen ? _open : _close,
    );
    if (picked == null) return;
    setState(() {
      if (isOpen) {
        _open = picked;
      } else {
        _close = picked;
      }
    });
  }

  Future<void> _save() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    final hoursError = validateGroundHours(
      open: _open,
      close: _close,
      slotMinutes: widget.ground.slotDurationMinutes,
    );
    if (hoursError != null) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(hoursError)));
      return;
    }

    setState(() => _busy = true);
    final messenger = ScaffoldMessenger.of(context);
    final groundService = context.read<GroundService>();
    final storage = context.read<StorageService>();
    try {
      // Cover photo: upload first so the URL is ready before the single
      // update call that the rules allow. A failed upload keeps the old cover
      // instead of throwing away the name/price edits the owner just typed.
      String? newCover;
      var coverFailed = false;
      if (_newCover != null) {
        try {
          final uploaded = await storage.uploadBytes(
            target: PhotoTarget.ground,
            ownerId: widget.ground.id,
            bytes: _newCover!.bytes,
            contentType: _newCover!.contentType,
            fileName: 'cover_${DateTime.now().millisecondsSinceEpoch}'
                '${PhotoRules.extensionFor(_newCover!.contentType)}',
          );
          newCover = uploaded.downloadUrl;
        } on Exception {
          coverFailed = true;
        }
      }

      await groundService.updateGround(
        widget.ground.id,
        {
          'name': _name.text.trim(),
          'address': _address.text.trim(),
          'price_weekday_hourly': int.parse(_weekday.text.trim()),
          'price_weekend_hourly': int.parse(_weekend.text.trim()),
          'price_full_day': int.parse(_fullDay.text.trim()),
          'open_time': _hhmm(_open),
          'close_time': _hhmm(_close),
          if (newCover != null) 'cover_photo_url': newCover,
          if (newCover != null && !_photoUrls.contains(newCover))
            'photos': [..._photoUrls, newCover],
        },
      );
      if (!mounted) return;
      Navigator.pop(context);
      messenger.showSnackBar(
        SnackBar(
          content: Text(coverFailed
              ? 'Saved, but the new cover photo could not be uploaded.'
              : 'Ground updated.'),
        ),
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
      appBar: AppBar(title: const Text('Edit ground')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            TextFormField(
              controller: _name,
              textCapitalization: TextCapitalization.words,
              decoration: const InputDecoration(labelText: 'Ground name'),
              validator: validateGroundName,
            ),
            const SizedBox(height: 14),
            TextFormField(
              controller: _address,
              maxLines: 2,
              decoration: const InputDecoration(
                labelText: 'Address',
                alignLabelWithHint: true,
              ),
              validator: validateGroundAddress,
            ),
            const SizedBox(height: 20),
            const _Label('COVER PHOTO'),
            const SizedBox(height: 10),
            Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: SizedBox(
                    width: 88,
                    height: 66,
                    child: _newCover != null
                        ? Image.memory(_newCover!.bytes, fit: BoxFit.cover)
                        : (widget.ground.coverPhotoUrl.isNotEmpty
                            ? Image.network(widget.ground.coverPhotoUrl,
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) =>
                                    _coverPlaceholder())
                            : _coverPlaceholder()),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _busy ? null : _pickCover,
                    icon: const Icon(Icons.add_a_photo_outlined, size: 18),
                    label: Text(_newCover == null ? 'Change cover' : 'New cover picked'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            const _Label('PRICING'),
            const SizedBox(height: 10),
            TextFormField(
              controller: _weekday,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Weekday rate per hour',
                prefixText: '₹ ',
              ),
              validator: validateGroundPrice,
            ),
            const SizedBox(height: 14),
            TextFormField(
              controller: _weekend,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Weekend rate per hour',
                prefixText: '₹ ',
              ),
              validator: validateGroundPrice,
            ),
            const SizedBox(height: 14),
            TextFormField(
              controller: _fullDay,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Full-day rate',
                prefixText: '₹ ',
                helperText: '0 = full-day booking not offered',
              ),
              validator: (v) => validateGroundPrice(v, allowZero: true),
            ),
            const SizedBox(height: 20),
            const _Label('OPENING HOURS'),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: _TimeTile(
                    label: 'Opens',
                    value: _hhmm(_open),
                    onTap: () => _pickTime(isOpen: true),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _TimeTile(
                    label: 'Closes',
                    value: _hhmm(_close),
                    onTap: () => _pickTime(isOpen: false),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            const Text(
              'Verification status and ratings are managed by CricketHub — '
              'they are not editable here.',
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

class _Label extends StatelessWidget {
  const _Label(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 10,
        letterSpacing: 1,
        fontWeight: FontWeight.w800,
        color: AppTheme.textSecondary,
      ),
    );
  }
}

class _TimeTile extends StatelessWidget {
  const _TimeTile({
    required this.label,
    required this.value,
    required this.onTap,
  });

  final String label;
  final String value;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: AppTheme.surfaceSoft,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppTheme.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: const TextStyle(
                fontSize: 11,
                color: AppTheme.textSecondary,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              value,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      ),
    );
  }
}


// -----------------------------------------------------------------------------
// Pure validators (tested in test/edit_forms_validation_test.dart)
// -----------------------------------------------------------------------------

/// Ground name: required, 3–80 characters.
String? validateGroundName(String? value) {
  if (value == null || value.trim().isEmpty) return 'Ground name is required.';
  if (value.trim().length < 3) return 'At least 3 characters.';
  if (value.trim().length > 80) return 'Keep it under 80 characters.';
  return null;
}

/// Address: required, up to 200 characters.
String? validateGroundAddress(String? value) {
  if (value == null || value.trim().isEmpty) return 'Address is required.';
  if (value.trim().length > 200) return 'Keep it under 200 characters.';
  return null;
}

/// Rupee amount. Hourly rates must be > 0; the full-day rate may be 0
/// ("full-day booking not offered").
String? validateGroundPrice(String? value, {bool allowZero = false}) {
  final n = int.tryParse((value ?? '').trim());
  if (n == null) return 'Enter a whole number of rupees.';
  if (allowZero ? n < 0 : n <= 0) {
    return allowZero ? 'Cannot be negative.' : 'Must be more than 0.';
  }
  if (n > 500000) return 'That looks too high.';
  return null;
}

/// Opening/closing hours must leave room for at least one slot.
String? validateGroundHours({
  required TimeOfDay open,
  required TimeOfDay close,
  required int slotMinutes,
}) {
  final openMin = open.hour * 60 + open.minute;
  final closeMin = close.hour * 60 + close.minute;
  if (closeMin <= openMin) return 'Closing time must be after opening.';
  if (closeMin - openMin < slotMinutes) {
    return 'Leave room for at least one $slotMinutes-minute slot.';
  }
  return null;
}
