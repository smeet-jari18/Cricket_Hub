import 'package:cloud_firestore/cloud_firestore.dart';

/// BallEvent = one document in `matches/{matchId}/balls`.
/// Sequence numbers remain globally increasing across both innings so a single
/// indexed Firestore query can render recent commentary in the right order.
class BallEvent {
  final int sequence;
  final int inningsNumber;
  final int overNumber; // 0-based over (0 = first over)
  final int ballInOver; // legal-ball count in the over, extras excluded
  final int runs;
  final int batRuns;
  final int extraRuns;
  final int scoreAfter;
  final int wicketsAfter;
  final String extraType; // "" | "wide" | "no_ball" | "bye" | "leg_bye"
  final String wicketType;
  final String playerOut;
  final String bowlerName;
  final String strikerName;
  final String strikerUid;
  final String bowlerUid;
  final DateTime? timestamp;

  const BallEvent({
    required this.sequence,
    this.inningsNumber = 1,
    required this.overNumber,
    required this.ballInOver,
    required this.runs,
    this.batRuns = 0,
    this.extraRuns = 0,
    this.scoreAfter = 0,
    this.wicketsAfter = 0,
    this.extraType = '',
    this.wicketType = '',
    this.playerOut = '',
    required this.bowlerName,
    required this.strikerName,
    this.strikerUid = '',
    this.bowlerUid = '',
    this.timestamp,
  });

  bool get isWicket => wicketType.isNotEmpty;
  bool get isExtra => extraType.isNotEmpty;
  bool get isLegalBall => extraType != 'wide' && extraType != 'no_ball';

  String get overDisplay => '$overNumber.${isLegalBall ? ballInOver : ballInOver + 1}';

  Map<String, dynamic> toMap() {
    return {
      'sequence': sequence,
      'innings_number': inningsNumber,
      'over_number': overNumber,
      'ball_in_over': ballInOver,
      'runs': runs,
      'bat_runs': batRuns,
      'extra_runs': extraRuns,
      'score_after': scoreAfter,
      'wickets_after': wicketsAfter,
      'extras': extraType.isEmpty
          ? null
          : {
              'type': extraType,
              'runs': extraRuns,
              'team_runs': runs,
              'bat_runs': batRuns,
            },
      'wicket': isWicket
          ? {
              'type': wicketType,
              'player_out': playerOut,
              'player_uid': strikerUid,
              'score_after': scoreAfter,
              'wickets_after': wicketsAfter,
            }
          : null,
      'bowler_name': bowlerName,
      'bowler_uid': bowlerUid,
      'striker_name': strikerName,
      'striker_uid': strikerUid,
      'timestamp': FieldValue.serverTimestamp(),
    };
  }
}
