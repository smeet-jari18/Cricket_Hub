// ============================================================
// EDGE-CASE REVIEW TESTS — added by the reviewer (Arena agent).
// Not part of the original repo. Purpose: probe the scoring
// engine for crash-paths and illegal-state bugs that the
// existing 35 tests do not cover.
// ============================================================
import 'package:flutter_test/flutter_test.dart';

import 'package:cricket_hub/providers/scoring_engine.dart';

ScoringEngine _engine({int overs = 2, int wickets = 10}) => ScoringEngine(
      ScoringState(
        battingTeamName: 'Team A',
        bowlingTeamName: 'Team B',
        totalOvers: overs,
        maxWickets: wickets,
      ),
    );

void main() {
  group('A. Un-setup state (no opener / no bowler)', () {
    test('recordRuns before setOpener/setBowler', () {
      final e = _engine();
      expect(
        () => e.recordRuns(1),
        returnsNormally,
        reason: 'Scoring 1 run on a fresh engine must not crash the app',
      );
    });

    test('recordWide before options/bowler are set', () {
      final e = _engine();
      expect(() => e.recordWide(), returnsNormally);
    });

    test('recordNoBall before options/bowler are set', () {
      final e = _engine();
      expect(() => e.recordNoBall(batRuns: 4), returnsNormally);
    });

    test('recordBye before options/bowler are set', () {
      final e = _engine();
      expect(() => e.recordBye(1), returnsNormally);
    });

    test('recordWicket before options/bowler are set', () {
      final e = _engine();
      expect(() => e.recordWicket(), returnsNormally);
    });

    test('opener set but NO bowler', () {
      final e = _engine();
      e.setOpener('Rahul');
      e.setSecondOpener('Amit');
      expect(() => e.recordRuns(2), returnsNormally);
    });

    test('bowler set but NO opener', () {
      final e = _engine();
      e.setBowler('Bhuvi');
      expect(() => e.recordRuns(2), returnsNormally);
    });
  });

  group('B. Scoring after the innings is already over', () {
    test('recordRuns after all out must not add runs', () {
      final e = _engine(overs: 5, wickets: 2);
      e.setOpener('Rahul');
      e.setSecondOpener('Amit');
      e.setBowler('Bhuvi');

      e.recordWicket(creditBowler: false); // 1 down
      e.confirmNewBatsman('Vijay');
      e.recordWicket(creditBowler: false); // 2 down -> all out

      expect(e.state.isAllOut, isTrue, reason: 'precondition');

      final runsBefore = e.state.totalRuns;
      expect(() => e.recordRuns(6), returnsNormally);
      expect(e.state.totalRuns, runsBefore,
          reason: 'Innings is over — runs must not be credited');
    });

    test('recordRuns after overs are done must not add runs', () {
      final e = _engine(overs: 1); // only 6 legal balls
      e.setOpener('Rahul');
      e.setSecondOpener('Amit');
      e.setBowler('Bhuvi');
      for (var i = 0; i < 6; i++) {
        e.recordRuns(1);
        if (e.state.pendingNewBowler) e.setBowler('Bhuvi');
      }
      expect(e.state.isOversDone, isTrue, reason: 'precondition');

      final ballsBefore = e.state.legalBalls;
      expect(() => e.recordRuns(4), returnsNormally);
      expect(e.state.legalBalls, ballsBefore,
          reason: 'Over quota finished — no more legal balls');
    });

    test('recordWicket when already all out', () {
      final e = _engine(overs: 5, wickets: 1);
      e.setOpener('Rahul');
      e.setSecondOpener('Amit');
      e.setBowler('Bhuvi');
      e.recordWicket(creditBowler: false);
      expect(e.state.isAllOut, isTrue, reason: 'precondition');

      final w = e.state.wickets;
      expect(() => e.recordWicket(creditBowler: false), returnsNormally);
      expect(e.state.wickets, w,
          reason: 'Cannot lose more wickets than the team has');
    });
  });

  group('C. Illegal / out-of-range input', () {
    test('recordRuns(7) is not a legal cricket outcome', () {
      final e = _ready();
      final before = e.state.totalRuns;
      expect(() => e.recordRuns(7), returnsNormally);
      // A single delivery can only yield 0-6 off the bat.
      expect(e.state.totalRuns - before, lessThanOrEqualTo(6),
          reason: '7 off the bat is impossible; engine should clamp/reject');
    });

    test('recordRuns(-1) ignored', () {
      final e = _ready();
      final before = e.state.totalRuns;
      e.recordRuns(-1);
      expect(e.state.totalRuns, before);
    });

    test('setOpener with blank name ignored', () {
      final e = _engine();
      e.setOpener('   ');
      expect(e.state.striker, isEmpty);
    });

    test('same player as both openers is rejected', () {
      final e = _engine();
      e.setOpener('Rahul');
      e.setSecondOpener('Rahul');
      expect(e.state.nonStriker, isNot('Rahul'),
          reason: 'Batter cannot be at both ends');
    });

    test('dismissed batter / current non-striker cannot walk back in', () {
      final e = _ready(); // Rahul batting, Amit at the other end
      e.recordWicket(creditBowler: false); // Rahul is out

      expect(e.confirmNewBatsman('Rahul'), isFalse,
          reason: 'The batter who just got out must be rejected');
      expect(e.confirmNewBatsman('Amit'), isFalse,
          reason: 'The non-striker already at the crease must be rejected');
      expect(e.state.pendingNewBatsman, isTrue,
          reason: 'Engine must keep asking until a valid name is given');

      expect(e.confirmNewBatsman('Vijay'), isTrue,
          reason: 'A genuinely new batter must be accepted');
      expect(e.state.striker, 'Vijay');
      expect(e.state.pendingNewBatsman, isFalse);
      expect(e.state.nonStriker, 'Amit');
    });
  });

  group('D. Overs / extras book-keeping', () {
    test('wide on the last legal ball still lets the over end', () {
      final e = _engine(overs: 2);
      e.setOpener('Rahul');
      e.setSecondOpener('Amit');
      e.setBowler('Bhuvi');
      for (var i = 0; i < 5; i++) {
        e.recordRuns(1);
      }
      e.recordWide(); // ballsThisOver must still be 5
      expect(e.state.ballsThisOver, 5);
      e.recordRuns(1); // 6th legal ball
      expect(e.state.completedOvers, 1,
          reason: 'Wide must not consume one of the 6 legal balls');
    });

    test('bye runs are not charged to the bowler', () {
      final e = _ready();
      final concededBefore = e.state.bowlers['Bhuvi']!.runsConceded;
      e.recordBye(4);
      expect(e.state.bowlers['Bhuvi']!.runsConceded, concededBefore);
      expect(e.state.legalBalls, 1, reason: 'Byes are still a legal ball');
    });

    test('bowler economy/overs sanity after a mixed over', () {
      final e = _ready();
      e.recordRuns(4);
      e.recordWide();
      e.recordRuns(2);
      e.recordNoBall(batRuns: 1);
      expect(e.state.bowlers['Bhuvi']!.legalBalls, 2);
      expect(e.state.bowlers['Bhuvi']!.runsConceded, 4 + 1 + 2 + 2);
    });
  });

  group('E. Undo integrity', () {
    test('undo restores state after a wicket at the end of an over', () {
      final e = _engine(overs: 3);
      e.setOpener('Rahul');
      e.setSecondOpener('Amit');
      e.setBowler('Bhuvi');
      for (var i = 0; i < 5; i++) {
        e.recordRuns(1);
      }
      final before = e.state.totalRuns;
      e.recordWicket(creditBowler: true); // wicket on the 6th ball
      e.undo();
      expect(e.state.totalRuns, before);
      expect(e.state.wickets, 0);
      expect(e.state.legalBalls, 5,
          reason: 'Undo must roll back the whole delivery, not just runs');
    });

    test('undo does not resurrect a stale striker reference', () {
      final e = _ready();
      e.recordWicket(creditBowler: false);
      e.undo();
      expect(e.state.batsmen.containsKey(e.state.striker), isTrue);
    });
  });

  group('F. Innings-completion flags', () {
    test('target of exactly totalRuns+1 ends the chase', () {
      final e = _ready();
      e.setTarget(3);
      e.recordRuns(2);
      expect(e.state.isTargetChased, isFalse);
      e.recordRuns(1);
      expect(e.state.isTargetChased, isTrue);
    });

    test('totalOvers = 0 does not create an infinite/illegal innings', () {
      final e = _engine(overs: 0);
      e.setOpener('Rahul');
      e.setSecondOpener('Amit');
      e.setBowler('Bhuvi');
      expect(e.state.isOversDone, isTrue);
      expect(() => e.recordRuns(1), returnsNormally);
    });

    test('maxWickets = 0 is immediately all out', () {
      final e = _engine(wickets: 0);
      expect(e.state.isAllOut, isTrue);
    });
  });
}

ScoringEngine _ready() {
  final e = _engine(overs: 2);
  e.setOpener('Rahul');
  e.setSecondOpener('Amit');
  e.setBowler('Bhuvi');
  return e;
}
