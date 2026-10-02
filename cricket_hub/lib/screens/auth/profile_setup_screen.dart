import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/app_theme.dart';
import '../../providers/auth_provider.dart';
import '../home/main_shell.dart';

/// New-player profile setup.
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

  static const _battingOptions = ['Right-hand Bat', 'Left-hand Bat'];
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
        const SnackBar(content: Text('Add your name to continue.')),
      );
      return;
    }

    try {
      await context.read<AuthProvider>().completeProfile(
            name: name,
            battingStyle: _battingStyle,
            bowlingStyle: _bowlingStyle,
          );
      if (!mounted) return;
      Navigator.pushReplacementNamed(context, MainShell.route);
    } catch (_) {
      // AuthProvider displays the save error inline.
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();

    return Scaffold(
      appBar: AppBar(title: const Text('Player profile')),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 560),
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
              children: [
                Container(
                  width: 72,
                  height: 72,
                  alignment: Alignment.center,
                  decoration: const BoxDecoration(
                    color: AppTheme.primaryContainer,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.person_rounded,
                      size: 34, color: AppTheme.primary),
                ),
                const SizedBox(height: 16),
                Text(
                  'Introduce yourself',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
                const SizedBox(height: 6),
                Text(
                  'Add a few details so your teammates know who’s at the crease.',
                  textAlign: TextAlign.center,
                  style: Theme.of(context)
                      .textTheme
                      .bodyMedium
                      ?.copyWith(color: AppTheme.textSecondary),
                ),
                const SizedBox(height: 22),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(18),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Player details',
                            style: Theme.of(context).textTheme.titleLarge),
                        const SizedBox(height: 14),
                        TextField(
                          controller: _nameController,
                          autofocus: true,
                          textCapitalization: TextCapitalization.words,
                          textInputAction: TextInputAction.next,
                          decoration: const InputDecoration(
                            labelText: 'Display name',
                            hintText: 'e.g. Rahul Sharma',
                            prefixIcon: Icon(Icons.badge_outlined),
                          ),
                        ),
                        const SizedBox(height: 14),
                        DropdownButtonFormField<String>(
                          initialValue: _battingStyle,
                          decoration: const InputDecoration(
                            labelText: 'Batting style',
                            prefixIcon: Icon(Icons.sports_cricket),
                          ),
                          items: _battingOptions
                              .map((style) => DropdownMenuItem(
                                    value: style,
                                    child: Text(style),
                                  ))
                              .toList(),
                          onChanged: (value) {
                            if (value != null) {
                              setState(() => _battingStyle = value);
                            }
                          },
                        ),
                        const SizedBox(height: 14),
                        DropdownButtonFormField<String>(
                          initialValue: _bowlingStyle,
                          decoration: const InputDecoration(
                            labelText: 'Bowling style',
                            prefixIcon: Icon(Icons.sports_baseball_outlined),
                          ),
                          items: _bowlingOptions
                              .map((style) => DropdownMenuItem(
                                    value: style,
                                    child: Text(style),
                                  ))
                              .toList(),
                          onChanged: (value) {
                            if (value != null) {
                              setState(() => _bowlingStyle = value);
                            }
                          },
                        ),
                        if (auth.errorMessage != null) ...[
                          const SizedBox(height: 12),
                          Text(
                            auth.errorMessage!,
                            style: const TextStyle(
                              color: Color(0xFFB42318),
                              fontSize: 12,
                            ),
                          ),
                        ],
                        const SizedBox(height: 18),
                        ElevatedButton.icon(
                          onPressed: auth.isLoading ? null : _save,
                          icon: auth.isLoading
                              ? const SizedBox(
                                  height: 18,
                                  width: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : const Icon(Icons.sports_cricket),
                          label: Text(auth.isLoading
                              ? 'Saving profile…'
                              : 'Start playing'),
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
