import 'package:cloud_firestore/cloud_firestore.dart';

/// A single review for a ground or an umpire.
///
/// Matches the schema enforced by `firestore.rules` ->
/// `match /ground_reviews/{reviewId}` / `match /umpire_reviews/{reviewId}`.
class Review {
  final String id;
  final String groundId; // '' for umpire reviews
  final String umpireUid; // '' for ground reviews
  final String reviewerUid;
  final String reviewerName;
  final int rating; // 1..5
  final String text;
  final DateTime? createdAt;

  const Review({
    required this.id,
    required this.groundId,
    required this.umpireUid,
    required this.reviewerUid,
    required this.reviewerName,
    required this.rating,
    required this.text,
    this.createdAt,
  });

  factory Review.fromFirestore(String id, Map<String, dynamic> map) {
    final raw = map['created_at'];
    return Review(
      id: id,
      groundId: (map['ground_id'] ?? '') as String,
      umpireUid: (map['umpire_uid'] ?? '') as String,
      reviewerUid: (map['reviewer_uid'] ?? '') as String,
      reviewerName: (map['reviewer_name'] ?? '') as String,
      rating: (map['rating'] as num?)?.toInt() ?? 0,
      text: (map['text'] ?? '') as String,
      createdAt: raw is Timestamp ? raw.toDate() : null,
    );
  }
}
