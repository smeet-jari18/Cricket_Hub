import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/app_theme.dart';
import '../../models/match_model.dart';
import '../../services/match_service.dart';
import '../../widgets/live_match_card.dart';
import '../match/live_match_screen.dart';

/// Screen 1 of UI/UX wireframes: Home.
/// "Live Now" carousel + upcoming matches list.
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final matchService = context.read<MatchService>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('CricketHub'),
        actions: const [
          Padding(
            padding: EdgeInsets.only(right: 16),
            child: Icon(Icons.notifications_none),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {}, // Firestore streams auto-refresh
        child: StreamBuilder<List<CricketMatch>>(
          stream: matchService.matchesStream(),
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              return const Center(child: Text('Something went wrong.'));
            }
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            final matches = snapshot.data ?? [];
            final liveMatches =
                matches.where((m) => m.isLive).toList();
            final otherMatches =
                matches.where((m) => !m.isLive).toList();

            if (matches.isEmpty) {
              // Empty state from UI/UX Guidelines.
              return const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.sports_cricket,
                        size: 72, color: AppTheme.textSecondary),
                    SizedBox(height: 16),
                    Text('No live action right now.',
                        style: TextStyle(fontSize: 18)),
                    SizedBox(height: 8),
                    Text('Start a match or browse past games!',
                        style: TextStyle(color: AppTheme.textSecondary)),
                  ],
                ),
              );
            }

            return ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.only(bottom: 96),
              children: [
                if (liveMatches.isNotEmpty) ...[
                  const _SectionHeader('🔴 Live Now'),
                  SizedBox(
                    height: 150,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      itemCount: liveMatches.length,
                      itemBuilder: (context, i) {
                        final m = liveMatches[i];
                        return LiveMatchCard(
                          match: m,
                          width: 280,
                          onTap: () => Navigator.pushNamed(
                            context,
                            LiveMatchScreen.route,
                            arguments: m.id,
                          ),
                        );
                      },
                    ),
                  ),
                ],
                const _SectionHeader('All Matches'),
                ...otherMatches.map(
                  (m) => Card(
                    child: ListTile(
                      title: Text('${m.teamAName} vs ${m.teamBName}',
                          style: const TextStyle(fontWeight: FontWeight.bold)),
                      subtitle: Text(
                          '${m.totalOvers} overs • ${_statusText(m.status)}'),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () => Navigator.pushNamed(
                        context,
                        LiveMatchScreen.route,
                        arguments: m.id,
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  String _statusText(String status) {
    switch (status) {
      case 'live':
        return 'LIVE';
      case 'completed':
        return 'Completed';
      case 'abandoned':
        return 'Abandoned';
      default:
        return 'Scheduled';
    }
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader(this.title);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
      child: Text(title,
          style: const TextStyle(
              fontSize: 18, fontWeight: FontWeight.bold)),
    );
  }
}
