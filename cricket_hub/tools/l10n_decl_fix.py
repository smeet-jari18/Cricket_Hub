#!/usr/bin/env python3
"""Insert `final l10n = AppLocalizations.of(context);` where the sweep missed it.

`l10n_apply.py` only knows to add the declaration inside methods whose
signature literally lists `BuildContext context`. Widget trees put `l10n.…`
in plenty of other places — `build` helpers, `_buildCard()`, `itemBuilder`
closures — and the sweep is not a parser. This script reads the analyzer's
`Undefined name 'l10n'` diagnostics and, for each one, walks back to the
enclosing method and inserts the declaration there — but only when `context`
is actually reachable (a State/StatelessWidget method). Anything else is
printed as MANUAL so it gets a human decision instead of a syntax error.

    python3 tools/l10n_decl_fix.py            # fix
    python3 tools/l10n_decl_fix.py --dry-run
"""
from __future__ import annotations

import collections
import pathlib
import re
import subprocess
import sys

ROOT = pathlib.Path(__file__).resolve().parent.parent
DECL = "final l10n = AppLocalizations.of(context);"

DIAG = re.compile(r"Undefined name 'l10n'.*• (lib/[^:]+):(\d+):(\d+) • undefined_identifier")

METHOD = re.compile(
    r"^\s*(?:Future<[^>]*>|void|Widget|String|bool|int|double|num|List<[^>]*>|"
    r"Map<[^>]*>|[A-Za-z_][\w<>?, ]*)\s+"
    r"[_a-zA-Z]\w*\s*\([^;]*?\)\s*(?:async\s*)?\{\s*$",
    re.MULTILINE,
)

CLASS = re.compile(r"^\s*class\s+(\w+)[^{]*\{", re.MULTILINE)
WIDGET_CLASS = re.compile(
    r"^\s*class\s+\w+[^{]*extends\s+(?:State|StatelessWidget|StatefulWidget)\b",
    re.MULTILINE,
)


def analyze() -> list[tuple[str, int, int]]:
    proc = subprocess.run(
        ["flutter", "analyze", "--no-fatal-infos"],
        cwd=ROOT, capture_output=True, text=True,
    )
    out = proc.stdout + proc.stderr
    return [(m.group(1), int(m.group(2)), int(m.group(3)))
            for m in DIAG.finditer(out)]


def enclosing_method(source: str, line: int) -> tuple[int, bool] | None:
    """(offset after `{`, context_reachable) for the method holding `line`."""
    lines = source.splitlines(keepends=True)
    upto = sum(len(l) for l in lines[: line - 1])
    open_braces = 0
    for m in reversed(list(METHOD.finditer(source, 0, upto + 1))):
        # `m` must still be open at `upto`.
        segment = source[m.end(): upto]
        if segment.count("}") - segment.count("{") >= 0 and "}" in segment:
            # A closing brace at the same level means we already left it.
            depth = 0
            closed = False
            for ch in segment:
                if ch == "{":
                    depth += 1
                elif ch == "}":
                    if depth == 0:
                        closed = True
                        break
                    depth -= 1
            if closed:
                continue
        return m.end(), True
    return None


def main(argv: list[str]) -> int:
    dry_run = "--dry-run" in argv
    errors = analyze()
    if not errors:
        print("No `undefined l10n` errors. Nothing to do.")
        return 0

    by_file: dict[str, list[int]] = collections.defaultdict(list)
    for path, line, _col in errors:
        by_file[path].append(line)

    fixed = manual = 0
    for rel, line_numbers in by_file.items():
        path = ROOT / rel
        source = path.read_text(encoding="utf-8")
        is_widget = bool(WIDGET_CLASS.search(source))
        inserts: set[int] = set()
        problems = []
        for line in sorted(set(line_numbers), reverse=True):
            found = enclosing_method(source, line)
            if found is None or not is_widget:
                problems.append(line)
                continue
            offset, _ = found
            if DECL in source[offset: offset + 200]:
                continue
            inserts.add(offset)
        if not inserts:
            print(f"  MANUAL {rel}: lines {problems}")
            manual += len(problems)
            continue
        new_source = source
        for offset in sorted(inserts, reverse=True):
            new_source = new_source[:offset] + "\n    " + DECL + new_source[offset:]
        fixed += len(inserts)
        if dry_run:
            print(f"  ~ {rel}: +{len(inserts)} declaration(s)")
        else:
            path.write_text(new_source, encoding="utf-8")
            print(f"  ✓ {rel}: +{len(inserts)} declaration(s)"
                  + (f" (manual: {problems})" if problems else ""))
        manual += len(problems)

    print(f"\n{'Would insert' if dry_run else 'Inserted'} {fixed} declaration(s); "
          f"{manual} site(s) need a human.")
    return 0 if manual == 0 else 1


if __name__ == "__main__":
    sys.exit(main(sys.argv))
