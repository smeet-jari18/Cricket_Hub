import 'package:cloud_firestore/cloud_firestore.dart';

DateTime? _matchDateFrom(Object? value) {
  if (value is Timestamp) return value.toDate();
  if (value is DateTime) return value;
  if (value is String) return DateTime.tryParse(value);
  return null;
}

List<Map<String, dynamic>> _inningsFrom(Object? value) {
  if (value is! Iterable) return const [];
  return value
      .whereType<Map>()
      .map((entry) => Map<String, dynamic>.from(entry))
      .toList(growable: false);
}

/// CricketMatch = one document in the `matches` collection.
/// Includes Phase 2 tournament links and two-innings scorecards while keeping
/// older Phase 1 documents readable.
class CricketMatch {
  final String id;
  final String status; // scheduled | live | completed | abandoned
  final String teamAId;
  final String teamBId;
  final String teamAName;
  final String teamBName;
  final int totalOvers;
  final String scorerUid;
  final String scorerName;
  final String? tournamentAdminUid;
  final String? tournamentId;
  final String? fixtureId;
  final String stage;
  final int roundNumber;
  final int fixtureNumber;
  final DateTime? scheduledAt;
  final String tossWinner;
  final String electedTo;
  final String battingTeamId;
  final String bowlingTeamId;
  final String currentBattingTeamId;
  final int currentInningsNumber;
  final int venueRuns;
  final int venueWickets;
  final int ballsBowled; // Legal balls in the current innings.
  final String strikerName;
  final String nonStrikerName;
  final String currentBowlerName;
  final List<Map<String, dynamic>> innings;
  final String? winnerTeamId;
  final String resultType;
  final String resultText;

  const CricketMatch({
    required this.id,
    required this.status,
    required this.teamAId,
    required this.teamBId,
    required this.teamAName,
    required this.teamBName,
    required this.totalOvers,
    required this.scorerUid,
    this.scorerName = '',
    this.tournamentAdminUid,
    this.tournamentId,
    this.fixtureId,
    this.stage = '',
    this.roundNumber = 0,
    this.fixtureNumber = 0,
    this.scheduledAt,
    this.tossWinner = '',
    this.electedTo = '',
    required this.battingTeamId,
    required this.bowlingTeamId,
    this.currentBattingTeamId = '',
    this.currentInningsNumber = 1,
    this.venueRuns = 0,
    this.venueWickets = 0,
    this.ballsBowled = 0,
    this.strikerName = '',
    this.nonStrikerName = '',
    this.currentBowlerName = '',
    this.innings = const [],
    this.winnerTeamId,
    this.resultType = '',
    this.resultText = '',
  });

  bool get isLive => status == 'live';
  bool get isCompleted => status == 'completed';
  bool get isScheduled => status == 'scheduled';

  String get currentBattingTeamName {
    final teamId = currentBattingTeamId.isNotEmpty
        ? currentBattingTeamId
        : battingTeamId;
    if (teamId == teamAId) return teamAName;
    if (teamId == teamBId) return teamBName;
    return status == 'scheduled' ? 'Match not started' : 'Team';
  }

  String get currentBowlingTeamName {
    final battingId = currentBattingTeamId.isNotEmpty
        ? currentBattingTeamId
        : battingTeamId;
    if (battingId == teamAId) return teamBName;
    if (battingId == teamBId) return teamAName;
    if (bowlingTeamId == teamAId) return teamAName;
    if (bowlingTeamId == teamBId) return teamBName;
    return 'TBD';
  }

  factory CricketMatch.fromFirestore(String id, Map<String, dynamic> map) {
    final currentSummary = map['current_summary'] is Map
        ? Map<String, dynamic>.from(map['current_summary'] as Map)
        : const <String, dynamic>{};
    return CricketMatch(
      id: id,
      status: (map['status'] ?? 'scheduled') as String,
      teamAId: (map['team_a_id'] ?? '') as String,
      teamBId: (map['team_b_id'] ?? '') as String,
      teamAName: (map['team_a_name'] ?? '') as String,
      teamBName: (map['team_b_name'] ?? '') as String,
      totalOvers: (map['total_overs'] as num?)?.toInt() ?? 20,
      scorerUid: (map['scorer_uid'] ?? '') as String,
      scorerName: (map['scorer_name'] ?? '') as String,
      tournamentAdminUid: map['tournament_admin_uid'] as String?,
      tournamentId: map['tournament_id'] as String?,
      fixtureId: map['fixture_id'] as String?,
      stage: (map['stage'] ?? '') as String,
      roundNumber: (map['round_number'] as num?)?.toInt() ?? 0,
      fixtureNumber: (map['fixture_number'] as num?)?.toInt() ?? 0,
      scheduledAt: _matchDateFrom(map['scheduled_at']),
      tossWinner: (map['toss_winner'] ?? '') as String,
      electedTo: (map['elected_to'] ?? '') as String,
      battingTeamId: (map['batting_team_id'] ?? '') as String,
      bowlingTeamId: (map['bowling_team_id'] ?? '') as String,
      currentBattingTeamId: (map['current_batting_team_id'] ??
          currentSummary['batting_team_id'] ?? map['batting_team_id'] ?? '') as String,
      currentInningsNumber: (map['current_innings_number'] as num?)?.toInt() ?? 1,
      venueRuns: (map['current_runs'] as num?)?.toInt() ??
          (currentSummary['runs'] as num?)?.toInt() ?? 0,
      venueWickets: (map['current_wickets'] as num?)?.toInt() ??
          (currentSummary['wickets'] as num?)?.toInt() ?? 0,
      ballsBowled: (map['legal_balls'] as num?)?.toInt() ??
          (currentSummary['legal_balls'] as num?)?.toInt() ?? 0,
      strikerName: (map['striker_name'] ?? '') as String,
      nonStrikerName: (map['non_striker_name'] ?? '') as String,
      currentBowlerName: (map['current_bowler_name'] ?? '') as String,
      innings: _inningsFrom(map['innings']),
      winnerTeamId: map['winner_team_id'] as String?,
      resultType: (map['result_type'] ?? '') as String,
      resultText: (map['result_text'] ?? '') as String,
    );
  }

  /// Use when creating a pre-match document (standard match, not a fixture).
  Map<String, dynamic> toMapPreMatch() {
    return {
      'status': status,
      'team_a_id': teamAId,
      'team_b_id': teamBId,
      'team_a_name': teamAName,
      'team_b_name': teamBName,
      'total_overs': totalOvers,
      'scorer_uid': scorerUid,
      'scorer_name': scorerName,
      'tournament_admin_uid': tournamentAdminUid,
      'tournament_id': tournamentId,
      'fixture_id': fixtureId,
      'stage': stage,
      'round_number': roundNumber,
      'fixture_number': fixtureNumber,
      'scheduled_at': scheduledAt == null ? null : Timestamp.fromDate(scheduledAt!),
      'innings': <Map<String, dynamic>>[],
      'current_innings_number': 1,
      'current_runs': 0,
      'current_wickets': 0,
      'legal_balls': 0,
      'created_at': FieldValue.serverTimestamp(),
    };
  }

  /// Use when the toss is confirmed and the first innings goes live.
  Map<String, dynamic> tossToMap() {
    return {
      'toss_winner': tossWinner,
      'elected_to': electedTo,
      'batting_team_id': battingTeamId,
      'bowling_team_id': bowlingTeamId,
      'current_batting_team_id': battingTeamId,
      'current_innings_number': 1,
      'status': 'live',
      'innings': <Map<String, dynamic>>[],
      'current_runs': 0,
      'current_wickets': 0,
      'legal_balls': 0,
      'updated_at': FieldValue.serverTimestamp(),
    };
  }
}
