import 'package:flutter_test/flutter_test.dart';
import 'package:cricket_hub/providers/scoring_engine.dart';

/// ============================================================
/// UNIT TESTS for the Scoring Engine.
/// Implementation Plan rule: scoring logic MUST have 100% test
/// coverage — cricket rules can't be trusted to manual testing.
/// Run with:  flutter test
/// ============================================================

ScoringEngine _readyEngine({int overs = 2}) {
  final engine = ScoringEngine(ScoringState(
    battingTeamName: 'Team A',
    bowlingTeamName: 'Team B',
    totalOvers: overs,
    maxWickets: 10,
  ));
  engine.setOpener('Rahul');
  engine.setSecondOpener('Amit');
  engine.setBowler('Bhuvi');
  return engine;
}

void main() {
  group('ScoringEngine — basic runs', () {
    test('single run adds to total, batter and bowler', () {
      final e = _readyEngine();
      e.recordRuns(1);

      expect(e.state.totalRuns, 1);
      expect(e.state.legalBalls, 1);
      expect(e.state.batsmen['Rahul']!.runs, 1);
      expect(e.state.batsmen['Rahul']!.balls, 1);
      expect(e.state.bowlers['Bhuvi']!.runsConceded, 1);
      expect(e.state.bowlers['Bhuvi']!.legalBalls, 1);
    });

    test('boundary counts four correctly', () {
      final e = _readyEngine();
      e.recordRuns(4);

      expect(e.state.totalRuns, 4);
      expect(e.state.batsmen['Rahul']!.fours, 1);
    });

    test('six counts six correctly', () {
      final e = _readyEngine();
      e.recordRuns(6);

      expect(e.state.batsmen['Rahul']!.sixes, 1);
      expect(e.state.totalRuns, 6);
    });
  });

  group('ScoringEngine — strike rotation', () {
    test('odd runs rotate the strike', () {
      final e = _readyEngine();
      e.recordRuns(1); // Rahul takes 1 -> now at non-striker end

      expect(e.state.striker, 'Amit');
      expect(e.state.nonStriker, 'Rahul');
    });

    test('even runs keep the strike', () {
      final e = _readyEngine();
      e.recordRuns(2);

      expect(e.state.striker, 'Rahul');
    });

    test('over completion rotates the strike', () {
      final e = _readyEngine();
      // 6 legal balls, all singles already rotate each ball...
      // Use all dots: rotation happens ONLY at over end.
      for (var i = 0; i < 6; i++) {
        e.recordRuns(0);
      }
      expect(e.state.completedOvers, 1);
      // Rotation at over end: Rahul -> non-striker
      expect(e.state.striker, 'Amit');
      expect(e.state.pendingNewBowler, true);
    });

    test('wide does NOT count as a legal ball of the over', () {
      final e = _readyEngine();
      e.recordWide(); // extra delivery!
      for (var i = 0; i < 5; i++) {
        e.recordRuns(0);
      }
      // Only 5 LEGAL balls so far -> over NOT complete yet,
      // even though 6 total deliveries have been bowled.
      expect(e.state.completedOvers, 0);
      expect(e.state.ballsThisOver, 5);
      expect(e.state.legalBalls, 5);
    });

    test('6th legal ball after a wide finishes the over', () {
      final e = _readyEngine();
      e.recordWide();
      for (var i = 0; i < 6; i++) {
        e.recordRuns(0);
      }
      // 6 legal deliveries = over complete (7 deliveries bowled in total).
      expect(e.state.completedOvers, 1);
      expect(e.state.legalBalls, 6);
    });
  });

  group('ScoringEngine — extras', () {
    test('wide adds 1 penalty run, not a legal ball, batter untouched', () {
      final e = _readyEngine();
      e.recordWide();

      expect(e.state.totalRuns, 1);
      expect(e.state.legalBalls, 0);
      expect(e.state.batsmen['Rahul']!.balls, 0);
      expect(e.state.bowlers['Bhuvi']!.runsConceded, 1);
      expect(e.state.bowlers['Bhuvi']!.legalBalls, 0);
    });

    test('no ball with bat runs credits batter but not over count', () {
      final e = _readyEngine();
      e.recordNoBall(batRuns: 4);

      expect(e.state.totalRuns, 5); // 1 penalty + 4 bat
      expect(e.state.legalBalls, 0);
      expect(e.state.batsmen['Rahul']!.runs, 4);
      expect(e.state.bowlers['Bhuvi']!.runsConceded, 5);
    });

    test('byes are legal but NOT charged to the bowler', () {
      final e = _readyEngine();
      e.recordBye(2);

      expect(e.state.totalRuns, 2);
      expect(e.state.legalBalls, 1);
      expect(e.state.bowlers['Bhuvi']!.runsConceded, 0); // key rule!
      expect(e.state.bowlers['Bhuvi']!.legalBalls, 1);
      // Odd? No — 2 is even, strike stays.
      expect(e.state.striker, 'Rahul');
    });
  });

  group('ScoringEngine — wickets', () {
    test('wicket increments count and asks for the next batter', () {
      final e = _readyEngine();
      e.recordWicket(type: 'bowled');

      expect(e.state.wickets, 1);
      expect(e.state.legalBalls, 1);
      expect(e.state.pendingNewBatsman, true);
      expect(e.state.bowlers['Bhuvi']!.wickets, 1); // bowler credited
      expect(e.state.batsmen['Rahul']!.out, true);
    });

    test('run out does NOT credit the bowler with a wicket', () {
      final e = _readyEngine();
      e.recordWicket(type: 'run out', creditBowler: false);

      expect(e.state.wickets, 1);
      expect(e.state.bowlers['Bhuvi']!.wickets, 0);
    });

    test('all out finishes the innings', () {
      final e = ScoringEngine(const ScoringState(
        battingTeamName: 'Team A',
        bowlingTeamName: 'Team B',
        totalOvers: 20,
        maxWickets: 2, // short test
      ));
      e.setOpener('P1');
      e.setSecondOpener('P2');
      e.setBowler('B1');

      e.recordWicket(); // 1 down -> asks new batter
      e.confirmNewBatsman('P3');
      e.recordWicket(); // 2 down = all out

      expect(e.state.wickets, 2);
      expect(e.state.isAllOut, true);
      expect(e.state.isInningsComplete, true);
    });
  });

  group('ScoringEngine — undo', () {
    test('undo reverts the last ball completely', () {
      final e = _readyEngine();
      e.recordRuns(4);
      expect(e.state.totalRuns, 4);

      e.undo();
      expect(e.state.totalRuns, 0);
      expect(e.state.batsmen['Rahul']!.runs, 0);
      expect(e.state.batsmen['Rahul']!.balls, 0);
      expect(e.state.legalBalls, 0);
      expect(e.state.bowlers['Bhuvi']!.runsConceded, 0);
    });

    test('undo works across multiple actions', () {
      final e = _readyEngine();
      e.recordRuns(1);
      e.recordWide();
      e.recordRuns(4);

      e.undo(); // remove the 4
      expect(e.state.totalRuns, 2); // 1 + wide
      e.undo(); // remove the wide
      expect(e.state.totalRuns, 1);
    });

    test('undo on empty stack is safe (no crash)', () {
      final e = _readyEngine();
      expect(() => e.undo(), returnsNormally);
    });
  });

  group('ScoringEngine — innings state', () {
    test('overs done finishes the innings', () {
      final e = _readyEngine(overs: 1);
      for (var i = 0; i < 6; i++) {
        e.recordRuns(1);
      }
      expect(e.state.isOversDone, true);
      expect(e.state.isInningsComplete, true);
    });

    test('target chased finishes the innings', () {
      final e = _readyEngine(overs: 20);
      e.setTarget(5);
      e.recordRuns(6);

      expect(e.state.isTargetChased, true);
      expect(e.state.isInningsComplete, true);
    });

    test('overs display format is cricket-style', () {
      final e = _readyEngine();
      e.recordRuns(1);
      e.recordRuns(1);
      expect(e.state.oversDisplay, '0.2');

      for (var i = 0; i < 4; i++) {
        e.recordRuns(1);
      }
      expect(e.state.oversDisplay, '1.0');
    });

    test('CRR calculates correctly', () {
      final e = _readyEngine();
      // 12 runs in 6 balls (1 over) = 12.00
      for (var i = 0; i < 6; i++) {
        e.recordRuns(2);
      }
      expect(e.state.crr, '12.00');
    });
  });
}
