import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/app_theme.dart';
import '../../models/umpire_model.dart';
import '../../providers/auth_provider.dart';
import '../../services/umpire_service.dart';
import '../../widgets/rating_stars.dart';
import 'umpire_availability_screen.dart';
import 'umpire_booking_requests_screen.dart';
import 'umpire_edit_screen.dart';
import 'umpire_onboarding_screen.dart';
import '../../l10n/generated/app_localizations.dart';

/// Sprint 10's `umpire_dashboard.dart` — the umpire's own home: status,
/// earnings rates, rating, and a link to their availability calendar.
class UmpireDashboard extends StatelessWidget {
  const UmpireDashboard({super.key});

  static const String route = '/umpire-dashboard';

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final uid = context.watch<AuthProvider>().appUser?.uid;
    if (uid == null) {
      return Scaffold(
        appBar: AppBar(title: Text(l10n.umpire)),
        body: Center(child: Text(l10n.commonPleaseSignIn)),
      );
    }

    return StreamBuilder<Umpire?>(
      stream: context.read<UmpireService>().umpireStream(uid),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Scaffold(
            appBar: AppBar(title: Text(l10n.umpire)),
            body: const Center(child: CircularProgressIndicator()),
          );
        }
        final umpire = snapshot.data;
        if (umpire == null) {
          return Scaffold(
            appBar: AppBar(title: Text(l10n.umpire)),
            body: _NotRegistered(),
          );
        }
        return _Dashboard(umpire: umpire);
      },
    );
  }
}

class _NotRegistered extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.record_voice_over_outlined,
                size: 48, color: AppTheme.textSecondary),
            const SizedBox(height: 16),
            Text(
              l10n.you_are_not_listed_as_an,
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            Text(
              l10n.create_a_profile_and_get_verified,
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppTheme.textSecondary),
            ),
            const SizedBox(height: 18),
            ElevatedButton(
              onPressed: () => Navigator.pushNamed(
                context,
                UmpireOnboardingScreen.route,
              ),
              child: Text(l10n.become_an_umpire),
            ),
          ],
        ),
      ),
    );
  }
}

class _Dashboard extends StatelessWidget {
  const _Dashboard({required this.umpire});

  final Umpire umpire;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(l10n.menuUmpireDashboard)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [AppTheme.primary, AppTheme.primaryBright],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  umpire.status.replaceAll('_', ' ').toUpperCase(),
                  style: const TextStyle(
                    fontSize: 10,
                    letterSpacing: 1.2,
                    fontWeight: FontWeight.w800,
                    color: Colors.white70,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  umpire.displayName,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 8),
                RatingStars(
                  rating: umpire.avgRating,
                  size: 14,
                  reviewCount: umpire.reviewCount,
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    _stat('${umpire.matchesOfficiated}', 'matches'),
                    const SizedBox(width: 28),
                    _stat('₹${umpire.hourlyRate}', 'per hour'),
                    const SizedBox(width: 28),
                    _stat('₹${umpire.dayRate}', 'per day'),
                  ],
                ),
              ],
            ),
          ),
          if (!umpire.verified && umpire.status != 'pending_verification') ...[
            const SizedBox(height: 12),
            Card(
              color: AppTheme.accentContainer,
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Row(
                  children: [
                    const Icon(Icons.info_outline_rounded, size: 18),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        l10n.draftProfileHelp,
                        style: const TextStyle(fontSize: 12),
                      ),
                    ),
                    TextButton(
                      onPressed: () async {
                        await context
                            .read<UmpireService>()
                            .submitForVerification(umpire.uid);
                        if (!context.mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text(l10n.submitted)),
                        );
                      },
                      child: Text(l10n.submit),
                    ),
                  ],
                ),
              ),
            ),
          ],
          const SizedBox(height: 16),
          Card(
            child: ListTile(
              leading: const Icon(Icons.event_available_rounded,
                  color: AppTheme.primary),
              title: Text(l10n.myAvailability),
              subtitle: Text(l10n.block_dates_you_cannot_officiate),
              trailing: const Icon(Icons.chevron_right_rounded),
              onTap: () => Navigator.pushNamed(
                context,
                UmpireAvailabilityScreen.route,
                arguments: umpire,
              ),
            ),
          ),
          const SizedBox(height: 10),
          Card(
            child: ListTile(
              leading: const Icon(Icons.inbox_rounded, color: AppTheme.accent),
              title: Text(l10n.booking_requests),
              subtitle: Text(l10n.confirm_cash_you_received_from_organizers),
              trailing: const Icon(Icons.chevron_right_rounded),
              onTap: () => Navigator.pushNamed(
                context,
                UmpireBookingRequestsScreen.route,
              ),
            ),
          ),
          const SizedBox(height: 10),
          Card(
            child: ListTile(
              leading: const Icon(Icons.edit_outlined, color: AppTheme.primary),
              title: Text(l10n.edit_profile),
              subtitle: Text(l10n.name_bio_experience_and_rates),
              trailing: const Icon(Icons.chevron_right_rounded),
              onTap: () => Navigator.pushNamed(
                context,
                UmpireEditScreen.route,
                arguments: umpire,
              ),
            ),
          ),
        ],
      ),
    );
  }

  static Widget _stat(String value, String label) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          value,
          style: const TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w800,
            color: Colors.white,
          ),
        ),
        Text(
          label,
          style: const TextStyle(fontSize: 11, color: Colors.white70),
        ),
      ],
    );
  }
}
