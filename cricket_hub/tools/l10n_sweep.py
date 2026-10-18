#!/usr/bin/env python3
"""Phrasebook-driven localization sweep.

`l10n_apply.py` needs a hand-written map per wave. With ~350 user-facing
strings left across 60+ screens that is a week of JSON authoring. This script
flips the model: you keep a *phrasebook* (`tools/phrasebook_*.json`) of

    "Cancel booking": ["बुकिंग रद्द करें", "முன்பதிவை ரத்துசெய்"]

…and the sweep finds every text slot in the app that holds that exact English
string, swaps it for `l10n.<key>`, names keys deterministically, reuses a key
when the same English already exists in the ARB, and adds the new entries to
en/hi/ta.

Only *text slots* are touched — `Text(...)`, `label:`, `hintText:`, `title:`,
`content:`, `tooltip:`, `semanticLabel:` … — so Firestore field keys, route
names and asset paths are never rewritten. Interpolated strings (`'$x runs'`)
are left alone on purpose: they need ARB placeholders, not a flat lookup.

    python3 tools/l10n_sweep.py              # apply
    python3 tools/l10n_sweep.py --dry-run
    python3 tools/l10n_sweep.py --report     # what is left, per file
"""
from __future__ import annotations

import collections
import json
import pathlib
import re
import sys

ROOT = pathlib.Path(__file__).resolve().parent.parent
LIB = ROOT / "lib"
ARB_FILES = {
    "en": ROOT / "lib/l10n/app_en.arb",
    "hi": ROOT / "lib/l10n/app_hi.arb",
    "ta": ROOT / "lib/l10n/app_ta.arb",
}
GENERATED = "lib/l10n/generated"

# Text that is correct in every language, or is not text at all: the brand,
# the trilingual language strip, currency/phone masks, and cricket's own
# abbreviations (a scorer writes "WD" in Hindi too).
ALLOW = {
    "CricketHub", "English · हिन्दी · தமிழ்", "₹", "+91", "••••••",
    "98765 43210", "NRR", "WD", "NB", "LB", "4s / 6s",
}

# The boot-failure screen deliberately does not depend on AppLocalizations —
# it has to render when the app cannot start at all.
SKIP_FILES = {"lib/screens/bootstrap_error_screen.dart"}

IMPORT_LINE = "import '{path}l10n/generated/app_localizations.dart';"
DECL = "final l10n = AppLocalizations.of(context);"

# A text slot: the widget argument that renders user-facing copy.
SLOT = re.compile(
    r"""(?P<pre>(?:
        Text\(\s*
      | (?:label|labelText|hintText|helperText|tooltip|title|subtitle|
           content|semanticLabel|errorText|prefixText|suffixText)\s*:\s*
    ))(?P<q>['"])(?P<lit>[^'"\n]{2,})(?P=q)""",
    re.VERBOSE,
)

METHOD_WITH_CONTEXT = re.compile(
    r"^\s*(?:Future<[^>]+>|void|Widget|String|bool|int|double|[A-Za-z_<>?]+)\s+"
    r"[_\w]+\s*\(\s*(?:[^)]*?)\bBuildContext\s+context\b[^)]*\)\s*(?:async\s*)?\{",
    re.MULTILINE,
)


def slugify(text: str) -> str:
    base = re.sub(r"[^a-z0-9]+", "_", text.lower()).strip("_")
    words = [w for w in base.split("_") if w][:6]
    slug = "_".join(words) or "text"
    if slug[0].isdigit():  # a Dart identifier cannot start with a digit
        slug = "k_" + slug
    return slug


def load_phrasebook() -> dict[str, tuple[str, str]]:
    book: dict[str, tuple[str, str]] = {}
    for path in sorted((ROOT / "tools").glob("phrasebook_*.json")):
        data = json.loads(path.read_text(encoding="utf-8"))
        for en, pair in data.items():
            if not (isinstance(pair, list) and len(pair) == 2):
                raise SystemExit(f"{path}: '{en}' must be [hi, ta]")
            book[en] = (pair[0], pair[1])
    return book


def ensure_import(source: str, rel_path: str) -> str:
    if "app_localizations.dart" in source:
        return source
    depth = rel_path.count("/") - 1
    prefix = "../" * depth if depth > 0 else ""
    last = None
    for match in re.finditer(r"^import .*;$", source, re.MULTILINE):
        last = match
    if last is None:
        return IMPORT_LINE.format(path=prefix) + "\n" + source
    return source[: last.end()] + "\n" + IMPORT_LINE.format(path=prefix) + source[last.end():]


def ensure_decls(source: str) -> str:
    """Add `final l10n = ...` to BuildContext methods whose body reads l10n."""
    matches = list(METHOD_WITH_CONTEXT.finditer(source))
    if not matches:
        return source
    out, pos = [], 0
    for i, match in enumerate(matches):
        body_start = match.end()  # just after '{'
        body_end = matches[i + 1].start() if i + 1 < len(matches) else len(source)
        body = source[body_start:body_end]
        if "l10n." not in body:
            continue
        if DECL in body[:240]:
            continue
        out.append(source[pos:body_start])
        out.append("\n    " + DECL)
        pos = body_start
    out.append(source[pos:])
    return "".join(out)


def main(argv: list[str]) -> int:
    dry_run = "--dry-run" in argv
    report_only = "--report" in argv
    book = load_phrasebook()

    arb_en = json.loads(ARB_FILES["en"].read_text(encoding="utf-8"))
    existing = {}
    for key, value in arb_en.items():
        if key.startswith("@"):
            continue
        existing.setdefault(value, key)
    taken = {k for k in arb_en if not k.startswith("@")}

    # Deterministic, collision-free key per phrase.
    keys: dict[str, str] = {}
    for en in sorted(book):
        if en in existing:
            keys[en] = existing[en]
            continue
        base = slugify(en)
        key, n = base, 2
        while key in taken:
            key = f"{base}_{n}"
            n += 1
        taken.add(key)
        keys[en] = key

    changed, replaced_total = 0, 0
    remaining = collections.Counter()
    skipped = collections.Counter()

    for path in sorted(LIB.rglob("*.dart")):
        rel = path.relative_to(ROOT).as_posix()
        if GENERATED in rel:
            continue
        if rel in SKIP_FILES:
            continue
        source = path.read_text(encoding="utf-8")

        if report_only:
            for m in SLOT.finditer(source):
                lit = m.group("lit").strip()
                if "$" in lit or lit in ALLOW:
                    continue
                if lit not in book:
                    remaining[lit] += 1
            continue

        hits = 0

        def swap(m: re.Match) -> str:
            nonlocal hits
            lit = m.group("lit")
            if "$" in lit or "'" in lit or lit.strip() in ALLOW:
                return m.group(0)
            # `'first half ' 'second half'` — a fragment. Skip: replacing one
            # half would leave invalid Dart, and these need a placeholder key.
            if re.match(r"\s*['\"]", source[m.end(): m.end() + 40]):
                skipped[lit.strip()] += 1
                return m.group(0)
            key = keys.get(lit.strip())
            if key is None:
                skipped[lit.strip()] += 1
                return m.group(0)
            hits += 1
            return f"{m.group('pre')}l10n.{key}"

        new_source = SLOT.sub(swap, source)
        if hits == 0:
            continue

        new_source = ensure_decls(ensure_import(new_source, rel))
        changed += 1
        replaced_total += hits
        if dry_run:
            print(f"  ~ {rel}: {hits}")
        else:
            path.write_text(new_source, encoding="utf-8")
            print(f"  ✓ {rel}: {hits}")

    if report_only:
        print(f"\n{sum(remaining.values())} literal(s) with no phrasebook entry, "
              f"{len(remaining)} unique:")
        for lit, n in remaining.most_common(40):
            print(f"  {n:2d} | {lit[:110]}")
        return 0

    if not dry_run:
        added = 0
        for lang, lang_file in ARB_FILES.items():
            arb = json.loads(lang_file.read_text(encoding="utf-8"),
                             object_pairs_hook=collections.OrderedDict)
            for en, key in keys.items():
                if key in arb:
                    continue
                hi, ta = book[en]
                arb[key] = en if lang == "en" else (hi if lang == "hi" else ta)
                added += 1
            lang_file.write_text(
                json.dumps(arb, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
        print(f"\nARB: +{added} key(s) across en/hi/ta")

    print(f"{'Would change' if dry_run else 'Changed'} {changed} file(s), "
          f"{replaced_total} literal(s).")
    if skipped:
        print(f"{len(skipped)} phrase(s) seen but missing from the phrasebook "
              f"— run with --report to list them.")
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv))
