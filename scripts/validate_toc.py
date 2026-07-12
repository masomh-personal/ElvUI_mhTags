#!/usr/bin/env python3
"""Verify that every runtime file listed in the addon TOC exists."""

from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
TOC_PATH = ROOT / "ElvUI_mhTags.toc"


def toc_files() -> list[str]:
    files: list[str] = []
    for raw_line in TOC_PATH.read_text(encoding="utf-8-sig").splitlines():
        line = raw_line.strip()
        if not line or line.startswith("#"):
            continue
        files.append(line.replace("\\", "/"))
    return files


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
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
