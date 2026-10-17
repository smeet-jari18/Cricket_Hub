import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart' show FirebaseAuth;
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'core/app_navigator.dart';
import 'core/app_theme.dart';
import 'firebase_options.dart';
import 'providers/auth_provider.dart';
import 'screens/auth/login_screen.dart';
import 'screens/auth/otp_screen.dart';
import 'screens/auth/profile_setup_screen.dart';
import 'screens/booking/booking_checkout_screen.dart';
import 'screens/booking/booking_detail_screen.dart';
import 'screens/booking/booking_success_screen.dart';
import 'screens/booking/checkout_args.dart';
import 'screens/booking/leave_review_screen.dart';
import 'screens/booking/my_bookings_screen.dart';
import 'screens/ground/ground_calendar_screen.dart';
import 'screens/ground/ground_detail_screen.dart';
import 'screens/ground/ground_list_screen.dart';
import 'screens/home/main_shell.dart';
import 'screens/match/create_match_screen.dart';
import 'screens/match/live_match_screen.dart';
import 'screens/match/scoring_dashboard_screen.dart';
import 'screens/match/toss_screen.dart';
import 'screens/owner/owner_calendar_screen.dart';
import 'screens/owner/owner_create_ground_screen.dart';
import 'screens/owner/owner_dashboard.dart';
import 'screens/owner/owner_earnings_screen.dart';
import 'screens/owner/owner_qr_scanner_screen.dart';
import 'screens/splash_screen.dart';
import 'screens/team/create_team_screen.dart';
import 'screens/tournament/create_tournament_screen.dart';
import 'screens/tournament/tournament_detail_screen.dart';
import 'screens/umpire/umpire_availability_screen.dart';
import 'screens/umpire/umpire_dashboard.dart';
import 'screens/umpire/umpire_detail_screen.dart';
import 'screens/umpire/umpire_list_screen.dart';
import 'screens/umpire/umpire_onboarding_screen.dart';
import 'services/booking_service.dart';
import 'services/ground_service.dart';
import 'services/match_service.dart';
import 'services/notification_service.dart';
import 'services/payment_service.dart';
import 'services/payout_service.dart';
import 'services/review_service.dart';
import 'services/team_service.dart';
import 'services/tournament_service.dart';
import 'services/umpire_service.dart';

/// ================================================
/// CricketHub — Phase 1 + Phase 2 + Phase 3
/// Flutter + Dart + Firebase (see README.md for setup)
/// ================================================
final NotificationService appNotificationService = NotificationService();

// ───────────────────────────────────────────────────────────────────────────
// Local Firebase Emulator Suite — free testing, no Blaze plan needed.
//
//   flutter run --dart-define=USE_EMULATOR=true
//
// Android emulator: "localhost" is auto-mapped to 10.0.2.2 by the plugins.
// Physical phone:   pass your PC's LAN IP —
//   flutter run --dart-define=USE_EMULATOR=true \
//               --dart-define=EMULATOR_HOST=192.168.1.42
//
// Start the suite with:  firebase emulators:start
// ───────────────────────────────────────────────────────────────────────────
const bool _useEmulator = bool.fromEnvironment('USE_EMULATOR');
const String _emulatorHost =
    String.fromEnvironment('EMULATOR_HOST', defaultValue: 'localhost');

Future<void> _connectEmulators() async {
  await FirebaseAuth.instance.useAuthEmulator(_emulatorHost, 9099);
  FirebaseFirestore.instance.useFirestoreEmulator(_emulatorHost, 8080);
  FirebaseFunctions.instanceFor(region: 'asia-south1')
      .useFunctionsEmulator(_emulatorHost, 5001);
  debugPrint('🔥 Emulators → $_emulatorHost '
      '(auth:9099 · firestore:8080 · functions:5001)');
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Generate lib/firebase_options.dart with `flutterfire configure`.
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  if (_useEmulator) {
    await _connectEmulators();
  }

  // Local cache on the phone -> scoring writes queue offline and sync later.
  FirebaseFirestore.instance.settings = const Settings(
    persistenceEnabled: true,
    cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED,
  );
  await appNotificationService.initialize();

  runApp(const CricketHubApp());
}

class CricketHubApp extends StatelessWidget {
  const CricketHubApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        // Services (Firebase talk)
        Provider<MatchService>(create: (_) => MatchService()),
        Provider<TeamService>(create: (_) => TeamService()),
        Provider<TournamentService>(create: (_) => TournamentService()),
        Provider<NotificationService>.value(value: appNotificationService),

        // Phase 3 — marketplace services
        Provider<GroundService>(create: (_) => GroundService()),
        Provider<BookingService>(create: (_) => BookingService()),
        Provider<UmpireService>(create: (_) => UmpireService()),
        Provider<ReviewService>(create: (_) => ReviewService()),
        Provider<PayoutService>(create: (_) => PayoutService()),
        Provider<PaymentService>(
          create: (_) => PaymentService()..initialize(),
        ),

        // Auth state for the whole app
        ChangeNotifierProvider(create: (_) => AuthProvider()),
      ],
      child: MaterialApp(
        navigatorKey: appNavigatorKey,
        scaffoldMessengerKey: appScaffoldMessengerKey,
        title: 'CricketHub',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light,
        initialRoute: SplashScreen.route,
        routes: {
          SplashScreen.route: (_) => const SplashScreen(),
          LoginScreen.route: (_) => const LoginScreen(),
          OtpScreen.route: (_) => const OtpScreen(),
          ProfileSetupScreen.route: (_) => const ProfileSetupScreen(),
          MainShell.route: (_) => const MainShell(),

          // Phase 1 / 2
          CreateTeamScreen.route: (_) => const CreateTeamScreen(),
          CreateMatchScreen.route: (_) => const CreateMatchScreen(),
          TossScreen.route: (_) => const TossScreen(),
          ScoringDashboardScreen.route: (_) => const ScoringDashboardScreen(),
          LiveMatchScreen.route: (_) => const LiveMatchScreen(),
          CreateTournamentScreen.route: (_) => const CreateTournamentScreen(),
          TournamentDetailScreen.route: (_) => const TournamentDetailScreen(),

          // Phase 3 — marketplace (argument-bearing routes read
          // ModalRoute arguments inside their own build()).
          GroundListScreen.route: (_) => const GroundListScreen(),

          // These three take a typed argument from Navigator.pushNamed, so
          // they are built from ModalRoute here (the remaining Phase-3
          // screens read their own arguments inside build()).
          GroundDetailScreen.route: (ctx) => GroundDetailScreen(
                groundId: ModalRoute.of(ctx)!.settings.arguments as String,
              ),
          BookingCheckoutScreen.route: (ctx) => BookingCheckoutScreen(
                args: ModalRoute.of(ctx)!.settings.arguments as CheckoutArgs,
              ),
          BookingSuccessScreen.route: (ctx) => BookingSuccessScreen(
                bookingId: ModalRoute.of(ctx)!.settings.arguments as String,
              ),

          GroundCalendarScreen.route: (_) => const GroundCalendarScreen(),
          BookingDetailScreen.route: (_) => const BookingDetailScreen(),
          MyBookingsScreen.route: (_) => const MyBookingsScreen(),
          LeaveReviewScreen.route: (_) => const LeaveReviewScreen(),

          // Phase 3 — ground owner panel
          OwnerDashboard.route: (_) => const OwnerDashboard(),
          OwnerCreateGroundScreen.route: (_) => const OwnerCreateGroundScreen(),
          OwnerCalendarScreen.route: (_) => const OwnerCalendarScreen(),
          OwnerEarningsScreen.route: (_) => const OwnerEarningsScreen(),
          OwnerQrScannerScreen.route: (_) => const OwnerQrScannerScreen(),

          // Phase 3 — umpire marketplace
          UmpireListScreen.route: (_) => const UmpireListScreen(),
          UmpireDetailScreen.route: (_) => const UmpireDetailScreen(),
          UmpireOnboardingScreen.route: (_) => const UmpireOnboardingScreen(),
          UmpireDashboard.route: (_) => const UmpireDashboard(),
          UmpireAvailabilityScreen.route: (_) => const UmpireAvailabilityScreen(),
        },
      ),
    );
  }
}
