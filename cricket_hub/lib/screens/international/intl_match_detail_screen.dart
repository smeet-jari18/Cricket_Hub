import 'package:flutter/material.dart';

import '../../core/app_theme.dart';
import '../../l10n/generated/app_localizations.dart';
import '../../models/intl_match.dart';
import '../../services/cric_api_demo.dart';
import '../../services/cric_api_service.dart';

/// Scorecard for one international match.
///
/// The list screen already knows the header (teams, score, status); this screen
/// fetches `/v1/match_info` only for the full scorecard, so opening a match
/// costs exactly one extra API hit.
class IntlMatchDetailScreen extends StatefulWidget {
  const IntlMatchDetailScreen({
    super.key,
    required this.match,
    this.service,
    this.demo = false,
  });

  static const String route = '/intl-match';

  final IntlMatch match;
  final CricApiService? service;

  /// True when the list was demo data — then the scorecard must come from the
  /// bundled fixtures too, not from a network call that has no key.
  final bool demo;

  @override
  State<IntlMatchDetailScreen> createState() => _IntlMatchDetailScreenState();
}

class _IntlMatchDetailScreenState extends State<IntlMatchDetailScreen> {
  IntlMatchDetail? _detail;
  CricApiError? _error;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    if (widget.demo) {
      setState(() {
        _detail = CricApiDemo.detailFor(widget.match.id);
        _loading = false;
      });
      return;
    }

    final service = widget.service;
    if (service == null || !service.hasKey) {
      setState(() {
        _error = CricApiError.missingKey;
        _loading = false;
      });
      return;
    }

    try {
      final detail = await service.matchInfo(widget.match.id);
      if (!mounted) return;
      setState(() {
        _detail = detail;
        _loading = false;
      });
    } on CricApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.kind;
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final match = _detail?.match ?? widget.match;

    return Scaffold(
      appBar: AppBar(title: Text(l10n.intlScorecard)),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 28),
        children: [
          _HeaderCard(match: match),
          const SizedBox(height: 16),
          if (_loading)
            const Padding(
              padding: EdgeInsets.only(top: 40),
              child: Center(child: CircularProgressIndicator()),
            )
          else if (_error != null)
            _ErrorCard(
              message: switch (_error!) {
                CricApiError.missingKey => l10n.intlNoKeyTitle,
                CricApiError.invalidKey => l10n.intlErrInvalidKey,
                CricApiError.rateLimited => l10n.intlErrRateLimited,
                CricApiError.network => l10n.intlErrNetwork,
                CricApiError.badResponse => l10n.intlErrGeneric,
              },
              onRetry: _load,
            )
          else if (_detail == null || !_detail!.hasScorecard)
            Padding(
              padding: const EdgeInsets.only(top: 24),
              child: Text(
                l10n.intlNoScorecard,
                textAlign: TextAlign.center,
                style: Theme.of(context)
                    .textTheme
                    .bodyMedium
                    ?.copyWith(color: AppTheme.textSecondary),
              ),
            )
          else
            for (final innings in _detail!.innings)
              if (innings.batting.isNotEmpty || innings.bowling.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(bottom: 18),
                  child: _InningsCard(innings: innings),
                ),
        ],
      ),
    );
  }
}

class _HeaderCard extends StatelessWidget {
  const _HeaderCard({required this.match});

  final IntlMatch match;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(match.name, style: theme.textTheme.titleMedium),
            const SizedBox(height: 12),
            for (var i = 0; i < match.teams.length; i++)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        match.teams[i],
                        style: theme.textTheme.bodyLarge
                            ?.copyWith(fontWeight: FontWeight.w600),
                      ),
                    ),
                    if (i < match.score.length)
                      Text(
                        match.score[i].scoreLabel,
                        style: theme.textTheme.bodyLarge
                            ?.copyWith(fontWeight: FontWeight.w800),
                      ),
                  ],
                ),
              ),
            if (match.status.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(
                match.status,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: match.isLive ? AppTheme.accentText : AppTheme.textSecondary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
            if (match.venue.isNotEmpty) ...[
              const SizedBox(height: 10),
              Row(
                children: [
                  const Icon(Icons.place_outlined,
                      size: 14, color: AppTheme.textSecondary),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      '${l10n.intlVenue}: ${match.venue}',
                      maxLines: 2,
                      style: theme.textTheme.bodySmall
                          ?.copyWith(color: AppTheme.textSecondary),
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

class _InningsCard extends StatelessWidget {
  const _InningsCard({required this.innings});

  final IntlInningsScorecard innings;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);

    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 14, 14, 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (innings.inning.isNotEmpty) ...[
              Text(innings.inning, style: theme.textTheme.titleSmall),
              const SizedBox(height: 10),
            ],
            if (innings.batting.isNotEmpty) ...[
              Text(
                l10n.intlBatting,
                style: theme.textTheme.labelSmall?.copyWith(
                  color: AppTheme.textSecondary,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.6,
                ),
              ),
              const SizedBox(height: 6),
              _BattingHeader(l10n: l10n),
              const Divider(height: 12, color: AppTheme.border),
              for (final line in innings.batting) _BattingRow(line: line),
              const SizedBox(height: 8),
            ],
            if (innings.bowling.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(
                l10n.intlBowling,
                style: theme.textTheme.labelSmall?.copyWith(
                  color: AppTheme.textSecondary,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.6,
                ),
              ),
              const SizedBox(height: 6),
              _BowlingHeader(l10n: l10n),
              const Divider(height: 12, color: AppTheme.border),
              for (final line in innings.bowling) _BowlingRow(line: line),
            ],
            const SizedBox(height: 6),
          ],
        ),
      ),
    );
  }
}

// Column widths are shared between the header and the rows so the numbers line
// up; changing one means changing its partner.
const Map<String, int> _numFlex = {'runs': 34, 'balls': 30, 'fours': 30, 'sixes': 30, 'sr': 44};

class _BattingHeader extends StatelessWidget {
  const _BattingHeader({required this.l10n});

  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    final style = Theme.of(context).textTheme.labelSmall?.copyWith(
          color: AppTheme.textSecondary,
          fontWeight: FontWeight.w700,
        );
    return Row(
      children: [
        Expanded(flex: 60, child: Text(l10n.intlBatter, style: style)),
        Expanded(flex: _numFlex['runs']!, child: Text(l10n.intlRunsShort, style: style, textAlign: TextAlign.end)),
        Expanded(flex: _numFlex['balls']!, child: Text(l10n.intlBallsShort, style: style, textAlign: TextAlign.end)),
        Expanded(flex: _numFlex['fours']!, child: Text(l10n.intlFours, style: style, textAlign: TextAlign.end)),
        Expanded(flex: _numFlex['sixes']!, child: Text(l10n.intlSixes, style: style, textAlign: TextAlign.end)),
        Expanded(flex: _numFlex['sr']!, child: Text(l10n.intlStrikeRate, style: style, textAlign: TextAlign.end)),
      ],
    );
  }
}

class _BattingRow extends StatelessWidget {
  const _BattingRow({required this.line});

  final IntlBattingLine line;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final numberStyle = theme.textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w600);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                flex: 60,
                child: Text(
                  line.name.isEmpty ? '—' : line.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w700),
                ),
              ),
              Expanded(flex: _numFlex['runs']!, child: Text('${line.runs}', style: numberStyle, textAlign: TextAlign.end)),
              Expanded(flex: _numFlex['balls']!, child: Text('${line.balls}', style: numberStyle, textAlign: TextAlign.end)),
              Expanded(flex: _numFlex['fours']!, child: Text('${line.fours}', style: numberStyle, textAlign: TextAlign.end)),
              Expanded(flex: _numFlex['sixes']!, child: Text('${line.sixes}', style: numberStyle, textAlign: TextAlign.end)),
              Expanded(
                flex: _numFlex['sr']!,
                child: Text(line.strikeRate.toStringAsFixed(1), style: numberStyle, textAlign: TextAlign.end),
              ),
            ],
          ),
          if (line.dismissal.isNotEmpty && line.dismissal.toLowerCase() != 'not out')
            Padding(
              padding: const EdgeInsets.only(top: 1),
              child: Text(
                line.dismissal,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.labelSmall?.copyWith(color: AppTheme.textSecondary),
              ),
            ),
        ],
      ),
    );
  }
}

const Map<String, int> _bowlFlex = {'overs': 34, 'maidens': 28, 'runs': 30, 'wickets': 28, 'eco': 42};

class _BowlingHeader extends StatelessWidget {
  const _BowlingHeader({required this.l10n});

  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    final style = Theme.of(context).textTheme.labelSmall?.copyWith(
          color: AppTheme.textSecondary,
          fontWeight: FontWeight.w700,
        );
    return Row(
      children: [
        Expanded(flex: 62, child: Text(l10n.intlBowler, style: style)),
        Expanded(flex: _bowlFlex['overs']!, child: Text(l10n.intlOversShort, style: style, textAlign: TextAlign.end)),
        Expanded(flex: _bowlFlex['maidens']!, child: Text(l10n.intlMaidensShort, style: style, textAlign: TextAlign.end)),
        Expanded(flex: _bowlFlex['runs']!, child: Text(l10n.intlRunsShort, style: style, textAlign: TextAlign.end)),
        Expanded(flex: _bowlFlex['wickets']!, child: Text(l10n.intlWicketsShort, style: style, textAlign: TextAlign.end)),
        Expanded(flex: _bowlFlex['eco']!, child: Text(l10n.intlEconomy, style: style, textAlign: TextAlign.end)),
      ],
    );
  }
}

class _BowlingRow extends StatelessWidget {
  const _BowlingRow({required this.line});

  final IntlBowlingLine line;

  @override
  Widget build(BuildContext context) {
    final style = Theme.of(context)
        .textTheme
        .bodySmall
        ?.copyWith(fontWeight: FontWeight.w600);
    final overs = line.overs == line.overs.roundToDouble()
        ? line.overs.toStringAsFixed(0)
        : line.overs.toStringAsFixed(1);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Expanded(
            flex: 62,
            child: Text(
              line.name.isEmpty ? '—' : line.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context)
                  .textTheme
                  .bodySmall
                  ?.copyWith(fontWeight: FontWeight.w700),
            ),
          ),
          Expanded(flex: _bowlFlex['overs']!, child: Text(overs, style: style, textAlign: TextAlign.end)),
          Expanded(flex: _bowlFlex['maidens']!, child: Text('${line.maidens}', style: style, textAlign: TextAlign.end)),
          Expanded(flex: _bowlFlex['runs']!, child: Text('${line.runs}', style: style, textAlign: TextAlign.end)),
          Expanded(flex: _bowlFlex['wickets']!, child: Text('${line.wickets}', style: style, textAlign: TextAlign.end)),
          Expanded(
            flex: _bowlFlex['eco']!,
            child: Text(line.economy.toStringAsFixed(1), style: style, textAlign: TextAlign.end),
          ),
        ],
      ),
    );
  }
}

class _ErrorCard extends StatelessWidget {
  const _ErrorCard({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          children: [
            const Icon(Icons.cloud_off_rounded, color: AppTheme.textSecondary, size: 26),
            const SizedBox(height: 10),
            Text(
              message,
              textAlign: TextAlign.center,
              style: Theme.of(context)
                  .textTheme
                  .bodySmall
                  ?.copyWith(color: AppTheme.textSecondary),
            ),
            const SizedBox(height: 12),
            FilledButton.tonal(onPressed: onRetry, child: Text(l10n.retry)),
          ],
        ),
      ),
    );
  }
}
