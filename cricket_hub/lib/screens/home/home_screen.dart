import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/app_theme.dart';
import '../../models/match_model.dart';
import '../../providers/auth_provider.dart';
import '../../services/match_service.dart';
import '../../widgets/live_match_card.dart';
import '../../widgets/player_hero_banner.dart';
import '../match/create_match_screen.dart';
import '../match/live_match_screen.dart';

/// Daylight-first home for grassroots players, captains and scorers.
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final matchService = context.read<MatchService>();
    final displayName = auth.appUser?.displayName.trim();
    final firstName = (displayName == null || displayName.isEmpty)
        ? 'Player'
        : displayName.split(RegExp(r'\s+')).first;

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: StreamBuilder<List<CricketMatch>>(
          stream: matchService.matchesStream(),
          builder: (context, snapshot) {
            final matches = snapshot.data ?? const <CricketMatch>[];
            final liveMatches = matches.where((match) => match.isLive).toList();
            final otherMatches = matches.where((match) => !match.isLive).toList();

            return RefreshIndicator(
              onRefresh: () async {}, // Firestore stream is realtime.
              color: AppTheme.primary,
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 112),
                children: [
                  _HomeHeader(
                    firstName: firstName,
                    onNotificationsTap: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('You’re all caught up.')),
                      );
                    },
                  ),
                  const SizedBox(height: 18),
                  PlayerHeroBanner(
                    eyebrow: 'The local game, elevated',
                    title: 'Your ground.\nYour game.',
                    subtitle: 'Bring your cricket community together.',
                    actionLabel: 'Start a match',
                    onAction: () =>
                        Navigator.pushNamed(context, CreateMatchScreen.route),
                    height: 222,
                  ),
                  const SizedBox(height: 24),
                  _SectionHeading(
                    title: 'Live on the pitch',
                    trailing: liveMatches.isEmpty
                        ? null
                        : _CountPill(count: liveMatches.length),
                  ),
                  const SizedBox(height: 12),
                  if (snapshot.connectionState == ConnectionState.waiting &&
                      matches.isEmpty)
                    const _LoadingCard()
                  else if (snapshot.hasError)
                    const _InlineNotice(
                      icon: Icons.cloud_off_outlined,
                      title: 'Couldn’t load matches',
                      subtitle: 'Check your connection and try again.',
                    )
                  else if (liveMatches.isEmpty)
                    const _InlineNotice(
                      icon: Icons.sports_cricket,
                      title: 'No live matches right now',
                      subtitle: 'The next great innings could be yours.',
                    )
                  else
                    SizedBox(
                      height: 184,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        clipBehavior: Clip.none,
                        itemCount: liveMatches.length,
                        separatorBuilder: (_, __) => const SizedBox(width: 12),
                        itemBuilder: (context, index) {
                          final match = liveMatches[index];
                          return LiveMatchCard(
                            match: match,
                            width: 292,
                            onTap: () => Navigator.pushNamed(
                              context,
                              LiveMatchScreen.route,
                              arguments: match.id,
                            ),
                          );
                        },
                      ),
                    ),
                  const SizedBox(height: 24),
                  _SectionHeading(
                    title: 'Your fixtures',
                    trailing: otherMatches.isNotEmpty
                        ? Text(
                            '${otherMatches.length} matches',
                            style: Theme.of(context).textTheme.labelMedium
                                ?.copyWith(color: AppTheme.textSecondary),
                          )
                        : null,
                  ),
                  const SizedBox(height: 12),
                  if (snapshot.connectionState == ConnectionState.waiting &&
                      matches.isEmpty)
                    const _LoadingCard()
                  else if (otherMatches.isEmpty)
                    _InlineNotice(
                      icon: Icons.calendar_month_outlined,
                      title: 'No fixtures yet',
                      subtitle: 'Set up two teams and schedule your first game.',
                      actionLabel: 'Create match',
                      onAction: () => Navigator.pushNamed(
                        context,
                        CreateMatchScreen.route,
                      ),
                    )
                  else
                    ...otherMatches.map(
                      (match) => Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: _FixtureCard(
                          match: match,
                          onTap: () => Navigator.pushNamed(
                            context,
                            LiveMatchScreen.route,
                            arguments: match.id,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

class _HomeHeader extends StatelessWidget {
  final String firstName;
  final VoidCallback onNotificationsTap;

  const _HomeHeader({
    required this.firstName,
    required this.onNotificationsTap,
  });

  @override
  Widget build(BuildContext context) {
    final hour = DateTime.now().hour;
    final greeting = hour < 12
        ? 'Good morning'
        : hour < 17
            ? 'Good afternoon'
            : 'Good evening';

    return Row(
      children: [
        Container(
          width: 46,
          height: 46,
          decoration: const BoxDecoration(
            color: AppTheme.primaryContainer,
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.sports_cricket, color: AppTheme.primary),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                greeting,
                style: Theme.of(context)
                    .textTheme
                    .bodySmall
                    ?.copyWith(color: AppTheme.textSecondary),
              ),
              Text(
                firstName,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.titleLarge,
              ),
            ],
          ),
        ),
        IconButton.filledTonal(
          onPressed: onNotificationsTap,
          tooltip: 'Notifications',
          style: IconButton.styleFrom(
            backgroundColor: AppTheme.surface,
            foregroundColor: AppTheme.textPrimary,
            side: const BorderSide(color: AppTheme.border),
          ),
          icon: const Icon(Icons.notifications_none_rounded),
        ),
      ],
    );
  }
}

class _SectionHeading extends StatelessWidget {
  final String title;
  final Widget? trailing;

  const _SectionHeading({required this.title, this.trailing});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(title, style: Theme.of(context).textTheme.titleLarge),
        if (trailing != null) trailing!,
      ],
    );
  }
}

class _CountPill extends StatelessWidget {
  final int count;

  const _CountPill({required this.count});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: const Color(0xFFFFE4E3),
        borderRadius: BorderRadius.circular(100),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.circle, size: 7, color: AppTheme.danger),
          const SizedBox(width: 6),
          Text(
            '$count live',
            style: const TextStyle(
              color: Color(0xFFB42318),
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _FixtureCard extends StatelessWidget {
  final CricketMatch match;
  final VoidCallback onTap;

  const _FixtureCard({required this.match, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final isCompleted = match.isCompleted;
    final statusColor = isCompleted ? AppTheme.textSecondary : AppTheme.primary;
    final statusBackground =
        isCompleted ? AppTheme.surfaceSoft : AppTheme.primaryContainer;

    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: statusBackground,
                  borderRadius: BorderRadius.circular(13),
                ),
                child: Icon(
                  isCompleted ? Icons.check_rounded : Icons.event_available,
                  color: statusColor,
                  size: 21,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${match.teamAName}  vs  ${match.teamBName}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 5),
                    Text(
                      '${match.totalOvers} overs  ·  ${_statusText(match.status)}',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppTheme.textSecondary,
                          ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              const Icon(Icons.chevron_right, color: AppTheme.textSecondary),
            ],
          ),
        ),
      ),
    );
  }

  String _statusText(String status) {
    switch (status) {
      case 'completed':
        return 'Completed';
      case 'abandoned':
        return 'Abandoned';
      default:
        return 'Scheduled';
    }
  }
}

class _InlineNotice extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final String? actionLabel;
  final VoidCallback? onAction;

  const _InlineNotice({
    required this.icon,
    required this.title,
    required this.subtitle,
    this.actionLabel,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              width: 46,
              height: 46,
              decoration: const BoxDecoration(
                color: AppTheme.surfaceSoft,
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: AppTheme.textSecondary),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 3),
                  Text(
                    subtitle,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppTheme.textSecondary,
                        ),
                  ),
                  if (actionLabel != null && onAction != null) ...[
                    const SizedBox(height: 10),
                    TextButton.icon(
                      onPressed: onAction,
                      style: TextButton.styleFrom(
                        padding: EdgeInsets.zero,
                        minimumSize: const Size(0, 36),
                        alignment: Alignment.centerLeft,
                      ),
                      icon: const Icon(Icons.add, size: 18),
                      label: Text(actionLabel!),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LoadingCard extends StatelessWidget {
  const _LoadingCard();

  @override
  Widget build(BuildContext context) {
    return const Card(
      child: Padding(
        padding: EdgeInsets.all(20),
        child: Center(
          child: SizedBox(
            width: 22,
            height: 22,
            child: CircularProgressIndicator(strokeWidth: 2.5),
          ),
        ),
      ),
    );
  }
}
