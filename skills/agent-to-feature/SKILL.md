---
name: agent-to-feature
description: cc-code + 双 agent（dev/qa）驱动的功能增量执行编排器（纯执行，不规划）。前置：/cc-code:plan-prd-feature 已落盘定稿且 status.md「下一步」点名 F-n 批次。用户显式调用 /cc-code:agent-to-feature 触发；入口先做增量定位（status.md 点名断言 − gates.md 已 PASS = 执行范围），再 Dev→QA 串行 + qa→dev 循环（≤3 轮），affected 精准回归，无全量清算。未规划拒跑。中途零确认。手动触发，不自动加载。
allowed-tools: Read, Write, Edit, Bash, Glob, Grep, Agent, TaskCreate, TaskUpdate, TaskList, mcp__codegraph__codegraph_explore, mcp__codegraph__codegraph_search, mcp__codegraph__codegraph_node, mcp__codegraph__codegraph_callers
---

# agent-to-feature — 双 agent × cc-code 驱动功能增量执行编排器

> **手动触发**：仅由用户显式输入 `/cc-code:agent-to-feature` 调用，不在会话中自动加载。
> **纯执行器**：只执行增量需求，**不规划**。需求与契约由 `/cc-code:plan-prd-feature` 商讨定稿落盘，本命令读定稿文档直接开发，**中途零确认**，只在 FAIL 3 轮升级时交人。
> **增量铁律**：只做「规划了但还没验过」的断言，绝不重推存量需求、绝不重做已 PASS 项。
> **与 agent-to-mvp 的分工**：mvp 是「盖整栋楼」（含 whole-qa 全量清算收口）；feature 是「在楼里加一个房间」（affected 精准回归，无全量清算）。

## 前置检查（启动时一次性）
1. 确认项目根存在 `.cc_code/`（否则提示先 `/cc-code:init`）。
2. 确认双 agent 可用：`dev` / `qa`。
3. **增量定位（⭐第一动作，见下节）**——定位失败即拒跑，后续检查全免。
4. 确认测试基建：读 `project.md` §六「测试基建契约」。缺失则把「补齐测试基建」作为 Dev 段首个任务。
5. **索引体检（静默）**：`codegraph status --json` —— `pendingChanges` 非 0 → 静默 `codegraph sync`（增量回归面建立在索引之上，旧索引 = 漏回归）；`initialized:false` → 报一行（⛔ 不自动重建）。CLI 未装则静默跳过（精准回归降级为全量）。⛔ 健康时一个字都不提。
6. 执行 `/cc-code:cc-code` 完成会话开启协议，锁定当前阶段与角色。

## ⭐ 增量定位（第一动作，纯查表，零推理）

```
 ① 读 status.md「下一步」
      └─ 期望形态：「F-n <需求名>，已规划未开发」+ 点名断言号（如 A28.1~A28.10 / U23）
           ├─ 没有 F-n / 写的是「未规划」/ 下一步是别的事
           │     → ⛔ 拒跑：「增量未规划，请先走 /cc-code:plan-prd-feature」
           │       （本命令绝不现场推需求——需求唯一来源 = 定稿文档）
           └─ 拿到 F 号 + 新断言清单
 ② 读 prd.md §1.5 主表 / ux.md §2.3 矩阵 → 取这些断言号的具体内容
 ③ 读 gates.md 追溯矩阵 → 取已 PASS 断言集合
 ④ 对账：
      增量范围 = F-n 点名断言 − gates.md 已 PASS
           ├─ 差集为空 → 报「F-n 已全部 PASS，无事可做」，结束
           └─ 差集非空 → 即本次执行范围，进 Dev 段
```

> 断言编号永久稳定（A 序列不重排不复用），所以这个对账天然精确——已 PASS 的不会重做，没 PASS 的就是本次的活。

## 生命周期总览

```
启动 → 增量定位 → ①Dev → 校准 → ②QA → 校准
                                 │
                       ┌─────────┴──────────┐
                       ▼                    ▼
                 FAIL→回Dev(≤3)         PASS→结算→结束
                       │                  （⛔ 无全量清算）
               3轮仍FAIL→升级(交人)
```

## 阶段执行规范

### ① Dev 段（agent: dev）
| 项 | 内容 |
| --- | --- |
| 读 | status, prd（仅 F-n 命中模块小节 + §1.5 命中断言）, ux（命中 U 项）, project（含实现指引章节）, data / api（仅命中契约小节） |
| 做 | 只按增量范围实现：改写命中模块 + 新增/补齐测试；遵循 project.md 约定；⛔ 不重构无关代码 |
| 跑 | Agent(dev) → 自检：`pnpm lint` → `tsc --noEmit` → `pnpm test` → `pnpm test:e2e` |
| 输出 | 增量代码 + 测试 + 完成报告（文件清单 + pass/fail） |
| 写 | `src/`, `project.md` §六 声明的测试根 |
| ⭐ 完成后 | **算精准回归面**：`codegraph affected <本段改动的源文件...>` → 测试文件清单传给 ②QA 段；非 `.spec`/`.test` 命名补跑 `--filter "<project.md §六 登记的 glob>"`，合并去重即「本段回归范围」 |
| ✅ 完成后 | 执行 `/cc-code:cc-code` 校准（静默） |

> **`affected` 空结果处置**：返回空 → 报一行「affected 未匹配到测试，本段回归用全量」+ 自查 ① 测试被 `.gitignore` 屏蔽？② 测试是否 import 被测源码（纯 HTTP 型无 import 边）③ 命名需 `--filter`？。CLI 未装 → 静默用全量，不报。

### ② QA 段（agent: qa，灰盒）
| 项 | 内容 |
| --- | --- |
| 读 | prd（仅命中断言）, ux, api / data（命中契约）, project(仅约定), `src/`（仅本段改动） |
| 做 | 只为增量范围的断言建验收清单 + 三层测试；完整跑一遍（不抽样） |
| 跑 | Agent(qa) → ① 段 `affected` 回归范围优先（拿不到则全量）+ 浏览器 MCP（chrome-devtools/Playwright）驱动疑难交互 |
| 输出 | QA 报告（Verdict + 断言追溯矩阵 + Critical Failures 清单 + 回归范围来源标注） |
| 写 | `gates.md`, 测试根（补测） |
| ✅ 完成后 | 执行 `/cc-code:cc-code` 校准（静默） |

> ⛔ **QA 用 codegraph 的双重限制**：只许用 `node` / `callers` / `affected`。**需求永远只来自 `prd.md` / `ux.md` / `api.md`** —— codegraph 绝不是需求的尺子。
> ⛔ **输出可读铁律**：断言引用一律双标识「编号｜中文模块-功能」（如 `A28.3｜素材队列-429 退避 → ✅`），禁止裸编号。

**三层测试矩阵：** 同 `agent-to-mvp`（逻辑 / 接口 / 交互三层，vitest + fetch + Playwright）。

## qa → dev 循环（QA 段内）

1. qa 出 FAIL 清单 → 主控原样喂回 dev。
2. dev 只修不改需求 → ⭐修完重算 `codegraph affected <本轮修改文件>`，主控再调 qa 复测（FAIL 项 + affected 影响面；拿不到则退回「同模块已 PASS 项」）。
3. 每轮循环后执行 `/cc-code:cc-code` 校准（静默）。
4. 最多 3 轮：仍 FAIL → qa 标记「升级」→ 交人决策（⛔ 直接报告卡点，不回规划），禁止无限循环。
5. 全绿 → QA 段 PASS。

## 增量结算（QA PASS 即结束，⛔ 无全量清算）

- **AI** 在 `back_up/milestone-log.md` 追加一行（格式见 `active/Agent.md` 归档规范），⛔ 不写进 `status.md`。
- AI 顺手更新 `status.md`「当前坐标 + 卡点 + 下一步」（下一步清空 F-n 指向，或指向遗留待办）。
- 报告：F-n 增量交付（断言 PASS 清单 + 回归范围）。
- **不跑 whole-qa、不做全量回归** —— 增量的验收面就是 affected 精准回归面；全量清算只属于 MVP 收口（`/cc-code:agent-to-mvp`）或主人显式调用 `/cc-code:whole-qa`。

## 编排器行为准则

- **你是编排器**：按阶段调对应 agent，不在主控里替角色思考。
- **纯执行定位**：发现增量文档缺漏 / 自相矛盾 / 断言查无内容 → 停下报告交人，⛔ 绝不现场发明需求（那是 `/cc-code:plan-prd-feature` 的职责）。
- **每次切阶段/切角色前必须 `/cc-code:cc-code` 校准**，禁止凭记忆推进；校准静默，不打扰人。
- **agent 通用、cc-code 项目特定**：项目约定一律让 agent 读 `.cc_code/active/project.md`，不替它假设。
- 进度以 `status.md` 为准、验收以 `gates.md` 为准。
- 不向用户报告归档细节；只报阶段结果与升级决策点。
