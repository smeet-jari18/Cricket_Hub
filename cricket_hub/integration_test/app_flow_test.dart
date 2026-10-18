// Device / emulator-only flow tests.
//
//   firebase emulators:start          (terminal 1)
//   flutter test integration_test/app_flow_test.dart \
//       --dart-define=USE_EMULATOR=true   (terminal 2, with a device attached)
//
// These cannot run in a headless unit-test environment: they boot the real
// app, which calls `Firebase.initializeApp` and needs the emulator suite.
//
// Status: scaffold. Test 1 (splash -> login) is the boot smoke test; the
// deeper Phase-3 flows listed in PHASE3_STATUS.md are still TODO because they
// need a seeded emulator + a device to execute — writing them without being
// able to run them once would just be dead code.

import 'package:cricket_hub/main.dart' as app;
import 'package:cricket_hub/screens/auth/login_screen.dart';
import 'package:cricket_hub/screens/umpire/umpire_booking_screen.dart';
import 'package:cricket_hub/models/umpire_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  // ---------------------------------------------------------------------------
  // T1 — boot smoke: the app starts and lands on the login screen.
  //      Needs: `firebase emulators:start` + --dart-define=USE_EMULATOR=true
  // ---------------------------------------------------------------------------
  testWidgets('T1 splash boots and routes to Login', (tester) async {
    await app.main();

    // Splash paints the cricket icon before AuthProvider resolves.
    expect(find.byIcon(Icons.sports_cricket), findsWidgets);

    // Wait for the auth stream to settle, then the redirect happens.
    await tester.pumpAndSettle(const Duration(seconds: 10));

    expect(
      find.byType(LoginScreen),
      findsOneWidget,
      reason: 'A signed-out app must land on the login screen.',
    );
  });

  // ---------------------------------------------------------------------------
  // T2 — umpire booking screen renders the 4 windows and the 5% fee line.
  //      No Firebase needed for the build; the booking call is not triggered.
  // ---------------------------------------------------------------------------
  testWidgets('T2 umpire booking screen shows windows and price breakdown',
      (tester) async {
    const umpire = Umpire(
      uid: 'umpire_test',
      displayName: 'Ramesh Bhai',
      phoneNumber: '+910000000000',
      city: 'Ahmedabad',
      experienceYears: 8,
      certifications: [],
      dayRate: 4000,
      hourlyRate: 500,
      bio: '',
      photoUrl: '',
      verified: true,
      avgRating: 4.5,
      reviewCount: 12,
      matchesOfficiated: 40,
      status: 'active',
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (ctx) => Scaffold(
            body: Center(
              child: ElevatedButton(
                onPressed: () => Navigator.push(
                  ctx,
                  MaterialPageRoute<void>(
                    settings: const RouteSettings(
                      name: UmpireBookingScreen.route,
                      arguments: umpire,
                    ),
                    builder: (_) => const UmpireBookingScreen(),
                  ),
                ),
                child: const Text('open'),
              ),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    // All four windows are offered.
    expect(find.text('Morning'), findsOneWidget);
    expect(find.text('Afternoon'), findsOneWidget);
    expect(find.text('Evening'), findsOneWidget);
    expect(find.text('Full day'), findsOneWidget);

    // Morning is selected by default: 3h × ₹500 = ₹1500, fee 5% = ₹75.
    expect(find.textContaining('₹1500'), findsWidgets);
    expect(find.textContaining('₹75'), findsWidgets);
  });

  // ---------------------------------------------------------------------------
  // TODO (needs a seeded emulator + device):
  //   T3  login via emulator phone OTP -> MainShell
  //   T5  ground list -> ground detail -> checkout (COD)
  //   T6  booking appears in My bookings as pending_payment
  //   T9  owner dashboard -> confirm cash -> booking becomes confirmed
  //   T10 umpire dashboard -> booking requests -> confirm cash
  // ---------------------------------------------------------------------------
}
