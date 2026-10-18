import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Guards the ARB files the way a compiler guards code.
///
/// `flutter gen-l10n` happily generates a locale with a missing key (it falls
/// back to the template), so a forgotten Tamil string would ship silently.
/// These tests run on the raw `.arb` files, before generation.
void main() {
  const locales = ['en', 'hi', 'ta'];
  const template = 'en';

  // NOTE: `expect` cannot be used at file scope (it throws OutsideTestException
  // during loading), so this throws a plain error instead.
  Map<String, dynamic> readArb(String code) {
    final file = File('lib/l10n/app_$code.arb');
    if (!file.existsSync()) {
      throw StateError('missing lib/l10n/app_$code.arb');
    }
    return jsonDecode(file.readAsStringSync()) as Map<String, dynamic>;
  }

  /// Keys that are actual strings, i.e. not metadata (`@key`, `@@locale`).
  Set<String> messageKeys(Map<String, dynamic> arb) =>
      arb.keys.where((k) => !k.startsWith('@')).toSet();

  Set<String> placeholdersOf(Map<String, dynamic> arb, String key) {
    final meta = arb['@$key'];
    if (meta is! Map) return {};
    final placeholders = meta['placeholders'];
    if (placeholders is! Map) return {};
    return placeholders.keys.cast<String>().toSet();
  }

  final arbs = {for (final code in locales) code: readArb(code)};

  test('every locale has exactly the same message keys', () {
    final templateKeys = messageKeys(arbs[template]!);

    for (final code in locales.where((c) => c != template)) {
      final keys = messageKeys(arbs[code]!);
      final missing = templateKeys.difference(keys);
      final extra = keys.difference(templateKeys);

      expect(missing, isEmpty,
          reason: '$code is missing: ${missing.join(', ')}');
      expect(extra, isEmpty,
          reason: '$code has keys the template does not: ${extra.join(', ')}');
    }
  });

  test('no message is empty or left as a TODO', () {
    for (final code in locales) {
      final arb = arbs[code]!;
      for (final key in messageKeys(arb)) {
        final value = arb[key];
        expect(value, isA<String>(), reason: '$code.$key is not a string');
        final text = (value as String).trim();
        expect(text, isNotEmpty, reason: '$code.$key is empty');
        expect(text.toLowerCase(), isNot(contains('todo')),
            reason: '$code.$key still says TODO');
        expect(text.toLowerCase(), isNot(contains('translate')),
            reason: '$code.$key looks untranslated');
      }
    }
  });

  test('Hindi and Tamil are actually translated, not copied from English', () {
    final english = arbs['en']!;

    // A handful of keys are legitimately identical across languages: brand
    // names, cricket notation (4s/6s/SR) and labels the market uses in English.
    const allowedIdentical = {
      'intlFours',
      'intlSixes',
      'intlStrikeRate',
      'languageEnglish',
      'languageHindi',
      'languageTamil',
      'menuLanguageSub',
    };

    for (final code in ['hi', 'ta']) {
      final arb = arbs[code]!;
      final copied = <String>[];
      for (final key in messageKeys(english)) {
        if (allowedIdentical.contains(key)) continue;
        if (arb[key] == english[key]) copied.add(key);
      }
      expect(copied, isEmpty,
          reason: '$code has English text in: ${copied.join(', ')}');
    }
  });

  test('placeholders match the template for every locale', () {
    final english = arbs[template]!;

    for (final key in messageKeys(english)) {
      final expected = placeholdersOf(english, key);
      if (expected.isEmpty) continue;

      for (final code in locales.where((c) => c != template)) {
        final arb = arbs[code]!;
        final actual = placeholdersOf(arb, key);
        // A locale may omit the @-metadata block (gen-l10n reads the template),
        // but if it declares placeholders they must be the same set.
        if (actual.isNotEmpty) {
          expect(actual, expected,
              reason: '$code.$key placeholders differ from the template');
        }

        // More important: every placeholder must actually appear in the text.
        final text = arb[key] as String;
        for (final placeholder in expected) {
          expect(text, contains('{$placeholder}'),
              reason: '$code.$key is missing {$placeholder} in its text');
        }
      }
    }
  });

  test('the app supports the three languages the PRD asks for', () {
    expect(messageKeys(arbs['en']!), contains('navInternational'));
    expect(locales, containsAll(['en', 'hi', 'ta']));
  });
}
