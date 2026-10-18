import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../core/app_theme.dart';
import '../../l10n/generated/app_localizations.dart';
import '../../models/intl_match.dart';
import '../../services/cric_api_demo.dart';
import '../../services/cric_api_service.dart';
import 'intl_match_detail_screen.dart';

/// Phase 4 — International Match Center (PRD US-10).
///
/// Three states the screen must never confuse:
///   1. **No API key** → explain how to add one, offer demo data.
///   2. **Demo data**   → show it, but label it loudly.
///   3. **Live data**   → show it (cached for 5 min by the service).
class InternationalScreen extends StatefulWidget {
  const InternationalScreen({super.key, this.service});

  static const String route = '/international';

  /// Injectable for widget tests; defaults to the real client from Provider.
  final CricApiService? service;

  @override
  State<InternationalScreen> createState() => _InternationalScreenState();
}

enum _IntlFilter { live, upcoming, recent }

class _InternationalScreenState extends State<InternationalScreen> {
  late CricApiService _service;

  List<IntlMatch>? _matches;
  CricApiError? _error;
  bool _loading = true;
  bool _demo = false;
  bool _started = false;
  _IntlFilter _filter = _IntlFilter.live;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _service = widget.service ?? context.read<CricApiService>();
    // `didChangeDependencies` also fires on a locale change — without this
    // guard that would re-hit the API (and burn a CricAPI quota unit) every
    // time the user switches language.
    if (!_started) {
      _started = true;
      _load();
    }
  }

  Future<void> _load({bool force = false}) async {
    if (!mounted) return;
    setState(() {
      _loading = true;
      _error = null;
    });

    if (!_service.hasKey) {
      setState(() {
        _loading = false;
        _error = CricApiError.missingKey;
        _demo = false;
      });
      return;
    }

    try {
      final matches = await _service.currentMatches(forceRefresh: force);
      if (!mounted) return;
      setState(() {
        _matches = matches;
        _demo = false;
        _loading = false;
        _error = null;
      });
    } on CricApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.kind;
        _loading = false;
        _demo = false;
      });
    }
  }

  void _loadDemo() {
    setState(() {
      _matches = CricApiDemo.matches;
      _demo = true;
      _loading = false;
      _error = null;
    });
  }

  List<IntlMatch> get _visible {
    final all = _matches ?? const <IntlMatch>[];
    return switch (_filter) {
      _IntlFilter.live => all.where((m) => m.isLive).toList(),
      _IntlFilter.upcoming => all.where((m) => m.isUpcoming).toList(),
      _IntlFilter.recent => all
          .where((m) => m.isCompleted)
          .toList()
        ..sort((a, b) => (b.date ?? DateTime(0)).compareTo(a.date ?? DateTime(0))),
    };
  }

  int _countFor(_IntlFilter filter) {
    final all = _matches ?? const <IntlMatch>[];
    return switch (filter) {
      _IntlFilter.live => all.where((m) => m.isLive).length,
      _IntlFilter.upcoming => all.where((m) => m.isUpcoming).length,
      _IntlFilter.recent => all.where((m) => m.isCompleted).length,
    };
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.intlTitle),
        actions: [
          IconButton(
            tooltip: l10n.retry,
            onPressed: _loading || _error == CricApiError.missingKey ? null : () => _load(force: true),
            icon: const Icon(Icons.refresh_rounded),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () => _load(force: true),
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 28),
          children: [
            if (_demo) _DemoBanner(text: l10n.intlDemoBanner),
            if (_loading) const _LoadingBlock(),
            if (!_loading && _error != null) _buildError(l10n),
            if (!_loading && _error == null) ...[
              _FilterBar(
                selected: _filter,
                counts: {
                  _IntlFilter.live: _countFor(_IntlFilter.live),
                  _IntlFilter.upcoming: _countFor(_IntlFilter.upcoming),
                  _IntlFilter.recent: _countFor(_IntlFilter.recent),
                },
                onChanged: (f) => setState(() => _filter = f),
              ),
              const SizedBox(height: 14),
              if (_visible.isEmpty)
                _EmptyBlock(text: switch (_filter) {
                  _IntlFilter.live => l10n.intlEmptyLive,
                  _IntlFilter.upcoming => l10n.intlEmptyUpcoming,
                  _IntlFilter.recent => l10n.intlEmptyRecent,
                })
              else
                ..._visible.map(
                  (match) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: _MatchCard(
                      match: match,
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => IntlMatchDetailScreen(
                            match: match,
                            service: _service,
                            demo: _demo,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildError(AppLocalizations l10n) {
    final error = _error!;
    if (error == CricApiError.missingKey) {
      return _InfoCard(
        icon: Icons.key_rounded,
        title: l10n.intlNoKeyTitle,
        body: l10n.intlNoKeyBody,
        actionLabel: l10n.intlLoadDemo,
        onAction: _loadDemo,
      );
    }

    final message = switch (error) {
      CricApiError.invalidKey => l10n.intlErrInvalidKey,
      CricApiError.rateLimited => l10n.intlErrRateLimited,
      CricApiError.network => l10n.intlErrNetwork,
      _ => l10n.intlErrGeneric,
    };
    return _InfoCard(
      icon: Icons.cloud_off_rounded,
      title: l10n.intlErrGeneric,
      body: message,
      actionLabel: l10n.retry,
      onAction: () => _load(force: true),
    );
  }
}

// ───────────────────────────────────────────────────────────────────────────
// Pieces
// ───────────────────────────────────────────────────────────────────────────

class _FilterBar extends StatelessWidget {
  const _FilterBar({
    required this.selected,
    required this.counts,
    required this.onChanged,
  });

  final _IntlFilter selected;
  final Map<_IntlFilter, int> counts;
  final ValueChanged<_IntlFilter> onChanged;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final labels = {
      _IntlFilter.live: l10n.intlTabLive,
      _IntlFilter.upcoming: l10n.intlTabUpcoming,
      _IntlFilter.recent: l10n.intlTabRecent,
    };

    return Row(
      children: [
        for (final filter in _IntlFilter.values)
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(
                right: filter == _IntlFilter.values.last ? 0 : 8,
              ),
              child: _FilterChip(
                label: labels[filter]!,
                count: counts[filter] ?? 0,
                selected: selected == filter,
                live: filter == _IntlFilter.live,
                onTap: () => onChanged(filter),
              ),
            ),
          ),
      ],
    );
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.label,
    required this.count,
    required this.selected,
    required this.live,
    required this.onTap,
  });

  final String label;
  final int count;
  final bool selected;
  final bool live;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final active = live && count > 0;
    final background = selected ? AppTheme.primary : AppTheme.surface;
    final foreground = selected ? Colors.white : AppTheme.textPrimary;

    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 11, horizontal: 6),
        decoration: BoxDecoration(
          color: background,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected ? AppTheme.primary : AppTheme.border,
          ),
        ),
        child: Column(
          children: [
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: foreground,
                fontWeight: FontWeight.w700,
                fontSize: 12,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              '$count',
              style: TextStyle(
                color: active
                    ? (selected ? Colors.white : AppTheme.accent)
                    : (selected ? Colors.white70 : AppTheme.textSecondary),
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MatchCard extends StatelessWidget {
  const _MatchCard({required this.match, required this.onTap});

  final IntlMatch match;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final locale = Localizations.localeOf(context).toLanguageTag();
    final dateLabel = match.date == null
        ? ''
        : DateFormat.MMMd(locale).add_Hm().format(match.date!);

    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  _TypeChip(type: match.matchType),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      match.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.titleSmall,
                    ),
                  ),
                  _StatusChip(match: match, l10n: l10n),
                ],
              ),
              const SizedBox(height: 12),
              for (var i = 0; i < match.teams.length; i++)
                Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: _TeamRow(
                    team: match.teams[i],
                    shortName: match.shortNameFor(match.teams[i]),
                    imageUrl: match.imageFor(match.teams[i]),
                    innings: i < match.score.length ? match.score[i] : null,
                  ),
                ),
              const SizedBox(height: 6),
              Text(
                match.status.isEmpty ? dateLabel : match.status,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: match.isLive ? AppTheme.accentText : AppTheme.textSecondary,
                      fontWeight: match.isLive ? FontWeight.w700 : FontWeight.w400,
                    ),
              ),
              if (match.venue.isNotEmpty) ...[
                const SizedBox(height: 6),
                Row(
                  children: [
                    const Icon(Icons.place_outlined,
                        size: 13, color: AppTheme.textSecondary),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        match.venue,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context)
                            .textTheme
                            .bodySmall
                            ?.copyWith(color: AppTheme.textSecondary),
                      ),
                    ),
                    Text(
                      dateLabel,
                      style: Theme.of(context)
                          .textTheme
                          .bodySmall
                          ?.copyWith(color: AppTheme.textSecondary),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _TeamRow extends StatelessWidget {
  const _TeamRow({
    required this.team,
    required this.shortName,
    required this.imageUrl,
    this.innings,
  });

  final String team;
  final String shortName;
  final String imageUrl;
  final IntlInnings? innings;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _TeamAvatar(shortName: shortName, imageUrl: imageUrl),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            team,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context)
                .textTheme
                .bodyMedium
                ?.copyWith(fontWeight: FontWeight.w600),
          ),
        ),
        if (innings != null)
          Text(
            innings!.scoreLabel,
            style: Theme.of(context)
                .textTheme
                .bodyMedium
                ?.copyWith(fontWeight: FontWeight.w700),
          ),
      ],
    );
  }
}

class _TeamAvatar extends StatelessWidget {
  const _TeamAvatar({required this.shortName, required this.imageUrl});

  final String shortName;
  final String imageUrl;

  @override
  Widget build(BuildContext context) {
    return ClipOval(
      child: SizedBox(
        width: 28,
        height: 28,
        child: imageUrl.isEmpty
            ? Container(
                color: AppTheme.surfaceSoft,
                alignment: Alignment.center,
                child: Text(
                  shortName,
                  style: const TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.w800,
                    color: AppTheme.textSecondary,
                  ),
                ),
              )
            : CachedNetworkImage(
                imageUrl: imageUrl,
                fit: BoxFit.cover,
                errorWidget: (_, __, ___) => Container(
                  color: AppTheme.surfaceSoft,
                  alignment: Alignment.center,
                  child: Text(
                    shortName,
                    style: const TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.w800,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                ),
              ),
      ),
    );
  }
}

class _TypeChip extends StatelessWidget {
  const _TypeChip({required this.type});

  final String type;

  @override
  Widget build(BuildContext context) {
    if (type.isEmpty) return const SizedBox.shrink();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: AppTheme.surfaceSoft,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        type.toUpperCase(),
        style: const TextStyle(
          fontSize: 9,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.4,
          color: AppTheme.textSecondary,
        ),
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.match, required this.l10n});

  final IntlMatch match;
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    final (label, color, background) = match.isLive
        ? (l10n.intlLiveNow, Colors.white, AppTheme.accent)
        : match.isCompleted
            ? (l10n.intlCompleted, AppTheme.textSecondary, AppTheme.surfaceSoft)
            : (l10n.intlUpcomingLabel, AppTheme.primary, AppTheme.primaryContainer);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(99),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 9,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.3,
          color: color,
        ),
      ),
    );
  }
}

class _DemoBanner extends StatelessWidget {
  const _DemoBanner({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: AppTheme.accentContainer,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          const Icon(Icons.science_outlined, size: 16, color: AppTheme.accentText),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                fontSize: 12,
                color: AppTheme.accentText,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  const _InfoCard({
    required this.icon,
    required this.title,
    required this.body,
    required this.actionLabel,
    required this.onAction,
  });

  final IconData icon;
  final String title;
  final String body;
  final String actionLabel;
  final VoidCallback onAction;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: AppTheme.primary, size: 26),
            const SizedBox(height: 10),
            Text(title, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 6),
            Text(
              body,
              style: Theme.of(context)
                  .textTheme
                  .bodySmall
                  ?.copyWith(color: AppTheme.textSecondary, height: 1.4),
            ),
            const SizedBox(height: 14),
            FilledButton.tonal(
              onPressed: onAction,
              child: Text(actionLabel),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyBlock extends StatelessWidget {
  const _EmptyBlock({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 40),
      child: Column(
        children: [
          const Icon(Icons.sports_cricket_outlined,
              size: 42, color: AppTheme.textSecondary),
          const SizedBox(height: 12),
          Text(
            text,
            textAlign: TextAlign.center,
            style: Theme.of(context)
                .textTheme
                .bodyMedium
                ?.copyWith(color: AppTheme.textSecondary),
          ),
        ],
      ),
    );
  }
}

class _LoadingBlock extends StatelessWidget {
  const _LoadingBlock();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.only(top: 60),
      child: Center(child: CircularProgressIndicator()),
    );
  }
}
