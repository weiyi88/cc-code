---
name: agent-to-mvp
description: cc-code + 双 agent（dev/qa）驱动的 MVP 执行编排器（纯执行，不规划）。前置：/cc-code:plan-prd-mvp 已定稿 prd/ux/project/data/api。用户显式调用 /cc-code:agent-to-mvp 触发；按 Dev→QA 串行 + qa→dev 循环（≤3 轮）逐阶段推进，全 PASS 后 whole-qa 全量清算收口。中途零确认。手动触发，不自动加载。
allowed-tools: Read, Write, Edit, Bash, Glob, Grep, Agent, TaskCreate, TaskUpdate, TaskList, mcp__codegraph__codegraph_explore
disable-model-invocation: true
---

# agent-to-mvp — 双 agent × cc-code 驱动 MVP 执行编排器

> **纯执行器**：需求与契约**只读不产**——一切规划产物（prd / ux / project / data / api）由 `/cc-code:plan-prd-mvp` 商讨定稿。本命令读定稿文档直接开发，**中途零确认**，只在 FAIL 3 轮升级时交人。
> **校准铁律**：每一个阶段完成后，**必须**先执行 `/cc-code:cc-code` 校准当前状态（重读 `Agent.md`/`status.md`，重锁角色与坐标），确认无误后再进入下一阶段。未校准禁止推进。校准是机器自检，**静默进行，不以「请确认」的姿态打扰人**。
> **串行铁律**：严守 Dev → QA 顺序，由 `.cc_code/active/Agent.md` 锁定当前角色，禁止跨角色思考与跳序。

## 与规划命令的分工（两两配对，单一职责）

```
 plan-prd-mvp（人参与）              agent-to-mvp（本命令，纯机器）
 商讨 → 逐点循环至通顺               读定稿文档
 落盘 prd/ux/project/data/api  ──►  Dev 编码 → QA 验收（≤3 轮回环）
 对话内确认，落盘即定稿               阶段全 PASS → whole-qa 收口
```

## 前置检查（启动时一次性）
1. 确认项目根存在 `.cc_code/`（否则提示先 `/cc-code:init`）。
2. **定稿体检**：`active/prd.md` 有 §1.5 验收断言主表，且 `ux.md` / `project.md` / `data.md` / `api.md` 齐备。缺任一 → ⛔ 拒跑，报「规划产物未定稿，请先走 `/cc-code:plan-prd-mvp`」，**绝不现场补需求**。
3. 确认双 agent 可用：`dev` / `qa`。
4. 确认测试基建：读 `project.md` §六「测试基建契约」取测试根 / glob / 运行命令。缺失或未填实则把「补齐测试基建 + 回填 `project.md` §六」作为 Dev 阶段首个任务。
5. **索引体检（静默）**：`codegraph status --json` 读三字段 —— `initialized:false` → 报一行（⛔ 不自动重建）；`pendingChanges` 非 0 → 静默 `codegraph sync`；`reindexRecommended:true` → 报一行建议。CLI 未装则静默跳过，全流程照跑（精准回归降级为全量）。⛔ 健康时一个字都不提。
6. 执行 `/cc-code:cc-code` 完成会话开启协议，锁定当前阶段与角色。
7. **阶段来源**：读 `project.md` 的阶段拆分章节。有 → 按阶段逐段推进；无 → 整体作单阶段跑完（⛔ 不自行拆阶段，拆分是规划的职责）。

## 生命周期总览

```
启动校准 → ①Dev → 校准 → ②QA → 校准
                              │
                    ┌─────────┴──────────┐
                    ▼                    ▼
              FAIL→回Dev(≤3)         PASS→阶段结算→校准
                    │                    ▼
            3轮仍FAIL→升级(交人)     还有阶段? →回①
                                         ▼
                                 全PASS → MVP收口
```

## 阶段执行规范

每阶段严格按「读 / 做 / 跑 / 输出 / 写」执行，完成即校准。

### ① Dev 段（agent: dev）
| 项 | 内容 |
| --- | --- |
| 读 | status, prd, ux, project（含阶段拆分章节）, data, api |
| 做 | 按规格实现 src + 三层测试；遵循 project.md 约定 |
| 跑 | Agent(dev) → 内部 Read/Edit/Write；自检：`pnpm lint` → `tsc --noEmit` → `pnpm test` → `pnpm test:e2e` |
| 输出 | 业务代码 + 测试（落 `project.md` §六 声明的测试根）+ 完成报告（文件清单 + pass/fail） |
| 写 | `src/`, `project.md` §六 声明的测试根 |
| ⭐ 完成后 | **算精准回归面**：`codegraph affected <本段改动的源文件...>` → 得测试文件清单，传给 ②QA 段。非 `.spec`/`.test` 命名的测试补跑 `--filter "<project.md §六 登记的 glob>"`。合并去重后即「本段回归范围」 |
| ✅ 完成后 | 执行 `/cc-code:cc-code` 校准 |

> **`affected` 空结果处置**（不做前置检测，出问题当场报一行即可）：
> 返回空 → 报「affected 未匹配到测试，本段回归用全量」+ 按序自查 ① 测试代码是否被 `.gitignore` 屏蔽（codegraph 不索引被 ignore 的文件）② 测试是否 import 了被测源码（纯 HTTP 打接口的脚本无 import 边，天然追不到）③ 命名是否需 `--filter`。CLI 未装 → 静默用全量，不报。

### ② QA 段（agent: qa，灰盒）
| 项 | 内容 |
| --- | --- |
| 读 | prd, ux, api, data, project(仅约定), `src/`（仅本阶段改动） |
| 做 | 建验收断言清单；为每条断言写三层测试；完整跑一遍（不抽样） |
| 跑 | Agent(qa) → ① 段传来的 `affected` 回归范围优先（拿不到则全量）+ 浏览器 MCP（chrome-devtools/Playwright）驱动疑难交互 |
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
4. 最多 3 轮：仍 FAIL → qa 标记「升级」→ 交人决策（⛔ 本命令无规划能力，不回 prd-plan 重规划，直接报告卡点），禁止无限循环。
5. 全绿 → QA 段 PASS。

```
   dev(修复) ◄──── FAIL 清单 ──── qa(复测)
      │                                │
      └────────── 只修不改需求 ─────────┘
                    ≤ 3 轮
        3 轮仍 FAIL → 升级交人
        全绿       → QA 段 PASS
```

## 阶段结算

- QA PASS 后，**AI** 在 `back_up/milestone-log.md` 追加一行（格式见 `active/Agent.md` 归档规范），⛔ 不写进 `status.md`。
- AI 顺手更新 `status.md`「当前坐标 + 卡点 + 下一步」。
- 执行 `/cc-code:cc-code` 校准，确认进入下一阶段。

## MVP 收口（全部阶段 PASS）

1. 执行 `/cc-code:cc-code` 校准，确认 N/N 阶段 PASS、`gates.md` 全关卡通过。
2. **执行 `/cc-code:whole-qa` 做一次全量清算** —— 阶段验收只覆盖各阶段增量，收口前必须逐页逐按钮逐接口穷尽一遍，并跑完修复回环。未过不得收口。
3. **索引体检（静默）**：`codegraph status --json` 确认索引健康 —— 收口报告里的冗余清单与回归范围都建立在索引之上，索引坏了这两项结论不可信。⛔ 只体检不重建，健康时不提。
4. 全量回归：`pnpm build` + `pnpm test` + `pnpm test:e2e` + `scripts/smoke-test.sh`（收口必须全量，不用 `affected` 裁剪 —— 收口的意义就是穷尽）。
5. 产出 `SETUP.md` / 部署清单。
6. `status.md` 记 MVP 里程碑。
7. 报告：可部署 MVP。

## 编排器行为准则

- **你是编排器**：按当前阶段调对应 agent，不在主控里替角色思考。
- **纯执行定位**：发现需求/契约缺漏或自相矛盾 → 停下报告交人，⛔ 绝不现场发明需求补洞（那是 `/cc-code:plan-prd-mvp` 的职责）。
- **每次切阶段/切角色前必须 `/cc-code:cc-code` 校准**，禁止凭记忆推进。
- **agent 通用、cc-code 项目特定**：项目约定一律让 agent 读 `.cc_code/active/project.md`，不替它假设。
- 进度以 `status.md` 为准、验收以 `gates.md` 为准。
- 不向用户报告归档细节（Hook 静默）；只报阶段结果与升级决策点。
