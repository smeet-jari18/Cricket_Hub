import 'package:flutter/material.dart';

import '../core/app_theme.dart';

/// Shown when the app cannot reach Firebase at startup.
///
/// A black screen is the worst possible failure: it tells the user nothing and
/// looks like a crashed build. This screen always appears instead, says what
/// broke, and keeps the technical detail behind an expander so a developer can
/// read it without the end user seeing a stack trace.
class BootstrapErrorScreen extends StatelessWidget {
  const BootstrapErrorScreen({super.key, required this.error});

  final Object? error;

  @override
  Widget build(BuildContext context) {
    final theme = ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(seedColor: AppTheme.primary),
    );

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: theme,
      home: Scaffold(
        backgroundColor: AppTheme.background,
        body: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(22),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 54,
                        height: 54,
                        decoration: const BoxDecoration(
                          color: AppTheme.accentContainer,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.cloud_off_rounded,
                            color: AppTheme.accentText, size: 26),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'CricketHub could not start',
                        style: theme.textTheme.titleLarge
                            ?.copyWith(fontWeight: FontWeight.w800),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'The app could not connect to Firebase, so the '
                        'screens have nothing to load yet.',
                        style: theme.textTheme.bodyMedium
                            ?.copyWith(color: AppTheme.textSecondary),
                      ),
                      const SizedBox(height: 16),
                      Text('To fix it',
                          style: theme.textTheme.titleSmall),
                      const SizedBox(height: 6),
                      Text(
                        '1. Run  flutterfire configure --project=crickethub-dev\n'
                        '2. Make sure android/app/google-services.json and '
                        'ios/Runner/GoogleService-Info.plist belong to the '
                        'same project\n'
                        '3. Rebuild:  flutter clean && flutter run',
                        style: theme.textTheme.bodySmall
                            ?.copyWith(color: AppTheme.textSecondary, height: 1.5),
                      ),
                      if (error != null) ...[
                        const SizedBox(height: 8),
                        ExpansionTile(
                          tilePadding: EdgeInsets.zero,
                          title: Text('Technical details',
                              style: theme.textTheme.bodySmall),
                          children: [
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: AppTheme.surfaceSoft,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: SelectableText(
                                '$error',
                                style: const TextStyle(
                                    fontSize: 11, fontFamily: 'monospace'),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
