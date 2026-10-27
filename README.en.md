# cc-code

> Version: **1.12.1** ｜ English ｜ [简体中文](./README.md)

> A minimalist development workflow system — puts the LLM into a "cognitive sandbox" so it becomes a precise, stable, traceable automated software machine.
> Constitutional principle: **own the result, not the process** (whether the result meets the requirements is the only yardstick).
> Built on four iron rules: **Context Minimization · Decision Serialization · Memory Externalization · active Three Criteria**.

---

## Table of Contents

- [Design Philosophy](#design-philosophy)
- [Core Logic](#core-logic)
- [Orchestration (1.8.0)](#orchestration-180-role--agent-the-main-thread-only-relays)
- [In-place update + retire-by-move (1.7.0)](#in-place-update--retire-by-move-170)
- [Frontend & Visual (1.11.0)](#frontend--visual-110)
- [Installation](#installation)
- [Full Lifecycle](#full-lifecycle)
- [Quick Start](#quick-start)
- [Codex CLI Support (1.1.0)](#codex-cli-support-110)
- [Optional Enhancement: codegraph](#optional-enhancement-codegraph)
- [Skill List (17)](#skill-list-17)
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

### Role Serialization (pm → uiux → architect → dev → qa)

```
pm ──► uiux ──► architect ──► dev ──► qa
(logic) (layout+look) (contract)  (code)  (acceptance)
```

Each role's must-read / writable / forbidden permissions live only in `templates/Agent.md` §3 (single source; no copy here).
uiux appears on the planning side only (`plan-mvp` / `plan-feature` / `plan-uiux`) and writes two files: `ux.md` (interaction and layout) and `design.md` (style and look). It never writes project code and never appears in any `agent-*` command. Style implementation is done by dev; restyle implementation is done by `agent-uiux`.

### Orchestration (1.8.0): role = agent, the main thread only relays

```
 Human ◄──────────────► Main thread (orchestrator: plays no role, reads no code, never answers for the human)
                         │  writes only status.md (coords/blockers/next + the "Style:" line) + appends to backup/milestone-log.md
                         │
   Planning (plan-mvp / plan-feature)       strictly pm → uiux → architect
     1. dispatch pm (fresh context) ─ one question at a time ◄──► human's words relayed verbatim to the same pm
            ├─ infers which ends exist and each end's form, plus the default stack and the one component-library family → writes them into the requirement summary (no questionnaire, "I picked this… say if you want it changed")
            └─ human approves requirements & prototypes (approval #1) → pm lands prd; uiux lands ux.md (page list / ASCII prototypes / testids / five states / breakpoints / flow)
     2. dispatch architect (fresh context) ─ asks tech points one by one ◄──► human
            ├─ requirement conflict → restated in business language → human decides → pm / uiux hand back a revision summary (no writes in plan mode) → back to architect
            └─ human approves the design (approval #2) → architect lands project / data / api / §9
   Style gate (plan-uiux, frontend projects)
     dispatch uiux ─ direction cards (only for marketing/brand forms when the human gave no direction) → design.md draft → style board
            └─ the human says "定了" (the only visual gate) → design.md locked → agent-mvp's visual foundation
   Execution (agent-*)
     dispatch dev ─► dispatch qa (three logic layers + visual fourth layer) ─► FAIL ≤3 rounds ─► still FAIL: hand to human
   Restyle (plan-uiux mode two ─► agent-uiux)
     qa current-state checkup ─► uiux target design.md ─► before/after board ─► "定了" ─► agent-uiux lands it
   Debug (no plan mode; bugs.md is maintained automatically, no approval wait)
     qa reproduces + gathers evidence, writes B-n the moment it reproduces (to-diagnose) ─► dev diagnoses read-only
     ─► main relays to qa, who adds root cause / blast radius / plan
     ├─ pure implementation bug ─► to-fix ─► dev fixes ─► qa retests ─► on PASS qa moves the entry to backup/retired/bugs.md
     └─ contract wrong / requirement wrong / visual spec wrong / no expected-behaviour source / cannot reproduce ─► to-decide: one question to the human
        ─► after the ruling architect / pm / uiux edit the docs (or qa reproduces again) ─► to-fix
```

| agent | Model tier |
| --- | --- |
| `pm` | opus |
| `architect` | opus |
| `dev` | inherit (main session's) |
| `qa` | sonnet |
| `uiux` | opus |
| `curator` | sonnet |

Who writes which file: see `templates/Agent.md` §2 / §3 (single source; not copied here).

Every agent except curator has `memory: project` (stored in the generated project's `.claude/agent-memory/<agent>/`, role-specific lessons only); project conventions are always read from `.cc_code/active/*`, never from memory. On Codex this release only guarantees the generation chain still works (the inherit tier writes no model line and follows the parent session; uiux's opus tier maps to gpt-5.4 + effort high).

**Owner participation points (the only ones in the whole flow)**:

| Moment | What you do | What you don't |
| :--- | :--- | :--- |
| **Requirements & prototypes approval** (plan-mvp / plan-feature) | Review pm's requirement summary (ends / forms / default stack / family) + uiux's page prototypes; approve once | Tech details, visual values |
| **Tech approval** (plan-mvp / plan-feature) | Review architect's design; approve once | Page look |
| **Style "定了"** (plan-uiux, the only visual gate) | Review the style board and say "定了" to lock; max 3 rounds per direction | Code implementation |
| **Direction cards** (conditional) | Only for marketing/brand forms with no direction given: pick from recommended 1 + contrasting 2; saying nothing uses the recommendation | Specific color values |
| **Collection board** (after wrap-up and new pages; does not block) | Look at qa's "human-only" aesthetic issues (VS); comments optional | Blocking release (VS never blocks) |

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
| `agent-uiux` | ⚠️ conditional | lanes | multiple devs / qas | ≥2 lanes inside this restyle scope; runtime visual checks run only in merge regression | 3 (default) |
| `agent-debug` | ❌ | — | — | one bug, one line; splitting loses root cause | 1 |
| `agent-whole-qa` | ✅ by default | module fan-out | multiple qas; multiple devs in fix rounds | right after inventory; Workflow on Claude Code, falls back to multiple Agent calls when unavailable | modules / fix groups ≤3 |
| `just-do-it` | ❌ | — | — | too small to be worth a lane | 1 |
| `deploy` | ❌ | — | — | single serial command | 1 |
| `pr` | ❌ | — | — | single serial command | 1 |

**Three things never run at once**: dev and qa (separated by two barriers), two phases, two writers on the same ledger.

### File Layering (know the layer, then the role)

```
┌ L0 Control ─ Agent.md (constitution/permission table)  status.md (coords / blockers / next + Style line) ─ Human/AI ┐
├ L1 Intent  ─ prd.md (per-module logic + rules + assertions A1..An + requirement summary) ──── PM ───┤
├ L2 Surface ─ ux.md (interaction & layout + five-state matrix, U-number issuer) ──────────── uiux ──┤
│              design.md (design spec: color/type/spacing/shape/motion/per-end mapping) ───── uiux ──┤
├ L3 Impl    ─ project.md  data.md  api.md ─────────────────────────────────── Architect ┤
├ L4 Accept  ─ gates.md (A+U+V traceability matrix, standard in prd/ux/design) ──────────── QA ───┤
└ backup/    ─ cold archive: ledgers + retired/ verbatim originals (gitignored) ────────────┘
```

### Information Flow Iron Rule (one-way, violation = failure)

```
   L1 Intent ──► L2 Surface (ux interaction/layout + design spec) ──► L3 Impl ──► Code
    ▲                                                                            │
    └──────────────── L4 Acceptance (A + U + V) ◄────────────────────────────────┘

  ① L4 uses only L1/L2 as ruler (L2 includes the design spec), never L3/code
     otherwise QA degrades to "verifying code with code", acceptance fails
  ② codegraph only calibrates L3 (fact layer), never generates L1/L2/L4
  ③ Dev/QA forbidden to edit prd/ux/design/api to pass tests
  ④ Standard and result never in the same file: standard in L1/L2 (pm writes prd,
     uiux writes ux/design), result in L4 (qa writes)
     writer of standard ≠ judge of result → checks balance
  ⑤ V-scale source = design.md values × ui-gates rules; V ids are issued in gates.md §2.4
```

### active Three Criteria

`active/` is the single source of truth, must **always** stay latest, most complete, purest:

```
   Latest    ── each object described in only one place in active, and it's the current state
               ⛔ no new "## Increment F-n" sections → in-place rewrite of the section

   Complete  ── every dimension to verify has a permanent stable number, denominator computable
               A-number (prd.md §1.5 main table) = business logic / chain / interface
               U-number (ux.md §2.3 matrix) = UI layout / interaction five-states
               V-number (gates.md §2.4 V section) = visual (design.md values × ui-gates rules; page chapter + group code)

   Purest    ── every line answers "what is it now", not "how it was decided"
               process artifacts not persisted (change-log one line) · per-round acceptance details → docs/qa/
               retired content → backup/retired/<source>.md (moved verbatim, nothing lost)
```

**1.12.0:** adds `/cc-code:pr` — hands accepted changes to an external review platform: a conventional commit → push a feature branch → open a merge request with the description (what changed / how it was tested / how to roll back / linked spec / blast radius, plus a decision log for high risk), then stops. qa gains "submission evidence": it reruns the commands for this increment's assertions and writes the raw output and screenshots into an evidence file, which the orchestrator pastes into the description verbatim. The orchestrator's single explicit exception becomes "version-control operations"; delivery happens only inside the pr command and never touches the main branch. Rejections and production bugs still go through the debug / feature chains. The entry file `CLAUDE.md` is trimmed to 100 lines. Skills 16 → 17, agents stay 6.

**1.12.1:** faster style locking. Contrast is now computed while the values are written (the design spec gains a "text × background pairing table"; a failing pair is fixed by changing the color value, with no render-and-redo loop). The uiux pre-lock self-check gets a fixed order (overflow first, then the remaining groups, accessibility last as a recheck); repair rounds recheck only what failed, and screenshots are taken once at the final check. Repair rounds are capped at 3; past that, uiux hands back the blocker and a recommended fix for the owner, and never locks with known violations.

**1.11.0:** the full frontend UI/UX chain ships — pm infers ten possible frontend forms from the owner's product sketch (no questionnaire), with React + Next.js + the shadcn family as defaults; one project uses exactly one component-library family and one `active/design.md` (the visual half of L2, written by uiux), whose values feed each end's theme. Adds `plan-uiux` (mode one: settle style / mode two: restyle; the only visual gate is the owner saying "定了") and `agent-uiux` (turns a settled-but-unimplemented style into code); uiux moves to opus and appears on the planning side only. qa gains a **visual fourth layer** (VH/VM/VS three-level verdicts, screenshot baselines, theme drift, collection board), and `agent-mvp`'s first phase is fixed as the **visual foundation**. The pen main chain is demoted to an optional medium for direction cards (an old `design.pen` stays in place, never read, written or converted). Skills 15 → 16, agents stay 6, template skeletons 9 → 10.

**1.10.1:** removed `/cc-code:experience-summary`: lessons are filed only by curator, automatically, from failures that really happened in acceptance; there is no manual entry any more (manual filing skipped the three gates, let unverified lessons in, and broke the zero-manual rule). Skills 16 → 15.

**1.10.0:** experience sediment is handed to a new **curator** agent: fully automatic and silent - the owner does nothing, confirms nothing, rules on nothing, and sees exactly one result line in the final report (nothing written when nothing changed).
- After every settlement of an executor (agent-mvp / agent-feature / agent-debug / just-do-it) the orchestrator dispatches curator in the background; qa only marks "consecutive / regression" and the root-cause category on the acceptance matrix, curator runs three gates and files lessons into the right level, architect / dev read the INDEX progressively and report an "adopted experience" line.
- Three libraries share one structure: project `.cc_code/references/`, personal `~/.cc-code/lessons/`, team `~/.cc-code/team/<repo>/` (read-only); append-only, dormant after 7 active days without adoption, archived after 14.
- A new, **only** Stop hook is the safety net (compares timestamps only - no AI, no network) and reminds the main session to dispatch curator if it was forgotten; agents 5 → 6.
- `init` configures everything once: creates the library skeletons and idempotently merges `.claude/settings.local.json` permissions so writing the personal library and pulling the team library never prompt.
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

## Frontend & Visual (1.11.0)

> Goal: the generated project's frontend loses its AI smell, gains taste, and is visually aligned (elements line up on the grid, edges, baselines and spacing).
> Single source of truth: verdicts / rule ids / thresholds = `skills/cc-code/references/ui-gates.md`; forms / default stack / families / three knobs / translation table = `skills/cc-code/references/frontend-forms.md`; loop protocol = `skills/cc-code/references/dev-qa-loop.md`.

### Five-stage chain

```
pm ──► uiux ──► architect ──► dev ──► qa
(infer ends/forms) (ux.md + design.md) (family/visual infra) (theme/pages) (visual fourth layer)
   │                 │                       │                    │                  │
 §0 summary        L2 two files          project.md §1.1/§6/§9   theme=generated    V section + baseline + board
                 (planning side only)    (never reads design.md)  (never hand-edited) (only verdict writer)
```

| Role | Only does | Never does |
| :--- | :--- | :--- |
| pm | Infers which ends exist and each end's form from the product sketch; writes the default stack and family into `prd.md` §0 | Send a questionnaire, write visual values, read `ux.md` / `design.md` |
| uiux | Writes `ux.md` (layout and interaction) and `design.md` (style and look); produces direction cards and the board in `plan-uiux` | Write project code, appear in any `agent-*`, touch `status.md` / `gates.md` |
| architect | Writes `project.md` §1.1 family / §6 visual infrastructure / §9 visual-foundation phase | Read `design.md` (visual values are not its business) |
| dev | **Generates** each end's theme files from `design.md`, implements pages, builds the visual foundation | Hand-edit theme artifacts, hardcode colors outside the theme entry, mix a second family |
| qa | Visual fourth layer: writes the V section, visual tests, screenshot baselines (exclusive), collection board | Edit `design.md` to pass, treat VS as blocking |

### Ten forms · default stack · one family

| Item | Rule |
| :--- | :--- |
| Ten forms | Marketing landing page / SaaS or Web App productivity tool / B2B admin / content & docs portal / cross-platform native app / mobile H5 marketing microsite / hybrid app / cross-compiled mini program / native mini program / no frontend |
| First-release scope | Four web forms + mobile H5 (hybrid app counts as H5); native app is not promised (visual section says "unverifiable"); mini programs only register the driver-tool contract slot, the rule pack is deferred |
| Default stack | React + Next.js (never asked unless the owner requests otherwise); docs default to a Next.js docs framework; a pure internal heavy admin that only needs speed may switch to Ant Design |
| One family | Exactly one component-library family per project (shadcn by default), each end using the family's matching version; if no family covers every end → pm states the consequence in §0 and asks the owner, never assembles a second family |
| One design spec | `active/design.md` is the project's only visual source of truth; per-end differences go only into §9 theme mapping, values feed each end's theme entry; dev-generated theme files are artifacts and must never be hand-edited |
| One-line criterion | Still true after swapping the skin → `ux.md`; changes with the skin → `design.md` |

### Two modes · visual three-level gates (start / 定了 / baseline)

```
 plan-uiux (owner present)                          agent-uiux (pure machine)
 ─────────────────                                ────────────────
 Mode one: settle style (new project)              Only takes "Style: settled-unimplemented"
   direction cards (conditional) → design.md draft   dev regenerates the theme + adjusts look/layout
   → style board → self-check → owner says "定了"     qa full five-state regression + all-page visual + baseline diff
   → locked → agent-mvp                             ≤3 rounds; PASS → freeze a new baseline → board
 Mode two: restyle (launched UI)
   qa current-state checkup → uiux target design.md
   → before/after board → "定了" → restyle-pending → agent-uiux
```

| Gate | Content |
| :--- | :--- |
| ① Start gate (per phase) | This phase touches pages and `design.md` is unlocked → the executor **refuses** and points to `plan-uiux`; pure-backend / no-UI phases pass and are marked "not applicable"; an old project's cold-start exemption is granted **once** |
| ② The only visual gate | Only the owner saying "定了" locks `design.md`; max 3 rounds per direction, a direction change restarts the count, still undecided → stop and hand to the owner |
| ③ Baseline gate | qa freezes screenshot baselines only after PASS; **no freeze on a failing round**; differences inside scope → new candidates (marked "not visually inspected by the owner"), outside scope → regression |

**Three check timings** (fixed names): current-state checkup (qa, mode two) / pre-lock (uiux self-check; visual-foundation qa re-check) / post-development (qa, every executor). The real visual verdicts start at "pre-lock · re-check".

### Visual fourth layer: how qa judges

| Verdict | Prefix | Blocks | Enters denominator | Destination |
| :--- | :--- | :--- | :--- | :--- |
| Blocking | `VH` | Yes | Yes | `gates.md` §2.4 V section → Critical Failures → back to dev (≤3 rounds) |
| Minor | `VM` | No | Yes (with its group row) | Row + Minor Failures |
| Human judgement | `VS` | No | No | **Collection board** (`.cc_code/docs/qa/`), the owner looks |

- **Machine checks are written as test-runner tests** (Playwright) committed under `.cc_code/test/visual/`; the Playwright browser tool is only for exploratory evidence; performance only via the Lighthouse CLI.
- **The visual model gives evidence, never verdicts**: its output may only feed VS leads and the collection board; it never blocks.
- Nine group codes: 01 design values (pre-lock) / 02 dependencies & source / 03 color & theme consistency / 04 type & typography / 05 layout & composition / 06 visual alignment / 07 text & content / 08 motion / 09 responsive & accessibility & performance & baseline.

### Visual foundation · baseline ownership · collection board · dual-viewport smoke

| Item | Rule |
| :--- | :--- |
| Visual foundation | `project.md` §9 **first phase is fixed**: theme entry + global shell + component gallery (a **non-shipping** route in the project); business pages come after it, and no business lane starts before the theme passes the visual gate |
| Baseline ownership | Screenshot baseline `.cc_code/test/visual/baseline/` and the allowed-value set: **qa writes exclusively, in git**; only the component gallery and board pages are compared (fixed data), split per "browser + OS" |
| Collection board | Produced by qa, read by the owner, **never blocks**; delivered after wrap-up and after new pages |
| Dual-viewport smoke | After `deploy`, qa captures the home page + one main-flow page at **390 / 1440** and samples performance at the same page/viewport; evidence only, no new thresholds |
| Directory ownership | `.cc_code/design/` (uiux: direction cards, board, screenshots) / `.cc_code/test/visual/` (qa: visual tests) / `.cc_code/test/visual/baseline/` (qa exclusive: baselines) / `.cc_code/docs/qa/` (qa: per-round reports and collection board) |
| Ignore policy | Ignore transient artifacts only (`docs/qa/artifacts/`, `coverage/`, `test-results/`); ⛔ never ignore screenshots with a global `*.png` / `screenshots/` wildcard; ⛔ the design directory and baselines must be committed |

### Visual boundaries of other commands

| Command | What it does visually |
| :--- | :--- |
| `agent-mvp` / `agent-feature` | Judge the start gate per phase; dev references theme values only and uses one family; qa checks affected pages × viewports × light-dark × five states after development |
| `agent-uiux` | Restyle only: dev regenerates the theme and adjusts look/layout; qa full five-state regression + all-page visual + baseline diff; stops and hands to the owner if flow / five states / interfaces are touched |
| `agent-whole-qa` | All pages × viewports × light-dark; the visual combination sub-row records coverage only and never multiplies into the V main row; the board never blocks |
| `agent-debug` | Visual bugs follow the same chain; a fix passes only when the regression test exists and passes |
| `just-do-it` | When frontend files are touched, only a **static scan** of the ui-gates rules: record only, no verdict, no blocking, not in the denominator |
| `deploy` | Home page + one main-flow page × 390 / 1440 screenshots and performance sampling (same as the dual-viewport smoke) |
| `login_auto` | Login page color / type / spacing / radius / shadow come only from the project theme and chosen family |

---

## Installation

```bash
# 1. Add this repo as a marketplace
/plugin marketplace add https://github.com/weiyi88/cc-code

# 2. Install the cc-code plugin
/plugin install cc-code
```

After install you get the `/cc-code:*` command family, 17 skills, 6 companion agents, and one Stop hook.

## Full Lifecycle

```
/cc-code:init          Scaffold (9 canonical skeletons + bugs.md debug note + migrate scattered files + stamp version
                       + design dir and screenshot-baseline dir + refresh .cc_code/README.md handbook)
                       Old-version fields auto-run upgrade migration (zero deletion)
       ↓
Session open (2 steps)  Read Agent.md (permission table) → status.md (set coords + the "Style:" line)
       ↓
/cc-code:plan-mvp  ⭐ First action call EnterPlanMode → probe + three-piece-set in plan
                       pm infers ends/forms plus the default stack and family (no questionnaire)
                       → uiux writes page prototypes → [approval #1: requirements & prototypes]
                       → architect asks tech points → [approval #2: tech]
                       → land five docs (prd/ux/project/data/api; design.md is left to plan-uiux)
       ↓
/cc-code:plan-uiux   (mandatory for frontend) Mode one: direction cards (conditional) → design.md draft
                       → style board → owner says "定了" (the only visual gate) → locked
       ↓
/cc-code:agent-mvp  Pure execution (read final docs, Dev→QA, FAIL≤3-round loop, zero mid-run confirmation;
                       lanes in a phase → same role runs in parallel, runtime visual checks only in merge regression;
                       first phase is the visual foundation: theme + global shell + component gallery; later pages reference the theme only)
       ↓
/cc-code:agent-whole-qa      Full acceptance (assertions + five states + elements + interfaces + visual fourth layer,
                       FAIL≤3-round loop; fixes grouped by file, in parallel; the collection board never blocks)
       ↓
/cc-code:pr            Deliver to the review platform (conventional commit → push feature branch → open a merge
                       request with the description, then stop; for projects on an external pipeline, which reviews and merges)
       ↓
/cc-code:deploy        Launch (reads the deployment contract in project.md, any platform mix; qa smoke-tests
                       production with 390 / 1440 screenshots and performance sampling; rollback to revert)

────────── After MVP delivered, feature iteration takes this branch ──────────

/cc-code:plan-feature  ⭐ First action call EnterPlanMode → spec checkup + lock baseline
                           + codegraph blast radius → per-conflict hard-gate ruling
                           + new-page layout in two tiers (reuse locked values: no gate but register / new values: back to plan-uiux)
                           + converge in place (landing = final)
                           + status.md names F-n and new assertion ids
       ↓
/cc-code:agent-feature  Incremental pure execution (increment locate → Dev→QA, affected precise regression; parallel if lanes)

────────── A launched UI needs a new look (requirements unchanged) ──────────

/cc-code:plan-uiux     Mode two: restyle: qa current-state checkup (screenshots + machine checks) → uiux target design.md
                       → before/after board → owner says "定了" → status "settled-unimplemented"
       ↓
/cc-code:agent-uiux    Land it: dev regenerates the theme + adjusts look/layout; qa full five-state regression + all-page visual
                       + baseline diff (≤3 rounds); stops and hands to the owner if flow/states/interfaces are touched

────────── Anytime, bug fixing takes this branch (requirement clear, implementation wrong) ──────────

/cc-code:plan-debug        No plan mode → qa interrogates + reproduces, writes B-n into active/bugs.md the moment
                           it reproduces (to-diagnose) → dev traces the chain read-only (links/radius/test surface)
                           → qa fills root cause / blast radius / plan (to-fix), then main tells you the four segments (symptom / root cause / blast radius / fix) in business language - inform only, no approval wait. Records never wait for approval;
                           only contract wrong / requirement wrong / visual spec wrong / no expected-behaviour source / cannot reproduce
                           marks the entry to-decide and asks you one question
                           (sticky note; moved to backup/retired/bugs.md once fixed)
       ↓
/cc-code:agent-debug      Bug-fix pure execution (takes only to-fix B-n → Dev→QA, affected precise
                           regression + regression test retained, no full sweep; visual bugs follow the same chain)

────────── Anytime ──────────

/cc-code:init                Run again after plugin upgrade: field migration + handbook refresh
```

**The main line is 8 skills in four pairs**: plan-mvp ⇄ agent-mvp, plan-feature ⇄ agent-feature, plan-uiux ⇄ agent-uiux, plan-debug ⇄ agent-debug — plan (conversation to final docs) → execute (pure machine) → full acceptance. `plan-uiux` mode one hands off to `agent-mvp`'s visual foundation; mode two restyle hands off to `agent-uiux`.
The `cc-code` skill manages the runtime protocol (role routing + layering) in the background; `init` is the entry. Only one Stop hook (safety net for experience sediment); all other state is written by AI in-conversation.

## Quick Start

In any project root:

```
/cc-code:init
```

- **New project**: scaffold + stamp version, switch to PM, await requirements.
- **Existing project (no `.cc_code/`)**: back up old `CLAUDE.md` → `.cc_code/backup/YYYY-MM/CLAUDE.md.legacy`; the orchestrator only sorts, dispatching pm / uiux / architect / qa per file to split and backfill `active/` per the mapping table (`prd`→pm, `ux`/`design`→uiux, `project/data/api`→architect, `gates/bugs`→qa); `Agent.md` and root `CLAUDE.md` are overwritten by the init script from plugin templates.
- **Frontend projects**: `init` creates `.cc_code/design/` (direction cards and boards) and `.cc_code/test/visual/baseline/` (screenshot baselines); both are committed. The upgrade track runs a mechanical frontend probe: with no frontend, `design.md` is created as a skeleton marked "not applicable (no frontend)" and uiux is not dispatched.
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
- The 17 skill descriptions may be auto-shortened by Codex's context budget (slightly weaker implicit triggering; explicit `$` invocation is unaffected). The new `pr` command's explicit gate is produced by the generation chain, and `verify-codex.sh` checks gate coverage for every command.

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

1. **Test code must be in git** — codegraph respects `.gitignore`; ignored tests aren't indexed → `affected` permanently fails. What should be ignored is test **artifacts** (`coverage/` / `test-results/` / `.cc_code/docs/qa/artifacts/`), not test **code**. `init`'s new `.cc_code/test/` is not ignored by default; neither may be the visual tests `.cc_code/test/visual/`, the baselines `baseline/`, or the design directory `.cc_code/design/` — ⛔ never use a global `*.png` / `screenshots/` wildcard to ignore screenshots.
2. **Tests must import the source under test** — static `import` ✅ dynamic `await import()` ✅ pure HTTP-interface scripts ⛔ (no import edge to trace).
3. **Non-standard names must register a glob** — defaults match `*.spec.*` / `*.test.*` / `__tests__/`; others need `--filter`.

## Skill List (17)

**Framework Core (manages flow)**

| skill | Trigger | Purpose |
| --- | --- | --- |
| `init` | `/cc-code:init` | First run scaffolds the management folder and core docs; existing projects auto-upgrade, zero deletion |
| `cc-code` | auto | Flow steward auto-loaded in projects with `.cc_code/`: plan→dev→test→accept, no shipping until all four steps pass |
| `plan-mvp` | `/cc-code:plan-mvp` | New project: pm asks through requirements and infers ends/forms (no questionnaire), uiux drafts page prototypes; after [requirements & prototypes approval] architect asks tech points and lands docs after [tech approval] |
| `plan-feature` | `/cc-code:plan-feature` | Scans existing code and the locked visual spec for conflicts before adding a feature; new pages follow two tiers (locked values: no gate but register / new values, components or motifs: back to `plan-uiux`) |
| `plan-uiux` | `/cc-code:plan-uiux` | Settle the frontend style: direction cards (conditional) → `design.md` draft → style board; only the owner saying "定了" locks it. Restyling a launched UI also runs here (mode two, qa checks first) |
| `agent-mvp` | `/cc-code:agent-mvp` | Write code per the approved plan: first phase is the visual foundation (theme + global shell + component gallery), later pages reference theme values only; Dev→QA, fix until green (≤3 rounds) |
| `agent-uiux` | `/cc-code:agent-uiux` | Turn a "settled but unimplemented" style into code: dev regenerates the theme and adjusts look/layout; qa runs full five-state regression + all-page visual + baseline diff (≤3 rounds) |
| `agent-feature` | `/cc-code:agent-feature` | Only write code the feature touches, only run the related tests — fast and safe |
| `plan-debug` | `/cc-code:plan-debug` | Trace the bug through the call chain to the root cause (including visual spec errors); bugs.md is maintained automatically, no approval wait, no code changes |
| `agent-debug` | `/cc-code:agent-debug` | Fix per the plan, run affected tests, all green = fixed; visual bugs follow the same chain and require the regression test to exist and pass |
| `agent-whole-qa` | `/cc-code:agent-whole-qa` | Before launch, drive a browser to click every page and button (including the visual fourth layer); FAILs auto-fixed |
| `short` | `/cc-code:short` | One-sentence answers (≤50 chars) for simple questions, nothing more |
| `just-do-it` | `/cc-code:just-do-it` | Tiny change, one sentence, done: dev writes, qa verifies, one log entry; frontend files get a static scan only (record only) |
| `deploy` | `/cc-code:deploy` | Ship every component per the deployment contract; only qa's live smoke test counts (including 390 / 1440 screenshots and performance sampling); one-command rollback |
| `pr` | `/cc-code:pr` | One click to deliver: accepted changes get a conventional commit, a pushed feature branch and a merge request with the five-part description; evidence comes only from qa's measured output |

**Tool Attachments (do work, unrelated to state machine)**

| skill | Purpose |
| --- | --- |
| `project_resume` | Scan the codebase and write the project intro copy for you |
| `login_auto` | A ready-made login suite: password / Google / email code + password reset; the login page look comes only from the project theme |

## Agents (6)

Six agents map one-to-one to cc-code roles (**role = agent**; the main thread only orchestrates), **independent of any specific project**; all project conventions defer to `.cc_code/active/project.md`, and test / build / self-check commands come only from its test-infra contract:

| agent | Model | cc-code Role | Responsibility |
| --- | --- | --- | --- |
| `pm` | opus | PM | Asks requirement questions one by one; infers which ends exist and each end's form and writes the default stack and family into `prd.md` §0 (no questionnaire); lands `prd.md` only once approved. Serves plan-mvp / plan-feature; never reads `ux.md` / `design.md` |
| `architect` | opus | Architect | codegraph recon + tech Q&A, lands project/data/api plus project.md §1.1 (component family), §6 (test & visual infrastructure), §8 (deploy contract), §9 (phases + lanes; first phase is the visual foundation); never reads `design.md` |
| `dev` | inherit | Dev | Implements per prd/ux/design/api/data; **generates** each end's theme files from `design.md` (artifacts, never hand-edited), builds the visual foundation, references theme values only; self-check commands come from project.md's test-infra contract |
| `qa` | sonnet | QA (gray box) | Writes+runs layered tests, writes gates/bugs/test dir directly; **visual fourth layer**: V section, visual tests, screenshot baselines (exclusive), collection board; structured FAIL list back to dev; still FAIL after 3 rounds → human decides |
| `uiux` | opus | UIUX (L2 two-file author) | Writes `ux.md` (form table / page list / ASCII prototypes / testids / five states / breakpoints / flow) and `design.md` (style and look); produces direction cards, style board and screenshots in `plan-uiux`; **no project code**, appears only in plan-mvp / plan-feature / plan-uiux |
| `curator` | sonnet | Curator (experience sediment, silent in background) | The only writer of every experience library: after settlement it runs three gates, classifies, appends, dedups, sleeps / archives, rebuilds INDEX; returns one line only; never touches active files, source or the visual section |

> Agents define "how to do"; cc-code defines "what to do + where"; `.cc_code/active/` is the only coupling interface.

## File Layering (L0~L4)

```
┌ L0 Control ─ Agent.md (constitution/permission table)  status.md (coords / blockers / next + Style line) ─ Human/AI ┐
├ L1 Intent  ─ prd.md (per-module logic + rules + assertions A1..An + requirement summary) ──── PM ───┤
├ L2 Surface ─ ux.md (interaction & layout + five-state matrix, U-number issuer) ──────────── uiux ──┤
│              design.md (design spec: color/type/spacing/shape/motion/per-end mapping) ───── uiux ──┤
├ L3 Impl    ─ project.md  data.md  api.md ─────────────────────────────────── Architect ┤
├ L4 Accept  ─ gates.md (A+U+V traceability matrix, standard in prd/ux/design) ──────────── QA ───┤
└ backup/    ─ cold archive: ledgers + retired/ verbatim originals (gitignored) ────────────┘
```

### Information Flow Iron Rule (one-way, violation = failure)

```
   L1 Intent ──► L2 Surface (ux interaction/layout + design spec) ──► L3 Impl ──► Code
    ▲                                                                            │
    └──────────────── L4 Acceptance (A + U + V) ◄────────────────────────────────┘

  ① L4 uses only L1/L2 as ruler (L2 includes the design spec), never L3/code
     otherwise QA degrades to "verifying code with code", acceptance fails
  ② codegraph only calibrates L3 (fact layer), never generates L1/L2/L4
  ③ Dev/QA forbidden to edit prd/ux/design/api to pass tests
  ④ Standard and result never in the same file: standard in L1/L2 (pm writes prd,
     uiux writes ux/design), result in L4 (qa writes)
     writer of standard ≠ judge of result → checks balance
  ⑤ V-scale source = design.md values × ui-gates rules; V ids are issued in gates.md §2.4
```

## Directory Architecture

### Plugin side (github.com/weiyi88/cc-code)

```
cc-code/
├── .claude-plugin/   marketplace.json + plugin.json
├── skills/           17 skill directories
├── agents/           6 agents (pm / architect / dev / qa / uiux / curator)
├── scripts/          init.sh (three-track scaffold + scattered-file migration + upgrade archive/audit/relocate, zero rm) / sync-codex.sh / verify-codex.sh
├── templates/        md skeletons (L0~L4 nine items (incl. design.md) + bugs.md debug sticky note + experience INDEX / topic skeletons)
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
    │   ├── status.md      L0 current coords / blockers / next + "Style:" line (main thread writes; milestones in backup/milestone-log.md)
    │   ├── prd.md         L1 per-module business logic + rules + assertions + §0 requirement summary (PM)
    │   ├── ux.md          L2 interaction & layout + five-state matrix (uiux)
    │   ├── design.md      L2 design spec (color/type/spacing/shape/motion/component look/per-end mapping; uiux)
    │   ├── project.md     L3 tech constitution (Architect; §1.1 component family / §6 visual infra / §9 visual foundation)
    │   ├── data.md        L3 data contract interface ↔ DB columns (Architect)
    │   ├── api.md         L3 interface contract method/path/in/out/error codes (Architect)
    │   ├── gates.md       L4 A+U+V acceptance traceability matrix (incl. §2.4 visual section) + unclosed FAILs (QA, Dev forbidden)
    │   └── bugs.md        🐛 Open-bug working context B-n (qa writes; on fix PASS the entry moves verbatim to backup/retired/bugs.md; empty at rest)
    ├── design/          🎨 Direction cards / style boards / board screenshots (uiux writes, not project code, **in git**)
    ├── docs/qa/         🔵 Full acceptance reports + collection board + evidence artifacts (agent-whole-qa / qa produce)
    ├── test/           ⭐ Test code (source, must be in repo; index base for affected precise regression)
    │   └── visual/       👁 Visual machine-check tests (qa writes, in git); baseline/ screenshot baselines (qa exclusive, in git)
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

> Ignore policy: ignore transient artifacts only (`.cc_code/docs/qa/artifacts/`, `coverage/`, `test-results/`); ⛔ never ignore screenshots with a global `*.png` / `screenshots/` wildcard — `.cc_code/design/` and `.cc_code/test/visual/baseline/` must be in git.

## Role Serialization

```
pm ──► uiux ──► Architect ──► Dev ──► QA
(logic) (layout+look) (contract)  (code)  (acceptance)
```

Each role's must-read / writable / forbidden permissions live only in `templates/Agent.md` §3 (single source; no copy here). uiux appears on the planning side only and writes both L2 files, `ux.md` and `design.md`.

## Experience Sediment (fully automatic)

Experience is sedimented by the **curator** agent, automatically and silently: the owner does nothing, confirms nothing, rules on nothing, and sees only one result line in the final report (nothing written when nothing changed). There is no manual entry: only failures that really happened in acceptance and were fixed get filed.

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
