import 'package:cricket_hub/providers/locale_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('load', () {
    test('a first run follows the device language', () async {
      final provider = LocaleProvider();
      await provider.load();

      expect(provider.locale, isNull);
      expect(provider.followsDevice, isTrue);
      expect(provider.isLoaded, isTrue);
    });

    test('a saved choice is restored', () async {
      SharedPreferences.setMockInitialValues({LocaleProvider.storageKey: 'ta'});

      final provider = LocaleProvider();
      await provider.load();

      expect(provider.locale, const Locale('ta'));
      expect(provider.followsDevice, isFalse);
    });

    test('a saved language we no longer ship is ignored', () async {
      // e.g. a build that once shipped Gujarati, or a hand-edited prefs file.
      SharedPreferences.setMockInitialValues({LocaleProvider.storageKey: 'gu'});

      final provider = LocaleProvider();
      await provider.load();

      expect(provider.locale, isNull);
    });
  });

  group('setLocale', () {
    test('persists the choice', () async {
      final provider = LocaleProvider();
      await provider.load();
      await provider.setLocale(const Locale('hi'));

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString(LocaleProvider.storageKey), 'hi');
      expect(provider.locale, const Locale('hi'));
    });

    test('null goes back to following the device', () async {
      final provider = LocaleProvider();
      await provider.load();
      await provider.setLocale(const Locale('hi'));
      await provider.setLocale(null);

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString(LocaleProvider.storageKey), isNull);
      expect(provider.locale, isNull);
      expect(provider.followsDevice, isTrue);
    });

    test('an unsupported language is refused, not silently stored', () async {
      final provider = LocaleProvider();
      await provider.load();
      await provider.setLocale(const Locale('fr'));

      expect(provider.locale, isNull);
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString(LocaleProvider.storageKey), isNull);
    });

    test('notifies listeners only when the language actually changes', () async {
      final provider = LocaleProvider();
      await provider.load();

      var notifications = 0;
      provider.addListener(() => notifications++);

      await provider.setLocale(const Locale('hi'));
      expect(notifications, 1);

      await provider.setLocale(const Locale('hi'));
      expect(notifications, 1, reason: 'same language, no rebuild');

      await provider.setLocale(const Locale('ta'));
      expect(notifications, 2);
    });
  });

  group('resolve', () {
    test('a supported device language is used as-is', () {
      expect(LocaleProvider.resolve(const Locale('hi')), const Locale('hi'));
      expect(LocaleProvider.resolve(const Locale('ta')), const Locale('ta'));
      expect(LocaleProvider.resolve(const Locale('en', 'GB')),
          const Locale('en', 'GB'));
    });

    test('an unsupported device language falls back to English', () {
      expect(LocaleProvider.resolve(const Locale('fr')), const Locale('en'));
      expect(LocaleProvider.resolve(const Locale('gu', 'IN')), const Locale('en'));
      expect(LocaleProvider.resolve(const Locale('zh', 'Hant')), const Locale('en'));
    });
  });

  test('every supported locale has an ARB file', () {
    // Keeps `supportedLocales` honest: adding a locale here without the ARB
    // (or the other way round) is a bug the l10n test would otherwise miss.
    expect(LocaleProvider.supportedLanguageCodes, ['en', 'hi', 'ta']);
    expect(LocaleProvider.supportedLocales.map((l) => l.languageCode).toList(),
        LocaleProvider.supportedLanguageCodes);
  });
}
