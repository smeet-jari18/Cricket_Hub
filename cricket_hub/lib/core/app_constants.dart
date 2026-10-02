/// App-wide constants. Keep magic numbers here, not inside screens.
///
/// Phase 3 additions:
///   * new collections for marketplace (grounds, slots, bookings, umpires, reviews)
///   * platform fee + hold duration
///   * refund policy thresholds (hours)
class AppConstants {
  AppConstants._(); // no instances

  // Firestore collection names (single source of truth)
  static const String usersCol = 'users';
  static const String teamsCol = 'teams';
  static const String matchesCol = 'matches';
  static const String ballsSubCol = 'balls';
  static const String tournamentsCol = 'tournaments';

  // Phase 3 collections
  static const String groundsCol = 'grounds';
  static const String slotsSubCol = 'slots';
  static const String blockedRulesSubCol = 'blocked_rules';
  static const String bookingsCol = 'bookings';
  static const String bookingAuditSubCol = 'audit';
  static const String groundReviewsCol = 'ground_reviews';
  static const String umpiresCol = 'umpires';
  static const String umpireAvailabilitySubCol = 'availability';
  static const String umpireReviewsCol = 'umpire_reviews';
  static const String payoutLedgerCol = 'payout_ledger';
  static const String payoutWeeksSubCol = 'weeks';
  static const String razorpayEventsCol = 'razorpay_events';
  static const String favoriteGroundsSubCol = 'favorite_grounds';
  static const String userBookingsSubCol = 'bookings';

  // Match defaults
  static const int defaultOvers = 20;
  static const int defaultWickets = 10;

  // Offline cache: Firestore persists data locally by default on mobile,
  // so the scorer can keep working with weak/no network.
  static const int maxUndoStack = 500;

  // Phase 3 marketplace constants
  static const double platformFeePct = 0.05; // 5%
  static const int holdDurationMinutes = 10;
  static const int refundFullHours = 24;
  static const int refundHalfHours = 12;
  static const List<String> pitchTypes = ['turf', 'matting', 'concrete'];
  static const List<String> standardAmenities = [
    'floodlights',
    'pavilion',
    'parking',
    'change_room',
    'cafeteria',
    'drinking_water',
  ];
  static const List<int> supportedOvers = [5, 10, 15, 20, 25, 30];
  static const List<String> supportedCities = [
    'Ahmedabad',
    'Mumbai',
    'Bengaluru',
    'Hyderabad',
    'Pune',
  ];

  // Slot duration presets (minutes) for ground owner wizard.
  static const List<int> slotDurationPresets = [60, 90, 120, 180, 300];
}