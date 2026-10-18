import 'package:cricket_hub/screens/owner/owner_edit_ground_screen.dart';
import 'package:cricket_hub/screens/umpire/umpire_edit_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Validation rules behind the two new edit screens.
///
/// The validators are static + pure so they can be pinned here without
/// pumping a form or touching Firestore.
void main() {
  group('OwnerEditGroundScreen.validateName', () {
    test('rejects empty and whitespace', () {
      expect(validateGroundName(''), isNotNull);
      expect(validateGroundName('   '), isNotNull);
      expect(validateGroundName(null), isNotNull);
    });

    test('rejects fewer than 3 characters', () {
      expect(validateGroundName('AB'), isNotNull);
    });

    test('accepts a normal ground name', () {
      expect(validateGroundName('Sardar Patel Ground'),
          isNull);
    });
  });

  group('OwnerEditGroundScreen.validateAddress', () {
    test('rejects empty', () {
      expect(validateGroundAddress(''), isNotNull);
      expect(validateGroundAddress(null), isNotNull);
    });

    test('accepts a real address', () {
      expect(
        validateGroundAddress('Nr. SG Highway, Ahmedabad'),
        isNull,
      );
    });
  });

  group('OwnerEditGroundScreen.validatePrice', () {
    test('rejects non-numbers', () {
      expect(validateGroundPrice('abc'), isNotNull);
      expect(validateGroundPrice(''), isNotNull);
    });

    test('hourly price must be greater than zero', () {
      expect(validateGroundPrice('0'), isNotNull);
      expect(validateGroundPrice('-100'), isNotNull);
      expect(validateGroundPrice('1200'), isNull);
    });

    test('full-day price may be zero (= not offered)', () {
      expect(
        validateGroundPrice('0', allowZero: true),
        isNull,
      );
      expect(
        validateGroundPrice('-1', allowZero: true),
        isNotNull,
      );
    });
  });

  group('OwnerEditGroundScreen.validateHours', () {
    test('closing must be after opening', () {
      expect(
        validateGroundHours(
          open: const TimeOfDay(hour: 22, minute: 0),
          close: const TimeOfDay(hour: 6, minute: 0),
          slotMinutes: 60,
        ),
        isNotNull,
      );
    });

    test('closing equal to opening is rejected', () {
      expect(
        validateGroundHours(
          open: const TimeOfDay(hour: 10, minute: 0),
          close: const TimeOfDay(hour: 10, minute: 0),
          slotMinutes: 60,
        ),
        isNotNull,
      );
    });

    test('must leave room for at least one slot', () {
      expect(
        validateGroundHours(
          open: const TimeOfDay(hour: 10, minute: 0),
          close: const TimeOfDay(hour: 11, minute: 0),
          slotMinutes: 120,
        ),
        isNotNull,
      );
    });

    test('accepts 06:00–22:00 with 120-minute slots', () {
      expect(
        validateGroundHours(
          open: const TimeOfDay(hour: 6, minute: 0),
          close: const TimeOfDay(hour: 22, minute: 0),
          slotMinutes: 120,
        ),
        isNull,
      );
    });
  });

  group('UmpireEditScreen validation', () {
    test('name is required', () {
      expect(validateUmpireName(''), isNotNull);
      expect(validateUmpireName('Ramesh Bhai'), isNull);
    });

    test('experience is a whole number between 0 and 60', () {
      expect(validateUmpireExperience('-1'), isNotNull);
      expect(validateUmpireExperience('61'), isNotNull);
      expect(validateUmpireExperience('abc'), isNotNull);
      expect(validateUmpireExperience('7'), isNull);
      expect(validateUmpireExperience('0'), isNull);
    });

    test('hourly rate must be above zero', () {
      expect(validateUmpireHourly('0'), isNotNull);
      expect(validateUmpireHourly('-5'), isNotNull);
      expect(validateUmpireHourly('500'), isNull);
    });

    test('day rate may be zero (full-day not offered)', () {
      expect(validateUmpireDay('0'), isNull);
      expect(validateUmpireDay('-1'), isNotNull);
      expect(validateUmpireDay('4000'), isNull);
    });
  });
}
