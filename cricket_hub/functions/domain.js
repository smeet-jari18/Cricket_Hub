'use strict';

const DEFAULT_POINTS = Object.freeze({ win: 2, tie: 1, loss: 0, no_result: 1 });

function normalizePlayerName(value) {
  return String(value || '')
    .normalize('NFKC')
    .trim()
    .replace(/\s+/g, ' ')
    .toLocaleLowerCase('en');
}

function safeNumber(value, fallback = 0) {
  const number = Number(value);
  return Number.isFinite(number) ? number : fallback;
}

function asTeam(team) {
  if (typeof team === 'string') return { id: team, name: team };
  return {
    id: String(team?.id || team?.team_id || ''),
    name: String(team?.name || team?.team_name || team?.id || ''),
  };
}

function assertUniqueTeams(teams) {
  if (!Array.isArray(teams) || teams.length < 2) {
    throw new Error('A tournament needs at least two teams.');
  }
  const ids = teams.map((team) => asTeam(team).id);
  if (ids.some((id) => !id) || new Set(ids).size !== ids.length) {
    throw new Error('Tournament teams must have unique, non-empty IDs.');
  }
}

/** Berger/circle-method single round-robin. Every pair plays exactly once. */
function generateRoundRobinFixtures(teamValues) {
  const teams = teamValues.map(asTeam);
  assertUniqueTeams(teams);

  const rotation = teams.slice();
  if (rotation.length % 2 === 1) rotation.push(null);
  const teamCount = rotation.length;
  const roundCount = teamCount - 1;
  const fixtures = [];

  for (let round = 0; round < roundCount; round += 1) {
    const firstFixtureIndex = fixtures.length;
    for (let i = 0; i < teamCount / 2; i += 1) {
      let teamA = rotation[i];
      let teamB = rotation[teamCount - 1 - i];
      if (!teamA || !teamB) continue; // Bye week; not a match.
      // Alternate home/away assignment without changing the pair schedule.
      if ((round + i) % 2 === 1) [teamA, teamB] = [teamB, teamA];
      fixtures.push({
        roundNumber: round + 1,
        fixtureNumber: fixtures.length - firstFixtureIndex + 1,
        teamAId: teamA.id,
        teamAName: teamA.name,
        teamBId: teamB.id,
        teamBName: teamB.name,
      });
    }
    const last = rotation.pop();
    rotation.splice(1, 0, last);
  }

  return fixtures;
}

function seededOrder(size) {
  let seeds = [1, 2];
  while (seeds.length < size) {
    const nextSize = seeds.length * 2;
    seeds = seeds.flatMap((seed) => [seed, nextSize + 1 - seed]);
  }
  return seeds;
}

function roundLabel(roundNumber, totalRounds) {
  const remaining = totalRounds - roundNumber;
  if (remaining === 0) return 'Final';
  if (remaining === 1) return 'Semi-final';
  if (remaining === 2) return 'Quarter-final';
  if (remaining >= 3) return `Round of ${2 ** (remaining + 1)}`;
  return `Round ${roundNumber}`;
}

/**
 * Builds a seeded single-elimination bracket. Empty seeds become byes and
 * propagate automatically; unresolved branches remain awaiting_teams.
 */
function generateKnockoutBracket(teamValues) {
  const teams = teamValues.map(asTeam);
  assertUniqueTeams(teams);

  let size = 1;
  while (size < teams.length) size *= 2;
  const totalRounds = Math.log2(size);
  const orderedTeams = seededOrder(size).map((seed) => teams[seed - 1] || null);
  const rounds = [];
  const allFixtures = [];

  for (let roundNumber = 1; roundNumber <= totalRounds; roundNumber += 1) {
    const matchCount = size / (2 ** roundNumber);
    const roundFixtures = [];
    for (let index = 0; index < matchCount; index += 1) {
      const id = `r${roundNumber}_m${index + 1}`;
      let teamA = null;
      let teamB = null;
      let status = 'awaiting_teams';
      let winner = null;

      if (roundNumber === 1) {
        teamA = orderedTeams[index * 2];
        teamB = orderedTeams[index * 2 + 1];
        if (teamA && teamB) status = 'scheduled';
        else if (teamA || teamB) {
          status = 'bye';
          winner = teamA || teamB;
        } else {
          status = 'empty';
        }
      } else {
        const previousRound = rounds[roundNumber - 2];
        const left = previousRound[index * 2];
        const right = previousRound[index * 2 + 1];
        teamA = left.status === 'bye'
          ? { id: left.winnerTeamId, name: left.winnerTeamName }
          : null;
        teamB = right.status === 'bye'
          ? { id: right.winnerTeamId, name: right.winnerTeamName }
          : null;
        const leftResolved = left.status === 'bye' || left.status === 'empty';
        const rightResolved = right.status === 'bye' || right.status === 'empty';
        if (leftResolved && rightResolved) {
          const winners = [teamA, teamB].filter(Boolean);
          if (winners.length === 2) status = 'scheduled';
          else if (winners.length === 1) {
            status = 'bye';
            winner = winners[0];
          } else status = 'empty';
        }
      }

      const fixture = {
        id,
        roundNumber,
        roundName: roundLabel(roundNumber, totalRounds),
        fixtureNumber: index + 1,
        status,
        teamAId: teamA?.id || null,
        teamAName: teamA?.name || null,
        teamBId: teamB?.id || null,
        teamBName: teamB?.name || null,
        winnerTeamId: winner?.id || null,
        winnerTeamName: winner?.name || null,
        isBye: status === 'bye',
        nextFixtureId: roundNumber < totalRounds
          ? `r${roundNumber + 1}_m${Math.floor(index / 2) + 1}`
          : null,
        winnerSlot: roundNumber < totalRounds
          ? (index % 2 === 0 ? 'team_a' : 'team_b')
          : null,
      };
      roundFixtures.push(fixture);
      allFixtures.push(fixture);
    }
    rounds.push(roundFixtures);
  }

  return { rounds, fixtures: allFixtures, totalRounds };
}

function effectiveBalls(innings) {
  const quota = Math.max(0, safeNumber(innings?.overs_limit ?? innings?.total_overs)) * 6;
  const legalBalls = Math.max(0, safeNumber(innings?.legal_balls));
  return innings?.all_out === true && quota > 0 ? quota : legalBalls;
}

function calculateNRR({ runsFor, ballsFaced, runsAgainst, ballsBowled }) {
  const faced = Math.max(0, safeNumber(ballsFaced));
  const bowled = Math.max(0, safeNumber(ballsBowled));
  if (faced === 0 || bowled === 0) return 0;
  const runRateFor = safeNumber(runsFor) * 6 / faced;
  const runRateAgainst = safeNumber(runsAgainst) * 6 / bowled;
  return runRateFor - runRateAgainst;
}

function deriveResult(match) {
  if (match?.status === 'abandoned' || match?.result_type === 'no_result') {
    return { type: 'no_result', winnerTeamId: null, text: 'No result' };
  }
  const innings = Array.isArray(match?.innings) ? match.innings : [];
  if (innings.length >= 2) {
    const first = innings[0] || {};
    const second = innings[1] || {};
    const firstTeam = String(first.team_id || '');
    const secondTeam = String(second.team_id || '');
    if (!firstTeam || !secondTeam || firstTeam === secondTeam) return null;
    const firstRuns = safeNumber(first.runs);
    const secondRuns = safeNumber(second.runs);
    if (firstRuns === secondRuns) {
      return { type: 'tie', winnerTeamId: null, text: 'Match tied' };
    }
    if (secondRuns > firstRuns) {
      const wicketsRemaining = Math.max(0, safeNumber(second.max_wickets, 10) - safeNumber(second.wickets));
      return {
        type: 'win',
        winnerTeamId: secondTeam,
        text: `${secondTeam} won by ${wicketsRemaining} wicket${wicketsRemaining === 1 ? '' : 's'}`,
      };
    }
    return {
      type: 'win',
      winnerTeamId: firstTeam,
      text: `${firstTeam} won by ${firstRuns - secondRuns} run${firstRuns - secondRuns === 1 ? '' : 's'}`,
    };
  }

  // Compatibility for manually finalized or older match documents.
  if (match?.winner_team_id) {
    return {
      type: match.result_type === 'tie' ? 'tie' : 'win',
      winnerTeamId: match.result_type === 'tie' ? null : String(match.winner_team_id),
      text: String(match.result_text || 'Match complete'),
    };
  }
  if (match?.result_type === 'tie') {
    return { type: 'tie', winnerTeamId: null, text: String(match.result_text || 'Match tied') };
  }
  return null;
}

function matchInningsForNRR(match) {
  const innings = Array.isArray(match?.innings) ? match.innings : [];
  if (innings.length < 2) return [];
  return innings.slice(0, 2).map((entry) => ({
    teamId: String(entry?.team_id || ''),
    runs: Math.max(0, safeNumber(entry?.runs)),
    balls: effectiveBalls(entry),
  }));
}

function calculateStandings(teamValues, matches, pointsConfig = {}) {
  const config = { ...DEFAULT_POINTS, ...(pointsConfig || {}) };
  const rows = new Map();
  for (const rawTeam of teamValues || []) {
    const team = asTeam(rawTeam);
    if (!team.id) continue;
    rows.set(team.id, {
      team_id: team.id,
      team_name: team.name,
      played: 0,
      won: 0,
      lost: 0,
      tied: 0,
      no_result: 0,
      points: 0,
      runs_for: 0,
      balls_faced: 0,
      runs_against: 0,
      balls_bowled: 0,
      nrr: 0,
      nrr_label: '0.000',
    });
  }

  for (const match of matches || []) {
    const teamA = String(match?.team_a_id || '');
    const teamB = String(match?.team_b_id || '');
    if (!rows.has(teamA) || !rows.has(teamB) || teamA === teamB) continue;
    const result = deriveResult(match);
    if (!result) continue;
    const a = rows.get(teamA);
    const b = rows.get(teamB);
    a.played += 1;
    b.played += 1;

    if (result.type === 'no_result') {
      a.no_result += 1;
      b.no_result += 1;
      a.points += safeNumber(config.no_result);
      b.points += safeNumber(config.no_result);
      continue;
    }
    if (result.type === 'tie') {
      a.tied += 1;
      b.tied += 1;
      a.points += safeNumber(config.tie);
      b.points += safeNumber(config.tie);
    } else if (result.winnerTeamId === teamA) {
      a.won += 1;
      b.lost += 1;
      a.points += safeNumber(config.win);
      b.points += safeNumber(config.loss);
    } else if (result.winnerTeamId === teamB) {
      b.won += 1;
      a.lost += 1;
      b.points += safeNumber(config.win);
      a.points += safeNumber(config.loss);
    }

    for (const innings of matchInningsForNRR(match)) {
      const batting = rows.get(innings.teamId);
      const bowling = rows.get(innings.teamId === teamA ? teamB : teamA);
      if (!batting || !bowling) continue;
      batting.runs_for += innings.runs;
      batting.balls_faced += innings.balls;
      bowling.runs_against += innings.runs;
      bowling.balls_bowled += innings.balls;
    }
  }

  for (const row of rows.values()) {
    row.nrr = calculateNRR({
      runsFor: row.runs_for,
      ballsFaced: row.balls_faced,
      runsAgainst: row.runs_against,
      ballsBowled: row.balls_bowled,
    });
    row.nrr = Number(row.nrr.toFixed(3));
    row.nrr_label = `${row.nrr > 0 ? '+' : ''}${row.nrr.toFixed(3)}`;
  }

  return [...rows.values()].sort((a, b) =>
    b.points - a.points || b.nrr - a.nrr || b.won - a.won || a.team_name.localeCompare(b.team_name));
}

function playerIdentity(row) {
  const uid = String(row?.player_uid || row?.player_id || '').trim();
  if (uid) return `uid:${uid}`;
  const name = normalizePlayerName(row?.name || row?.display_name);
  return name ? `name:${name}` : '';
}

function buildCareerContributions(match) {
  const players = new Map();
  const innings = Array.isArray(match?.innings) ? match.innings : [];
  const ensure = (row, teamId) => {
    const key = playerIdentity(row);
    if (!key) return null;
    if (!players.has(key)) {
      players.set(key, {
        key,
        player_uid: String(row.player_uid || row.player_id || ''),
        display_name: String(row.name || row.display_name || 'Player').trim(),
        matches_played: 1,
        batting_innings: 0,
        runs: 0,
        balls_faced: 0,
        dismissals: 0,
        not_outs: 0,
        fours: 0,
        sixes: 0,
        fifties: 0,
        hundreds: 0,
        high_score: 0,
        bowling_innings: 0,
        bowling_runs: 0,
        bowling_balls: 0,
        wickets: 0,
        five_wicket_hauls: 0,
        best_bowling_wickets: 0,
        best_bowling_runs: 0,
        team_ids: [],
      });
    }
    const contribution = players.get(key);
    if (teamId && !contribution.team_ids.includes(teamId)) contribution.team_ids.push(teamId);
    if (!contribution.player_uid && (row.player_uid || row.player_id)) {
      contribution.player_uid = String(row.player_uid || row.player_id);
    }
    return contribution;
  };

  for (const inning of innings) {
    const teamId = String(inning?.team_id || '');
    for (const batter of Array.isArray(inning?.batting) ? inning.batting : []) {
      const contribution = ensure(batter, teamId);
      if (!contribution) continue;
      const runs = Math.max(0, safeNumber(batter.runs));
      contribution.batting_innings += 1;
      contribution.runs += runs;
      contribution.balls_faced += Math.max(0, safeNumber(batter.balls));
      contribution.dismissals += batter.out === true ? 1 : 0;
      contribution.not_outs += batter.out === true ? 0 : 1;
      contribution.fours += Math.max(0, safeNumber(batter.fours));
      contribution.sixes += Math.max(0, safeNumber(batter.sixes));
      contribution.fifties += runs >= 50 && runs < 100 ? 1 : 0;
      contribution.hundreds += runs >= 100 ? 1 : 0;
      contribution.high_score = Math.max(contribution.high_score, runs);
    }
    for (const bowler of Array.isArray(inning?.bowling) ? inning.bowling : []) {
      const contribution = ensure(bowler, teamId ? String(inning?.bowling_team_id || '') : '');
      if (!contribution) continue;
      const wickets = Math.max(0, safeNumber(bowler.wickets));
      const runs = Math.max(0, safeNumber(bowler.runs_conceded));
      contribution.bowling_innings += 1;
      contribution.bowling_runs += runs;
      contribution.bowling_balls += Math.max(0, safeNumber(bowler.legal_balls));
      contribution.wickets += wickets;
      contribution.five_wicket_hauls += wickets >= 5 ? 1 : 0;
      if (wickets > contribution.best_bowling_wickets ||
          (wickets === contribution.best_bowling_wickets && runs < contribution.best_bowling_runs)) {
        contribution.best_bowling_wickets = wickets;
        contribution.best_bowling_runs = runs;
      }
    }
  }

  return [...players.values()];
}

function mergeCareerStats(current = {}, contribution = {}) {
  const keys = [
    'matches_played', 'batting_innings', 'runs', 'balls_faced', 'dismissals',
    'not_outs', 'fours', 'sixes', 'fifties', 'hundreds', 'bowling_innings',
    'bowling_runs', 'bowling_balls', 'wickets', 'five_wicket_hauls',
  ];
  const next = {};
  for (const key of keys) next[key] = safeNumber(current[key]) + safeNumber(contribution[key]);
  next.high_score = Math.max(safeNumber(current.high_score), safeNumber(contribution.high_score));
  const currentBestWickets = safeNumber(current.best_bowling_wickets);
  const currentBestRuns = safeNumber(current.best_bowling_runs, Number.MAX_SAFE_INTEGER);
  const addedBestWickets = safeNumber(contribution.best_bowling_wickets);
  const addedBestRuns = safeNumber(contribution.best_bowling_runs, Number.MAX_SAFE_INTEGER);
  const useAddedBest = addedBestWickets > currentBestWickets ||
    (addedBestWickets === currentBestWickets && addedBestWickets > 0 && addedBestRuns < currentBestRuns);
  next.best_bowling_wickets = useAddedBest ? addedBestWickets : currentBestWickets;
  next.best_bowling_runs = useAddedBest ? addedBestRuns : safeNumber(current.best_bowling_runs);
  next.batting_average = next.dismissals === 0 ? null : Number((next.runs / next.dismissals).toFixed(2));
  next.strike_rate = next.balls_faced === 0 ? 0 : Number((next.runs * 100 / next.balls_faced).toFixed(2));
  next.bowling_average = next.wickets === 0 ? null : Number((next.bowling_runs / next.wickets).toFixed(2));
  next.economy = next.bowling_balls === 0 ? 0 : Number((next.bowling_runs * 6 / next.bowling_balls).toFixed(2));
  next.best_bowling = next.best_bowling_wickets > 0
    ? `${next.best_bowling_wickets}/${next.best_bowling_runs}`
    : '—';
  return next;
}

function buildTournamentLeaders(matches, limit = 10) {
  const batters = new Map();
  const bowlers = new Map();
  for (const match of matches || []) {
    if (match?.status !== 'completed') continue;
    for (const inning of Array.isArray(match.innings) ? match.innings : []) {
      const teamId = String(inning?.team_id || '');
      const teamName = String(inning?.team_name || '');
      for (const row of Array.isArray(inning?.batting) ? inning.batting : []) {
        const key = playerIdentity(row);
        if (!key) continue;
        const entry = batters.get(key) || {
          player_id: String(row.player_uid || row.player_id || key),
          player_name: String(row.name || row.display_name || 'Player'),
          team_id: teamId,
          team_name: teamName,
          runs: 0,
          balls: 0,
          fours: 0,
          sixes: 0,
        };
        entry.runs += Math.max(0, safeNumber(row.runs));
        entry.balls += Math.max(0, safeNumber(row.balls));
        entry.fours += Math.max(0, safeNumber(row.fours));
        entry.sixes += Math.max(0, safeNumber(row.sixes));
        batters.set(key, entry);
      }
      const bowlingTeamId = String(inning?.bowling_team_id || '');
      const bowlingTeamName = String(inning?.bowling_team_name || '');
      for (const row of Array.isArray(inning?.bowling) ? inning.bowling : []) {
        const key = playerIdentity(row);
        if (!key) continue;
        const entry = bowlers.get(key) || {
          player_id: String(row.player_uid || row.player_id || key),
          player_name: String(row.name || row.display_name || 'Player'),
          team_id: bowlingTeamId,
          team_name: bowlingTeamName,
          wickets: 0,
          runs: 0,
          legal_balls: 0,
          five_wicket_hauls: 0,
        };
        const wickets = Math.max(0, safeNumber(row.wickets));
        entry.wickets += wickets;
        entry.runs += Math.max(0, safeNumber(row.runs_conceded));
        entry.legal_balls += Math.max(0, safeNumber(row.legal_balls));
        entry.five_wicket_hauls += wickets >= 5 ? 1 : 0;
        bowlers.set(key, entry);
      }
    }
  }

  const orangeCap = [...batters.values()]
    .map((entry) => ({
      ...entry,
      strike_rate: entry.balls === 0 ? 0 : Number((entry.runs * 100 / entry.balls).toFixed(2)),
    }))
    .sort((a, b) => b.runs - a.runs || b.strike_rate - a.strike_rate || a.player_name.localeCompare(b.player_name))
    .slice(0, limit);
  const purpleCap = [...bowlers.values()]
    .map((entry) => ({
      ...entry,
      economy: entry.legal_balls === 0 ? 0 : Number((entry.runs * 6 / entry.legal_balls).toFixed(2)),
    }))
    .sort((a, b) => b.wickets - a.wickets || a.economy - b.economy || a.player_name.localeCompare(b.player_name))
    .slice(0, limit);
  return { orange_cap: orangeCap, purple_cap: purpleCap };
}

module.exports = {
  DEFAULT_POINTS,
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
};
