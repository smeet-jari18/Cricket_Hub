import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/app_theme.dart';
import '../../models/team_model.dart';
import '../../providers/auth_provider.dart';
import '../../services/team_service.dart';
import '../team/create_team_screen.dart';

/// Teams and roster management for the signed-in player.
class MyCricketScreen extends StatelessWidget {
  const MyCricketScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final teamService = context.read<TeamService>();
    final uid = auth.firebaseUser?.uid ?? '';

    if (uid.isEmpty) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('My Cricket')),
      body: StreamBuilder<List<Team>>(
        stream: teamService.myTeamsStream(uid),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting &&
              !snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Text('Couldn’t load your teams. Please try again.'),
              ),
            );
          }

          final teams = snapshot.data ?? [];
          return ListView(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 112),
            children: [
              Text(
                'Your squads',
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              const SizedBox(height: 5),
              Text(
                'Manage your teams and keep your playing group together.',
                style: Theme.of(context)
                    .textTheme
                    .bodyMedium
                    ?.copyWith(color: AppTheme.textSecondary),
              ),
              const SizedBox(height: 20),
              if (teams.isEmpty)
                _EmptyTeams(
                  onCreate: () =>
                      Navigator.pushNamed(context, CreateTeamScreen.route),
                )
              else ...[
                Text(
                  '${teams.length} ${teams.length == 1 ? 'team' : 'teams'}',
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                        color: AppTheme.textSecondary,
                      ),
                ),
                const SizedBox(height: 10),
                ...teams.map(
                  (team) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: _TeamCard(team: team),
                  ),
                ),
              ],
            ],
          );
        },
      ),
    );
  }
}

class _TeamCard extends StatelessWidget {
  final Team team;

  const _TeamCard({required this.team});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ExpansionTile(
        tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 7),
        childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        collapsedShape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        leading: Container(
          width: 46,
          height: 46,
          decoration: BoxDecoration(
            color: AppTheme.primaryContainer,
            borderRadius: BorderRadius.circular(14),
          ),
          child: const Icon(Icons.shield, color: AppTheme.primary),
        ),
        title: Text(team.teamName,
            style: Theme.of(context).textTheme.titleMedium),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 3),
          child: Text(
            '${team.city}  ·  ${team.roster.length} players',
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
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 8),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Your squad is ready for its first player.',
                  style: TextStyle(color: AppTheme.textSecondary),
                ),
              ),
            )
          else
            ...team.roster.map(
              (player) => ListTile(
                dense: true,
                contentPadding: EdgeInsets.zero,
                leading: const CircleAvatar(
                  radius: 16,
                  backgroundColor: AppTheme.surfaceSoft,
                  child: Icon(Icons.person_outline,
                      size: 17, color: AppTheme.textSecondary),
                ),
                title: Text(player,
                    style: Theme.of(context).textTheme.bodyMedium),
                trailing: IconButton(
                  tooltip: 'Remove player',
                  icon: const Icon(Icons.close_rounded,
                      size: 18, color: AppTheme.textSecondary),
                  onPressed: () => context
                      .read<TeamService>()
                      .removePlayerFromRoster(team.id, player),
                ),
              ),
            ),
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
              child: const Icon(Icons.groups_rounded,
                  size: 32, color: AppTheme.primary),
            ),
            const SizedBox(height: 14),
            Text('Start with your first team',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 6),
            Text(
              'Add a team name and city, then invite your squad onto the field.',
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
              label: const Text('Create your first team'),
            ),
          ],
        ),
      ),
    );
  }
}

/// Inline roster entry field.
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
    return Row(
      children: [
        Expanded(
          child: TextField(
            controller: _controller,
            textCapitalization: TextCapitalization.words,
            textInputAction: TextInputAction.done,
            onSubmitted: (_) => _addPlayer(),
            decoration: const InputDecoration(
              hintText: 'Add a player',
              prefixIcon: Icon(Icons.person_add_alt_1_rounded),
              contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            ),
          ),
        ),
        const SizedBox(width: 8),
        IconButton.filledTonal(
          tooltip: 'Add player',
          onPressed: _addPlayer,
          icon: const Icon(Icons.add_rounded),
        ),
      ],
    );
  }
}
