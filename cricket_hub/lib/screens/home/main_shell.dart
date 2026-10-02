import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/app_theme.dart';
import '../../providers/auth_provider.dart';
import '../../services/notification_service.dart';
import '../match/create_match_screen.dart';
import '../menu/menu_screen.dart';
import '../team/create_team_screen.dart';
import '../tournament/tournaments_screen.dart';
import 'home_screen.dart';
import 'my_cricket_screen.dart';

/// Primary destinations: Home, My Cricket, Tours and Menu.
class MainShell extends StatefulWidget {
  const MainShell({super.key});

  static const String route = '/home';

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _index = 0;

  static const _pages = [
    HomeScreen(),
    MyCricketScreen(),
    TournamentsScreen(),
    MenuScreen(),
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _openPendingMatch());
  }

  Future<void> _openPendingMatch() async {
    if (!mounted) return;
    final uid = context.read<AuthProvider>().firebaseUser?.uid;
    if (uid == null) return;
    final notifications = context.read<NotificationService>();
    await notifications.resubscribeFollowedMatches(uid);
    final matchId = notifications.takePendingMatchId();
    if (matchId != null && mounted) {
      Navigator.pushNamed(context, '/live-match', arguments: matchId);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _index, children: _pages),
      floatingActionButton: _index < 2
          ? FloatingActionButton.extended(
              heroTag: 'quickActions',
              onPressed: () => _showQuickActions(context),
              icon: const Icon(Icons.add_rounded),
              label: const Text('Create'),
            )
          : null,
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (index) => setState(() => _index = index),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home_rounded),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Icon(Icons.sports_cricket),
            selectedIcon: Icon(Icons.sports_cricket),
            label: 'My Cricket',
          ),
          NavigationDestination(
            icon: Icon(Icons.emoji_events_outlined),
            selectedIcon: Icon(Icons.emoji_events_rounded),
            label: 'Tours',
          ),
          NavigationDestination(
            icon: Icon(Icons.grid_view_outlined),
            selectedIcon: Icon(Icons.grid_view_rounded),
            label: 'Menu',
          ),
        ],
      ),
    );
  }

  void _showQuickActions(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (sheetContext) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 4, 20, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Make it a match day',
                  style: Theme.of(context).textTheme.headlineSmall),
              const SizedBox(height: 6),
              Text(
                'Pick what you want to set up.',
                style: Theme.of(context)
                    .textTheme
                    .bodyMedium
                    ?.copyWith(color: AppTheme.textSecondary),
              ),
              const SizedBox(height: 16),
              _QuickActionTile(
                icon: Icons.sports_cricket,
                title: 'Start a match',
                subtitle: 'Choose teams, toss and start scoring',
                accent: AppTheme.accentContainer,
                iconColor: AppTheme.accentText,
                onTap: () {
                  Navigator.pop(sheetContext);
                  Navigator.pushNamed(context, CreateMatchScreen.route);
                },
              ),
              const SizedBox(height: 10),
              _QuickActionTile(
                icon: Icons.groups_rounded,
                title: 'Create a team',
                subtitle: 'Build a squad for your next game',
                accent: AppTheme.primaryContainer,
                iconColor: AppTheme.primary,
                onTap: () {
                  Navigator.pop(sheetContext);
                  Navigator.pushNamed(context, CreateTeamScreen.route);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _QuickActionTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color accent;
  final Color iconColor;
  final VoidCallback onTap;

  const _QuickActionTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.accent,
    required this.iconColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: accent,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(icon, color: iconColor),
              ),
              const SizedBox(width: 13),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title,
                        style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(height: 3),
                    Text(
                      subtitle,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppTheme.textSecondary,
                          ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.arrow_forward_rounded,
                  size: 19, color: AppTheme.textSecondary),
            ],
          ),
        ),
      ),
    );
  }
}

/// Tournaments arrive in Phase 2; show the placeholder in the same design system.
class TournamentsPlaceholder extends StatelessWidget {
  const TournamentsPlaceholder({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Tournaments')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Card(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 68,
                    height: 68,
                    decoration: const BoxDecoration(
                      color: AppTheme.primaryContainer,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.emoji_events_rounded,
                        size: 32, color: AppTheme.primary),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Tournaments are on the way',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Points tables, net run rate and brackets are planned for a future release.',
                    textAlign: TextAlign.center,
                    style: Theme.of(context)
                        .textTheme
                        .bodyMedium
                        ?.copyWith(color: AppTheme.textSecondary),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
