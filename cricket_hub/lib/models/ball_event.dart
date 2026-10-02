import 'package:cloud_firestore/cloud_firestore.dart';

/// BallEvent = one document in `matches/{matchId}/balls` subcollection.
/// Matches CricketHub_Backend_Schema.md -> Sub-Collection: balls
///
/// IMPORTANT (from schema): document ID uses a RUNNING SEQUENCE
/// (ball_001, ball_002 ...) because a wide/no-ball makes an over
/// longer than 6 balls — "over1ball_1" style IDs would collide.
class BallEvent {
  final int sequence; // 1, 2, 3 ... across the whole innings
  final int overNumber; // 0-based over (0 = first over)
  final int ballInOver; // legal balls in this over (1..6) - extras excluded
  final int runs; // runs off the bat OR extra runs
  final String extraType; // "" | "wide" | "no_ball" | "bye" | "leg_bye"
  final String wicketType; // "" | "bowled" | "caught" | "run_out" | ...
  final String playerOut;
  final String bowlerName;
  final String strikerName;
  final DateTime? timestamp;

  BallEvent({
    required this.sequence,
    required this.overNumber,
    required this.ballInOver,
    required this.runs,
    this.extraType = '',
    this.wicketType = '',
    this.playerOut = '',
    required this.bowlerName,
    required this.strikerName,
    this.timestamp,
  });

  bool get isWicket => wicketType.isNotEmpty;
  bool get isExtra => extraType.isNotEmpty;
  bool get isLegalBall => extraType != 'wide' && extraType != 'no_ball';

  /// e.g. "15.3" style display of the over this ball belongs to.
  String get overDisplay => '$overNumber.${isLegalBall ? ballInOver : ballInOver + 1}';

  Map<String, dynamic> toMap() {
    return {
      'sequence': sequence,
      'over_number': overNumber,
      'ball_in_over': ballInOver,
      'runs': runs,
      'extras': extraType.isEmpty
          ? null
          : {'type': extraType, 'runs': runs},
      'wicket': isWicket
          ? {'type': wicketType, 'player_out': playerOut}
          : null,
      'bowler_name': bowlerName,
      'striker_name': strikerName,
      'timestamp': FieldValue.serverTimestamp(),
    };
  }
}
