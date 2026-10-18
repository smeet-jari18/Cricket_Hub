import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Which language the app is drawing in.
///
/// Deliberately a `ChangeNotifier` (not a Riverpod provider) — the whole app
/// already uses `provider`, so a new state-management library for one setting
/// would be overkill.
///
/// Three states, and the difference matters:
///   * `locale == null`        → follow the device language
///   * `locale == Locale('hi')`→ user picked Hindi explicitly
///
/// A device set to Gujarati (supported nahi) falls back to English without
/// overwriting the user's choice — that is why we keep "null" instead of
/// writing the resolved locale back into storage.
class LocaleProvider extends ChangeNotifier {
  LocaleProvider({SharedPreferences? prefs}) : _prefs = prefs;

  static const String storageKey = 'app_locale';

  /// Languages CricketHub ships translations for. Adding one here + an ARB
  /// file is the whole recipe (`l10n.yaml`, `lib/l10n/app_<code>.arb`).
  static const List<Locale> supportedLocales = [
    Locale('en'),
    Locale('hi'),
    Locale('ta'),
  ];

  static const List<String> supportedLanguageCodes = ['en', 'hi', 'ta'];

  SharedPreferences? _prefs;
  Locale? _locale;
  bool _loaded = false;

  /// Null means "follow the device".
  Locale? get locale => _locale;

  bool get followsDevice => _locale == null;

  bool get isLoaded => _loaded;

  /// Reads the saved choice. Safe to call more than once.
  Future<void> load() async {
    _prefs ??= await SharedPreferences.getInstance();
    final code = _prefs!.getString(storageKey);
    if (code != null && supportedLanguageCodes.contains(code)) {
      _locale = Locale(code);
    }
    _loaded = true;
    notifyListeners();
  }

  /// `null` = go back to following the device language.
  Future<void> setLocale(Locale? locale) async {
    if (locale != null && !supportedLanguageCodes.contains(locale.languageCode)) {
      return; // unsupported: ignore rather than persist a language we cannot draw
    }
    if (_locale?.languageCode == locale?.languageCode) return;

    _locale = locale;
    notifyListeners();

    _prefs ??= await SharedPreferences.getInstance();
    if (locale == null) {
      await _prefs!.remove(storageKey);
    } else {
      await _prefs!.setString(storageKey, locale.languageCode);
    }
  }

  /// What `MaterialApp` should actually draw with. A locale we do not support
  /// (`gujarati`, `fr`, …) must not blank the UI out.
  static Locale resolve(Locale deviceLocale) {
    // `Locale('pt', 'BR')` → 'pt'
    if (supportedLanguageCodes.contains(deviceLocale.languageCode)) {
      return deviceLocale;
    }
    // Script/region variants like zh_Hant are still honoured by language code,
    // so only fall back when the language itself is unsupported.
    return const Locale('en');
  }
}
