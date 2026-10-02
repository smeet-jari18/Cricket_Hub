import 'package:flutter/material.dart';

import 'package:provider/provider.dart';

import '../../core/app_theme.dart';
import '../../models/match_model.dart';
import '../../services/match_service.dart';
import 'scoring_dashboard_screen.dart';

/// Flow 3, step 4: who won the toss and what did they choose?
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
      appBar: AppBar(title: const Text('Toss')),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          Text(
            '${match.teamAName}  vs  ${match.teamBName}',
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 32),

          const Text('Who won the toss?'),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _TossCard(
                  title: match.teamAName,
                  selected: _tossWinnerTeamId == match.teamAId,
                  onTap: () =>
                      setState(() => _tossWinnerTeamId = match.teamAId),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _TossCard(
                  title: match.teamBName,
                  selected: _tossWinnerTeamId == match.teamBId,
                  onTap: () =>
                      setState(() => _tossWinnerTeamId = match.teamBId),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          const Text('And they chose to...'),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _TossCard(
                  icon: Icons.sports_baseball,
                  title: 'BAT first',
                  selected: _electedTo == 'bat',
                  onTap: () => setState(() => _electedTo = 'bat'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _TossCard(
                  icon: Icons.sports_baseball_outlined,
                  title: 'BOWL first',
                  selected: _electedTo == 'bowl',
                  onTap: () => setState(() => _electedTo = 'bowl'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 40),

          ElevatedButton(
            onPressed: (_tossWinnerTeamId == null || _saving)
                ? null
                : () async {
                    setState(() => _saving = true);
                    final tossWinner = _tossWinnerTeamId!;
                    final battingTeamId =
                        _electedTo == 'bat' ? tossWinner : (tossWinner == match.teamAId ? match.teamBId : match.teamAId);
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
                      tossWinner: tossWinner,
                      electedTo: _electedTo,
                      battingTeamId: battingTeamId,
                      bowlingTeamId: bowlingTeamId,
                    );

                    await context.read<MatchService>().startMatchWithToss(updated);
                    if (!mounted) return;
                    Navigator.pushReplacementNamed(
                      context,
                      ScoringDashboardScreen.route,
                      arguments: {'matchId': matchId, 'match': updated},
                    );
                  },
            child: _saving
                ? const SizedBox(
                    height: 22,
                    width: 22,
                    child: CircularProgressIndicator(strokeWidth: 2))
                : const Text("Let's Play"),
          ),
        ],
      ),
    );
  }
}

class _TossCard extends StatelessWidget {
  final String title;
  final bool selected;
  final VoidCallback onTap;
  final IconData? icon;

  const _TossCard({
    required this.title,
    required this.selected,
    required this.onTap,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: selected ? AppTheme.primary.withValues(alpha: 0.15) : AppTheme.surface,
          border: Border.all(
            color: selected ? AppTheme.primary : AppTheme.textSecondary,
            width: selected ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            if (icon != null)
              Icon(icon, color: selected ? AppTheme.primary : AppTheme.textSecondary),
            if (icon != null) const SizedBox(height: 8),
            Text(
              title,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontWeight: selected ? FontWeight.bold : FontWeight.normal,
                color: selected ? AppTheme.primary : AppTheme.textPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
