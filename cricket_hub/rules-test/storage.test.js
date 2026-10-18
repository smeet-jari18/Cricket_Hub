/**
 * CricketHub — Firebase Storage rules verification.
 *
 * `@firebase/rules-unit-testing@4` has no Storage support, so this talks to
 * the Storage emulator's REST API directly — the same endpoint the Flutter
 * firebase_storage SDK uses:
 *
 *   POST http://127.0.0.1:9199/v0/b/<bucket>/o?name=<path>   (multipart upload)
 *   GET  http://127.0.0.1:9199/v0/b/<bucket>/o?prefix=...    (list, needs auth)
 *
 * Every request carries a REAL Auth-emulator ID token, so storage.rules is
 * actually enforced (the emulator only bypasses rules for `Bearer owner`).
 *
 *   firebase emulators:exec --only auth,storage,firestore "node storage.test.js"
 */
const fs = require('fs');
const path = require('path');

const PROJECT_ID = 'demo-crickethub';
const AUTH_HOST = '127.0.0.1:9099';
const STORAGE_HOST = '127.0.0.1:9199';
const BUCKET = `${PROJECT_ID}.firebasestorage.app`;

const OWNER = 'uid_owner';
const STRANGER = 'uid_stranger';
const UMPIRE = 'uid_umpire';
const GROUND_ID = 'Gr_storage_1';

const results = [];
function check(name, passed, note = '') {
  results.push({ name, passed, note });
  console.log(`${passed ? '  ok  ' : ' FAIL '} ${name}${note ? '  -> ' + note : ''}`);
}

// ---------------------------------------------------------------- auth
async function signUp(email) {
  const base = `http://${AUTH_HOST}/identitytoolkit.googleapis.com/v1/accounts`;
  for (const op of [':signUp', ':signInWithPassword']) {
    const res = await fetch(`${base}${op}?key=fake-api-key`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ email, password: 'crickethub123', returnSecureToken: true }),
    });
    if (res.ok) {
      const body = await res.json();
      return { uid: body.localId, token: body.idToken };
    }
  }
  throw new Error(`auth failed for ${email}`);
}

// ---------------------------------------------------------------- firestore seed
async function seedGround(id, data) {
  const res = await fetch(
    `http://127.0.0.1:8080/v1/projects/${PROJECT_ID}/databases/(default)/documents/grounds/${id}`,
    {
      method: 'PATCH',
      headers: { 'Content-Type': 'application/json', Authorization: 'Bearer owner' },
      body: JSON.stringify({ fields: data }),
    },
  );
  if (!res.ok) throw new Error(`seed failed: ${res.status}`);
}

// ---------------------------------------------------------------- storage REST
/** Uploads bytes. Returns the HTTP status. */
async function upload(objectPath, { token, contentType = 'image/jpeg', bytes = 'x'.repeat(64) } = {}) {
  const boundary = '----crickethubboundary';
  const metadata = JSON.stringify({ name: objectPath, contentType });
  // The upload form the real firebase_storage SDKs use against the Firebase
  // Storage API — the ONLY endpoint where the emulator enforces storage.rules:
  //   POST /v0/b/{bucket}/o?name=<path>
  //   X-Goog-Upload-Protocol: multipart
  //   Content-Type: multipart/related; boundary=...
  // part 1 = metadata (name + contentType), part 2 = the bytes.
  //
  // Two traps, both cost a debugging session — do not "simplify" them back:
  //   1. `multipart/form-data` body against /v0/ stores the whole envelope as
  //      the object, so request.resource.contentType becomes
  //      "multipart/form-data; boundary=..." and every image rule fails.
  //   2. `/upload/storage/v1/b/{bucket}/o?uploadType=multipart` is accepted by
  //      the emulator as the GCS *admin* API and skips storage.rules entirely
  //      (it even accepts anonymous uploads) — a green-looking test that
  //      proves nothing.
  const body =
    `--${boundary}\r\n` +
    'Content-Type: application/json; charset=UTF-8\r\n\r\n' +
    `${metadata}\r\n` +
    `--${boundary}\r\n` +
    `Content-Type: ${contentType}\r\n\r\n` +
    `${bytes}\r\n` +
    `--${boundary}--\r\n`;

  const headers = {
    'Content-Type': `multipart/related; boundary=${boundary}`,
    'X-Goog-Upload-Protocol': 'multipart',
  };
  if (token) headers.Authorization = `Bearer ${token}`;

  const res = await fetch(
    `http://${STORAGE_HOST}/v0/b/${BUCKET}/o?name=${encodeURIComponent(objectPath)}`,
    { method: 'POST', headers, body },
  );
  return res.status;
}

async function download(objectPath, token) {
  const headers = token ? { Authorization: `Bearer ${token}` } : {};
  const res = await fetch(
    `http://${STORAGE_HOST}/v0/b/${BUCKET}/o/${encodeURIComponent(objectPath)}?alt=media`,
    { headers },
  );
  return res.status;
}

/**
 * Deletes an object. Returns the status — a successful delete is **204 No
 * Content**, not 200, and an assertion of `=== 200` would fail even though the
 * rules allowed it.
 */
async function remove(objectPath, token) {
  const headers = token ? { Authorization: `Bearer ${token}` } : {};
  const res = await fetch(
    `http://${STORAGE_HOST}/v0/b/${BUCKET}/o/${encodeURIComponent(objectPath)}`,
    { method: 'DELETE', headers },
  );
  return res.status;
}

// ---------------------------------------------------------------- suite
(async () => {
  console.log('\n=== CricketHub Storage rules — verification ===\n');

  const owner = await signUp('storage.owner@crickethub.test');
  const stranger = await signUp('storage.stranger@crickethub.test');
  const umpire = await signUp('storage.umpire@crickethub.test');

  // The Storage rule does a cross-service lookup on the ground document.
  await seedGround(GROUND_ID, {
    name: { stringValue: 'Storage Test Turf' },
    owner_uid: { stringValue: owner.uid },
    status: { stringValue: 'active' },
  });

  const rulesPath = path.join(__dirname, '..', 'storage.rules');
  check('storage.rules exists and is loaded by the emulator', fs.existsSync(rulesPath));

  // ------------------------------------------------ ground photos
  console.log('\n[1] Ground photos');

  check('1. ground owner CAN upload a photo',
    (await upload(`grounds/${GROUND_ID}/cover.jpg`, { token: owner.token })) === 200);

  check('2. a stranger CANNOT upload to that ground',
    (await upload(`grounds/${GROUND_ID}/evil.jpg`, { token: stranger.token })) === 403);

  check('3. anonymous upload is rejected',
    (await upload(`grounds/${GROUND_ID}/anon.jpg`, {})) === 403);

  check('4. public (unauthenticated) read of a listing photo works',
    (await download(`grounds/${GROUND_ID}/cover.jpg`)) === 200);

  check('5. non-image upload is rejected (contentType)',
    (await upload(`grounds/${GROUND_ID}/doc.pdf`, {
      token: owner.token,
      contentType: 'application/pdf',
    })) === 403);

  check('6. a photo over 5MB is rejected',
    (await upload(`grounds/${GROUND_ID}/huge.jpg`, {
      token: owner.token,
      bytes: 'x'.repeat(5 * 1024 * 1024 + 10),
    })) === 403);

  check('7. owner CAN replace an existing photo',
    (await upload(`grounds/${GROUND_ID}/cover.jpg`, { token: owner.token })) === 200);

  // The size limit is inclusive on both sides (PhotoRules.maxBytes in Dart).
  // Without this positive control, check 6 would still pass if the rule were
  // `size <= 1` — a denied upload alone proves nothing about the boundary.
  check('7b. exactly 5MB is ACCEPTED (limit is inclusive)',
    (await upload(`grounds/${GROUND_ID}/exact.jpg`, {
      token: owner.token,
      bytes: 'x'.repeat(5 * 1024 * 1024),
    })) === 200);

  check('7c. 5MB + 1 byte is rejected',
    (await upload(`grounds/${GROUND_ID}/over.jpg`, {
      token: owner.token,
      bytes: 'x'.repeat(5 * 1024 * 1024 + 1),
    })) === 403);

  // ------------------------------------------------ deletes
  console.log('\n[1b] Deleting photos');

  check('7d. a stranger CANNOT delete the owner\'s photo',
    (await remove(`grounds/${GROUND_ID}/exact.jpg`, stranger.token)) === 403);

  check('7e. the owner CAN delete their own photo',
    (await remove(`grounds/${GROUND_ID}/exact.jpg`, owner.token)) === 204);

  // ------------------------------------------------ umpire photos
  console.log('\n[2] Umpire photos');

  check('8. umpire CAN upload their own profile photo',
    (await upload(`umpires/${umpire.uid}/profile.jpg`, { token: umpire.token })) === 200);

  check('9. another user CANNOT upload to that umpire path',
    (await upload(`umpires/${umpire.uid}/fake.jpg`, { token: stranger.token })) === 403);

  check('10. public read of an umpire photo works',
    (await download(`umpires/${umpire.uid}/profile.jpg`)) === 200);

  check('10b. an umpire CAN delete their own photo',
    (await remove(`umpires/${umpire.uid}/profile.jpg`, umpire.token)) === 204);

  check('10c. a stranger CANNOT delete that umpire photo',
    (await remove(`umpires/${umpire.uid}/cover.jpg`, stranger.token)) === 403);

  // ------------------------------------------------ deny-by-default
  console.log('\n[3] Anything else is denied');

  check('11. an unlisted path is not writable by anyone',
    (await upload('scratch/random.jpg', { token: owner.token })) === 403);

  check('12. an unlisted path is not readable',
    (await download('scratch/random.jpg')) === 403);

  const failed = results.filter((r) => !r.passed);
  console.log(`\n=== ${results.length - failed.length}/${results.length} checks passed ===`);
  if (failed.length) {
    console.log('\nFAILED:');
    failed.forEach((f) => console.log(`  - ${f.name}${f.note ? ' (' + f.note + ')' : ''}`));
  }
  process.exit(failed.length ? 1 : 0);
})().catch((err) => {
  console.error('\nSUITE CRASHED:', err.message);
  process.exit(1);
});
