import 'package:cloud_firestore/cloud_firestore.dart';

DateTime? _dateFrom(Object? value) {
  if (value is Timestamp) return value.toDate();
  if (value is DateTime) return value;
  if (value is String) return DateTime.tryParse(value);
  return null;
}

List<Map<String, dynamic>> _mapList(Object? value) {
  if (value is! Iterable) return const [];
  return value
      .whereType<Map>()
      .map((entry) => Map<String, dynamic>.from(entry))
      .toList(growable: false);
}

class Tournament {
  final String id;
  final String name;
  final String location;
  final String format; // round_robin | knockout
  final String status; // draft | upcoming | ongoing | completed
  final String adminUid;
  final DateTime? startAt;
  final DateTime? endAt;
  final int totalOvers;
  final List<String> teamIds;
  final List<Map<String, dynamic>> teams;
  final Map<String, int> pointsConfig;
  final List<Map<String, dynamic>> pointsTable;
  final Map<String, dynamic> leaderboards;
  final String fixtureGenerationStatus; // not_generated | generating | generated | failed
  final int fixtureCount;
  final int roundCount;

  const Tournament({
    required this.id,
    required this.name,
    required this.location,
    required this.format,
    required this.status,
    required this.adminUid,
    this.startAt,
    this.endAt,
    this.totalOvers = 20,
    this.teamIds = const [],
    this.teams = const [],
    this.pointsConfig = const {'win': 2, 'tie': 1, 'loss': 0, 'no_result': 1},
    this.pointsTable = const [],
    this.leaderboards = const {},
    this.fixtureGenerationStatus = 'not_generated',
    this.fixtureCount = 0,
    this.roundCount = 0,
  });

  bool isAdmin(String uid) => uid.isNotEmpty && uid == adminUid;
  bool get isRoundRobin => format == 'round_robin';
  bool get isKnockout => format == 'knockout';
  bool get fixturesGenerated => fixtureGenerationStatus == 'generated';

  factory Tournament.fromFirestore(String id, Map<String, dynamic> map) {
    final rawPoints = map['points_config'];
    final points = rawPoints is Map ? Map<String, dynamic>.from(rawPoints) : const <String, dynamic>{};
    final rawLeaders = map['leaderboards'];
    final rawTeamIds = map['team_ids'];
    return Tournament(
      id: id,
      name: (map['name'] ?? '') as String,
      location: (map['location'] ?? '') as String,
      format: (map['format'] ?? 'round_robin') as String,
      status: (map['status'] ?? 'draft') as String,
      adminUid: (map['admin_uid'] ?? '') as String,
      startAt: _dateFrom(map['start_at']),
      endAt: _dateFrom(map['end_at']),
      totalOvers: (map['total_overs'] as num?)?.toInt() ?? 20,
      teamIds: rawTeamIds is Iterable ? rawTeamIds.whereType<String>().toList() : const [],
      teams: _mapList(map['teams']),
      pointsConfig: points.map((key, value) => MapEntry(key, (value as num?)?.toInt() ?? 0)),
      pointsTable: _mapList(map['points_table']),
      leaderboards: rawLeaders is Map ? Map<String, dynamic>.from(rawLeaders) : const {},
      fixtureGenerationStatus: (map['fixture_generation_status'] ?? 'not_generated') as String,
      fixtureCount: (map['fixture_count'] as num?)?.toInt() ?? 0,
      roundCount: (map['round_count'] as num?)?.toInt() ?? 0,
    );
  }
}

class TournamentFixture {
  final String id;
  final String tournamentId;
  final String matchId;
  final int roundNumber;
  final String roundName;
  final int fixtureNumber;
  final String status; // scheduled | live | completed | bye | empty | awaiting_teams | needs_tiebreak
  final String? teamAId;
  final String? teamAName;
  final String? teamBId;
  final String? teamBName;
  final String? winnerTeamId;
  final String? winnerTeamName;
  final String? resultText;
  final DateTime? scheduledAt;
  final bool isBye;
  final String? nextFixtureId;
  final String? winnerSlot;

  const TournamentFixture({
    required this.id,
    required this.tournamentId,
    required this.matchId,
    required this.roundNumber,
    required this.roundName,
    required this.fixtureNumber,
    required this.status,
    this.teamAId,
    this.teamAName,
    this.teamBId,
    this.teamBName,
    this.winnerTeamId,
    this.winnerTeamName,
    this.resultText,
    this.scheduledAt,
    this.isBye = false,
    this.nextFixtureId,
    this.winnerSlot,
  });

  factory TournamentFixture.fromFirestore(String id, Map<String, dynamic> map) {
    return TournamentFixture(
      id: id,
      tournamentId: (map['tournament_id'] ?? '') as String,
      matchId: (map['match_id'] ?? '') as String,
      roundNumber: (map['round_number'] as num?)?.toInt() ?? 1,
      roundName: (map['round_name'] ?? 'Round 1') as String,
      fixtureNumber: (map['fixture_number'] as num?)?.toInt() ?? 1,
      status: (map['status'] ?? 'awaiting_teams') as String,
      teamAId: map['team_a_id'] as String?,
      teamAName: map['team_a_name'] as String?,
      teamBId: map['team_b_id'] as String?,
      teamBName: map['team_b_name'] as String?,
      winnerTeamId: map['winner_team_id'] as String?,
      winnerTeamName: map['winner_team_name'] as String?,
      resultText: map['result_text'] as String?,
      scheduledAt: _dateFrom(map['scheduled_at']),
      isBye: map['is_bye'] == true,
      nextFixtureId: map['next_fixture_id'] as String?,
      winnerSlot: map['winner_slot'] as String?,
    );
  }
}
