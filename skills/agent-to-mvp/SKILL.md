---
name: agent-to-mvp
description: cc-code + 三 agent（prd-plan/dev/qa）驱动 MVP 开发的完整生命周期编排器。用户显式调用 /cc-code:agent-to-mvp 触发；按 PM→Architect→Dev→QA 串行 + qa→dev 循环推进至 MVP，每阶段完成后强制 /cc-code:cc-code 校准状态。手动触发，不自动加载。
allowed-tools: Read, Write, Edit, Bash, Glob, Grep, Agent, TaskCreate, TaskUpdate, TaskList, mcp__codegraph__codegraph_explore, mcp__codegraph__codegraph_search, mcp__codegraph__codegraph_node, mcp__codegraph__codegraph_callers
---

# agent-to-mvp — 三 agent × cc-code 驱动 MVP 生命周期编排器

> **手动触发**：仅由用户显式输入 `/cc-code:agent-to-mvp` 调用，不在会话中自动加载。
> **校准铁律**：每一个阶段完成后，**必须**先执行 `/cc-code:cc-code` 校准当前状态（重读 `Agent.md`/`status.md`，重锁角色与坐标），确认无误后再进入下一阶段。未校准禁止推进。
> **串行铁律**：严守 PM → Architect → Dev → QA 顺序，由 `.cc_code/active/Agent.md` 锁定当前角色，禁止跨角色思考与跳序。

## 前置检查（启动时一次性）
1. 确认项目根存在 `.cc_code/`（否则提示先 `/cc-code:init`）。
2. 确认三 agent 可用：`prd-plan` / `dev` / `qa`。
3. 确认测试基建：读 `project.md` §六「测试基建契约」取测试根 / glob / 运行命令。缺失或未填实则把「补齐测试基建 + 回填 `project.md` §六」作为 Dev 阶段首个任务。
4. **索引体检（⭐0.10.0，静默）**：`codegraph status --json` 读三字段 —— `initialized:false` → 报一行（⛔ 不自动重建）；`pendingChanges` 非 0 → 静默 `codegraph sync`；`reindexRecommended:true` → 报一行建议。CLI 未装则静默跳过，全流程照跑（精准回归降级为全量）。⛔ 健康时一个字都不提。
5. 执行 `/cc-code:cc-code` 完成会话开启协议，锁定当前阶段与角色。

## 生命周期总览

```
启动校准 → ①PM → 校准 → ②Architect → 校准 → ③Dev → 校准 → ④QA → 校准
                                                            │
                                                  ┌─────────┴──────────┐
                                                  ▼                    ▼
                                            FAIL→回Dev(≤3)         PASS→阶段结算→校准
                                                  │                    │
                                          3轮仍FAIL→升级              ▼
                                          (回prd-plan/人)        还有阶段? →回①
                                                                 全PASS → MVP收口
```

## 阶段执行规范

每阶段严格按「读 / 做 / 跑 / 输出 / 写」执行，完成即校准。

### ① PM 段（agent: prd-plan，PM 视角）
| 项 | 内容 |
| --- | --- |
| 读 | status.md, 用户需求（禁读 src/、project.md） |
| 做 | 模糊需求→精确规范；定义 P0/P1；拆交互场景；覆盖五态（正常/加载/完成/错误/空） |
| 跑 | Agent 工具 `subagent_type=prd-plan` |
| 输出 | PRD + 交互矩阵 + 前端规格 |
| 写 | `prd.md`, `ux.md` |
| ✅ 完成后 | 执行 `/cc-code:cc-code` 校准 |

### ② Architect 段（agent: prd-plan，Architect 视角）
| 项 | 内容 |
| --- | --- |
| 读 | status, prd, ux（禁读 src 业务码） |
| 做 | 技术选型/DB设计/API定义/目录；列每阶段验收断言清单；标 `⚠️ Needs Decision` |
| 跑 | Agent 工具 `subagent_type=prd-plan`（切 Architect 视角） |
| 输出 | 实现计划文档（Summary/Scope/Design/边缘案例/风险/Rollout） |
| 写 | `project.md`, `docs/plans/phaseN-plan.md` |
| ✅ 完成后 | 执行 `/cc-code:cc-code` 校准 |

### ③ Dev 段（agent: dev）
| 项 | 内容 |
| --- | --- |
| 读 | status, errors, project, ux, `docs/plans/phaseN-plan.md` |
| 做 | 按规格实现 src + 三层测试；遵循 project.md 约定 |
| 跑 | Agent(dev) → 内部 Read/Edit/Write；自检：`pnpm lint` → `tsc --noEmit` → `pnpm test` → `pnpm test:e2e` |
| 输出 | 业务代码 + 测试（落 `project.md` §六 声明的测试根）+ 完成报告（文件清单 + pass/fail） |
| 写 | `src/`, `project.md` §六 声明的测试根 |
| ⭐ 完成后 | **算精准回归面**：`codegraph affected <本段改动的源文件...>` → 得测试文件清单，传给 ④QA 段。非 `.spec`/`.test` 命名的测试补跑 `--filter "<project.md §六 登记的 glob>"`。合并去重后即「本段回归范围」 |
| ✅ 完成后 | 执行 `/cc-code:cc-code` 校准 |

> **`affected` 空结果处置**（不做前置检测，出问题当场报一行即可）：
> 返回空 → 报「affected 未匹配到测试，本段回归用全量」+ 按序自查 ① 测试代码是否被 `.gitignore` 屏蔽（codegraph 不索引被 ignore 的文件）② 测试是否 import 了被测源码（纯 HTTP 打接口的脚本无 import 边，天然追不到）③ 命名是否需 `--filter`。CLI 未装 → 静默用全量，不报。

### ④ QA 段（agent: qa，灰盒）
| 项 | 内容 |
| --- | --- |
| 读 | prd, ux, api, data, project(仅约定), `src/`（仅本阶段改动） |
| 做 | 建验收断言清单；为每条断言写三层测试；完整跑一遍（不抽样） |
| 跑 | Agent(qa) → ③ 段传来的 `affected` 回归范围优先（拿不到则全量）+ 浏览器 MCP（chrome-devtools/Playwright）驱动疑难交互 |
| 输出 | QA 报告（Verdict + 断言追溯矩阵 + Critical Failures 清单 + 回归范围来源标注） |
| 写 | `gates.md`, 测试根（补测） |
| ✅ 完成后 | 执行 `/cc-code:cc-code` 校准 |

> ⛔ **QA 用 codegraph 的双重限制**：只许用 `node`（找真实入口点以写出能跑的测试）、`callers`（判死代码）、`affected`（算回归面）。**需求永远只来自 `prd.md` / `ux.md` / `api.md`** —— codegraph 是找入口的工具，绝不是需求的尺子。用代码当尺子 = QA 退化为「拿代码验代码」。

**三层测试矩阵：**

| 层 | 断言类型 | 工具 | 命令 |
| --- | --- | --- | --- |
| 逻辑 | 纯函数/规则/边界 | vitest | `pnpm test` |
| 接口 | method/path/状态码/schema/错误码/鉴权/分页 | vitest+fetch | `pnpm test:api`（需 `TEST_BASE_URL`） |
| 交互 | ux 五态 + 角色门控 | Playwright | `pnpm test:e2e` |

## qa → dev 循环（QA 段内）

1. qa 出 FAIL 清单 → 主控原样喂回 dev。
2. dev 只修不改需求 → ⭐修完重算 `codegraph affected <本轮修改文件>`，主控再调 qa 复测（FAIL 项 + affected 算出的真实影响面；拿不到则退回「同模块已 PASS 项」）。
3. **每轮循环后执行 `/cc-code:cc-code` 校准**。
4. 最多 3 轮：仍 FAIL → qa 标记「升级」→ 回 prd-plan 重规划 或 交人决策，禁止无限循环。
5. 全绿 → QA 段 PASS。

```
   dev(修复) ◄──── FAIL 清单 ──── qa(复测)
      │                                │
      └────────── 只修不改需求 ─────────┘
                    ≤ 3 轮
        3 轮仍 FAIL → 升级（回 prd-plan / 交人）
        全绿       → QA 段 PASS
```

## 阶段结算

- QA PASS 后，**AI** 在 `back_up/milestone-log.md` 追加一行（格式见 `active/Agent.md` 归档规范），⛔ 不写进 `status.md`。
- AI 顺手更新 `status.md`「当前坐标 + 卡点 + 下一步」。
- 执行 `/cc-code:cc-code` 校准，确认进入下一阶段。

## MVP 收口（全部阶段 PASS）

1. 执行 `/cc-code:cc-code` 校准，确认 N/N 阶段 PASS、`gates.md` 全关卡通过。
2. **执行 `/cc-code:whole-qa` 做一次全量清算** —— 阶段验收只覆盖各阶段增量，收口前必须逐页逐按钮逐接口穷尽一遍，并跑完修复回环。未过不得收口。
3. **索引体检（⭐0.10.0，静默）**：`codegraph status --json` 确认索引健康 —— 收口报告里的冗余清单与回归范围都建立在索引之上，索引坏了这两项结论不可信。⛔ 只体检不重建，健康时不提。
4. 全量回归：`pnpm build` + `pnpm test` + `pnpm test:e2e` + `scripts/smoke-test.sh`（收口必须全量，不用 `affected` 裁剪 —— 收口的意义就是穷尽）。
5. 产出 `SETUP.md` / 部署清单。
6. `status.md` 记 MVP 里程碑。
7. 报告：可部署 MVP。

## 编排器行为准则

- **你是编排器**：按当前阶段调对应 agent，不在主控里替角色思考。
- **每次切阶段/切角色前必须 `/cc-code:cc-code` 校准**，禁止凭记忆推进。
- **agent 通用、cc-code 项目特定**：项目约定一律让 agent 读 `.cc_code/active/project.md`，不替它假设。
- 进度以 `status.md` 为准、验收以 `gates.md` 为准。
- 不向用户报告归档细节（Hook 静默）；只报阶段结果与决策点。
