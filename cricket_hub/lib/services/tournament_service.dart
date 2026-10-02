import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';

import '../models/team_model.dart';
import '../models/tournament_model.dart';

class TournamentService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseFunctions _functions =
      FirebaseFunctions.instanceFor(region: 'asia-south1');

  Stream<List<Tournament>> tournamentsStream() {
    return _db
        .collection('tournaments')
        .orderBy('created_at', descending: true)
        .limit(50)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => Tournament.fromFirestore(doc.id, doc.data()))
            .toList());
  }

  Stream<Tournament?> tournamentStream(String tournamentId) {
    return _db
        .collection('tournaments')
        .doc(tournamentId)
        .snapshots()
        .map((snapshot) => snapshot.exists
            ? Tournament.fromFirestore(snapshot.id, snapshot.data()!)
            : null);
  }

  Stream<List<TournamentFixture>> fixturesStream(String tournamentId) {
    return _db
        .collection('tournaments')
        .doc(tournamentId)
        .collection('fixtures')
        .orderBy('round_number')
        .orderBy('fixture_number')
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => TournamentFixture.fromFirestore(doc.id, doc.data()))
            .toList());
  }

  Future<String> createTournament({
    required String name,
    required String location,
    required DateTime startAt,
    DateTime? endAt,
    required String format,
    required int totalOvers,
    required String adminUid,
    required Map<String, int> pointsConfig,
  }) async {
    final ref = _db.collection('tournaments').doc();
    await ref.set({
      'name': name.trim(),
      'location': location.trim(),
      'format': format,
      'status': 'draft',
      'admin_uid': adminUid,
      'start_at': Timestamp.fromDate(startAt),
      'end_at': endAt == null ? null : Timestamp.fromDate(endAt),
      'total_overs': totalOvers,
      'team_ids': <String>[],
      'teams': <Map<String, dynamic>>[],
      'points_config': pointsConfig,
      'points_table': <Map<String, dynamic>>[],
      'leaderboards': {
        'orange_cap': <Map<String, dynamic>>[],
        'purple_cap': <Map<String, dynamic>>[],
      },
      'fixture_generation_status': 'not_generated',
      'fixture_count': 0,
      'round_count': 0,
      'created_at': FieldValue.serverTimestamp(),
      'updated_at': FieldValue.serverTimestamp(),
    });
    return ref.id;
  }

  Future<void> updateTournamentTeams(
      String tournamentId, List<Team> selectedTeams) async {
    final unique = <String, Team>{};
    for (final team in selectedTeams) {
      unique[team.id] = team;
    }
    await _db.collection('tournaments').doc(tournamentId).update({
      'team_ids': unique.keys.toList(),
      'teams': unique.values
          .map((team) => {
                'id': team.id,
                'name': team.teamName,
                'city': team.city,
              })
          .toList(),
      'updated_at': FieldValue.serverTimestamp(),
    });
  }

  Future<Map<String, dynamic>> generateFixtures(String tournamentId) async {
    final callable = _functions.httpsCallable('generateTournamentFixtures');
    final response = await callable.call({
      'tournamentId': tournamentId,
    });
    final data = response.data;
    return data is Map ? Map<String, dynamic>.from(data) : const <String, dynamic>{};
  }

  Future<void> resolveKnockoutTie({
    required String tournamentId,
    required String fixtureId,
    required String winnerTeamId,
  }) async {
    final callable = _functions.httpsCallable('resolveKnockoutTie');
    await callable.call({
      'tournamentId': tournamentId,
      'fixtureId': fixtureId,
      'winnerTeamId': winnerTeamId,
    });
  }
}
