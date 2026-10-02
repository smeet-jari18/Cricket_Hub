import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/app_theme.dart';
import '../../models/match_model.dart';
import '../../providers/scoring_engine.dart';
import '../../providers/scoring_provider.dart';
import '../../services/match_service.dart';
import '../../widgets/score_button.dart';

/// THE MOST CRITICAL SCREEN (UI/UX doc Screen 2).
/// Top 45% = context (score, batsmen, bowler)
/// Bottom 55% = big thumb-friendly action pad.
/// Fully usable offline — an "offline" banner shows sync status.
class ScoringDashboardScreen extends StatefulWidget {
  const ScoringDashboardScreen({super.key});

  static const String route = '/scoring';

  @override
  State<ScoringDashboardScreen> createState() => _ScoringDashboardScreenState();
}

class _ScoringDashboardScreenState extends State<ScoringDashboardScreen> {
  bool _offline = false;
  bool _setupShown = false;
  StreamSubscription<List<ConnectivityResult>>? _connectivitySubscription;

  @override
  void initState() {
    super.initState();
    _listenConnectivity();
  }

  Future<void> _listenConnectivity() async {
    final connectivity = Connectivity();
    _connectivitySubscription = connectivity.onConnectivityChanged.listen(
      _updateConnectivity,
    );

    // Read the initial state too; the stream may not emit until it changes.
    try {
      _updateConnectivity(await connectivity.checkConnectivity());
    } catch (_) {
      // Connectivity is only an indicator; Firestore remains authoritative.
    }
  }

  void _updateConnectivity(List<ConnectivityResult> results) {
    final offline =
        results.isEmpty || results.contains(ConnectivityResult.none);
    if (mounted && offline != _offline) {
      setState(() => _offline = offline);
    }
  }

  @override
  void dispose() {
    _connectivitySubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final args =
        ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
    final match = args?['match'] as CricketMatch?;

    if (match == null) {
      return const Scaffold(body: Center(child: Text('Match not found')));
    }

    return ChangeNotifierProvider(
      create: (_) => ScoringProvider(match, context.read<MatchService>()),
      child: Consumer<ScoringProvider>(
        builder: (context, scoring, _) {
          final s = scoring.state;

          _maybeShowDialogs(context, scoring, s);

          return Scaffold(
            appBar: AppBar(
              title: Text('${s.battingTeamName} batting'),
              actions: [
                // UNDO — prominent & frictionless (UI/UX principle 3)
                TextButton.icon(
                  onPressed: s.lastEventText == 'Match started'
                      ? null
                      : () => scoring.undo(),
                  icon: const Icon(Icons.undo, color: AppTheme.accentText),
                  label: const Text('Undo',
                      style: TextStyle(color: AppTheme.accentText)),
                ),
              ],
            ),
            body: Column(
              children: [
                // ---- offline banner (UI/UX Guidelines §5) ----
                if (_offline)
                  Container(
                    width: double.infinity,
                    color: AppTheme.accent,
                    padding: const EdgeInsets.all(6),
                    child: const Text(
                      'You are offline. Scoring continues — syncs automatically.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                          fontSize: 12, fontWeight: FontWeight.bold),
                    ),
                  ),

                _ContextBlock(s: s),

                const Divider(height: 1),

                // ---- ACTION PAD (bottom 55%) ----
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      children: [
                        Expanded(
                          child: Row(
                            children: [
                              ScoreButton(label: '0', onTap: () => scoring.recordRuns(0)),
                              const SizedBox(width: 8),
                              ScoreButton(label: '1', onTap: () => scoring.recordRuns(1)),
                              const SizedBox(width: 8),
                              ScoreButton(label: '2', onTap: () => scoring.recordRuns(2)),
                              const SizedBox(width: 8),
                              ScoreButton(label: '3', onTap: () => scoring.recordRuns(3)),
                            ],
                          ),
                        ),
                        const SizedBox(height: 8),
                        Expanded(
                          child: Row(
                            children: [
                              ScoreButton(
                                  label: '4',
                                  color: AppTheme.boundaryFour,
                                  textColor: AppTheme.textPrimary,
                                  onTap: () => scoring.recordRuns(4)),
                              const SizedBox(width: 8),
                              ScoreButton(
                                  label: '6',
                                  color: AppTheme.boundarySix,
                                  onTap: () => scoring.recordRuns(6)),
                              const SizedBox(width: 8),
                              ScoreButton(
                                  label: 'WD',
                                  onTap: () => _askWideRuns(scoring)),
                              const SizedBox(width: 8),
                              ScoreButton(
                                  label: 'NB',
                                  onTap: () => _askNoBallRuns(scoring)),
                            ],
                          ),
                        ),
                        const SizedBox(height: 8),
                        Expanded(
                          child: Row(
                            children: [
                              ScoreButton(
                                  label: 'B',
                                  onTap: () => _askByeRuns(scoring, false)),
                              const SizedBox(width: 8),
                              ScoreButton(
                                  label: 'LB',
                                  onTap: () => _askByeRuns(scoring, true)),
                              const SizedBox(width: 8),
                              ScoreButton(
                                label: 'WICKET',
                                color: AppTheme.danger,
                                textColor: Colors.white,
                                flex: 2,
                                onTap: () => _askWicketType(scoring),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  // ================= DIALOGS =================

  /// Show opener setup once, then wicket/bowler dialogs as the engine asks.
  void _maybeShowDialogs(
      BuildContext context, ScoringProvider scoring, dynamic s) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!context.mounted) return;

      if (!_setupShown && s.batsmen.isEmpty) {
        _setupShown = true;
        _showOpenersDialog(context, scoring);
      } else if (s.isInningsComplete) {
        _showInningsCompleteDialog(context, scoring, s);
      } else if (s.pendingNewBatsman) {
        _showNewBatsmanDialog(context, scoring);
      } else if (s.pendingNewBowler) {
        _showNewBowlerDialog(context, scoring);
      }
    });
  }

  void _showOpenersDialog(BuildContext context, ScoringProvider scoring) {
    final c1 = TextEditingController();
    final c2 = TextEditingController();
    final c3 = TextEditingController();

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Match Setup'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                  controller: c1,
                  textCapitalization: TextCapitalization.words,
                  decoration:
                      const InputDecoration(hintText: 'Striker name')),
              const SizedBox(height: 12),
              TextField(
                  controller: c2,
                  textCapitalization: TextCapitalization.words,
                  decoration:
                      const InputDecoration(hintText: 'Non-striker name')),
              const SizedBox(height: 12),
              TextField(
                  controller: c3,
                  textCapitalization: TextCapitalization.words,
                  decoration:
                      const InputDecoration(hintText: 'Opening bowler')),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              if (c1.text.trim().isEmpty ||
                  c2.text.trim().isEmpty ||
                  c3.text.trim().isEmpty) {
                return; // all three are required
              }
              scoring.setOpener(c1.text);
              scoring.setSecondOpener(c2.text);
              scoring.setBowler(c3.text);
              Navigator.pop(dialogContext);
            },
            child: const Text("Let's Play"),
          ),
        ],
      ),
    );
  }

  void _showNewBatsmanDialog(BuildContext context, ScoringProvider scoring) {
    final c = TextEditingController();
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => AlertDialog(
        title: const Text('WICKET! Next batter'),
        content: TextField(
          controller: c,
          autofocus: true,
          textCapitalization: TextCapitalization.words,
          decoration: const InputDecoration(hintText: 'New batter name'),
        ),
        actions: [
          TextButton(
            onPressed: () {
              if (c.text.trim().isEmpty) return;
              scoring.confirmNewBatsman(c.text);
              Navigator.pop(dialogContext);
            },
            child: const Text('Send in'),
          ),
        ],
      ),
    );
  }

  void _showNewBowlerDialog(BuildContext context, ScoringProvider scoring) {
    final c = TextEditingController();
    // Quick-pick: bowlers who already bowled.
    final existing =
        scoring.state.bowlers.keys.where((k) => k.isNotEmpty).toList();

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Over complete! Next bowler'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (existing.isNotEmpty)
              Wrap(
                spacing: 8,
                children: existing
                    .map((name) => ActionChip(
                          label: Text(name),
                          onPressed: () {
                            scoring.setBowler(name);
                            Navigator.pop(dialogContext);
                          },
                        ))
                    .toList(),
              ),
            const SizedBox(height: 12),
            TextField(
              controller: c,
              autofocus: true,
              textCapitalization: TextCapitalization.words,
              decoration:
                  const InputDecoration(hintText: 'Or type a new bowler'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              if (c.text.trim().isEmpty) return;
              scoring.setBowler(c.text);
              Navigator.pop(dialogContext);
            },
            child: const Text('Continue'),
          ),
        ],
      ),
    );
  }

  void _showInningsCompleteDialog(
      BuildContext context, ScoringProvider scoring, dynamic s) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Innings Complete!'),
        content: Text(
          '${s.battingTeamName}: ${s.totalRuns}/${s.wickets} '
          '(${s.completedOvers}.${s.ballsThisOver} ov)\n\n'
          'Well bowled! Save the result to the cloud.',
        ),
        actions: [
          TextButton(
            onPressed: () async {
              await scoring.endMatch();
              if (!context.mounted) return;
              Navigator.of(context).popUntil((r) => r.isFirst);
            },
            child: const Text('Save & Finish'),
          ),
        ],
      ),
    );
  }

  // ---- small prompts for extras ----

  void _askWideRuns(ScoringProvider scoring) {
    final c = TextEditingController(text: '0');
    _promptNumber(context, 'Wide: extra runs run?', c, () {
      scoring.recordWide(additional: int.tryParse(c.text) ?? 0);
    });
  }

  void _askNoBallRuns(ScoringProvider scoring) {
    final c = TextEditingController(text: '0');
    _promptNumber(context, 'No-ball: runs off the bat?', c, () {
      scoring.recordNoBall(batRuns: int.tryParse(c.text) ?? 0);
    });
  }

  void _askByeRuns(ScoringProvider scoring, bool isLegBye) {
    final c = TextEditingController(text: '1');
    _promptNumber(context, isLegBye ? 'Leg bye runs?' : 'Bye runs?', c, () {
      final runs = int.tryParse(c.text) ?? 1;
      if (isLegBye) {
        scoring.recordLegBye(runs);
      } else {
        scoring.recordBye(runs);
      }
    });
  }

  void _promptNumber(BuildContext context, String title,
      TextEditingController controller, VoidCallback onConfirm) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(title, style: const TextStyle(fontSize: 18)),
        content: TextField(
          controller: controller,
          autofocus: true,
          keyboardType: TextInputType.number,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              onConfirm();
              Navigator.pop(dialogContext);
            },
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _askWicketType(ScoringProvider scoring) {
    const types = [
      'bowled',
      'caught',
      'lbw',
      'run out',
      'stumped',
      'hit wicket',
    ];
    showDialog(
      context: context,
      builder: (dialogContext) => SimpleDialog(
        title: const Text('How was the batter out?'),
        children: types
            .map((t) => SimpleDialogOption(
                  onPressed: () {
                    Navigator.pop(dialogContext);
                    scoring.recordWicket(type: t);
                  },
                  child: Text(t,
                      style: const TextStyle(
                          fontSize: 16, fontWeight: FontWeight.w500)),
                ))
            .toList(),
      ),
    );
  }
}

/// Compact score, players and over tracker above the action pad.
class _ContextBlock extends StatelessWidget {
  final ScoringState s;

  const _ContextBlock({required this.s});

  @override
  Widget build(BuildContext context) {
    final bowler = s.bowlers[s.currentBowler];

    return Card(
      margin: const EdgeInsets.fromLTRB(12, 8, 12, 8),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 12, 14, 10),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        s.battingTeamName.toUpperCase(),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: AppTheme.textSecondary,
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.7,
                        ),
                      ),
                      const SizedBox(height: 1),
                      Text(
                        '${s.totalRuns}/${s.wickets}',
                        style: const TextStyle(
                          color: AppTheme.textPrimary,
                          fontSize: 34,
                          height: 1.05,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -1.2,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        '${s.oversDisplay} overs  ·  CRR ${s.crr}',
                        style: const TextStyle(
                          color: AppTheme.textSecondary,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                if (s.target != null)
                  Container(
                    constraints: const BoxConstraints(minWidth: 94),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 10),
                    decoration: BoxDecoration(
                      color: AppTheme.accentContainer,
                      borderRadius: BorderRadius.circular(13),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        const Text(
                          'TARGET',
                          style: TextStyle(
                            color: AppTheme.accentText,
                            fontSize: 9,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.65,
                          ),
                        ),
                        Text(
                          '${s.target}',
                          style: const TextStyle(
                            color: AppTheme.textPrimary,
                            fontSize: 21,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        Text(
                          'Need ${s.runsNeeded}',
                          style: const TextStyle(
                            color: AppTheme.accentText,
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  )
                else
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 8),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryContainer,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.circle, size: 7, color: AppTheme.primary),
                        SizedBox(width: 6),
                        Text(
                          'INNINGS 1',
                          style: TextStyle(
                            color: AppTheme.primary,
                            fontSize: 9,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 9),
              child: Divider(height: 1),
            ),
            _BatterLine(
              name: s.striker,
              stats: s.batsmen[s.striker],
              onStrike: true,
            ),
            _BatterLine(
              name: s.nonStriker,
              stats: s.batsmen[s.nonStriker],
              onStrike: false,
            ),
            const SizedBox(height: 5),
            Row(
              children: [
                const Text(
                  'THIS OVER',
                  style: TextStyle(
                    color: AppTheme.textSecondary,
                    fontSize: 9,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.55,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Row(
                    children: s.thisOverBalls.isEmpty
                        ? const [
                            Text('Ready to bowl',
                                style: TextStyle(
                                    color: AppTheme.textSecondary,
                                    fontSize: 10)),
                          ]
                        : s.thisOverBalls
                            .take(6)
                            .map((ball) => Padding(
                                  padding: const EdgeInsets.only(right: 4),
                                  child: _ScoreBallChip(token: ball),
                                ))
                            .toList(),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 5),
            Row(
              children: [
                const Icon(Icons.sports_cricket,
                    size: 14, color: AppTheme.textSecondary),
                const SizedBox(width: 5),
                Expanded(
                  child: Text(
                    'Bowling: ${s.currentBowler.isEmpty ? '—' : s.currentBowler}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: AppTheme.textSecondary,
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                Flexible(
                  child: Text(
                    '${bowler?.oversDisplay ?? '0.0'} ov  ·  '
                    '${bowler?.runsConceded ?? 0} runs  ·  ${bowler?.wickets ?? 0} wkts',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.end,
                    style: const TextStyle(
                      color: AppTheme.textSecondary,
                      fontSize: 10,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _BatterLine extends StatelessWidget {
  final String name;
  final BatStats? stats;
  final bool onStrike;

  const _BatterLine({
    required this.name,
    required this.stats,
    required this.onStrike,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Icon(
            onStrike ? Icons.sports_cricket : Icons.person_outline_rounded,
            size: 13,
            color: onStrike ? AppTheme.primary : AppTheme.textSecondary,
          ),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              name.isEmpty ? (onStrike ? 'Striker' : 'Non-striker') : name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: onStrike ? AppTheme.textPrimary : AppTheme.textSecondary,
                fontWeight: onStrike ? FontWeight.w700 : FontWeight.w500,
                fontSize: 11,
              ),
            ),
          ),
          Text(
            '${stats?.runs ?? 0} (${stats?.balls ?? 0})',
            style: const TextStyle(
              color: AppTheme.textPrimary,
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(width: 8),
          SizedBox(
            width: 48,
            child: Text(
              '${stats?.strikeRate ?? '0.0'} SR',
              textAlign: TextAlign.end,
              style: const TextStyle(
                color: AppTheme.textSecondary,
                fontSize: 10,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ScoreBallChip extends StatelessWidget {
  final String token;

  const _ScoreBallChip({required this.token});

  @override
  Widget build(BuildContext context) {
    final isWicket = token.toUpperCase() == 'W';
    final isFour = token == '4';
    final isSix = token == '6';
    final isExtra = token.toUpperCase() == 'WD' || token.toUpperCase() == 'NB';
    final background = isWicket
        ? AppTheme.danger
        : isFour
            ? AppTheme.boundaryFour
            : isSix
                ? AppTheme.boundarySix
                : isExtra
                    ? AppTheme.accentContainer
                    : token == '0' || token == '.'
                        ? AppTheme.surfaceSoft
                        : AppTheme.primaryContainer;
    final foreground = isWicket || isSix
        ? Colors.white
        : isFour
            ? AppTheme.textPrimary
            : isExtra
                ? AppTheme.accentText
                : AppTheme.primary;

    return Container(
      width: 22,
      height: 22,
      alignment: Alignment.center,
      decoration: BoxDecoration(color: background, shape: BoxShape.circle),
      child: Text(
        token,
        style: TextStyle(
          color: foreground,
          fontSize: token.length > 1 ? 7 : 9,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}
