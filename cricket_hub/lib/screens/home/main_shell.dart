import 'package:flutter/material.dart';

import '../match/create_match_screen.dart';
import '../menu/menu_screen.dart';
import '../team/create_team_screen.dart';
import 'home_screen.dart';
import 'my_cricket_screen.dart';

/// Bottom Navigation Bar (UI/UX doc): Home | My Cricket | Tournaments | Menu
/// Tournaments tab is a Phase 2 placeholder.
class MainShell extends StatefulWidget {
  const MainShell({super.key});

  static const String route = '/home';

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _index = 0;

  final _pages = const [
    HomeScreen(),
    MyCricketScreen(),
    TournamentsPlaceholder(),
    MenuScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _index, children: _pages),
      // Big primary FAB -> quick actions (Start Match / Create Team)
      floatingActionButton: _index == 0 || _index == 1
          ? FloatingActionButton.extended(
              heroTag: 'quickActions',
              onPressed: () => _showQuickActions(context),
              icon: const Icon(Icons.add),
              label: const Text('Create'),
            )
          : null,
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _index,
        onTap: (i) => setState(() => _index = i),
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(
              icon: Icon(Icons.sports_cricket), label: 'My Cricket'),
          BottomNavigationBarItem(icon: Icon(Icons.emoji_events), label: 'Tours'),
          BottomNavigationBarItem(icon: Icon(Icons.menu), label: 'Menu'),
        ],
      ),
    );
  }

  void _showQuickActions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 8),
            ListTile(
              leading: const Icon(Icons.play_circle_fill,
                  color: AppThemeIcon.primary),
              title: const Text('Start a Match',
                  style: TextStyle(fontWeight: FontWeight.bold)),
              subtitle: const Text('Set up teams, toss and start scoring'),
              onTap: () {
                Navigator.pop(context);
                Navigator.pushNamed(context, CreateMatchScreen.route);
              },
            ),
            ListTile(
              leading:
                  const Icon(Icons.groups, color: AppThemeIcon.primary),
              title: const Text('Create a Team',
                  style: TextStyle(fontWeight: FontWeight.bold)),
              subtitle: const Text('Build your squad'),
              onTap: () {
                Navigator.pop(context);
                Navigator.pushNamed(context, CreateTeamScreen.route);
              },
            ),
          ],
        ),
      ),
    );
  }
}

/// Tournaments arrive in Phase 2 (per PRD Release Plan).
class TournamentsPlaceholder extends StatelessWidget {
  const TournamentsPlaceholder({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Tournaments')),
      body: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.emoji_events,
                size: 72, color: AppThemeIcon.textSecondary),
            SizedBox(height: 16),
            Text('Tournaments are coming in Phase 2!',
                style: TextStyle(fontSize: 18)),
            SizedBox(height: 8),
            const Text('Points tables, NRR and brackets.\nAlready fully planned in the PRD.',
                textAlign: TextAlign.center,
                style: const TextStyle(color: AppThemeIcon.textSecondary)),
          ],
        ),
      ),
    );
  }
}

/// Small color alias so the files above stay readable.
class AppThemeIcon {
  static const Color primary = Color(0xFF00BFA5);
  static const Color textSecondary = Color(0xFFA0A0A0);
}
