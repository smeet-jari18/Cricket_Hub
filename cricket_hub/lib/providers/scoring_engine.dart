import 'package:flutter/foundation.dart';

/// ============================================================
/// THE SCORING ENGINE — the heart of CricketHub.
///
/// This file is PURE CRICKET LOGIC (no Firebase, no UI),
/// so it can be 100% unit tested (Implementation Plan rule).
///
/// Supported rules (v1):
///  - Runs 0-6 off the bat, strike rotation on 1/3/5
///  - Wides & No-balls: +1 penalty, NOT legal balls (over continues)
///  - Byes & Leg byes: legal balls, runs NOT charged to the bowler
///  - Wickets: bowler credited except run-outs
///  - Over end after 6 legal balls -> rotate strike + new bowler
///  - Undo everything (snapshot stack)
/// ============================================================

/// Batting stats for one player.
@immutable
class BatStats {
  final String name;
  final int runs;
  final int balls;
  final int fours;
  final int sixes;
  final bool out;
  final String howOut;

  const BatStats({
    required this.name,
    this.runs = 0,
    this.balls = 0,
    this.fours = 0,
    this.sixes = 0,
    this.out = false,
    this.howOut = '',
  });

  String get strikeRate =>
      balls == 0 ? '0.0' : ((runs / balls) * 100).toStringAsFixed(1);

  BatStats copyWith({
    int? runs,
    int? balls,
    int? fours,
    int? sixes,
    bool? out,
    String? howOut,
  }) {
    return BatStats(
      name: name,
      runs: runs ?? this.runs,
      balls: balls ?? this.balls,
      fours: fours ?? this.fours,
      sixes: sixes ?? this.sixes,
      out: out ?? this.out,
      howOut: howOut ?? this.howOut,
    );
  }
}

/// Bowling stats for one player.
@immutable
class BowlStats {
  final String name;
  final int legalBalls;
  final int runsConceded;
  final int wickets;

  const BowlStats({
    required this.name,
    this.legalBalls = 0,
    this.runsConceded = 0,
    this.wickets = 0,
  });

  /// Overs in cricket display: "4.2" = 4 overs + 2 balls.
  String get oversDisplay => '${legalBalls ~/ 6}.${legalBalls % 6}';

  String get economy =>
      legalBalls == 0 ? '0.00' : (runsConceded / (legalBalls / 6)).toStringAsFixed(2);

  BowlStats copyWith({int? legalBalls, int? runsConceded, int? wickets}) {
    return BowlStats(
      name: name,
      legalBalls: legalBalls ?? this.legalBalls,
      runsConceded: runsConceded ?? this.runsConceded,
      wickets: wickets ?? this.wickets,
    );
  }
}

/// Everything that describes the current innings.
/// One action = one new immutable state -> easy & safe Undo.
@immutable
class ScoringState {
  final String battingTeamName;
  final String bowlingTeamName;
  final int totalOvers;
  final int maxWickets;

  final int totalRuns;
  final int wickets;
  final int legalBalls; // total in this innings
  final int ballsThisOver; // 0..5 (legal only)
  final int completedOvers;

  final Map<String, BatStats> batsmen; // key = player name
  final Map<String, BowlStats> bowlers; // key = player name

  final String striker;
  final String nonStriker;
  final String currentBowler;

  final List<String> thisOverBalls; // display tokens: "1","4","WD","W"
  final int nextSequence; // running ball id (ball_001, ball_002 ...)

  final bool pendingNewBatsman; // wicket just fell -> pick next batter
  final bool pendingNewBowler; // over finished -> pick next bowler
  final bool overJustEnded; // over completed (used after wicket-at-over-end)
  final int? target; // 2nd innings chase target (null = 1st innings)
  final String lastEventText; // for the UI banner/commentary

  const ScoringState({
    required this.battingTeamName,
    required this.bowlingTeamName,
    required this.totalOvers,
    required this.maxWickets,
    this.totalRuns = 0,
    this.wickets = 0,
    this.legalBalls = 0,
    this.ballsThisOver = 0,
    this.completedOvers = 0,
    this.batsmen = const {},
    this.bowlers = const {},
    this.striker = '',
    this.nonStriker = '',
    this.currentBowler = '',
    this.thisOverBalls = const [],
    this.nextSequence = 1,
    this.pendingNewBatsman = false,
    this.pendingNewBowler = false,
    this.overJustEnded = false,
    this.target,
    this.lastEventText = 'Match started',
  });

  /// "15.2" style overs display.
  String get oversDisplay => '$completedOvers.$ballsThisOver';

  /// Current run rate.
  String get crr =>
      legalBalls == 0 ? '0.00' : (totalRuns / (legalBalls / 6)).toStringAsFixed(2);

  /// Required run rate (only when chasing).
  String? get rrr {
    if (target == null) return null;
    final ballsLeft = totalOvers * 6 - legalBalls;
    final runsNeeded = target! - totalRuns;
    if (ballsLeft <= 0) return null;
    return (runsNeeded * 6 / ballsLeft).toStringAsFixed(2);
  }

  int get runsNeeded => target == null ? 0 : (target! - totalRuns);

  bool get isAllOut => wickets >= maxWickets;

  bool get isOversDone => legalBalls >= totalOvers * 6;

  bool get isTargetChased => target != null && totalRuns >= target!;

  /// Innings is finished?
  bool get isInningsComplete => isAllOut || isOversDone || isTargetChased;

  /// True while the scorer must handle a dialog (new batter / bowler).
  bool get needsAttention => pendingNewBatsman || pendingNewBowler;

  // ---------- deep copy helpers (for Undo snapshots) ----------

  Map<String, BatStats> _copyBatsmen() =>
      batsmen.map((k, v) => MapEntry(k, v));

  Map<String, BowlStats> _copyBowlers() =>
      bowlers.map((k, v) => MapEntry(k, v));

  ScoringState copyWith({
    int? totalRuns,
    int? wickets,
    int? legalBalls,
    int? ballsThisOver,
    int? completedOvers,
    Map<String, BatStats>? batsmen,
    Map<String, BowlStats>? bowlers,
    String? striker,
    String? nonStriker,
    String? currentBowler,
    List<String>? thisOverBalls,
    int? nextSequence,
    bool? pendingNewBatsman,
    bool? pendingNewBowler,
    bool? overJustEnded,
    int? target,
    String? lastEventText,
  }) {
    return ScoringState(
      battingTeamName: battingTeamName,
      bowlingTeamName: bowlingTeamName,
      totalOvers: totalOvers,
      maxWickets: maxWickets,
      totalRuns: totalRuns ?? this.totalRuns,
      wickets: wickets ?? this.wickets,
      legalBalls: legalBalls ?? this.legalBalls,
      ballsThisOver: ballsThisOver ?? this.ballsThisOver,
      completedOvers: completedOvers ?? this.completedOvers,
      batsmen: batsmen ?? _copyBatsmen(),
      bowlers: bowlers ?? _copyBowlers(),
      striker: striker ?? this.striker,
      nonStriker: nonStriker ?? this.nonStriker,
      currentBowler: currentBowler ?? this.currentBowler,
      thisOverBalls: thisOverBalls ?? List.of(this.thisOverBalls),
      nextSequence: nextSequence ?? this.nextSequence,
      pendingNewBatsman: pendingNewBatsman ?? this.pendingNewBatsman,
      pendingNewBowler: pendingNewBowler ?? this.pendingNewBowler,
      overJustEnded: overJustEnded ?? this.overJustEnded,
      target: target ?? this.target,
      lastEventText: lastEventText ?? this.lastEventText,
    );
  }
}

class ScoringEngine extends ChangeNotifier {
  ScoringState _state;
  final List<ScoringState> _undoStack = <ScoringState>[];

  ScoringEngine(this._state);

  ScoringState get state => _state;

  /// Snapshot of the state BEFORE the last action (for cloud sync of
  /// the last recorded ball).
  ScoringState? get lastSnapshot =>
      _undoStack.isEmpty ? null : _undoStack.last;

  void _backup() {
    _undoStack.add(_state);
    if (_undoStack.length > 500) _undoStack.removeAt(0); // safety cap
  }

  void _apply(ScoringState next) {
    _state = next;
    notifyListeners();
  }

  // ---------------- SETUP ----------------

  void setOpener(String name) {
    if (name.trim().isEmpty || _state.batsmen.containsKey(name)) return;
    final batsmen = _state._copyBatsmen();
    batsmen[name.trim()] = BatStats(name: name.trim());
    _apply(_state.copyWith(batsmen: batsmen, striker: name.trim()));
  }

  void setSecondOpener(String name) {
    if (name.trim().isEmpty || _state.batsmen.containsKey(name)) return;
    final batsmen = _state._copyBatsmen();
    batsmen[name.trim()] = BatStats(name: name.trim());
    _apply(_state.copyWith(batsmen: batsmen, nonStriker: name.trim()));
  }

  void setBowler(String name) {
    if (name.trim().isEmpty) return;
    final bowlers = _state._copyBowlers();
    bowlers[name.trim()] =
        bowlers[name.trim()] ?? BowlStats(name: name.trim());
    _apply(_state.copyWith(
      bowlers: bowlers,
      currentBowler: name.trim(),
      pendingNewBowler: false,
      overJustEnded: false,
    ));
  }

  /// New batter after a wicket (replaces the striker position).
  void confirmNewBatsman(String name) {
    if (name.trim().isEmpty || _state.batsmen.containsKey(name.trim())) {
      _apply(_state.copyWith(pendingNewBatsman: false));
      return;
    }
    final batsmen = _state._copyBatsmen();
    batsmen[name.trim()] = BatStats(name: name.trim());
    var next = _state.copyWith(
      batsmen: batsmen,
      striker: name.trim(),
      pendingNewBatsman: false,
    );
    // Wicket fell on the LAST ball of the over? Then we still need
    // to ask for the new bowler now that the batter is confirmed.
    if (next.overJustEnded && !next.isInningsComplete) {
      next = next.copyWith(pendingNewBowler: true);
    }
    _apply(next);
  }

  void setTarget(int runs) {
    _apply(_state.copyWith(target: runs));
  }

  // ---------------- RUNS OFF THE BAT ----------------

  void recordRuns(int runs) {
    if (_state.needsAttention || runs < 0) return;
    _backup();

    final batsmen = _state._copyBatsmen();
    final bowlers = _state._copyBowlers();

    // Batter
    final s = _state.striker;
    final oldBat = batsmen[s]!;
    batsmen[s] = oldBat.copyWith(
      runs: oldBat.runs + runs,
      balls: oldBat.balls + 1,
      fours: runs == 4 ? oldBat.fours + 1 : oldBat.fours,
      sixes: runs == 6 ? oldBat.sixes + 1 : oldBat.sixes,
    );

    // Bowler concedes the runs
    final b = _state.currentBowler;
    final oldBowl = bowlers[b]!;
    bowlers[b] = oldBowl.copyWith(
      runsConceded: oldBowl.runsConceded + runs,
      legalBalls: oldBowl.legalBalls + 1,
    );

    var next = _state.copyWith(
      totalRuns: _state.totalRuns + runs,
      legalBalls: _state.legalBalls + 1,
      batsmen: batsmen,
      bowlers: bowlers,
      thisOverBalls: [..._state.thisOverBalls, '$runs'],
      nextSequence: _state.nextSequence + 1,
      lastEventText: '$s scored $runs run${runs == 1 ? '' : 's'}',
    );

    if (runs.isOdd) next = _rotated(next); // 1, 3, 5 -> swap ends
    next = _afterLegalBall(next);
    _apply(next);
  }

  // ---------------- EXTRAS ----------------

  /// WIDE: +1 penalty (plus any additional runs run).
  /// NOT a legal ball, batter's ball count unchanged.
  void recordWide({int additional = 0}) {
    if (_state.needsAttention) return;
    _backup();

    final bowlers = _state._copyBowlers();
    final b = _state.currentBowler;
    final totalWideRuns = 1 + additional;

    bowlers[b] =
        bowlers[b]!.copyWith(runsConceded: bowlers[b]!.runsConceded + totalWideRuns);

    var next = _state.copyWith(
      totalRuns: _state.totalRuns + totalWideRuns,
      bowlers: bowlers,
      thisOverBalls: [
        ..._state.thisOverBalls,
        additional > 0 ? 'W$additional' : 'WD'
      ],
      nextSequence: _state.nextSequence + 1,
      lastEventText: 'Wide ball (+$totalWideRuns)',
    );

    if (additional.isOdd) next = _rotated(next);
    _apply(next);
  }

  /// NO BALL: +1 penalty plus runs off the bat.
  /// NOT a legal ball, but the batter IS credited with runs + ball faced.
  void recordNoBall({int batRuns = 0}) {
    if (_state.needsAttention) return;
    _backup();

    final batsmen = _state._copyBatsmen();
    final bowlers = _state._copyBowlers();

    final s = _state.striker;
    batsmen[s] = batsmen[s]!.copyWith(
      runs: batsmen[s]!.runs + batRuns,
      balls: batsmen[s]!.balls + 1,
      fours: batRuns == 4 ? batsmen[s]!.fours + 1 : batsmen[s]!.fours,
      sixes: batRuns == 6 ? batsmen[s]!.sixes + 1 : batsmen[s]!.sixes,
    );

    final b = _state.currentBowler;
    bowlers[b] = bowlers[b]!
        .copyWith(runsConceded: bowlers[b]!.runsConceded + 1 + batRuns);

    var next = _state.copyWith(
      totalRuns: _state.totalRuns + 1 + batRuns,
      batsmen: batsmen,
      bowlers: bowlers,
      thisOverBalls: [ ..._state.thisOverBalls, batRuns > 0 ? 'NB$batRuns' : 'NB'],
      nextSequence: _state.nextSequence + 1,
      lastEventText: 'No ball (+${1 + batRuns})',
    );

    if (batRuns.isOdd) next = _rotated(next);
    _apply(next);
  }

  /// BYE / LEG BYE: legal ball, runs NOT charged to the bowler.
  void _recordByeLike(int runs, String label) {
    if (_state.needsAttention || runs <= 0) return;
    _backup();

    final batsmen = _state._copyBatsmen();
    final bowlers = _state._copyBowlers();

    final s = _state.striker;
    batsmen[s] = batsmen[s]!.copyWith(balls: batsmen[s]!.balls + 1);

    final b = _state.currentBowler;
    bowlers[b] =
        bowlers[b]!.copyWith(legalBalls: bowlers[b]!.legalBalls + 1);

    var next = _state.copyWith(
      totalRuns: _state.totalRuns + runs,
      legalBalls: _state.legalBalls + 1,
      batsmen: batsmen,
      bowlers: bowlers,
      thisOverBalls: [..._state.thisOverBalls, '$label$runs'],
      nextSequence: _state.nextSequence + 1,
      lastEventText: '$label: $runs run${runs == 1 ? '' : 's'}',
    );

    if (runs.isOdd) next = _rotated(next);
    next = _afterLegalBall(next);
    _apply(next);
  }

  void recordBye(int runs) => _recordByeLike(runs, 'B');
  void recordLegBye(int runs) => _recordByeLike(runs, 'LB');

  // ---------------- WICKET ----------------

  void recordWicket({String type = 'bowled', bool creditBowler = true}) {
    if (_state.needsAttention) return;
    _backup();

    final batsmen = _state._copyBatsmen();
    final bowlers = _state._copyBowlers();

    final s = _state.striker;
    batsmen[s] = batsmen[s]!.copyWith(
      out: true,
      howOut: type,
      balls: batsmen[s]!.balls + 1,
    );

    if (creditBowler) {
      final b = _state.currentBowler;
      bowlers[b] = bowlers[b]!.copyWith(
        legalBalls: bowlers[b]!.legalBalls + 1,
        wickets: bowlers[b]!.wickets + 1,
      );
    } else {
      final b = _state.currentBowler;
      bowlers[b] =
          bowlers[b]!.copyWith(legalBalls: bowlers[b]!.legalBalls + 1);
    }

    var next = _state.copyWith(
      wickets: _state.wickets + 1,
      legalBalls: _state.legalBalls + 1,
      batsmen: batsmen,
      bowlers: bowlers,
      thisOverBalls: [..._state.thisOverBalls, 'W'],
      nextSequence: _state.nextSequence + 1,
      pendingNewBatsman: true, // UI must ask: who is the new batter?
      lastEventText: 'WICKET! $s out ($type)',
    );

    next = _afterLegalBall(next, allowBowlerChangePrompt: false);
    if (next.isInningsComplete) {
      next = next.copyWith(pendingNewBatsman: false);
    }
    _apply(next);
  }

  // ---------------- UNDO ----------------

  void undo() {
    if (_undoStack.isEmpty) return;
    _state = _undoStack.removeLast();
    notifyListeners();
  }

  bool get canUndo => _undoStack.isNotEmpty;

  // ---------------- INTERNAL HELPERS ----------------

  /// Swap striker and non-striker.
  ScoringState _rotated(ScoringState s) {
    return s.copyWith(striker: s.nonStriker, nonStriker: s.striker);
  }

  /// Common logic after every LEGAL ball: over end checks.
  ScoringState _afterLegalBall(ScoringState s,
      {bool allowBowlerChangePrompt = true}) {
    // Target chased -> match over, no over-end prompt needed.
    if (s.isTargetChased) return s.copyWith(pendingNewBowler: false);

    var next = s;

    if (next.ballsThisOver + 1 >= 6) {
      // OVER COMPLETE
      next = _rotated(next.copyWith(
        ballsThisOver: 0,
        completedOvers: next.completedOvers + 1,
        overJustEnded: true,
      ));
      if (allowBowlerChangePrompt && !next.isInningsComplete) {
        next = next.copyWith(pendingNewBowler: true);
      }
      return next;
    }

    return next.copyWith(
        ballsThisOver: next.ballsThisOver + 1, overJustEnded: false);
  }
}
