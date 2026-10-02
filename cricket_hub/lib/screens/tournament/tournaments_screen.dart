import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../core/app_theme.dart';
import '../../models/tournament_model.dart';
import '../../services/tournament_service.dart';
import 'create_tournament_screen.dart';
import 'tournament_detail_screen.dart';

class TournamentsScreen extends StatefulWidget {
  const TournamentsScreen({super.key});

  @override
  State<TournamentsScreen> createState() => _TournamentsScreenState();
}

class _TournamentsScreenState extends State<TournamentsScreen> {
  String _filter = 'All';

  @override
  Widget build(BuildContext context) {
    final service = context.read<TournamentService>();
    return Scaffold(
      appBar: AppBar(
        title: const Text('Tournaments'),
        actions: [
          IconButton.filledTonal(
            tooltip: 'Create tournament',
            onPressed: () => Navigator.pushNamed(
              context,
              CreateTournamentScreen.route,
            ),
            icon: const Icon(Icons.add_rounded),
          ),
          const SizedBox(width: 10),
        ],
      ),
      body: StreamBuilder<List<Tournament>>(
        stream: service.tournamentsStream(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting &&
              !snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return _StateCard(
              icon: Icons.cloud_off_outlined,
              title: 'Couldn’t load tournaments',
              subtitle: 'Check your connection and try again.',
            );
          }
          final all = snapshot.data ?? const <Tournament>[];
          final visible = all.where((tournament) {
            switch (_filter) {
              case 'Live':
                return tournament.status == 'ongoing';
              case 'Upcoming':
                return tournament.status == 'draft' || tournament.status == 'upcoming';
              case 'Completed':
                return tournament.status == 'completed';
              default:
                return true;
            }
          }).toList();

          return ListView(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 112),
            children: [
              Text('Local cups, sorted.',
                  style: Theme.of(context).textTheme.headlineMedium),
              const SizedBox(height: 5),
              Text(
                'Follow fixtures, points and player leaders from one place.',
                style: Theme.of(context)
                    .textTheme
                    .bodyMedium
                    ?.copyWith(color: AppTheme.textSecondary),
              ),
              const SizedBox(height: 15),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: ['All', 'Live', 'Upcoming', 'Completed']
                      .map((filter) => Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: ChoiceChip(
                              label: Text(filter),
                              selected: _filter == filter,
                              showCheckmark: false,
                              selectedColor: AppTheme.primary,
                              labelStyle: TextStyle(
                                color: _filter == filter
                                    ? Colors.white
                                    : AppTheme.textPrimary,
                                fontWeight: FontWeight.w700,
                              ),
                              onSelected: (_) => setState(() => _filter = filter),
                            ),
                          ))
                      .toList(),
                ),
              ),
              const SizedBox(height: 12),
              if (visible.isEmpty)
                _StateCard(
                  icon: Icons.emoji_events_outlined,
                  title: all.isEmpty ? 'Start a local tournament' : 'No ${_filter.toLowerCase()} tournaments',
                  subtitle: all.isEmpty
                      ? 'Create your competition, add teams and let CricketHub build the schedule.'
                      : 'Try another filter, or create a new competition.',
                  actionLabel: all.isEmpty ? 'Create tournament' : null,
                  onAction: all.isEmpty
                      ? () => Navigator.pushNamed(context, CreateTournamentScreen.route)
                      : null,
                )
              else ...visible.map((tournament) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: _TournamentCard(
                      tournament: tournament,
                      onTap: () => Navigator.pushNamed(
                        context,
                        TournamentDetailScreen.route,
                        arguments: tournament.id,
                      ),
                    ),
                  )),
            ],
          );
        },
      ),
    );
  }
}

class _TournamentCard extends StatelessWidget {
  final Tournament tournament;
  final VoidCallback onTap;

  const _TournamentCard({required this.tournament, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final status = _status(tournament);
    final date = tournament.startAt == null
        ? 'Date to be confirmed'
        : DateFormat('d MMM yyyy').format(tournament.startAt!);
    final isLive = tournament.status == 'ongoing';
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: isLive ? const Color(0xFFFFE4E3) : AppTheme.primaryContainer,
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Icon(
                  tournament.isKnockout ? Icons.account_tree_outlined : Icons.sync_alt_rounded,
                  color: isLive ? AppTheme.danger : AppTheme.primary,
                ),
              ),
              const SizedBox(width: 13),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            tournament.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                        ),
                        const SizedBox(width: 7),
                        _StatusPill(label: status, live: isLive),
                      ],
                    ),
                    const SizedBox(height: 5),
                    Text(
                      '${tournament.location}  ·  $date',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context)
                          .textTheme
                          .bodySmall
                          ?.copyWith(color: AppTheme.textSecondary),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${tournament.isKnockout ? 'Knockout' : 'Round robin'}  ·  ${tournament.teamIds.length} teams  ·  ${tournament.totalOvers} overs',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context)
                          .textTheme
                          .labelSmall
                          ?.copyWith(color: AppTheme.primary),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 4),
              const Icon(Icons.chevron_right_rounded, color: AppTheme.textSecondary),
            ],
          ),
        ),
      ),
    );
  }

  String _status(Tournament tournament) {
    if (tournament.status == 'ongoing') return 'LIVE';
    if (tournament.status == 'completed') return 'DONE';
    if (tournament.fixtureGenerationStatus == 'generated') return 'OPEN';
    return 'SETUP';
  }
}

class _StatusPill extends StatelessWidget {
  final String label;
  final bool live;

  const _StatusPill({required this.label, this.live = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: live ? const Color(0xFFFFE4E3) : AppTheme.surfaceSoft,
        borderRadius: BorderRadius.circular(99),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: live ? AppTheme.danger : AppTheme.textSecondary,
          fontSize: 9,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.45,
        ),
      ),
    );
  }
}

class _StateCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final String? actionLabel;
  final VoidCallback? onAction;

  const _StateCard({
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
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Container(
              width: 66,
              height: 66,
              decoration: const BoxDecoration(
                color: AppTheme.primaryContainer,
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 31, color: AppTheme.primary),
            ),
            const SizedBox(height: 14),
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
                  ?.copyWith(color: AppTheme.textSecondary),
            ),
            if (actionLabel != null && onAction != null) ...[
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: onAction,
                icon: const Icon(Icons.add_rounded),
                label: Text(actionLabel!),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
