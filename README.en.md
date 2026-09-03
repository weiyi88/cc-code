# cc-code

> Version: **0.13.0** ｜ English ｜ [简体中文](./README.md)

> A minimalist development workflow system — puts the LLM into a "cognitive sandbox" so it becomes a precise, stable, traceable automated software machine.
> Built on four iron rules: **Context Minimization · Decision Serialization · Memory Externalization · active Three Criteria**.

---

## Table of Contents

- [Design Philosophy](#design-philosophy)
- [Core Logic](#core-logic)
- [Installation](#installation)
- [Full Lifecycle](#full-lifecycle)
- [Quick Start](#quick-start)
- [Optional Enhancement: codegraph](#optional-enhancement-codegraph)
- [Skill List (16)](#skill-list-16)
- [Agents (3)](#agents-3)
- [File Layering (L0~L4)](#file-layering-l0l4)
- [Directory Architecture](#directory-architecture)
- [Role Serialization](#role-serialization)
- [Experience Sediment (references)](#experience-sediment-references)
- [No-Hook Design](#no-hook-design)
- [Scattered-File Migration](#scattered-file-migration)
- [Onboarding](#onboarding)
- [License](#license)

---

## Design Philosophy

LLMs writing code suffer three diseases: **forgetting the goal mid-way, context rot, and hallucinating from memory**.
cc-code's prescription: **externalize all memory, state, and rules into `.cc_code/` static files**. The AI locates itself by reading files per protocol each session, not by brain capacity.

```
① Memory/log/state fully externalized ── not in the agent, in .cc_code/ static files
② Responsibility verticalized ── each role owns one layer, clean context, no overreach
③ active three criteria ── latest + most complete + purest (hard iron rule)
④ Anti-vibecoding three diseases:
   logic drift → one-way info flow + codegraph never generates intent layer
   redundancy piling → in-place convergent writes + whole-qa redundancy detection
   arrogant skipping → multi-role + separate test/fix contexts
```

## Core Logic

### Role Serialization (only one role active at a time)

```
PM ──► Architect ──► Dev ──► QA
(logic)  (contract)   (code)   (acceptance)
```

Each role is locked by the `active/Agent.md` routing table: "must-read / writable / forbidden-to-read", no overreach.

| Role | Owns | Writable | Forbidden |
| --- | --- | --- | --- |
| PM | L1+L2 | prd, ux | src/, project, data, api |
| Architect | L3 | project, data, api | src/ business code |
| Dev | code | src/, test dir | gates |
| QA | L4 (gray box) | gates, test dir | unrelated history code |

### File Layering (know the layer, then the role)

```
┌ L0 Control ─ Agent.md (constitution/permission table)  status.md (coords+milestones) ─ Human/AI ┐
├ L1 Intent  ─ prd.md (per-module logic + rules + acceptance assertions A1..An) ────── PM ───┤
├ L2 Surface ─ ux.md (visual specs + five-state matrix, U-number issuer) ──────────── PM ───┤
├ L3 Impl    ─ project.md  data.md  api.md ─────────────────────────────────── Architect ─┤
├ L4 Accept  ─ gates.md (A+U traceability matrix, standard in prd/ux) ──────────────── QA ───┤
└ backup/    ─ cold archive (AI moves in on demand, not in repo by default) ─────────────────┘
```

### Information Flow Iron Rule (one-way, violation = failure)

```
   L1 Intent ──► L2 Surface ──► L3 Impl ──► Code
    ▲                                          │
    └────────── L4 Acceptance ◄────────────────┘

  ① L4 uses only L1/L2 as ruler, never L3/code
     otherwise QA degrades to "verifying code with code", acceptance fails
  ② codegraph only calibrates L3 (fact layer), never generates L1/L2/L4
  ③ Dev/QA forbidden to edit prd/ux/api to pass tests
  ④ Standard and result never in the same file: standard in L1/L2 (PM writes),
     result in L4 (QA writes). Writer of standard ≠ judge of result → checks balance
```

### active Three Criteria

`active/` is the single source of truth, must **always** stay latest, most complete, purest:

```
   Latest    ── each object described in only one place in active, and it's the current state
               ⛔ no new "## Increment F-n" sections → in-place rewrite of the section

   Complete  ── every dimension to verify has a permanent stable number, denominator computable
               A-number (prd.md §1.5 main table) = business logic / chain / interface
               U-number (ux.md §2.3 matrix) = UI layout / interaction five-states

   Purest    ── every line answers "what is it now", not "how it was decided"
               process artifacts not persisted (change-log one line) · per-round acceptance details → docs/qa/
               history via git (.cc_code is version-controlled, no extra snapshots)
```

## Installation

```bash
# 1. Add this repo as a marketplace
/plugin marketplace add https://github.com/weiyi88/cc-code

# 2. Install the cc-code plugin
/plugin install cc-code
```

After install you get the `/cc-code:*` command family, 16 skills, and 3 companion agents.

## Full Lifecycle

```
/cc-code:init          Scaffold (8 templates + bugs.md debug note + migrate scattered files + stamp version
                       + refresh .cc_code/README.md handbook)
                       Old-version fields auto-run upgrade migration (zero deletion)
       ↓
Session open (2 steps)  Read Agent.md (lock role) → status.md (set coords)
       ↓
/cc-code:plan-prd-mvp  ⭐ First action call EnterPlanMode → probe + three-piece-set in plan
                       + per-point conversation until smooth → land five docs (prd/ux/project/data/api)
                       (landing = final, no second review)
       ↓
/cc-code:agent-to-mvp  Pure execution (read final docs, Dev→QA, FAIL≤3-round loop, zero mid-run confirmation)
       ↓
/cc-code:whole-qa      Full acceptance (function + redundancy, FAIL≤3-round loop)
       ↓
Deploy                 /cc-code:vercel_supabase or /cc-code:cf_online

────────── After MVP delivered, feature iteration takes this branch ──────────

/cc-code:plan-prd-feature  ⭐ First action call EnterPlanMode → spec checkup + lock baseline
                           + codegraph blast radius → per-conflict hard-gate ruling
                           + three-piece-set conversation → converge in place (landing = final)
                           + status.md names F-n and new assertion ids
       ↓
/cc-code:agent-to-feature  Incremental pure execution (increment locate → Dev→QA, affected precise regression)

────────── Anytime, bug fixing takes this branch (requirement clear, implementation wrong) ──────────

/cc-code:debug-plan        ⭐ First action call EnterPlanMode → interrogate the bug
                           + codegraph trace the chain (links/radius/test surface) + ruling gate
                           (touches contract/requirement → refuse, redirect to planning)
                           + three-piece-set confirmation → land B-n into active/bugs.md
                           (sticky note, deleted once fixed)
       ↓
/cc-code:debug-qa-dev      Bug-fix pure execution (locate B-n → Dev→QA, affected precise
                           regression + regression test retained, no full sweep)

────────── Anytime ──────────

/cc-code:experience-summary  Pitfalls/retros → distill design rules → references/ library
/cc-code:init                Run again after plugin upgrade: field migration + handbook refresh
```

**The main line is 6 skills chained in three pairs**: plan (conversation to final docs) → execute (pure machine) → full acceptance.
The `cc-code` skill manages the runtime protocol (role routing + layering) in the background; `init` is the entry. No Stop Hook; all state written by AI in-conversation.

## Quick Start

In any project root:

```
/cc-code:init
```

- **New project**: scaffold + stamp version, switch to PM, await requirements.
- **Existing project (no `.cc_code/`)**: back up old `CLAUDE.md` → `.cc_code/backup/YYYY-MM/CLAUDE.md.legacy`; AI splits and merges into `active/` per mapping table, then overwrites root `CLAUDE.md` with the entry template.
- **Old-version field (has `.cc_code/` but version stamp missing or older)**: auto upgrade migration — **archive → audit → migrate → verify → relocate → stamp**. `init.sh` uses `rm` zero times; old files only `cp` snapshot and `mv` relocate, always recoverable. If the verify gate fails, stop, no stamp; next `init` still judges as pending-upgrade.

> Root `CLAUDE.md` is a pure entry guide (session-open protocol + three iron rules + file index), no business state. Claude Code natively auto-loads it, guiding into the `.cc_code/` state machine.

## Optional Enhancement: codegraph

[codegraph](https://github.com/colbymchenry/codegraph) is a code knowledge-graph index. cc-code **runs fully without it**; installing upgrades four capabilities:

| Capability | Installed | Not installed (degraded) |
| --- | --- | --- |
| Incremental blast radius | `impact` computes transitive closure, know blast scope from one change | Glob/Grep surface guess, radius underestimated |
| Redundancy detection | Auto-scan dead code / orphan files / duplicate impls | `whole-qa` redundancy basically blind |
| Precise regression | `affected` computes only-needed tests via import graph | Full run, high QA time cost |
| Contract calibration | Architect auto-checks `api.md` / `data.md` impl status | Manual Grep, error-prone |

### Fully Silent Design (zero cognitive load)

```
Install once   /cc-code:init detects missing → popup with benefits → user approves → install
               npm i -g @colbymchenry/codegraph   ⚠️ scoped package name
Build index    init builds silently in background, never blocks entry
Stay fresh     codegraph built-in watcher auto-syncs + daemon catch-up on revival
               ⛔ user never needs manual sync / index
Anomaly        reports one line (corrupt index / rebuild suggestion); zero output when healthy
```

`init.sh` only probes, never installs (modifying global env is high-risk and scripts can't interact); the user decides.

### Iron Rule: codegraph answers "what is", never "what should be"

| Role | Permission | Notes |
| --- | --- | --- |
| PM | ❌ fully forbidden | Inferring intent from status = L1/L2 polluted by L3 = system failure |
| Architect | ✅ fully open | Calibrate L3 contracts; `explore`/`node`/`files`/`callers`/`callees`/`impact` |
| Dev | ⚠️ read-only locating | Find existing impls to avoid reinventing; never override contracts |
| QA | ⚠️ dual-limited | Only for finding entry points / computing regression scope; **never as a requirement ruler** |

### Prerequisites for `affected` precise regression

The test-infrastructure contract is registered in `active/project.md` §6. Three iron rules:

1. **Test code must be in git** — codegraph respects `.gitignore`; ignored tests aren't indexed → `affected` permanently fails. What should be ignored is test **artifacts** (`coverage/` / `*.png`), not test **code**. `init`'s new `.cc_code/test/` is not ignored by default.
2. **Tests must import the source under test** — static `import` ✅ dynamic `await import()` ✅ pure HTTP-interface scripts ⛔ (no import edge to trace).
3. **Non-standard names must register a glob** — defaults match `*.spec.*` / `*.test.*` / `__tests__/`; others need `--filter`.

## Skill List (16)

**Framework Core (manages flow)**

| skill | Trigger | Purpose |
| --- | --- | --- |
| `init` | `/cc-code:init` | **Entry + upgrade** three-track init (new/latest/old-upgrade-migrate); judgment-chain migrates scattered files; upgrade runs "archive→audit→migrate→verify→relocate", **zero deletion** |
| `cc-code` | auto | **Runtime protocol** role routing + file layering + state-machine constraints |
| `plan-prd-mvp` | `/cc-code:plan-prd-mvp` | **MVP planner** (first action EnterPlanMode, per-point conversation in plan mode until logic is smooth; produces five docs prd/ux/project/data/api, landing = final) |
| `plan-prd-feature` | `/cc-code:plan-prd-feature` | **Incremental requirement planner** (post-MVP iteration: spec checkup + codegraph blast radius + per-conflict hard gate + converge in place into L1/L2/L3, landing = final + status.md names F-n) |
| `agent-to-mvp` | `/cc-code:agent-to-mvp` | **MVP pure-execution orchestration** (read final docs, Dev→QA + qa→dev loop, zero mid-run confirmation, whole-qa wrap-up) |
| `agent-to-feature` | `/cc-code:agent-to-feature` | **Incremental pure-execution orchestration** (increment locate → Dev→QA + qa→dev loop, affected precise regression, no full sweep) |
| `debug-plan` | `/cc-code:debug-plan` | **Bug diagnostician** (first action EnterPlanMode; in plan mode: interrogate + codegraph trace + ruling gate + three-piece-set confirmation → land B-n into `bugs.md`; never edits requirements, never writes code) |
| `debug-qa-dev` | `/cc-code:debug-qa-dev` | **Bug-fix pure-execution orchestration** (locate B-n → Dev→QA + qa→dev loop, affected precise regression, PASS hard condition = regression test exists and passes, no full sweep) |
| `whole-qa` | `/cc-code:whole-qa` | **Full acceptance + fix loop** (per-page/button/interface + redundancy detection, FAIL≤3-round loop) |
| `experience-summary` | `/cc-code:experience-summary` | **Project-level experience sediment** (pitfalls/retros → distill rules → user review → land `references/[role]-[domain]-references.md` + INDEX on-demand) |
| `short` | `/cc-code:short` | Minimal reply (when no thinking needed, ≤50 chars) |

**Tool Attachments (do work, unrelated to state machine)**

| skill | Purpose |
| --- | --- |
| `project_resume` | Read real tech stack, generate standardized project intro copy |
| `login_auto` | Supabase Auth + Resend universal login system |
| `vercel_supabase_deployment` | Vercel + Supabase one-click deploy |
| `cf_online` | Deploy Next.js to Cloudflare Pages (Edge) |
| `next2taro` | Next.js UI → Taro mini-program conversion |

## Agents (3)

Three agents bind to cc-code role serialization, **independent of any specific project**; all project conventions defer to `.cc_code/active/project.md`:

| agent | Model | cc-code Role | Responsibility |
| --- | --- | --- | --- |
| `prd-plan` | opus | PM + Architect | Requirements→spec→tech plan; produces prd/ux/project/data/api (phase plans live inside project.md, serving plan-prd-mvp / plan-prd-feature) |
| `dev` | haiku | Dev | Implement code per spec + three-layer tests; self-check lint/tsc/test/e2e |
| `qa` | sonnet | QA (gray box) | Write+run three-layer tests (logic/api/browser), structured FAIL list back to dev, ≤3-round loop |

> Agents define "how to do"; cc-code defines "what to do + where"; `.cc_code/active/` is the only coupling interface.

## File Layering (L0~L4)

```
┌ L0 Control ─ Agent.md (constitution/permission table)  status.md (coords+milestones) ─ Human/AI ┐
├ L1 Intent  ─ prd.md (per-module logic + rules + acceptance assertions A1..An) ────── PM ───┤
├ L2 Surface ─ ux.md (visual specs + five-state matrix, U-number issuer) ──────────── PM ───┤
├ L3 Impl    ─ project.md  data.md  api.md ─────────────────────────────────── Architect ─┤
├ L4 Accept  ─ gates.md (A+U traceability matrix, standard in prd/ux) ──────────────── QA ───┤
└ backup/    ─ cold archive (AI moves in on demand, not in repo by default) ─────────────────┘
```

### Information Flow Iron Rule (one-way, violation = failure)

```
   L1 Intent ──► L2 Surface ──► L3 Impl ──► Code
    ▲                                          │
    └────────── L4 Acceptance ◄────────────────┘

  ① L4 uses only L1/L2 as ruler, never L3/code
     otherwise QA degrades to "verifying code with code", acceptance fails
  ② codegraph only calibrates L3 (fact layer), never generates L1/L2/L4
  ③ Dev/QA forbidden to edit prd/ux/api to pass tests
  ④ Standard and result never in the same file: standard in L1/L2 (PM writes),
     result in L4 (QA writes). Writer of standard ≠ judge of result → checks balance
```

## Directory Architecture

### Plugin side (github.com/weiyi88/cc-code)

```
cc-code/
├── .claude-plugin/   marketplace.json + plugin.json
├── skills/           16 skill directories
├── agents/           3 agents (prd-plan / dev / qa)
├── scripts/          init.sh (three-track scaffold + scattered-file migration + upgrade archive/audit/relocate, zero rm)
├── templates/        9 md skeletons (L0~L4 + bugs.md debug sticky note)
├── docs/             ARCHITECTURE.md
└── no hooks/         (removed in 0.5.0, no automated mechanical work)
```

### Project side (generated by /cc-code:init)

```
project-root/
├── CLAUDE.md              🧭 Entry guide (Claude natively auto-loads, pure protocol no business state)
└── .cc_code/
    ├── README.md          🧭 Handbook (refreshed each init: project logic / Skill / usage / examples)
    ├── active/          🔴 Hot data (read every conversation, layered L0~L4)
    │   ├── Agent.md       L0 role routing table / supreme constitution
    │   ├── status.md      L0 current coords + milestones (AI self-manages length)
    │   ├── prd.md         L1 per-module business logic + rules + acceptance assertions (PM)
    │   ├── ux.md          L2 visual specs + interaction five-state matrix (PM)
    │   ├── project.md     L3 tech constitution (Architect)
    │   ├── data.md        L3 data contract interface ↔ DB columns (Architect)
    │   ├── api.md         L3 interface contract method/path/in/out/error codes (Architect)
    │   └── gates.md       L4 A+U acceptance traceability matrix + unclosed FAILs (QA, Dev forbidden)
    │   └── bugs.md        🐛 Open-bug working context B-n (debug-plan writes; deleted once fixed; empty at rest)
    ├── docs/qa/         🔵 Full acceptance reports + element inventory (whole-qa produces)
    ├── test/           ⭐ Test code (source, must be in repo; index base for affected precise regression)
    ├── images/          🔵 Screenshots (init migrates, flat storage)
    ├── scripts/         🔵 Scattered-script archive
    ├── references/      🟢 Project-level experience library (experience-summary produces, INDEX + role on-demand)
    ├── backup/          🧊 Cold data (CLAUDE.md.legacy / migration_manifest / needs_review; not in repo by default)
    │   └── YYYY-MM/     On upgrade: pre-upgrade-<old>/ read-only snapshot + upgrade_audit.md + superseded/ relocated
    └── .cc_code_version 🔖 Field version stamp (decides whether init runs upgrade migration)
```

## Role Serialization

```
PM ──► Architect ──► Dev ──► QA
(logic)  (contract)   (code)   (acceptance)
```

Each role is locked by the `active/Agent.md` routing table: "must-read / writable / forbidden-to-read", no overreach.

| Role | Owns | Writable | Forbidden |
| --- | --- | --- | --- |
| PM | L1+L2 | prd, ux | src/, project, data, api |
| Architect | L3 | project, data, api | src/ business code |
| Dev | code | src/, test dir | gates |
| QA | L4 (gray box) | gates, test dir | unrelated history code |

## Experience Sediment (references)

**Design experience** exposed during pitfalls/troubleshooting/plan retros is sedimented into project-level references via `/cc-code:experience-summary`:

```
/cc-code:experience-summary
       ↓
Distill "must-answer questions + design rules" → user review → land
       ↓
.cc_code/references/[role]-[domain]-references.md
  e.g.: architect-bull-redis-queue-references.md
       ↓
INDEX.md registers one line "when to read" → role scans index on task, reads only on hit (on-demand, not all)
```

- **Project-level**: follows the project, not into the plugin or global.
- **Refined**: only "how to think/act during design/acceptance", ≤30 lines, no narrative trace.
- **Exit value**: every rule must be actionable — can veto a plan based on it.

## No-Hook Design

cc-code **uses no Stop Hook**. All `.cc_code/` files are written by AI in-conversation; no automated mechanical work.

> Design history: early versions had a Stop Hook for `errors.md` cold slicing. From 0.5.0 `errors.md` was abolished (pitfalls go into commit messages / git blame, natural trace), the Hook lost its only job and was removed. Fits "one thing does only its own logic" — no logic, don't keep it.

## Scattered-File Migration

`/cc-code:init` cleans project-root scattered files with a "default don't move" judgment chain — better to miss than to miskill:

```
root file ──► ① protected whitelist? ──► ② git-tracked? ──► ③ referenced? ──► ④ temp-looking name?
               (any hit → SKIP)                              (then move)
                                                                ↓ none match
                                                            keep in place + log needs_review.md
```

The old "default move" would miskill `setup.py`/`manage.py`/`AGENTS.md`/`build.sh` infra — reversed.

## Onboarding

After each project init, `.cc_code/README.md` generates a **handbook** (project logic / Skill list / usage / examples), and **auto-refreshes to the latest version each `/cc-code:init`** — collaborators unfamiliar with cc-code can just read it, no need to browse this repo.

## License

MIT
