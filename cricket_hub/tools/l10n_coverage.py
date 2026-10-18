#!/usr/bin/env python3
"""How much of the UI is actually localized — measured, not guessed.

Phase 4 asks for Hindi + Tamil. The infrastructure (ARB files, delegates,
language picker) landed this round, but the app has ~80 screens and 3000 string
literals; migrating them is a sprint of its own. This script turns "we're
partly done" into a number the team can move every week.

    python3 tools/l10n_coverage.py            # summary
    python3 tools/l10n_coverage.py --files    # per-file table, worst first
    python3 tools/l10n_coverage.py --gate     # exit 1 if a migrated file regresses

A file counts as **migrated** when it imports AppLocalizations. Inside a
migrated file we still look for leftover English literals, because "imported
the delegate" and "translated the screen" are different things.
"""
from __future__ import annotations

import argparse
import pathlib
import re
import sys

ROOT = pathlib.Path(__file__).resolve().parent.parent
LIB = ROOT / "lib"
GENERATED = "lib/l10n/generated"

# Widget arguments that take user-facing text. Matching the constructor rather
# than every string keeps `key: 'value'`, asset paths and route names out of the
# count — those are not translatable.
TEXT_CONTEXT = re.compile(
    r"""(?:
        Text\(\s*
      | (?:label|labelText|hintText|helperText|tooltip|title|subtitle|
           content|semanticLabel|errorText|prefixText|suffixText)\s*:\s*
    )['"]([^'"\n]{2,})['"]""",
    re.VERBOSE,
)

# Things that look like text but must not be translated.
SKIP_VALUES = re.compile(
    r"""^(?:
        \s*$ | https?:// | assets/ | / | [a-z0-9_.\-/]+\.(?:png|jpg|jpeg|svg|json)
      | [A-Z_]{2,}$            # SCREAMING constants
      | \d+(?:\.\d+)?$         # pure numbers
    )""",
    re.VERBOSE,
)


# Strings that are correct in every language: the brand, and the strip of
# language names shown on the picker (each name is written in its own script).
ALLOWLIST = {"CricketHub", "English · हिन्दी · தமிழ்"}


def scan() -> list[dict]:
    rows = []
    for path in sorted(LIB.rglob("*.dart")):
        rel = path.relative_to(ROOT).as_posix()
        if GENERATED in rel:
            continue
        source = path.read_text(encoding="utf-8")
        literals = [
            value
            for value in TEXT_CONTEXT.findall(source)
            if not SKIP_VALUES.match(value)
            # "$count", "${line.runs}" — runtime values, nothing to translate.
            and not value.lstrip().startswith('$')
            and value not in ALLOWLIST
        ]
        migrated = "AppLocalizations" in source
        rows.append(
            {
                "path": rel,
                "literals": literals,
                "migrated": migrated,
                "lines": source.count("\n") + 1,
            }
        )
    return rows


def main() -> int:
    parser = argparse.ArgumentParser(description="l10n coverage report")
    parser.add_argument("--files", action="store_true", help="per-file table")
    parser.add_argument(
        "--gate",
        action="store_true",
        help="exit 1 if a migrated file still has English literals",
    )
    args = parser.parse_args()

    rows = scan()
    total_literals = sum(len(r["literals"]) for r in rows)
    migrated = [r for r in rows if r["migrated"]]
    migrated_clean = [r for r in migrated if not r["literals"]]
    leftover_in_migrated = sum(len(r["literals"]) for r in migrated)

    print("CricketHub — localization coverage\n")
    print(f"  dart files            : {len(rows)}")
    print(f"  files importing l10n  : {len(migrated)}")
    print(f"  fully clean files     : {len(migrated_clean)}")
    print(f"  text literals total   : {total_literals}")
    print(f"  literals still in migrated files : {leftover_in_migrated}")

    if total_literals:
        localized_share = 100 * (1 - total_literals / total_literals)
        print(f"\n  (raw share is only meaningful once files are migrated; "
              f"{localized_share:.0f}% is the floor, not the answer)")

    print("\n  Localized verticals this round:")
    for row in migrated:
        mark = "clean" if not row["literals"] else f"{len(row['literals'])} left"
        print(f"    {row['path']:<62} {mark}")

    if args.files:
        print("\n  Worst offenders (by remaining text literals):")
        for row in sorted(rows, key=lambda r: -len(r["literals"]))[:20]:
            if not row["literals"]:
                continue
            print(f"    {len(row['literals']):>4}  {row['path']}")

    if args.gate:
        regressions = [r for r in migrated if r["literals"]]
        if regressions:
            print("\nGATE FAILED — these migrated files still contain literals:")
            for row in regressions:
                print(f"  {row['path']}")
                for value in row["literals"][:5]:
                    print(f"      \"{value}\"")
            return 1
        print("\nGATE PASSED — every migrated file is clean.")

    return 0


if __name__ == "__main__":
    sys.exit(main())
