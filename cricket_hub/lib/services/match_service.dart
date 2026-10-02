import 'package:cloud_firestore/cloud_firestore.dart';

import '../core/app_constants.dart';
import '../models/ball_event.dart';
import '../models/match_model.dart';

/// All match + ball-by-ball Firestore calls live here.
///
/// OFFLINE NOTE: Firestore keeps a local cache on the phone.
/// If the scorer has no network, writes are queued locally and
/// Firestore syncs them automatically when the connection returns.
/// (Full Isar queue comes in Sprint 4 — this already works offline.)
class MatchService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  /// Live list of matches for the Home screen.
  Stream<List<CricketMatch>> matchesStream() {
    return _db
        .collection(AppConstants.matchesCol)
        .orderBy('created_at', descending: true)
        .limit(50)
        .snapshots()
        .map((snap) => snap.docs
            .map((doc) => CricketMatch.fromFirestore(doc.id, doc.data()))
            .toList());
  }

  /// One live match (the fan's Live Match screen listens to this).
  Stream<CricketMatch?> matchStream(String matchId) {
    return _db.collection(AppConstants.matchesCol).doc(matchId).snapshots().map(
          (snap) => snap.exists ? CricketMatch.fromFirestore(snap.id, snap.data()!) : null,
        );
  }

  /// Ball-by-ball feed for the Commentary tab.
  Stream<List<BallEvent>> ballsStream(String matchId) {
    return _db
        .collection(AppConstants.matchesCol)
        .doc(matchId)
        .collection(AppConstants.ballsSubCol)
        .orderBy('sequence', descending: true)
        .limit(120)
        .snapshots()
        .map((snap) => snap.docs.map((doc) {
              final d = doc.data();
              return BallEvent(
                sequence: (d['sequence'] ?? 0) as int,
                overNumber: (d['over_number'] ?? 0) as int,
                ballInOver: (d['ball_in_over'] ?? 0) as int,
                runs: (d['runs'] ?? 0) as int,
                extraType: ((d['extras'] ?? const {})['type'] ?? '') as String,
                wicketType: ((d['wicket'] ?? const {})['type'] ?? '') as String,
                playerOut: ((d['wicket'] ?? const {})['player_out'] ?? '') as String,
                bowlerName: (d['bowler_name'] ?? '') as String,
                strikerName: (d['striker_name'] ?? '') as String,
                timestamp: (d['timestamp'] as Timestamp?)?.toDate(),
              );
            }).toList());
  }

  /// Step 1 of Flow 3 (App Flow doc): create the pre-match document.
  Future<String> createMatch(CricketMatch match) async {
    final doc = await _db
        .collection(AppConstants.matchesCol)
        .add(match.toMapPreMatch());
    return doc.id;
  }

  /// Step 2 of Flow 3: toss done -> match goes LIVE.
  Future<void> startMatchWithToss(CricketMatch match) async {
    await _db
        .collection(AppConstants.matchesCol)
        .doc(match.id)
        .update(match.tossToMap());
  }

  /// The scorer taps a run/extra/wicket button:
  /// 1. write the ball event to the `balls` subcollection
  /// 2. update the match `current_summary` (fans read THIS, cheap!)
  Future<void> pushBall({
    required String matchId,
    required BallEvent ball,
    required int totalRuns,
    required int totalWickets,
    required int legalBalls,
    required String strikerName,
    required String nonStrikerName,
    required String bowlerName,
  }) async {
    final batch = _db.batch(); // WriteBatch = all-or-nothing write

    final ballRef = _db
        .collection(AppConstants.matchesCol)
        .doc(matchId)
        .collection(AppConstants.ballsSubCol)
        .doc('ball_${ball.sequence.toString().padLeft(3, '0')}');

    batch.set(ballRef, ball.toMap());

    batch.update(
      _db.collection(AppConstants.matchesCol).doc(matchId),
      {
        'current_runs': totalRuns,
        'current_wickets': totalWickets,
        'legal_balls': legalBalls,
        'striker_name': strikerName,
        'non_striker_name': nonStrikerName,
        'current_bowler_name': bowlerName,
      },
    );

    await batch.commit();
  }

  /// End of innings / end of match.
  Future<void> updateStatus(String matchId, String status) async {
    await _db
        .collection(AppConstants.matchesCol)
        .doc(matchId)
        .update({'status': status});
  }
}
