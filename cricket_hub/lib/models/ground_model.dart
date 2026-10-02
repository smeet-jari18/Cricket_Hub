import 'package:cloud_firestore/cloud_firestore.dart';

/// Ground = one document in the `grounds` collection.
/// Matches CricketHub_Backend_Schema_Phase3.md -> Collection: grounds.
class Ground {
  final String id;
  final String name;
  final String ownerUid;
  final String city;
  final String address;
  final double lat;
  final double lng;
  final String pitchType; // 'turf' | 'matting' | 'concrete'
  final List<String> amenities;
  final List<String> photos;
  final String coverPhotoUrl;
  final int priceWeekdayHourly; // INR
  final int priceWeekendHourly; // INR
  final int priceFullDay; // INR (0 if owner does not offer full-day)
  final String openTime; // 'HH:mm' 24h
  final String closeTime; // 'HH:mm'
  final int slotDurationMinutes; // default 120
  final String status; // 'draft' | 'pending_verification' | 'active' | 'paused' | 'banned'
  final bool verified;
  final double avgRating;
  final int reviewCount;
  final int bookingCount;
  final Map<String, dynamic> groundStats;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const Ground({
    required this.id,
    required this.name,
    required this.ownerUid,
    required this.city,
    required this.address,
    required this.lat,
    required this.lng,
    required this.pitchType,
    required this.amenities,
    required this.photos,
    required this.coverPhotoUrl,
    required this.priceWeekdayHourly,
    required this.priceWeekendHourly,
    required this.priceFullDay,
    required this.openTime,
    required this.closeTime,
    required this.slotDurationMinutes,
    required this.status,
    required this.verified,
    required this.avgRating,
    required this.reviewCount,
    required this.bookingCount,
    required this.groundStats,
    this.createdAt,
    this.updatedAt,
  });

  bool get isActive => status == 'active' && verified;

  /// Effective hourly rate for a given date — Saturday/Sunday use [priceWeekendHourly].
  int hourlyRateFor(DateTime date) {
    final weekday = date.weekday; // 1..7 (Mon..Sun)
    return (weekday == DateTime.saturday || weekday == DateTime.sunday)
        ? priceWeekendHourly
        : priceWeekdayHourly;
  }

  factory Ground.fromFirestore(String id, Map<String, dynamic> map) {
    return Ground(
      id: id,
      name: (map['name'] ?? '') as String,
      ownerUid: (map['owner_uid'] ?? '') as String,
      city: (map['city'] ?? '') as String,
      address: (map['address'] ?? '') as String,
      lat: (map['lat'] as num?)?.toDouble() ?? 0.0,
      lng: (map['lng'] as num?)?.toDouble() ?? 0.0,
      pitchType: (map['pitch_type'] ?? 'matting') as String,
      amenities: List<String>.from(map['amenities'] ?? const <String>[]),
      photos: List<String>.from(map['photos'] ?? const <String>[]),
      coverPhotoUrl: (map['cover_photo_url'] ?? '') as String,
      priceWeekdayHourly: (map['price_weekday_hourly'] as num?)?.toInt() ?? 0,
      priceWeekendHourly: (map['price_weekend_hourly'] as num?)?.toInt() ?? 0,
      priceFullDay: (map['price_full_day'] as num?)?.toInt() ?? 0,
      openTime: (map['open_time'] ?? '06:00') as String,
      closeTime: (map['close_time'] ?? '22:00') as String,
      slotDurationMinutes: (map['slot_duration_minutes'] as num?)?.toInt() ?? 120,
      status: (map['status'] ?? 'draft') as String,
      verified: (map['verified'] as bool?) ?? false,
      avgRating: (map['avg_rating'] as num?)?.toDouble() ?? 0.0,
      reviewCount: (map['review_count'] as num?)?.toInt() ?? 0,
      bookingCount: (map['booking_count'] as num?)?.toInt() ?? 0,
      groundStats: map['ground_stats'] is Map
          ? Map<String, dynamic>.from(map['ground_stats'] as Map)
          : const <String, dynamic>{},
      createdAt: _toDate(map['created_at']),
      updatedAt: _toDate(map['updated_at']),
    );
  }

  /// Use during ground creation by an owner (status='draft', verified=false).
  Map<String, dynamic> toCreateMap() {
    return {
      'name': name.trim(),
      'owner_uid': ownerUid,
      'city': city.trim(),
      'address': address.trim(),
      'lat': lat,
      'lng': lng,
      'pitch_type': pitchType,
      'amenities': amenities,
      'photos': photos,
      'cover_photo_url': coverPhotoUrl,
      'price_weekday_hourly': priceWeekdayHourly,
      'price_weekend_hourly': priceWeekendHourly,
      'price_full_day': priceFullDay,
      'open_time': openTime,
      'close_time': closeTime,
      'slot_duration_minutes': slotDurationMinutes,
      'status': 'draft',
      'verified': false,
      'avg_rating': 0.0,
      'review_count': 0,
      'booking_count': 0,
      'ground_stats': const <String, dynamic>{},
      'created_at': FieldValue.serverTimestamp(),
      'updated_at': FieldValue.serverTimestamp(),
    };
  }

  /// Updates only owner-editable fields. Server-owned fields are immutable.
  Map<String, dynamic> toUpdateMap() {
    return {
      'name': name.trim(),
      'city': city.trim(),
      'address': address.trim(),
      'lat': lat,
      'lng': lng,
      'pitch_type': pitchType,
      'amenities': amenities,
      'photos': photos,
      'cover_photo_url': coverPhotoUrl,
      'price_weekday_hourly': priceWeekdayHourly,
      'price_weekend_hourly': priceWeekendHourly,
      'price_full_day': priceFullDay,
      'open_time': openTime,
      'close_time': closeTime,
      'slot_duration_minutes': slotDurationMinutes,
      'status': status,
      'updated_at': FieldValue.serverTimestamp(),
    };
  }
}

DateTime? _toDate(Object? value) {
  if (value is Timestamp) return value.toDate();
  if (value is DateTime) return value;
  if (value is String) return DateTime.tryParse(value);
  return null;
}

/// Per-day inventory at `grounds/{id}/slots/{dateIso}`.
class GroundSlotDay {
  final String dateIso; // 'YYYY-MM-DD'
  final Map<String, SlotEntry> slots;
  final bool blocked;
  final String? blockReason;
  final DateTime? updatedAt;

  const GroundSlotDay({
    required this.dateIso,
    required this.slots,
    required this.blocked,
    this.blockReason,
    this.updatedAt,
  });

  factory GroundSlotDay.fromFirestore(String dateIso, Map<String, dynamic>? map) {
    if (map == null) {
      return GroundSlotDay(dateIso: dateIso, slots: const {}, blocked: false);
    }
    final slotsMap = (map['slots'] is Map) ? map['slots'] as Map : <String, dynamic>{};
    final entries = <String, SlotEntry>{};
    slotsMap.forEach((key, value) {
      if (value is Map) {
        entries[key as String] = SlotEntry.fromMap(Map<String, dynamic>.from(value));
      }
    });
    return GroundSlotDay(
      dateIso: dateIso,
      slots: entries,
      blocked: (map['blocked'] as bool?) ?? false,
      blockReason: (map['block_reason'] ?? '') as String?,
      updatedAt: _toDate(map['updated_at']),
    );
  }
}

class SlotEntry {
  final String status; // 'available' | 'held' | 'booked' | 'blocked'
  final String? heldBy;
  final DateTime? heldUntil;
  final String? bookingId;
  final String? matchId;

  const SlotEntry({
    required this.status,
    this.heldBy,
    this.heldUntil,
    this.bookingId,
    this.matchId,
  });

  factory SlotEntry.available() => const SlotEntry(status: 'available');
  factory SlotEntry.blocked() => const SlotEntry(status: 'blocked');

  factory SlotEntry.fromMap(Map<String, dynamic> map) {
    return SlotEntry(
      status: (map['status'] ?? 'available') as String,
      heldBy: (map['held_by'] ?? '') as String?,
      heldUntil: _toDate(map['held_until']),
      bookingId: (map['booking_id'] ?? '') as String?,
      matchId: (map['match_id'] ?? '') as String?,
    );
  }
}