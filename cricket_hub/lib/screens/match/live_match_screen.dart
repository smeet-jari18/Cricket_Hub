import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/app_theme.dart';
import '../../models/match_model.dart';
import '../../services/match_service.dart';

/// Screen 3 of UI/UX wireframes: Live Match Center (for fans).
/// Sticky header score + 3 tabs: Summary | Scorecard | Commentary.
/// Updates in real time via Firestore snapshot listener (<2s target).
class LiveMatchScreen extends StatelessWidget {
  const LiveMatchScreen({super.key});

  static const String route = '/live-match';

  @override
  Widget build(BuildContext context) {
    final matchId = ModalRoute.of(context)?.settings.arguments as String?;
    if (matchId == null) {
      return const Scaffold(body: Center(child: Text('Match not found')));
    }

    final matchService = context.read<MatchService>();

    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Match Center'),
          bottom: const TabBar(
            indicatorColor: AppTheme.primary,
            tabs: [
              Tab(text: 'Summary'),
              Tab(text: 'Scorecard'),
              Tab(text: 'Commentary'),
            ],
          ),
        ),
        body: StreamBuilder<CricketMatch?>(
          stream: matchService.matchStream(matchId),
          builder: (context, matchSnap) {
            if (matchSnap.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            final match = matchSnap.data;
            if (match == null) {
              return const Center(child: Text('Match not found'));
            }

            return Column(
              children: [
                // ---- Sticky live header ----
                Container(
                  width: double.infinity,
                  color: AppTheme.surface,
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      Text(
                        '${match.teamAName} vs ${match.teamBName}',
                        style: const TextStyle(
                            color: AppTheme.textSecondary, fontSize: 13),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        '${match.venueRuns}/${match.venueWickets}',
                        style: const TextStyle(
                            fontSize: 48, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '$_oversDisplay(match) ov  •  ${match.status.toUpperCase()}',
                        style: const TextStyle(color: AppTheme.textSecondary),
                      ),
                      if (match.isLive)
                        const Padding(
                          padding: EdgeInsets.only(top: 8),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.circle,
                                  color: AppTheme.danger, size: 10),
                              SizedBox(width: 6),
                              Text('LIVE',
                                  style: TextStyle(
                                      color: AppTheme.danger,
                                      fontWeight: FontWeight.bold,
                                      letterSpacing: 2)),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),

                // ---- Tabs content ----
                const Expanded(
                  child: TabBarView(
                    children: [
                      _SummaryTab(),
                      _ScorecardTab(),
                      _CommentaryTab(),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  String _oversDisplay(match) {
    final balls = match.ballsBowled as int;
    return '${balls ~/ 6}.${balls % 6}';
  }
}

// ---------------- TAB 1: SUMMARY ----------------
class _SummaryTab extends StatelessWidget {
  const _SummaryTab();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.speed, size: 56, color: AppTheme.textSecondary),
            SizedBox(height: 12),
            Text(
              'Batsmen stats, partnership graph and recent balls\n'
              'appear here when the match is live.\n\n'
              '(Batsmen-level live data lands in Sprint 4 — '
              'the score header is already real-time!)',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppTheme.textSecondary, height: 1.6),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------- TAB 2: SCORECARD ----------------
class _ScorecardTab extends StatelessWidget {
  const _ScorecardTab();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.table_chart, size: 56, color: AppTheme.textSecondary),
            SizedBox(height: 12),
            Text(
              'Full batting & bowling card with fall of wickets\n'
              'is generated after Cloud Functions aggregate stats (Phase 2).',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppTheme.textSecondary, height: 1.6),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------- TAB 3: COMMENTARY ----------------
class _CommentaryTab extends StatelessWidget {
  const _CommentaryTab();

  @override
  Widget build(BuildContext context) {
    final matchId = ModalRoute.of(context)?.settings.arguments as String?;
    final matchService = context.read<MatchService>();

    return StreamBuilder(
      stream: matchService.ballsStream(matchId!),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        final balls = snapshot.data ?? const [];
        if (balls.isEmpty) {
          return const Center(
            child: Text('No balls yet — waiting for the first over!',
                style: TextStyle(color: AppTheme.textSecondary)),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(12),
          itemCount: balls.length,
          itemBuilder: (context, i) {
            final ball = balls[i] as dynamic;
            final isWicket = ball.wicketType != null && (ball.wicketType as String).isNotEmpty;
            final isBoundary = !isWicket && (ball.runs == 4 || ball.runs == 6);

            return Card(
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: isWicket
                      ? AppTheme.danger
                      : isBoundary
                          ? AppTheme.accent
                          : AppTheme.primary,
                  child: Text(
                    isWicket
                        ? 'W'
                        : '${ball.runs}',
                    style: const TextStyle(
                        color: AppTheme.background,
                        fontWeight: FontWeight.bold),
                  ),
                ),
                title: Text(
                  isWicket
                      ? 'WICKET! ${ball.playerOut} (${ball.wicketType})'
                      : isBoundary
                          ? '${ball.runs} runs!'
                          : '${ball.runs} run${ball.runs == 1 ? '' : 's'}',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: Text(
                  'Over ${ball.overNumber}.${ball.ballInOver} • '
                  '${ball.bowlerName} to ${ball.strikerName}'
                  '${ball.extraType != null && (ball.extraType as String).isNotEmpty ? " (${ball.extraType})" : ""}',
                ),
              ),
            );
          },
        );
      },
    );
  }
}
