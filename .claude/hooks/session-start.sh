#!/bin/bash
set -euo pipefail

# Provisions the Python backend (agent/) for Claude Code on the web sessions
# so pytest/ruff/vibe-trading-ai are ready without manual setup.
#
# Docker is NOT usable in these sessions (docker CLI present, no daemon), so
# this mirrors README "Path B: Local install" rather than docker compose.

cd "$CLAUDE_PROJECT_DIR"

if [ ! -d .venv ]; then
  python3 -m venv .venv
fi

# shellcheck disable=SC1091
source .venv/bin/activate

pip install -q -e ".[dev]"

echo "export PATH=\"$CLAUDE_PROJECT_DIR/.venv/bin:\$PATH\"" >> "$CLAUDE_ENV_FILE"
echo "export VIRTUAL_ENV=\"$CLAUDE_PROJECT_DIR/.venv\"" >> "$CLAUDE_ENV_FILE"
