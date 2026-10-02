import 'package:cloud_firestore/cloud_firestore.dart';

import '../core/app_constants.dart';
import '../models/team_model.dart';

/// All team-related Firestore calls live here.
class TeamService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  /// Live list of ALL teams (Home + My Cricket screens).
  Stream<List<Team>> teamsStream() {
    return _db
        .collection(AppConstants.teamsCol)
        .orderBy('created_at', descending: true)
        .snapshots()
        .map((snap) => snap.docs
            .map((doc) => Team.fromFirestore(doc.id, doc.data()))
            .toList());
  }

  /// Teams created by the logged-in user.
  Stream<List<Team>> myTeamsStream(String uid) {
    return _db
        .collection(AppConstants.teamsCol)
        .where('admin_uid', isEqualTo: uid)
        .snapshots()
        .map((snap) => snap.docs
            .map((doc) => Team.fromFirestore(doc.id, doc.data()))
            .toList());
  }

  /// Create a new team. Returns the new team id.
  Future<String> createTeam({
    required String name,
    required String city,
    required String adminUid,
  }) async {
    final team = Team(
      id: '', // Firestore generates the real id
      teamName: name.trim(),
      city: city.trim(),
      adminUid: adminUid,
    );
    final doc = await _db
        .collection(AppConstants.teamsCol)
        .add(team.toMap());
    return doc.id;
  }

  /// Add a player name to the roster (Phase 1 simple version).
  Future<void> addPlayerToRoster(String teamId, String playerName) async {
    await _db.collection(AppConstants.teamsCol).doc(teamId).update({
      'roster': FieldValue.arrayUnion([playerName.trim()]),
    });
  }

  Future<void> removePlayerFromRoster(String teamId, String playerName) async {
    await _db.collection(AppConstants.teamsCol).doc(teamId).update({
      'roster': FieldValue.arrayRemove([playerName.trim()]),
    });
  }

  Future<Team?> getTeam(String teamId) async {
    final doc = await _db.collection(AppConstants.teamsCol).doc(teamId).get();
    if (!doc.exists) return null;
    return Team.fromFirestore(doc.id, doc.data()!);
  }
}
