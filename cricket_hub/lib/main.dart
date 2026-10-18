import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart' show FirebaseAuth;
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'core/app_navigator.dart';
import 'core/firebase_bootstrap.dart';
import 'l10n/generated/app_localizations.dart';
import 'providers/locale_provider.dart';
import 'services/cric_api_service.dart';
import 'screens/international/international_screen.dart';
import 'screens/settings/language_screen.dart';
import 'core/app_theme.dart';
import 'firebase_options.dart';
import 'providers/auth_provider.dart';
import 'screens/admin/admin_verification_screen.dart';
import 'screens/bootstrap_error_screen.dart';
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
import 'screens/owner/owner_edit_ground_screen.dart';
import 'screens/owner/owner_earnings_screen.dart';
import 'screens/owner/owner_qr_scanner_screen.dart';
import 'screens/splash_screen.dart';
import 'screens/team/create_team_screen.dart';
import 'screens/tournament/create_tournament_screen.dart';
import 'screens/tournament/tournament_detail_screen.dart';
import 'models/ground_model.dart';
import 'screens/umpire/umpire_availability_screen.dart';
import 'screens/umpire/umpire_booking_requests_screen.dart';
import 'screens/umpire/umpire_booking_screen.dart';
import 'screens/umpire/umpire_dashboard.dart';
import 'screens/umpire/umpire_edit_screen.dart';
import 'screens/umpire/umpire_detail_screen.dart';
import 'screens/umpire/umpire_list_screen.dart';
import 'screens/umpire/umpire_onboarding_screen.dart';
import 'services/admin_service.dart';
import 'services/booking_service.dart';
import 'services/ground_service.dart';
import 'services/match_service.dart';
import 'services/notification_service.dart';
import 'services/payment_service.dart';
import 'services/payout_service.dart';
import 'services/storage_service.dart';
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
  await FirebaseStorage.instance.useStorageEmulator(_emulatorHost, 9199);
  debugPrint('🔥 Emulators → $_emulatorHost '
      '(auth:9099 · firestore:8080 · functions:5001)');
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Firebase init must never kill the app.
  //
  // Android's google-services plugin creates the [DEFAULT] app natively at
  // process start from google-services.json. Calling `Firebase.initializeApp`
  // with *different* options (e.g. the placeholder firebase_options.dart that
  // ships in the zip) throws `[core/duplicate-app]`, and because that used to
  // be un-guarded, `runApp` never ran and the phone showed a black screen.
  // See lib/core/firebase_bootstrap.dart for the full story.
  final bootstrap = await bootstrapFirebase(
    existingProjectId: () {
      final apps = Firebase.apps;
      return apps.isEmpty ? null : apps.first.options.projectId;
    },
    initialize: () async {
      final app = await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
      return app.options.projectId;
    },
    // Last resort: no options => attach to the native [DEFAULT] app.
    adoptExisting: () async {
      final app = await Firebase.initializeApp();
      return app.options.projectId;
    },
    log: debugPrint,
  );

  if (!bootstrap.ready) {
    debugPrint('Firebase bootstrap failed: ${bootstrap.error}');
    runApp(BootstrapErrorScreen(error: bootstrap.error));
    return;
  }

  // Loud, non-fatal warning: a placeholder key (the one that ships in this
  // repo's firebase_options.dart) means auth/database calls will fail in ways
  // that look like "no data" rather than an error. Say it once, clearly.
  try {
    final apiKey = Firebase.app().options.apiKey;
    if (apiKey.isEmpty || apiKey.toUpperCase().contains('PLACEHOLDER')) {
      debugPrint(
        '⚠️ Firebase apiKey looks like a placeholder — run '
        '`flutterfire configure --project=crickethub-dev` '
        'before testing auth/data on a real device.',
      );
    }
  } catch (_) {
    // Never let diagnostics break startup.
  }

  if (_useEmulator) {
    await _connectEmulators();
  }

  // Everything after init can fail too (bad config, missing permission, a
  // plugin that refuses the emulator host). Any failure here must still land on
  // a readable screen instead of a black one.
  try {
    // Local cache on the phone -> scoring writes queue offline and sync later.
    FirebaseFirestore.instance.settings = const Settings(
      persistenceEnabled: true,
      cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED,
    );
    await appNotificationService.initialize();
  } catch (e, stack) {
    debugPrint('Startup failed after Firebase init: $e\n$stack');
    runApp(BootstrapErrorScreen(error: e));
    return;
  }

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
        Provider<AdminService>(create: (_) => AdminService()),
        Provider<StorageService>(create: (_) => StorageService()),
        Provider<UmpireService>(create: (_) => UmpireService()),
        Provider<ReviewService>(create: (_) => ReviewService()),
        Provider<PayoutService>(create: (_) => PayoutService()),
        Provider<PaymentService>(
          create: (_) => PaymentService()..initialize(),
        ),

        // Phase 4 — International scores (CricAPI). The key is baked in with
        // --dart-define=CRICAPI_KEY=... ; without it the screen offers demo
        // data instead of failing.
        Provider<CricApiService>(create: (_) => CricApiService()),

        // Auth state for the whole app
        ChangeNotifierProvider(create: (_) => AuthProvider()),

        // Phase 4 — language. Loads the saved choice asynchronously; while it
        // loads the app draws in the device language, which is also the
        // correct default for a first run.
        ChangeNotifierProvider(create: (_) => LocaleProvider()..load()),
      ],
      child: Consumer<LocaleProvider>(
        builder: (context, localeProvider, _) => MaterialApp(
        navigatorKey: appNavigatorKey,
        scaffoldMessengerKey: appScaffoldMessengerKey,
        title: 'CricketHub',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light,

        // Phase 4 — localization. `locale == null` means "follow the device",
        // which is why the provider stores null instead of the resolved value.
        locale: localeProvider.locale,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        localeResolutionCallback: (device, supported) =>
            LocaleProvider.resolve(device ?? const Locale('en')),
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
          // Takes a typed argument from Navigator.pushNamed (see _GroundRow).
          OwnerEditGroundScreen.route: (ctx) => OwnerEditGroundScreen(
                ground: ModalRoute.of(ctx)!.settings.arguments as Ground,
              ),

          // Platform admin
          AdminVerificationScreen.route: (_) =>
              const AdminVerificationScreen(),

          // Phase 3 — umpire marketplace
          UmpireListScreen.route: (_) => const UmpireListScreen(),
          UmpireDetailScreen.route: (_) => const UmpireDetailScreen(),
          UmpireOnboardingScreen.route: (_) => const UmpireOnboardingScreen(),
          UmpireDashboard.route: (_) => const UmpireDashboard(),
          UmpireAvailabilityScreen.route: (_) => const UmpireAvailabilityScreen(),
          // These two read their own `ModalRoute` argument inside build().
          UmpireBookingScreen.route: (_) => const UmpireBookingScreen(),
          UmpireEditScreen.route: (_) => const UmpireEditScreen(),
          UmpireBookingRequestsScreen.route: (_) =>
              const UmpireBookingRequestsScreen(),

          // Phase 4
          InternationalScreen.route: (_) => const InternationalScreen(),
          LanguageScreen.route: (_) => const LanguageScreen(),
        },
        ),
      ),
    );
  }
}
