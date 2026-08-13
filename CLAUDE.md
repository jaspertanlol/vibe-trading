# Vibe-Trading — Claude Code on the web notes

Personal trading research agent: Python/FastAPI backend (`agent/`), React
frontend (`frontend/`), CLI (`vibe-trading`), web server (`vibe-trading
serve`), and an MCP server (`vibe-trading-mcp`, 70 tools). See `README.md`
for the full picture and `AGENT_CONTRIBUTOR_GUIDE.md` for agent-facing repo
rules (safety-critical surfaces, test commands, PR expectations) — this file
only covers what's specific to running in a Claude Code cloud/remote session.

## What doesn't work here

- **Docker (README "Path A").** The `docker` CLI is present but there is no
  daemon in this container (`docker info` fails to reach
  `/var/run/docker.sock`). `docker compose up --build` will not work.
- **Browser access to the web UI.** `vibe-trading serve` (port 8899) and the
  Vite dev server (port 5899) start fine, but this is a headless container —
  there's no port-forward to a local browser like a real dev machine gets.
  Drive things via the CLI/TUI or direct tool calls instead (see below).
- **Arbitrary LLM provider APIs, if this environment's network policy is
  "trusted only."** That policy allowlists `*.anthropic.com` and `pypi.org`
  (among others) but blocks e.g. `openrouter.ai`. Check with:
  `curl -sS "$HTTPS_PROXY/__agentproxy/status"` (look at `recentRelayFailures`
  and `noProxy`). If a provider you need is blocked, ask the user to switch
  the environment to full network access.

## Setup (automated)

`.claude/hooks/session-start.sh` (registered in `.claude/settings.json`) runs
`pip install -e ".[dev]"` into `.venv` at repo root on every session start —
this is README "Path B: Local install". It's idempotent and reuses the
cached `.venv` on repeat runs, so it stays fast after the first session.

Manual equivalent, if you ever need to redo it:

```bash
python3 -m venv .venv && source .venv/bin/activate
pip install -e ".[dev]"
```

## Using Vibe-Trading's tools without an LLM key

Almost all of the 70 MCP tools (`agent/mcp_server.py`) are plain,
deterministic Python — backtesting, market data, options pricing, factor
analysis, the 462-alpha Alpha Zoo, the 89 finance skills, shadow-account
analysis, etc. **None of these need an LLM API key.** Only `run_swarm`
(multi-agent workers) and the natural-language `vibe-trading run`/`chat`
loop need one.

Two ways to reach them from a Claude Code session:

1. **Direct Python import (reliable, works mid-session).** The tool
   functions are just importable Python:
   ```bash
   cd agent && source ../.venv/bin/activate
   python3 -c "
   import sys; sys.path.insert(0, '.')
   from mcp_server import list_skills
   print(list_skills())
   "
   ```
   This lets Claude call `backtest`, `get_market_data`, `analyze_options`,
   `alpha_bench`, etc. directly, acting as the reasoning agent itself instead
   of going through a separate LLM-backed vibe-trading process.

2. **MCP registration (`.mcp.json` at repo root, README "Path C").** Points
   at `.venv/bin/vibe-trading-mcp`. A **fresh** Claude Code session/CLI
   invocation against this repo can pick this up (after the usual MCP
   approval prompt) and get the tools natively as `mcp__vibe-trading__*`.
   It does **not** hot-load into a session that's already running — adding
   or editing `.mcp.json` mid-conversation has no effect until the next
   session start. Prefer approach 1 within a single session.

## If you do need a real LLM provider

For `run_swarm` or the natural-language CLI (`vibe-trading run -p "..."`):

```bash
cp agent/.env.example agent/.env
# uncomment one provider block and set its API key
```

`agent/.env` is gitignored — never commit real keys. `LANGCHAIN_PROVIDER=anthropic`
is the safest default here since `*.anthropic.com` is allowlisted even under
the restrictive network policy.

## Test / lint commands

See `AGENT_CONTRIBUTOR_GUIDE.md` for the full list and for which commands
need explicit maintainer approval (live/broker/order-affecting surfaces).
Quick reference:

```bash
source .venv/bin/activate
ruff check agent/                                   # lint
pytest --ignore=agent/tests/e2e_backtest --ignore=agent/tests/test_e2e_harness_v2.py -q   # from agent/
cd frontend && npm ci && npm run build               # frontend build check
```
