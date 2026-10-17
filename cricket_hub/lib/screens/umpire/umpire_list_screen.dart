import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/app_constants.dart';
import '../../core/app_theme.dart';
import '../../models/umpire_model.dart';
import '../../services/umpire_service.dart';
import '../../widgets/rating_stars.dart';
import 'umpire_detail_screen.dart';

/// Sprint 10's `umpire_list_screen.dart`.
///
/// `umpiresByCityStream` existed since Phase 3 but nothing called it, so the
/// menu's "Umpire booking" tile was permanently disabled.
class UmpireListScreen extends StatefulWidget {
  const UmpireListScreen({super.key});

  static const String route = '/umpire-list';

  @override
  State<UmpireListScreen> createState() => _UmpireListScreenState();
}

class _UmpireListScreenState extends State<UmpireListScreen> {
  String _city = AppConstants.supportedCities.first;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Umpires'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(52),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: Row(
              children: [
                const Icon(Icons.location_on_outlined,
                    size: 18, color: AppTheme.textSecondary),
                const SizedBox(width: 8),
                DropdownButton<String>(
                  value: _city,
                  underline: const SizedBox.shrink(),
                  borderRadius: BorderRadius.circular(12),
                  items: [
                    for (final c in AppConstants.supportedCities)
                      DropdownMenuItem(value: c, child: Text(c)),
                  ],
                  onChanged: (v) => setState(() => _city = v ?? _city),
                ),
              ],
            ),
          ),
        ),
      ),
      body: StreamBuilder<List<Umpire>>(
        stream: context.read<UmpireService>().umpiresByCityStream(_city),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return _msg(Icons.error_outline_rounded, 'Could not load umpires',
                '${snapshot.error}');
          }
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final umpires = snapshot.data ?? const <Umpire>[];
          if (umpires.isEmpty) {
            return _msg(
              Icons.record_voice_over_outlined,
              'No umpires in $_city yet',
              'Verified umpires appear here once they finish onboarding.',
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: umpires.length,
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (context, i) => _UmpireCard(umpire: umpires[i]),
          );
        },
      ),
    );
  }

  static Widget _msg(IconData icon, String title, String body) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 48, color: AppTheme.textSecondary),
            const SizedBox(height: 16),
            Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),
            Text(
              body,
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppTheme.textSecondary),
            ),
          ],
        ),
      ),
    );
  }
}

class _UmpireCard extends StatelessWidget {
  const _UmpireCard({required this.umpire});

  final Umpire umpire;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        onTap: () => Navigator.pushNamed(
          context,
          UmpireDetailScreen.route,
          arguments: umpire,
        ),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              CircleAvatar(
                radius: 24,
                backgroundColor: AppTheme.primaryContainer,
                backgroundImage: umpire.photoUrl.isEmpty
                    ? null
                    : NetworkImage(umpire.photoUrl),
                child: umpire.photoUrl.isEmpty
                    ? Text(
                        umpire.displayName.isEmpty
                            ? 'U'
                            : umpire.displayName[0].toUpperCase(),
                        style: const TextStyle(
                          fontWeight: FontWeight.w800,
                          color: AppTheme.primary,
                        ),
                      )
                    : null,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      umpire.displayName.isEmpty
                          ? 'Umpire'
                          : umpire.displayName,
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 3),
                    RatingStars(
                      rating: umpire.avgRating,
                      size: 13,
                      reviewCount: umpire.reviewCount,
                    ),
                    const SizedBox(height: 3),
                    Text(
                      '${umpire.experienceYears} yrs · ${umpire.matchesOfficiated} matches',
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppTheme.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '₹${umpire.hourlyRate}',
                    style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 15,
                    ),
                  ),
                  const Text(
                    'per hour',
                    style: TextStyle(
                      fontSize: 10,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
