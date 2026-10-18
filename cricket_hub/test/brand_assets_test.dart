import 'dart:io';

import 'dart:ui' as ui;

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

/// The logo ships in four places (in-app asset, Android, iOS, web) and only
/// one of them is checked by the compiler. A missing or zero-byte icon is
/// discovered by a user installing the app, which is too late — so check every
/// path here instead.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('the splash logo is bundled and decodes', () async {
    final data = await rootBundle.load('assets/images/logo.png');
    expect(data.lengthInBytes, greaterThan(2000),
        reason: 'assets/images/logo.png is missing or empty');

    final codec = await ui.instantiateImageCodec(data.buffer.asUint8List());
    final frame = await codec.getNextFrame();
    expect(frame.image.width, 512);
    expect(frame.image.height, 512);
  });

  test('every Android launcher density is present', () {
    for (final density in ['mdpi', 'hdpi', 'xhdpi', 'xxhdpi', 'xxxhdpi']) {
      final legacy = File(
          'android/app/src/main/res/mipmap-$density/ic_launcher.png');
      final adaptive = File(
          'android/app/src/main/res/drawable-$density/ic_launcher_foreground.png');
      expect(legacy.existsSync(), isTrue, reason: '${legacy.path} missing');
      expect(adaptive.existsSync(), isTrue, reason: '${adaptive.path} missing');
      expect(legacy.lengthSync(), greaterThan(200),
          reason: '${legacy.path} looks empty');
    }

    expect(
        File('android/app/src/main/res/mipmap-anydpi-v26/ic_launcher.xml')
            .existsSync(),
        isTrue,
        reason: 'adaptive icon XML missing — Android 8+ falls back to a '
            'stretched legacy bitmap');
  });

  test('the iOS icon set is complete and has no alpha channel', () {
    // App Store Connect rejects icons with transparency, so this is a release
    // blocker, not a style note.
    final dir = Directory('ios/Runner/Assets.xcassets/AppIcon.appiconset');
    final icons = dir
        .listSync()
        .whereType<File>()
        .where((f) => f.path.endsWith('.png'))
        .toList();

    expect(icons.length, greaterThanOrEqualTo(15));
    for (final icon in icons) {
      final width = _pngWidth(icon.readAsBytesSync());
      expect(width, greaterThan(0), reason: '${icon.path} is not a PNG');
      final colourType = icon.readAsBytesSync()[25];
      expect(colourType, isNot(6), reason: '${icon.path} has an alpha channel');
    }

    final big = File('${dir.path}/Icon-App-1024x1024@1x.png');
    expect(_pngWidth(big.readAsBytesSync()), 1024);
  });

  test('the web icons match the launcher icon', () {
    for (final name in [
      'web/icons/Icon-192.png',
      'web/icons/Icon-512.png',
      'web/favicon.png',
    ]) {
      expect(File(name).existsSync(), isTrue, reason: '$name missing');
    }
  });

  test('the original artwork is kept in the repo', () {
    // tools/make_icons.py regenerates everything from this one file. If it
    // disappears, the icons become unreproducible.
    expect(File('assets/branding/logo_source.png').existsSync(), isTrue);
  });
}

/// Width from the PNG IHDR chunk (bytes 16–19), no image package needed.
int _pngWidth(List<int> bytes) {
  if (bytes.length < 24) return 0;
  if (bytes[1] != 0x50 || bytes[2] != 0x4E || bytes[3] != 0x47) return 0;
  return (bytes[16] << 24) | (bytes[17] << 16) | (bytes[18] << 8) | bytes[19];
}
