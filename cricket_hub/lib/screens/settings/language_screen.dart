import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/app_theme.dart';
import '../../l10n/generated/app_localizations.dart';
import '../../providers/locale_provider.dart';

/// Phase 4 — language picker.
///
/// "Device language" is a real option, not a reset button: a user whose phone
/// is in Hindi should get Hindi without ever visiting this screen.
class LanguageScreen extends StatelessWidget {
  const LanguageScreen({super.key});

  static const String route = '/language';

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final localeProvider = context.watch<LocaleProvider>();

    final options = <_LanguageOption>[
      _LanguageOption(
        label: l10n.languageSystem,
        subtitle: 'English · हिन्दी · தமிழ்',
        locale: null,
      ),
      // No subtitle on these three: the label is already the language's own
      // name, and a second line saying "Hindi" under "हिन्दी" is noise.
      _LanguageOption(
        label: l10n.languageEnglish,
        locale: const Locale('en'),
      ),
      _LanguageOption(
        label: l10n.languageHindi,
        locale: const Locale('hi'),
      ),
      _LanguageOption(
        label: l10n.languageTamil,
        locale: const Locale('ta'),
      ),
    ];

    return Scaffold(
      appBar: AppBar(title: Text(l10n.languageTitle)),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 4, bottom: 12),
            child: Text(
              l10n.languageSubtitle,
              style: Theme.of(context)
                  .textTheme
                  .bodySmall
                  ?.copyWith(color: AppTheme.textSecondary),
            ),
          ),
          Card(
            child: Column(
              children: [
                for (var i = 0; i < options.length; i++) ...[
                  if (i > 0) const Divider(height: 1, indent: 16),
                  _LanguageTile(
                    option: options[i],
                    selected: options[i].locale?.languageCode ==
                        localeProvider.locale?.languageCode,
                    onTap: () => context
                        .read<LocaleProvider>()
                        .setLocale(options[i].locale),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _LanguageOption {
  const _LanguageOption({
    required this.label,
    required this.locale,
    this.subtitle,
  });

  final String label;
  final String? subtitle;

  /// Null = follow the device.
  final Locale? locale;
}

class _LanguageTile extends StatelessWidget {
  const _LanguageTile({
    required this.option,
    required this.selected,
    required this.onTap,
  });

  final _LanguageOption option;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: onTap,
      title: Text(
        option.label,
        style: Theme.of(context).textTheme.titleSmall?.copyWith(
              fontWeight: selected ? FontWeight.w800 : FontWeight.w500,
            ),
      ),
      subtitle: option.subtitle == null
          ? null
          : Text(
              option.subtitle!,
              style: Theme.of(context)
                  .textTheme
                  .bodySmall
                  ?.copyWith(color: AppTheme.textSecondary),
            ),
      trailing: selected
          ? const Icon(Icons.check_circle_rounded, color: AppTheme.primary)
          : const Icon(Icons.circle_outlined, color: AppTheme.border),
    );
  }
}
