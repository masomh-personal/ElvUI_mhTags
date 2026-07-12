#!/bin/sh
set -eu

ROOT=$(git rev-parse --show-toplevel)
cd "$ROOT"

echo "Checking Lua formatting..."
if command -v stylua >/dev/null 2>&1; then
	stylua --check .
elif command -v podman >/dev/null 2>&1; then
	podman run --rm \
		--security-opt label=disable \
		--userns=keep-id \
		-v "$ROOT:/workspace:ro" \
		-w /workspace \
		docker.io/johnnymorganz/stylua:2.5.2 \
		/stylua --check .
else
	echo "Error: install StyLua or Podman to run formatting checks." >&2
	exit 1
fi

echo "Linting Lua..."
if command -v luacheck >/dev/null 2>&1; then
	luacheck .
elif command -v podman >/dev/null 2>&1; then
	podman run --rm \
		--security-opt label=disable \
		--userns=keep-id \
		-v "$ROOT:/workspace:ro" \
		-w /workspace \
		ghcr.io/lunarmodules/luacheck:latest .
else
	echo "Error: install Luacheck or Podman to run lint checks." >&2
	exit 1
fi

echo "Validating TOC runtime files..."
python3 scripts/validate_toc.py

echo "Checking uncommitted whitespace..."
git diff --check
git diff --cached --check

echo "All local checks passed."
