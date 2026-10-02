import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/app_theme.dart';
import '../providers/auth_provider.dart';
import 'auth/login_screen.dart';
import 'auth/profile_setup_screen.dart';
import 'home/main_shell.dart';

/// Flow 1 of the App Flow doc:
/// Splash -> (logged in? Home : Login) -> (new user? Profile Setup : Home)
class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  static const String route = '/';

  @override
  Widget build(BuildContext context) {
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

    return const Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.sports_cricket, size: 96, color: AppTheme.primary),
            SizedBox(height: 16),
            Text('CricketHub',
                style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold)),
            SizedBox(height: 8),
            Text('Local cricket. Pro level.',
                style: TextStyle(color: AppTheme.textSecondary)),
            SizedBox(height: 32),
            CircularProgressIndicator(),
          ],
        ),
      ),
    );
  }
}
