'use strict';

const crypto = require('node:crypto');
const { initializeApp } = require('firebase-admin/app');
const { FieldValue, getFirestore } = require('firebase-admin/firestore');
const { getMessaging } = require('firebase-admin/messaging');
const { logger } = require('firebase-functions');
const { setGlobalOptions } = require('firebase-functions/v2');
const { HttpsError, onCall } = require('firebase-functions/v2/https');
const { onDocumentCreated, onDocumentUpdated, onDocumentWritten } = require('firebase-functions/v2/firestore');
const {
  DEFAULT_POINTS,
  buildCareerContributions,
  buildTournamentLeaders,
  calculateStandings,
  deriveResult,
  generateKnockoutBracket,
  generateRoundRobinFixtures,
  mergeCareerStats,
  normalizePlayerName,
} = require('./domain');

const REGION = 'asia-south1';
setGlobalOptions({ region: REGION, maxInstances: 20 });
initializeApp();
const db = getFirestore();

function requireUid(request) {
  const uid = request.auth?.uid;
  if (!uid) throw new HttpsError('unauthenticated', 'Sign in to manage tournaments.');
  return uid;
}

function toDate(value) {
  if (!value) return null;
  if (typeof value.toDate === 'function') return value.toDate();
  if (value instanceof Date) return value;
  const parsed = new Date(value);
  return Number.isNaN(parsed.getTime()) ? null : parsed;
}

function scheduledDate(startValue, roundNumber) {
  const base = toDate(startValue) || new Date();
  const date = new Date(base.getTime());
  date.setUTCDate(date.getUTCDate() + Math.max(0, roundNumber - 1));
  return date;
}

function sanitizePoints(value, fallback) {
  const number = Number(value);
  return Number.isInteger(number) && number >= 0 && number <= 20 ? number : fallback;
}

function mapTeamSnapshots(tournament, snapshots) {
  const byId = new Map(snapshots.filter((doc) => doc.exists).map((doc) => [doc.id, doc.data()]));
  return (tournament.team_ids || []).map((id) => {
    const data = byId.get(id);
    if (!data) return null;
    return { id, name: String(data.team_name || 'Team'), city: String(data.city || '') };
  }).filter(Boolean);
}

function fixtureDocument({ tournamentId, tournament, fixture, format, adminName }) {
  const fixtureId = fixture.id;
  const plannedMatchId = `${tournamentId}_${fixtureId}`;
  const isScheduled = fixture.status === 'scheduled';
  const scheduledAt = scheduledDate(tournament.start_at, fixture.roundNumber);
  const teamAId = fixture.teamAId || null;
  const teamBId = fixture.teamBId || null;
  const teamAName = fixture.teamAName || null;
  const teamBName = fixture.teamBName || null;
  const fixtureData = {
    fixture_id: fixtureId,
    tournament_id: tournamentId,
    format,
    round_number: fixture.roundNumber,
    round_name: fixture.roundName || `Round ${fixture.roundNumber}`,
    fixture_number: fixture.fixtureNumber,
    status: fixture.status,
    is_bye: fixture.status === 'bye',
    team_a_id: teamAId,
    team_a_name: teamAName,
    team_b_id: teamBId,
    team_b_name: teamBName,
    winner_team_id: fixture.winnerTeamId || null,
    winner_team_name: fixture.winnerTeamName || null,
    result_text: fixture.status === 'bye' ? `${fixture.winnerTeamName || 'Team'} advances with a bye` : '',
    match_id: isScheduled ? plannedMatchId : '',
    planned_match_id: plannedMatchId,
    next_fixture_id: fixture.nextFixtureId || null,
    winner_slot: fixture.winnerSlot || null,
    scheduled_at: scheduledAt,
    total_overs: Number(tournament.total_overs || 20),
    tournament_admin_uid: tournament.admin_uid,
    tournament_admin_name: adminName,
    created_at: FieldValue.serverTimestamp(),
  };

  const matchData = isScheduled
    ? matchDocumentFromFixture(tournamentId, fixtureId, fixtureData)
    : null;
  return { fixtureData, matchData, plannedMatchId };
}

function matchDocumentFromFixture(tournamentId, fixtureId, fixture) {
  return {
    status: 'scheduled',
    team_a_id: fixture.team_a_id,
    team_b_id: fixture.team_b_id,
    team_a_name: fixture.team_a_name,
    team_b_name: fixture.team_b_name,
    total_overs: Number(fixture.total_overs || 20),
    scorer_uid: fixture.tournament_admin_uid,
    scorer_name: fixture.tournament_admin_name || '',
    tournament_admin_uid: fixture.tournament_admin_uid,
    tournament_id: tournamentId,
    fixture_id: fixtureId,
    stage: fixture.format === 'knockout' ? 'knockout' : 'league',
    round_number: Number(fixture.round_number || 1),
    fixture_number: Number(fixture.fixture_number || 1),
    scheduled_at: fixture.scheduled_at,
    toss_winner: '',
    elected_to: '',
    batting_team_id: '',
    bowling_team_id: '',
    current_batting_team_id: '',
    current_innings_number: 1,
    current_runs: 0,
    current_wickets: 0,
    legal_balls: 0,
    innings: [],
    created_at: FieldValue.serverTimestamp(),
  };
}

async function commitOperations(operations) {
  for (let offset = 0; offset < operations.length; offset += 400) {
    const batch = db.batch();
    for (const operation of operations.slice(offset, offset + 400)) {
      batch.set(operation.ref, operation.data, operation.options || {});
    }
    await batch.commit();
  }
}

exports.generateTournamentFixtures = onCall({ enforceAppCheck: false }, async (request) => {
  const uid = requireUid(request);
  const tournamentId = String(request.data?.tournamentId || '').trim();
  if (!tournamentId) throw new HttpsError('invalid-argument', 'Tournament ID is required.');
  const tournamentRef = db.collection('tournaments').doc(tournamentId);

  const generation = await db.runTransaction(async (transaction) => {
    const snapshot = await transaction.get(tournamentRef);
    if (!snapshot.exists) throw new HttpsError('not-found', 'Tournament not found.');
    const tournament = snapshot.data();
    if (tournament.admin_uid !== uid) {
      throw new HttpsError('permission-denied', 'Only the tournament organizer can generate fixtures.');
    }
    if (tournament.fixture_generation_status === 'generated') {
      return { alreadyGenerated: true, fixtureCount: tournament.fixture_count || 0 };
    }
    if (tournament.fixture_generation_status === 'generating') {
      throw new HttpsError('aborted', 'Fixture generation is already in progress. Try again shortly.');
    }
    if (!['round_robin', 'knockout'].includes(tournament.format)) {
      throw new HttpsError('failed-precondition', 'Choose a supported tournament format.');
    }
    const teamIds = Array.isArray(tournament.team_ids) ? tournament.team_ids : [];
    const maximum = tournament.format === 'round_robin' ? 20 : 64;
    if (teamIds.length < 2 || teamIds.length > maximum || new Set(teamIds).size !== teamIds.length) {
      throw new HttpsError('failed-precondition', `Add 2–${maximum} unique teams before generating fixtures.`);
    }
    transaction.update(tournamentRef, {
      fixture_generation_status: 'generating',
      fixture_generation_error: FieldValue.delete(),
      updated_at: FieldValue.serverTimestamp(),
    });
    return { alreadyGenerated: false, tournament };
  });

  if (generation.alreadyGenerated) {
    return { alreadyGenerated: true, fixtureCount: generation.fixtureCount };
  }

  const tournament = generation.tournament;
  try {
    const teamIds = tournament.team_ids;
    const teamDocs = await db.getAll(...teamIds.map((id) => db.collection('teams').doc(id)));
    const teams = mapTeamSnapshots(tournament, teamDocs);
    if (teams.length !== teamIds.length) {
      throw new HttpsError('failed-precondition', 'One or more selected teams no longer exist.');
    }
    const adminDoc = await db.collection('users').doc(uid).get();
    const adminName = String(adminDoc.data()?.display_name || '');
    const rawFormat = tournament.format;
    let fixtures;
    let roundCount;
    if (rawFormat === 'round_robin') {
      const generated = generateRoundRobinFixtures(teams);
      roundCount = generated.reduce((max, fixture) => Math.max(max, fixture.roundNumber), 0);
      fixtures = generated.map((fixture) => ({
        ...fixture,
        id: `r${fixture.roundNumber}_m${fixture.fixtureNumber}`,
        roundName: `Round ${fixture.roundNumber}`,
        status: 'scheduled',
        nextFixtureId: null,
        winnerSlot: null,
      }));
    } else {
      const generated = generateKnockoutBracket(teams);
      fixtures = generated.fixtures;
      roundCount = generated.totalRounds;
    }

    const normalizedPoints = {
      win: sanitizePoints(tournament.points_config?.win, DEFAULT_POINTS.win),
      tie: sanitizePoints(tournament.points_config?.tie, DEFAULT_POINTS.tie),
      loss: sanitizePoints(tournament.points_config?.loss, DEFAULT_POINTS.loss),
      no_result: sanitizePoints(tournament.points_config?.no_result, DEFAULT_POINTS.no_result),
    };
    const operations = [];
    let playableFixtureCount = 0;
    for (const fixture of fixtures) {
      if (fixture.status === 'scheduled' || fixture.status === 'awaiting_teams') {
        playableFixtureCount += 1;
      }
      const built = fixtureDocument({
        tournamentId,
        tournament: { ...tournament, teams },
        fixture,
        format: rawFormat,
        adminName,
      });
      const fixtureRef = tournamentRef.collection('fixtures').doc(fixture.id);
      operations.push({ ref: fixtureRef, data: built.fixtureData });
      if (built.matchData) {
        operations.push({
          ref: db.collection('matches').doc(built.plannedMatchId),
          data: built.matchData,
        });
      }
    }
    await commitOperations(operations);

    const pointsTable = calculateStandings(teams, [], normalizedPoints);
    await db.runTransaction(async (transaction) => {
      const latest = await transaction.get(tournamentRef);
      if (!latest.exists || latest.data().fixture_generation_status !== 'generating') {
        throw new HttpsError('aborted', 'Tournament generation state changed.');
      }
      transaction.update(tournamentRef, {
        teams,
        points_config: normalizedPoints,
        points_table: pointsTable,
        fixture_generation_status: 'generated',
        fixture_generation_error: FieldValue.delete(),
        fixture_count: playableFixtureCount,
        round_count: roundCount,
        status: 'upcoming',
        updated_at: FieldValue.serverTimestamp(),
      });
    });

    return {
      alreadyGenerated: false,
      fixtureCount: playableFixtureCount,
      roundCount,
    };
  } catch (error) {
    logger.error('Fixture generation failed', { tournamentId, error });
    try {
      await tournamentRef.update({
        fixture_generation_status: 'failed',
        fixture_generation_error: String(error.message || 'Generation failed').slice(0, 200),
        updated_at: FieldValue.serverTimestamp(),
      });
    } catch (stateError) {
      logger.error('Could not store fixture-generation failure state', stateError);
    }
    if (error instanceof HttpsError) throw error;
    throw new HttpsError('internal', 'Could not generate the fixture schedule. Try again.');
  }
});

function matchResultForTournament(match) {
  if (match.status === 'abandoned') {
    return { type: 'no_result', winnerTeamId: null, text: 'No result' };
  }
  return deriveResult(match);
}

async function markFixtureResult(tournamentId, match, result) {
  if (!match.fixture_id) return;
  const fixtureRef = db
    .collection('tournaments')
    .doc(tournamentId)
    .collection('fixtures')
    .doc(match.fixture_id);
  const status = result.type === 'win' || result.type === 'tie' || result.type === 'no_result'
    ? 'completed'
    : 'needs_tiebreak';
  await fixtureRef.set({
    status,
    winner_team_id: result.winnerTeamId || null,
    result_type: result.type,
    result_text: match.result_text || result.text,
    completed_at: FieldValue.serverTimestamp(),
  }, { merge: true });
}

async function advanceKnockoutWinner(tournamentId, fixtureId, winnerTeamId, resultText) {
  const tournamentRef = db.collection('tournaments').doc(tournamentId);
  const fixtureRef = tournamentRef.collection('fixtures').doc(fixtureId);
  await db.runTransaction(async (transaction) => {
    const fixtureSnapshot = await transaction.get(fixtureRef);
    if (!fixtureSnapshot.exists) return;
    const fixture = fixtureSnapshot.data();
    if (fixture.status === 'completed' && fixture.winner_team_id === winnerTeamId) return;
    const candidateIds = [fixture.team_a_id, fixture.team_b_id].filter(Boolean);
    if (!candidateIds.includes(winnerTeamId)) {
      throw new HttpsError('failed-precondition', 'Winner must be one of the teams in this fixture.');
    }
    const winnerName = winnerTeamId === fixture.team_a_id
      ? fixture.team_a_name
      : fixture.team_b_name;

    let nextRef = null;
    let nextSnapshot = null;
    let nextFixture = null;
    let nextMatchRef = null;
    let nextMatchSnapshot = null;
    let updatedNext = null;
    let createNextMatch = false;

    if (fixture.next_fixture_id) {
      nextRef = tournamentRef.collection('fixtures').doc(fixture.next_fixture_id);
      nextSnapshot = await transaction.get(nextRef);
      if (nextSnapshot.exists) {
        nextFixture = nextSnapshot.data();
        const slot = fixture.winner_slot === 'team_b' ? 'team_b' : 'team_a';
        const winnerKey = `${slot}_id`;
        const nameKey = `${slot}_name`;
        const existingId = nextFixture[winnerKey];
        if (existingId && existingId !== winnerTeamId) {
          throw new HttpsError('already-exists', 'A different team already occupies this bracket slot.');
        }
        updatedNext = {
          ...nextFixture,
          [winnerKey]: winnerTeamId,
          [nameKey]: winnerName,
        };
        const hasBothTeams = Boolean(updatedNext.team_a_id && updatedNext.team_b_id);
        const unresolved = updatedNext.status === 'awaiting_teams';
        createNextMatch = hasBothTeams && unresolved;
        if (createNextMatch) {
          const nextMatchId = String(updatedNext.planned_match_id || `${tournamentId}_${fixture.next_fixture_id}`);
          nextMatchRef = db.collection('matches').doc(nextMatchId);
          nextMatchSnapshot = await transaction.get(nextMatchRef);
          updatedNext.match_id = nextMatchId;
          updatedNext.status = 'scheduled';
        }
      }
    }

    transaction.update(fixtureRef, {
      status: 'completed',
      winner_team_id: winnerTeamId,
      winner_team_name: winnerName,
      result_text: resultText || `${winnerName} advances`,
      completed_at: FieldValue.serverTimestamp(),
    });
    if (nextRef && updatedNext) {
      transaction.update(nextRef, {
        team_a_id: updatedNext.team_a_id || null,
        team_a_name: updatedNext.team_a_name || null,
        team_b_id: updatedNext.team_b_id || null,
        team_b_name: updatedNext.team_b_name || null,
        status: updatedNext.status,
        match_id: updatedNext.match_id || '',
        updated_at: FieldValue.serverTimestamp(),
      });
      if (createNextMatch && nextMatchRef && !nextMatchSnapshot?.exists) {
        transaction.create(
          nextMatchRef,
          matchDocumentFromFixture(tournamentId, fixture.next_fixture_id, updatedNext),
        );
      }
    }
  });
}

async function refreshTournament(tournamentId) {
  const tournamentRef = db.collection('tournaments').doc(tournamentId);
  const tournamentSnapshot = await tournamentRef.get();
  if (!tournamentSnapshot.exists) return;
  const tournament = tournamentSnapshot.data();
  const [matchSnapshot, fixtureSnapshot] = await Promise.all([
    db.collection('matches').where('tournament_id', '==', tournamentId).get(),
    tournamentRef.collection('fixtures').get(),
  ]);
  const matches = matchSnapshot.docs.map((doc) => ({ id: doc.id, ...doc.data() }));
  const fixtures = fixtureSnapshot.docs.map((doc) => ({ id: doc.id, ...doc.data() }));
  const teams = Array.isArray(tournament.teams) ? tournament.teams : [];
  const pointsConfig = { ...DEFAULT_POINTS, ...(tournament.points_config || {}) };
  const standings = calculateStandings(teams, matches, pointsConfig);
  const leaders = buildTournamentLeaders(matches);
  const hasLiveMatch = matches.some((match) => match.status === 'live');
  let completed = false;
  if (tournament.format === 'round_robin') {
    completed = fixtures.length > 0 && fixtures.every((fixture) => fixture.status === 'completed');
  } else if (tournament.format === 'knockout' && tournament.round_count > 0) {
    const finalFixture = fixtures.find((fixture) => fixture.id === `r${tournament.round_count}_m1`);
    completed = finalFixture?.status === 'completed' && Boolean(finalFixture.winner_team_id);
  }
  const status = completed ? 'completed' : hasLiveMatch ? 'ongoing' : 'upcoming';
  await tournamentRef.update({
    points_table: standings,
    leaderboards: leaders,
    status,
    stats_updated_at: FieldValue.serverTimestamp(),
  });
}

function stablePlayerDocId(key) {
  return crypto.createHash('sha256').update(key).digest('hex').slice(0, 40);
}

async function resolveUserUid(contribution) {
  if (contribution.player_uid) {
    const user = await db.collection('users').doc(contribution.player_uid).get();
    if (user.exists) return contribution.player_uid;
  }
  const nameKey = normalizePlayerName(contribution.display_name);
  if (!nameKey) return null;
  const matches = await db.collection('users')
    .where('player_name_key', '==', nameKey)
    .limit(2)
    .get();
  return matches.size === 1 ? matches.docs[0].id : null;
}

function recentMatchEntry(match, contribution) {
  const teamIds = Array.isArray(contribution.team_ids) ? contribution.team_ids : [];
  const opponentId = [match.team_a_id, match.team_b_id].find((id) => !teamIds.includes(id));
  const opponent = opponentId === match.team_a_id
    ? match.team_a_name
    : opponentId === match.team_b_id
        ? match.team_b_name
        : 'Match';
  let result = 'Played';
  if (match.result_type === 'tie') result = 'Tied';
  else if (match.result_type === 'no_result' || match.status === 'abandoned') result = 'No result';
  else if (match.winner_team_id) result = teamIds.includes(match.winner_team_id) ? 'Won' : 'Lost';
  return {
    match_id: String(match.id || ''),
    opponent: String(opponent || 'Match'),
    runs: contribution.runs,
    wickets: contribution.wickets,
    result,
    played_at: toDate(match.completed_at)?.toISOString() || new Date().toISOString(),
  };
}

function mergeContributionsByLinkedUid(contributions, linkedUids) {
  const combined = new Map();
  contributions.forEach((contribution, index) => {
    const uid = linkedUids[index];
    const key = uid ? `uid:${uid}` : contribution.key;
    if (!combined.has(key)) {
      combined.set(key, { ...contribution, player_uid: uid || contribution.player_uid || '' });
      return;
    }
    const current = combined.get(key);
    for (const field of [
      'batting_innings', 'runs', 'balls_faced', 'dismissals', 'not_outs', 'fours', 'sixes',
      'fifties', 'hundreds', 'bowling_innings', 'bowling_runs', 'bowling_balls', 'wickets',
      'five_wicket_hauls',
    ]) current[field] = Number(current[field] || 0) + Number(contribution[field] || 0);
    current.high_score = Math.max(Number(current.high_score || 0), Number(contribution.high_score || 0));
    if (Number(contribution.best_bowling_wickets || 0) > Number(current.best_bowling_wickets || 0) ||
        (Number(contribution.best_bowling_wickets || 0) === Number(current.best_bowling_wickets || 0) &&
         Number(contribution.best_bowling_runs || 0) < Number(current.best_bowling_runs || 0))) {
      current.best_bowling_wickets = contribution.best_bowling_wickets;
      current.best_bowling_runs = contribution.best_bowling_runs;
    }
    current.team_ids = [...new Set([...(current.team_ids || []), ...(contribution.team_ids || [])])];
  });
  return [...combined.entries()];
}

async function aggregateCareerStats(matchRef, match) {
  if (match.stats_aggregated) return;
  const contributions = buildCareerContributions(match);
  if (contributions.length === 0) {
    await matchRef.update({
      stats_aggregated: true,
      stats_aggregation_version: 1,
      stats_aggregated_at: FieldValue.serverTimestamp(),
    });
    return;
  }
  const linkedUids = await Promise.all(contributions.map(resolveUserUid));
  const combined = mergeContributionsByLinkedUid(contributions, linkedUids);
  const playerRefs = combined.map(([key]) => db.collection('player_stats').doc(stablePlayerDocId(key)));
  const uidByKey = new Map(combined.map(([key, contribution]) => [key, contribution.player_uid || '']));
  const userRefsByKey = new Map();
  for (const [key, contribution] of combined) {
    const uid = uidByKey.get(key);
    if (uid) userRefsByKey.set(key, db.collection('users').doc(uid));
  }

  await db.runTransaction(async (transaction) => {
    const latestMatch = await transaction.get(matchRef);
    if (!latestMatch.exists || latestMatch.data().stats_aggregated) return;
    if (latestMatch.data().status !== 'completed') return;

    const refsByKey = new Map();
    for (let i = 0; i < combined.length; i += 1) {
      const [key] = combined[i];
      const refs = [playerRefs[i]];
      if (userRefsByKey.has(key)) refs.push(userRefsByKey.get(key));
      refsByKey.set(key, refs);
    }
    const previousByPath = new Map();
    for (const refs of refsByKey.values()) {
      for (const ref of refs) {
        const snapshot = await transaction.get(ref);
        previousByPath.set(ref.path, snapshot.exists ? snapshot.data() : {});
      }
    }

    for (const [key, contribution] of combined) {
      const recentEntry = recentMatchEntry(match, contribution);
      const refs = refsByKey.get(key);
      for (const ref of refs) {
        const previousDocument = previousByPath.get(ref.path) || {};
        const previousStats = ref.parent.id === 'users'
          ? previousDocument.career_stats || {}
          : previousDocument.career_stats || previousDocument;
        const merged = mergeCareerStats(previousStats, contribution);
        const priorRecent = Array.isArray(previousDocument.recent_matches)
          ? previousDocument.recent_matches
          : Array.isArray(previousStats.recent_matches)
              ? previousStats.recent_matches
              : [];
        const recent = [recentEntry, ...priorRecent]
          .filter((entry, index, array) => array.findIndex((candidate) => candidate.match_id === entry.match_id) === index)
          .sort((a, b) => Date.parse(b.played_at || '') - Date.parse(a.played_at || ''))
          .slice(0, 5);
        const careerStats = { ...merged, recent_matches: recent };
        if (ref.parent.id === 'users') {
          transaction.set(ref, {
            career_stats: careerStats,
            career_stats_updated_at: FieldValue.serverTimestamp(),
          }, { merge: true });
        } else {
          transaction.set(ref, {
            player_key: key,
            player_uid: contribution.player_uid || null,
            display_name: contribution.display_name,
            team_ids: contribution.team_ids || [],
            career_stats: careerStats,
            recent_matches: recent,
            updated_at: FieldValue.serverTimestamp(),
          }, { merge: true });
        }
      }
    }
    transaction.update(matchRef, {
      stats_aggregated: true,
      stats_aggregation_version: 1,
      stats_aggregated_at: FieldValue.serverTimestamp(),
    });
  });
}

exports.processCompletedMatch = onDocumentUpdated(
  { document: 'matches/{matchId}', retry: true },
  async (event) => {
    const before = event.data?.before.data();
    const after = event.data?.after.data();
    if (!before || !after) return;
    const becameFinal = ['completed', 'abandoned'].includes(after.status) && before.status !== after.status;
    if (!becameFinal) return;

    const matchId = event.params.matchId;
    const match = { id: matchId, ...after };
    const result = matchResultForTournament(match);
    const tournamentId = String(match.tournament_id || '');
    if (tournamentId) {
      const tournamentSnapshot = await db.collection('tournaments').doc(tournamentId).get();
      if (tournamentSnapshot.exists) {
        const tournament = tournamentSnapshot.data();
        if (tournament.format === 'knockout' && result?.type !== 'win') {
          if (match.fixture_id) {
            const fixtureRef = db.collection('tournaments').doc(tournamentId)
              .collection('fixtures').doc(match.fixture_id);
            await fixtureRef.set({
              status: 'needs_tiebreak',
              winner_team_id: null,
              result_type: result?.type || 'incomplete',
              result_text: result?.type === 'tie'
                ? 'Match tied — organizer decision required'
                : 'No result — organizer decision required',
              completed_at: FieldValue.serverTimestamp(),
            }, { merge: true });
          }
        } else if (tournament.format === 'knockout' && result?.winnerTeamId && match.fixture_id) {
          await advanceKnockoutWinner(
            tournamentId,
            match.fixture_id,
            result.winnerTeamId,
            match.result_text || result.text,
          );
        } else if (match.fixture_id && result) {
          await markFixtureResult(tournamentId, match, result);
        }
        await refreshTournament(tournamentId);
      }
    }

    if (after.status === 'completed' && Array.isArray(after.innings) && after.innings.length >= 2) {
      await aggregateCareerStats(db.collection('matches').doc(matchId), match);
    } else if (after.status === 'completed') {
      logger.warn('Career stats skipped: a completed match needs two innings.', { matchId });
    }
  },
);

exports.onMatchStarted = onDocumentUpdated(
  { document: 'matches/{matchId}' },
  async (event) => {
    const before = event.data?.before.data();
    const after = event.data?.after.data();
    if (!before || !after || before.status === 'live' || after.status !== 'live') return;
    const matchId = event.params.matchId;
    if (after.tournament_id) {
      await db.collection('tournaments').doc(after.tournament_id).update({
        status: 'ongoing',
        updated_at: FieldValue.serverTimestamp(),
      }).catch((error) => logger.warn('Could not mark tournament ongoing', { error, matchId }));
    }
    await sendMatchTopicNotification(
      matchId,
      `${after.team_a_name || 'Team A'} vs ${after.team_b_name || 'Team B'}`,
      'A new local match has started. Follow the live score now.',
      'match_start',
    );
  },
);

exports.onWicketScored = onDocumentWritten(
  { document: 'matches/{matchId}/balls/{ballId}', retry: true },
  async (event) => {
    const before = event.data?.before.exists ? event.data.before.data() : null;
    const after = event.data?.after.exists ? event.data.after.data() : null;
    const wicket = after?.wicket;
    if (!wicket || typeof wicket !== 'object' || !wicket.type) return;
    const previousWicket = before?.wicket;
    if (previousWicket && previousWicket.type) return;

    const matchId = event.params.matchId;
    const matchSnapshot = await db.collection('matches').doc(matchId).get();
    if (!matchSnapshot.exists) return;
    const match = matchSnapshot.data();
    const playerOut = String(wicket.player_out || 'A batter');
    const inningsNumber = Number(after.innings_number || 1);
    await sendMatchTopicNotification(
      matchId,
      `Wicket! ${playerOut} is out`,
      `${match.team_a_name || 'Team A'} vs ${match.team_b_name || 'Team B'} · Innings ${inningsNumber}`,
      'wicket',
    );
  },
);

async function sendMatchTopicNotification(matchId, title, body, type) {
  try {
    const topic = `match_${String(matchId).replace(/[^A-Za-z0-9_-]/g, '_')}`;
    await getMessaging().send({
      topic,
      notification: { title, body },
      data: { type, matchId: String(matchId) },
      android: {
        priority: 'high',
        notification: {
          channelId: 'crickethub_match_alerts',
          sound: 'default',
        },
      },
      apns: {
        payload: {
          aps: { sound: 'default' },
        },
      },
    });
  } catch (error) {
    // No followers is not a match-scoring failure; keep event retries safe.
    logger.warn('Could not send match notification', { matchId, type, error });
  }
}

exports.resolveKnockoutTie = onCall({ enforceAppCheck: false }, async (request) => {
  const uid = requireUid(request);
  const tournamentId = String(request.data?.tournamentId || '').trim();
  const fixtureId = String(request.data?.fixtureId || '').trim();
  const winnerTeamId = String(request.data?.winnerTeamId || '').trim();
  if (!tournamentId || !fixtureId || !winnerTeamId) {
    throw new HttpsError('invalid-argument', 'Tournament, fixture and winner are required.');
  }
  const tournamentSnapshot = await db.collection('tournaments').doc(tournamentId).get();
  if (!tournamentSnapshot.exists) throw new HttpsError('not-found', 'Tournament not found.');
  const tournament = tournamentSnapshot.data();
  if (tournament.admin_uid !== uid) {
    throw new HttpsError('permission-denied', 'Only the organizer can resolve a tied fixture.');
  }
  if (tournament.format !== 'knockout') {
    throw new HttpsError('failed-precondition', 'Tie resolution is only used for knockout fixtures.');
  }
  const fixtureRef = db.collection('tournaments').doc(tournamentId)
    .collection('fixtures').doc(fixtureId);
  const fixtureSnapshot = await fixtureRef.get();
  if (!fixtureSnapshot.exists || fixtureSnapshot.data().status !== 'needs_tiebreak') {
    throw new HttpsError('failed-precondition', 'This fixture is not waiting for a tie decision.');
  }
  const fixture = fixtureSnapshot.data();
  if (![fixture.team_a_id, fixture.team_b_id].includes(winnerTeamId)) {
    throw new HttpsError('invalid-argument', 'Select one of the teams in the tied fixture.');
  }
  const winnerName = winnerTeamId === fixture.team_a_id ? fixture.team_a_name : fixture.team_b_name;
  await advanceKnockoutWinner(
    tournamentId,
    fixtureId,
    winnerTeamId,
    `${winnerName || 'Team'} advances by organizer decision`,
  );
  await refreshTournament(tournamentId);
  return { resolved: true, winnerTeamId };
});
