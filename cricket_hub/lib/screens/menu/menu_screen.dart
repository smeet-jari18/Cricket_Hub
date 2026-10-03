import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/app_theme.dart';
import '../../providers/auth_provider.dart';
import '../auth/login_screen.dart';
import '../ground/ground_list_screen.dart';

/// Player profile, account options and phase roadmap.
class MenuScreen extends StatelessWidget {
  const MenuScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final user = auth.appUser;
    final name = user?.displayName.trim().isNotEmpty == true
        ? user!.displayName
        : 'Player';

    return Scaffold(
      appBar: AppBar(title: const Text('Your profile')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 29,
                    backgroundColor: AppTheme.primaryContainer,
                    backgroundImage: (user?.avatarUrl.isNotEmpty ?? false)
                        ? NetworkImage(user!.avatarUrl)
                        : null,
                    child: (user?.avatarUrl.isNotEmpty ?? false)
                        ? null
                        : const Icon(Icons.person_rounded,
                            size: 29, color: AppTheme.primary),
                  ),
                  const SizedBox(width: 15),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(name,
                            style: Theme.of(context).textTheme.titleLarge),
                        const SizedBox(height: 4),
                        Text(
                          [user?.battingStyle, user?.bowlingStyle]
                              .where((style) => style != null && style.isNotEmpty)
                              .join('  ·  '),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context)
                              .textTheme
                              .bodySmall
                              ?.copyWith(color: AppTheme.textSecondary),
                        ),
                      ],
                    ),
                  ),
                  const Icon(Icons.verified_rounded,
                      size: 19, color: AppTheme.primary),
                ],
              ),
            ),
          ),
          const SizedBox(height: 18),
          Text('Your season', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 10),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.insights_rounded,
                          color: AppTheme.primary, size: 20),
                      const SizedBox(width: 8),
                      Text('Career stats',
                          style: Theme.of(context).textTheme.titleMedium),
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 9, vertical: 5),
                        decoration: BoxDecoration(
                          color: AppTheme.primaryContainer,
                          borderRadius: BorderRadius.circular(99),
                        ),
                        child: const Text(
                          'COMING SOON',
                          style: TextStyle(
                            color: AppTheme.primary,
                            fontSize: 9,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: const [
                      _StatPlaceholder(label: 'RUNS'),
                      _StatPlaceholder(label: 'WICKETS'),
                      _StatPlaceholder(label: 'AVERAGE'),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'Your match history and leaderboards will live here.',
                    style: Theme.of(context)
                        .textTheme
                        .bodySmall
                        ?.copyWith(color: AppTheme.textSecondary),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),
          Text('Explore', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 10),
          Card(
            child: Column(
              children: [
                _ExploreTile(
                  icon: Icons.grass_rounded,
                  title: 'Ground booking',
                  subtitle: 'Find a place for your next game',
                  onTap: () => Navigator.pushNamed(
                    context,
                    GroundListScreen.route,
                  ),
                ),
                const Divider(height: 1, indent: 68),
                const _ExploreTile(
                  icon: Icons.record_voice_over_rounded,
                  title: 'Umpire booking',
                  subtitle: 'Bring an official to match day',
                  comingSoon: true,
                ),
                const Divider(height: 1, indent: 68),
                const _ExploreTile(
                  icon: Icons.public_rounded,
                  title: 'International scores',
                  subtitle: 'Follow the wider cricket world',
                  comingSoon: true,
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          OutlinedButton.icon(
            onPressed: () => _confirmSignOut(context),
            icon: const Icon(Icons.logout_rounded, color: AppTheme.danger),
            label: const Text('Log out',
                style: TextStyle(color: AppTheme.danger)),
          ),
          const SizedBox(height: 16),
          Text(
            'CricketHub  ·  Local cricket. Pro level.',
            textAlign: TextAlign.center,
            style: Theme.of(context)
                .textTheme
                .bodySmall
                ?.copyWith(color: AppTheme.textSecondary),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmSignOut(BuildContext context) async {
    final shouldSignOut = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Log out?'),
        content: const Text('You can sign back in anytime to return to your teams.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Log out'),
          ),
        ],
      ),
    );
    if (shouldSignOut != true || !context.mounted) return;

    await context.read<AuthProvider>().signOut();
    if (!context.mounted) return;
    Navigator.pushNamedAndRemoveUntil(
      context,
      LoginScreen.route,
      (route) => false,
    );
  }
}

class _StatPlaceholder extends StatelessWidget {
  final String label;

  const _StatPlaceholder({required this.label});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('—',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800)),
          Text(
            label,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: AppTheme.textSecondary,
                  fontSize: 9,
                  letterSpacing: 0.6,
                ),
          ),
        ],
      ),
    );
  }
}

class _ExploreTile extends StatelessWidget {
  const _ExploreTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    this.onTap,
    this.comingSoon = false,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback? onTap;
  final bool comingSoon;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: comingSoon ? null : onTap,
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: AppTheme.surfaceSoft,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(
          icon,
          size: 20,
          color: comingSoon ? AppTheme.textSecondary : AppTheme.primary,
        ),
      ),
      title: Text(title, style: Theme.of(context).textTheme.titleSmall),
      subtitle: Text(
        subtitle,
        style: Theme.of(context)
            .textTheme
            .bodySmall
            ?.copyWith(color: AppTheme.textSecondary),
      ),
      trailing: comingSoon
          ? Container(
              padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
              decoration: BoxDecoration(
                color: AppTheme.primaryContainer,
                borderRadius: BorderRadius.circular(99),
              ),
              child: const Text(
                'COMING SOON',
                style: TextStyle(
                  color: AppTheme.primary,
                  fontSize: 9,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.4,
                ),
              ),
            )
          : const Icon(
              Icons.chevron_right_rounded,
              size: 20,
              color: AppTheme.primary,
            ),
    );
  }
}
