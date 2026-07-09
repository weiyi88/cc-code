---
name: agentToMVP
description: cc-code + 三 agent（prd-plan/dev/qa）驱动 MVP 开发的完整生命周期编排器。用户显式调用 /cc-code:agentToMVP 触发；按 PM→Architect→Dev→QA 串行 + qa→dev 循环推进至 MVP，每阶段完成后强制 /cc-code:cc-code 校准状态。手动触发，不自动加载。
---

# agentToMVP — 三 agent × cc-code 驱动 MVP 生命周期编排器

> **手动触发**：仅由用户显式输入 `/cc-code:agentToMVP` 调用，不在会话中自动加载。
> **校准铁律**：每一个阶段完成后，**必须**先执行 `/cc-code:cc-code` 校准当前状态（重读 `Agent.md`/`status.md`/`errors.md`，重锁角色与坐标），确认无误后再进入下一阶段。未校准禁止推进。
> **串行铁律**：严守 PM → Architect → Dev → QA 顺序，由 `.cc_code/active/Agent.md` 锁定当前角色，禁止跨角色思考与跳序。

## 前置检查（启动时一次性）
1. 确认项目根存在 `.cc_code/`（否则提示先 `/cc-code:init`）。
2. 确认三 agent 可用：`prd-plan` / `dev` / `qa`。
3. 确认测试基建：`vitest.config.ts` / `playwright.config.ts` / `tests/{unit,api,e2e}`。缺失则把「补齐测试基建」作为 Dev 阶段首个任务。
4. 执行 `/cc-code:cc-code` 完成会话开启协议，锁定当前阶段与角色。

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
| 读 | status.md, errors.md, 用户需求（禁读 src/、project.md） |
| 做 | 模糊需求→精确规范；定义 P0/P1；拆交互场景；覆盖四态（加载/空/错误/完成） |
| 跑 | Agent 工具 `subagent_type=prd-plan` |
| 输出 | PRD + 交互矩阵 + 前端规格 |
| 写 | `prd.md`, `flow.md`, `front.md` |
| ✅ 完成后 | 执行 `/cc-code:cc-code` 校准 |

### ② Architect 段（agent: prd-plan，Architect 视角）
| 项 | 内容 |
| --- | --- |
| 读 | status, prd, flow, front（禁读 src 业务码） |
| 做 | 技术选型/DB设计/API定义/目录；列每阶段验收断言清单；标 `⚠️ Needs Decision` |
| 跑 | Agent 工具 `subagent_type=prd-plan`（切 Architect 视角） |
| 输出 | 实现计划文档（Summary/Scope/Design/边缘案例/风险/Rollout） |
| 写 | `project.md`, `docs/plans/phaseN-plan.md` |
| ✅ 完成后 | 执行 `/cc-code:cc-code` 校准 |

### ③ Dev 段（agent: dev）
| 项 | 内容 |
| --- | --- |
| 读 | status, errors, project, front, flow, `docs/plans/phaseN-plan.md` |
| 做 | 按规格实现 src + 三层测试；遵循 project.md 约定；踩坑即记 errors.md |
| 跑 | Agent(dev) → 内部 Read/Edit/Write；自检：`pnpm lint` → `tsc --noEmit` → `pnpm test` → `pnpm test:e2e` |
| 输出 | 业务代码 + `tests/` + 完成报告（文件清单 + pass/fail） |
| 写 | `src/`, `tests/`, `errors.md` |
| ✅ 完成后 | 执行 `/cc-code:cc-code` 校准 |

### ④ QA 段（agent: qa，灰盒）
| 项 | 内容 |
| --- | --- |
| 读 | prd, flow, front, project(仅约定), API 文档, `src/`（仅本阶段改动） |
| 做 | 建验收断言清单；为每条断言写三层测试；完整跑一遍（不抽样） |
| 跑 | Agent(qa) → `pnpm test` + `pnpm test:e2e` + 浏览器 MCP（chrome-devtools/Playwright）驱动疑难交互 |
| 输出 | QA 报告（Verdict + 断言追溯矩阵 + Critical Failures 清单） |
| 写 | `gates.md`, `tests/`（补测） |
| ✅ 完成后 | 执行 `/cc-code:cc-code` 校准 |

**三层测试矩阵：**

| 层 | 断言类型 | 工具 | 命令 |
| --- | --- | --- | --- |
| 逻辑 | 纯函数/规则/边界 | vitest | `pnpm test` |
| 接口 | method/path/状态码/schema/错误码/鉴权/分页 | vitest+fetch | `pnpm test:api`（需 `TEST_BASE_URL`） |
| 交互 | flow 四态 + 角色门控 | Playwright | `pnpm test:e2e` |

## qa → dev 循环（QA 段内）

1. qa 出 FAIL 清单 → 主控原样喂回 dev。
2. dev 只修不改需求 → 主控再调 qa 复测（仅重跑 FAIL 项 + 受影响回归）。
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

- QA PASS 后，Hook 静默归档 `status.md`/`changelog.md`/`backup/`。
- AI 顺手更新 `status.md`「当前坐标 + 下一步」。
- 执行 `/cc-code:cc-code` 校准，确认进入下一阶段。

## MVP 收口（全部阶段 PASS）

1. 执行 `/cc-code:cc-code` 校准，确认 N/N 阶段 PASS、`gates.md` 全关卡通过。
2. 全量回归：`pnpm build` + `pnpm test` + `pnpm test:e2e` + `scripts/smoke-test.sh`。
3. 产出 `SETUP.md` / 部署清单。
4. `changelog.md` 记 MVP 里程碑。
5. 报告：可部署 MVP。

## 编排器行为准则

- **你是编排器**：按当前阶段调对应 agent，不在主控里替角色思考。
- **每次切阶段/切角色前必须 `/cc-code:cc-code` 校准**，禁止凭记忆推进。
- **agent 通用、cc-code 项目特定**：项目约定一律让 agent 读 `.cc_code/active/project.md`，不替它假设。
- 进度以 `status.md` 为准、踩坑以 `errors.md` 为准、验收以 `gates.md` 为准。
- 不向用户报告归档细节（Hook 静默）；只报阶段结果与决策点。
