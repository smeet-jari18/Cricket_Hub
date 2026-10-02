import 'package:flutter/foundation.dart';

import '../models/ball_event.dart';
import '../models/match_model.dart';
import '../services/match_service.dart';
import 'scoring_engine.dart';

/// Connects the pure ScoringEngine to Firestore.
/// Flow: UI taps button -> engine updates state -> ball event + summary
/// are pushed to Firebase (works offline: Firestore queues writes).
class ScoringProvider extends ChangeNotifier {
  final CricketMatch match;
  final MatchService _matchService;
  late ScoringEngine engine;

  ScoringProvider(this.match, this._matchService) {
    final battingTeamName = match.battingTeamId == match.teamAId
        ? match.teamAName
        : match.teamBName;
    final bowlingTeamName = match.battingTeamId == match.teamAId
        ? match.teamBName
        : match.teamAName;

    engine = ScoringEngine(ScoringState(
      battingTeamName: battingTeamName,
      bowlingTeamName: bowlingTeamName,
      totalOvers: match.totalOvers,
      maxWickets: 10,
    ));
  }

  ScoringState get state => engine.state;
  String get matchId => match.id;

  /// Shared tail for every ball action: build BallEvent, push to cloud.
  void _afterAction(
    ScoringState before, {
    required int runs,
    String extraType = '',
    String wicketType = '',
  }) {
    final after = engine.state;

    final ball = BallEvent(
      sequence: before.nextSequence,
      overNumber: before.completedOvers,
      ballInOver: before.ballsThisOver + 1,
      runs: runs,
      extraType: extraType,
      wicketType: wicketType,
      playerOut: wicketType.isNotEmpty ? before.striker : '',
      bowlerName: before.currentBowler,
      strikerName: before.striker,
    );

    // Fire-and-forget: UI never waits for the network (offline-first!).
    _matchService
        .pushBall(
          matchId: match.id,
          ball: ball,
          totalRuns: after.totalRuns,
          totalWickets: after.wickets,
          legalBalls: after.legalBalls,
          strikerName: after.striker,
          nonStrikerName: after.nonStriker,
          bowlerName: after.currentBowler,
        )
        .catchError((_) {}); // queued locally if offline; retry later

    notifyListeners();
  }

  // ---- engine wrappers (UI calls these) ----

  void recordRuns(int runs) {
    final before = engine.state;
    engine.recordRuns(runs);
    _afterAction(before, runs: runs);
  }

  void recordWide({int additional = 0}) {
    final before = engine.state;
    engine.recordWide(additional: additional);
    _afterAction(before, runs: 1 + additional, extraType: 'wide');
  }

  void recordNoBall({int batRuns = 0}) {
    final before = engine.state;
    engine.recordNoBall(batRuns: batRuns);
    _afterAction(before, runs: 1 + batRuns, extraType: 'no_ball');
  }

  void recordBye(int runs) {
    final before = engine.state;
    engine.recordBye(runs);
    _afterAction(before, runs: runs, extraType: 'bye');
  }

  void recordLegBye(int runs) {
    final before = engine.state;
    engine.recordLegBye(runs);
    _afterAction(before, runs: runs, extraType: 'leg_bye');
  }

  void recordWicket({required String type}) {
    final before = engine.state;
    final creditBowler = type != 'run out' && type != 'retired hurt';
    engine.recordWicket(type: type, creditBowler: creditBowler);
    _afterAction(before, runs: 0, wicketType: type);
  }

  void undo() => engine.undo();
  void setOpener(String name) => engine.setOpener(name);
  void setSecondOpener(String name) => engine.setSecondOpener(name);
  void setBowler(String name) => engine.setBowler(name);
  void confirmNewBatsman(String name) => engine.confirmNewBatsman(name);

  /// Innings over -> mark the match completed in Firebase.
  Future<void> endMatch() async {
    await _matchService.updateStatus(match.id, 'completed');
  }
}
