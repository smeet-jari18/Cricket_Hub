import 'dart:ui' show FontFeature;

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../core/app_theme.dart';
import '../../models/match_model.dart';
import '../../models/team_model.dart';
import '../../models/tournament_model.dart';
import '../../providers/auth_provider.dart';
import '../../services/match_service.dart';
import '../../services/team_service.dart';
import '../../services/tournament_service.dart';
import '../match/live_match_screen.dart';
import '../match/toss_screen.dart';
import '../team/create_team_screen.dart';

class TournamentDetailScreen extends StatelessWidget {
  const TournamentDetailScreen({super.key});

  static const String route = '/tournament-detail';

  @override
  Widget build(BuildContext context) {
    final tournamentId = ModalRoute.of(context)?.settings.arguments as String?;
    if (tournamentId == null || tournamentId.isEmpty) {
      return const Scaffold(body: Center(child: Text('Tournament not found')));
    }

    final service = context.read<TournamentService>();
    return DefaultTabController(
      length: 4,
      child: Scaffold(
        appBar: AppBar(
          title: StreamBuilder<Tournament?>(
            stream: service.tournamentStream(tournamentId),
            builder: (context, snapshot) => Text(
              snapshot.data?.name ?? 'Tournament',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          bottom: const TabBar(
            isScrollable: true,
            indicatorColor: AppTheme.primary,
            tabs: [
              Tab(text: 'Overview'),
              Tab(text: 'Fixtures'),
              Tab(text: 'Points'),
              Tab(text: 'Leaders'),
            ],
          ),
        ),
        body: StreamBuilder<Tournament?>(
          stream: service.tournamentStream(tournamentId),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting &&
                !snapshot.hasData) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError) {
              return const _MessageState(
                icon: Icons.cloud_off_outlined,
                title: 'Couldn’t load this tournament',
                subtitle: 'Check your connection and try again.',
              );
            }
            final tournament = snapshot.data;
            if (tournament == null) {
              return const _MessageState(
                icon: Icons.search_off_rounded,
                title: 'Tournament not found',
                subtitle: 'It may have been removed by its organizer.',
              );
            }
            return TabBarView(
              children: [
                _OverviewTab(tournament: tournament),
                _FixturesTab(tournament: tournament),
                _PointsTableTab(tournament: tournament),
                _LeadersTab(tournament: tournament),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _OverviewTab extends StatefulWidget {
  final Tournament tournament;

  const _OverviewTab({required this.tournament});

  @override
  State<_OverviewTab> createState() => _OverviewTabState();
}

class _OverviewTabState extends State<_OverviewTab> {
  bool _savingTeams = false;
  bool _generating = false;

  Tournament get tournament => widget.tournament;

  @override
  Widget build(BuildContext context) {
    final uid = context.watch<AuthProvider>().firebaseUser?.uid ?? '';
    final isAdmin = tournament.isAdmin(uid);
    final dateLabel = _dateRange(tournament);
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 28),
      children: [
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF006B5C), Color(0xFF0B8F78)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(18),
          ),
          child: Row(
            children: [
              Container(
                width: 54,
                height: 54,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.14),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  tournament.isKnockout ? Icons.account_tree_rounded : Icons.sync_alt_rounded,
                  color: Colors.white,
                  size: 27,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      tournament.isKnockout ? 'KNOCKOUT' : 'ROUND ROBIN',
                      style: const TextStyle(
                        color: Color(0xFFD5F5EE),
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      tournament.name,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 21,
                        height: 1.2,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      '${tournament.location} · $dateLabel',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(color: Color(0xFFE1F2EE), fontSize: 12),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        Row(
          children: [
            Expanded(
              child: _MetricCard(
                label: 'TEAMS',
                value: '${tournament.teamIds.length}',
                icon: Icons.groups_rounded,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _MetricCard(
                label: 'FIXTURES',
                value: tournament.fixturesGenerated ? '${tournament.fixtureCount}' : '—',
                icon: Icons.event_note_rounded,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _MetricCard(
                label: 'OVERS',
                value: '${tournament.totalOvers}',
                icon: Icons.sports_cricket_rounded,
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text('Participating teams',
                          style: Theme.of(context).textTheme.titleLarge),
                    ),
                    if (isAdmin && !tournament.fixturesGenerated)
                      TextButton.icon(
                        onPressed: _savingTeams ? null : _editTeams,
                        icon: const Icon(Icons.edit_outlined, size: 17),
                        label: Text(tournament.teamIds.isEmpty ? 'Add teams' : 'Edit'),
                      ),
                  ],
                ),
                const SizedBox(height: 9),
                if (tournament.teams.isEmpty)
                  const Text(
                    'No teams added yet. Choose teams from your CricketHub team list to continue.',
                    style: TextStyle(color: AppTheme.textSecondary, height: 1.45),
                  )
                else
                  ...tournament.teams.map((team) {
                    final name = (team['name'] ?? team['team_name'] ?? 'Team') as String;
                    final city = (team['city'] ?? '') as String;
                    return ListTile(
                      contentPadding: EdgeInsets.zero,
                      dense: true,
                      leading: const CircleAvatar(
                        backgroundColor: AppTheme.primaryContainer,
                        child: Icon(Icons.shield_rounded, color: AppTheme.primary, size: 19),
                      ),
                      title: Text(name, style: Theme.of(context).textTheme.titleSmall),
                      subtitle: city.isEmpty ? null : Text(city),
                    );
                  }),
                if (isAdmin && !tournament.fixturesGenerated) ...[
                  const SizedBox(height: 8),
                  ElevatedButton.icon(
                    onPressed: _generating || tournament.teamIds.length < 2
                        ? null
                        : _generateFixtures,
                    icon: _generating
                        ? const SizedBox(
                            height: 18,
                            width: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(Icons.auto_awesome_rounded),
                    label: Text(_generating ? 'Building schedule…' : 'Generate fixtures'),
                  ),
                  if (tournament.teamIds.length < 2)
                    const Padding(
                      padding: EdgeInsets.only(top: 8),
                      child: Text(
                        'Add at least two teams before generating the schedule.',
                        style: TextStyle(color: AppTheme.textSecondary, fontSize: 12),
                      ),
                    ),
                ] else if (!tournament.fixturesGenerated)
                  const Padding(
                    padding: EdgeInsets.only(top: 7),
                    child: Text(
                      'The organizer is still preparing the team list and fixtures.',
                      style: TextStyle(color: AppTheme.textSecondary, fontSize: 12),
                    ),
                  ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 14),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Points configuration',
                    style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 9,
                  runSpacing: 8,
                  children: [
                    _RulePill('Win', tournament.pointsConfig['win'] ?? 2),
                    _RulePill('Tie', tournament.pointsConfig['tie'] ?? 1),
                    _RulePill('Loss', tournament.pointsConfig['loss'] ?? 0),
                    _RulePill('No result', tournament.pointsConfig['no_result'] ?? 1),
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  tournament.isRoundRobin
                      ? 'Standings are recalculated on the server from completed scorecards. Net Run Rate uses aggregate runs and legal balls; an all-out innings counts the full overs quota.'
                      : 'Winners advance automatically through the seeded bracket. A tied knockout fixture waits for the organizer to choose a winner.',
                  style: Theme.of(context)
                      .textTheme
                      .bodySmall
                      ?.copyWith(color: AppTheme.textSecondary, height: 1.45),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _editTeams() async {
    if (_savingTeams) return;
    setState(() => _savingTeams = true);
    try {
      final teamService = context.read<TeamService>();
      final service = context.read<TournamentService>();
      final current = tournament.teamIds.toSet();
      final selected = await showModalBottomSheet<List<Team>>(
        context: context,
        isScrollControlled: true,
        builder: (sheetContext) => _TeamPickerSheet(
          selectedIds: current,
          maxTeams: tournament.isKnockout ? 64 : 20,
          teamService: teamService,
        ),
      );
      if (selected == null || !mounted) return;
      await service.updateTournamentTeams(tournament.id, selected);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${selected.length} teams saved.')),
      );
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not save teams: $error')),
        );
      }
    } finally {
      if (mounted) setState(() => _savingTeams = false);
    }
  }

  Future<void> _generateFixtures() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Generate fixture schedule?'),
        content: Text(
          tournament.isKnockout
              ? 'CricketHub will build a seeded knockout bracket for ${tournament.teamIds.length} teams, including byes where needed. This cannot be edited after generation.'
              : 'CricketHub will create a single round-robin schedule for ${tournament.teamIds.length} teams. This cannot be edited after generation.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Not yet'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Generate'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    setState(() => _generating = true);
    try {
      final result = await context
          .read<TournamentService>()
          .generateFixtures(tournament.id);
      if (!mounted) return;
      final count = result['fixtureCount'] ?? tournament.fixtureCount;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Schedule ready · $count fixtures created.')),
      );
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not generate fixtures: $error')),
        );
      }
    } finally {
      if (mounted) setState(() => _generating = false);
    }
  }
}

class _TeamPickerSheet extends StatefulWidget {
  final Set<String> selectedIds;
  final int maxTeams;
  final TeamService teamService;

  const _TeamPickerSheet({
    required this.selectedIds,
    required this.maxTeams,
    required this.teamService,
  });

  @override
  State<_TeamPickerSheet> createState() => _TeamPickerSheetState();
}

class _TeamPickerSheetState extends State<_TeamPickerSheet> {
  late final Set<String> _selected = Set<String>.from(widget.selectedIds);

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;
    return SafeArea(
      child: SizedBox(
        height: MediaQuery.sizeOf(context).height * 0.78,
        child: Padding(
          padding: EdgeInsets.fromLTRB(18, 10, 18, 16 + bottomInset),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Choose tournament teams',
                  style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 4),
              Text(
                '${_selected.length}/${widget.maxTeams} selected · at least 2 required',
                style: Theme.of(context)
                    .textTheme
                    .bodySmall
                    ?.copyWith(color: AppTheme.textSecondary),
              ),
              const SizedBox(height: 12),
              Expanded(
                child: StreamBuilder<List<Team>>(
                  stream: widget.teamService.teamsStream(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting &&
                        !snapshot.hasData) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    if (snapshot.hasError) {
                      return const Center(child: Text('Couldn’t load teams.'));
                    }
                    final teams = snapshot.data ?? const <Team>[];
                    if (teams.isEmpty) {
                      return Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Text('Create a team before building your tournament.'),
                            const SizedBox(height: 12),
                            OutlinedButton.icon(
                              onPressed: () {
                                final navigator = Navigator.of(context);
                                navigator.pop();
                                navigator.pushNamed(CreateTeamScreen.route);
                              },
                              icon: const Icon(Icons.add_rounded),
                              label: const Text('Create team'),
                            ),
                          ],
                        ),
                      );
                    }
                    return ListView.builder(
                      itemCount: teams.length,
                      itemBuilder: (context, index) {
                        final team = teams[index];
                        final selected = _selected.contains(team.id);
                        final canAdd = _selected.length < widget.maxTeams;
                        return CheckboxListTile(
                          value: selected,
                          controlAffinity: ListTileControlAffinity.leading,
                          activeColor: AppTheme.primary,
                          contentPadding: EdgeInsets.zero,
                          title: Text(team.teamName),
                          subtitle: Text('${team.city} · ${team.roster.length} players'),
                          secondary: const Icon(Icons.shield_outlined, color: AppTheme.primary),
                          onChanged: (value) {
                            if (value == true && !canAdd) return;
                            setState(() {
                              if (value == true) {
                                _selected.add(team.id);
                              } else {
                                _selected.remove(team.id);
                              }
                            });
                          },
                        );
                      },
                    );
                  },
                ),
              ),
              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _selected.length < 2
                      ? null
                      : () async {
                          final teams = await widget.teamService.teamsStream().first;
                          if (!context.mounted) return;
                          Navigator.pop(
                            context,
                            teams.where((team) => _selected.contains(team.id)).toList(),
                          );
                        },
                  child: const Text('Save selected teams'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FixturesTab extends StatelessWidget {
  final Tournament tournament;

  const _FixturesTab({required this.tournament});

  @override
  Widget build(BuildContext context) {
    if (!tournament.fixturesGenerated) {
      return const _MessageState(
        icon: Icons.event_note_outlined,
        title: 'Fixtures aren’t ready yet',
        subtitle: 'The organizer can add teams and generate the schedule from Overview.',
      );
    }
    return StreamBuilder<List<TournamentFixture>>(
      stream: context.read<TournamentService>().fixturesStream(tournament.id),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting && !snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return const _MessageState(
            icon: Icons.cloud_off_outlined,
            title: 'Couldn’t load fixtures',
            subtitle: 'Check your connection and try again.',
          );
        }
        final fixtures = snapshot.data ?? const <TournamentFixture>[];
        if (fixtures.isEmpty) {
          return const _MessageState(
            icon: Icons.event_busy_outlined,
            title: 'No fixtures found',
            subtitle: 'Ask the organizer to regenerate the tournament schedule.',
          );
        }
        final grouped = <int, List<TournamentFixture>>{};
        for (final fixture in fixtures) {
          grouped.putIfAbsent(fixture.roundNumber, () => []).add(fixture);
        }
        final rounds = grouped.keys.toList()..sort();
        return ListView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
          children: [
            if (tournament.isKnockout)
              const Padding(
                padding: EdgeInsets.fromLTRB(4, 0, 4, 10),
                child: Text(
                  'Winners advance automatically. Fixtures marked TBD unlock when the previous round is complete.',
                  style: TextStyle(color: AppTheme.textSecondary, height: 1.4),
                ),
              ),
            for (final round in rounds) ...[
              Padding(
                padding: const EdgeInsets.fromLTRB(4, 11, 4, 8),
                child: Text(
                  _roundName(tournament, round, grouped[round]!),
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
              ...grouped[round]!.map((fixture) => Padding(
                    padding: const EdgeInsets.only(bottom: 9),
                    child: _FixtureCard(
                      tournament: tournament,
                      fixture: fixture,
                    ),
                  )),
            ],
          ],
        );
      },
    );
  }

  String _roundName(Tournament tournament, int round, List<TournamentFixture> fixtures) {
    final label = fixtures.isNotEmpty ? fixtures.first.roundName : 'Round $round';
    return tournament.isRoundRobin ? 'Round $round' : label;
  }
}

class _FixtureCard extends StatelessWidget {
  final Tournament tournament;
  final TournamentFixture fixture;

  const _FixtureCard({required this.tournament, required this.fixture});

  @override
  Widget build(BuildContext context) {
    if (fixture.status == 'bye' || fixture.isBye) {
      return Card(
        child: ListTile(
          leading: const CircleAvatar(
            backgroundColor: AppTheme.primaryContainer,
            child: Icon(Icons.skip_next_rounded, color: AppTheme.primary),
          ),
          title: Text(fixture.winnerTeamName ?? fixture.teamAName ?? fixture.teamBName ?? 'Team'),
          subtitle: Text('${fixture.roundName} · BYE — advances automatically'),
          trailing: const Icon(Icons.check_circle_outline, color: AppTheme.primary),
        ),
      );
    }
    if (fixture.status == 'empty') return const SizedBox.shrink();
    if (fixture.status == 'needs_tiebreak') {
      return _TieResolutionCard(tournament: tournament, fixture: fixture);
    }
    if (fixture.matchId.isEmpty) {
      return Card(
        child: ListTile(
          leading: CircleAvatar(
            backgroundColor: AppTheme.surfaceSoft,
            child: Text('${fixture.fixtureNumber}',
                style: const TextStyle(fontWeight: FontWeight.w800)),
          ),
          title: Text('${fixture.teamAName ?? 'TBD'}  vs  ${fixture.teamBName ?? 'TBD'}'),
          subtitle: Text('${fixture.roundName} · Waiting for previous result'),
          trailing: const Icon(Icons.lock_clock_outlined, color: AppTheme.textSecondary),
        ),
      );
    }
    return StreamBuilder<CricketMatch?>(
      stream: context.read<MatchService>().matchStream(fixture.matchId),
      builder: (context, snapshot) {
        final match = snapshot.data;
        if (match == null) {
          return Card(
            child: ListTile(
              title: Text('${fixture.teamAName ?? 'Team A'}  vs  ${fixture.teamBName ?? 'Team B'}'),
              subtitle: Text('${fixture.roundName} · Loading fixture'),
              trailing: const CircularProgressIndicator(strokeWidth: 2),
            ),
          );
        }
        return _ReadyFixtureCard(tournament: tournament, fixture: fixture, match: match);
      },
    );
  }
}

class _ReadyFixtureCard extends StatelessWidget {
  final Tournament tournament;
  final TournamentFixture fixture;
  final CricketMatch match;

  const _ReadyFixtureCard({
    required this.tournament,
    required this.fixture,
    required this.match,
  });

  @override
  Widget build(BuildContext context) {
    final uid = context.watch<AuthProvider>().firebaseUser?.uid ?? '';
    final canScore = uid.isNotEmpty && uid == match.scorerUid;
    final isLive = match.isLive;
    final isComplete = match.isCompleted;
    final subtitle = isLive
        ? '${match.venueRuns}/${match.venueWickets} · ${match.ballsBowled ~/ 6}.${match.ballsBowled % 6} overs · LIVE'
        : isComplete
            ? (match.resultText.isEmpty ? 'Completed' : match.resultText)
            : match.scheduledAt == null
                ? '${tournament.totalOvers} overs · Scheduled'
                : '${DateFormat('d MMM · h:mm a').format(match.scheduledAt!.toLocal())} · ${tournament.totalOvers} overs';
    final label = match.isScheduled && canScore
        ? 'Start match'
        : isLive
            ? 'Live score'
            : isComplete
                ? 'Scorecard'
                : 'Details';
    final icon = match.isScheduled && canScore
        ? Icons.play_arrow_rounded
        : isLive
            ? Icons.sensors_rounded
            : isComplete
                ? Icons.scoreboard_outlined
                : Icons.chevron_right_rounded;

    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
        child: Column(
          children: [
            Row(
              children: [
                Container(
                  width: 35,
                  height: 35,
                  alignment: Alignment.center,
                  decoration: const BoxDecoration(
                    color: AppTheme.primaryContainer,
                    shape: BoxShape.circle,
                  ),
                  child: Text('${fixture.fixtureNumber}',
                      style: const TextStyle(color: AppTheme.primary, fontWeight: FontWeight.w800)),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${match.teamAName}  vs  ${match.teamBName}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.titleSmall,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        subtitle,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context)
                            .textTheme
                            .bodySmall
                            ?.copyWith(color: isLive ? AppTheme.danger : AppTheme.textSecondary),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () {
                  if (match.isScheduled && canScore) {
                    Navigator.pushNamed(
                      context,
                      TossScreen.route,
                      arguments: {'matchId': match.id, 'match': match},
                    );
                  } else {
                    Navigator.pushNamed(
                      context,
                      LiveMatchScreen.route,
                      arguments: match.id,
                    );
                  }
                },
                icon: Icon(icon, size: 18),
                label: Text(label),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TieResolutionCard extends StatelessWidget {
  final Tournament tournament;
  final TournamentFixture fixture;

  const _TieResolutionCard({required this.tournament, required this.fixture});

  @override
  Widget build(BuildContext context) {
    final uid = context.watch<AuthProvider>().firebaseUser?.uid ?? '';
    final isAdmin = tournament.isAdmin(uid);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('${fixture.teamAName ?? 'Team A'}  vs  ${fixture.teamBName ?? 'Team B'}',
                style: Theme.of(context).textTheme.titleSmall),
            const SizedBox(height: 4),
            const Text('Tied fixture · organizer decision required',
                style: TextStyle(color: AppTheme.accentText, fontSize: 12)),
            if (isAdmin) ...[
              const SizedBox(height: 10),
              OutlinedButton.icon(
                onPressed: () => _chooseWinner(context),
                icon: const Icon(Icons.emoji_events_outlined),
                label: const Text('Resolve tie'),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _chooseWinner(BuildContext context) async {
    final candidates = [
      if (fixture.teamAId != null) (fixture.teamAId!, fixture.teamAName ?? 'Team A'),
      if (fixture.teamBId != null) (fixture.teamBId!, fixture.teamBName ?? 'Team B'),
    ];
    final winner = await showModalBottomSheet<String>(
      context: context,
      builder: (sheetContext) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.all(18),
              child: Text('Choose the advancing team',
                  style: Theme.of(context).textTheme.titleLarge),
            ),
            ...candidates.map((team) => ListTile(
                  leading: const Icon(Icons.shield_outlined, color: AppTheme.primary),
                  title: Text(team.$2),
                  onTap: () => Navigator.pop(sheetContext, team.$1),
                )),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
    if (winner == null || !context.mounted) return;
    try {
      await context.read<TournamentService>().resolveKnockoutTie(
            tournamentId: tournament.id,
            fixtureId: fixture.id,
            winnerTeamId: winner,
          );
    } catch (error) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not resolve the tie: $error')),
        );
      }
    }
  }
}

class _PointsTableTab extends StatelessWidget {
  final Tournament tournament;

  const _PointsTableTab({required this.tournament});

  @override
  Widget build(BuildContext context) {
    if (tournament.isKnockout) {
      return const _MessageState(
        icon: Icons.account_tree_outlined,
        title: 'Knockout bracket',
        subtitle: 'There is no league points table for elimination matches. Follow each round in the Fixtures tab.',
      );
    }
    final rows = tournament.pointsTable;
    if (rows.isEmpty) {
      return const _MessageState(
        icon: Icons.leaderboard_outlined,
        title: 'The table is ready for play',
        subtitle: 'Points and NRR are calculated automatically after each completed fixture.',
      );
    }
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 24),
      children: [
        Text('League standings', style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 4),
        const Text(
          'Equal points are ranked by net run rate, then wins.',
          style: TextStyle(color: AppTheme.textSecondary, fontSize: 12),
        ),
        const SizedBox(height: 12),
        Card(
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: DataTable(
              columnSpacing: 18,
              horizontalMargin: 14,
              columns: const [
                DataColumn(label: Text('#')),
                DataColumn(label: Text('TEAM')),
                DataColumn(label: Text('P')),
                DataColumn(label: Text('W')),
                DataColumn(label: Text('L')),
                DataColumn(label: Text('T/NR')),
                DataColumn(label: Text('PTS')),
                DataColumn(label: Text('NRR')),
              ],
              rows: [
                for (var index = 0; index < rows.length; index++)
                  DataRow(cells: [
                    DataCell(Text('${index + 1}',
                        style: const TextStyle(fontWeight: FontWeight.w700))),
                    DataCell(SizedBox(
                      width: 112,
                      child: Text(
                        (rows[index]['team_name'] ?? 'Team') as String,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                    )),
                    DataCell(Text('${_number(rows[index]['played'])}')),
                    DataCell(Text('${_number(rows[index]['won'])}')),
                    DataCell(Text('${_number(rows[index]['lost'])}')),
                    DataCell(Text('${_number(rows[index]['tied'])}/${_number(rows[index]['no_result'])}')),
                    DataCell(Text('${_number(rows[index]['points'])}',
                        style: const TextStyle(color: AppTheme.primary, fontWeight: FontWeight.w800))),
                    DataCell(Text((rows[index]['nrr_label'] ?? '0.000') as String,
                        style: const TextStyle(fontFeatures: [FontFeature.tabularFigures()]))),
                  ]),
              ],
            ),
          ),
        ),
        const SizedBox(height: 10),
        const Text(
          'NRR uses cumulative runs scored and conceded divided by legal balls. A completed all-out innings counts the full overs quota.',
          style: TextStyle(color: AppTheme.textSecondary, fontSize: 11, height: 1.4),
        ),
      ],
    );
  }
}

class _LeadersTab extends StatelessWidget {
  final Tournament tournament;

  const _LeadersTab({required this.tournament});

  @override
  Widget build(BuildContext context) {
    final orange = _listFrom(tournament.leaderboards['orange_cap']);
    final purple = _listFrom(tournament.leaderboards['purple_cap']);
    if (orange.isEmpty && purple.isEmpty) {
      return const _MessageState(
        icon: Icons.military_tech_outlined,
        title: 'Player leaders appear here',
        subtitle: 'The Orange Cap and Purple Cap lists update from completed tournament scorecards.',
      );
    }
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 24),
      children: [
        Text('Tournament leaders', style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 4),
        const Text('Live totals from completed fixtures.',
            style: TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
        const SizedBox(height: 14),
        _LeaderListCard(
          title: 'ORANGE CAP',
          subtitle: 'Most tournament runs',
          color: AppTheme.accent,
          icon: Icons.sports_cricket_rounded,
          entries: orange,
          stat: (entry) => '${_number(entry['runs'])} runs',
          detail: (entry) => '${_number(entry['balls'])} balls · SR ${_decimal(entry['strike_rate'])}',
        ),
        const SizedBox(height: 12),
        _LeaderListCard(
          title: 'PURPLE CAP',
          subtitle: 'Most tournament wickets',
          color: AppTheme.boundarySix,
          icon: Icons.sports_baseball_rounded,
          entries: purple,
          stat: (entry) => '${_number(entry['wickets'])} wkts',
          detail: (entry) => '${_number(entry['legal_balls']) ~/ 6}.${_number(entry['legal_balls']) % 6} ov · Econ ${_decimal(entry['economy'])}',
        ),
      ],
    );
  }
}

class _LeaderListCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final Color color;
  final IconData icon;
  final List<Map<String, dynamic>> entries;
  final String Function(Map<String, dynamic>) stat;
  final String Function(Map<String, dynamic>) detail;

  const _LeaderListCard({
    required this.title,
    required this.subtitle,
    required this.color,
    required this.icon,
    required this.entries,
    required this.stat,
    required this.detail,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(15, 15, 15, 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 19,
                  backgroundColor: color.withValues(alpha: 0.13),
                  child: Icon(icon, color: color, size: 20),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title,
                          style: TextStyle(color: color, fontWeight: FontWeight.w800, letterSpacing: 0.7)),
                      Text(subtitle,
                          style: const TextStyle(color: AppTheme.textSecondary, fontSize: 11)),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            if (entries.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 14),
                child: Text('No player stats yet.', style: TextStyle(color: AppTheme.textSecondary)),
              )
            else
              ...entries.take(10).toList().asMap().entries.map((indexed) {
                final entry = indexed.value;
                return ListTile(
                  contentPadding: EdgeInsets.zero,
                  dense: true,
                  leading: CircleAvatar(
                    radius: 15,
                    backgroundColor: AppTheme.surfaceSoft,
                    child: Text('${indexed.key + 1}',
                        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800)),
                  ),
                  title: Text((entry['player_name'] ?? 'Player') as String,
                      style: Theme.of(context).textTheme.titleSmall),
                  subtitle: Text(detail(entry)),
                  trailing: Text(stat(entry),
                      style: TextStyle(color: color, fontWeight: FontWeight.w800)),
                );
              }),
          ],
        ),
      ),
    );
  }
}

class _MetricCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;

  const _MetricCard({required this.label, required this.value, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(11, 12, 10, 11),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, size: 17, color: AppTheme.primary),
            const SizedBox(height: 9),
            Text(value,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(fontSize: 17)),
            const SizedBox(height: 1),
            Text(label,
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      fontSize: 8,
                      color: AppTheme.textSecondary,
                    )),
          ],
        ),
      ),
    );
  }
}

class _RulePill extends StatelessWidget {
  final String label;
  final int points;

  const _RulePill(this.label, this.points);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: AppTheme.surfaceSoft,
        borderRadius: BorderRadius.circular(99),
      ),
      child: Text('$label · $points pts',
          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700)),
    );
  }
}

class _MessageState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;

  const _MessageState({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(30),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 66,
              height: 66,
              decoration: const BoxDecoration(
                color: AppTheme.primaryContainer,
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: AppTheme.primary, size: 30),
            ),
            const SizedBox(height: 15),
            Text(title,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 6),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: Theme.of(context)
                  .textTheme
                  .bodyMedium
                  ?.copyWith(color: AppTheme.textSecondary, height: 1.45),
            ),
          ],
        ),
      ),
    );
  }
}

List<Map<String, dynamic>> _listFrom(Object? value) {
  if (value is! Iterable) return const [];
  return value.whereType<Map>().map((item) => Map<String, dynamic>.from(item)).toList();
}

int _number(Object? value) => value is num ? value.toInt() : int.tryParse('$value') ?? 0;

String _decimal(Object? value) => value is num ? value.toStringAsFixed(2) : '0.00';

String _dateRange(Tournament tournament) {
  final start = tournament.startAt;
  if (start == null) return 'Dates TBA';
  final end = tournament.endAt;
  final formatter = DateFormat('d MMM yyyy');
  return end == null || DateUtils.dateOnly(start) == DateUtils.dateOnly(end)
      ? formatter.format(start.toLocal())
      : '${formatter.format(start.toLocal())} – ${formatter.format(end.toLocal())}';
}
