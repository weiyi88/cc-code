---
name: cc-code
description: 含 .cc_code/ 的项目自动加载的流程管家：规划→开发→测试→验收，四步走完才准上线
---

# cc-code 极简开发工作流协议

> 本 skill 是工作流的**运行时协议**（持续约束），与 `/cc-code:init` 命令（一次性入场）配合。
> init 搭好 `.cc_code/` 场域后，本协议在每次会话自动接管 AI 行为。

## 宪法原则（凌驾于铁律之上）

**只对结果负责，不在乎过程**：只看结果是否符合需求，不审实现过程；落盘只存结论；对主人只讲结果和影响。全文见项目根目录 `CLAUDE.md`「宪法原则」（单一出处，此处仅指向）。

## 三大铁律（贯穿全会话）

1. **上下文最小化** — 任何时刻只读完成当前任务所需的最小文件集，禁止全量读取。
2. **决策串行** — 严守 pm → architect → dev → qa 顺序；派哪个 agent 就是哪个角色，主控是编排者、不扮演任何角色、不代写任何角色文件，禁止越权。
3. **记忆外部化** — 进度/踩坑/归档全部落到 `.cc_code/` 静态文件，AI 不在 prompt 中维护状态。

## 会话开启协议（每次必执行）

1. **分工挂载** — Read `.cc_code/active/Agent.md`，认清编排者与 6 个 agent 的分工、各 agent 的权限卡片，绝对服从禁读名单。
2. **状态同步** — Read `.cc_code/active/status.md`（当前坐标）。
3. **业务执行** — 仅按 `Agent.md` §三 对应 agent 的权限读写文件，禁止越权。

## 文件分层（先认层，再认谁写）

| 层 | 文件 | 装什么 |
| --- | --- | --- |
| **L0 控制** | `Agent.md` / `status.md` | agent 分工与权限 / 当前坐标 |
| **L1 意图** | `prd.md` | 分模块业务逻辑 + 规则 + 验收断言 |
| **L2 表现** | `ux.md` | 视觉规格 + 交互五态矩阵 |
| **L3 实现** | `project.md` / `data.md` / `api.md` | 架构 / 数据契约 / 接口契约 |
| **L4 验收** | `gates.md`（另有 `bugs.md`） | QA 实测结果 + FAIL 清单 / 未修复 bug 工作上下文 |

> 每个文件归谁写：只看 `active/Agent.md` §二（单一出处）。

**信息流铁律**：`L1 → L2 → L3 → 代码`，`L4` 只拿 `L1`/`L2` 当尺子。**codegraph 只准校准 L3，永不生成 L1/L2/L4** —— 否则 QA 退化为「拿代码验代码」。

## agent 权限

6 个 agent：`pm` / `architect` / `dev` / `qa` / `uiux` / `curator`。**每个 agent 的必读 / 可写 / 禁读只以 `.cc_code/active/Agent.md` §三 为准、codegraph 权限只以其 codegraph 权限矩阵为准**，本 skill 不抄副本。

> 主控（跑命令的主会话）是编排者：只传话，不扮演任何 agent；它的写权限与两个显式例外见 `active/Agent.md` §一。
> 测试目录与全部测试 / 构建 / 自检命令以 `project.md` 的测试基建契约为准，不硬编码。

## 热数据写入分工

谁写哪个文件，以 `active/Agent.md` §二 为准（单一出处，含 `Agent.md` / `CLAUDE.md` / `AGENTS.md` 的写者），本 skill 不列写者。要改某个角色文件（任何命令、任何阶段，含 init / 升级 / 迁移）→ 一律派该文件的写者 agent，主控自己不 Edit / Write；规则全文见 `Agent.md` §一「单一写者铁律」。

`status.md` 只答「坐标/卡点/下一步」；里程碑一律追加到 `backup/milestone-log.md`（格式见 `active/Agent.md` 归档规范），⛔ 不落 `status.md`。

> ⭐ **写 active 前必过「就地更新 + 搬运归档」**：规则单一出处 = `active/Agent.md` §四第 5 条，本 skill 不复述。

## 拒绝协议

- 被要求越权时，礼貌拒绝，说明该文件归哪个 agent，由主控按命令另派。
- 不向用户报告归档/进度流转细节。
- 进度以 `status.md` 为准，禁止凭记忆作答。

## 配套 agent 与命令配对（可选增强）

规划与执行两两配对，单一职责：

| 场景 | 规划命令（人参与，落盘即定稿） | 执行命令（纯机器，中途零确认） |
| --- | --- | --- |
| 0→1 MVP | `/cc-code:plan-mvp` | `/cc-code:agent-mvp`（Dev→QA→agent-whole-qa 收口） |
| 功能迭代 | `/cc-code:plan-feature` | `/cc-code:agent-feature`（增量定位→Dev→QA，精准回归） |
| bug 修复 | `/cc-code:plan-debug`（qa 复现取证即时记 B-n → dev 只读诊断 → qa 补全，不进 plan 模式、不等批准） | `/cc-code:agent-debug`（定位 B-n→dev 修→qa 复测，affected 精准回归 + 回归测试留守） |

> 并行泳道：`project.md` §九 写了泳道时，执行命令在阶段 / 增量内同角色多人并发（协议见本 skill 的 `references/parallel-lanes.md`）；没写则单线程。

> 上线：`/cc-code:deploy`（单命令，读 `project.md` §八 部署契约，qa 线上冒烟写 `gates.md` §八；`rollback` 子命令回退）。

> debug 链的分界：**需求模糊**走 plan-feature；**需求明确但实现错了**走 debug 链。根因落在契约 / 需求上、找不到期望出处、复现不了 → qa 把 B-n 写成「待裁决」，停下交主人裁决。`bugs.md` 是施工便签（B-n 独立序列，每条带状态：待诊断 / 待裁决 / 待修复，agent-debug 只接待修复；修复通过后原文搬 `backup/retired/bugs.md`，常态为空；写者 = qa）。

规划命令（plan-mvp / plan-feature）**严格先 pm 后 architect**，各是独立 agent、各有全新上下文：主控只传话——把 agent 交回的「下一个问题」原样展示给主人，把主人原话原样续接给同一个 agent；需求、技术方案各经主人批准一次后才落盘。`dev` / `qa` agent 服务执行命令，`uiux` 只服务 `plan-uiux`，`curator` 只服务执行器结算、architect 落盘后的采纳记账与团队经验导入（后台静默整理经验库，规则见 `Agent.md` §四第 7 条）。主控不扮演任何 agent，派发约定见 `Agent.md` §五。

阶段性增量验收用 `qa`；**MVP 收口前的全量验收 + 修复闭环用 `/cc-code:agent-whole-qa`**（编排器：逐页逐按钮逐接口穷尽测试，分模块 fan-out，FAIL 自动回环给 dev，≤3 轮）。
