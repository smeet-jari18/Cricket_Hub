import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/app_theme.dart';
import '../../models/team_model.dart';
import '../../providers/auth_provider.dart';
import '../../services/team_service.dart';
import '../team/create_team_screen.dart';

/// "My Cricket" tab: user's teams + roster management.
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
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final teams = snapshot.data ?? [];

          if (teams.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.groups, size: 72, color: AppTheme.textSecondary),
                  const SizedBox(height: 16),
                  const Text('No teams yet',
                      style: TextStyle(fontSize: 18)),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: () => Navigator.pushNamed(
                        context, CreateTeamScreen.route),
                    icon: const Icon(Icons.add),
                    label: const Text('Create your first team'),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.only(bottom: 96, top: 8),
            itemCount: teams.length,
            itemBuilder: (context, i) {
              final team = teams[i];
              return Card(
                child: ExpansionTile(
                  leading: const CircleAvatar(
                    backgroundColor: AppTheme.primary,
                    child: Icon(Icons.shield, color: AppTheme.background),
                  ),
                  title: Text(team.teamName,
                      style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text(
                      '${team.city} • ${team.roster.length} players'),
                  childrenPadding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  children: [
                    if (team.roster.isEmpty)
                      const Text('Squad is empty — add players below.',
                          style: TextStyle(color: AppTheme.textSecondary)),
                    ...team.roster.map(
                      (player) => ListTile(
                        dense: true,
                        leading: const Icon(Icons.person_outline),
                        title: Text(player),
                        trailing: IconButton(
                          icon: const Icon(Icons.close,
                              size: 18, color: AppTheme.textSecondary),
                          onPressed: () => teamService
                              .removePlayerFromRoster(team.id, player),
                        ),
                      ),
                    ),
                    _AddPlayerField(teamId: team.id),
                    const SizedBox(height: 8),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}

/// Small inline field: type name + tap add (simple Phase 1 roster).
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

  @override
  Widget build(BuildContext context) {
    final teamService = context.read<TeamService>();
    return Row(
      children: [
        Expanded(
          child: TextField(
            controller: _controller,
            textCapitalization: TextCapitalization.words,
            decoration: const InputDecoration(
              hintText: 'Player name',
              contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            ),
          ),
        ),
        IconButton(
          icon: const Icon(Icons.add_circle, color: AppTheme.primary),
          onPressed: () {
            if (_controller.text.trim().isNotEmpty) {
              teamService.addPlayerToRoster(
                  widget.teamId, _controller.text);
              _controller.clear();
            }
          },
        ),
      ],
    );
  }
}
