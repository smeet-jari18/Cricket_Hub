import 'package:cricket_hub/services/storage_service.dart';
import 'package:flutter_test/flutter_test.dart';

/// `PhotoRules` mirrors `storage.rules`. If either side changes, this test or
/// `rules-test/storage.test.js` fails — they are the pair that keeps the
/// client's friendly error and the server's hard limit identical.
void main() {
  group('PhotoRules.validate', () {
    test('accepts a normal JPEG under the limit', () {
      expect(
        PhotoRules.validate(sizeBytes: 800 * 1024, contentType: 'image/jpeg'),
        isNull,
      );
    });

    test('accepts exactly 5MB', () {
      expect(
        PhotoRules.validate(sizeBytes: PhotoRules.maxBytes, contentType: 'image/png'),
        isNull,
      );
    });

    test('rejects one byte over 5MB with a readable message', () {
      final msg = PhotoRules.validate(
        sizeBytes: PhotoRules.maxBytes + 1,
        contentType: 'image/jpeg',
      );
      expect(msg, isNotNull);
      expect(msg, contains('5MB'));
    });

    test('rejects non-image content types', () {
      expect(
        PhotoRules.validate(sizeBytes: 1024, contentType: 'application/pdf'),
        'Only images can be uploaded.',
      );
      expect(
        PhotoRules.validate(sizeBytes: 1024, contentType: 'text/plain'),
        isNotNull,
      );
    });

    test('rejects an empty file', () {
      expect(
        PhotoRules.validate(sizeBytes: 0, contentType: 'image/jpeg'),
        isNotNull,
      );
    });

    test('allows every image subtype the picker can produce', () {
      for (final type in ['image/jpeg', 'image/png', 'image/webp', 'image/gif']) {
        expect(
          PhotoRules.validate(sizeBytes: 2048, contentType: type),
          isNull,
          reason: type,
        );
      }
    });

    test('assertValid throws PhotoRuleException, not ArgumentError', () {
      expect(
        () => PhotoRules.assertValid(sizeBytes: 6 * 1024 * 1024, contentType: 'image/jpeg'),
        throwsA(isA<PhotoRuleException>()),
      );
    });

    test('assertValid stays quiet for a good photo', () {
      expect(
        () => PhotoRules.assertValid(sizeBytes: 1024, contentType: 'image/jpeg'),
        returnsNormally,
      );
    });
  });

  group('extensionFor', () {
    test('maps the types the picker produces', () {
      expect(PhotoRules.extensionFor('image/jpeg'), '.jpg');
      expect(PhotoRules.extensionFor('image/jpg'), '.jpg');
      expect(PhotoRules.extensionFor('image/png'), '.png');
      expect(PhotoRules.extensionFor('image/webp'), '.webp');
      expect(PhotoRules.extensionFor('image/gif'), '.gif');
      expect(PhotoRules.extensionFor('image/heic'), '.heic');
    });

    test('falls back to .bin for an unknown subtype', () {
      expect(PhotoRules.extensionFor('image/tiff'), '.bin');
      expect(PhotoRules.extensionFor('application/pdf'), '.bin');
    });
  });

  group('photo limits', () {
    test('a ground may show at most 5 photos', () {
      expect(PhotoRules.maxGroundPhotos, 5);
    });

    test('the byte limit matches storage.rules (5MB)', () {
      expect(PhotoRules.maxBytes, 5 * 1024 * 1024);
    });
  });
}
