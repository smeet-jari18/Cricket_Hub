import 'package:cloud_firestore/cloud_firestore.dart';

import '../core/app_constants.dart';
import '../models/review_model.dart';

/// Reviews for grounds and umpires (Sprint 11).
///
/// `ground_reviews` / `umpire_reviews` rules and the `aggregateGroundRating`
/// Cloud Function existed since Phase 3, but nothing ever wrote a review, so
/// `avg_rating` stayed at 0 forever. This closes that loop.
class ReviewService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _groundReviews =>
      _db.collection(AppConstants.groundReviewsCol);

  CollectionReference<Map<String, dynamic>> get _umpireReviews =>
      _db.collection(AppConstants.umpireReviewsCol);

  /// Client-side mirror of the rule checks, so the user gets a readable
  /// message instead of `permission-denied`.
  ///
  /// `booking_id` is mandatory: `firestore.rules` only accepts a review when
  /// that booking exists, belongs to the reviewer, targets this exact
  /// ground/umpire, and is `completed`.
  static void _validate({
    required int rating,
    required String text,
    required String bookingId,
  }) {
    if (bookingId.trim().isEmpty) {
      throw ArgumentError(
        'A review needs a completed booking. Book first, then rate.',
      );
    }
    if (rating < 1 || rating > 5) {
      throw ArgumentError('Rating must be between 1 and 5.');
    }
    if (text.length > 500) {
      throw ArgumentError('Review text must be 500 characters or fewer.');
    }
  }

  /// Writes a ground review.
  ///
  /// The rules require exactly this shape:
  ///   reviewer_uid == request.auth.uid,
  ///   rating is int in 1..5,
  ///   text.size() <= 500
  /// Anything else is rejected server-side, so validate on the client too to
  /// give the user a readable message instead of `permission-denied`.
  Future<void> submitGroundReview({
    required String groundId,
    required String bookingId,
    required String reviewerUid,
    required String reviewerName,
    required int rating,
    required String text,
  }) async {
    _validate(rating: rating, text: text, bookingId: bookingId);
    await _groundReviews.add({
      'ground_id': groundId,
      'booking_id': bookingId,
      'reviewer_uid': reviewerUid,
      'reviewer_name': reviewerName,
      'rating': rating,
      'text': text,
      'created_at': FieldValue.serverTimestamp(),
    });
  }

  Future<void> submitUmpireReview({
    required String umpireUid,
    required String bookingId,
    required String reviewerUid,
    required String reviewerName,
    required int rating,
    required String text,
  }) async {
    _validate(rating: rating, text: text, bookingId: bookingId);
    await _umpireReviews.add({
      'umpire_uid': umpireUid,
      'booking_id': bookingId,
      'reviewer_uid': reviewerUid,
      'reviewer_name': reviewerName,
      'rating': rating,
      'text': text,
      'created_at': FieldValue.serverTimestamp(),
    });
  }

  /// Newest-first reviews for a ground.
  Stream<List<Review>> groundReviewsStream(String groundId, {int limit = 30}) {
    return _groundReviews
        .where('ground_id', isEqualTo: groundId)
        .orderBy('created_at', descending: true)
        .limit(limit)
        .snapshots()
        .map((snap) =>
            snap.docs.map((d) => Review.fromFirestore(d.id, d.data())).toList());
  }

  /// Newest-first reviews for an umpire.
  Stream<List<Review>> umpireReviewsStream(String umpireUid, {int limit = 30}) {
    return _umpireReviews
        .where('umpire_uid', isEqualTo: umpireUid)
        .orderBy('created_at', descending: true)
        .limit(limit)
        .snapshots()
        .map((snap) =>
            snap.docs.map((d) => Review.fromFirestore(d.id, d.data())).toList());
  }
}
