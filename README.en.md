# cc-code

> Version: **1.10.0** ｜ English ｜ [简体中文](./README.md)

> A minimalist development workflow system — puts the LLM into a "cognitive sandbox" so it becomes a precise, stable, traceable automated software machine.
> Constitutional principle: **own the result, not the process** (whether the result meets the requirements is the only yardstick).
> Built on four iron rules: **Context Minimization · Decision Serialization · Memory Externalization · active Three Criteria**.

---

## Table of Contents

- [Design Philosophy](#design-philosophy)
- [Core Logic](#core-logic)
- [Orchestration (1.8.0)](#orchestration-180-role--agent-the-main-thread-only-relays)
- [In-place update + retire-by-move (1.7.0)](#in-place-update--retire-by-move-170)
- [Installation](#installation)
- [Full Lifecycle](#full-lifecycle)
- [Quick Start](#quick-start)
- [Codex CLI Support (1.1.0)](#codex-cli-support-110)
- [Optional Enhancement: codegraph](#optional-enhancement-codegraph)
- [Skill List (16)](#skill-list-16)
- [Agents (6)](#agents-6)
- [File Layering (L0~L4)](#file-layering-l0l4)
- [Directory Architecture](#directory-architecture)
- [Role Serialization](#role-serialization)
- [Experience Sediment (1.10.0, fully automatic)](#experience-sediment-fully-automatic)
- [The Only Stop Hook](#the-only-stop-hook)
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
④ Single source of truth for rules ── each rule is written exactly once, on its
   audience's mandatory path; restating it elsewhere is forbidden
   (copies are the precondition for drift; a prompt library has no tests and no CI,
    so drift never raises an error)
⑤ Anti-vibecoding three diseases:
   logic drift → one-way info flow + codegraph never generates intent layer
   redundancy piling → in-place convergent writes + agent-whole-qa redundancy detection
   arrogant skipping → multi-role + separate test/fix contexts
```

Which layer a rule belongs to is settled by three questions (still true for another role → shared section / role-specific → that role's card / a subagent needs it → its own system prompt / it constrains artifact format → that template's header). Decision table in [`docs/ARCHITECTURE.md`](./docs/ARCHITECTURE.md#规则归属单一出处ssot分层--0131-立规).

## Core Logic

### Role Serialization (PM first, then Architect, then Dev, QA)

```
PM ──► Architect ──► Dev ──► QA
(logic)  (contract)   (code)   (acceptance)
```

Each role's must-read / writable / forbidden permissions live only in `templates/Agent.md` §3 (single source; no copy here).

### Orchestration (1.8.0): role = agent, the main thread only relays

```
 Human ◄──────────────► Main thread (orchestrator: plays no role, reads no code, never answers for the human)
                         │  writes only status.md (coords/blockers/next) + appends to backup/milestone-log.md
                         │
   Planning (plan-mvp / plan-feature)        strictly PM first, then Architect
     1. dispatch pm (fresh context) ─ one question at a time ◄──► human's words relayed verbatim to the same pm
            └─ human approves requirements (approval #1) → pm lands prd / ux
     2. dispatch architect (fresh context) ─ asks tech points one by one ◄──► human
            ├─ requirement conflict → restated in business language → human decides → pm hands back a revision summary (no writes in plan mode) → back to architect; after approval, land pm first, then architect
            └─ human approves the design (approval #2) → architect lands project / data / api / §9
   Execution (agent-*)
     dispatch dev ─► dispatch qa ─► FAIL ≤3 rounds ─► still FAIL: hand to human
   Debug (no plan mode; bugs.md is maintained automatically, no approval wait)
     qa reproduces + gathers evidence, writes B-n the moment it reproduces (to-diagnose) ─► dev diagnoses read-only
     ─► main relays to qa, who adds root cause / blast radius / plan
     ├─ pure implementation bug ─► to-fix ─► dev fixes ─► qa retests ─► on PASS qa moves the entry to backup/retired/bugs.md
     └─ contract wrong / requirement wrong / no expected-behaviour source / cannot reproduce ─► to-decide: one question to the human
        ─► after the ruling architect / pm edit the docs (or qa reproduces again) ─► to-fix
```

| agent | Model tier |
| --- | --- |
| `pm` | opus |
| `architect` | opus |
| `dev` | inherit (main session's) |
| `qa` | sonnet |
| `uiux` | inherit (main session's) |
| `curator` | sonnet |

Who writes which file: see `templates/Agent.md` §2 / §3 (single source; not copied here).

Every agent except curator has `memory: project` (stored in the generated project's `.claude/agent-memory/<agent>/`, role-specific lessons only); project conventions are always read from `.cc_code/active/*`, never from memory. On Codex this release only guarantees the generation chain still works (the inherit tier writes no model line and follows the parent session).

### Parallel Lanes (1.6.0): role serialization ≠ single thread

Serialization locks the **role order** and the **dispatch order**, not "one worker per role". Planning splits a phase into independent lanes; execution runs several workers of the same role at once:

```
 Plan (Architect): split phases → split lanes → give each lane its "may write only" paths
                   files several lanes need → a separate "foundation" lane, first
        ▼
 Execute (main):   foundation (single thread)
                     ▼
                   Dev A ┃ Dev B ┃ Dev C      write in parallel
                   ━━━━━━ barrier: all written ━━━━━━
                   QA A  ┃ QA B  ┃ QA C       verify in parallel, report only
                   ━━━━━━ barrier: all verified ━━━━━━
                     ├─ failed lanes → only those go back (≤3 rounds each)
                     └─ all pass → merge regression (union impact + e2e) → phase settles
```

| Unchanged | How it holds |
| --- | --- |
| Dev → QA role order | Between two barriers everyone is the same role |
| Executors never plan | Lanes come only from `project.md` §9; invalid table → single thread |
| One writer per file | Lane subagents only report; who lands the write follows `parallel-lanes.md` |
| One card dispatched at a time | Parallelism lives inside one phase / one increment |

Old projects without lanes run single-threaded automatically. Details: `skills/cc-code/references/parallel-lanes.md`.

#### Parallelism by command

| Command | Parallel? | Unit | Who runs in parallel | Trigger | Max at once |
| --- | --- | --- | --- | --- | --- |
| `plan-*` | ❌ | — | — | Q&A, the owner is present | 1 |
| `agent-mvp` | ⚠️ conditional | lanes | multiple devs, or multiple qas (two batches) | `project.md` §9 has ≥2 lanes for this phase and the check passes | 3 (default) |
| `agent-feature` | ⚠️ conditional | lanes | multiple devs / qas | §9 9.2 has ≥2 lanes for this F-number | 3 (default) |
| `agent-debug` | ❌ | — | — | one bug, one line; splitting loses root cause | 1 |
| `agent-whole-qa` | ✅ by default | module fan-out | multiple qas; multiple devs in fix rounds | right after inventory; Workflow on Claude Code, falls back to multiple Agent calls when unavailable | modules / fix groups ≤3 |
| `just-do-it` | ❌ | — | — | too small to be worth a lane | 1 |
| `deploy` | ❌ | — | — | single serial command | 1 |

**Three things never run at once**: dev and qa (separated by two barriers), two phases, two writers on the same ledger.

### File Layering (know the layer, then the role)

```
┌ L0 Control ─ Agent.md (constitution/permission table)  status.md (coords+milestones) ─ Human/AI ┐
├ L1 Intent  ─ prd.md (per-module logic + rules + acceptance assertions A1..An) ────── PM ───┤
├ L2 Surface ─ ux.md (visual specs + five-state matrix, U-number issuer) ──────────── PM ───┤
├ L3 Impl    ─ project.md  data.md  api.md ─────────────────────────────────── Architect ─┤
├ L4 Accept  ─ gates.md (A+U traceability matrix, standard in prd/ux) ──────────────── QA ───┤
└ backup/    ─ cold archive: ledgers + retired/ verbatim originals (gitignored) ────────────┘
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
               retired content → backup/retired/<source>.md (moved verbatim, nothing lost)
```

**1.10.0:** experience sediment is handed to a new **curator** agent: fully automatic and silent - the owner does nothing, confirms nothing, rules on nothing, and sees exactly one result line in the final report (nothing written when nothing changed).
- After every settlement of an executor (agent-mvp / agent-feature / agent-debug / just-do-it) the orchestrator dispatches curator in the background; qa only marks "consecutive / regression" and the root-cause category on the acceptance matrix, curator runs three gates and files lessons into the right level, architect / dev read the INDEX progressively and report an "adopted experience" line.
- Three libraries share one structure: project `.cc_code/references/`, personal `~/.cc-code/lessons/`, team `~/.cc-code/team/<repo>/` (read-only); append-only, dormant after 7 active days without adoption, archived after 14.
- A new, **only** Stop hook is the safety net (compares timestamps only - no AI, no network) and reminds the main session to dispatch curator if it was forgotten; agents 5 → 6.
- `init` configures everything once: creates the library skeletons and idempotently merges `.claude/settings.local.json` permissions so writing the personal library and pulling the team library never prompt.
- `/cc-code:experience-summary` becomes a manual entry: your words on the spot are handed to curator as-is.
- Codex not adapted yet (generation chain unchanged, verification unbroken); agent-whole-qa not wired in this release.

**1.9.3:** upgrade and migration also keep the single-writer rule - `init` dispatches pm / architect / qa per file to backfill, the orchestrator only sorts and dispatches and never writes; `Agent.md` / `CLAUDE.md` are overwritten by the init script from plugin templates; pm does not read milestone-log.

**1.9.2:** fixes the 1.9.1 landing gap - the orchestrator has no browser tools in `allowed-tools`, so the browser lifecycle now belongs to the first qa (owner, opens) and a wrap-up qa (closer, closes); the qa protocol and Workflow script gain owner/closer roles, report-on-lost-instance without relaunching, and explicit artifact paths; PREFLIGHT auto-detects the single browser tool and `Workflow` joins the tool allowlist; project.md §6 gains a QA data-isolation contract.

**1.9.1:** browser acceptance now reuses a **single instance** - one browser for the whole run; concurrent qa agents still test as before, each owning its own tab and re-selecting it before every browser call, never launching a second instance or closing the whole browser. project.md §6 gains three contract rows (browser tool / instance / artifact dir); the qa agent, inventory flow and Workflow script carry the same protocol.

**1.9.0:** agent-whole-qa now runs on Workflow orchestration - inventory → module fan-out → reduce → fix loop (≤3 rounds), falling back to multiple Agent calls when the tool is unavailable; the three executor descriptions state their parallelism bounds; lane reports use a fixed summary skeleton and single-threaded runs say so; README gains a parallelism-by-command table.

**1.8.2:** a constitutional principle now heads the generated project's `CLAUDE.md` - own the result, not the process: the only yardstick is whether the result meets the requirements; only conclusions are persisted; the owner hears results and impact, never implementation; humans step in only when results miss the requirements or the requirements must change.

**1.8.1:** the debug report to the owner is now four business-language segments (symptom / root cause / blast radius / fix) instead of the old trio - inform only, never persisted; only the conclusions land in B-n (the "impact" field became "blast radius", covering affected features/pages plus the regression test surface).

### In-place update + retire-by-move (1.7.0)

`active/` holds only the project's **latest state and content**. Before writing, triage as below; each role touches only the files it owns:

```
         about to write an active file
                 │
    ┌────────────┼──────────────┬────────────────┐
    ▼            ▼              ▼                ▼
  changed       is new        is retired       unchanged
                           (done/fixed/voided)
    │            │              │                │
    ▼            ▼              ▼                ▼
edit only     insert into    move verbatim to   touch nothing
those lines   its section    backup/retired/    (saves tokens,
              not EOF        then drop from      keeps cache)
    │            │           active              │
    └────────────┴──────┬───────┴────────────────┘
                        ▼
     append 1 row to backup/change-log.md (detail col = retired path)
```

| ⛔ Forbidden | Why |
| --- | --- |
| Rewriting the whole file | Unchanged lines rewritten = wasted tokens + cache miss |
| Appending new content/sections at EOF | One object scattered across N patches; readers must stitch |
| Keeping history in active (old rounds / fixed / voided / strikethrough corpses) | A fat active is re-read in full every session |
| Deleting retired content outright | Not one word may be lost — move to `backup/retired/` first, then drop from active |

> Effect: active's size is driven by **how many rules exist now**, not by how many times it was used.
> `backup/` is gitignored, so size is a non-issue; retired content stays fully readable in `retired/`.

## Installation

```bash
# 1. Add this repo as a marketplace
/plugin marketplace add https://github.com/weiyi88/cc-code

# 2. Install the cc-code plugin
/plugin install cc-code
```

After install you get the `/cc-code:*` command family, 16 skills, 6 companion agents, and one Stop hook.

## Full Lifecycle

```
/cc-code:init          Scaffold (8 templates + bugs.md debug note + migrate scattered files + stamp version
                       + refresh .cc_code/README.md handbook)
                       Old-version fields auto-run upgrade migration (zero deletion)
       ↓
Session open (2 steps)  Read Agent.md (permission table) → status.md (set coords)
       ↓
/cc-code:plan-mvp  ⭐ First action call EnterPlanMode → probe + three-piece-set in plan
                       + per-point conversation until smooth → land five docs (prd/ux/project/data/api)
                       (landing = final, no second review)
       ↓
/cc-code:plan-uiux   (optional, frontend projects) ux.md page list → design.pen visual
                       prototype frames; style stacking: plan-uiux gpt-taste; AI auto-saves
       ↓
/cc-code:agent-mvp  Pure execution (read final docs, Dev→QA, FAIL≤3-round loop, zero mid-run confirmation;
                       lanes in a phase → same role runs in parallel;
                       with pen, Dev runs bottom-up three steps: Export html-tailwind → thin assembly → screenshot diff)
       ↓
/cc-code:agent-whole-qa      Full acceptance (function + redundancy, FAIL≤3-round loop; fixes grouped by file, in parallel)
       ↓
/cc-code:deploy        Launch (reads the deployment contract in project.md, any platform mix;
                       qa smoke-tests production; /cc-code:deploy rollback to revert)

────────── After MVP delivered, feature iteration takes this branch ──────────

/cc-code:plan-feature  ⭐ First action call EnterPlanMode → spec checkup + lock baseline
                           + codegraph blast radius → per-conflict hard-gate ruling
                           + three-piece-set conversation → converge in place (landing = final)
                           + status.md names F-n and new assertion ids
       ↓
/cc-code:agent-feature  Incremental pure execution (increment locate → Dev→QA, affected precise regression; parallel if lanes)

────────── Anytime, bug fixing takes this branch (requirement clear, implementation wrong) ──────────

/cc-code:plan-debug        No plan mode → qa interrogates + reproduces, writes B-n into active/bugs.md the moment
                           it reproduces (to-diagnose) → dev traces the chain read-only (links/radius/test surface)
                           → qa fills root cause / blast radius / plan (to-fix), then main tells you the four segments (symptom / root cause / blast radius / fix) in business language - inform only, no approval wait. Records never wait for approval;
                           only contract wrong / requirement wrong / no expected-behaviour source / cannot reproduce
                           marks the entry to-decide and asks you one question
                           (sticky note; moved to backup/retired/bugs.md once fixed)
       ↓
/cc-code:agent-debug      Bug-fix pure execution (takes only to-fix B-n → Dev→QA, affected precise
                           regression + regression test retained, no full sweep)

────────── Anytime ──────────

/cc-code:experience-summary  Manually add one lesson (your words handed to curator as-is; normally fully automatic, no need to call)
/cc-code:init                Run again after plugin upgrade: field migration + handbook refresh
```

**The main line is 6 skills chained in three pairs**: plan (conversation to final docs) → execute (pure machine) → full acceptance.
The `cc-code` skill manages the runtime protocol (role routing + layering) in the background; `init` is the entry. Only one Stop hook (safety net for experience sediment); all other state is written by AI in-conversation.

## Quick Start

In any project root:

```
/cc-code:init
```

- **New project**: scaffold + stamp version, switch to PM, await requirements.
- **Existing project (no `.cc_code/`)**: back up old `CLAUDE.md` → `.cc_code/backup/YYYY-MM/CLAUDE.md.legacy`; the orchestrator only sorts, dispatching pm / architect / qa per file to split and backfill `active/` per the mapping table; `Agent.md` and root `CLAUDE.md` are overwritten by the init script from plugin templates.
- **Old-version field (has `.cc_code/` but version stamp missing or older)**: auto upgrade migration — **archive → audit → migrate → verify → relocate → stamp**. `init.sh` uses `rm` zero times; old files only `cp` snapshot and `mv` relocate, always recoverable. If the verify gate fails, stop, no stamp; next `init` still judges as pending-upgrade.

> Root `CLAUDE.md` is a pure entry guide (session-open protocol + three iron rules + file index), no business state. Claude Code natively auto-loads it, guiding into the `.cc_code/` state machine.

## Codex CLI Support (1.1.0)

One repo, dual-runtime distribution: `skills/`, `agents/`, `CLAUDE.md` are the **single source** (consumed directly by Claude Code); everything Codex-side is **generated** (by `scripts/sync-codex.sh`, never hand-edit; `scripts/verify-codex.sh` reports drift).

### Install (Codex CLI ≥ 0.149.0)

```bash
codex plugin marketplace add weiyi88/cc-code
codex plugin add cc-code@cc-code-marketplace
```

Project side (run once after field init, distributes the guardrails):

```bash
bash "$CLAUDE_PLUGIN_ROOT/scripts/init.sh" --codex   # or point at scripts/init.sh in this repo
```

`--codex` does three things: `AGENTS.md → CLAUDE.md` symlink (one constitution for both runtimes), `.codex/hooks.json + gate.sh` (plan-mode write interception), `.codex/agents/*.toml` (six role sandboxes; stale toml of agents deleted at source are cleaned up). **On first run codex asks you to review and trust gate.sh in `/hooks` — trust once and it takes effect.**

### The plan cage on Codex

Users type exactly one command (e.g. `$cc-code:plan-mvp build a pomodoro web app`) — arming is done by the AI's engine self-check, zero extra steps:

```
$cc-code:plan-mvp fires
   └─ AI first action self-check: is EnterPlanMode available?
       ├─ Claude Code ──► call EnterPlanMode (unchanged)
       └─ Codex      ──► Bash touch plan-lock itself (guard arms automatically)
                           exit is also AI-run rm; the owner only approves the write list
```

| Layer | Mechanism | Strength |
| :--- | :--- | :--- |
| Automatic | plan-mvp / plan-feature arming is AI-run on trigger (plan-debug does not enter plan mode, so it never arms); the hook blocks all Edit/Write/apply_patch | Engine-level block |
| Hardening | Optionally run built-in `/plan` first (engine-level read-only, double layer) | Engine-level read-only |
| Exit | AI presents write list → owner approves → AI `rm .cc_code/.runtime/plan-lock` | In-conversation consent |

### Known residual gaps (honest list)

- Claude's `allowed-tools` allowlist has no Codex equivalent; role sandboxes (`sandbox_mode`) carry the main permission boundary.
- Claude tool names like `EnterPlanMode` mentioned in skill bodies are ignored by Codex — write safety is backstopped by the guard above; flow safety relies on following the sequence.
- The 16 skill descriptions may be auto-shortened by Codex's context budget (slightly weaker implicit triggering; explicit `$` invocation is unaffected).

## Optional Enhancement: codegraph

[codegraph](https://github.com/colbymchenry/codegraph) is a code knowledge-graph index. cc-code **runs fully without it**; installing upgrades four capabilities:

| Capability | Installed | Not installed (degraded) |
| --- | --- | --- |
| Incremental blast radius | `impact` computes transitive closure, know blast scope from one change | Glob/Grep surface guess, radius underestimated |
| Redundancy detection | Auto-scan dead code / orphan files / duplicate impls | `agent-whole-qa` redundancy basically blind |
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
| `init` | `/cc-code:init` | First run scaffolds the management folder and core docs; existing projects auto-upgrade, zero deletion |
| `cc-code` | auto | Flow steward auto-loaded in projects with `.cc_code/`: plan→dev→test→accept, no shipping until all four steps pass |
| `plan-mvp` | `/cc-code:plan-mvp` | Ask through every requirement, sketch flows and pages, write the spec docs after your OK |
| `plan-feature` | `/cc-code:plan-feature` | Scan existing code for conflicts before adding a feature, list what to change/build, write the plan |
| `plan-uiux` | `/cc-code:plan-uiux` | Paint 2 sample pages to lock style, then paint page by page into `design.pen`, save each after your OK |
| `agent-mvp` | `/cc-code:agent-mvp` | Write code per the approved plan, auto-test, fix until green (max 3 rounds) |
| `agent-feature` | `/cc-code:agent-feature` | Only write code the feature touches, only run the related tests — fast and safe |
| `plan-debug` | `/cc-code:plan-debug` | Trace the bug through the call chain to the root cause; bugs.md is maintained automatically, no approval wait, no code changes |
| `agent-debug` | `/cc-code:agent-debug` | Fix per the plan, run affected tests, all green = fixed |
| `agent-whole-qa` | `/cc-code:agent-whole-qa` | Before launch, drive a browser to click every page and button; FAILs auto-fixed |
| `experience-summary` | `/cc-code:experience-summary` | Manually add one lesson: your words on the spot go to curator, which files them silently (normally experience is sedimented automatically) |
| `short` | `/cc-code:short` | One-sentence answers (≤50 chars) for simple questions, nothing more |
| `just-do-it` | `/cc-code:just-do-it` | Tiny change, one sentence, done: dev writes, qa verifies, one log entry, that's it |
| `deploy` | `/cc-code:deploy` | Ship every component per the deployment contract; only qa's live smoke test counts; one-command rollback |

**Tool Attachments (do work, unrelated to state machine)**

| skill | Purpose |
| --- | --- |
| `project_resume` | Scan the codebase and write the project intro copy for you |
| `login_auto` | A ready-made login suite: password / Google / email code + password reset |

## Agents (6)

Six agents map one-to-one to cc-code roles (**role = agent**; the main thread only orchestrates), **independent of any specific project**; all project conventions defer to `.cc_code/active/project.md`, and test / build / self-check commands come only from its test-infra contract:

| agent | Model | cc-code Role | Responsibility |
| --- | --- | --- | --- |
| `pm` | opus | PM | Asks requirement questions one by one, lands prd/ux once approved; serves plan-mvp / plan-feature |
| `architect` | opus | Architect | codegraph recon + tech Q&A, lands project/data/api and project.md §9 (phases+lanes) and §8 deploy contract once approved |
| `dev` | inherit | Dev | Implements per prd/ux/api/data; self-check commands come from project.md's test-infra contract |
| `qa` | sonnet | QA (gray box) | Writes+runs layered tests, writes gates/bugs/test dir directly, structured FAIL list back to dev; still FAIL after 3 rounds → human decides |
| `uiux` | inherit | UIUX (prototype worker) | Receives a single-page task order → paints P-n/M-n frames via pencil MCP → screenshot self-check → reports frameId; serves plan-uiux |
| `curator` | sonnet | Curator (experience sediment, silent in background) | The only writer of every experience library: after settlement it runs three gates, classifies, appends, dedups, sleeps / archives, rebuilds INDEX; returns one line only; never touches active files or source |

> Agents define "how to do"; cc-code defines "what to do + where"; `.cc_code/active/` is the only coupling interface.

## File Layering (L0~L4)

```
┌ L0 Control ─ Agent.md (constitution/permission table)  status.md (coords+milestones) ─ Human/AI ┐
├ L1 Intent  ─ prd.md (per-module logic + rules + acceptance assertions A1..An) ────── PM ───┤
├ L2 Surface ─ ux.md (visual specs + five-state matrix, U-number issuer) ──────────── PM ───┤
├ L3 Impl    ─ project.md  data.md  api.md ─────────────────────────────────── Architect ─┤
├ L4 Accept  ─ gates.md (A+U traceability matrix, standard in prd/ux) ──────────────── QA ───┤
└ backup/    ─ cold archive: ledgers + retired/ verbatim originals (gitignored) ────────────┘
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
├── agents/           6 agents (pm / architect / dev / qa / uiux / curator)
├── scripts/          init.sh (three-track scaffold + scattered-file migration + upgrade archive/audit/relocate, zero rm)
├── templates/        md skeletons (L0~L4 + bugs.md debug sticky note + experience INDEX / topic skeletons)
├── docs/             ARCHITECTURE.md
└── hooks/            the only Stop hook (safety-net reminder for experience sediment: timestamps only, no AI, no network)
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
    │   └── bugs.md        🐛 Open-bug working context B-n (qa writes; on fix PASS the entry moves verbatim to backup/retired/bugs.md; empty at rest)
    ├── docs/qa/         🔵 Full acceptance reports + element inventory (agent-whole-qa produces)
    ├── test/           ⭐ Test code (source, must be in repo; index base for affected precise regression)
    ├── images/          🔵 Screenshots (init migrates, flat storage)
    ├── scripts/         🔵 Scattered-script archive
    ├── references/      🟢 Project-level experience library (curator maintains it automatically: INDEX + topic files + archive/ + log/, roles read on demand)
    ├── backup/          🧊 Cold data (change-log / milestone-log / retired/ originals / CLAUDE.md.legacy; gitignored)
    │   └── YYYY-MM/     On upgrade: pre-upgrade-<old>/ read-only snapshot + upgrade_audit.md + superseded/ relocated
    └── .cc_code_version 🔖 Field version stamp (decides whether init runs upgrade migration)

Cross-project libraries (outside .cc_code/, created by init):
~/.cc-code/
    ├── lessons/         🟢 Personal library (curator writes, follows the person, same structure as the project library)
    └── team/<repo>/     🟢 Team library (read-only; curator only clones and pulls)
```

## Role Serialization

```
PM ──► Architect ──► Dev ──► QA
(logic)  (contract)   (code)   (acceptance)
```

Each role's must-read / writable / forbidden permissions live only in `templates/Agent.md` §3 (single source; no copy here).

## Experience Sediment (fully automatic)

Experience is sedimented by the **curator** agent, automatically and silently: the owner does nothing, confirms nothing, rules on nothing, and sees only one result line in the final report (nothing written when nothing changed). `/cc-code:experience-summary` is demoted to a manual entry you normally never need.

### Who files it · when

| Role | Part in experience sediment |
| --- | --- |
| **curator** | The **only writer** of every library: three gates, classify, append, dedup, sleep / archive, rebuild INDEX |
| **qa** | Only marks "consecutive / regression" and the root-cause category on the same assertion row of the `gates.md` acceptance matrix; never files |
| **Orchestrator** | Only dispatches and forwards reports verbatim; never writes a library |
| **architect / dev** | Read experience as self-check questions; the completion report must carry one "adopted experience" line |
| **pm / uiux** | Read no experience library |

```
 Executor settles (all pass / three rounds still failing, handed to the owner)
        │
        ▼
 Orchestrator dispatches curator in background ── forwards verbatim: this round's QA report,
        │                                           dev fix report, adopted-experience lines
        ▼
 ① write start timestamp
 ② record adoptions / invalidations, ③ record active day
 ④ three gates ─► ⑤ five level questions ─► ⑥ dedup / restore / append (mechanical self-check first)
 ⑦ dormancy / archive sweep ─► ⑧ pull team libraries (at most once per active day) ─► ⑨ rebuild INDEX
        │
        ▼
 One result line ─► merged into the final report (nothing written if no change)

 Safety net: orchestrator forgot ─► Stop hook sees acceptance record newer than the start timestamp ─► reminds to dispatch once
```

agent-whole-qa is not wired in this release.

### Three gates: worth writing?

```
 A mark on some assertion row of the acceptance matrix
        │
 ① Trigger? "consecutive" (failed last round, failed again) or "regression" (passed last round, failed now) ──no──► ignore
        │yes
 ② Root cause? "implementation defect" or "design omission" ──no (test itself wrong / environment / third party / spec ambiguity)──► not filed
        │yes
 ③ Evidence? a root cause · a source change · reproducible ──any missing──► skip (mark stays for next time)
        │all present
        ▼
      classify
```

A processing log keeps the same mark from being handled twice. Evidence comes from the forwarded reports plus what curator may read: `active/gates.md`, `active/bugs.md`, `docs/qa/`; ⛔ never `backup/`.

### How to classify: three levels

| Level | Location | Who writes |
| --- | --- | --- |
| Project | `.cc_code/references/` | curator |
| Personal | `~/.cc-code/lessons/` | curator |
| Team | `~/.cc-code/team/<repo>/` | read-only; curator only clones and pulls (at most once per active day, time-boxed, failures skipped silently) |

```
 A lesson worth writing
        │
 Do collaborators need it? ──yes──► Project
        │no
 Still true without project nouns? ──no──► Project
        │yes
 Technology's own behavior, or this project's choice? ──project's choice──► Project
        │technology's behavior
 Would a different business hit it again? ──no──► Project
        │yes
 Would the answer flip under a different business / compliance / cost goal? ──yes (trade-off)──► Project only
        │no
        ▼
     Personal          (when unsure, always Project)
```

### Structure: progressive disclosure

All three levels share one structure:

| File | Role |
| --- | --- |
| `INDEX.md` | Entry point. One line per topic: topic, when to read, live count, dormant entries; a derived file regenerated by curator every run |
| `<topic>.md` | One file per topic, English kebab-case name (e.g. `async-queue.md`, `db-timezone.md`); same topic appends to the same file, an identical constraint is not added again - only one adoption is logged |
| `archive/<same-topic>.md` | Archived entries, full text preserved |
| `log/` | Append-only logs: adoption log, active-day log (project library also keeps a processing log and the start timestamp; personal library keeps the team-pull record) |

Each entry has five fields, not a wasted word, no code:

| Field | Content |
| --- | --- |
| Title | `<project>-<role>-<date>` (same-day duplicate gets -2) |
| Background | What was being done |
| Input | Conditions and dependencies at the time |
| Output | What was expected |
| What happened | What actually went wrong and why |
| Constraint | One sentence that must be obeyed from now on; scope goes in parentheses at the end |

Forbidden: assertion numbers, measured / expected values, secrets, accounts, customer names, internal addresses, code. Curator self-checks mechanically before writing and rewrites any hit.

### Append-only · lifecycle

Entry files are only appended to - never overwritten or deleted - by appending at the end, safe for concurrent sessions. An **active day** = a day on which a curator settlement ran in the library's scope (the personal library counts any project).

| State | Criterion | Action |
| --- | --- | --- |
| Normal | Adopted within the last 7 active days (or just written) | — |
| Dormant | 7 consecutive active days without adoption | Marked in INDEX, readers may skip it; adoption revives it |
| Archived | 14 consecutive active days without adoption, or reported "not applicable / invalid" | Moved to the same-topic file under `archive/` (curator's only move; full text preserved); when the topic recurs, curator checks the archive first and restores if it can |

### Who reads · when

| Who | When | Reads |
| --- | --- | --- |
| architect | First dispatch at step 6 of plan-mvp / plan-feature; when plan-debug routes a contract error to it | The project / personal / team INDEX (skipped if absent), opens a topic only on a hit. Project level feeds the design directly; personal / team level is written into `project.md` §5 special constraints when the plan lands |
| dev | When the executor's dispatch explicitly lists it | Project `references/INDEX.md` + `project.md` (including cross-project experience transcribed by architect) |
| qa / pm / uiux | — | No experience library |

Both architect's and dev's completion reports must carry one line "adopted experience: <entry title> / none / not applicable: <entry title>"; the orchestrator asks dev to supplement if it is missing and forwards these lines verbatim to curator (with the settlement material at executor settlement; after an architect lands a plan in plan-*, a separate adoption-only background curator run); adoptions are logged, "not applicable" is archived immediately.

Priority: active files > project > personal > team; conflicts between experiences are reported on that line, never auto-resolved; experience is a self-check question, never the acceptance yardstick.

### Team import · one-time setup · review

- **Team import**: give a git address in the conversation and say it is team experience; the orchestrator dispatches curator to clone it into `~/.cc-code/team/<repo>/`. No new command.
- **init configures it once**: creates the project and personal library skeletons and idempotently merges the required permissions into the generated project's `.claude/settings.local.json` (machine-local, not committed; existing settings are not broken), so writing the personal library and pulling the team library never prompt.
- **Post-launch review**: if the total adoption count is still 0 thirty days after launch, review or retire the mechanism.

## The Only Stop Hook

cc-code has exactly **one** Stop hook, with a single job: the safety net for experience sediment. All other `.cc_code/` files are still written by AI in-conversation.

```
 Session wrap-up (Stop)
      │
      ▼
 Already inside a hook continuation? ──yes──► exit at once (loop guard)
      │no
 Project has .cc_code/ and a start timestamp? ──no──► exit silently
      │yes
 Acceptance record newer than curator's start timestamp? ──no──► exit silently
      │yes
      ▼
 Give the main session a non-error hint ─► orchestrator dispatches curator once in background (ignore if already dispatched)
```

- **Very fast**: compares two file timestamps only - no AI, no network.
- **No false alarms**: curator's very first step writes the start timestamp.
- **Only a reminder**: never errors, never blocks the main session.

> Design history: early versions had a Stop Hook for `errors.md` cold slicing. From 0.5.0 `errors.md` was abolished (pitfalls go into commit messages / git blame, natural trace), the Hook lost its only job and was removed - fitting "one thing does only its own logic": no logic, don't keep it. From 1.10.0 experience sediment runs as a background agent, and "was curator really dispatched after settlement" is a **mechanically decidable** question (two timestamps), so this single hook returns, doing the safety net only.

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
