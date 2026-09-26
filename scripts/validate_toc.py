#!/usr/bin/env python3
"""Verify TOC runtime files exist and the release version matches README and CHANGELOG."""

import re
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
TOC_PATH = ROOT / "ElvUI_mhTags.toc"
README_PATH = ROOT / "README.md"
CHANGELOG_PATH = ROOT / "CHANGELOG.md"


def toc_lines() -> list[str]:
    return TOC_PATH.read_text(encoding="utf-8-sig").splitlines()


def toc_files() -> list[str]:
    files: list[str] = []
    for raw_line in toc_lines():
        line = raw_line.strip()
        if not line or line.startswith("#"):
            continue
        files.append(line.replace("\\", "/"))
    return files


def toc_version() -> str | None:
    for line in toc_lines():
        match = re.match(r"^## Version:\s*(\S+)", line)
        if match:
            return match.group(1)
    return None


def readme_badge_version() -> str | None:
    # shields.io escapes "-" inside badge text as "--".
    match = re.search(r"badge/Version-((?:[^-]|--)+)-", README_PATH.read_text(encoding="utf-8"))
    return match.group(1).replace("--", "-") if match else None


def changelog_version() -> str | None:
    for line in CHANGELOG_PATH.read_text(encoding="utf-8").splitlines():
        match = re.match(r"^## \[([^\]]+)\]", line)
        if match and match.group(1).lower() != "unreleased":
            return match.group(1)
    return None


def main() -> int:
    files = toc_files()
    missing = [path for path in files if not (ROOT / path).is_file()]

    if not files:
        print(f"No runtime files found in {TOC_PATH.name}")
        return 1

    if missing:
        print("Missing TOC runtime files:")
        for path in missing:
            print(f"- {path}")
        return 1

    print(f"Validated {len(files)} runtime files from {TOC_PATH.name}")

    versions = {
        f"{TOC_PATH.name} Version": toc_version(),
        f"{README_PATH.name} badge": readme_badge_version(),
        f"{CHANGELOG_PATH.name} latest release": changelog_version(),
    }
    if None in versions.values() or len(set(versions.values())) != 1:
        print("Release versions disagree:")
        for source, version in versions.items():
            print(f"- {source}: {version}")
        return 1

    print(f"Release version {toc_version()} matches README and CHANGELOG")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
