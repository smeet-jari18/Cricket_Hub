import 'dart:typed_data';

import 'package:firebase_storage/firebase_storage.dart';

/// Where a photo is being uploaded — decides the storage path.
enum PhotoTarget { ground, umpire }

/// Result of uploading one photo.
class UploadedPhoto {
  const UploadedPhoto({required this.path, required this.downloadUrl});

  final String path;
  final String downloadUrl;
}

/// Thrown when a file would be rejected — locally by [PhotoRules] and,
/// authoritatively, by `storage.rules`.
class PhotoRuleException implements Exception {
  const PhotoRuleException(this.message);

  final String message;

  @override
  String toString() => message;
}

/// Client-side mirror of `storage.rules`.
///
/// The rules are the real gate (they run on every upload), but checking here
/// turns a `storage/unauthorized` into a readable message *before* 5 MB goes
/// over the wire. Keep the two in sync — `rules-test/storage.test.js` pins the
/// server side, `test/storage_service_test.dart` pins this one. A mutation test
/// against the emulator confirms that suite is rules-sensitive: deleting the
/// owner check turns 3 of its 19 checks red.
class PhotoRules {
  PhotoRules._();

  static const int maxBytes = 5 * 1024 * 1024; // 5 MB, same as storage.rules
  static const int maxGroundPhotos = 5;
  static const List<String> allowedMimePrefix = ['image/'];

  /// Returns null when acceptable, otherwise a user-facing reason.
  static String? validate({
    required int sizeBytes,
    required String contentType,
  }) {
    if (sizeBytes <= 0) return 'That file is empty.';
    if (sizeBytes > maxBytes) {
      final mb = (sizeBytes / (1024 * 1024)).toStringAsFixed(1);
      return 'Photo is ${mb}MB — the limit is 5MB.';
    }
    final ok = allowedMimePrefix.any(contentType.startsWith);
    if (!ok) return 'Only images can be uploaded.';
    return null;
  }

  static void assertValid({required int sizeBytes, required String contentType}) {
    final problem = validate(sizeBytes: sizeBytes, contentType: contentType);
    if (problem != null) throw PhotoRuleException(problem);
  }

  /// File extension for a MIME type. Only affects the object name (humans read
  /// it in the console) — the rules check [validate]'s `contentType`, never the
  /// extension, so an unknown type safely falls back to `.bin` and is then
  /// rejected by the `image/` check anyway.
  static String extensionFor(String contentType) {
    final sub = contentType.split('/').last.toLowerCase();
    return switch (sub) {
      'jpeg' || 'jpg' => '.jpg',
      'png' => '.png',
      'webp' => '.webp',
      'gif' => '.gif',
      'heic' => '.heic',
      _ => '.bin',
    };
  }
}

/// Uploads listing photos to Firebase Storage and hands back download URLs.
///
/// Paths match `storage.rules`:
///   grounds/{groundId}/{fileName}   — only that ground's owner may write
///   umpires/{umpireUid}/{fileName}  — only that umpire may write
class StorageService {
  StorageService({FirebaseStorage? storage})
      : _storage = storage ?? FirebaseStorage.instance;

  final FirebaseStorage _storage;

  /// Prefix on generated file names, so the bucket stays readable when
  /// someone looks at it in the Firebase console.
  static const String _fileNamePrefix = 'photo';

  /// Uploads raw bytes. [extension] is used for the file name only — the
  /// content type is what the rules check.
  Future<UploadedPhoto> uploadBytes({
    required PhotoTarget target,
    required String ownerId,
    required Uint8List bytes,
    required String contentType,
    String? fileName,
  }) async {
    PhotoRules.assertValid(sizeBytes: bytes.length, contentType: contentType);

    final name = fileName ?? _timestampedName(contentType);
    final path = switch (target) {
      PhotoTarget.ground => 'grounds/$ownerId/$name',
      PhotoTarget.umpire => 'umpires/$ownerId/$name',
    };

    final ref = _storage.ref(path);
    await ref.putData(
      bytes,
      SettableMetadata(contentType: contentType),
    );
    final url = await ref.getDownloadURL();
    return UploadedPhoto(path: path, downloadUrl: url);
  }

  /// Uploads several ground photos and returns their public URLs in order.
  Future<List<String>> uploadGroundPhotos({
    required String groundId,
    required List<(Uint8List bytes, String contentType)> photos,
  }) async {
    if (photos.length > PhotoRules.maxGroundPhotos) {
      throw const PhotoRuleException('A ground can show at most 5 photos.');
    }
    final urls = <String>[];
    for (var i = 0; i < photos.length; i++) {
      final (bytes, contentType) = photos[i];
      final result = await uploadBytes(
        target: PhotoTarget.ground,
        ownerId: groundId,
        bytes: bytes,
        contentType: contentType,
        fileName: 'photo_${i + 1}_${DateTime.now().millisecondsSinceEpoch}'
            '${PhotoRules.extensionFor(contentType)}',
      );
      urls.add(result.downloadUrl);
    }
    return urls;
  }

  /// Deletes a file this user uploaded (best effort — a missing file is fine).
  Future<void> deleteByPath(String path) async {
    try {
      await _storage.ref(path).delete();
    } on FirebaseException {
      // Already gone / never existed: nothing to clean up.
    }
  }

  static String _timestampedName(String contentType) =>
      '${_fileNamePrefix}_${DateTime.now().millisecondsSinceEpoch}'
      '${PhotoRules.extensionFor(contentType)}';

}
