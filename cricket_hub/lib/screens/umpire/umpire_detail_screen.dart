import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/app_theme.dart';
import '../../models/review_model.dart';
import '../../models/umpire_model.dart';
import '../../services/review_service.dart';
import '../../widgets/rating_stars.dart';
import 'umpire_booking_screen.dart';
import '../../l10n/generated/app_localizations.dart';

/// Sprint 10's `umpire_detail_screen.dart` — profile, certifications, rates and
/// (read-only) reviews.
///
/// Booking an umpire reuses the same `createBookingHold` Cloud Function with
/// `kind: 'umpire'`, but the availability picker for umpires is
/// `UmpireAvailabilityScreen`; from there the organizer books a slot.
class UmpireDetailScreen extends StatelessWidget {
  const UmpireDetailScreen({super.key});

  static const String route = '/umpire-detail';

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final arg = ModalRoute.of(context)?.settings.arguments;
    if (arg is! Umpire) {
      return Scaffold(
        appBar: AppBar(title: Text(l10n.umpire)),
        body: Center(child: Text(l10n.noUmpireSelected)),
      );
    }
    return _Body(umpire: arg);
  }
}

class _Body extends StatelessWidget {
  const _Body({required this.umpire});

  final Umpire umpire;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(umpire.displayName)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _Hero(umpire: umpire),
          const SizedBox(height: 16),
          if (umpire.bio.isNotEmpty) ...[
            _Card(
              title: l10n.about,
              child: Text(
                umpire.bio,
                style: const TextStyle(fontSize: 13, height: 1.5),
              ),
            ),
            const SizedBox(height: 12),
          ],
          _Card(
            title: l10n.experience,
            child: Column(
              children: [
                _row('Years umpiring', '${umpire.experienceYears}'),
                _row('Matches officiated', '${umpire.matchesOfficiated}'),
                _row('City', umpire.city),
              ],
            ),
          ),
          const SizedBox(height: 12),
          _Card(
            title: l10n.certifications,
            child: umpire.certifications.isEmpty
                ? Text(
                    l10n.none_listed_yet,
                    style: const TextStyle(color: AppTheme.textSecondary),
                  )
                : Column(
                    children: [
                      for (final c in umpire.certifications)
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          child: Row(
                            children: [
                              Icon(
                                c.verified
                                    ? Icons.verified_rounded
                                    : Icons.schedule_rounded,
                                size: 16,
                                color: c.verified
                                    ? AppTheme.boundaryFour
                                    : AppTheme.textSecondary,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  c.name,
                                  style: const TextStyle(fontSize: 13),
                                ),
                              ),
                              if (!c.verified)
                                Text(
                                  l10n.unverified,
                                  style: const TextStyle(
                                    fontSize: 10,
                                    color: AppTheme.textSecondary,
                                  ),
                                ),
                            ],
                          ),
                        ),
                    ],
                  ),
          ),
          const SizedBox(height: 12),
          _ReviewsCard(umpireUid: umpire.uid),
        ],
      ),
      // No "leave a review" button here on purpose: a review must reference a
      // completed booking (firestore.rules requires booking_id + status
      // 'completed' + reviewer == organizer). The entry point is the booking
      // itself — Booking Detail -> "Rate this umpire".
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              ElevatedButton.icon(
                onPressed: umpire.isActive
                    ? () => Navigator.pushNamed(
                          context,
                          UmpireBookingScreen.route,
                          arguments: umpire,
                        )
                    : null,
                icon: const Icon(Icons.event_available_rounded, size: 18),
                label: Text(
                  umpire.isActive
                      ? 'Book this umpire'
                      : 'Not available for booking',
                ),
              ),
              const SizedBox(height: 6),
              Text(
                l10n.you_can_rate_an_umpire_after,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary),
              ),
            ],
          ),
        ),
      ),
    );
  }

  static Widget _row(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 13,
              color: AppTheme.textSecondary,
            ),
          ),
          Text(
            value,
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }
}

class _Hero extends StatelessWidget {
  const _Hero({required this.umpire});

  final Umpire umpire;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppTheme.primary, AppTheme.primaryBright],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          CircleAvatar(
            radius: 34,
            backgroundColor: Colors.white24,
            backgroundImage: umpire.photoUrl.isEmpty
                ? null
                : NetworkImage(umpire.photoUrl),
            child: umpire.photoUrl.isEmpty
                ? Text(
                    umpire.displayName.isEmpty
                        ? 'U'
                        : umpire.displayName[0].toUpperCase(),
                    style: const TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                    ),
                  )
                : null,
          ),
          const SizedBox(height: 12),
          Text(
            umpire.displayName,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 6),
          RatingStars(
            rating: umpire.avgRating,
            size: 16,
            showValue: true,
            reviewCount: umpire.reviewCount,
          ),
          const SizedBox(height: 14),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _stat('₹${umpire.hourlyRate}', 'per hour'),
              Container(width: 1, height: 28, color: Colors.white24),
              _stat('₹${umpire.dayRate}', 'per day'),
            ],
          ),
        ],
      ),
    );
  }

  static Widget _stat(String value, String label) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            fontSize: 18,
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

class _Card extends StatelessWidget {
  const _Card({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title.toUpperCase(),
              style: const TextStyle(
                fontSize: 10,
                letterSpacing: 1,
                fontWeight: FontWeight.w800,
                color: AppTheme.textSecondary,
              ),
            ),
            const SizedBox(height: 10),
            child,
          ],
        ),
      ),
    );
  }
}

class _ReviewsCard extends StatelessWidget {
  const _ReviewsCard({required this.umpireUid});

  final String umpireUid;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.reviews,
              style: const TextStyle(
                fontSize: 10,
                letterSpacing: 1,
                fontWeight: FontWeight.w800,
                color: AppTheme.textSecondary,
              ),
            ),
            const SizedBox(height: 10),
            StreamBuilder<List<Review>>(
              stream:
                  context.read<ReviewService>().umpireReviewsStream(umpireUid),
              builder: (context, snapshot) {
                final reviews = snapshot.data ?? const <Review>[];
                if (reviews.isEmpty) {
                  return Text(
                    l10n.no_reviews_yet_2,
                    style: const TextStyle(
                      fontSize: 13,
                      color: AppTheme.textSecondary,
                    ),
                  );
                }
                return Column(
                  children: [
                    for (final r in reviews.take(5))
                      Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                RatingStars(
                                  rating: r.rating.toDouble(),
                                  size: 13,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  r.reviewerName.isEmpty
                                      ? 'Player'
                                      : r.reviewerName,
                                  style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ],
                            ),
                            if (r.text.isNotEmpty) ...[
                              const SizedBox(height: 4),
                              Text(
                                r.text,
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: AppTheme.textSecondary,
                                  height: 1.4,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
