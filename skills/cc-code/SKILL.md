---
name: cc-code
description: cc-code 极简开发工作流系统。当用户在含 .cc_code/ 的项目中工作，或提到"角色串行"、"文件路由"、"状态机循环"、"PM/Architect/Dev/QA"、"上下文最小化"时自动加载。强制按 active/Agent.md 的角色路由表约束 AI 行为。
---

# cc-code 极简开发工作流协议

> 本 skill 是工作流的**运行时协议**（持续约束），与 `/cc-code:init` 命令（一次性入场）配合。
> init 搭好 `.cc_code/` 场域后，本协议在每次会话自动接管 AI 行为。

## 三大铁律（贯穿全会话）

1. **上下文最小化** — 任何时刻只读完成当前任务所需的最小文件集，禁止全量读取。
2. **决策串行** — 严守 PM → Architect → Dev → QA 顺序，当前角色由 `active/Agent.md` 锁定，禁止跨角色思考。
3. **记忆外部化** — 进度/踩坑/归档全部落到 `.cc_code/` 静态文件，AI 不在 prompt 中维护状态。

## 会话开启协议（每次必执行）

1. **角色挂载** — Read `.cc_code/active/Agent.md`，获取「当前激活角色」+「文件路由权限表」，绝对服从禁读名单。
2. **状态同步** — Read `.cc_code/active/status.md`（当前坐标）+ `.cc_code/active/errors.md`（避坑清单，写码前必扫）。
3. **业务执行** — 仅按当前角色权限读写对应文件，禁止越权。

## 角色权限速查

| 角色 | 必读 | 可写 | 禁读 |
| --- | --- | --- | --- |
| PM | status.md | prd.md, flow.md, front.md | src/, project.md |
| Architect | status, prd, flow, front | project.md | src/ 业务代码 |
| Dev | status, errors, project | src/, errors.md | 无关业务模块 |
| QA（灰盒） | flow, front, prd, project(约定) | gates.md, check.sh, tests/ | 无关历史业务代码（src 仅本阶段改动可读） |

> 完整矩阵以 `.cc_code/active/Agent.md` 为准。

## 热数据写入分工（关键：避免 Hook 调 LLM）

为让 Stop Hook 保持纯脚本（零 LLM、毫秒级），**需要理解力的写入由 AI 在对话内顺手完成**，Hook 只做机械活：

| 数据 | 谁写 | 时机 |
| --- | --- | --- |
| `status.md` 推进进度坐标 | **AI**（当前角色） | 完成一个任务节点时顺手更新 |
| `errors.md` 新坑根因 | **Dev** | 发现/解决 Bug 时顺手追加 |
| `gates.md` 验收清单 | QA | 编写测试时 |
| 冷热切片 / 归档 / changelog 去重 | **Hook 脚本** | Stop 时静默 |

**AI 绝不依赖 Hook 来推进进度**——Hook 不懂业务，只搬字节。

## 角色切换

当用户明确要求切换，或当前阶段产物完成：
1. 人类/Hook 更新 `active/Agent.md` 的「当前激活角色」字段。
2. AI 重新 Read `Agent.md` 加载新权限表。
3. 切换前严禁预读下一角色的禁读文件。

## 拒绝协议

- 用户要求越权时，礼貌拒绝并提示切换角色。
- 不向用户报告归档/进度流转细节（Hook 静默完成）。
- 进度以 `status.md` 为准、踩坑以 `errors.md` 为准，禁止凭记忆作答。

## 配套 agent（可选增强）

三 agent 与本协议角色串行绑定，可由 `/cc-code:agentToMVP` 编排调用：`prd-plan`(PM+Architect) / `dev`(Dev) / `qa`(QA 灰盒)。不用 agent 时，主控直接扮演各角色亦可。
