import 'package:flutter/foundation.dart';

import '../models/ball_event.dart';
import '../models/match_model.dart';
import '../services/match_service.dart';
import 'scoring_engine.dart';

/// Bridges the local, immutable scoring engine to Firestore. The first innings
/// is persisted before the chase starts; match completion writes both innings
/// and a result in one document update for standings/stat aggregation.
class ScoringProvider extends ChangeNotifier {
  static const int _sequenceStride = 100000;

  final CricketMatch match;
  final MatchService _matchService;
  late ScoringEngine engine;
  int _inningsNumber = 1;
  final List<Map<String, dynamic>> _completedInnings = [];

  ScoringProvider(this.match, this._matchService) {
    engine = _newEngine(inningsNumber: 1);
  }

  ScoringState get state => engine.state;
  String get matchId => match.id;
  int get inningsNumber => _inningsNumber;
  bool get isSecondInnings => _inningsNumber == 2;

  String get battingTeamId => _inningsNumber == 1
      ? match.battingTeamId
      : match.bowlingTeamId;

  String get bowlingTeamId => _inningsNumber == 1
      ? match.bowlingTeamId
      : match.battingTeamId;

  String _teamName(String teamId) => teamId == match.teamAId
      ? match.teamAName
      : teamId == match.teamBId
          ? match.teamBName
          : '';

  ScoringEngine _newEngine({required int inningsNumber, int? target}) {
    final battingId = inningsNumber == 1 ? match.battingTeamId : match.bowlingTeamId;
    final bowlingId = inningsNumber == 1 ? match.bowlingTeamId : match.battingTeamId;
    final state = ScoringState(
      battingTeamName: _teamName(battingId),
      bowlingTeamName: _teamName(bowlingId),
      totalOvers: match.totalOvers,
      maxWickets: 10,
      target: target,
    );
    return ScoringEngine(state);
  }

  String _canonicalName(String name) =>
      name.trim().replaceAll(RegExp(r'\s+'), ' ').toLowerCase();

  String _linkedUidFor(String playerName) {
    final scorerName = match.scorerName.trim();
    if (match.scorerUid.isNotEmpty &&
        scorerName.isNotEmpty &&
        _canonicalName(playerName) == _canonicalName(scorerName)) {
      return match.scorerUid;
    }
    return '';
  }

  /// Builds a stable, server-readable innings snapshot from the same state
  /// shown to the scorer; no client-side tournament points are trusted.
  Map<String, dynamic> _snapshotInnings() {
    final current = engine.state;
    final battingName = _teamName(battingTeamId);
    final bowlingName = _teamName(bowlingTeamId);
    final batting = current.batsmen.values.map((player) => <String, dynamic>{
      'name': player.name,
      'player_uid': _linkedUidFor(player.name),
      'runs': player.runs,
      'balls': player.balls,
      'fours': player.fours,
      'sixes': player.sixes,
      'out': player.out,
      'how_out': player.howOut,
    }).toList();
    final bowling = current.bowlers.values.map((player) => <String, dynamic>{
      'name': player.name,
      'player_uid': _linkedUidFor(player.name),
      'legal_balls': player.legalBalls,
      'runs_conceded': player.runsConceded,
      'wickets': player.wickets,
    }).toList();
    return {
      'innings_number': _inningsNumber,
      'team_id': battingTeamId,
      'team_name': battingName,
      'bowling_team_id': bowlingTeamId,
      'bowling_team_name': bowlingName,
      'runs': current.totalRuns,
      'wickets': current.wickets,
      'max_wickets': current.maxWickets,
      'legal_balls': current.legalBalls,
      'overs_limit': current.totalOvers,
      'all_out': current.isAllOut,
      'ended_by_target': current.isTargetChased,
      'batting': batting,
      'bowling': bowling,
      'recorded_at': DateTime.now().toUtc().toIso8601String(),
    };
  }

  void _afterAction(
    ScoringState before, {
    required int runs,
    int batRuns = 0,
    int extraRuns = 0,
    String extraType = '',
    String wicketType = '',
  }) {
    final after = engine.state;
    if (after.nextSequence == before.nextSequence) return;

    final strikerUid = _linkedUidFor(before.striker);
    final bowlerUid = _linkedUidFor(before.currentBowler);
    final ball = BallEvent(
      sequence: ((_inningsNumber - 1) * _sequenceStride) + before.nextSequence,
      inningsNumber: _inningsNumber,
      overNumber: before.completedOvers,
      ballInOver: before.ballsThisOver + 1,
      runs: runs,
      batRuns: batRuns,
      extraRuns: extraRuns,
      scoreAfter: after.totalRuns,
      wicketsAfter: after.wickets,
      extraType: extraType,
      wicketType: wicketType,
      playerOut: wicketType.isNotEmpty ? before.striker : '',
      bowlerName: before.currentBowler,
      strikerName: before.striker,
      strikerUid: strikerUid,
      bowlerUid: bowlerUid,
    );

    _matchService
        .pushBall(
          matchId: match.id,
          ball: ball,
          totalRuns: after.totalRuns,
          totalWickets: after.wickets,
          legalBalls: after.legalBalls,
          battingTeamId: battingTeamId,
          strikerName: after.striker,
          nonStrikerName: after.nonStriker,
          bowlerName: after.currentBowler,
        )
        .catchError((_) {});
    notifyListeners();
  }

  void recordRuns(int runs) {
    final before = engine.state;
    engine.recordRuns(runs);
    _afterAction(before, runs: runs, batRuns: runs);
  }

  void recordWide({int additional = 0}) {
    final before = engine.state;
    engine.recordWide(additional: additional);
    _afterAction(
      before,
      runs: 1 + additional,
      extraRuns: 1 + additional,
      extraType: 'wide',
    );
  }

  void recordNoBall({int batRuns = 0}) {
    final before = engine.state;
    engine.recordNoBall(batRuns: batRuns);
    _afterAction(
      before,
      runs: 1 + batRuns,
      batRuns: batRuns,
      extraRuns: 1,
      extraType: 'no_ball',
    );
  }

  void recordBye(int runs) {
    final before = engine.state;
    engine.recordBye(runs);
    _afterAction(before, runs: runs, extraRuns: runs, extraType: 'bye');
  }

  void recordLegBye(int runs) {
    final before = engine.state;
    engine.recordLegBye(runs);
    _afterAction(before, runs: runs, extraRuns: runs, extraType: 'leg_bye');
  }

  void recordWicket({required String type}) {
    final before = engine.state;
    final normalized = type.trim().toLowerCase();
    final creditBowler = normalized != 'run out' &&
        normalized != 'retired hurt' &&
        normalized != 'obstructing the field';
    engine.recordWicket(type: type, creditBowler: creditBowler);
    _afterAction(before, runs: 0, wicketType: type);
  }

  void undo() {
    if (!engine.canUndo) return;
    engine.undo();
    final current = engine.state;
    final sequence = ((_inningsNumber - 1) * _sequenceStride) + current.nextSequence;
    _matchService
        .undoLastBall(
          matchId: match.id,
          sequence: sequence,
          totalRuns: current.totalRuns,
          totalWickets: current.wickets,
          legalBalls: current.legalBalls,
          battingTeamId: battingTeamId,
          strikerName: current.striker,
          nonStrikerName: current.nonStriker,
          bowlerName: current.currentBowler,
          inningsNumber: _inningsNumber,
        )
        .catchError((_) {});
    notifyListeners();
  }

  void setOpener(String name) {
    engine.setOpener(name);
    notifyListeners();
  }

  void setSecondOpener(String name) {
    engine.setSecondOpener(name);
    notifyListeners();
  }

  void setBowler(String name) {
    engine.setBowler(name);
    notifyListeners();
  }

  void confirmNewBatsman(String name) {
    engine.confirmNewBatsman(name);
    notifyListeners();
  }

  Future<void> startSecondInnings() async {
    if (_inningsNumber != 1 || !engine.state.isInningsComplete) {
      throw StateError('The first innings must be complete before the chase.');
    }
    final firstInnings = _snapshotInnings();
    _completedInnings
      ..clear()
      ..add(firstInnings);
    _matchService
        .saveInningsProgress(
          matchId: match.id,
          innings: List<Map<String, dynamic>>.from(_completedInnings),
          currentInningsNumber: 2,
          battingTeamId: match.bowlingTeamId,
        )
        .catchError((_) {});
    _inningsNumber = 2;
    engine = _newEngine(
      inningsNumber: 2,
      target: (firstInnings['runs'] as int) + 1,
    );
    notifyListeners();
  }

  /// Finish the second innings and persist the authoritative result payload.
  Future<void> endMatch() async {
    if (_inningsNumber != 2 || !engine.state.isInningsComplete) {
      throw StateError('Complete both innings before ending the match.');
    }
    final secondInnings = _snapshotInnings();
    final innings = [..._completedInnings, secondInnings];
    final first = innings.first;
    final second = innings.last;
    final firstRuns = first['runs'] as int;
    final secondRuns = second['runs'] as int;

    String? winnerTeamId;
    String resultType;
    String resultText;
    if (firstRuns == secondRuns) {
      resultType = 'tie';
      resultText = 'Match tied';
    } else if (secondRuns > firstRuns) {
      winnerTeamId = battingTeamId;
      resultType = 'win';
      final remaining = (second['max_wickets'] as int) - (second['wickets'] as int);
      resultText = '${_teamName(winnerTeamId)} won by $remaining wicket${remaining == 1 ? '' : 's'}';
    } else {
      winnerTeamId = match.battingTeamId;
      resultType = 'win';
      final margin = firstRuns - secondRuns;
      resultText = '${_teamName(winnerTeamId)} won by $margin run${margin == 1 ? '' : 's'}';
    }

    final current = engine.state;
    _matchService
        .completeMatch(
          matchId: match.id,
          innings: innings,
          runs: current.totalRuns,
          wickets: current.wickets,
          legalBalls: current.legalBalls,
          battingTeamId: battingTeamId,
          winnerTeamId: winnerTeamId,
          resultType: resultType,
          resultText: resultText,
        )
        .catchError((_) {});
  }
}
