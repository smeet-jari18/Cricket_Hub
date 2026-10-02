import 'package:cloud_firestore/cloud_firestore.dart';
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
import 'screens/home/main_shell.dart';
import 'screens/match/create_match_screen.dart';
import 'screens/match/live_match_screen.dart';
import 'screens/match/scoring_dashboard_screen.dart';
import 'screens/match/toss_screen.dart';
import 'screens/splash_screen.dart';
import 'screens/team/create_team_screen.dart';
import 'screens/tournament/create_tournament_screen.dart';
import 'screens/tournament/tournament_detail_screen.dart';
import 'services/match_service.dart';
import 'services/notification_service.dart';
import 'services/team_service.dart';
import 'services/tournament_service.dart';

/// ================================================
/// CricketHub — Phase 1 + Phase 2 foundations
/// Flutter + Dart + Firebase (see README.md for setup)
/// ================================================
final NotificationService appNotificationService = NotificationService();

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Generate lib/firebase_options.dart with `flutterfire configure`.
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

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
          CreateTeamScreen.route: (_) => const CreateTeamScreen(),
          CreateMatchScreen.route: (_) => const CreateMatchScreen(),
          TossScreen.route: (_) => const TossScreen(),
          ScoringDashboardScreen.route: (_) => const ScoringDashboardScreen(),
          LiveMatchScreen.route: (_) => const LiveMatchScreen(),
          CreateTournamentScreen.route: (_) => const CreateTournamentScreen(),
          TournamentDetailScreen.route: (_) => const TournamentDetailScreen(),
        },
      ),
    );
  }
}
