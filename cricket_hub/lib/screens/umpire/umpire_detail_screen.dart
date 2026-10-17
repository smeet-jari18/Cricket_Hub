import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/app_theme.dart';
import '../../models/review_model.dart';
import '../../models/umpire_model.dart';
import '../../services/review_service.dart';
import '../../widgets/rating_stars.dart';
import '../booking/leave_review_screen.dart';

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
    final arg = ModalRoute.of(context)?.settings.arguments;
    if (arg is! Umpire) {
      return Scaffold(
        appBar: AppBar(title: const Text('Umpire')),
        body: const Center(child: Text('No umpire selected.')),
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
    return Scaffold(
      appBar: AppBar(title: Text(umpire.displayName)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _Hero(umpire: umpire),
          const SizedBox(height: 16),
          if (umpire.bio.isNotEmpty) ...[
            _Card(
              title: 'About',
              child: Text(
                umpire.bio,
                style: const TextStyle(fontSize: 13, height: 1.5),
              ),
            ),
            const SizedBox(height: 12),
          ],
          _Card(
            title: 'Experience',
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
            title: 'Certifications',
            child: umpire.certifications.isEmpty
                ? const Text(
                    'None listed yet.',
                    style: TextStyle(color: AppTheme.textSecondary),
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
                                const Text(
                                  'unverified',
                                  style: TextStyle(
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
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: ElevatedButton(
            onPressed: umpire.isActive
                ? () => Navigator.pushNamed(
                      context,
                      LeaveReviewScreen.route,
                      arguments: LeaveReviewArgs(
                        bookingId: '',
                        groundId: '',
                        groundName: umpire.displayName,
                        umpireUid: umpire.uid,
                      ),
                    )
                : null,
            child: Text(
              umpire.isActive ? 'Leave a review' : 'Not available for booking',
            ),
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
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'REVIEWS',
              style: TextStyle(
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
                  return const Text(
                    'No reviews yet.',
                    style: TextStyle(
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
