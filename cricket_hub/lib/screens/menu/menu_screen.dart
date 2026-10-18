import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/app_theme.dart';
import '../../l10n/generated/app_localizations.dart';
import '../../providers/auth_provider.dart';
import '../../services/admin_service.dart';
import '../admin/admin_verification_screen.dart';
import '../auth/login_screen.dart';
import '../booking/my_bookings_screen.dart';
import '../ground/ground_list_screen.dart';
import '../international/international_screen.dart';
import '../owner/owner_dashboard.dart';
import '../settings/language_screen.dart';
import '../umpire/umpire_dashboard.dart';
import '../umpire/umpire_list_screen.dart';

/// Player profile, account options and phase roadmap.
///
/// Phase 4: every string here goes through [AppLocalizations], and the two
/// "coming soon" rows are now real screens (International scores, Language).
class MenuScreen extends StatelessWidget {
  const MenuScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final auth = context.watch<AuthProvider>();
    final user = auth.appUser;
    final name = user?.displayName.trim().isNotEmpty == true
        ? user!.displayName
        : l10n.menuPlayer;

    return Scaffold(
      appBar: AppBar(title: Text(l10n.menuProfileTitle)),
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
          Text(l10n.menuSeason, style: Theme.of(context).textTheme.titleLarge),
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
                      Text(l10n.menuCareerStats,
                          style: Theme.of(context).textTheme.titleMedium),
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 9, vertical: 5),
                        decoration: BoxDecoration(
                          color: AppTheme.primaryContainer,
                          borderRadius: BorderRadius.circular(99),
                        ),
                        child: Text(
                          l10n.menuComingSoon,
                          style: const TextStyle(
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
                    children: [
                      _StatPlaceholder(label: l10n.menuRuns),
                      _StatPlaceholder(label: l10n.menuWickets),
                      _StatPlaceholder(label: l10n.menuAverage),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text(
                    l10n.menuCareerBody,
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
          Text(l10n.menuExplore, style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 10),
          Card(
            child: Column(
              children: [
                _MenuTile(
                  icon: Icons.grass_rounded,
                  title: l10n.menuGroundBooking,
                  subtitle: l10n.menuGroundBookingSub,
                  onTap: () => Navigator.pushNamed(
                    context,
                    GroundListScreen.route,
                  ),
                ),
                const Divider(height: 1, indent: 68),
                _MenuTile(
                  icon: Icons.record_voice_over_rounded,
                  title: l10n.menuUmpireBooking,
                  subtitle: l10n.menuUmpireBookingSub,
                  onTap: () => Navigator.pushNamed(
                    context,
                    UmpireListScreen.route,
                  ),
                ),
                const Divider(height: 1, indent: 68),
                _MenuTile(
                  icon: Icons.event_note_rounded,
                  title: l10n.menuMyBookings,
                  subtitle: l10n.menuMyBookingsSub,
                  onTap: () => Navigator.pushNamed(
                    context,
                    MyBookingsScreen.route,
                  ),
                ),
                const Divider(height: 1, indent: 68),
                // Phase 4 — was a disabled "coming soon" row until this round.
                _MenuTile(
                  icon: Icons.public_rounded,
                  title: l10n.menuInternational,
                  subtitle: l10n.menuInternationalSub,
                  onTap: () => Navigator.pushNamed(
                    context,
                    InternationalScreen.route,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          Text(l10n.menuForOwners,
              style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 10),
          Card(
            child: Column(
              children: [
                _MenuTile(
                  icon: Icons.stadium_rounded,
                  title: l10n.menuOwnerPanel,
                  subtitle: l10n.menuOwnerPanelSub,
                  onTap: () => Navigator.pushNamed(
                    context,
                    OwnerDashboard.route,
                  ),
                ),
                const Divider(height: 1, indent: 68),
                _MenuTile(
                  icon: Icons.sports_rounded,
                  title: l10n.menuUmpireDashboard,
                  subtitle: l10n.menuUmpireDashboardSub,
                  onTap: () => Navigator.pushNamed(
                    context,
                    UmpireDashboard.route,
                  ),
                ),
              ],
            ),
          ),
          const _AdminEntry(),
          const SizedBox(height: 18),
          Card(
            child: _MenuTile(
              icon: Icons.translate_rounded,
              title: l10n.menuLanguage,
              subtitle: l10n.menuLanguageSub,
              onTap: () => Navigator.pushNamed(context, LanguageScreen.route),
            ),
          ),
          const SizedBox(height: 18),
          OutlinedButton.icon(
            onPressed: () => _confirmSignOut(context),
            icon: const Icon(Icons.logout_rounded, color: AppTheme.danger),
            label: Text(l10n.menuLogout,
                style: const TextStyle(color: AppTheme.danger)),
          ),
          const SizedBox(height: 16),
          Text(
            l10n.menuTagline,
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
    final l10n = AppLocalizations.of(context);
    final shouldSignOut = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(l10n.menuLogoutTitle),
        content: Text(l10n.menuLogoutBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: Text(l10n.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: Text(l10n.menuLogout),
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

/// A menu row. When [onTap] is null the row renders as a disabled "coming
/// soon" entry (lock icon) — Phase 4 leaves none of those behind in this
/// screen, but the state stays for future rows.
class _MenuTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback? onTap;

  const _MenuTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final enabled = onTap != null;
    return ListTile(
      onTap: onTap,
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: enabled ? AppTheme.primaryContainer : AppTheme.surfaceSoft,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(
          icon,
          size: 20,
          color: enabled ? AppTheme.primary : AppTheme.textSecondary,
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
      trailing: Icon(
        enabled ? Icons.chevron_right_rounded : Icons.lock_outline_rounded,
        size: 17,
        color: AppTheme.textSecondary,
      ),
    );
  }
}

/// Renders nothing unless the signed-in user has an `/admins/{uid}` document.
/// Rules also make `/admins/{uid}` readable only by its owner, so a normal
/// user never even learns whether other admins exist.
class _AdminEntry extends StatelessWidget {
  const _AdminEntry();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final uid = context.watch<AuthProvider>().appUser?.uid;
    if (uid == null) return const SizedBox.shrink();

    return StreamBuilder<bool>(
      stream: context.read<AdminService>().isAdminStream(uid),
      builder: (context, snapshot) {
        if (snapshot.data != true) return const SizedBox.shrink();
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 18),
            Text(l10n.menuStaff, style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 10),
            Card(
              child: _MenuTile(
                icon: Icons.verified_user_rounded,
                title: l10n.menuVerificationQueue,
                subtitle: l10n.menuVerificationQueueSub,
                onTap: () => Navigator.pushNamed(
                  context,
                  AdminVerificationScreen.route,
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
