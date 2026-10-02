import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/app_theme.dart';
import '../../providers/auth_provider.dart';
import '../auth/login_screen.dart';

/// "Menu" tab: profile summary + settings + logout.
class MenuScreen extends StatelessWidget {
  const MenuScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final user = auth.appUser;

    return Scaffold(
      appBar: AppBar(title: const Text('Menu')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Profile header
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  const CircleAvatar(
                    radius: 32,
                    backgroundColor: AppTheme.primary,
                    child: Icon(Icons.person, color: AppTheme.background),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(user?.displayName ?? 'Player',
                            style: const TextStyle(
                                fontSize: 18, fontWeight: FontWeight.bold)),
                        Text(
                          user?.battingStyle ?? '',
                          style: const TextStyle(
                              color: AppTheme.textSecondary),
                        ),
                        if ((user?.bowlingStyle ?? '').isNotEmpty)
                          Text(user!.bowlingStyle,
                              style: const TextStyle(
                                  color: AppTheme.textSecondary)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Career stats teaser (Phase 2: real aggregation via Cloud Functions)
          const Card(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Career Stats',
                      style:
                          TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  SizedBox(height: 8),
                  Text(
                    'Runs, wickets, averages and leaderboards arrive in '
                    'Phase 2 — powered by Cloud Functions (see TRD §5).',
                    style: TextStyle(color: AppTheme.textSecondary),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          const ListTile(
            leading: Icon(Icons.grass),
            title: Text('Ground Booking (Phase 3)'),
            trailing: Icon(Icons.lock, size: 18),
          ),
          const ListTile(
            leading: Icon(Icons.record_voice_over),
            title: Text('Umpire Booking (Phase 3)'),
            trailing: Icon(Icons.lock, size: 18),
          ),
          const ListTile(
            leading: Icon(Icons.public),
            title: Text('International Scores (Phase 4)'),
            trailing: Icon(Icons.lock, size: 18),
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.logout, color: AppTheme.danger),
            title: const Text('Log out', style: TextStyle(color: AppTheme.danger)),
            onTap: () async {
              final authProvider = context.read<AuthProvider>();
              await authProvider.signOut();
              if (!context.mounted) return;
              Navigator.pushNamedAndRemoveUntil(
                context,
                LoginScreen.route,
                (route) => false,
              );
            },
          ),
        ],
      ),
    );
  }
}
