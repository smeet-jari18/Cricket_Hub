import 'package:cloud_firestore/cloud_firestore.dart';

/// Umpire = one document in the `umpires` collection. Document ID = user UID.
class Umpire {
  final String uid;
  final String displayName;
  final String phoneNumber;
  final String city;
  final int experienceYears;
  final List<UmpireCertification> certifications;
  final int dayRate; // INR
  final int hourlyRate; // INR
  final String bio;
  final String photoUrl;
  final bool verified;
  final double avgRating;
  final int reviewCount;
  final int matchesOfficiated;
  final String status; // 'draft' | 'pending_verification' | 'active' | 'paused'
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const Umpire({
    required this.uid,
    required this.displayName,
    required this.phoneNumber,
    required this.city,
    required this.experienceYears,
    required this.certifications,
    required this.dayRate,
    required this.hourlyRate,
    required this.bio,
    required this.photoUrl,
    required this.verified,
    required this.avgRating,
    required this.reviewCount,
    required this.matchesOfficiated,
    required this.status,
    this.createdAt,
    this.updatedAt,
  });

  bool get isActive => status == 'active' && verified;

  factory Umpire.fromFirestore(String uid, Map<String, dynamic> map) {
    final certs = (map['certifications'] as List?)
            ?.whereType<Map>()
            .map((c) => UmpireCertification.fromMap(Map<String, dynamic>.from(c)))
            .toList() ??
        const <UmpireCertification>[];
    return Umpire(
      uid: uid,
      displayName: (map['display_name'] ?? '') as String,
      phoneNumber: (map['phone_number'] ?? '') as String,
      city: (map['city'] ?? '') as String,
      experienceYears: (map['experience_years'] as num?)?.toInt() ?? 0,
      certifications: certs,
      dayRate: (map['day_rate'] as num?)?.toInt() ?? 0,
      hourlyRate: (map['hourly_rate'] as num?)?.toInt() ?? 0,
      bio: (map['bio'] ?? '') as String,
      photoUrl: (map['photo_url'] ?? '') as String,
      verified: (map['verified'] as bool?) ?? false,
      avgRating: (map['avg_rating'] as num?)?.toDouble() ?? 0.0,
      reviewCount: (map['review_count'] as num?)?.toInt() ?? 0,
      matchesOfficiated: (map['matches_officiated'] as num?)?.toInt() ?? 0,
      status: (map['status'] ?? 'draft') as String,
      createdAt: _toDate(map['created_at']),
      updatedAt: _toDate(map['updated_at']),
    );
  }

  Map<String, dynamic> toCreateMap() {
    return {
      'user_uid': uid,
      'display_name': displayName.trim(),
      'phone_number': phoneNumber.trim(),
      'city': city.trim(),
      'experience_years': experienceYears,
      'certifications': certifications.map((c) => c.toMap()).toList(),
      'day_rate': dayRate,
      'hourly_rate': hourlyRate,
      'bio': bio.trim(),
      'photo_url': photoUrl,
      'status': 'draft',
      'verified': false,
      'avg_rating': 0.0,
      'review_count': 0,
      'matches_officiated': 0,
      'created_at': FieldValue.serverTimestamp(),
      'updated_at': FieldValue.serverTimestamp(),
    };
  }
}

class UmpireCertification {
  final String name;
  final String documentUrl;
  final bool verified;

  const UmpireCertification({
    required this.name,
    required this.documentUrl,
    required this.verified,
  });

  factory UmpireCertification.fromMap(Map<String, dynamic> map) {
    return UmpireCertification(
      name: (map['name'] ?? '') as String,
      documentUrl: (map['document_url'] ?? '') as String,
      verified: (map['verified'] as bool?) ?? false,
    );
  }

  Map<String, dynamic> toMap() => {
        'name': name,
        'document_url': documentUrl,
        'verified': verified,
      };
}

DateTime? _toDate(Object? value) {
  if (value is Timestamp) return value.toDate();
  if (value is DateTime) return value;
  if (value is String) return DateTime.tryParse(value);
  return null;
}