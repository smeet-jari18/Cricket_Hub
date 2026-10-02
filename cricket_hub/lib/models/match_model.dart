import 'package:cloud_firestore/cloud_firestore.dart';

/// CricketMatch = one document in the `matches` collection.
/// Matches CricketHub_Backend_Schema.md -> Collection: matches
class CricketMatch {
  final String id;
  final String status; // scheduled | live | completed | abandoned
  final String teamAId;
  final String teamBId;
  final String teamAName; // denormalized for fast rendering
  final String teamBName;
  final int totalOvers;
  final String scorerUid; // ONLY this user can write score (security rules)
  final String? tournamentAdminUid; // set if match belongs to a tournament
  final String tossWinner; // team id
  final String electedTo; // "bat" or "bowl"
  final String battingTeamId; // computed from toss
  final String bowlingTeamId;
  final int venueRuns;
  final int venueWickets;
  final int ballsBowled; // LEGAL balls only
  final String strikerName;
  final String nonStrikerName;
  final String currentBowlerName;

  CricketMatch({
    required this.id,
    required this.status,
    required this.teamAId,
    required this.teamBId,
    required this.teamAName,
    required this.teamBName,
    required this.totalOvers,
    required this.scorerUid,
    this.tournamentAdminUid,
    this.tossWinner = '',
    this.electedTo = '',
    required this.battingTeamId,
    required this.bowlingTeamId,
    this.venueRuns = 0,
    this.venueWickets = 0,
    this.ballsBowled = 0,
    this.strikerName = '',
    this.nonStrikerName = '',
    this.currentBowlerName = '',
  });

  bool get isLive => status == 'live';
  bool get isCompleted => status == 'completed';

  factory CricketMatch.fromFirestore(String id, Map<String, dynamic> map) {
    return CricketMatch(
      id: id,
      status: (map['status'] ?? 'scheduled') as String,
      teamAId: (map['team_a_id'] ?? '') as String,
      teamBId: (map['team_b_id'] ?? '') as String,
      teamAName: (map['team_a_name'] ?? '') as String,
      teamBName: (map['team_b_name'] ?? '') as String,
      totalOvers: (map['total_overs'] ?? 20) as int,
      scorerUid: (map['scorer_uid'] ?? '') as String,
      tournamentAdminUid: map['tournament_admin_uid'] as String?,
      tossWinner: (map['toss_winner'] ?? '') as String,
      electedTo: (map['elected_to'] ?? '') as String,
      battingTeamId: (map['batting_team_id'] ?? '') as String,
      bowlingTeamId: (map['bowling_team_id'] ?? '') as String,
      venueRuns: (map['current_runs'] ?? 0) as int,
      venueWickets: (map['current_wickets'] ?? 0) as int,
      ballsBowled: (map['legal_balls'] ?? 0) as int,
      strikerName: (map['striker_name'] ?? '') as String,
      nonStrikerName: (map['non_striker_name'] ?? '') as String,
      currentBowlerName: (map['current_bowler_name'] ?? '') as String,
    );
  }

  /// Use when creating a match (before toss is done).
  Map<String, dynamic> toMapPreMatch() {
    return {
      'status': status,
      'team_a_id': teamAId,
      'team_b_id': teamBId,
      'team_a_name': teamAName,
      'team_b_name': teamBName,
      'total_overs': totalOvers,
      'scorer_uid': scorerUid,
      'tournament_admin_uid': tournamentAdminUid,
      'created_at': FieldValue.serverTimestamp(),
    };
  }

  /// Use when the toss is confirmed and match goes live.
  Map<String, dynamic> tossToMap() {
    return {
      'toss_winner': tossWinner,
      'elected_to': electedTo,
      'batting_team_id': battingTeamId,
      'bowling_team_id': bowlingTeamId,
      'status': 'live',
      'current_runs': 0,
      'current_wickets': 0,
      'legal_balls': 0,
    };
  }
}
