/// App-wide constants. Keep magic numbers here, not inside screens.
class AppConstants {
  AppConstants._(); // no instances

  // Firestore collection names (single source of truth)
  static const String usersCol = 'users';
  static const String teamsCol = 'teams';
  static const String matchesCol = 'matches';
  static const String ballsSubCol = 'balls';
  static const String tournamentsCol = 'tournaments';
  static const String groundsCol = 'grounds';
  static const String bookingsCol = 'bookings';

  // Match defaults
  static const int defaultOvers = 20;
  static const int defaultWickets = 10; // all out

  // Offline cache: Firestore persists data locally by default on mobile,
  // so the scorer can keep working with weak/no network.
  static const int maxUndoStack = 500;
}
