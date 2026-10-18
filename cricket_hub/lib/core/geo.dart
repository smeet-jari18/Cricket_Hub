/// Small, dependency-free geo + search helpers used by the marketplace list.
///
/// They are pure functions so they can be unit-tested without Firebase,
/// widgets or a GPS permission — see `test/ground_search_test.dart`.
library;

import 'dart:math' as math;

/// Great-circle distance in kilometres between two coordinates (haversine).
///
/// The app has no location permission yet (that is a Phase-3.5 item), so the
/// "Distance" sort measures from the city centre, which is a stable, honest
/// proxy: it never claims to know where the user is standing.
double distanceKm(double lat1, double lng1, double lat2, double lng2) {
  const earthRadiusKm = 6371.0;
  const toRad = 0.017453292519943295; // pi / 180

  final dLat = (lat2 - lat1) * toRad;
  final dLng = (lng2 - lng1) * toRad;
  final a = _sin2(dLat / 2) +
      math.cos(lat1 * toRad) * math.cos(lat2 * toRad) * _sin2(dLng / 2);
  final c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
  return earthRadiusKm * c;
}

double _sin2(double x) => math.sin(x) * math.sin(x);

/// Approximate city centres for the cities `AppConstants.supportedCities`
/// offers. Unknown cities fall back to Ahmedabad.
const Map<String, (double, double)> cityCentres = {
  'Ahmedabad': (23.0225, 72.5714),
  'Mumbai': (19.0760, 72.8777),
  'Bengaluru': (12.9716, 77.5946),
  'Hyderabad': (17.3850, 78.4867),
  'Pune': (18.5204, 73.8567),
};

(double, double) centreOf(String city) =>
    cityCentres[city] ?? cityCentres['Ahmedabad']!;

/// Free-text search across the fields a player actually types.
///
/// Case-insensitive, matches name, city, address and pitch type. An empty or
/// whitespace-only query matches everything.
bool groundMatchesQuery({
  required String query,
  required String name,
  required String city,
  required String address,
  required String pitchType,
}) {
  final q = query.trim().toLowerCase();
  if (q.isEmpty) return true;
  bool hit(String s) => s.toLowerCase().contains(q);
  return hit(name) || hit(city) || hit(address) || hit(pitchType);
}
