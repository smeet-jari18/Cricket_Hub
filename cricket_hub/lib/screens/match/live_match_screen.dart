import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/app_theme.dart';
import '../../models/ball_event.dart';
import '../../models/match_model.dart';
import '../../providers/auth_provider.dart';
import '../../services/match_service.dart';
import '../../services/notification_service.dart';

/// Live Match Center: score summary, innings scorecards, commentary and
/// per-match push-notification follow controls.
class LiveMatchScreen extends StatelessWidget {
  const LiveMatchScreen({super.key});

  static const String route = '/live-match';

  @override
  Widget build(BuildContext context) {
    final matchId = ModalRoute.of(context)?.settings.arguments as String?;
    if (matchId == null || matchId.isEmpty) {
      return const Scaffold(body: Center(child: Text('Match not found')));
    }
    final matchService = context.read<MatchService>();
    final uid = context.watch<AuthProvider>().firebaseUser?.uid ?? '';
    final notifications = context.read<NotificationService>();

    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Match Center'),
          actions: [
            if (uid.isNotEmpty)
              StreamBuilder<bool>(
                stream: notifications.followingMatchStream(uid, matchId),
                builder: (context, snapshot) {
                  final isFollowing = snapshot.data ?? false;
                  return IconButton(
                    tooltip: isFollowing ? 'Turn off match alerts' : 'Follow match alerts',
                    onPressed: () => _toggleFollow(
                      context,
                      notifications: notifications,
                      uid: uid,
                      matchId: matchId,
                      isFollowing: isFollowing,
                    ),
                    icon: Icon(isFollowing
                        ? Icons.notifications_active_rounded
                        : Icons.notifications_none_rounded),
                  );
                },
              ),
          ],
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
            if (matchSnap.connectionState == ConnectionState.waiting &&
                !matchSnap.hasData) {
              return const Center(child: CircularProgressIndicator());
            }
            if (matchSnap.hasError) {
              return const Center(child: Text('Couldn’t load the match.'));
            }
            final match = matchSnap.data;
            if (match == null) return const Center(child: Text('Match not found'));

            return Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
                  child: _LiveScoreHeader(match: match),
                ),
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

  Future<void> _toggleFollow(
    BuildContext context, {
    required NotificationService notifications,
    required String uid,
    required String matchId,
    required bool isFollowing,
  }) async {
    try {
      if (isFollowing) {
        await notifications.unfollowMatch(uid: uid, matchId: matchId);
      } else {
        await notifications.followMatch(uid: uid, matchId: matchId);
      }
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(isFollowing
              ? 'Match alerts turned off.'
              : 'You’ll be notified when this match starts or a wicket falls.'),
        ),
      );
    } catch (error) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not update match alerts: $error')),
      );
    }
  }
}

class _LiveScoreHeader extends StatelessWidget {
  final CricketMatch match;

  const _LiveScoreHeader({required this.match});

  @override
  Widget build(BuildContext context) {
    final overs = '${match.ballsBowled ~/ 6}.${match.ballsBowled % 6}';
    final statusColor = match.isLive ? AppTheme.danger : AppTheme.primary;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(17),
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
                    style: Theme.of(context)
                        .textTheme
                        .titleSmall
                        ?.copyWith(color: AppTheme.textSecondary),
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
                  decoration: BoxDecoration(
                    color: match.isLive ? const Color(0xFFFFE4E3) : AppTheme.primaryContainer,
                    borderRadius: BorderRadius.circular(99),
                  ),
                  child: Text(
                    match.isLive
                        ? 'LIVE'
                        : match.isCompleted
                            ? 'FINAL'
                            : match.status.toUpperCase(),
                    style: TextStyle(color: statusColor, fontSize: 10, fontWeight: FontWeight.w800),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 11),
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        match.currentBattingTeamName.toUpperCase(),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                              color: AppTheme.textSecondary,
                              letterSpacing: 0.6,
                            ),
                      ),
                      const SizedBox(height: 1),
                      Text(
                        '${match.venueRuns}/${match.venueWickets}',
                        style: Theme.of(context)
                            .textTheme
                            .displayMedium
                            ?.copyWith(fontSize: 40, height: 1.05),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(bottom: 5),
                  child: Text('$overs / ${match.totalOvers} ov',
                      style: Theme.of(context)
                          .textTheme
                          .bodyMedium
                          ?.copyWith(color: AppTheme.textSecondary)),
                ),
              ],
            ),
            if (match.resultText.isNotEmpty) ...[
              const SizedBox(height: 10),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 9),
                decoration: BoxDecoration(
                  color: AppTheme.primaryContainer,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  match.resultText,
                  style: const TextStyle(color: AppTheme.primary, fontWeight: FontWeight.w700),
                ),
              ),
            ] else ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(Icons.bolt_rounded, color: AppTheme.primary, size: 16),
                  const SizedBox(width: 6),
                  Text('${match.totalOvers}-over match',
                      style: Theme.of(context).textTheme.labelMedium?.copyWith(
                            color: AppTheme.textSecondary,
                          )),
                  const Spacer(),
                  Text(
                    match.isLive ? 'Updating live' : 'Follow for match alerts',
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: AppTheme.textSecondary,
                        ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _SummaryTab extends StatelessWidget {
  const _SummaryTab();

  @override
  Widget build(BuildContext context) {
    final matchId = ModalRoute.of(context)?.settings.arguments as String?;
    final service = context.read<MatchService>();
    if (matchId == null) return const SizedBox.shrink();
    return StreamBuilder<CricketMatch?>(
      stream: service.matchStream(matchId),
      builder: (context, snapshot) {
        final match = snapshot.data;
        if (match == null) return const SizedBox.shrink();
        return StreamBuilder<List<BallEvent>>(
          stream: service.ballsStream(matchId),
          builder: (context, ballSnapshot) {
            final balls = ballSnapshot.data ?? const <BallEvent>[];
            final innings = match.innings;
            final recent = balls.take(8).toList().reversed.toList();
            return ListView(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 22),
              children: [
                if (innings.isNotEmpty) ...[
                  Text('Innings summary', style: Theme.of(context).textTheme.titleLarge),
                  const SizedBox(height: 10),
                  ...innings.map((item) => _InningsSummaryCard(innings: item)),
                  const SizedBox(height: 15),
                ],
                Text('Recent balls', style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: 9),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(14),
                    child: recent.isEmpty
                        ? const Text('No balls recorded yet.',
                            style: TextStyle(color: AppTheme.textSecondary))
                        : Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: recent.map((ball) => _BallToken(ball: ball)).toList(),
                          ),
                  ),
                ),
                const SizedBox(height: 14),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(15),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(Icons.notifications_active_outlined, color: AppTheme.primary),
                        const SizedBox(width: 11),
                        Expanded(
                          child: Text(
                            'Follow this match from the bell above to get a push alert when play starts or a wicket falls.',
                            style: Theme.of(context)
                                .textTheme
                                .bodySmall
                                ?.copyWith(color: AppTheme.textSecondary, height: 1.4),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }
}

class _InningsSummaryCard extends StatelessWidget {
  final Map<String, dynamic> innings;

  const _InningsSummaryCard({required this.innings});

  @override
  Widget build(BuildContext context) {
    final name = (innings['team_name'] ?? 'Team') as String;
    final runs = _int(innings['runs']);
    final wickets = _int(innings['wickets']);
    final balls = _int(innings['legal_balls']);
    final batting = _asMaps(innings['batting']);
    final topScorer = batting.isEmpty
        ? 'No batting figures'
        : batting.reduce((a, b) => _int(a['runs']) >= _int(b['runs']) ? a : b);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(15),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(name, style: Theme.of(context).textTheme.titleSmall),
                  const SizedBox(height: 5),
                  Text('${_int(topScorer is Map ? topScorer['runs'] : null)} · ${topScorer is Map ? (topScorer['name'] ?? 'Top scorer') : topScorer}',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppTheme.textSecondary)),
                ],
              ),
            ),
            Text('$runs/$wickets',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(color: AppTheme.primary)),
            const SizedBox(width: 9),
            Text('${balls ~/ 6}.${balls % 6} ov',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppTheme.textSecondary)),
          ],
        ),
      ),
    );
  }
}

class _ScorecardTab extends StatelessWidget {
  const _ScorecardTab();

  @override
  Widget build(BuildContext context) {
    final matchId = ModalRoute.of(context)?.settings.arguments as String?;
    final service = context.read<MatchService>();
    if (matchId == null) return const SizedBox.shrink();
    return StreamBuilder<CricketMatch?>(
      stream: service.matchStream(matchId),
      builder: (context, matchSnapshot) {
        final match = matchSnapshot.data;
        if (match == null) return const Center(child: CircularProgressIndicator());
        if (match.innings.isEmpty) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(28),
              child: Text('The scorecard will fill in as innings are completed.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: AppTheme.textSecondary)),
            ),
          );
        }
        return StreamBuilder<List<BallEvent>>(
          stream: service.allBallsStream(matchId),
          builder: (context, ballSnapshot) {
            final balls = ballSnapshot.data ?? const <BallEvent>[];
            return ListView(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 24),
              children: [
                for (final innings in match.innings)
                  _InningsScorecard(
                    innings: innings,
                    balls: balls.where((ball) => ball.inningsNumber == _int(innings['innings_number'])).toList(),
                  ),
              ],
            );
          },
        );
      },
    );
  }
}

class _InningsScorecard extends StatelessWidget {
  final Map<String, dynamic> innings;
  final List<BallEvent> balls;

  const _InningsScorecard({required this.innings, required this.balls});

  @override
  Widget build(BuildContext context) {
    final batting = _asMaps(innings['batting']);
    final bowling = _asMaps(innings['bowling']);
    final number = _int(innings['innings_number']);
    final runs = _int(innings['runs']);
    final wickets = _int(innings['wickets']);
    final legalBalls = _int(innings['legal_balls']);
    final extras = <String, int>{'wide': 0, 'no_ball': 0, 'bye': 0, 'leg_bye': 0};
    for (final ball in balls) {
      if (extras.containsKey(ball.extraType)) {
        extras[ball.extraType] = extras[ball.extraType]! + ball.extraRuns;
      }
    }
    final extrasTotal = extras.values.fold<int>(0, (sum, value) => sum + value);
    final fallOfWickets = balls.where((ball) => ball.isWicket).toList()
      ..sort((a, b) => a.sequence.compareTo(b.sequence));

    return Card(
      margin: const EdgeInsets.only(bottom: 14),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 14, 14, 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Innings $number · ${(innings['team_name'] ?? 'Team') as String}',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ),
                Text('$runs/$wickets',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(color: AppTheme.primary)),
              ],
            ),
            const SizedBox(height: 3),
            Text('${legalBalls ~/ 6}.${legalBalls % 6} overs',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppTheme.textSecondary)),
            const SizedBox(height: 12),
            _ScoreTable(
              headings: const ['BATTER', 'R', 'B', '4s', '6s', 'SR'],
              rows: batting.map((batter) {
                final batRuns = _int(batter['runs']);
                final ballsFaced = _int(batter['balls']);
                final howOut = (batter['how_out'] ?? '') as String;
                final dismissal = batter['out'] == true
                    ? (howOut.isEmpty ? 'out' : howOut)
                    : 'not out';
                final strikeRate = ballsFaced == 0 ? '0.0' : (batRuns * 100 / ballsFaced).toStringAsFixed(1);
                return [
                  '${(batter['name'] ?? 'Batter') as String}\n$dismissal',
                  '$batRuns',
                  '$ballsFaced',
                  '${_int(batter['fours'])}',
                  '${_int(batter['sixes'])}',
                  strikeRate,
                ];
              }).toList(),
            ),
            const SizedBox(height: 10),
            _ScoreLine(
              label: 'Extras',
              value: '$extrasTotal  (WD ${extras['wide']}, NB ${extras['no_ball']}, B ${extras['bye']}, LB ${extras['leg_bye']})',
            ),
            _ScoreLine(label: 'Total', value: '$runs/$wickets  (${legalBalls ~/ 6}.${legalBalls % 6} ov)', bold: true),
            const SizedBox(height: 15),
            Text('Bowling', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 7),
            _ScoreTable(
              headings: const ['BOWLER', 'O', 'R', 'W', 'ECON'],
              rows: bowling.map((bowler) {
                final ballsBowled = _int(bowler['legal_balls']);
                final runsConceded = _int(bowler['runs_conceded']);
                final economy = ballsBowled == 0 ? '0.00' : (runsConceded * 6 / ballsBowled).toStringAsFixed(2);
                return [
                  (bowler['name'] ?? 'Bowler') as String,
                  '${ballsBowled ~/ 6}.${ballsBowled % 6}',
                  '$runsConceded',
                  '${_int(bowler['wickets'])}',
                  economy,
                ];
              }).toList(),
            ),
            if (fallOfWickets.isNotEmpty) ...[
              const SizedBox(height: 14),
              Text('Fall of wickets', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 6),
              Wrap(
                spacing: 7,
                runSpacing: 7,
                children: fallOfWickets.map((ball) => Chip(
                      visualDensity: VisualDensity.compact,
                      avatar: const Icon(Icons.close_rounded, size: 15, color: AppTheme.danger),
                      label: Text('${ball.wicketsAfter}-${ball.scoreAfter} · ${ball.overDisplay}'),
                    )).toList(),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _ScoreTable extends StatelessWidget {
  final List<String> headings;
  final List<List<String>> rows;

  const _ScoreTable({required this.headings, required this.rows});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: DataTable(
        columnSpacing: 14,
        horizontalMargin: 0,
        headingRowHeight: 30,
        dataRowMinHeight: 40,
        dataRowMaxHeight: 54,
        columns: headings
            .map((heading) => DataColumn(
                  label: Text(heading,
                      style: const TextStyle(fontSize: 9, fontWeight: FontWeight.w800, color: AppTheme.textSecondary)),
                ))
            .toList(),
        rows: rows.map((values) => DataRow(
              cells: values.map((value) => DataCell(
                SizedBox(
                  width: value.contains('\n') ? 112 : null,
                  child: Text(value,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 11)),
                ),
              )).toList(),
            )).toList(),
      ),
    );
  }
}

class _ScoreLine extends StatelessWidget {
  final String label;
  final String value;
  final bool bold;

  const _ScoreLine({required this.label, required this.value, this.bold = false});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Expanded(
            child: Text(label,
                style: TextStyle(
                  color: bold ? AppTheme.textPrimary : AppTheme.textSecondary,
                  fontWeight: bold ? FontWeight.w800 : FontWeight.w500,
                  fontSize: 12,
                )),
          ),
          Text(value,
              style: TextStyle(
                fontWeight: bold ? FontWeight.w800 : FontWeight.w600,
                fontSize: 12,
              )),
        ],
      ),
    );
  }
}

class _CommentaryTab extends StatelessWidget {
  const _CommentaryTab();

  @override
  Widget build(BuildContext context) {
    final matchId = ModalRoute.of(context)?.settings.arguments as String?;
    if (matchId == null) return const SizedBox.shrink();
    final service = context.read<MatchService>();
    return StreamBuilder<List<BallEvent>>(
      stream: service.ballsStream(matchId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting && !snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        final balls = snapshot.data ?? const <BallEvent>[];
        if (balls.isEmpty) {
          return const Center(
            child: Text('No balls yet — waiting for the first over!',
                style: TextStyle(color: AppTheme.textSecondary)),
          );
        }
        return ListView.builder(
          padding: const EdgeInsets.all(12),
          itemCount: balls.length,
          itemBuilder: (context, index) {
            final ball = balls[index];
            final isBoundary = !ball.isWicket && (ball.runs == 4 || ball.runs == 6);
            final eventLabel = ball.isWicket
                ? 'WICKET! ${ball.playerOut} (${ball.wicketType})'
                : ball.extraType == 'wide'
                    ? 'Wide ball · ${ball.runs} run${ball.runs == 1 ? '' : 's'}'
                    : ball.extraType == 'no_ball'
                        ? 'No-ball · ${ball.runs} run${ball.runs == 1 ? '' : 's'}'
                        : ball.extraType.isNotEmpty
                            ? '${ball.extraType.replaceAll('_', ' ')} · ${ball.runs} run${ball.runs == 1 ? '' : 's'}'
                            : isBoundary
                                ? '${ball.runs} runs!'
                                : '${ball.runs} run${ball.runs == 1 ? '' : 's'}';
            return Card(
              margin: const EdgeInsets.only(bottom: 9),
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: ball.isWicket
                      ? AppTheme.danger
                      : ball.runs == 4
                          ? AppTheme.boundaryFour
                          : ball.runs == 6
                              ? AppTheme.boundarySix
                              : AppTheme.primaryContainer,
                  child: Text(
                    ball.isWicket ? 'W' : '${ball.runs}',
                    style: TextStyle(
                      color: ball.isWicket || ball.runs == 6 ? Colors.white : AppTheme.textPrimary,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                title: Text(eventLabel, style: const TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Text(
                  'Inn ${ball.inningsNumber} · ${ball.overDisplay} · ${ball.bowlerName} to ${ball.strikerName}',
                ),
              ),
            );
          },
        );
      },
    );
  }
}

class _BallToken extends StatelessWidget {
  final BallEvent ball;

  const _BallToken({required this.ball});

  @override
  Widget build(BuildContext context) {
    final color = ball.isWicket
        ? AppTheme.danger
        : ball.runs == 4
            ? AppTheme.boundaryFour
            : ball.runs == 6
                ? AppTheme.boundarySix
                : AppTheme.primaryContainer;
    return Container(
      width: 42,
      height: 42,
      alignment: Alignment.center,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
      child: Text(
        ball.isWicket ? 'W' : ball.extraType.isNotEmpty ? _extraLabel(ball) : '${ball.runs}',
        style: TextStyle(
          color: ball.isWicket || ball.runs == 6 ? Colors.white : AppTheme.textPrimary,
          fontWeight: FontWeight.w800,
          fontSize: ball.extraType.isNotEmpty ? 10 : 14,
        ),
      ),
    );
  }

  String _extraLabel(BallEvent ball) {
    switch (ball.extraType) {
      case 'wide':
        return 'WD';
      case 'no_ball':
        return 'NB';
      case 'leg_bye':
        return 'LB';
      case 'bye':
        return 'B';
      default:
        return 'EX';
    }
  }
}

List<Map<String, dynamic>> _asMaps(Object? value) {
  if (value is! Iterable) return const [];
  return value.whereType<Map>().map((entry) => Map<String, dynamic>.from(entry)).toList();
}

int _int(Object? value) => value is num ? value.toInt() : int.tryParse('$value') ?? 0;
