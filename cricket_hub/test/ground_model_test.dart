import 'package:flutter_test/flutter_test.dart';

import 'package:cricket_hub/models/ground_model.dart';

void main() {
  group('Ground hourly rate by date', () {
    final ground = Ground(
      id: 'Gr_1',
      name: 'Suncity Turf',
      ownerUid: 'uid_owner',
      city: 'Ahmedabad',
      address: 'S.G. Highway',
      lat: 23.0,
      lng: 72.5,
      pitchType: 'turf',
      amenities: const ['floodlights', 'parking'],
      photos: const [],
      coverPhotoUrl: '',
      priceWeekdayHourly: 500,
      priceWeekendHourly: 800,
      priceFullDay: 3000,
      openTime: '06:00',
      closeTime: '22:00',
      slotDurationMinutes: 120,
      status: 'active',
      verified: true,
      avgRating: 4.5,
      reviewCount: 10,
      bookingCount: 50,
      groundStats: const {},
    );

    test('uses weekday rate on Monday', () {
      final monday = DateTime(2025, 4, 14); // Monday
      expect(ground.hourlyRateFor(monday), 500);
    });

    test('uses weekend rate on Saturday', () {
      final saturday = DateTime(2025, 4, 19);
      expect(ground.hourlyRateFor(saturday), 800);
    });

    test('uses weekend rate on Sunday', () {
      final sunday = DateTime(2025, 4, 20);
      expect(ground.hourlyRateFor(sunday), 800);
    });
  });

  group('Ground isActive', () {
    test('true when status=active and verified=true', () {
      final g = Ground(
        id: 'g',
        name: 'g',
        ownerUid: 'u',
        city: 'c',
        address: 'a',
        lat: 0,
        lng: 0,
        pitchType: 'turf',
        amenities: const [],
        photos: const [],
        coverPhotoUrl: '',
        priceWeekdayHourly: 100,
        priceWeekendHourly: 100,
        priceFullDay: 0,
        openTime: '06:00',
        closeTime: '22:00',
        slotDurationMinutes: 120,
        status: 'active',
        verified: true,
        avgRating: 0,
        reviewCount: 0,
        bookingCount: 0,
        groundStats: const {},
      );
      expect(g.isActive, isTrue);
    });

    test('false when not verified', () {
      final g = Ground(
        id: 'g',
        name: 'g',
        ownerUid: 'u',
        city: 'c',
        address: 'a',
        lat: 0,
        lng: 0,
        pitchType: 'turf',
        amenities: const [],
        photos: const [],
        coverPhotoUrl: '',
        priceWeekdayHourly: 100,
        priceWeekendHourly: 100,
        priceFullDay: 0,
        openTime: '06:00',
        closeTime: '22:00',
        slotDurationMinutes: 120,
        status: 'active',
        verified: false,
        avgRating: 0,
        reviewCount: 0,
        bookingCount: 0,
        groundStats: const {},
      );
      expect(g.isActive, isFalse);
    });

    test('false when status is not active', () {
      final g = Ground(
        id: 'g',
        name: 'g',
        ownerUid: 'u',
        city: 'c',
        address: 'a',
        lat: 0,
        lng: 0,
        pitchType: 'turf',
        amenities: const [],
        photos: const [],
        coverPhotoUrl: '',
        priceWeekdayHourly: 100,
        priceWeekendHourly: 100,
        priceFullDay: 0,
        openTime: '06:00',
        closeTime: '22:00',
        slotDurationMinutes: 120,
        status: 'paused',
        verified: true,
        avgRating: 0,
        reviewCount: 0,
        bookingCount: 0,
        groundStats: const {},
      );
      expect(g.isActive, isFalse);
    });
  });
}