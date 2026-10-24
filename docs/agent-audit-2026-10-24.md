# cc-code agent 审查报告（2026-10-24）

> 日期：2026-10-24。方法：先按 5 个维度（dev、qa、uiux 与 prd-plan、跨文件一致性、角色权限与边界）对 agent 及其调用链做只读审查，再对每条发现逐条对抗复核（复核者独立回到原文取证，能驳回就驳回）。全程只读，未改任何文件。结论：共确认 **113** 条（严重 39、中 68、低 6），驳回 **5** 条。以下按问题类型分组，每条的「处理」列均为 1.8.0 处理，对应的设计编号（D1–D17）见各组小标题下方。

## 总览

| 问题类型 | 条数 | 其中严重 |
|---|---|---|
| 记忆跨项目 | 18 | 12 |
| 别的项目残留 | 15 | 4 |
| 主控自己读代码 / 切角色 | 7 | 6 |
| QA 能力锁死 | 9 | 3 |
| 角色越界 | 17 | 7 |
| 单一写者 | 9 | 4 |
| 规则副本 | 6 | 0 |
| prd-plan 引用与生成链 | 14 | 2 |
| 模型档位与子代理约束 | 10 | 1 |
| uiux | 8 | 0 |
| 合计 | 113 | 39 |

说明：一条发现只归入一个类型；不少发现同时涉及多个类型（例如 prd-plan 的用户级记忆既属记忆跨项目、也属 prd-plan 引用），以最贴近根因的类型为准。

## 1. 记忆跨项目（18 条）

memory 声明为 user 级、正文写死作者本机路径、「适用于所有项目」、整段记忆说明书逐字复制三份、记忆示例与「项目约定只从 active/* 读」自相矛盾。

1.8.0 对应设计：D5（memory: project，删整段说明书，正文只留 2–4 行该记/不该记，禁写死路径与 user-scope 字样）

| 编号 | 严重程度 | 文件:行 | 问题 | 原文证据 | 处理 |
|---|---|---|---|---|---|
| cross-1 | 严重 | agents/dev.md:6 | dev、qa、prd-plan 三个 agent 的 frontmatter 都写成 memory: user（用户级）。拍板要求全部改成项目级：用户级记忆会把 A 项目的经验带进 B 项目，正是这次 L1 报的串味问题。 | `memory: user` | 1.8.0 处理 |
| cross-2 | 严重 | agents/dev.md:264 | 记忆正文写死作者机器的绝对路径 /Users/blue_focus/.claude/agent-memory/<角色>/，还写“适用于所有项目”。插件分发到别人机器上这个路径不存在，而且明确鼓励跨项目通用，与“项目级记忆”背道而驰；qa（131/261）和 prd-plan（195/325）各有一份同样的句子。 | `Since this memory is user-scope, keep learnings general since they apply across all projects` | 1.8.0 处理 |
| dev-2 | 严重 | agents/dev.md:134 | memory 声明为 user 级，正文还写死 /Users/blue_focus/.claude/agent-memory/dev/，第 264 行更明说「适用于所有项目」。所有生成项目共用同一份记忆，A 项目的经验会直接污染 B 项目，这是本次要修的核心问题。 | `You have a persistent, file-based memory system at '/Users/blue_focus/.claude/agent-memory/dev/'` | 1.8.0 处理 |
| qa-1 | 严重 | agents/qa.md:7 | qa 的记忆档位是用户级，正文还把记忆目录写死成个人目录，并明说这些经验适用于所有项目。某个生成项目的验收习惯会被反灌到所有项目，正好违反已拍板的项目级记忆决定。 | `memory: user ／ "Since this memory is user-scope, keep learnings general since they apply across all projects"` | 1.8.0 处理 |
| qa-2 | 严重 | agents/qa.md:123 | 第 14 行立了「项目约定只从 project.md 取，绝不从记忆取」，这里却让 QA 把某个项目的权限函数名、CSRF、游标、错误码大小写等约定写进记忆。换个项目就会拿旧项目的规矩当尺子，且与本文件自己的原则自相矛盾。 | `Recurring API contract failures (missing 'requirePerm', bare-array list responses, raw 'error.message' leaks)` | 1.8.0 处理 |
| roles-3 | 严重 | agents/prd-plan.md:195 | prd-plan 把记忆写成用户级并硬编码在 ~/.claude/agent-memory/prd-plan/ 下，正文还要求「适用于所有项目」；这会把某个项目的经验带进另一个项目，正是主人指出的问题。 | `persistent, file-based memory system at '/Users/blue_focus/.claude/agent-memory/prd-plan/'` | 1.8.0 处理 |
| roles-4 | 严重 | agents/dev.md:134 | Dev 的记忆同样是用户级，硬编码在 ~/.claude/agent-memory/dev/，跨项目共享；项目里的踩坑会被 Dev 当成通用经验带到下一个项目。 | `persistent, file-based memory system at '/Users/blue_focus/.claude/agent-memory/dev/'` | 1.8.0 处理 |
| roles-5 | 严重 | agents/qa.md:131 | QA 的记忆也是用户级，存 ~/.claude/agent-memory/qa/；某个项目的接口约定、验收习惯会被带到别的项目，和「agent 跨项目通用、项目约定只来自 active」冲突。 | `persistent, file-based memory system at '/Users/blue_focus/.claude/agent-memory/qa/'` | 1.8.0 处理 |
| uiux-prdplan-2 | 严重 | agents/prd-plan.md:6 | 记忆写成用户级，所有项目共用；这个项目里形成的规划习惯会被带进下一个项目，正是主人指出的串味问题。 | `memory: user` | 1.8.0 处理 |
| uiux-prdplan-3 | 严重 | agents/prd-plan.md:195 | 把作者本机的绝对路径写死进 agent 指令；插件分发到别人机器上这个目录根本不存在，而且它指向用户级记忆区，等于强制跨项目共享。 | `You have a persistent, file-based memory system at '/Users/blue_focus/.claude/agent-memory/prd-plan/'.` | 1.8.0 处理 |
| uiux-prdplan-4 | 严重 | agents/prd-plan.md:325 | 明写『适用于所有项目』，和项目级记忆的决定正好相反；agent 会把某个项目的偏好当成通用规则。 | `Since this memory is user-scope, keep learnings general since they apply across all projects` | 1.8.0 处理 |
| uiux-prdplan-5 | 严重 | agents/prd-plan.md:188 | 这里让 agent 记住代码约定和架构，同一文件后面又明确禁止记这些（理由是读当前项目就能得到）；两条规则直接打架，agent 只能二选一。 | `- Codebase-specific constraints and conventions discovered` | 1.8.0 处理 |
| cross-3 | 中 | agents/dev.md:268 | 整套 Persistent Agent Memory 说明（约 130 行）在 dev、qa、prd-plan 三份文件里逐字重复，还写死“MEMORY.md 目前为空”这种当下状态。同一规则三份副本，改一处漏两处就会互相矛盾，违反“规则只写一次”。 | `Your MEMORY.md is currently empty. When you save new memories, they will appear here.` | 1.8.0 处理 |
| cross-7 | 中 | agents/dev.md:130 | dev 的“该记什么”示例写死了 requestCached 这类别的项目函数名。agent 是跨项目的，这种示例会被当成通用经验带到下一个项目。 | `Performance patterns (requestCached usage, batch query patterns)` | 1.8.0 处理 |
| dev-13 | 中 | assets/codex/agents/dev.toml:4 | Codex 侧生成物把模型写死成 gpt-5.3-codex-spark，正文记忆说明也沿用用户级绝对路径和「适用所有项目」。这与「不得写死具体模型名」「memory 改项目级」两项拍板都不一致（本版 Codex 不改，但问题需记录）。 | `model = "gpt-5.3-codex-spark"` | 1.8.0 处理 |
| dev-14 | 中 | agents/dev.md:132 | 从第 121 行到文件末尾约 148 行是通用记忆系统说明，四个 agent 逐字重复，占 dev.md 一半以上；既增加每次派发的上下文，又和第 206 行「代码模式、架构、文件路径不写进记忆」自相矛盾。 | `# Persistent Agent Memory` | 1.8.0 处理 |
| dev-6 | 中 | agents/dev.md:130 | 记忆示例点名 requestCached 这种某个项目的具体函数，还要求记录「测试/性能模式」。这类实现细节写进跨项目记忆，会把 A 项目的习惯带进 B 项目，正是本次要清理的污染源。 | `- Performance patterns (requestCached usage, batch query patterns)` | 1.8.0 处理 |
| uiux-prdplan-22 | 中 | agents/prd-plan.md:193 | 整段记忆说明书有 130 多行，在 dev、qa、prd-plan 三份里逐字复制；规则一式三份，改一份漏两份，还占掉 agent 大半上下文。 | `# Persistent Agent Memory` | 1.8.0 处理 |

## 2. 别的项目残留（15 条）

apiError / parseBody / requirePerm / requestCached、插件系统、定时发布、修订、软删除、三种数据库方言、Pre-1.0、Changeset、Discussions、forward-only、CSRF、对齐 CLAUDE.md，以及写死 pnpm / tsc / vitest / Playwright / package.json / tests/ / Tailwind 等技术栈。

1.8.0 对应设计：D17 + D10（清残留；测试 / 构建 / 自检命令一律读 project.md 测试基建契约）

| 编号 | 严重程度 | 文件:行 | 问题 | 原文证据 | 处理 |
|---|---|---|---|---|---|
| cross-6 | 严重 | agents/prd-plan.md:50 | 正文点名要复用 apiError、parseBody、requirePerm、requestCached 这些具体函数，第 146 行还要求逐个考虑 SQLite、D1、Postgres 三种方言。这些是某个具体项目的实现细节，违反“agent 跨项目通用、约定一律来自 project.md”的铁律；拆出来的 architect 若照抄，会把上一个项目的栈硬塞进新项目。 | `('apiError', 'parseBody', 'requirePerm', 'requestCached', etc.)` | 1.8.0 处理 |
| dev-5 | 严重 | agents/dev.md:98 | Quality Control 里有一条 Changesets / published package 规则，这是某个 npm 发包项目的发版流程，跟生成项目无关。跨项目写死发版流程，会误导 dev 去加 changeset 或用错发布工具。 | `**Changesets.** If a published package changed, add a changeset.` | 1.8.0 处理 |
| roles-15 | 严重 | skills/agent-mvp/SKILL.md:59 | 执行器把 pnpm、tsc、vitest、Playwright 写死在自检里，和它自己「项目约定一律读 project.md §六」自相矛盾；换到 Python 或 Go 项目会直接跑错命令，属于跨项目带偏。 | `自检：'pnpm lint' → 'tsc --noEmit' → 'pnpm test' → 'pnpm test:e2e'` | 1.8.0 处理 |
| uiux-prdplan-9 | 严重 | agents/prd-plan.md:50 | 写死了别的项目的工具函数名，还让 agent 去读现有实现；PM 禁读 src，Architect 禁读业务代码，照做即越权，同时会把外项目习惯带进来。 | `('apiError', 'parseBody', 'requirePerm', 'requestCached', etc.)` | 1.8.0 处理 |
| dev-7 | 中 | agents/dev.md:77 | 自检序列要求以「项目 package.json 的 scripts」为准，等于默认生成项目是 Node 技术栈。Python / Go 等项目没有 package.json，dev 会找不到验证命令或干脆跳过自检。 | `命令以项目 package.json 实际 scripts 为准，不假设存在某脚本` | 1.8.0 处理 |
| dev-9 | 中 | agents/dev.md:60 | pen 底稿流程把导出格式固定为 html-tailwind，并要求 Tailwind class 原样直用，等于预设生成项目用 Tailwind；同段第 63 行还点名 Taro / uni-app 的专用链路。项目用别的样式或框架方案时会被迫套。 | `按 'project.md' 技术选型把底稿装配成目标框架组件（Tailwind class 原样直用` | 1.8.0 处理 |
| qa-8 | 中 | agents/qa.md:93 | 把测试目录写死成 tests/，可 Agent.md §三 明说测试目录以 project.md 为准、本文件不许硬编码；第 20 行自己也说以 project.md 和项目测试基建为准。遇到 __tests__、spec 或与源码同目录的项目，QA 会把测试写到错地方。 | `只写 'tests/' 下的测试与测试夹具` | 1.8.0 处理 |
| qa-9 | 中 | agents/qa.md:50 | 测试命令写死「以 package.json scripts 为准」，等于假定项目是 Node。agent 要跨项目通用，命令应只从 project.md 的测试基建契约取；执行器也正是这么传的，这里却另立了一个来源。 | `执行项目测试命令（单元 + 接口 + 浏览器，命令以 package.json scripts 为准）` | 1.8.0 处理 |
| uiux-prdplan-10 | 中 | agents/prd-plan.md:110 | 定时发布、修订、软删除是内容站的具体功能，不是通用清单；agent 会拿它当默认追问项，套到无关项目上。 | `Interaction with existing features — does this conflict with scheduled publishing, revisions, soft deletes, etc.?` | 1.8.0 处理 |
| uiux-prdplan-11 | 中 | agents/prd-plan.md:132 | Changeset、Discussions、feature flags 是别的项目的发版流程；铁律要求发版约定只来自当前项目的 project.md，这里等于另立一套。 | `Changeset entries (written as release notes for users, not commit messages).` | 1.8.0 处理 |
| uiux-prdplan-12 | 中 | agents/prd-plan.md:146 | 把三种数据库方言、Pre-1.0 阶段和 locale 假设写成必查项；没有这些前提的项目会被强行套上，还会把外项目的技术判断带进来。 | `**Have I considered all dialects?** SQLite, D1, Postgres.` | 1.8.0 处理 |
| uiux-prdplan-23 | 中 | agents/prd-plan.md:3 | 描述把 agent 说成一个通吃需求与技术的综合规划师，示例是内容审批、多语言内容管理、权限重构，都是别的项目题材；拆成两个 agent 后这句话职责不成立，也指导不了主控派单。 | `This agent transforms rough concepts and PRDs into detailed, actionable implementation plans` | 1.8.0 处理 |
| uiux-prdplan-26 | 中 | agents/prd-plan.md:73 | 项目约定唯一真相源是 active/project.md，CLAUDE.md 只是入口；这里让 agent 去对齐 CLAUDE.md，还让它参考现有代码，两处都会越权。 | `**Patterns to follow** — reference existing code and CLAUDE.md conventions.` | 1.8.0 处理 |
| uiux-prdplan-27 | 低 | agents/prd-plan.md:78 | 前半句说按 project.md 的迁移约定，后半句又写死 forward-only 和命名/注册方式；等于替所有项目定了迁移规则。 | `Migration plan — 按 project.md 的迁移约定（命名/注册/forward-only）。` | 1.8.0 处理 |
| uiux-prdplan-32 | 低 | agents/prd-plan.md:89 | 整节接口设计归 architect（写进 api.md）；其中把 CSRF 当成每个接口的必答项，只适用于特定认证方式，别的项目没有这项。 | `- CSRF requirements.` | 1.8.0 处理 |

## 3. 主控自己读代码 / 切角色（7 条）

规划与部署编排器自己探测项目、读代码、跑 codegraph、代笔改「当前激活角色」、扮演各角色写 prd/ux/project。

1.8.0 对应设计：D2 + D3 + D7（主控只传话；删「当前激活角色」及全部切角色/复位步骤；codegraph 侦察改由 architect；deploy 写 §八 派 architect）

| 编号 | 严重程度 | 文件:行 | 问题 | 原文证据 | 处理 |
|---|---|---|---|---|---|
| roles-10 | 严重 | skills/plan-mvp/SKILL.md:63 | 落盘阶段主控自己改 Agent.md 的「当前激活角色」再自己写 prd/ux，既不是派 agent，也违反 Agent.md §一「字段由人类更新、AI 不得篡改」；角色切换成了主控自导自演。 | `Edit Agent.md「当前激活角色」→ PM → 落盘 → 复位` | 1.8.0 处理 |
| roles-11 | 严重 | skills/plan-feature/SKILL.md:82 | codegraph 侦察（explore / impact / affected）由主控执行，等于主控读了代码并参与需求三态判定；应只由 architect agent 取事实，主控不读代码。 | `Step2 codegraph 侦察（受铁律 2 约束，只取事实）` | 1.8.0 处理 |
| roles-12 | 严重 | skills/plan-feature/SKILL.md:58 | 铁律 6 明确授权主控「代笔改」当前激活角色，和 Agent.md §一「AI 不得自行篡改」直接冲突，也让规划主控可以任意给自己换权限。 | `✅ active/Agent.md「当前激活角色」一行 —— 落盘阶段按批次代笔改（对话定稿即授权，免请示）` | 1.8.0 处理 |
| roles-14 | 严重 | skills/deploy/SKILL.md:62 | 部署编排器自己把角色切成 Architect、写 project.md §八，再复位；这是主控自己给自己发 Architect 权限、自己写 L3，绕开了 agent 派发。 | `写回 §八 前把 'Agent.md'「当前激活角色」切 Architect，写完复位（同 plan-mvp）。` | 1.8.0 处理 |
| roles-8 | 严重 | skills/cc-code/SKILL.md:93 | 运行时协议仍说 prd-plan 一个 agent 兼 PM+Architect，还允许「主控直接扮演各角色」；这正是主控读代码、自己切角色写文件的根源，和已定的「规划主控只传话、pm/architect 各自独立」冲突。 | `不用 agent 时，主控直接扮演各角色亦可。` | 1.8.0 处理 |
| roles-9 | 严重 | skills/plan-mvp/SKILL.md:46 | 进入 plan 模式后主控自己探测项目、读代码，再开始问需求；这违反「主控不读代码、不思考需求」，也让后面写 prd/ux 的 PM 在没有隔离的情况下已经看过 src 和 L3（PM 明令禁读）。 | `Step2 探测项目（Read/Glob/Grep，守上下文最小化）` | 1.8.0 处理 |
| uiux-prdplan-24 | 中 | agents/prd-plan.md:35 | 子代理是按固定角色派出去的，这里让它去读『当前激活角色』；主控文件里那一刻可能写着别的角色，agent 会照错的角色行动。 | `确认当前激活角色与禁读边界` | 1.8.0 处理 |

## 4. QA 能力锁死（9 条）

qa 的 tools 白名单缺 Write / Edit / Glob / Grep 且写死 MCP 列表；Codex 端 qa 沙箱只读；可写范围与 gates.md 授权不一致。

1.8.0 对应设计：D8 + D15（qa 不写 tools 白名单、可直接写 gates.md / 测试目录 / bugs.md；Codex pm / architect / qa 沙箱 workspace-write）

| 编号 | 严重程度 | 文件:行 | 问题 | 原文证据 | 处理 |
|---|---|---|---|---|---|
| cross-4 | 严重 | agents/qa.md:4 | qa 的 tools 白名单列了 76 项，里面却没有 Write、Edit、Glob、Grep。而这个 agent 的核心职责是“写三类测试、写 gates.md、记忆落盘”，拿不到写文件的工具等于干不了本职工作；codex 侧 qa 的沙箱同样被设成只读，问题一致。 | `tools: Agent, ListMcpResourcesTool, Read, ReadMcpResourceDirTool, ReadMcpResourceTool, TaskCreate` | 1.8.0 处理 |
| qa-5 | 严重 | assets/codex/agents/qa.toml:6 | Codex 端把 qa 的沙箱设成只读，可它的核心工作就是写三层测试、写回归测试和写记忆。读死写活，QA 在 Codex 下根本跑不出验收，只能读代码空谈；对比 dev 是可写，落差明显。 | `sandbox_mode = "read-only"` | 1.8.0 处理 |
| roles-7 | 严重 | agents/qa.md:107 | 这里明确禁止 QA 写 gates.md 和 status.md，说「主控原样写回」；但 Agent.md §三把 gates.md 的可写权给了 QA。结果每个编排器主控都自动变成 L4 写者，「QA 唯一写者」名存实亡。 | `只回 QA 报告，⛔ 不写 'gates.md' / 'status.md' —— 主控原样写回` | 1.8.0 处理 |
| cross-5 | 中 | agents/qa.md:4 | qa 的工具白名单把作者机器上装的 MCP 服务逐个写死（chrome-devtools、Playwright、v0、figma、exa、context7 等），还给了 Agent 让它能再派子 agent。换台机器或生成项目没装这些服务时，agent 会以为能用却调不到；也把“浏览器用什么工具”变成了跨项目硬编码，还削弱了 QA 的独立性。 | `mcp__chrome-devtools__click, mcp__chrome-devtools__close_page, mcp__chrome-devtools__drag` | 1.8.0 处理 |
| qa-10 | 中 | agents/qa.md:52 | 报告模板被写成「结构严格如下」，但没有「回归范围来源」栏，也没有未测项 / SKIPPED 清单。可 agent-mvp、agent-feature 都要求 QA 报告带回归范围来源，gates.md 还要求未测项逐条列明。按这个模板交回去，主控拿不到该写进 gates 的关键字段。 | `5. **出 QA 报告**（结构严格如下，供主控回喂 dev）` | 1.8.0 处理 |
| qa-11 | 中 | agents/qa.md:3 | description 对外宣称只读 PRD 和 API 文档、不读其他上下文，但正文定义的灰盒要求读实现代码找入口，还必须读 ux.md 的五态和 project.md 的约定。主控按 description 派活，就会少给它尺子和入口信息。 | `This agent acts as a ruthless test engineer who reads only the PRD and API docs` | 1.8.0 处理 |
| qa-3 | 中 | agents/qa.md:4 | 工具白名单里没有写文件、改文件、文件检索，也没有代码索引。可正文要求它写三层测试、写记忆（第 131 行明说用写文件工具），执行器还要求它用代码索引算回归面。照这份白名单，QA 根本做不了核心工作。 | `mcp__v0__sendChatMessage, Bash` | 1.8.0 处理 |
| qa-6 | 中 | agents/qa.md:93 | 这里把 QA 的可写范围写成「只写 tests/ 下的测试」，漏掉 gates.md；但 Agent.md §三 和 agent-mvp / agent-feature 的 QA 段都写 QA 写 gates.md。结果 gates.md 在普通模式没人认领，或主控和 QA 两边都写，破坏「一个文件一个写者」。 | `只写 'tests/' 下的测试与测试夹具，不改业务代码。` | 1.8.0 处理 |
| roles-6 | 中 | agents/qa.md:3 | QA 的 tools 白名单里没有 Write 和 Edit（也没有 Glob/Grep），但 Agent.md 授权它写测试目录与 gates.md，正文也把「写并跑测试」列为核心职责；实际它只能靠 Bash 落文件，很容易退化成只读评审。 | `tools: Agent, ListMcpResourcesTool, Read, ReadMcpResourceDirTool, ReadMcpResourceTool, TaskCreate,` | 1.8.0 处理 |

## 5. 角色越界（17 条）

PM / Architect 混在同一 agent、顺序写反、dev 把 QA 结果当需求、dev 遇契约冲突自行假设、QA 判定越权、裁决路由不按角色升级。

1.8.0 对应设计：D1 + D9 + D12 + D14（先 PM 后 Architect；dev 冲突停下交回；需求尺子只来自 prd/ux/api/data；3 轮 FAIL 一律交人）

| 编号 | 严重程度 | 文件:行 | 问题 | 原文证据 | 处理 |
|---|---|---|---|---|---|
| cross-8 | 严重 | agents/prd-plan.md:22 | 这个 agent 第一段就要求读 active/project.md 的技术栈，可 Agent.md §三 的 PM 卡片明确写着 PM [禁读] project.md（第147行）。现在靠“一个 agent 兼任两角色”勉强说得通，拆成独立 pm 后若照搬，PM 就名正言顺越权，需求也会被技术方案带偏。 | `pay attention to the patterns documented in '.cc_code/active/project.md'（技术栈 / 编码宪法 / 特殊约束）` | 1.8.0 处理 |
| dev-11 | 严重 | agents/dev.md:104 | 错误处理让 dev 遇到阻塞或契约冲突时自行假设并继续、不要停下问人。但 Agent.md §三 要求 dev「修不动就上报，绝不改需求迁就实现」，执行器也靠「只修不改需求/契约」和 3 轮升级兜底。这条等于授权 dev 沉默偏离 api/data 契约，且全文没有「契约错升级 Architect、需求错升级 PM」的出口。 | `Make the most reasonable assumption, implement based on it, and note the assumption` | 1.8.0 处理 |
| qa-4 | 严重 | agents/qa.md:113 | 升级路径写「主控回退 prd-plan 重新规划」，但 prd-plan 已决定拆成 pm/architect 并删除；三个执行器也都写 3 轮不过就停下交人，agent-mvp 更明确禁止回 prd-plan。照这条走会把已删除的角色叫回来，或绕过人工决策自动重规划。 | `3 轮仍 FAIL → qa 标记「升级」，主控回退 prd-plan 重新规划或交人决策` | 1.8.0 处理 |
| roles-1 | 严重 | templates/Agent.md:152 | 唯一权限出处把角色先后写反了：prd.md 的 PM 条目里说 plan-mvp 内部先 Architect 再 PM。这与全文 PM → Architect 的流水线、以及已定的「先 PM 后 Architect」都相反，会让规划从技术方案倒推需求。 | `独立 agent，内部 Architect→PM 串行切角色` | 1.8.0 处理 |
| uiux-prdplan-13 | 严重 | agents/prd-plan.md:173 | 明写一个 agent 跨 PM 和 Architect 两段；同一上下文先定需求再定技术，技术方案会倒过来改写需求，和『拆成两个独立上下文、严格先 PM 后 Architect』的决定冲突。 | `**角色边界**：本 agent 跨 PM + Architect 两段。` | 1.8.0 处理 |
| uiux-prdplan-15 | 严重 | templates/Agent.md:152 | 这里写的是『独立 agent，内部 Architect→PM 串行』，与已定『严格先 PM 后 Architect、各自独立上下文』正好相反；而且实际 plan-mvp 是命令自身切角色，不是独立 agent。 | `'prd.md' 也可由 '/cc-code:plan-mvp' 支线命令产出（独立 agent，内部 Architect→PM 串行切角色）` | 1.8.0 处理 |
| uiux-prdplan-6 | 严重 | agents/prd-plan.md:9 | 一个 agent 同时自称规划师与架构师，PM 阶段就会顺手做技术选型和取舍，需求层被实现层反向牵着走。 | `You are a Principal Technical Planner and Systems Architect` | 1.8.0 处理 |
| cross-21 | 中 | agents/prd-plan.md:154 | 这个 agent 全文只说“the plan file”，却从不指明该写哪份 active 文件；同时它跨 PM/Architect 两段。没有落盘目标，它可能把技术细节写进 prd.md，或反过来覆盖 api.md，角色边界只靠口头约束。 | `Keep code-level detail in the plan file, not in the chat reply.` | 1.8.0 处理 |
| dev-3 | 中 | agents/dev.md:67 | Step 3 要求 dev 为「qa 验收断言」写测试，把 QA 的 L4 结果当成需求输入。Agent.md §三 明确 dev 禁读 gates.md，需求尺子只能是 prd / ux / api / data，否则就是拿验收结果反推需求，角色污染。 | `为每条 qa 验收断言落地测试` | 1.8.0 处理 |
| dev-8 | 中 | agents/dev.md:39 | 把 project.md 说成实现约定的「唯一准则」，而 Step 2 的必读清单只有 project / ux / api，漏掉 Agent.md §三 列为必读的 data.md（和 status.md）。dev 可能完全不知道数据契约，凭空造表或字段。 | `约定一律以 '.cc_code/active/project.md' 为唯一准则` | 1.8.0 处理 |
| qa-12 | 中 | agents/qa.md:32 | 这里让 QA 拿 project.md 里所有标 ⛔ 的铁律当 Critical 判定，可 Agent.md §三 只允许 QA 用 project.md 的「约定形式」（技术栈 / 测试框架 / 契约风格），第 96 行也这么写。这等于把架构与日志、部署铁律的执法权塞给 QA，与 Architect 的职责重叠。 | `本阶段改动代码违反 'project.md' 任一节标 ⛔ 的铁律 → 一律记 Critical Failure` | 1.8.0 处理 |
| roles-17 | 中 | skills/plan-debug/SKILL.md:43 | 裁决门把「动契约」和「动需求」两类 bug 一律推回 plan-feature，没有按角色升级：契约错应升 Architect，需求错应升 PM。现在等于把架构判断和需求判断都塞回规划命令。 | `① 修复需要改 api.md / data.md 契约` | 1.8.0 处理 |
| roles-22 | 中 | agents/qa.md:113 | 3 轮 FAIL 时让主控「回退 prd-plan 重新规划」；prd-plan 即将删除，而且重新规划的合法归属是 PM（需求）或 Architect（契约），不是这个混合 agent。 | `3 轮仍 FAIL → qa 标记「升级」，主控回退 prd-plan 重新规划或交人决策` | 1.8.0 处理 |
| roles-24 | 中 | skills/agent-mvp/SKILL.md:93 | 升级话术仍指向 prd-plan；该 agent 删除后这句话无法执行，主控也不知道该找谁重规划。 | `⛔ 本命令无规划能力，不回 prd-plan 重规划` | 1.8.0 处理 |
| uiux-prdplan-14 | 中 | agents/prd-plan.md:180 | cc-code 没有『一份综合规划文档』这一层；产物应就地写 prd/ux 与 project/data/api。另起一份 plan 文档会变成和 active 并行的第二个真相源。 | `Produce a comprehensive, well-structured plan document in Markdown.` | 1.8.0 处理 |
| uiux-prdplan-25 | 中 | agents/prd-plan.md:38 | 技术栈对齐、约定复用属于 Architect；验收断言属于 PM；『未覆盖即提问』的标题和动作也对不上（动作其实是登记）。混在一组里会让 pm 越界做技术、architect 越界写断言。 | `**技术栈对齐**：方案是否与 project.md 声明的框架/运行时/数据层一致？` | 1.8.0 处理 |
| uiux-prdplan-28 | 中 | agents/prd-plan.md:94 | 页面、流程、组件拆分、国际化、可访问性、五态全塞在一节；界面与五态是 PM 的 ux.md 域，组件库和国际化是 Architect 的 project.md 域，照这节写会和 ux.md 重复并让 architect 越界写 L2。 | `i18n plan — 按 project.md 的 i18n 方案，所有用户可见字符串走国际化。` | 1.8.0 处理 |

## 6. 单一写者（9 条）

bugs.md / ux.md / gates.md 写者写成命令名、两个写者、主控代写；bugs.md 修完即删与「搬运归档」冲突。

1.8.0 对应设计：D6 + D8 + D13（bugs.md QA 唯一写；PASS 搬 backup/retired/bugs.md；gates.md 由 qa 写；ux.md 指针行由 pm 写）

| 编号 | 严重程度 | 文件:行 | 问题 | 原文证据 | 处理 |
|---|---|---|---|---|---|
| cross-18 | 严重 | templates/Agent.md:24 | 权限表把 bugs.md 的写者定成 /cc-code:plan-debug 命令，QA 卡片的 [可写]（第184行）里没有 bugs.md。按拍板要改成“QA 唯一写者、Dev 修、QA 验”，就得把 bugs.md 加进 QA 可写并从 plan-debug 拿走。另：把 bugs.md 交给 Architect 走不通——Architect 第164行 [禁读] src/ 业务代码，读不了代码和日志就做不了诊断；它的职责是 L3 契约（project/data/api），不是 bug 定位。 | `'/cc-code:plan-debug' 写入 · '/cc-code:agent-debug' 结算删除` | 1.8.0 处理 |
| roles-13 | 严重 | skills/plan-debug/SKILL.md:100 | B-n 由 plan-debug（主控）写进 bugs.md，QA 既不写也不验条目；按已定方向 bugs.md 应是 QA 唯一写者、Dev 修、QA 验，契约错才升 Architect、需求错升 PM。 | `bugs.md 新条目 B-n（复现/期望出处/根因/日志证据/需加探针/方案/影响面，≈17 行）` | 1.8.0 处理 |
| roles-2 | 严重 | templates/Agent.md:24 | bugs.md 的「唯一写者」写的是两个命令，不是角色；§三四个角色里没有任何一个被授权写 bugs.md，等于这个文件在权限表上无人可写。「修完即删」也与全文「内容一字不丢、先搬 retired」的退役规范互相打架。 | `'/cc-code:plan-debug' 写入 · '/cc-code:agent-debug' 结算删除` | 1.8.0 处理 |
| uiux-prdplan-16 | 严重 | templates/Agent.md:24 | bugs.md 现在写的是『诊断命令写、执行命令删』，一个文件两个写者，违反单一写者，也和『QA 唯一写者、Dev 修、QA 验证』不符。Architect 更不能接：它的职责只有技术选型/数据/接口/目录，且禁读 src 业务代码，而 bug 诊断必须读代码和日志。 | `'/cc-code:plan-debug' 写入 · '/cc-code:agent-debug' 结算删除` | 1.8.0 处理 |
| cross-19 | 中 | templates/bugs.md:3 | bugs.md 的写者规则在模板头、CLAUDE.md（54/68）、plan-debug（182）、agent-debug（89）、cc-code skill（85）里各抄一份。按拍板换成 QA 写时要改五六处，漏一处就出现两套说法，违反“规则只写一次”。 | `由 '/cc-code:plan-debug' 写入（诊断落盘），'/cc-code:agent-debug' 读取执行` | 1.8.0 处理 |
| qa-7 | 中 | agents/qa.md:96 | 已拍板方向是 bugs.md 由 QA 唯一写、Dev 修、QA 验证，但 qa.md 全篇没有 bugs.md 和 B-n：真相源不含它，可写范围也不含它。agent-debug 的 QA 段却要它读 B-n、写永久回归测试并在 gates 记 B 段，QA 会把这些当越界拒掉。 | `真相源限定：prd.md / ux.md / api.md / data.md / project.md（仅取约定形式）/ 本阶段被审实现代码。` | 1.8.0 处理 |
| roles-18 | 中 | skills/plan-uiux/SKILL.md:79 | plan-uiux 的「唯一落盘动作」包括往 ux.md 写指针行和改 status，但 ux.md 的唯一写者是 PM；一个绘制命令直接改 L2，破了单写者。 | `✅ 根目录 design.pen + ux.md 指针行 + status.md   —— 唯一落盘动作` | 1.8.0 处理 |
| roles-19 | 中 | skills/just-do-it/SKILL.md:36 | gates.md 记录由主控追加，而且没有 .cc_code 时在项目根另建 gates.md；这让 L4 出现第二个位置和第二个写者，以后分不清哪个是真实验收结果。 | `仍FAIL→报告  ③ gates.md 追加完整记录 → 结束` | 1.8.0 处理 |
| roles-30 | 中 | templates/CLAUDE.md:54 | bugs.md 写成「plan-debug 写 / agent-debug 结算删」，把命令当写者，还说「修完即删」，与「原文搬 retired、一个字不许丢」冲突。 | `未修复 bug 工作上下文（B-n 施工便签，修完即删，常态为空）` | 1.8.0 处理 |

## 7. 规则副本（6 条）

同一规则在多处整段抄写（泳道规则、残留正则、角色权限矩阵、文件索引、真相源表重复行）。

1.8.0 对应设计：D12（角色权限只在 templates/Agent.md §三；泳道出处 parallel-lanes.md；其他处只留一句指针）

| 编号 | 严重程度 | 文件:行 | 问题 | 原文证据 | 处理 |
|---|---|---|---|---|---|
| dev-12 | 中 | agents/dev.md:119 | 泳道模式的四条规则在 dev.md 里整段复述，而单一出处是 skills/cc-code/references/parallel-lanes.md。复述已经出现偏差：status.md 实际只由主控写，这里写成「地基泳道或主控」，规则一多就会继续漂。 | `⛔ 不装 / 不卸依赖，不改共享配置，不写 'status.md' / 'gates.md' —— 这些属于地基泳道或主控。` | 1.8.0 处理 |
| qa-14 | 中 | agents/qa.md:115 | 「收口轮纯净自查」把 plan-feature 的残留正则原样抄了一份，违反规则只写一次；而且让单个 QA 去 grep 全部 active、把别人的文件标 Minor FAIL、要求回写者剥除，既越权又不是它的收口职责（收口在 agent-whole-qa）。 | `命中即 Minor FAIL（「active 残留过程戳记」），指明文件:行回写者剥除` | 1.8.0 处理 |
| roles-28 | 中 | skills/cc-code/SKILL.md:37 | 运行时协议又抄了一份完整角色权限矩阵（掌、必读、可写、禁读），和唯一出处 Agent.md §三重复；任何一边改了另一边就漂，而且这份表里没有 bugs.md 和 design.pen。 | `\| 角色 \| 掌 \| 必读 \| 可写 \| 禁读 \|` | 1.8.0 处理 |
| roles-29 | 中 | templates/CLAUDE.md:44 | 入口文件也抄了一份文件索引加维护者表，维护者列还混着命令名（PM / plan-mvp / plan-feature），和 Agent.md 的「角色唯一写者」不是同一套口径。 | `\| 层 \| 文件 \| 用途 \| 维护者 \|` | 1.8.0 处理 |
| uiux-prdplan-31 | 中 | agents/prd-plan.md:34 | 同一个 ux.md 在真相源表里出现两行，一行写五态矩阵、一行写前端交接规格；同一对象两处描述，读者不知道该以哪行为准。 | `\| '.cc_code/active/ux.md' \| 前端交接规格 \| 涉及 UI 时必读 \|` | 1.8.0 处理 |
| cross-22 | 低 | agents/prd-plan.md:34 | 真相源路由表里 ux.md 写了两行（第33、34行），第二行还用过时的“前端交接规格”说法。同一个文件两份描述，后续改一处留一处。 | `\| '.cc_code/active/ux.md' \| 前端交接规格 \| 涉及 UI 时必读 \|` | 1.8.0 处理 |

## 8. prd-plan 引用与生成链（14 条）

删除 prd-plan 后的悬空引用（README / ARCHITECTURE / init / cc-code SKILL / agent-mvp / 升级话术），以及 Codex 同步 / 校验脚本的沙箱映射、旧 toml 清理。

1.8.0 对应设计：D1 + D15（全仓清除 prd-plan，历史 backup 除外；sync / verify 不坏，删 agent 后旧 toml 被清掉）

| 编号 | 严重程度 | 文件:行 | 问题 | 原文证据 | 处理 |
|---|---|---|---|---|---|
| cross-16 | 严重 | scripts/sync-codex.sh:126 | 沙箱映射按旧角色名写，未命中的角色一律 workspace-write。拆出 pm/architect 后两者都不在表里，architect 会直接拿到能改代码的写权限，违背“规划只读”；反过来现在的 prd-plan 被设成 read-only，可它要写 prd/ux/project/data/api，规划产物落不了盘。 | `"sandbox_mode": f'"{SANDBOX_MAP.get(name, "workspace-write")}"'` | 1.8.0 处理 |
| cross-17 | 严重 | scripts/verify-codex.sh:51 | verify 的顺序是“先拍快照、再重跑 sync、然后比对”，而 sync 只写文件、从不删文件。删掉 agents/prd-plan.md 后，assets/codex/agents/prd-plan.toml 会以孤儿身份留在盘上，快照与现状都有它，diff 照样通过；init --codex 还会把这个已删除角色的 toml 拷进用户项目。openai.yaml 也有同样问题。 | `if diff -r "$SNAP/$name" "$PLUGIN_ROOT/$pair" >/dev/null 2>&1; then` | 1.8.0 处理 |
| cross-11 | 中 | README.md:369 | README 的 agent 表还写着 4 个 agent、prd-plan 兼任 PM+Architect、dev/uiux 是 haiku；同段上面还说“三 agent”。拆分和档位定案后整表失效（README.en.md:372 同样）。第 410 行文件树和 plugin.json 第 4 行的“4 agent”数量也得跟着改。 | `\| 'prd-plan' \| opus \| PM + Architect \|` | 1.8.0 处理 |
| cross-12 | 中 | docs/ARCHITECTURE.md:64 | 这份文档专门回答“新规则该写到哪”，却只认 dev/qa/prd-plan 三个 subagent；拆出 pm、architect 后它们不在名单里，以后角色专属规则就没地方写，uiux 也一直被漏掉（第14、38、77行同）。 | `② dev / qa / prd-plan 这三个 subagent 需要吗？` | 1.8.0 处理 |
| cross-13 | 中 | skills/init/SKILL.md:122 | init 文档告诉用户 codex 侧会装“dev/prd-plan/qa/uiux”四个角色沙箱；拆分后是五个且名字变了。scripts/init.sh 第456行的日志也写死旧名册。 | `'.codex/agents/*.toml'（dev/prd-plan/qa/uiux 角色沙箱，唯一源 'agents/*.md' 的生成物）` | 1.8.0 处理 |
| cross-14 | 中 | skills/cc-code/SKILL.md:93 | 主 skill 仍把规划 agent 说成一个 prd-plan（PM+Architect）；拆分后这个名字不存在，主控和用户都会找错 agent。agent-mvp 第93行“不回 prd-plan 重规划”同样失效。 | `'prd-plan' agent（PM+Architect）服务规划命令；'dev' / 'qa' agent 服务执行命令。` | 1.8.0 处理 |
| cross-15 | 中 | scripts/sync-codex.sh:94 | 模型映射表只有 haiku/sonnet/opus 三档，没有 inherit，且写死了具体 codex 模型名。dev/uiux 改成 inherit 后，脚本会静默落到默认的 gpt-5.4-mini（第120行），codex 侧档位与拍板不符。 | `MODEL_MAP = {` | 1.8.0 处理 |
| dev-4 | 中 | agents/dev.md:3 | description 的第三个示例仍让「执行 prd-plan 和 qa 的所有要求」触发 dev，prd-plan agent 即将删除；同时示例鼓励用户直接贴 PRD / 接口文档就拉起 dev，跳过 PM→Architect 的串行规划。 | `user: "执行prd-plan和qa的所有要求"` | 1.8.0 处理 |
| roles-23 | 中 | agents/dev.md:48 | Dev 的通用铁律仍以「prd-plan 产物」为需求来源；prd-plan 拆掉后这句落空，agent 会找不到该读哪个文件。 | `严格按 prd-plan 产物 + PRD/API 文档实现` | 1.8.0 处理 |
| roles-25 | 中 | README.md:369 | 对外文档仍写 4 个 agent、prd-plan 一肩挑 PM+Architect；拆分后会与真实文件清单不符，用户按文档找 agent 会找不到。 | `'prd-plan' \| opus \| PM + Architect \| 需求→规范→技术方案` | 1.8.0 处理 |
| roles-26 | 中 | docs/ARCHITECTURE.md:14 | 架构文档写 agents/ 是「3+1 → prd-plan/dev/qa/uiux」，拆分后目录与角色映射都过期，喂给后续 agent 会继续复制旧结构。 | `agents/       3+1 个 .md → prd-plan / dev / qa / uiux` | 1.8.0 处理 |
| roles-27 | 中 | scripts/sync-codex.sh:100 | Codex 生成脚本把 prd-plan 映射成 read-only；拆分后新 pm/architect 不在表里，会落到默认 workspace-write，规划角色在 Codex 端反而拿到写权限。 | `"prd-plan": "read-only",` | 1.8.0 处理 |
| uiux-prdplan-30 | 中 | agents/qa.md:113 | 删除 prd-plan 后仍有大量文件指向它：README 两处、架构文档四处、规划与初始化命令、dev 与 qa 的升级路径，甚至 Codex 生成脚本；QA 升级时会去找一个不存在的角色。 | `3 轮仍 FAIL → qa 标记「升级」，主控回退 prd-plan 重新规划` | 1.8.0 处理 |
| cross-23 | 低 | agents/dev.md:3 | dev 的 description 和示例仍把“prd-plan specifications / 执行 prd-plan 的要求”当输入来源；拆分后这个名字没有了，自动路由会指向不存在的东西。 | `prd-plan specifications, or QA requirements` | 1.8.0 处理 |

## 9. 模型档位与子代理约束（10 条）

dev / uiux 写死 haiku、Codex 端写死具体型号；subagent 不能问用户却写着「问用户 / 要求用户 / 用户施压」；frontmatter 格式。

1.8.0 对应设计：D4 + D11 + D15（只写档位不写模型名；问用户一律改「交回主控，由主控交人」）

| 编号 | 严重程度 | 文件:行 | 问题 | 原文证据 | 处理 |
|---|---|---|---|---|---|
| dev-1 | 严重 | agents/dev.md:4 | dev 的模型写死成 haiku，与已拍板的「dev = inherit（跟主会话）」冲突。haiku 是四档里最弱的编码档，复杂实现和质量会明显掉档。 | `model: haiku` | 1.8.0 处理 |
| cross-10 | 中 | agents/dev.md:4 | dev 和 uiux 的模型档位都写死 haiku，拍板是 dev、uiux 用 inherit（跟随主会话）。写死最弱档会让执行质量与主会话脱节，也违反“不得写死具体模型名/档位”的决定。 | `model: haiku` | 1.8.0 处理 |
| cross-20 | 中 | agents/prd-plan.md:157 | prd-plan 里还写着“ask clarifying questions before proceeding”和“Chat replies to the user”，qa 第42行也让“要求用户指出”。subagent 没有 AskUserQuestion，中途不能直接问人；这些句子会让 agent 卡住返回或自行假设，和“主控只传话”的设计冲突。 | `If the plan reveals the request is underspecified, ask clarifying questions before proceeding.` | 1.8.0 处理 |
| dev-10 | 中 | agents/dev.md:73 | 缺测试基建时让 dev「在 status.md 记录并要求补齐」，但 subagent 不能向用户提问，三个执行器也都是把「补齐测试基建」直接作为 dev 段首个任务。这条会让人以为可以停下来等，实际会卡住。 | `若项目无测试基建，先在 status.md 记录并要求补齐，再继续。` | 1.8.0 处理 |
| qa-13 | 中 | agents/qa.md:42 | 多处要 QA「要求用户指出、不给就不开工」「用户对 FAIL 施压时」「若用户要审全仓就拒绝并要求其指出」。但 qa 是 subagent，不能向用户提问，只能通过主控传话。照写会在缺文档时卡住，或把该回报的卡点变成直接向用户发难。 | `若 PRD/API 文档未提供，要求用户指出，不给就不开工` | 1.8.0 处理 |
| qa-15 | 中 | assets/codex/agents/qa.toml:4 | Codex 端把 qa 模型写死成具体型号，已拍板要求用档位、不写死具体模型名。模型一升级这份文件就过时，各 agent 的档位也无法统一调整；而 qa 档位本身还处于待定状态。 | `model = "gpt-5.4-mini"` | 1.8.0 处理 |
| roles-20 | 中 | agents/dev.md:4 | Dev 写死 haiku，已定档位是 inherit（跟主会话）；会固定降智，而且 README 的模型表也照着写死，形成第二处漂移源。 | `model: haiku` | 1.8.0 处理 |
| uiux-prdplan-29 | 中 | agents/prd-plan.md:156 | 子代理没有和主人的对话窗口，产出只能交回主控；『在对话里只给摘要、细节放计划文件』会让关键内容落在一个不存在的地方。 | `In chat, give only a summary (conclusion, decisions needed from the user, next step)` | 1.8.0 处理 |
| uiux-prdplan-8 | 中 | agents/prd-plan.md:157 | 子代理没有向主人提问的能力，也没有和主人的对话通道；让它『先提问再继续』会直接卡住，或者逼它自己编一个答案。文件末尾还要求列一堆待回答问题。 | `If the plan reveals the request is underspecified, ask clarifying questions before proceeding.` | 1.8.0 处理 |
| dev-15 | 低 | agents/dev.md:3 | description 里的换行转义多写了一层反斜杠，YAML 解析后是字面量 \n，示例不会真的换行；生成到 Codex 侧后反斜杠还会再翻一倍，读起来是一长串转义字符。 | `\\n\\n<example>` | 1.8.0 处理 |

## 10. uiux（8 条）

uiux 缺 description / memory / model: inherit，权限未写进 Agent.md §三，plan-uiux 编排器自己握 pencil 工具。

1.8.0 对应设计：D13（补 description、memory: project、model: inherit；写进 Agent.md §三；plan-uiux 只派 uiux 画）

| 编号 | 严重程度 | 文件:行 | 问题 | 原文证据 | 处理 |
|---|---|---|---|---|---|
| cross-9 | 中 | agents/uiux.md:3 | uiux 的 frontmatter 只有 name/model/color：没有 description，引擎判断不了何时该派它，codex 生成的描述直接退化成 “uiux”；也没有 memory，拍板要求所有 agent 用项目级记忆，它连记忆都没有。model 还写死 haiku，按拍板应为 inherit。 | `model: haiku` | 1.8.0 处理 |
| roles-21 | 中 | agents/uiux.md:3 | uiux 也写死 haiku，已定档位是 inherit；会固定用低档模型画原型，和主会话能力脱节。 | `model: haiku` | 1.8.0 处理 |
| uiux-prdplan-1 | 中 | agents/uiux.md:63 | uiux 的所有禁令只写在正文里，frontmatter 没有限定可用工具，子代理实际拿到写文件、跑命令、读源码的全部工具；一句『绝不写』拦不住越权，和 Agent.md 宣称的硬权限自相矛盾。 | `⛔ Never write ux.md / any active/ file / any code` | 1.8.0 处理 |
| uiux-prdplan-17 | 中 | agents/uiux.md:3 | 已定 uiux 跟随主会话模型，这里写死 haiku；主会话用更强模型时，原型质量被人为压低，README 的 agent 表也写着 haiku。 | `model: haiku` | 1.8.0 处理 |
| uiux-prdplan-18 | 中 | agents/uiux.md:2 | uiux 的 frontmatter 只有名字、模型、颜色，没有记忆设置；已定所有 agent 用项目级记忆，它会一条也存不下。 | `name: "uiux" model: haiku color: pink` | 1.8.0 处理 |
| uiux-prdplan-19 | 中 | templates/Agent.md:25 | Agent.md 只在分层表里提了一句 uiux 是 design.pen 的绘制者，§三 角色权限表没有它；uiux 的详细边界因此只存在于 agent 自己的文件里，违反『权限唯一出处 = Agent.md §三』。 | `'/cc-code:plan-uiux'（编排）+ 'uiux' agent（逐帧绘制）` | 1.8.0 处理 |
| uiux-prdplan-20 | 中 | skills/plan-uiux/SKILL.md:64 | 风格锁阶段要建组件、画样板页，但流程只在这一步说『建/画』，派 uiux 写在下一步；编排器自己又握着 pencil 执行权限，同一个 .pen 可能出现两个写者。 | `① 风格锁：加载风格 → 建 reusable 组件 → 画 1~2 页样板` | 1.8.0 处理 |
| uiux-prdplan-34 | 低 | agents/uiux.md:2 | 其余三个 agent 都有职责描述，uiux 没有；主控只能按名字硬派，无法根据能力描述判断何时该用它。 | `name: "uiux" model: haiku color: pink` | 1.8.0 处理 |

## 11. 被驳回的 5 条

| 编号 | 原发现 | 驳回理由 |
|---|---|---|
| uiux-prdplan-7 | 真相源表要求『规划技术方案前必读 project.md』，但 PM 在 Agent.md 里明确禁读 project/data/api；照这张表做，PM 会先看技术方案再写需求。 | 该行写的是『规划技术方案前必读』，与同文件『先 PM 后 Architect』顺序一致，推不出 PM 先看技术方案，属误读。 |
| uiux-prdplan-21 | 摘要、范围、详细设计三段是通用方案文档骨架，和 prd.md 的模块清单、Out of Scope 重复；拆开后 pm 与 architect 会各写一份同样的东西。 | 第59行只是一句执行摘要定义，prd 模板并无摘要段，所谓与模块清单/Out of Scope 重复是拆角色后的推测，非现有缺陷。 |
| uiux-prdplan-33 | 测试策略整体归 architect（写进 project.md 的测试约定）；每阶段的验收断言清单归 pm（prd 的 A 编号）。现在混在一起，两边容易互相代写。 | 证据只是一条通用单元测试项，本节并没有把断言清单混进来，测试策略归 architect 属拆角色后的分工建议，不是现有矛盾。 |
| uiux-prdplan-35 | 记忆排除项还在说 CLAUDE.md，但项目约定已经全部搬到 active/*，CLAUDE.md 只是入口；按这句执行会把该记的项目约定也漏掉。 | 该句排除的是『CLAUDE.md 已载内容』，项目约定在 active/* 并不受它排除，『会把该记的漏掉』方向理解反了。 |
| roles-16 | design.pen 的写者是 plan-uiux 命令加 uiux agent，但 uiux 不在 §三的四个角色里，权限表也没有它的可写域；等于一个实际写者游离在角色体系外。 | uiux 是 plan-uiux 派出的绘制工人而非激活角色，其 design.pen 写域已在 Agent.md §二和 plan-uiux 越权红线上写明，不构成 §三 的权限缺口。 |
