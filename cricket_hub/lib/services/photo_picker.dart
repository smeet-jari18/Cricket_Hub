import 'dart:typed_data';

import 'package:image_picker/image_picker.dart';

/// Picked image bytes plus the MIME type Storage will check.
class PickedPhoto {
  const PickedPhoto({required this.bytes, required this.contentType, this.name});

  final Uint8List bytes;
  final String contentType;
  final String? name;
}

/// Thin wrapper over `image_picker` so screens (and widget tests) never touch
/// the plugin directly. Every method returns null when the user cancels.
class PhotoPicker {
  PhotoPicker({ImagePicker? picker}) : _picker = picker ?? ImagePicker();

  final ImagePicker _picker;

  static const double _maxWidth = 1600;
  static const int _quality = 80;

  /// Gallery pick — downscaled in the plugin so a 12MP shot does not have to
  /// be rejected by the 5MB rule.
  Future<PickedPhoto?> pickFromGallery() => _pick(_picker.pickImage);

  Future<PickedPhoto?> pickFromCamera() => _pick(_picker.pickImage, camera: true);

  Future<PickedPhoto?> _pick(
    Future<XFile?> Function({
      required ImageSource source,
      double? maxWidth,
      int? imageQuality,
    }) picker, {
    bool camera = false,
  }) async {
    final file = await picker(
      source: camera ? ImageSource.camera : ImageSource.gallery,
      maxWidth: _maxWidth,
      imageQuality: _quality,
    );
    if (file == null) return null;
    final bytes = await file.readAsBytes();
    return PickedPhoto(
      bytes: bytes,
      contentType: file.mimeType ?? _guessType(file.name),
      name: file.name,
    );
  }

  /// `image_picker` does not always report a MIME type (Android gallery
  /// returns null), so fall back to the extension.
  static String _guessType(String fileName) {
    final lower = fileName.toLowerCase();
    if (lower.endsWith('.png')) return 'image/png';
    if (lower.endsWith('.webp')) return 'image/webp';
    if (lower.endsWith('.gif')) return 'image/gif';
    return 'image/jpeg';
  }
}
