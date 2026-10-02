import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/app_theme.dart';
import '../../models/match_model.dart';
import '../../services/match_service.dart';
import 'scoring_dashboard_screen.dart';

/// Confirm the toss result and begin the live innings.
class TossScreen extends StatefulWidget {
  const TossScreen({super.key});

  static const String route = '/toss';

  @override
  State<TossScreen> createState() => _TossScreenState();
}

class _TossScreenState extends State<TossScreen> {
  String? _tossWinnerTeamId;
  String _electedTo = 'bat';
  bool _saving = false;

  @override
  Widget build(BuildContext context) {
    final args =
        ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
    final match = args?['match'] as CricketMatch?;
    final matchId = (args?['matchId'] ?? '') as String;

    if (match == null) {
      return const Scaffold(body: Center(child: Text('Match not found')));
    }

    return Scaffold(
      appBar: AppBar(title: const Text('The toss')),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 600),
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
              children: [
                Text(
                  'One last call',
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
                const SizedBox(height: 5),
                Text(
                  'Confirm the toss, then the first ball is yours.',
                  style: Theme.of(context)
                      .textTheme
                      .bodyMedium
                      ?.copyWith(color: AppTheme.textSecondary),
                ),
                const SizedBox(height: 18),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        Expanded(
                          child: _TeamLabel(
                            label: 'SIDE A',
                            name: match.teamAName,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            color: AppTheme.surfaceSoft,
                            borderRadius: BorderRadius.circular(99),
                          ),
                          child: const Text(
                            'VS',
                            style: TextStyle(
                              color: AppTheme.textSecondary,
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                        Expanded(
                          child: _TeamLabel(
                            label: 'SIDE B',
                            name: match.teamBName,
                            alignEnd: true,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                const _TossStep(number: '01', title: 'Who won the toss?'),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: _TossCard(
                        icon: Icons.shield,
                        title: match.teamAName,
                        selected: _tossWinnerTeamId == match.teamAId,
                        onTap: () =>
                            setState(() => _tossWinnerTeamId = match.teamAId),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _TossCard(
                        icon: Icons.shield,
                        title: match.teamBName,
                        selected: _tossWinnerTeamId == match.teamBId,
                        onTap: () =>
                            setState(() => _tossWinnerTeamId = match.teamBId),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 22),
                const _TossStep(number: '02', title: 'What did they choose?'),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: _TossCard(
                        icon: Icons.sports_cricket,
                        title: 'Bat first',
                        selected: _electedTo == 'bat',
                        onTap: () => setState(() => _electedTo = 'bat'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _TossCard(
                        icon: Icons.sports_baseball_outlined,
                        title: 'Bowl first',
                        selected: _electedTo == 'bowl',
                        onTap: () => setState(() => _electedTo = 'bowl'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 22),
                ElevatedButton.icon(
                  onPressed: _tossWinnerTeamId == null || _saving
                      ? null
                      : () => _startMatch(match, matchId),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.accent,
                    foregroundColor: AppTheme.textPrimary,
                  ),
                  icon: _saving
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: AppTheme.textPrimary,
                          ),
                        )
                      : const Icon(Icons.play_arrow_rounded),
                  label: Text(_saving ? 'Starting innings…' : 'Start scoring'),
                ),
                const SizedBox(height: 8),
                Text(
                  'You can undo scoring actions during the match.',
                  textAlign: TextAlign.center,
                  style: Theme.of(context)
                      .textTheme
                      .bodySmall
                      ?.copyWith(color: AppTheme.textSecondary),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _startMatch(CricketMatch match, String matchId) async {
    final tossWinner = _tossWinnerTeamId;
    if (tossWinner == null) return;
    setState(() => _saving = true);

    final battingTeamId = _electedTo == 'bat'
        ? tossWinner
        : (tossWinner == match.teamAId ? match.teamBId : match.teamAId);
    final bowlingTeamId =
        battingTeamId == match.teamAId ? match.teamBId : match.teamAId;
    final updated = CricketMatch(
      id: matchId,
      status: 'live',
      teamAId: match.teamAId,
      teamBId: match.teamBId,
      teamAName: match.teamAName,
      teamBName: match.teamBName,
      totalOvers: match.totalOvers,
      scorerUid: match.scorerUid,
      scorerName: match.scorerName,
      tournamentAdminUid: match.tournamentAdminUid,
      tournamentId: match.tournamentId,
      fixtureId: match.fixtureId,
      stage: match.stage,
      roundNumber: match.roundNumber,
      fixtureNumber: match.fixtureNumber,
      scheduledAt: match.scheduledAt,
      tossWinner: tossWinner,
      electedTo: _electedTo,
      battingTeamId: battingTeamId,
      bowlingTeamId: bowlingTeamId,
    );

    try {
      await context.read<MatchService>().startMatchWithToss(updated);
      if (!mounted) return;
      Navigator.pushReplacementNamed(
        context,
        ScoringDashboardScreen.route,
        arguments: {'matchId': matchId, 'match': updated},
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not start match: $error')),
      );
      setState(() => _saving = false);
    }
  }
}

class _TeamLabel extends StatelessWidget {
  final String label;
  final String name;
  final bool alignEnd;

  const _TeamLabel({
    required this.label,
    required this.name,
    this.alignEnd = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment:
          alignEnd ? CrossAxisAlignment.end : CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: AppTheme.textSecondary,
            fontSize: 9,
            fontWeight: FontWeight.w800,
            letterSpacing: 0.7,
          ),
        ),
        const SizedBox(height: 3),
        Text(
          name,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          textAlign: alignEnd ? TextAlign.end : TextAlign.start,
          style: Theme.of(context).textTheme.titleSmall,
        ),
      ],
    );
  }
}

class _TossStep extends StatelessWidget {
  final String number;
  final String title;

  const _TossStep({required this.number, required this.title});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 27,
          height: 27,
          alignment: Alignment.center,
          decoration: const BoxDecoration(
            color: AppTheme.primaryContainer,
            shape: BoxShape.circle,
          ),
          child: Text(number,
              style: const TextStyle(
                  color: AppTheme.primary,
                  fontSize: 10,
                  fontWeight: FontWeight.w800)),
        ),
        const SizedBox(width: 9),
        Text(title, style: Theme.of(context).textTheme.titleMedium),
      ],
    );
  }
}

class _TossCard extends StatelessWidget {
  final String title;
  final bool selected;
  final VoidCallback onTap;
  final IconData icon;

  const _TossCard({
    required this.title,
    required this.selected,
    required this.onTap,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final foreground = selected ? AppTheme.primary : AppTheme.textSecondary;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 160),
      child: Card(
        color: selected ? AppTheme.primaryContainer : AppTheme.surface,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(10, 18, 10, 16),
            child: Column(
              children: [
                Icon(icon, color: foreground, size: 25),
                const SizedBox(height: 9),
                Text(
                  title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                        color: selected ? AppTheme.primary : AppTheme.textPrimary,
                      ),
                ),
                if (selected) ...[
                  const SizedBox(height: 6),
                  const Icon(Icons.check_circle_rounded,
                      size: 17, color: AppTheme.primary),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
