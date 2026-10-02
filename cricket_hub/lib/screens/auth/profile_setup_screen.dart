import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/app_theme.dart';
import '../../providers/auth_provider.dart';
import '../home/main_shell.dart';

/// Screen 3: Profile Setup (name + player role) — Flow 1, step 6.
class ProfileSetupScreen extends StatefulWidget {
  const ProfileSetupScreen({super.key});

  static const String route = '/profile-setup';

  @override
  State<ProfileSetupScreen> createState() => _ProfileSetupScreenState();
}

class _ProfileSetupScreenState extends State<ProfileSetupScreen> {
  final _nameController = TextEditingController();
  String _battingStyle = 'Right-hand Bat';
  String _bowlingStyle = 'None';

  static const _battingOptions = [
    'Right-hand Bat',
    'Left-hand Bat',
  ];
  static const _bowlingOptions = [
    'None',
    'Right-arm Fast',
    'Right-arm Medium',
    'Right-arm Off-spin',
    'Left-arm Fast',
    'Left-arm Medium',
    'Left-arm Orthodox',
    'Left-arm Leg-spin (Chinaman)',
  ];

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter your name')),
      );
      return;
    }

    final auth = context.read<AuthProvider>();
    await auth.completeProfile(
      name: name,
      battingStyle: _battingStyle,
      bowlingStyle: _bowlingStyle,
    );
    if (!mounted) return;
    Navigator.pushReplacementNamed(context, MainShell.route);
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();

    return Scaffold(
      appBar: AppBar(title: const Text('Set up your profile')),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          const CircleAvatar(
            radius: 44,
            backgroundColor: AppTheme.surface,
            child: Icon(Icons.person, size: 48, color: AppTheme.primary),
          ),
          const SizedBox(height: 32),
          const Text('Your name'),
          const SizedBox(height: 8),
          TextField(
            controller: _nameController,
            textCapitalization: TextCapitalization.words,
            decoration:
                const InputDecoration(hintText: 'e.g. Rahul Sharma'),
          ),
          const SizedBox(height: 24),

          const Text('Batting style'),
          const SizedBox(height: 8),
          DropdownButtonFormField<String>(
            initialValue: _battingStyle,
            items: _battingOptions
                .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                .toList(),
            onChanged: (v) => setState(() => _battingStyle = v!),
          ),
          const SizedBox(height: 24),

          const Text('Bowling style'),
          const SizedBox(height: 8),
          DropdownButtonFormField<String>(
            initialValue: _bowlingStyle,
            items: _bowlingOptions
                .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                .toList(),
            onChanged: (v) => setState(() => _bowlingStyle = v!),
          ),
          const SizedBox(height: 40),

          ElevatedButton(
            onPressed: auth.isLoading ? null : _save,
            child: auth.isLoading
                ? const SizedBox(
                    height: 22,
                    width: 22,
                    child: CircularProgressIndicator(strokeWidth: 2))
                : const Text('Start Playing'),
          ),
        ],
      ),
    );
  }
}
