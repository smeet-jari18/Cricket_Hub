import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/app_theme.dart';
import '../../models/team_model.dart';
import '../../providers/auth_provider.dart';
import '../../services/team_service.dart';
import '../team/create_team_screen.dart';
import 'career_stats_screen.dart';
import '../../l10n/generated/app_localizations.dart';

/// Personal cricket hub: team management and server-aggregated career stats.
class MyCricketScreen extends StatelessWidget {
  const MyCricketScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final uid = context.watch<AuthProvider>().firebaseUser?.uid ?? '';
    final teamService = context.read<TeamService>();
    if (uid.isEmpty) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: Text(l10n.navMyCricket),
          bottom: const TabBar(
            indicatorColor: AppTheme.primary,
            tabs: [
              Tab(icon: Icon(Icons.groups_outlined), text: 'Teams'),
              Tab(icon: Icon(Icons.insights_outlined), text: 'Career'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _TeamsTab(uid: uid, teamService: teamService),
            const CareerStatsScreen(),
          ],
        ),
      ),
    );
  }
}

class _TeamsTab extends StatelessWidget {
  final String uid;
  final TeamService teamService;

  const _TeamsTab({required this.uid, required this.teamService});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return StreamBuilder<List<Team>>(
      stream: teamService.myTeamsStream(uid),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting && !snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Text(l10n.myCricketErrLoad),
            ),
          );
        }

        final teams = snapshot.data ?? [];
        return ListView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 112),
          children: [
            Text(l10n.myCricketYourSquads, style: Theme.of(context).textTheme.headlineMedium),
            const SizedBox(height: 5),
            Text(
              l10n.myCricketSquadsSub,
              style: Theme.of(context)
                  .textTheme
                  .bodyMedium
                  ?.copyWith(color: AppTheme.textSecondary),
            ),
            const SizedBox(height: 20),
            if (teams.isEmpty)
              _EmptyTeams(
                onCreate: () => Navigator.pushNamed(context, CreateTeamScreen.route),
              )
            else ...[
              Text(
                l10n.teamsCount(teams.length),
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      color: AppTheme.textSecondary,
                    ),
              ),
              const SizedBox(height: 10),
              ...teams.map((team) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: _TeamCard(team: team),
                  )),
            ],
          ],
        );
      },
    );
  }
}

class _TeamCard extends StatelessWidget {
  final Team team;

  const _TeamCard({required this.team});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Card(
      child: ExpansionTile(
        tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 7),
        childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        collapsedShape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        leading: Container(
          width: 46,
          height: 46,
          decoration: BoxDecoration(
            color: AppTheme.primaryContainer,
            borderRadius: BorderRadius.circular(14),
          ),
          child: const Icon(Icons.shield, color: AppTheme.primary),
        ),
        title: Text(team.teamName, style: Theme.of(context).textTheme.titleMedium),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 3),
          child: Text(
            l10n.cityAndPlayers(team.city, team.roster.length),
            style: Theme.of(context)
                .textTheme
                .bodySmall
                ?.copyWith(color: AppTheme.textSecondary),
          ),
        ),
        children: [
          const Divider(height: 1),
          const SizedBox(height: 8),
          if (team.roster.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  l10n.myCricketEmptySquad,
                  style: const TextStyle(color: AppTheme.textSecondary),
                ),
              ),
            )
          else
            ...team.roster.map((player) => ListTile(
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                  leading: const CircleAvatar(
                    radius: 16,
                    backgroundColor: AppTheme.surfaceSoft,
                    child: Icon(Icons.person_outline,
                        size: 17, color: AppTheme.textSecondary),
                  ),
                  title: Text(player, style: Theme.of(context).textTheme.bodyMedium),
                  trailing: IconButton(
                    tooltip: l10n.removePlayer,
                    icon: const Icon(Icons.close_rounded,
                        size: 18, color: AppTheme.textSecondary),
                    onPressed: () => context
                        .read<TeamService>()
                        .removePlayerFromRoster(team.id, player),
                  ),
                )),
          const SizedBox(height: 8),
          _AddPlayerField(teamId: team.id),
        ],
      ),
    );
  }
}

class _EmptyTeams extends StatelessWidget {
  final VoidCallback onCreate;

  const _EmptyTeams({required this.onCreate});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Container(
              width: 68,
              height: 68,
              decoration: const BoxDecoration(
                color: AppTheme.primaryContainer,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.groups_rounded, size: 32, color: AppTheme.primary),
            ),
            const SizedBox(height: 14),
            Text(l10n.myCricketStartTitle,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 6),
            Text(
              l10n.myCricketStartSub,
              textAlign: TextAlign.center,
              style: Theme.of(context)
                  .textTheme
                  .bodyMedium
                  ?.copyWith(color: AppTheme.textSecondary),
            ),
            const SizedBox(height: 18),
            ElevatedButton.icon(
              onPressed: onCreate,
              icon: const Icon(Icons.add_rounded),
              label: Text(l10n.myCricketCreateFirst),
            ),
          ],
        ),
      ),
    );
  }
}

class _AddPlayerField extends StatefulWidget {
  final String teamId;

  const _AddPlayerField({required this.teamId});

  @override
  State<_AddPlayerField> createState() => _AddPlayerFieldState();
}

class _AddPlayerFieldState extends State<_AddPlayerField> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _addPlayer() {
    final name = _controller.text.trim();
    if (name.isEmpty) return;
    context.read<TeamService>().addPlayerToRoster(widget.teamId, name);
    _controller.clear();
    FocusScope.of(context).unfocus();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Row(
      children: [
        Expanded(
          child: TextField(
            controller: _controller,
            textCapitalization: TextCapitalization.words,
            textInputAction: TextInputAction.done,
            onSubmitted: (_) => _addPlayer(),
            decoration: InputDecoration(
              hintText: l10n.addPlayerHint,
              prefixIcon: const Icon(Icons.person_add_alt_1_rounded),
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            ),
          ),
        ),
        const SizedBox(width: 8),
        IconButton.filledTonal(
          tooltip: l10n.addPlayerTooltip,
          onPressed: _addPlayer,
          icon: const Icon(Icons.add_rounded),
        ),
      ],
    );
  }
}
