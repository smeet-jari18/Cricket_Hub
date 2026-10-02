'use strict';

const test = require('node:test');
const assert = require('node:assert/strict');
const {
  buildCareerContributions,
  buildTournamentLeaders,
  calculateNRR,
  calculateStandings,
  deriveResult,
  effectiveBalls,
  generateKnockoutBracket,
  generateRoundRobinFixtures,
  mergeCareerStats,
  normalizePlayerName,
} = require('../domain');

const teams = [
  { id: 'a', name: 'Aces' },
  { id: 'b', name: 'Blazers' },
  { id: 'c', name: 'Comets' },
  { id: 'd', name: 'Dynamos' },
  { id: 'e', name: 'Eagles' },
];

test('round robin: every pair plays exactly once, including an odd-team bye', () => {
  const fixtures = generateRoundRobinFixtures(teams);
  assert.equal(fixtures.length, 10);
  assert.equal(new Set(fixtures.map((f) => [f.teamAId, f.teamBId].sort().join(':'))).size, 10);
  assert.equal(Math.max(...fixtures.map((f) => f.roundNumber)), 5);
  for (const team of teams) {
    const matchesByTeam = fixtures.filter((f) => f.teamAId === team.id || f.teamBId === team.id);
    assert.equal(matchesByTeam.length, 4);
  }
});

test('knockout: pads to a power-of-two bracket and automatically resolves byes', () => {
  const bracket = generateKnockoutBracket(teams);
  assert.equal(bracket.totalRounds, 3);
  assert.equal(bracket.fixtures.length, 7);
  assert.equal(bracket.rounds[0].filter((f) => f.status === 'bye').length, 3);
  assert.equal(bracket.rounds[0].filter((f) => f.status === 'scheduled').length, 1);
  assert.equal(bracket.rounds[1].filter((f) => f.status === 'scheduled').length, 1);
  assert.ok(bracket.rounds[1].some((f) => f.status === 'awaiting_teams'));
  assert.equal(bracket.rounds[2][0].status, 'awaiting_teams');

  const largeBracket = generateKnockoutBracket(
    Array.from({ length: 33 }, (_, index) => ({ id: `team-${index + 1}`, name: `Team ${index + 1}` })),
  );
  assert.equal(largeBracket.rounds[0][0].roundName, 'Round of 64');
});

test('NRR follows ICC all-out overs rule and handles incomplete/zero-ball innings', () => {
  assert.equal(effectiveBalls({ legal_balls: 42, overs_limit: 10, all_out: true }), 60);
  assert.equal(effectiveBalls({ legal_balls: 42, overs_limit: 10, all_out: false }), 42);
  assert.equal(calculateNRR({ runsFor: 100, ballsFaced: 60, runsAgainst: 50, ballsBowled: 60 }), 5);
  assert.equal(calculateNRR({ runsFor: 0, ballsFaced: 0, runsAgainst: 0, ballsBowled: 0 }), 0);
});

test('result derives winner, margin, and tie from the two innings', () => {
  const match = {
    status: 'completed',
    innings: [
      { team_id: 'a', runs: 150, wickets: 8 },
      { team_id: 'b', runs: 151, wickets: 6, max_wickets: 10 },
    ],
  };
  assert.deepEqual(deriveResult(match), {
    type: 'win',
    winnerTeamId: 'b',
    text: 'b won by 4 wickets',
  });
  assert.equal(deriveResult({ ...match, innings: [match.innings[0], { ...match.innings[1], runs: 150 }] }).type, 'tie');
});

test('points table sorts by points then NRR and computes aggregate NRR', () => {
  const matches = [
    {
      status: 'completed', team_a_id: 'a', team_b_id: 'b',
      innings: [
        { team_id: 'a', runs: 120, legal_balls: 60, overs_limit: 10, all_out: false },
        { team_id: 'b', runs: 90, legal_balls: 60, overs_limit: 10, all_out: false },
      ],
    },
    {
      status: 'completed', team_a_id: 'c', team_b_id: 'a',
      innings: [
        { team_id: 'c', runs: 80, legal_balls: 60, overs_limit: 10, all_out: false },
        { team_id: 'a', runs: 81, legal_balls: 30, overs_limit: 10, all_out: false },
      ],
    },
  ];
  const table = calculateStandings(teams.slice(0, 3), matches);
  assert.equal(table[0].team_id, 'a');
  assert.equal(table[0].played, 2);
  assert.equal(table[0].won, 2);
  assert.equal(table[0].points, 4);
  assert.equal(table[0].nrr, 4.9);
  assert.equal(table[1].team_id, 'b');
});

test('career aggregation tracks batting, bowling, milestones and derived rates', () => {
  const match = {
    status: 'completed',
    innings: [
      {
        team_id: 'a', bowling_team_id: 'b',
        batting: [
          { player_uid: 'u1', name: 'Rahul', runs: 100, balls: 60, fours: 10, sixes: 3, out: false },
          { name: 'Amit', runs: 49, balls: 40, out: true },
        ],
        bowling: [
          { name: 'Bhuvi', wickets: 5, runs_conceded: 24, legal_balls: 36 },
        ],
      },
    ],
  };
  const contributions = buildCareerContributions(match);
  const rahul = contributions.find((p) => p.player_uid === 'u1');
  assert.equal(rahul.runs, 100);
  assert.equal(rahul.hundreds, 1);
  assert.equal(rahul.not_outs, 1);
  const merged = mergeCareerStats({}, rahul);
  assert.equal(merged.high_score, 100);
  assert.equal(merged.strike_rate, 166.67);
  const bhuvi = contributions.find((p) => p.display_name === 'Bhuvi');
  assert.equal(bhuvi.five_wicket_hauls, 1);
  assert.equal(mergeCareerStats({}, bhuvi).best_bowling, '5/24');
});

test('tournament leaders sort by runs and wickets and expose rates', () => {
  const leaders = buildTournamentLeaders([
    {
      status: 'completed',
      innings: [{
        team_id: 'a', team_name: 'Aces', bowling_team_id: 'b', bowling_team_name: 'Blazers',
        batting: [{ name: 'Rahul', runs: 70, balls: 45, fours: 8, sixes: 2 }],
        bowling: [{ name: 'Bhuvi', wickets: 3, runs_conceded: 20, legal_balls: 24 }],
      }],
    },
  ]);
  assert.equal(leaders.orange_cap[0].player_name, 'Rahul');
  assert.equal(leaders.orange_cap[0].strike_rate, 155.56);
  assert.equal(leaders.purple_cap[0].player_name, 'Bhuvi');
  assert.equal(leaders.purple_cap[0].economy, 5);
});

test('player-name normalization is stable across whitespace and casing', () => {
  assert.equal(normalizePlayerName('  RAHUL   Sharma '), 'rahul sharma');
});
