#!/usr/bin/env python3
"""Mapping-driven localization codemod.

Extracting ~500 strings by hand is how localization projects die. This script
does the mechanical half: you give it a JSON map of
`"exact English literal" -> "arbKey"`, and it

  1. replaces `'literal'` with `l10n.<arbKey>` in the Dart file,
  2. adds the AppLocalizations import with the right relative depth,
  3. inserts `final l10n = AppLocalizations.of(context);` into every method
     that takes a BuildContext (unused ones are removed by l10n_fix_consts.py),
  4. appends the new keys to all three ARB files.

`tools/l10n_fix_consts.py` then removes the `const` keywords that a runtime
`l10n.` call invalidates.

    python3 tools/l10n_apply.py map.json
    python3 tools/l10n_apply.py map.json --dry-run
"""
from __future__ import annotations

import collections
import json
import pathlib
import re
import sys

ROOT = pathlib.Path(__file__).resolve().parent.parent
ARB_FILES = {
    "en": ROOT / "lib/l10n/app_en.arb",
    "hi": ROOT / "lib/l10n/app_hi.arb",
    "ta": ROOT / "lib/l10n/app_ta.arb",
}

IMPORT_LINE = "import '{path}l10n/generated/app_localizations.dart';"

DECL = "final l10n = AppLocalizations.of(context);"

# Signatures that receive a BuildContext we can read from.
METHOD_WITH_CONTEXT = re.compile(
    r"^\s*(?:Future<[^>]+>|void|Widget|String|bool|int|double|[A-Za-z_<>?]+)\s+"
    r"[_\w]+\s*\(\s*(?:[^)]*?)\bBuildContext\s+context\b[^)]*\)\s*(?:async\s*)?\{",
    re.MULTILINE,
)


def main(argv: list[str]) -> int:
    if len(argv) < 2:
        print(__doc__)
        return 2
    dry_run = "--dry-run" in argv
    mapping = json.loads(pathlib.Path(argv[1]).read_text(encoding="utf-8"))

    files: dict[str, list[dict]] = mapping["files"]
    arb_values: dict[str, dict[str, str]] = mapping["arb"]

    changed_files = 0
    replaced_total = 0

    for rel_path, entries in files.items():
        path = ROOT / rel_path
        if not path.exists():
            print(f"  SKIP {rel_path}: file not found")
            continue
        source = path.read_text(encoding="utf-8")
        original = source
        replaced_here = 0

        for entry in entries:
            literal = entry["literal"]
            key = entry["key"]
            # Try the exact quoted forms that appear in Dart source.
            for quoted in (f"'{literal}'", f'"{literal}"'):
                if quoted in source:
                    source = source.replace(quoted, f"l10n.{key}")
                    replaced_here += 1

        if replaced_here == 0:
            print(f"  ! {rel_path}: no literal matched (already done?)")
            continue

        # Import.
        if "app_localizations.dart" not in source:
            depth = rel_path.count("/") - 1  # lib/screens/x.dart -> ../../
            prefix = "../" * depth if depth > 0 else ""
            last_import = None
            for match in re.finditer(r"^import .*;$", source, re.MULTILINE):
                last_import = match
            if last_import is None:
                source = IMPORT_LINE.format(path=prefix) + "\n" + source
            else:
                insert_at = last_import.end()
                source = (
                    source[:insert_at]
                    + "\n" + IMPORT_LINE.format(path=prefix)
                    + source[insert_at:]
                )

        # Declare `l10n` in every method that has a BuildContext.
        if DECL not in source:
            out = []
            pos = 0
            for match in METHOD_WITH_CONTEXT.finditer(source):
                brace = match.end() - 1
                if brace < pos:
                    continue
                body_start = brace + 1
                # Skip if the very next non-space is already our declaration.
                tail = source[body_start: body_start + 120]
                out.append(source[pos:body_start])
                out.append("\n    " + DECL)
                pos = body_start
                _ = tail
            out.append(source[pos:])
            source = "".join(out)
        else:
            # A second method may also need it; append where missing.
            out = []
            pos = 0
            for match in METHOD_WITH_CONTEXT.finditer(source):
                brace = match.end() - 1
                body_start = brace + 1
                tail = source[body_start: body_start + 200]
                if DECL in tail:
                    continue
                out.append(source[pos:body_start])
                out.append("\n    " + DECL)
                pos = body_start
            out.append(source[pos:])
            source = "".join(out)

        if source != original:
            changed_files += 1
            replaced_total += replaced_here
            if dry_run:
                print(f"  ~ {rel_path}: would replace {replaced_here}")
            else:
                path.write_text(source, encoding="utf-8")
                print(f"  ✓ {rel_path}: {replaced_here} string(s)")

    # ARB files.
    for lang, arb_path in ARB_FILES.items():
        arb = json.loads(arb_path.read_text(encoding="utf-8"),
                         object_pairs_hook=collections.OrderedDict)
        added = 0
        for key, values in arb_values.items():
            if key in arb:
                if arb[key] != values[lang]:
                    print(f"  ! duplicate key '{key}' with different text")
                continue
            arb[key] = values[lang]
            added += 1
        if added and not dry_run:
            arb_path.write_text(
                json.dumps(arb, ensure_ascii=False, indent=2) + "\n",
                encoding="utf-8",
            )
        print(f"  ARB {lang}: +{added} key(s)")

    print(f"\n{'Would change' if dry_run else 'Changed'} {changed_files} file(s), "
          f"{replaced_total} literal(s).")
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv))
