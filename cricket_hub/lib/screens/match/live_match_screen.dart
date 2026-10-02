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
                // ---- Sticky live score card ----
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
                  child: Card(
                    child: Padding(
                      padding: const EdgeInsets.all(18),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  '${match.teamAName}  vs  ${match.teamBName}',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: Theme.of(context).textTheme.titleSmall
                                      ?.copyWith(color: AppTheme.textSecondary),
                                ),
                              ),
                              const SizedBox(width: 8),
                              _MatchStatusPill(isLive: match.isLive),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                '${match.venueRuns}/${match.venueWickets}',
                                style: Theme.of(context).textTheme.displayMedium
                                    ?.copyWith(fontSize: 42, height: 1),
                              ),
                              const SizedBox(width: 10),
                              Padding(
                                padding: const EdgeInsets.only(bottom: 5),
                                child: Text(
                                  '${_oversDisplay(match)} overs',
                                  style: Theme.of(context).textTheme.bodyMedium
                                      ?.copyWith(color: AppTheme.textSecondary),
                                ),
                              ),
                              const Spacer(),
                              const Icon(Icons.sports_cricket,
                                  color: AppTheme.primary, size: 26),
                            ],
                          ),
                          const SizedBox(height: 10),
                          const Divider(height: 1),
                          const SizedBox(height: 10),
                          Row(
                            children: [
                              const Icon(Icons.bolt_rounded,
                                  color: AppTheme.primary, size: 16),
                              const SizedBox(width: 6),
                              Text(
                                '${match.totalOvers}-over match',
                                style: Theme.of(context).textTheme.labelMedium
                                    ?.copyWith(color: AppTheme.textSecondary),
                              ),
                              const Spacer(),
                              Text(
                                match.isCompleted
                                    ? 'Final score'
                                    : match.isLive
                                        ? 'Updating live'
                                        : 'Scheduled',
                                style: Theme.of(context).textTheme.labelMedium
                                    ?.copyWith(color: AppTheme.textSecondary),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
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

  String _oversDisplay(CricketMatch match) {
    final balls = match.ballsBowled;
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
              margin: const EdgeInsets.only(bottom: 10),
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: isWicket
                      ? AppTheme.danger
                      : ball.runs == 4
                          ? AppTheme.boundaryFour
                          : ball.runs == 6
                              ? AppTheme.boundarySix
                              : AppTheme.primaryContainer,
                  child: Text(
                    isWicket ? 'W' : '${ball.runs}',
                    style: TextStyle(
                      color: isWicket || ball.runs == 6
                          ? Colors.white
                          : AppTheme.textPrimary,
                      fontWeight: FontWeight.w800,
                    ),
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

class _MatchStatusPill extends StatelessWidget {
  final bool isLive;

  const _MatchStatusPill({required this.isLive});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: isLive ? const Color(0xFFFFE4E3) : AppTheme.primaryContainer,
        borderRadius: BorderRadius.circular(99),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.circle,
            size: 7,
            color: isLive ? AppTheme.danger : AppTheme.primary,
          ),
          const SizedBox(width: 5),
          Text(
            isLive ? 'LIVE' : 'MATCH',
            style: TextStyle(
              color: isLive ? const Color(0xFFB42318) : AppTheme.primary,
              fontSize: 10,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }
}
