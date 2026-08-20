# Project Instructions for AI Agents

This file provides instructions and context for AI coding agents working on this project.

## What this is

The public site for **comehomealabama.com** — Mandy Longshore, RE/MAX of Gulf Shores
(coastal Alabama + NW Florida). Astro 5 + Tailwind v4, deployed to GitHub Pages via
`.github/workflows/deploy.yml` on every push to main (Pages source = Actions; CNAME kept).

**This repo is PUBLIC.** No strategy, client data, calibration data, or recipient
addresses belong here — that private state lives in the operator's private ops repo
(coastal-realty-ops `content-machine/` + `brand/voice-profile.md`).

## The journal pipeline (the Mandy content machine)

`/journal` is the canonical content home. Architecture = producer/lander split:

- **Producer** (LLM, `/mandy-journal` skill on the operator box) writes
  `src/content/journal/<slug>.mdx` + a `.journal-staging/<date>.intent.json` sentinel.
  It never touches git.
- **Lander** `scripts/journal/mandy-land.sh` is the ONLY committer on the journal path:
  re-runs both lints, builds, commits the single MDX to main, pushes, verifies the live
  URL; quarantines to `.journal-quarantine/` on any gate failure.
- **Gates** (fail-closed, no overrides): `scripts/journal/lint-post-voice.py` (voice
  denylist, call-or-text CTA, em-dash budget, tier word bands) and
  `scripts/journal/lint-fair-housing.py` (HARD list blocks publication).
- **Distribution**: `scripts/journal/mandy-posting-packet.sh` (branded HTML packets via
  `mandy-packet-html.cjs`, +24h site-first stagger) + `mandy-calibrate.sh` monthly report.
- **Cadence**: operator crontab — Mon/Wed/Fri 04:30 driver (`mandy-journal-daily.sh`,
  producer chain claude → codex → grok → minimax), daily 05:15 packet sweep, Friday
  digest, monthly calibration. Liveness beats feed the estate dead-man sweep.

Frontmatter contract for journal MDX is the zod schema in `src/content.config.ts` —
title, description (≤200 chars, doubles as social copy), date, community slug, topics,
tier (T1/T2/T3), draft.

## Commands

```bash
pnpm install
pnpm dev          # localhost:4321
pnpm build        # static → dist/ (also the schema gate for journal posts)
pnpm typecheck    # astro check
python3 scripts/journal/lint-post-voice.py src/content/journal/<slug>.mdx
python3 scripts/journal/lint-fair-housing.py src/content/journal/<slug>.mdx
```

<!-- BEGIN BEADS INTEGRATION v:1 profile:minimal hash:ca08a54f -->
## Beads Issue Tracker

This project uses **bd (beads)** for issue tracking. Run `bd prime` to see full workflow context and commands.

### Quick Reference

```bash
bd ready              # Find available work
bd show <id>          # View issue details
bd update <id> --claim  # Claim work
bd close <id>         # Complete work
```

### Rules

- Use `bd` for ALL task tracking — do NOT use TodoWrite, TaskCreate, or markdown TODO lists
- Run `bd prime` for detailed command reference and session close protocol
- Use `bd remember` for persistent knowledge — do NOT use MEMORY.md files

## Session Completion

**When ending a work session**, you MUST complete ALL steps below. Work is NOT complete until `git push` succeeds.

**MANDATORY WORKFLOW:**

1. **File issues for remaining work** - Create issues for anything that needs follow-up
2. **Run quality gates** (if code changed) - Tests, linters, builds
3. **Update issue status** - Close finished work, update in-progress items
4. **PUSH TO REMOTE** - This is MANDATORY:
   ```bash
   git pull --rebase
   bd dolt push
   git push
   git status  # MUST show "up to date with origin"
   ```
5. **Clean up** - Clear stashes, prune remote branches
6. **Verify** - All changes committed AND pushed
7. **Hand off** - Provide context for next session

**CRITICAL RULES:**
- Work is NOT complete until `git push` succeeds
- NEVER stop before pushing - that leaves work stranded locally
- NEVER say "ready to push when you are" - YOU must push
- If push fails, resolve and retry until it succeeds
<!-- END BEADS INTEGRATION -->


## Build & Test

_Add your build and test commands here_

```bash
# Example:
# npm install
# npm test
```

## Architecture Overview

_Add a brief overview of your project architecture_

## Conventions & Patterns

_Add your project-specific conventions here_
