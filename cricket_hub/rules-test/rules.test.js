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
  console.log('\n[6] Reviews: own booking only, correct rating bounds');

  // A review must reference a booking the reviewer actually completed.
  // (docs/CricketHub_Security_Phase3.md -> "Self-booking + self-review")
  await seed('bookings/Bk_done', {
    organizer_uid: STRANGER, counterparty_uid: OWNER, kind: 'ground',
    resource_id: 'Gr_1', status: 'completed', amount_paise: 100000,
  });
  await seed('bookings/Bk_pending', {
    organizer_uid: STRANGER, counterparty_uid: OWNER, kind: 'ground',
    resource_id: 'Gr_1', status: 'pending_payment', amount_paise: 100000,
  });
  await seed('bookings/Bk_other', {
    organizer_uid: BUYER, counterparty_uid: OWNER, kind: 'ground',
    resource_id: 'Gr_1', status: 'completed', amount_paise: 100000,
  });
  await seed('bookings/Bk_umpire_done', {
    organizer_uid: STRANGER, counterparty_uid: 'U_1', kind: 'umpire',
    resource_id: 'U_1', status: 'completed', amount_paise: 150000,
  });

  check('user CAN review a completed own booking',
    await allowed(setDoc(doc(asStranger(), 'ground_reviews/R_new'),
      { booking_id: 'Bk_done', ground_id: 'Gr_1', reviewer_uid: STRANGER,
        rating: 4, text: 'Nice' }), 'review'));
  check('review WITHOUT booking_id is rejected',
    !(await allowed(setDoc(doc(asStranger(), 'ground_reviews/R_nobooking'),
      { reviewer_uid: STRANGER, rating: 5, text: 'Drive-by review' }), 'review')));
  check('review on a pending (unplayed) booking is rejected',
    !(await allowed(setDoc(doc(asStranger(), 'ground_reviews/R_pending'),
      { booking_id: 'Bk_pending', ground_id: 'Gr_1', reviewer_uid: STRANGER,
        rating: 5, text: 'Not played yet' }), 'review')));
  check('review on someone else\'s booking is rejected',
    !(await allowed(setDoc(doc(asStranger(), 'ground_reviews/R_someone'),
      { booking_id: 'Bk_other', ground_id: 'Gr_1', reviewer_uid: STRANGER,
        rating: 5, text: 'Not mine' }), 'review')));
  check('review for the wrong ground is rejected',
    !(await allowed(setDoc(doc(asStranger(), 'ground_reviews/R_wrongground'),
      { booking_id: 'Bk_done', ground_id: 'Gr_OTHER', reviewer_uid: STRANGER,
        rating: 5, text: 'Wrong ground' }), 'review')));
  check('user CANNOT create a review in someone else\'s name',
    !(await allowed(setDoc(doc(asStranger(), 'ground_reviews/R_fake'),
      { booking_id: 'Bk_done', ground_id: 'Gr_1', reviewer_uid: BUYER,
        rating: 5, text: 'Fake' }), 'review')));
  check('rating out of bounds is rejected',
    !(await allowed(setDoc(doc(asStranger(), 'ground_reviews/R_bad'),
      { booking_id: 'Bk_done', ground_id: 'Gr_1', reviewer_uid: STRANGER,
        rating: 9, text: 'Bad' }), 'review')));
  check('umpire review requires a completed umpire booking',
    await allowed(setDoc(doc(asStranger(), 'umpire_reviews/UR_ok'),
      { booking_id: 'Bk_umpire_done', umpire_uid: 'U_1', reviewer_uid: STRANGER,
        rating: 5, text: 'Good calls' }), 'review'));
  check('umpire review without a booking is rejected',
    !(await allowed(setDoc(doc(asStranger(), 'umpire_reviews/UR_nobooking'),
      { umpire_uid: 'U_1', reviewer_uid: STRANGER, rating: 1,
        text: 'Anonymous' }), 'review')));
  check('user CANNOT delete a review (admin only)',
    !(await allowed(deleteDoc(doc(asStranger(), 'ground_reviews/R_1')), 'review')));

  // -------------------------------------------------- 6b. admins
  console.log('\n[6b] Admin roster: read own entry only, never writable');

  check('admin CAN read own /admins/{uid}',
    await allowed(getDoc(doc(asAdmin(), 'admins/' + ADMIN)), 'admin doc'));
  check('user CANNOT read someone else\'s admin entry',
    !(await allowed(getDoc(doc(asBuyer(), 'admins/' + ADMIN)), 'admin doc')));
  check('nobody can write themselves into /admins',
    !(await allowed(setDoc(doc(asStranger(), 'admins/' + STRANGER),
      { granted_at: 'now' }), 'admin doc')));
  check('anon CANNOT read the admin doc',
    !(await allowed(getDoc(doc(asNobody(), 'admins/' + ADMIN)), 'admin doc')));

  console.log('\n[6c] Admin verification writes');

  await seed('grounds/Gr_pending', {
    name: 'Pending Turf', owner_uid: OWNER, city: 'Ahmedabad',
    status: 'pending_verification', verified: false, avg_rating: 0,
    review_count: 0, booking_count: 0,
  });
  await seed('umpires/U_pending', {
    user_uid: STRANGER, display_name: 'Pending Umpire', status: 'pending_verification',
    verified: false, day_rate: 3000, avg_rating: 0, review_count: 0,
    matches_officiated: 0, city: 'Ahmedabad',
  });

  check('owner CANNOT verify their own ground',
    !(await allowed(updateDoc(doc(asOwner(), 'grounds/Gr_pending'),
      { verified: true, status: 'active' }), 'ground')));
  check('admin CAN approve a pending ground',
    await allowed(updateDoc(doc(asAdmin(), 'grounds/Gr_pending'),
      { verified: true, status: 'active', updated_at: 'now' }), 'ground'));
  check('umpire CANNOT verify themselves',
    !(await allowed(updateDoc(doc(asStranger(), 'umpires/U_pending'),
      { verified: true, status: 'active' }), 'umpire')));
  check('admin CAN approve a pending umpire',
    await allowed(updateDoc(doc(asAdmin(), 'umpires/U_pending'),
      { verified: true, status: 'active', updated_at: 'now' }), 'umpire'));
  check('admin CANNOT silently edit a ground\'s name (scope)',
    !(await allowed(updateDoc(doc(asAdmin(), 'grounds/Gr_pending'),
      { name: 'Hijacked' }), 'ground')));

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
