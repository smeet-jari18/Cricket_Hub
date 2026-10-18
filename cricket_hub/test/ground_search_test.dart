import 'package:cricket_hub/core/geo.dart';
import 'package:flutter_test/flutter_test.dart';

/// The marketplace list's search + "distance" sort are pure helpers in
/// lib/core/geo.dart. They are pinned here because both used to be dead
/// controls: `onChanged` was a no-op and the distance comparator returned 0
/// for every pair.
void main() {
  group('distanceKm (haversine)', () {
    test('is zero for the same point', () {
      expect(distanceKm(23.0225, 72.5714, 23.0225, 72.5714), closeTo(0, 1e-9));
    });

    test('Ahmedabad → Mumbai is roughly 440 km', () {
      final d = distanceKm(23.0225, 72.5714, 19.0760, 72.8777);
      expect(d, greaterThan(420));
      expect(d, lessThan(470));
    });

    test('is symmetric', () {
      final ab = distanceKm(23.0225, 72.5714, 12.9716, 77.5946);
      final ba = distanceKm(12.9716, 77.5946, 23.0225, 72.5714);
      expect(ab, closeTo(ba, 1e-6));
    });

    test('a point 1 degree of latitude away is ~111 km', () {
      expect(distanceKm(23, 72, 24, 72), closeTo(111.2, 1.0));
    });
  });

  group('centreOf', () {
    test('knows every supported city', () {
      for (final city in [
        'Ahmedabad',
        'Mumbai',
        'Bengaluru',
        'Hyderabad',
        'Pune',
      ]) {
        final (lat, lng) = centreOf(city);
        expect(lat, inInclusiveRange(-90, 90));
        expect(lng, inInclusiveRange(-180, 180));
      }
    });

    test('falls back to Ahmedabad for an unknown city', () {
      expect(centreOf('Atlantis'), centreOf('Ahmedabad'));
    });
  });

  group('groundMatchesQuery', () {
    const name = 'Sardar Patel Cricket Ground';
    const city = 'Ahmedabad';
    const address = 'Nr. SG Highway, Ahmedabad';
    const pitch = 'turf';

    bool matches(String q) => groundMatchesQuery(
          query: q,
          name: name,
          city: city,
          address: address,
          pitchType: pitch,
        );

    test('empty query matches everything', () {
      expect(matches(''), isTrue);
      expect(matches('   '), isTrue);
    });

    test('matches name, case-insensitively', () {
      expect(matches('sardar'), isTrue);
      expect(matches('SARDAR'), isTrue);
      expect(matches('patel cricket'), isTrue);
    });

    test('matches city, address and pitch type', () {
      expect(matches('ahmedabad'), isTrue);
      expect(matches('sg highway'), isTrue);
      expect(matches('turf'), isTrue);
    });

    test('does not match unrelated text', () {
      expect(matches('mumbai'), isFalse);
      expect(matches('matting'), isFalse);
    });

    test('trims surrounding whitespace', () {
      expect(matches('  patel  '), isTrue);
    });
  });
}
