---
name: debug-qa-dev
description: cc-code + 双 agent（dev/qa）驱动的 bug 修复执行编排器（纯执行，不诊断）。前置：/cc-code:debug-plan 已落盘 B-n 且 status.md「下一步」点名 B-n。用户显式调用 /cc-code:debug-qa-dev 触发；入口先做增量定位（status.md 点名 B-n − bugs.md OPEN 条目 = 执行范围），再 Dev→QA 串行 + qa→dev 循环（≤3 轮），affected 精准回归，修复 PASS 硬条件 = 回归测试存在且通过。无全量清算。未诊断拒跑。中途零确认。手动触发，不自动加载。
allowed-tools: Read, Write, Edit, Bash, Glob, Grep, Agent, TaskCreate, TaskUpdate, TaskList, mcp__codegraph__codegraph_explore
disable-model-invocation: true
---

# debug-qa-dev — 双 agent × cc-code 驱动 bug 修复执行编排器

> **纯执行器**：只修已诊断的 bug，**不诊断**。根因与方案由 `/cc-code:debug-plan` 落盘到 `active/bugs.md` 的 B-n 条目，本命令读 B-n 直接开发，**中途零确认**，只在 FAIL 3 轮升级时交人。
> **与 agent-to-feature 的分工**：feature 是「加一个房间」（执行 F-n 需求增量）；本命令是「修房子里的漏水点」（执行 B-n bug 修复）。执行循环、回归策略、结算纪律全部同构。
> **初衷铁律**：完整地修复 bug —— 修复面 = B-n 用例 + affected 影响面，⛔ 无 whole-qa、无全量回归。

## 前置检查（启动时一次性）
1. 确认项目根存在 `.cc_code/`（否则提示先 `/cc-code:init`）。
2. 确认双 agent 可用：`dev` / `qa`。
3. **增量定位（⭐第一动作，见下节）**——定位失败即拒跑，后续检查全免。
4. 确认测试基建：读 `project.md` §六「测试基建契约」。缺失则把「补齐测试基建」作为 Dev 段首个任务。
5. **索引体检（静默）**：`codegraph status --json` —— `pendingChanges` 非 0 → 静默 `codegraph sync`；`initialized:false` → 报一行（⛔ 不自动重建）。CLI 未装则静默跳过（精准回归降级为全量）。⛔ 健康时一个字都不提。
6. 执行 `/cc-code:cc-code` 完成会话开启协议，锁定当前阶段与角色。

## ⭐ 增量定位（第一动作，纯查表，零推理）

```
 ① 读 status.md「下一步」
      └─ 期望形态：「B-n 待修复」+（bugs.md 里有对应 OPEN 条目）
           ├─ 没有 B-n / 写的是「未诊断」/ 下一步是别的事
           │     → ⛔ 拒跑：「bug 未诊断，请先走 /cc-code:debug-plan」
           │       （本命令绝不现场诊断根因——根因唯一来源 = B-n 条目）
           └─ 拿到 B 号 + 条目内容（复现/期望出处/根因/方案/影响面）
 ② 读 gates.md → 查该 B-n 是否已有 PASS 记录
 ③ 对账：
      已有 PASS → 报「B-n 已修复，无事可做」，结束
      无 PASS   → B-n 即本次执行范围，进 Dev 段
```

## 生命周期总览

```
启动 → 增量定位 → ①Dev → 校准 → ②QA → 校准
                              │
                    ┌─────────┴──────────┐
                    ▼                    ▼
              FAIL→回Dev(≤3)         PASS→结算→结束
                    │                （⛔ 无全量清算）
            3轮仍FAIL→升级(交人)
```

## 阶段执行规范

### ① Dev 段（agent: dev）
| 项 | 内容 |
| --- | --- |
| 读 | status, bugs.md（仅 B-n 条目）, prd / ux（仅期望出处命中的断言/判定项）, project（含实现指引章节）, data / api（仅命中契约小节） |
| 做 | 只按 B-n 方案修：根因处修复 + 按「影响面」清单逐文件核对连带；遵循 project.md 约定；⛔ 不重构无关代码、不改契约 |
| 跑 | Agent(dev) → 自检：`pnpm lint` → `tsc --noEmit` → `pnpm test` → `pnpm test:e2e` |
| 输出 | 修复代码 + 完成报告（文件清单 + pass/fail） |
| 写 | `src/`, `project.md` §六 声明的测试根 |
| ✅ 完成后 | 执行 `/cc-code:cc-code` 校准（静默） |

### ② QA 段（agent: qa，灰盒）
| 项 | 内容 |
| --- | --- |
| 读 | bugs.md（B-n 条目：复现/期望出处/影响面）, prd / ux（期望出处）, api / data（命中契约）, project(仅约定), `src/`（仅本段改动） |
| 做 | ① 按「复现」写 bug 用例（修复前应 FAIL、修复后应 PASS）②⭐**落一个永久回归测试进测试根** ③ 完整跑一遍 B-n 用例 + 影响面回归 |
| 跑 | Agent(qa) → Dev 段改动文件的 `affected` 回归范围优先（拿不到则全量）+ 浏览器 MCP（chrome-devtools/Playwright）驱动疑难交互 |
| 输出 | QA 报告（Verdict + B-n 用例结果 + 回归范围来源标注） |
| 写 | `gates.md`, 测试根（回归测试） |
| ✅ 完成后 | 执行 `/cc-code:cc-code` 校准（静默） |

> **⭐ 修复 PASS 硬条件**：回归测试存在且通过才许把 gates 记 ✅。没有测试的修复不算修完 —— 没有回归测试，gates 的 ✅ 就是假账，下次这段代码被改动没人兜底。
> ⛔ **QA 用 codegraph 的双重限制**：只许用 `node` / `callers` / `affected`。**期望行为永远只来自 B-n 条目（其出处为主人原话或 prd/ux 既有断言）** —— codegraph 绝不是期望的尺子。

## qa → dev 循环（QA 段内）

1. qa 出 FAIL 清单 → 主控原样喂回 dev。
2. dev 只修不改方案不改需求 → 修完重算 `codegraph affected <本轮修改文件>`，主控再调 qa 复测（B-n 用例 + affected 影响面；拿不到则退回全量）。
3. 每轮循环后执行 `/cc-code:cc-code` 校准（静默）。
4. 最多 3 轮：仍 FAIL → qa 标记「升级」→ 交人决策（⛔ 直接报告卡点，不回诊断），禁止无限循环。
5. 全绿 → QA 段 PASS。

## 修复结算（QA PASS 即结束，⛔ 无全量清算）

1. **gates.md 记账**（QA 域，按 bugs.md 条目的「期望出处」分两路）：
   - 出处 = 既有 A/U 断言 → **就地改写**该断言行为 ✅（换新测试位置，不新开行）
   - 出处 = 主人原话（无既有断言）→ 追溯矩阵 **B 段**追加一行 `B-n ✅`
2. **milestone-log 追加一行**：`日期 ｜ 模块 ｜ B-n <简述> 修复 PASS ｜ <期望出处断言号或 B-n>`。
3. **bugs.md 删该条目**（施工便签用完即撕；历史由 git 提交 + milestone-log + 留守的回归测试承载，⛔ 不另建 bug 归档）。
4. **status.md** 顺手更新（下一步清空 B-n 指向，或指向遗留待办）。
5. 报告：B-n 修复交付（用例 PASS + 回归范围 + 回归测试位置）。
6. **不跑 whole-qa、不做全量回归** —— bug 修复的验收面就是 B-n 用例 + affected 精准回归面；全量清算只属于 MVP 收口或主人显式调用 `/cc-code:whole-qa`。

## 编排器行为准则

- **你是编排器**：按阶段调对应 agent，不在主控里替角色思考。
- **纯执行定位**：发现 B-n 条目缺漏（方案说不清 / 影响面为空 / 根因存疑）→ 停下报告交人，⛔ 绝不现场重新诊断（那是 `/cc-code:debug-plan` 的职责）。
- **每次切阶段/切角色前必须 `/cc-code:cc-code` 校准**，禁止凭记忆推进；校准静默，不打扰人。
- **agent 通用、cc-code 项目特定**：项目约定一律让 agent 读 `.cc_code/active/project.md`，不替它假设。
- 进度以 `status.md` 为准、验收以 `gates.md` 为准、待修 bug 以 `bugs.md` 为准。
- 不向用户报告归档细节；只报阶段结果与升级决策点。
