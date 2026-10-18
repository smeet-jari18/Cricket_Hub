"""Shared plumbing for the emulator scripts in this folder.

Everything talks to the Firebase Emulator Suite over plain HTTP with the
standard library only — no pip install, no firebase-admin, no service account.

  auth       http://localhost:9099
  firestore  http://localhost:8080
  functions  http://localhost:5001

Two ways of authenticating against Firestore:

  * ``Bearer owner``  — the emulator's admin bypass (ignores security rules).
                        Used only for SEEDING.
  * ``Bearer <idToken>`` — a real end-user token, so every assertion in
                        e2e_smoke_test.py goes through the real
                        ``firestore.rules``. That is the whole point: a green
                        run here means the deployed rules will not surprise us.
"""

from __future__ import annotations

import json
import os
import urllib.error
import urllib.request

PROJECT_ID = os.environ.get("FB_PROJECT", "crickethub-dev")
REGION = os.environ.get("FB_REGION", "asia-south1")

AUTH_HOST = os.environ.get("AUTH_EMULATOR_HOST", "127.0.0.1:9099")
FIRESTORE_HOST = os.environ.get("FIRESTORE_EMULATOR_HOST", "127.0.0.1:8080")
FUNCTIONS_HOST = os.environ.get("FUNCTIONS_EMULATOR_HOST", "127.0.0.1:5001")


# ---------------------------------------------------------------------------
# HTTP
# ---------------------------------------------------------------------------

def _request(method: str, url: str, body=None, token: str | None = None,
             timeout: float = 30.0):
    """Returns (status, parsed_json_or_text). Never raises on 4xx/5xx."""
    data = None
    headers = {"Content-Type": "application/json"}
    if body is not None:
        data = json.dumps(body).encode()
    if token:
        headers["Authorization"] = f"Bearer {token}"
    req = urllib.request.Request(url, data=data, headers=headers, method=method)
    try:
        with urllib.request.urlopen(req, timeout=timeout) as resp:
            raw = resp.read().decode()
            return resp.status, (json.loads(raw) if raw else {})
    except urllib.error.HTTPError as e:
        raw = e.read().decode()
        try:
            return e.code, json.loads(raw) if raw else {}
        except json.JSONDecodeError:
            return e.code, raw
    except urllib.error.URLError as e:
        raise SystemExit(
            f"\n❌ {url} reachable nahi hai ({e.reason}).\n"
            "   Pehle doosre terminal mein:  firebase emulators:start\n"
        )


# ---------------------------------------------------------------------------
# Auth emulator
# ---------------------------------------------------------------------------

def create_auth_user(email: str, password: str = "crickethub123") -> tuple[str, str]:
    """Signs up (or signs in) an email/password user on the Auth emulator.

    Returns (uid, idToken). Email auth is used because the emulator's phone
    flow needs a fake SMS code round-trip; the rules only care about
    ``request.auth.uid``, so the sign-in method is irrelevant here.
    """
    base = f"http://{AUTH_HOST}/identitytoolkit.googleapis.com/v1/accounts"
    status, res = _request(
        "POST",
        f"{base}:signUp?key=fake-api-key",
        {"email": email, "password": password, "returnSecureToken": True},
    )
    if status == 200:
        return res["localId"], res["idToken"]

    # Already created by an earlier run -> sign in instead.
    status2, res2 = _request(
        "POST",
        f"{base}:signInWithPassword?key=fake-api-key",
        {"email": email, "password": password, "returnSecureToken": True},
    )
    if status2 == 200:
        return res2["localId"], res2["idToken"]
    raise RuntimeError(f"Auth user banaya nahi ja saka ({email}): {status} {res}")


def fs_clear() -> None:
    """Deletes every Firestore document in the emulator (fresh-run guarantee)."""
    status, _ = _request(
        "DELETE",
        f"http://{FIRESTORE_HOST}/emulator/v1/projects/{PROJECT_ID}"
        "/databases/(default)/documents",
    )
    if status not in (200, 204):
        print(f"  (firestore wipe skipped: HTTP {status})")


def auth_delete_all() -> None:
    """Wipes every Auth-emulator user. Handy between runs."""
    status, _ = _request(
        "DELETE",
        f"http://{AUTH_HOST}/emulator/v1/projects/{PROJECT_ID}/accounts",
    )
    if status not in (200, 204):
        print(f"  (auth wipe skipped: HTTP {status})")


# ---------------------------------------------------------------------------
# Firestore REST value encoding
# ---------------------------------------------------------------------------

def to_value(v):
    if v is None:
        return {"nullValue": None}
    if isinstance(v, bool):
        return {"booleanValue": v}
    if isinstance(v, int):
        return {"integerValue": str(v)}
    if isinstance(v, float):
        return {"doubleValue": v}
    if isinstance(v, str):
        return {"stringValue": v}
    if isinstance(v, dict):
        return {"mapValue": {"fields": {k: to_value(x) for k, x in v.items()}}}
    if isinstance(v, (list, tuple)):
        return {"arrayValue": {"values": [to_value(x) for x in v]}}
    raise TypeError(f"Firestore me ye type nahi ja sakta: {type(v)}")


def to_fields(d: dict) -> dict:
    return {k: to_value(v) for k, v in d.items()}


def from_value(v):
    if "nullValue" in v:
        return None
    if "booleanValue" in v:
        return v["booleanValue"]
    if "integerValue" in v:
        return int(v["integerValue"])
    if "doubleValue" in v:
        return float(v["doubleValue"])
    if "stringValue" in v:
        return v["stringValue"]
    if "timestampValue" in v:
        return v["timestampValue"]
    if "mapValue" in v:
        return from_doc(v["mapValue"].get("fields", {}))
    if "arrayValue" in v:
        return [from_value(x) for x in v["arrayValue"].get("values", [])]
    return None


def from_doc(fields: dict) -> dict:
    return {k: from_value(v) for k, v in (fields or {}).items()}


# ---------------------------------------------------------------------------
# Firestore CRUD
# ---------------------------------------------------------------------------

def _doc_url(path: str) -> str:
    return (f"http://{FIRESTORE_HOST}/v1/projects/{PROJECT_ID}"
            f"/databases/(default)/documents/{path}")


def fs_set_admin(path: str, fields: dict) -> None:
    """Creates/overwrites a document with rules BYPASSED (``Bearer owner``)."""
    status, res = _request(
        "PATCH", _doc_url(path), {"fields": to_fields(fields)}, token="owner"
    )
    if status != 200:
        raise RuntimeError(f"Seed fail {path}: HTTP {status} {res}")


def fs_get(path: str, token: str | None = None):
    """Reads a document as an end user. Returns (status, data|error)."""
    return _request("GET", _doc_url(path), token=token)


def fs_patch(path: str, fields: dict, token: str):
    """Updates fields as an end user — so ``firestore.rules`` are enforced.

    Uses ``updateMask`` so only the listed fields count as "affected keys"
    (that is exactly what the rule's ``affectedKeys().hasOnly([...])`` checks).
    """
    mask = "&".join(f"updateMask.fieldPaths={k}" for k in fields)
    return _request(
        "PATCH", f"{_doc_url(path)}?{mask}", {"fields": to_fields(fields)},
        token=token,
    )


def fs_create(path: str, fields: dict, token: str):
    """Creates a document as an end user (POST with documentId)."""
    col, _, doc_id = path.rpartition("/")
    return _request(
        "POST",
        f"http://{FIRESTORE_HOST}/v1/projects/{PROJECT_ID}"
        f"/databases/(default)/documents/{col}?documentId={doc_id}",
        {"fields": to_fields(fields)},
        token=token,
    )


# ---------------------------------------------------------------------------
# Cloud Functions (callable v2 over the emulator)
# ---------------------------------------------------------------------------

def call(name: str, data: dict, token: str):
    """Calls a callable function. Returns (ok, result_or_error_code)."""
    url = f"http://{FUNCTIONS_HOST}/{PROJECT_ID}/{REGION}/{name}"
    status, res = _request("POST", url, {"data": data}, token=token, timeout=60)
    if status == 200 and isinstance(res, dict) and "result" in res:
        return True, res["result"]
    code = "UNKNOWN"
    if isinstance(res, dict):
        code = (res.get("error") or {}).get("status", "UNKNOWN")
    return False, code


# ---------------------------------------------------------------------------
# Tiny check runner (same output style as rules-test/rules.test.js)
# ---------------------------------------------------------------------------

class Checks:
    def __init__(self):
        self.results: list[tuple[str, bool, str]] = []

    def check(self, name: str, passed: bool, note: str = "") -> bool:
        self.results.append((name, bool(passed), note))
        mark = "ok  " if passed else "FAIL"
        print(f"  {mark} {name}" + (f"  ({note})" if note and not passed else ""))
        return passed

    def section(self, title: str) -> None:
        print(f"\n[{title}]")

    def finish(self) -> int:
        failed = [(n, note) for n, ok, note in self.results if not ok]
        total = len(self.results)
        print(f"\n=== {total - len(failed)}/{total} checks passed ===")
        if failed:
            print("\nFAILED:")
            for n, note in failed:
                print(f"  - {n}" + (f" ({note})" if note else ""))
            return 1
        return 0
