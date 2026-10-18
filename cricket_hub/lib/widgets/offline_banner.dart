import 'package:flutter/material.dart';

import '../core/app_theme.dart';
import '../l10n/generated/app_localizations.dart';

/// Non-intrusive offline indicator (UI/UX Guidelines §5).
/// Used on the scoring screen — scoring NEVER blocks while offline.
class OfflineBanner extends StatelessWidget {
  final bool isOffline;

  const OfflineBanner({super.key, required this.isOffline});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    if (!isOffline) return const SizedBox.shrink();

    return Container(
      width: double.infinity,
      color: AppTheme.accent,
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.cloud_off, size: 14, color: AppTheme.textPrimary),
          const SizedBox(width: 8),
          Text(
            l10n.offlineBanner,
            style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: AppTheme.textPrimary),
          ),
        ],
      ),
    );
  }
}
