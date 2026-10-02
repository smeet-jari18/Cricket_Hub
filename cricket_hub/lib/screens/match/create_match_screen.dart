import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/app_constants.dart';
import '../../models/match_model.dart';
import '../../models/team_model.dart';
import '../../providers/auth_provider.dart';
import '../../services/match_service.dart';
import '../../services/team_service.dart';
import 'toss_screen.dart';

/// Flow 3 (App Flow doc): Select Teams -> Match Settings -> Toss.
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
    final teamService = context.read<TeamService>();
    final auth = context.watch<AuthProvider>();

    return Scaffold(
      appBar: AppBar(title: const Text('Start a Match')),
      body: StreamBuilder<List<Team>>(
        stream: teamService.teamsStream(),
        builder: (context, snapshot) {
          final teams = snapshot.data ?? [];

          return ListView(
            padding: const EdgeInsets.all(24),
            children: [
              _TeamPicker(
                label: 'Team A',
                teams: teams,
                selected: _teamA,
                exclude: _teamB,
                onChanged: (t) => setState(() => _teamA = t),
              ),
              const SizedBox(height: 16),
              _TeamPicker(
                label: 'Team B',
                teams: teams,
                selected: _teamB,
                exclude: _teamA,
                onChanged: (t) => setState(() => _teamB = t),
              ),
              const SizedBox(height: 24),

              // Overs selector (chips: 5 / 10 / 15 / 20 / 25)
              const Text('Match overs'),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: [5, 10, 15, 20, 25].map((o) {
                  final selected = _overs == o;
                  return ChoiceChip(
                    label: Text('$o'),
                    selected: selected,
                    selectedColor: const Color(0xFF00BFA5),
                    onSelected: (_) => setState(() => _overs = o),
                  );
                }).toList(),
              ),
              const SizedBox(height: 8),
              const Text('Ball type: Tennis (default) — leather ball option in Phase 2.',
                  style: TextStyle(color: Color(0xFFA0A0A0), fontSize: 12)),
              const SizedBox(height: 32),

              ElevatedButton(
                onPressed: (_teamA == null || _teamB == null || _saving)
                    ? null
                    : () => _createMatch(context, auth),
                child: _saving
                    ? const SizedBox(
                        height: 22,
                        width: 22,
                        child: CircularProgressIndicator(strokeWidth: 2))
                    : const Text('Next: Toss'),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _createMatch(BuildContext context, AuthProvider auth) async {
    setState(() => _saving = true);

    final matchService = context.read<MatchService>();
    final match = CricketMatch(
      id: '',
      status: 'scheduled',
      teamAId: _teamA!.id,
      teamBId: _teamB!.id,
      teamAName: _teamA!.teamName,
      teamBName: _teamB!.teamName,
      totalOvers: _overs,
      scorerUid: auth.firebaseUser!.uid, // creator scores by default
      // Toss has not happened yet; these are set on the toss screen.
      battingTeamId: '',
      bowlingTeamId: '',
    );

    try {
      final matchId = await matchService.createMatch(match);
      if (!mounted) return;
      Navigator.pushReplacementNamed(
        context,
        TossScreen.route,
        arguments: {'matchId': matchId, 'match': match},
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not create match: $e')),
      );
      setState(() => _saving = false);
    }
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
    final available =
        teams.where((t) => t.id != (exclude?.id ?? '')).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label),
        const SizedBox(height: 8),
        DropdownButtonFormField<Team>(
          initialValue: selected,
          isExpanded: true,
          hint: available.isEmpty
              ? const Text('No teams yet — create one first!')
              : const Text('Select team'),
          items: available
              .map((t) => DropdownMenuItem(
                    value: t,
                    child: Text('${t.teamName} (${t.city})'),
                  ))
              .toList(),
          onChanged: (t) { if (t != null) onChanged(t); },
        ),
      ],
    );
  }
}
