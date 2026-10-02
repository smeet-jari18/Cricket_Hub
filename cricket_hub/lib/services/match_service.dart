import 'package:cloud_firestore/cloud_firestore.dart';

import '../core/app_constants.dart';
import '../models/ball_event.dart';
import '../models/match_model.dart';

/// Match and ball-by-ball persistence. Firestore's local persistence keeps
/// scorer writes queued during a network interruption.
class MatchService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Stream<List<CricketMatch>> matchesStream() {
    return _db
        .collection(AppConstants.matchesCol)
        .orderBy('created_at', descending: true)
        .limit(100)
        .snapshots()
        .map((snap) => snap.docs
            .map((doc) => CricketMatch.fromFirestore(doc.id, doc.data()))
            .toList());
  }

  Stream<CricketMatch?> matchStream(String matchId) {
    return _db.collection(AppConstants.matchesCol).doc(matchId).snapshots().map(
          (snap) => snap.exists
              ? CricketMatch.fromFirestore(snap.id, snap.data()!)
              : null,
        );
  }

  Future<CricketMatch?> getMatch(String matchId) async {
    final snap = await _db.collection(AppConstants.matchesCol).doc(matchId).get();
    if (!snap.exists) return null;
    return CricketMatch.fromFirestore(snap.id, snap.data()!);
  }

  Stream<List<BallEvent>> ballsStream(String matchId) =>
      _ballsQuery(matchId, limit: 120);

  /// Unbounded innings feed for complete scorecards and fall-of-wickets.
  Stream<List<BallEvent>> allBallsStream(String matchId) =>
      _ballsQuery(matchId);

  Stream<List<BallEvent>> _ballsQuery(String matchId, {int? limit}) {
    final ordered = _db
        .collection(AppConstants.matchesCol)
        .doc(matchId)
        .collection(AppConstants.ballsSubCol)
        .orderBy('sequence', descending: true);
    final query = limit == null ? ordered : ordered.limit(limit);
    return query.snapshots().map((snap) => snap.docs.map((doc) {
              final data = doc.data();
              final extras = data['extras'] is Map
                  ? Map<String, dynamic>.from(data['extras'] as Map)
                  : const <String, dynamic>{};
              final wicket = data['wicket'] is Map
                  ? Map<String, dynamic>.from(data['wicket'] as Map)
                  : const <String, dynamic>{};
              final timestamp = data['timestamp'];
              return BallEvent(
                sequence: (data['sequence'] as num?)?.toInt() ?? 0,
                inningsNumber: (data['innings_number'] as num?)?.toInt() ?? 1,
                overNumber: (data['over_number'] as num?)?.toInt() ?? 0,
                ballInOver: (data['ball_in_over'] as num?)?.toInt() ?? 0,
                runs: (data['runs'] as num?)?.toInt() ?? 0,
                batRuns: (data['bat_runs'] as num?)?.toInt() ??
                    (extras['bat_runs'] as num?)?.toInt() ?? 0,
                extraRuns: (data['extra_runs'] as num?)?.toInt() ??
                    (extras['runs'] as num?)?.toInt() ?? 0,
                scoreAfter: (data['score_after'] as num?)?.toInt() ??
                    (wicket['score_after'] as num?)?.toInt() ?? 0,
                wicketsAfter: (data['wickets_after'] as num?)?.toInt() ??
                    (wicket['wickets_after'] as num?)?.toInt() ?? 0,
                extraType: (extras['type'] ?? '') as String,
                wicketType: (wicket['type'] ?? '') as String,
                playerOut: (wicket['player_out'] ?? '') as String,
                bowlerName: (data['bowler_name'] ?? '') as String,
                strikerName: (data['striker_name'] ?? '') as String,
                strikerUid: (data['striker_uid'] ?? '') as String,
                bowlerUid: (data['bowler_uid'] ?? '') as String,
                timestamp: timestamp is Timestamp ? timestamp.toDate() : null,
              );
            }).toList());
  }

  Future<String> createMatch(CricketMatch match) async {
    final doc = await _db
        .collection(AppConstants.matchesCol)
        .add(match.toMapPreMatch());
    return doc.id;
  }

  Future<void> startMatchWithToss(CricketMatch match) async {
    await _db
        .collection(AppConstants.matchesCol)
        .doc(match.id)
        .update(match.tossToMap());
  }

  Future<void> pushBall({
    required String matchId,
    required BallEvent ball,
    required int totalRuns,
    required int totalWickets,
    required int legalBalls,
    required String battingTeamId,
    required String strikerName,
    required String nonStrikerName,
    required String bowlerName,
  }) async {
    final batch = _db.batch();
    final matchRef = _db.collection(AppConstants.matchesCol).doc(matchId);
    final ballRef = matchRef
        .collection(AppConstants.ballsSubCol)
        .doc('ball_${ball.sequence.toString().padLeft(5, '0')}');

    batch.set(ballRef, ball.toMap());
    batch.update(matchRef, {
      'current_runs': totalRuns,
      'current_wickets': totalWickets,
      'legal_balls': legalBalls,
      'current_batting_team_id': battingTeamId,
      'current_innings_number': ball.inningsNumber,
      'striker_name': strikerName,
      'non_striker_name': nonStrikerName,
      'current_bowler_name': bowlerName,
      'updated_at': FieldValue.serverTimestamp(),
    });
    await batch.commit();
  }

  Future<void> undoLastBall({
    required String matchId,
    required int sequence,
    required int totalRuns,
    required int totalWickets,
    required int legalBalls,
    required String battingTeamId,
    required String strikerName,
    required String nonStrikerName,
    required String bowlerName,
    required int inningsNumber,
  }) async {
    final batch = _db.batch();
    final matchRef = _db.collection(AppConstants.matchesCol).doc(matchId);
    final ballRef = matchRef
        .collection(AppConstants.ballsSubCol)
        .doc('ball_${sequence.toString().padLeft(5, '0')}');
    batch.delete(ballRef);
    batch.update(matchRef, {
      'current_runs': totalRuns,
      'current_wickets': totalWickets,
      'legal_balls': legalBalls,
      'current_batting_team_id': battingTeamId,
      'current_innings_number': inningsNumber,
      'striker_name': strikerName,
      'non_striker_name': nonStrikerName,
      'current_bowler_name': bowlerName,
      'updated_at': FieldValue.serverTimestamp(),
    });
    await batch.commit();
  }

  Future<void> saveInningsProgress({
    required String matchId,
    required List<Map<String, dynamic>> innings,
    required int currentInningsNumber,
    required String battingTeamId,
  }) async {
    await _db.collection(AppConstants.matchesCol).doc(matchId).update({
      'innings': innings,
      'current_innings_number': currentInningsNumber,
      'current_batting_team_id': battingTeamId,
      'current_runs': 0,
      'current_wickets': 0,
      'legal_balls': 0,
      'striker_name': '',
      'non_striker_name': '',
      'current_bowler_name': '',
      'updated_at': FieldValue.serverTimestamp(),
    });
  }

  Future<void> completeMatch({
    required String matchId,
    required List<Map<String, dynamic>> innings,
    required int runs,
    required int wickets,
    required int legalBalls,
    required String battingTeamId,
    required String? winnerTeamId,
    required String resultType,
    required String resultText,
  }) async {
    await _db.collection(AppConstants.matchesCol).doc(matchId).update({
      'status': 'completed',
      'innings': innings,
      'current_innings_number': 2,
      'current_batting_team_id': battingTeamId,
      'current_runs': runs,
      'current_wickets': wickets,
      'legal_balls': legalBalls,
      'winner_team_id': winnerTeamId,
      'result_type': resultType,
      'result_text': resultText,
      'completed_at': FieldValue.serverTimestamp(),
      'updated_at': FieldValue.serverTimestamp(),
    });
  }

  Future<void> updateStatus(String matchId, String status) async {
    await _db.collection(AppConstants.matchesCol).doc(matchId).update({
      'status': status,
      'updated_at': FieldValue.serverTimestamp(),
    });
  }
}
