import 'package:cricket_hub/screens/umpire/umpire_booking_screen.dart';
import 'package:flutter_test/flutter_test.dart';

/// Price maths for the umpire booking screen.
///
/// These are pure functions — no Firebase, no widgets — so a change to the
/// fee percentage or the full-day fallback fails here first.
void main() {
  group('UmpireBookingWindow catalogue', () {
    test('offers 3 three-hour windows plus a full day', () {
      expect(UmpireBookingWindow.all.length, 4);
      final ids = UmpireBookingWindow.all.map((w) => w.id).toSet();
      expect(ids, {'morning', 'afternoon', 'evening', 'full_day'});
    });

    test('half-day windows are 3 hours, full day is 12', () {
      for (final w in UmpireBookingWindow.all) {
        expect(w.durationMinutes % 60, 0, reason: '${w.id} must be whole hours');
        expect(w.hours, w.isFullDay ? 12 : 3, reason: w.id);
      }
    });

    test('every window has a start before its end', () {
      for (final w in UmpireBookingWindow.all) {
        expect(w.start.compareTo(w.end), lessThan(0), reason: w.id);
      }
    });
  });

  group('Base price', () {
    final morning = UmpireBookingWindow.all
        .firstWhere((w) => w.id == 'morning');
    final fullDay = UmpireBookingWindow.all
        .firstWhere((w) => w.id == 'full_day');

    test('hourly window = hourly rate × hours × 100', () {
      // ₹500/hr × 3h = ₹1500 = 150000 paise
      expect(
        morning.basePricePaise(hourlyRate: 500, dayRate: 4000),
        150000,
      );
    });

    test('full day prefers the day rate', () {
      // day rate ₹4000 wins over 12 × ₹500 = ₹6000
      expect(
        fullDay.basePricePaise(hourlyRate: 500, dayRate: 4000),
        400000,
      );
    });

    test('full day falls back to 12 × hourly when day rate is 0', () {
      expect(
        fullDay.basePricePaise(hourlyRate: 500, dayRate: 0),
        600000,
      );
    });

    test('a zero hourly rate makes the booking unbookable', () {
      expect(morning.basePricePaise(hourlyRate: 0, dayRate: 0), 0);
    });
  });

  group('Platform fee (5%)', () {
    final morning = UmpireBookingWindow.all
        .firstWhere((w) => w.id == 'morning');

    test('is 5% of the base price', () {
      // ₹1500 base -> ₹75 fee = 7500 paise
      expect(
        morning.platformFeePaise(hourlyRate: 500, dayRate: 0),
        7500,
      );
    });

    test('rounds to the nearest paise', () {
      // ₹333/hr × 3h = ₹999 -> 5% = ₹49.95 -> 4995 paise exactly
      expect(
        morning.platformFeePaise(hourlyRate: 333, dayRate: 0),
        4995,
      );
      // ₹123/hr × 3h = ₹369 -> 5% = ₹18.45 -> 1845 paise
      expect(
        morning.platformFeePaise(hourlyRate: 123, dayRate: 0),
        1845,
      );
    });

    test('payout = base − fee, and base = payout + fee', () {
      final base = morning.basePricePaise(hourlyRate: 777, dayRate: 0);
      final fee = morning.platformFeePaise(hourlyRate: 777, dayRate: 0);
      final payout = morning.payoutPaise(hourlyRate: 777, dayRate: 0);
      expect(payout, base - fee);
      expect(payout + fee, base);
      expect(payout, greaterThan(0));
    });
  });
}
