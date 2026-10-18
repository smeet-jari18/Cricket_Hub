#!/usr/bin/env python3
"""Fixes what `l10n_apply.py` breaks, automatically.

Replacing `Text('Book')` with `Text(l10n.book)` turns every enclosing `const`
into an error (`Invalid constant value`). Fixing 300 of those by hand is not a
good use of a day, so this reads `flutter analyze` output and edits the exact
token the analyzer points at:

  * `Invalid constant value` / `const_with_non_constant_argument`
        -> drop the nearest `const` at or before that column
  * `unused_local_variable` for `l10n`
        -> delete the declaration line
  * `undefined_identifier` for `l10n`
        -> add the declaration at the top of that method body

    python3 tools/l10n_fix_consts.py            # fix, then re-analyze
    python3 tools/l10n_fix_consts.py --dry-run
"""
from __future__ import annotations

import pathlib
import re
import subprocess
import sys

ROOT = pathlib.Path(__file__).resolve().parent.parent
DECL = "final l10n = AppLocalizations.of(context);"

ISSUE = re.compile(
    r"^\s*(?:(?:error|warning|info)\s+•\s+)?(?P<message>.+?)\s+•\s+"
    r"(?P<file>[^:\s][^:]*\.dart):(?P<line>\d+):(?P<col>\d+)\s+•\s+(?P<code>[\w_]+)$"
)

CONST_CODES = {
    "invalid_constant",
    "const_with_non_constant_argument",
    "non_constant_list_element",
    "non_constant_map_value",
    "const_eval_method_invocation",
    "const_constructor_param_type_mismatch",
    "non_constant_default_value",
}


def analyze() -> list[dict]:
    result = subprocess.run(
        ["flutter", "analyze", "--no-pub"],
        cwd=ROOT,
        capture_output=True,
        text=True,
    )
    issues = []
    for line in result.stdout.splitlines():
        match = ISSUE.match(line.strip())
        if match:
            issues.append(match.groupdict())
    return issues


def strip_const_at(lines: list[str], lineno: int, col: int) -> bool:
    """Remove the closest `const` at or before (lineno, col) in the same file."""
    for index in range(lineno - 1, max(lineno - 12, -1), -1):
        line = lines[index]
        limit = col if index == lineno - 1 else len(line)
        best = None
        for match in re.finditer(r"\bconst\b\s*", line):
            if match.start() <= limit:
                best = match
        if best:
            lines[index] = line[:best.start()] + line[best.end():]
            return True
    return False


def main(argv: list[str]) -> int:
    dry_run = "--dry-run" in argv
    rounds = 0
    while True:
        rounds += 1
        if rounds > 8:
            print("Too many rounds — stopping.")
            return 1

        issues = analyze()
        target = [i for i in issues if i["code"] in CONST_CODES
                  or (i["code"] == "unused_local_variable" and "l10n" in i["message"])
                  or (i["code"] == "undefined_identifier" and "l10n" in i["message"])]
        if not target:
            print(f"No fixable issues left (round {rounds}). "
                  f"{len(issues)} issue(s) remain in total.")
            for issue in issues[:15]:
                print(f"  {issue['code']:<38} {issue['file']}:{issue['line']}")
            return 0

        by_file: dict[str, list[dict]] = {}
        for issue in target:
            by_file.setdefault(issue["file"], []).append(issue)

        for rel, file_issues in by_file.items():
            path = ROOT / rel
            text = path.read_text(encoding="utf-8")
            lines = text.split("\n")

            # Work bottom-up so earlier line numbers stay valid.
            for issue in sorted(file_issues, key=lambda i: -int(i["line"])):
                line = int(issue["line"])
                col = int(issue["col"])

                if issue["code"] in CONST_CODES:
                    strip_const_at(lines, line, col)
                elif issue["code"] == "unused_local_variable":
                    index = line - 1
                    if DECL in lines[index]:
                        del lines[index]
                elif issue["code"] == "undefined_identifier":
                    index = line - 1
                    indent = re.match(r"\s*", lines[index]).group(0)
                    # Walk up to the method body opening brace.
                    depth = 0
                    for up in range(index, max(index - 60, -1), -1):
                        if "{" in lines[up]:
                            depth += 1
                            break
                    lines.insert(index + 1, f"{indent}{DECL}")

            new_text = "\n".join(lines)
            if new_text != text and not dry_run:
                path.write_text(new_text, encoding="utf-8")

        print(f"Round {rounds}: fixed {len(target)} issue(s) "
              f"across {len(by_file)} file(s)")


if __name__ == "__main__":
    sys.exit(main(sys.argv))
