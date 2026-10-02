import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/app_theme.dart';
import '../../providers/auth_provider.dart';
import '../../services/team_service.dart';

/// Create a club or local side.
class CreateTeamScreen extends StatefulWidget {
  const CreateTeamScreen({super.key});

  static const String route = '/create-team';

  @override
  State<CreateTeamScreen> createState() => _CreateTeamScreenState();
}

class _CreateTeamScreenState extends State<CreateTeamScreen> {
  final _nameController = TextEditingController();
  final _cityController = TextEditingController();
  bool _saving = false;

  @override
  void dispose() {
    _nameController.dispose();
    _cityController.dispose();
    super.dispose();
  }

  Future<void> _createTeam() async {
    final name = _nameController.text.trim();
    final city = _cityController.text.trim();

    if (name.isEmpty || city.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Add both a team name and a city.')),
      );
      return;
    }

    setState(() => _saving = true);
    try {
      final auth = context.read<AuthProvider>();
      await context.read<TeamService>().createTeam(
            name: name,
            city: city,
            adminUid: auth.firebaseUser!.uid,
          );
      if (!mounted) return;
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('$name is ready for match day.')),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not create team: $error')),
      );
      setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Create a team')),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 560),
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
              children: [
                Container(
                  width: 78,
                  height: 78,
                  alignment: Alignment.center,
                  decoration: const BoxDecoration(
                    color: AppTheme.primaryContainer,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.shield,
                      size: 38, color: AppTheme.primary),
                ),
                const SizedBox(height: 16),
                Text(
                  'Build your squad',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
                const SizedBox(height: 6),
                Text(
                  'Give your side a name and a home city. You can add players next.',
                  textAlign: TextAlign.center,
                  style: Theme.of(context)
                      .textTheme
                      .bodyMedium
                      ?.copyWith(color: AppTheme.textSecondary),
                ),
                const SizedBox(height: 24),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(18),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Team details',
                            style: Theme.of(context).textTheme.titleLarge),
                        const SizedBox(height: 16),
                        TextField(
                          controller: _nameController,
                          textCapitalization: TextCapitalization.words,
                          textInputAction: TextInputAction.next,
                          decoration: const InputDecoration(
                            labelText: 'Team name',
                            hintText: 'e.g. Ahmedabad Strikers',
                            prefixIcon: Icon(Icons.groups_rounded),
                          ),
                        ),
                        const SizedBox(height: 14),
                        TextField(
                          controller: _cityController,
                          textCapitalization: TextCapitalization.words,
                          textInputAction: TextInputAction.done,
                          onSubmitted: (_) {
                            if (!_saving) _createTeam();
                          },
                          decoration: const InputDecoration(
                            labelText: 'Home city',
                            hintText: 'e.g. Ahmedabad',
                            prefixIcon: Icon(Icons.location_on_outlined),
                          ),
                        ),
                        const SizedBox(height: 20),
                        ElevatedButton.icon(
                          onPressed: _saving ? null : _createTeam,
                          icon: _saving
                              ? const SizedBox(
                                  height: 18,
                                  width: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : const Icon(Icons.add_rounded),
                          label: Text(_saving ? 'Creating team…' : 'Create team'),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
