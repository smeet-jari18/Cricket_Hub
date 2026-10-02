import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/auth_provider.dart';
import '../../services/team_service.dart';

/// Flow 2 of App Flow doc: Create Team form.
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
        const SnackBar(
            content: Text('Team name and city are both required')),
      );
      return;
    }

    setState(() => _saving = true);
    final auth = context.read<AuthProvider>();
    final teamService = context.read<TeamService>();

    // NOTE: write rules allow any logged-in user to CREATE a team,
    // and only the admin_uid owner can edit afterwards (Security doc).
    try {
      await teamService.createTeam(
        name: name,
        city: city,
        adminUid: auth.firebaseUser!.uid,
      );
      if (!mounted) return;
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Team "$name" created! 🏏')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not create team: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Create Team')),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          const Center(
            child: CircleAvatar(
              radius: 44,
              backgroundColor: Color(0xFF1E1E1E),
              child: Icon(Icons.shield, size: 44, color: Color(0xFF00BFA5)),
            ),
          ),
          const SizedBox(height: 8),
          const Center(child: Text('Team logo coming soon',
              style: TextStyle(color: Color(0xFFA0A0A0), fontSize: 12))),
          const SizedBox(height: 24),
          TextField(
            controller: _nameController,
            textCapitalization: TextCapitalization.words,
            decoration:
                const InputDecoration(hintText: 'Team name (e.g. Ahmedabad Strikers)'),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _cityController,
            textCapitalization: TextCapitalization.words,
            decoration: const InputDecoration(hintText: 'City'),
          ),
          const SizedBox(height: 32),
          ElevatedButton(
            onPressed: _saving ? null : _createTeam,
            child: _saving
                ? const SizedBox(
                    height: 22,
                    width: 22,
                    child: CircularProgressIndicator(strokeWidth: 2))
                : const Text('Create Team'),
          ),
        ],
      ),
    );
  }
}
