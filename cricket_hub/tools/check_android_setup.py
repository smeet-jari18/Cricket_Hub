#!/usr/bin/env python3
"""Why is Gradle failing before the app even builds? — find it in one run.

Most `build.gradle.kts` errors in a Flutter project are not syntax errors in
the file the console points at. The console says "Build file
'android/build.gradle.kts' line: 1" because that is where Gradle *starts*, and
then lists the real cause six lines below. This script checks the causes that
actually happen, in order of likelihood:

  1. two build files in the same folder (`build.gradle` **and** `build.gradle.kts`)
  2. repositories declared in both settings and the root build file while
     `RepositoriesMode.FAIL_ON_PROJECT_REPOS` is on
  3. `local.properties` pointing at an SDK/Flutter path that does not exist
  4. the Gradle wrapper and the Android Gradle Plugin disagreeing
  5. unbalanced braces in the Kotlin DSL files (a half-edited paste)

    python3 tools/check_android_setup.py
    python3 tools/check_android_setup.py --android path/to/android

Exit 0 = nothing wrong found. Exit 1 = at least one problem printed.
"""
from __future__ import annotations

import argparse
import pathlib
import re
import shutil
import subprocess
import sys

ROOT = pathlib.Path(__file__).resolve().parent.parent
DEFAULT_ANDROID = ROOT / "android"

OK = "  ok  "
WARN = " warn "
BAD = " FAIL "


def read(path: pathlib.Path) -> str:
    try:
        return path.read_text(encoding="utf-8", errors="replace")
    except OSError:
        return ""


def braces_balanced(text: str) -> bool:
    text = re.sub(r"//[^\n]*", "", text)
    text = re.sub(r"/\*.*?\*/", "", text, flags=re.S)
    text = re.sub(r'"(?:[^"\\]|\\.)*"', '""', text)
    text = re.sub(r"'(?:[^'\\]|\\.)*'", "''", text)
    return text.count("{") == text.count("}")


def main(argv: list[str]) -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--android", default=str(DEFAULT_ANDROID))
    args = parser.parse_args(argv[1:])

    android = pathlib.Path(args.android).expanduser().resolve()
    problems: list[str] = []
    notes: list[str] = []

    print(f"CricketHub — Android build setup check\n  {android}\n")
    if not android.is_dir():
        print(f"{BAD} android folder not found: {android}")
        return 1

    # 1. duplicate build files ------------------------------------------------
    for folder in (android, android / "app"):
        groovy = folder / "build.gradle"
        kotlin = folder / "build.gradle.kts"
        where = folder.relative_to(android) if folder != android else pathlib.Path(".")
        if groovy.exists() and kotlin.exists():
            print(f"{BAD} {where}: build.gradle AND build.gradle.kts both exist")
            problems.append(
                f"{folder}\n      Gradle refuses to pick one. Delete "
                f"'build.gradle' (Groovy) and keep 'build.gradle.kts'.")
        elif kotlin.exists():
            print(f"{OK} {where}: build.gradle.kts")
        elif groovy.exists():
            print(f"{OK} {where}: build.gradle (Groovy)")
        else:
            print(f"{BAD} {where}: no build file at all")
            problems.append(f"{folder} has no build file — the project is incomplete.")

    root_build = android / "build.gradle.kts"
    settings = android / "settings.gradle.kts"
    if not root_build.exists():
        root_build = android / "build.gradle"
    if not settings.exists():
        settings = android / "settings.gradle"

    root_text = read(root_build)
    settings_text = read(settings)

    # 2. repositories declared twice -----------------------------------------
    fail_on_project = "FAIL_ON_PROJECT_REPOS" in settings_text
    project_repos = bool(re.search(r"allprojects\s*\{", root_text)) and \
        bool(re.search(r"repositories\s*\{", root_text))
    if fail_on_project and project_repos:
        print(f"{BAD} repositories declared twice")
        problems.append(
            "settings.gradle.kts sets RepositoriesMode.FAIL_ON_PROJECT_REPOS, but\n"
            "      " + str(root_build.name) + " also declares allprojects { repositories { … } }.\n"
            "      Gradle then stops with:\n"
            "        Build was configured to prefer settings repositories over\n"
            "        project repositories but repository 'Google' was added by\n"
            "        build file 'android/build.gradle.kts'\n"
            "      Fix: delete the allprojects{repositories{…}} block from the root\n"
            "      build file — settings.gradle.kts already lists google()/mavenCentral().")
    elif fail_on_project:
        print(f"{OK} repositories only in settings")
    elif project_repos:
        print(f"{OK} repositories in the root build file")
    else:
        print(f"{WARN} no repositories found — a fresh sync will fail to resolve")
        notes.append("Add google()/mavenCentral() to settings or the root build file.")

    # 3. local.properties -----------------------------------------------------
    local = android / "local.properties"
    if not local.exists():
        print(f"{BAD} local.properties missing")
        problems.append(
            "android/local.properties is missing. It must contain:\n"
            "        flutter.sdk=<path to your Flutter SDK>\n"
            "        sdk.dir=<path to your Android SDK>\n"
            "      Without it, settings.gradle.kts throws 'flutter.sdk not set'.")
    else:
        props = {}
        for line in read(local).splitlines():
            line = line.strip()
            if line and not line.startswith("#") and "=" in line:
                k, v = line.split("=", 1)
                props[k.strip()] = v.strip()
        for key in ("flutter.sdk", "sdk.dir"):
            value = props.get(key)
            if not value:
                print(f"{BAD} local.properties: {key} not set")
                problems.append(f"Add '{key}=<path>' to android/local.properties.")
                continue
            # On Windows the path is written with escaped backslashes.
            clean = value.replace("\\\\", "\\")
            exists = pathlib.Path(clean).exists()
            print(f"{OK if exists else WARN} local.properties: {key} = {value}"
                  + ("" if exists else "   (not found on this machine)"))
            if not exists:
                notes.append(
                    f"{key} points at a folder that does not exist — Gradle will "
                    f"fail with 'SDK location not found'. Fix the path.")

    # 4. wrapper vs plugin versions ------------------------------------------
    wrapper = android / "gradle/wrapper/gradle-wrapper.properties"
    gradle_version = "?"
    if wrapper.exists():
        m = re.search(r"gradle-([\d.]+)-(?:all|bin)\.zip", read(wrapper))
        if m:
            gradle_version = m.group(1)
            print(f"{OK} gradle wrapper: {gradle_version}")

    agp = re.search(r'com\.android\.application"?\)?\s*version\s*\(?"?([\d.]+)', settings_text)
    kotlin = re.search(r'org\.jetbrains\.kotlin\.android"?\)?\s*version\s*\(?"?([\d.]+)', settings_text)
    if agp:
        print(f"{OK} Android Gradle Plugin: {agp.group(1)}")
    if kotlin:
        print(f"{OK} Kotlin: {kotlin.group(1)}")
    if agp and gradle_version != "?":
        major = int(gradle_version.split(".")[0])
        agp_major = int(agp.group(1).split(".")[0])
        # AGP 9 needs Gradle 9; AGP 8 works on Gradle 8.x.
        if agp_major >= 9 and major < 9:
            print(f"{BAD} AGP {agp.group(1)} needs Gradle 9+, wrapper has {gradle_version}")
            problems.append("Upgrade android/gradle/wrapper/gradle-wrapper.properties "
                            "to gradle-9.3.1-all.zip (or lower the AGP version).")
        elif agp_major == 8 and major >= 10:
            print(f"{WARN} AGP {agp.group(1)} on Gradle {gradle_version} is untested")

    # 5. JDK and Flutter versions --------------------------------------------
    java = shutil.which("java")
    if not java:
        print(f"{BAD} java not on PATH")
        problems.append("No JDK found. AGP needs JDK 17+ (21 recommended). "
                        "Install it, then set JAVA_HOME.")
    else:
        try:
            out = subprocess.run([java, "-version"], capture_output=True,
                                 text=True, timeout=20)
            text = (out.stderr or "") + (out.stdout or "")
            m = re.search(r'version "(\d+)', text)
            if m:
                major = int(m.group(1))
                print(f"{OK if major >= 17 else BAD} JDK {major}")
                if major < 17:
                    problems.append(
                        f"JDK {major} is too old. AGP 9.x requires JDK 17+, and "
                        f"Gradle 9 is tested on 17-21 — install JDK 21 and point "
                        f"JAVA_HOME at it.")
        except (OSError, subprocess.SubprocessError):
            print(f"{WARN} could not read java -version")

    flutter = shutil.which("flutter")
    if flutter:
        try:
            out = subprocess.run([flutter, "--version", "--machine"],
                                 capture_output=True, text=True, timeout=90)
            m = re.search(r'"frameworkVersion"\s*:\s*"([^"]+)"', out.stdout or "")
            if m:
                print(f"{OK} flutter {m.group(1)}")
        except (OSError, subprocess.SubprocessError):
            pass

    # 6. compileSdk sanity ----------------------------------------------------
    app_build = android / "app/build.gradle.kts"
    if app_build.exists():
        text = read(app_build)
        m = re.search(r"compileSdk\s*=?\s*(\d+)", text)
        if m and int(m.group(1)) < 34:
            print(f"{WARN} compileSdk {m.group(1)} — the adaptive icon and the "
                  f"Android 12 splash need 33+")
        elif m:
            print(f"{OK} compileSdk {m.group(1)}")

    # 7. brace balance --------------------------------------------------------
    for path in (android / "build.gradle.kts", android / "app/build.gradle.kts",
                 android / "settings.gradle.kts"):
        if path.exists() and path.suffix == ".kts":
            if braces_balanced(read(path)):
                print(f"{OK} {path.relative_to(android)}: braces balanced")
            else:
                print(f"{BAD} {path.relative_to(android)}: unbalanced braces")
                text = read(path)
                opens, closes = text.count("{"), text.count("}")
                problems.append(
                    f"{path} has {opens} opening and {closes} closing braces "
                    f"— a half-edited paste. Re-copy the whole file.")

    # 6. gradle.properties flags ---------------------------------------------
    gp = android / "gradle.properties"
    if gp.exists():
        text = read(gp)
        if "android.newDsl" in text or "android.builtInKotlin" in text:
            print(f"{OK} gradle.properties has the Flutter template flags")
        if "org.gradle.jvmargs" in text:
            m = re.search(r"org\.gradle\.jvmargs=(.+)", text)
            if m and "-Xmx8G" in m.group(1):
                print(f"{WARN} heap is set to 8G — a 8GB machine will thrash")
                notes.append("Lower org.gradle.jvmargs to -Xmx2G on smaller machines.")

    # ------------------------------------------------------------------------
    print()
    if problems:
        print(f"{len(problems)} problem(s) found:\n")
        for i, problem in enumerate(problems, 1):
            print(f"  {i}. {problem}\n")
        print("After fixing, run:")
        print("    cd android && .\\gradlew.bat --stop && cd ..")
        print("    flutter clean && flutter pub get && flutter run")
        return 1

    print("No setup problems found in the Android project.")
    if notes:
        print("\nWorth knowing:")
        for note in notes:
            print(f"  • {note}")
    print("\nIf Gradle still fails, the console says 'Build file: … line: 1' but the")
    print("real cause is in the *next* block. Copy the text under")
    print("'* What went wrong:' — that is the line to search for.")
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv))
