import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/app_theme.dart';
import '../providers/auth_provider.dart';
import 'auth/login_screen.dart';
import 'auth/profile_setup_screen.dart';
import 'home/main_shell.dart';
import '../l10n/generated/app_localizations.dart';

/// Flow 1 of the App Flow doc:
/// Splash -> (logged in? Home : Login) -> (new user? Profile Setup : Home)
class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  static const String route = '/';

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final auth = context.watch<AuthProvider>();

    if (auth.isReady) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!context.mounted) return;

        final destination = !auth.isLoggedIn
            ? LoginScreen.route
            : auth.needsProfileSetup
                ? ProfileSetupScreen.route
                : MainShell.route;
        Navigator.pushReplacementNamed(context, destination);
      });
    }

    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // The real mark, not a Material stand-in. `assets/images/logo.png`
            // is generated from `assets/branding/logo_source.png` by
            // `tools/make_icons.py`, so the splash and the launcher icon can
            // never drift apart.
            Image.asset('assets/images/logo.png', width: 128, height: 128),
            const SizedBox(height: 18),
            const Text('CricketHub',
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.8,
                )),
            const SizedBox(height: 8),
            Text(l10n.splashTagline,
                style: const TextStyle(color: AppTheme.textSecondary)),
            const SizedBox(height: 32),
            const CircularProgressIndicator(),
          ],
        ),
      ),
    );
  }
}
