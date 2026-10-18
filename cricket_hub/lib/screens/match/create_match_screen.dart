import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/app_constants.dart';
import '../../core/app_theme.dart';
import '../../models/match_model.dart';
import '../../models/team_model.dart';
import '../../providers/auth_provider.dart';
import '../../services/match_service.dart';
import '../../services/team_service.dart';
import '../team/create_team_screen.dart';
import 'toss_screen.dart';
import '../../l10n/generated/app_localizations.dart';

/// Team and match-format setup before the toss.
class CreateMatchScreen extends StatefulWidget {
  const CreateMatchScreen({super.key});

  static const String route = '/create-match';

  @override
  State<CreateMatchScreen> createState() => _CreateMatchScreenState();
}

class _CreateMatchScreenState extends State<CreateMatchScreen> {
  Team? _teamA;
  Team? _teamB;
  int _overs = AppConstants.defaultOvers;
  bool _saving = false;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final teamService = context.read<TeamService>();
    final auth = context.watch<AuthProvider>();

    return Scaffold(
      appBar: AppBar(title: Text(l10n.set_up_a_match)),
      body: StreamBuilder<List<Team>>(
        stream: teamService.teamsStream(),
        builder: (context, snapshot) {
          final teams = snapshot.data ?? const <Team>[];
          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(l10n.couldn_t_load_teams_please_try),
              ),
            );
          }

          if (snapshot.connectionState == ConnectionState.waiting &&
              !snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          return SafeArea(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 600),
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 42,
                          height: 42,
                          decoration: BoxDecoration(
                            color: AppTheme.accentContainer,
                            borderRadius: BorderRadius.circular(13),
                          ),
                          child: const Icon(Icons.sports_cricket,
                              color: AppTheme.accentText),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(l10n.match_day_starts_here,
                                  style: Theme.of(context).textTheme.titleLarge),
                              const SizedBox(height: 3),
                              Text(
                                l10n.choose_your_teams_and_playing_format,
                                style: Theme.of(context)
                                    .textTheme
                                    .bodySmall
                                    ?.copyWith(color: AppTheme.textSecondary),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(18),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _StepLabel(number: '01', label: l10n.choose_the_sides),
                            const SizedBox(height: 16),
                            _TeamPicker(
                              label: l10n.batting_side_a,
                              teams: teams,
                              selected: _teamA,
                              exclude: _teamB,
                              onChanged: (team) => setState(() => _teamA = team),
                            ),
                            const SizedBox(height: 14),
                            _TeamPicker(
                              label: l10n.bowling_side_b,
                              teams: teams,
                              selected: _teamB,
                              exclude: _teamA,
                              onChanged: (team) => setState(() => _teamB = team),
                            ),
                            if (teams.isEmpty) ...[
                              const SizedBox(height: 14),
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: AppTheme.surfaceSoft,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Row(
                                  children: [
                                    const Icon(Icons.info_outline_rounded,
                                        color: AppTheme.textSecondary, size: 20),
                                    const SizedBox(width: 9),
                                    Expanded(
                                      child: Text(
                                        l10n.create_at_least_two_teams_before,
                                        style: Theme.of(context)
                                            .textTheme
                                            .bodySmall
                                            ?.copyWith(
                                                color: AppTheme.textSecondary),
                                      ),
                                    ),
                                    TextButton(
                                      onPressed: () => Navigator.pushNamed(
                                          context, CreateTeamScreen.route),
                                      child: Text(l10n.create),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(18),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _StepLabel(number: '02', label: l10n.match_format),
                            const SizedBox(height: 5),
                            Text(
                              l10n.how_long_will_you_play,
                              style: Theme.of(context)
                                  .textTheme
                                  .bodySmall
                                  ?.copyWith(color: AppTheme.textSecondary),
                            ),
                            const SizedBox(height: 13),
                            Wrap(
                              spacing: 9,
                              runSpacing: 9,
                              children: [5, 10, 15, 20, 25].map((overs) {
                                final selected = _overs == overs;
                                return ChoiceChip(
                                  label: Text(l10n.oversCount(overs)),
                                  selected: selected,
                                  showCheckmark: false,
                                  selectedColor: AppTheme.primary,
                                  backgroundColor: AppTheme.surfaceSoft,
                                  side: BorderSide(
                                    color: selected
                                        ? AppTheme.primary
                                        : AppTheme.border,
                                  ),
                                  labelStyle: TextStyle(
                                    color: selected
                                        ? Colors.white
                                        : AppTheme.textPrimary,
                                    fontWeight: FontWeight.w700,
                                  ),
                                  onSelected: (_) =>
                                      setState(() => _overs = overs),
                                );
                              }).toList(),
                            ),
                            const SizedBox(height: 14),
                            Row(
                              children: [
                                const Icon(Icons.sports_cricket,
                                    size: 17, color: AppTheme.textSecondary),
                                const SizedBox(width: 7),
                                Expanded(
                                  child: Text(
                                    l10n.tennis_ball_by_default_toss_comes,
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodySmall
                                        ?.copyWith(
                                            color: AppTheme.textSecondary),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    ElevatedButton.icon(
                      onPressed: (_teamA == null || _teamB == null || _saving)
                          ? null
                          : () => _createMatch(context, auth),
                      icon: _saving
                          ? const SizedBox(
                              height: 18,
                              width: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Icon(Icons.arrow_forward_rounded),
                      label: Text(_saving ? 'Preparing match…' : 'Continue to toss'),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Future<void> _createMatch(BuildContext context, AuthProvider auth) async {
    final l10n = AppLocalizations.of(context);
    setState(() => _saving = true);

    final match = CricketMatch(
      id: '',
      status: 'scheduled',
      teamAId: _teamA!.id,
      teamBId: _teamB!.id,
      teamAName: _teamA!.teamName,
      teamBName: _teamB!.teamName,
      totalOvers: _overs,
      scorerUid: auth.firebaseUser!.uid,
      scorerName: auth.appUser?.displayName ?? '',
      battingTeamId: '',
      bowlingTeamId: '',
    );

    try {
      final matchId = await context.read<MatchService>().createMatch(match);
      // `context` is this method's BuildContext parameter, so guard it with
      // its own `context.mounted` (not State.mounted).
      if (!context.mounted) return;
      Navigator.pushReplacementNamed(
        context,
        TossScreen.route,
        arguments: {'matchId': matchId, 'match': match},
      );
    } catch (error) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.errCouldNotCreateMatch('$error'))),
      );
      if (mounted) setState(() => _saving = false);
    }
  }
}

class _StepLabel extends StatelessWidget {
  final String number;
  final String label;

  const _StepLabel({required this.number, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 28,
          height: 28,
          alignment: Alignment.center,
          decoration: const BoxDecoration(
            color: AppTheme.primaryContainer,
            shape: BoxShape.circle,
          ),
          child: Text(
            number,
            style: const TextStyle(
              color: AppTheme.primary,
              fontSize: 10,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
        const SizedBox(width: 9),
        Text(label, style: Theme.of(context).textTheme.titleMedium),
      ],
    );
  }
}

class _TeamPicker extends StatelessWidget {
  final String label;
  final List<Team> teams;
  final Team? selected;
  final Team? exclude;
  final ValueChanged<Team> onChanged;

  const _TeamPicker({
    required this.label,
    required this.teams,
    required this.selected,
    required this.exclude,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final available = teams.where((team) => team.id != exclude?.id).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: Theme.of(context)
              .textTheme
              .labelLarge
              ?.copyWith(color: AppTheme.textSecondary),
        ),
        const SizedBox(height: 7),
        DropdownButtonFormField<Team>(
          initialValue: selected,
          isExpanded: true,
          hint: Text(available.isEmpty ? 'No teams available' : 'Select a team'),
          items: available
              .map(
                (team) => DropdownMenuItem<Team>(
                  value: team,
                  child: Text(
                    '${team.teamName} · ${team.city}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              )
              .toList(),
          onChanged: (team) {
            if (team != null) onChanged(team);
          },
        ),
      ],
    );
  }
}
