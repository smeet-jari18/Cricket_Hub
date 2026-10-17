/**
 * CricketHub Firestore rules — verification suite.
 *
 * Runs against the Firestore emulator with the REAL firestore.rules loaded,
 * using the real client SDK. Every assertion below is a genuine request going
 * through the rule engine, so a PASS here means `firebase deploy` will not
 * leave you with PERMISSION_DENIED surprises.
 *
 *   firebase emulators:exec --only firestore "node rules.test.js"
 */
const fs = require('fs');
const path = require('path');
const {
  initializeTestEnvironment,
  assertSucceeds,
  assertFails,
} = require('@firebase/rules-unit-testing');
const {
  doc,
  getDoc,
  setDoc,
  updateDoc,
  deleteDoc,
  collection,
  getDocs,
  query,
  where,
} = require('firebase/firestore');

const PROJECT_ID = 'demo-crickethub';
const OWNER = 'uid_owner';
const BUYER = 'uid_buyer';
const STRANGER = 'uid_stranger';

let testEnv;

// ---------------------------------------------------------------- helpers
const asOwner = () => testEnv.authenticatedContext(OWNER).firestore();
const asBuyer = () => testEnv.authenticatedContext(BUYER).firestore();
const asStranger = () => testEnv.authenticatedContext(STRANGER).firestore();
const asNobody = () => testEnv.unauthenticatedContext().firestore();

/** Write a document with rules bypassed (like a Cloud Function would). */
async function seed(path, data) {
  await testEnv.withSecurityRulesDisabled(async (ctx) => {
    await setDoc(doc(ctx.firestore(), path), data);
  });
}

const results = [];
function check(name, passed, note = '') {
  results.push({ name, passed, note });
  console.log(`${passed ? '  ok  ' : ' FAIL '} ${name}${note ? '  -> ' + note : ''}`);
}

async function allowed(promise, label) {
  try {
    await promise;
    return true;
  } catch (e) {
    return false;
  }
}

// ---------------------------------------------------------------- suite
async function run() {
  console.log('\n=== CricketHub Firestore Rules — verification ===\n');

  // -------------------------------------------------- 0. BUG-01 regression
  console.log('[0] BUG-01: Phase-3 collections must NOT be permission-denied');
  console.log('    (each checked with the user who is SUPPOSED to have access)');

  // /admins/{uid} — a real admin, so isAdmin() evaluates to true.
  const ADMIN = 'uid_admin';
  await seed('admins/' + ADMIN, { granted_at: 'now' });
  const asAdmin = () => testEnv.authenticatedContext(ADMIN).firestore();

  const phase3Checks = [
    // [path, seedData, reader, label]
    ['grounds/Gr_1', { name: 'Suncity Turf', owner_uid: OWNER, city: 'Ahmedabad',
      status: 'active', verified: true, avg_rating: 4.5 }, asBuyer, 'buyer'],
    ['bookings/Bk_1', { organizer_uid: BUYER, counterparty_uid: OWNER, kind: 'ground',
      status: 'held', amount_paise: 100000 }, asBuyer, 'organizer'],
    ['umpires/U_1', { user_uid: STRANGER, status: 'active', verified: true,
      day_rate: 2000, city: 'Ahmedabad', avg_rating: 4.0 }, asBuyer, 'buyer'],
    ['ground_reviews/R_1', { reviewer_uid: BUYER, rating: 5, text: 'Good turf' },
      asBuyer, 'signed-in user'],
    ['payout_ledger/' + OWNER + '/weeks/2025-W15', { net_payout_paise: 95000 },
      asOwner, 'payout owner'],
    ['razorpay_events/evt_1', { type: 'payment.captured' }, asAdmin, 'admin'],
  ];
  for (const [path, data] of phase3Checks) {
    await seed(path, data);
  }

  for (const [path, , reader, label] of phase3Checks) {
    const code = await getDoc(doc(reader(), path)).then(() => 'ok').catch((e) => e.code);
    check(`${path.split('/')[0]} reachable by ${label}`, code === 'ok',
      code === 'permission-denied' ? 'PERMISSION_DENIED (rule missing/broken!)' : code);
  }

  // -------------------------------------------------- 1. unauthenticated
  console.log('\n[1] Unauthenticated users are locked out');
  check('anon cannot read grounds',
    !(await allowed(getDoc(doc(asNobody(), 'grounds/Gr_1')), 'grounds')));
  check('anon cannot read bookings',
    !(await allowed(getDoc(doc(asNobody(), 'bookings/Bk_1')), 'bookings')));
  check('anon cannot read matches',
    !(await allowed(getDoc(doc(asNobody(), 'matches/M_1')), 'matches')));

  // -------------------------------------------------- 1b. BUG-12 (PII leak)
  console.log('\n[1b] BUG-12: umpire PII must not be world-readable');
  await seed('umpires/U_1', {
    user_uid: STRANGER, status: 'active', verified: true, day_rate: 2000,
    city: 'Ahmedabad', avg_rating: 4.0, phone_number: '+91-9999999999',
  });
  const anonUmpire = await getDoc(doc(asNobody(), 'umpires/U_1'))
    .then(() => 'ok').catch((e) => e.code);
  check('anon CANNOT read umpires/{uid} (phone_number lives here)',
    anonUmpire === 'permission-denied',
    anonUmpire === 'ok'
      ? 'LEAK: phone_number is world-readable (Security doc says it must not be)'
      : anonUmpire);
  check('signed-in user CAN still browse verified umpires',
    await allowed(getDoc(doc(asBuyer(), 'umpires/U_1')), 'umpires'));

  // -------------------------------------------------- 2. grounds
  console.log('\n[2] Grounds: verified+active public to signed-in, draft private to owner');
  check('signed-in user CAN read a verified+active ground',
    await allowed(getDoc(doc(asStranger(), 'grounds/Gr_1')), 'grounds'));

  await seed('grounds/Gr_draft', {
    name: 'Draft Ground', owner_uid: OWNER, city: 'Ahmedabad',
    status: 'draft', verified: false, avg_rating: 0,
  });

  check('stranger CANNOT read a draft ground',
    !(await allowed(getDoc(doc(asStranger(), 'grounds/Gr_draft')), 'grounds')));
  check('owner CAN read own draft ground',
    await allowed(getDoc(doc(asOwner(), 'grounds/Gr_draft')), 'grounds'));

  check('isAdmin() is FALSE without an /admins doc',
    !(await allowed(getDoc(doc(testEnv.authenticatedContext('uid_nobody_admin')
      .firestore(), 'razorpay_events/evt_1')), 'razorpay_events')),
    'deny-by-default while /admins/{uid} is empty');
  check('isAdmin() is TRUE once /admins/{uid} exists',
    await allowed(getDoc(doc(asAdmin(), 'razorpay_events/evt_1')), 'razorpay_events'),
    'admin can read server-only collections');

  // -------------------------------------------------- 2b. query compatibility
  console.log('\n[2b] List queries must satisfy the rules (rules are not filters)');
  const q = query(collection(asBuyer(), 'grounds'),
    where('city', '==', 'Ahmedabad'),
    where('status', '==', 'active'),
    where('verified', '==', true),
    where('avg_rating', '>=', 0));
  check('ground_list_screen style query is allowed',
    await allowed(getDocs(q), 'grounds query'),
    'service filters city+status+verified, matching the rule');

  // -------------------------------------------------- 3. bookings
  console.log('\n[3] Bookings: only the two parties (or admin) can read');
  check('organizer CAN read own booking',
    await allowed(getDoc(doc(asBuyer(), 'bookings/Bk_1')), 'bookings'));
  check('counterparty (owner) CAN read the booking',
    await allowed(getDoc(doc(asOwner(), 'bookings/Bk_1')), 'bookings'));
  check('unrelated user CANNOT read the booking',
    !(await allowed(getDoc(doc(asStranger(), 'bookings/Bk_1')), 'bookings')));
  check('booking delete is always denied',
    !(await allowed(deleteDoc(doc(asBuyer(), 'bookings/Bk_1')), 'bookings')));

  // -------------------------------------------------- 4. payout path
  console.log('\n[4] BUG-11: payout_ledger path must match functions/index.js:836');
  check('owner CAN read payout_ledger/{uid}/weeks/{week}',
    await allowed(getDoc(doc(asOwner(), 'payout_ledger/' + OWNER + '/weeks/2025-W15')), 'payout'),
    'this is the path the Cloud Function actually writes');
  check('stranger CANNOT read someone else\'s payout',
    !(await allowed(getDoc(doc(asStranger(), 'payout_ledger/' + OWNER + '/weeks/2025-W15')), 'payout')));
  check('owner CANNOT write payouts (server-owned)',
    !(await allowed(setDoc(doc(asOwner(), 'payout_ledger/' + OWNER + '/weeks/2025-W99'),
      { net_payout_paise: 1 }), 'payout')));

  // -------------------------------------------------- 5. users subcollections
  console.log('\n[5] users/{uid} subcollections (Phase 3 additions)');
  check('owner CAN write own favorite_grounds',
    await allowed(setDoc(doc(asBuyer(), 'users/' + BUYER + '/favorite_grounds/Gr_1'),
      { added_at: 'now' }), 'fav'));
  check('other user CANNOT write my favorite_grounds',
    !(await allowed(setDoc(doc(asStranger(), 'users/' + BUYER + '/favorite_grounds/Gr_1'),
      { added_at: 'now' }), 'fav')));

  // -------------------------------------------------- 6. reviews
  console.log('\n[6] Reviews: create own only, correct rating bounds');
  check('user CAN create own review',
    await allowed(setDoc(doc(asStranger(), 'ground_reviews/R_new'),
      { reviewer_uid: STRANGER, rating: 4, text: 'Nice' }), 'review'));
  check('user CANNOT create a review in someone else\'s name',
    !(await allowed(setDoc(doc(asStranger(), 'ground_reviews/R_fake'),
      { reviewer_uid: BUYER, rating: 5, text: 'Fake' }), 'review')));
  check('rating out of bounds is rejected',
    !(await allowed(setDoc(doc(asStranger(), 'ground_reviews/R_bad'),
      { reviewer_uid: STRANGER, rating: 9, text: 'Bad' }), 'review')));
  check('user CANNOT delete a review (admin only)',
    !(await allowed(deleteDoc(doc(asStranger(), 'ground_reviews/R_1')), 'review')));

  // -------------------------------------------------- 7. legacy Phase 1/2 still works
  console.log('\n[7] Phase 1/2 rules must not have regressed');
  check('balls subcollection write denied to non-scorer',
    !(await allowed(setDoc(doc(asStranger(), 'matches/M_1/balls/b_1'),
      { runs: 4 }), 'balls')));
  check('player_stats is read-only for clients',
    !(await allowed(setDoc(doc(asStranger(), 'player_stats/p_1'),
      { runs: 100 }), 'stats')));

  // -------------------------------------------------- summary
  const failed = results.filter((r) => !r.passed);
  console.log(`\n=== ${results.length - failed.length}/${results.length} checks passed ===`);
  if (failed.length) {
    console.log('\nFAILED:');
    failed.forEach((f) => console.log(`  - ${f.name}${f.note ? ' (' + f.note + ')' : ''}`));
  }
  return failed.length;
}

(async () => {
  // `firebase emulators:exec` exports FIRESTORE_EMULATOR_HOST (e.g.
  // "127.0.0.1:8080"), so we never hardcode the port and the suite works
  // regardless of which port the emulator picks.
  const hostPort = process.env.FIRESTORE_EMULATOR_HOST || '127.0.0.1:8080';
  const [host, port] = hostPort.split(':');

  // The suite lives in rules-test/ but must always test the APP's real rules
  // file at ../firestore.rules — never a stale copy. If someone runs this from
  // the project root, './firestore.rules' is the same file.
  const rulesPath = [
    path.join(__dirname, '..', 'firestore.rules'), // rules-test/../firestore.rules
    path.join(__dirname, 'firestore.rules'),       // local copy, legacy
  ].find((p) => fs.existsSync(p));

  if (!rulesPath) {
    console.error(
      '\nCould not find firestore.rules.\n' +
        'Looked in:\n' +
        `  ${path.join(__dirname, '..', 'firestore.rules')}\n` +
        `  ${path.join(__dirname, 'firestore.rules')}\n`,
    );
    process.exit(1);
  }

  console.log(`Using rules: ${rulesPath}\n`);

  testEnv = await initializeTestEnvironment({
    projectId: PROJECT_ID,
    firestore: {
      rules: fs.readFileSync(rulesPath, 'utf8'),
      host,
      port: Number(port),
    },
  });

  let failedCount = 1;
  try {
    failedCount = await run();
  } catch (err) {
    console.error('\nSUITE CRASHED:', err.message);
  } finally {
    await testEnv.cleanup();
  }
  process.exit(failedCount ? 1 : 0);
})();
