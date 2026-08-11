# cc-code Plugin

> 极简开发工作流系统 —— 把 LLM 装进「认知沙盒」，让它成为精确、稳定、可溯源的自动化软件工业母机。
> 基于四大铁律：**上下文最小化 · 决策串行 · 记忆外部化 · active 三判据**。

## 设计哲学

```
① 记忆/逻辑/状态全外部寄存 ── 不交给 agent，落 .cc_code/ 静态文件
② 责任垂直化 ── 每角色只掌一层，上下文干净，禁止越权
③ active 三判据 ── 最新 + 最完整 + 最纯净（0.9.0 起为硬铁律）
④ 防 vibecoding 三病：
   逻辑偏离 → 信息流单向 + codegraph 不生成意图层
   冗余堆积 → 就地收敛写入 + whole-qa 冗余检测
   自傲跳过 → 多角色 + 测修独立上下文
```

## active 三判据（0.9.0 核心）

`active/` 是唯一真相源，必须**永远**保持最新、最完整、最纯净 —— 三条都可判真假：

```
   最新   ── 同一对象在 active 只有一处描述, 且是当前态
             ⛔ 禁新开「## 增量 F-n」章节 → 就地改写对应小节
             治的病: 同一 interface/path/规则 散成 N 段补丁, 读者得脑内拼接

   最完整 ── 每个待验维度都有永久稳定编号, 分母算得出
             A 编号 (prd.md §1.5 主表) = 业务逻辑 / 链路 / 接口
             U 编号 (ux.md  §2.3 矩阵) = UI 布局 / 交互五态   ⭐0.9.0 新增
             治的病: 有维度没编号 → 覆盖率黑洞, 漏了查不出来

   最纯净 ── 每一行都在答「现在是什么」, 不是「当时怎么决定的」
             过程产物 → docs/plans/  ·  逐轮验收详情 → docs/qa/
             历史版本靠 git (.cc_code 在版本控制内, 不另存快照)
             治的病: 裁决记录/迁移清单/历史轮次堆在 active
```

**写入前三问**（任一不通过即停手重判）：

| # | 自查 | 不通过怎么办 |
| --- | --- | --- |
| 1 | active 里已有对应小节吗？ | 有 → **就地改写**，⛔ 禁新开章节 |
| 2 | 这段在答「现在是什么」吗？ | 不是 → 落 `docs/plans/` 或 `docs/qa/` |
| 3 | 别的层已经有了吗？ | 有 → 不写，只留指针（跨层唯一源） |

**收敛时机 = 每次写 active 的动作本身**，不是事后清理，无需额外工具：

| 时机 | 触发者 | 动作 |
| --- | --- | --- |
| 增量落盘（`plan-prd-feature` Step8） | PM / Architect | 就地改写对应小节 + 台账 1 行 + 过程落 `docs/plans/` |
| 单轮验收收尾（`whole-qa` ❸❺ / QA） | QA | 更新 `gates.md` 矩阵**对应行**，详情落 `docs/qa/` |
| 契约校准（发现漂移） | Architect | 就地改写 `data.md` / `api.md` 对应小节 + 台账 1 行 |
| 场域升级（`init` D4） | init | 存量归位：旧格式 → 新骨架，历史迁 `docs/`（零删除） |

## 安装

```bash
# 1. 添加本仓库为 marketplace
/plugin marketplace add https://github.com/weiyi88/cc-code

# 2. 安装 cc-code 插件
/plugin install cc-code
```

安装后自动获得 `/cc-code:*` 命令族、13 个 skill 与 3 个配套 agent。

## 完整生命周期

```
/cc-code:init          搭场域（8模板 + 迁移散落物 + 盖版本戳
                       + 刷新 .cc_code/README.md 使用手册）
                       旧版场域自动走升级迁移（零删除）
       ↓
会话开启(2步)          Read Agent.md(锁角色) → status.md(定坐标)
       ↓
/cc-code:plan-prd-mvp  ⭐第一动作 call EnterPlanMode → plan 内探测+三件套
                       +逐点交谈至通顺 → 落地 prd.md
       ↓
/cc-code:agent-to-mvp  编排实现（PM→Architect→Dev→QA，FAIL≤3轮回环）
       ↓
/cc-code:whole-qa      全量验收（功能 + 冗余，FAIL≤3轮回环）
       ↓
部署                   /cc-code:vercel_supabase 或 /cc-code:cf_online

────────── MVP 交付后，功能迭代走这条支线 ──────────

/cc-code:plan-prd-feature  ⭐第一动作 call EnterPlanMode → 规范体检+锁基线
                           +codegraph 算爆炸半径 → 冲突逐条硬门控裁决
                           +三件套交谈至通顺 → 按层分批切角色落 L1/L2/L3
       ↓
/cc-code:agent-to-mvp      编排实现（Dev→QA）

────────── 任意时刻 ──────────

/cc-code:experience-summary  踩坑/复盘 → 提炼设计准则 → references/ 资料库
/cc-code:init                插件升级后再跑一次：场域迁移 + 手册刷新到最新
```

**主线是 3 个 skill 串起来**：产需求 → 编排实现 → 全量验收。
`cc-code` skill 在背后管运行时协议（角色路由 + 分层），`init` 是入场。无 Stop Hook，所有状态由 AI 顺手写。

## 快速开始

在任意项目根目录：

```
/cc-code:init
```

- **新项目**：直接搭场域 + 盖版本戳，切 PM 等需求。
- **旧项目（无 `.cc_code/`）**：备份旧 `CLAUDE.md` → `.cc_code/backup/YYYY-MM/CLAUDE.md.legacy`，AI 按映射表分拆归并到 `active/` 各文件，再用入口模板覆盖根目录 `CLAUDE.md`。
- **旧版场域（已有 `.cc_code/` 但版本戳缺失或更旧）**：自动走升级迁移 —— **归档 → 清点 → 迁移 → 校验 → 归位 → 盖戳**，`init.sh` 中 `rm` 出现 0 次，旧物只 `cp` 快照与 `mv` 归位，内容永远可回溯。校验门未过则停手，戳不盖，下次 `init` 仍判为待升级。

> 根目录 `CLAUDE.md` 是纯入口引导（会话开启协议 + 三铁律 + 文件索引），不含业务状态。Claude Code 原生自动加载它，从而被引导进 `.cc_code/` 状态机。

## 可选增强：codegraph（0.10.0 起深度集成）

[codegraph](https://github.com/colbymchenry/codegraph) 是代码知识图谱索引。cc-code **不依赖它也能全流程跑通**，装了则四项能力升级：

| 能力 | 装了 | 不装（降级形态） |
| --- | --- | --- |
| 增量规划爆炸半径 | `impact` 算传递闭包，改一处知道炸到哪 | Glob/Grep 表层猜测，半径估偏 |
| 冗余检测 | 自动扫死代码 / 孤儿文件 / 重复实现 | `whole-qa` 冗余项基本瞎 |
| 精准回归 | `affected` 沿 import 图算出只需跑的测试 | 全量跑，QA 时间成本高 |
| 契约校准 | Architect 自动核对 `api.md` / `data.md` 实现状态 | 手工 Grep 核对，易漏 |

### 全静默设计（人零心智负担）

```
装一次        /cc-code:init 检测到未装 → 弹选择框介绍收益 → 人点头后装
              npm i -g @colbymchenry/codegraph   ⚠️包名带 scope
建索引        init 静默后台建，绝不阻塞入场
保持新鲜      codegraph 自带 watcher 自动追写 + daemon 复活时 catch-up 补账
              ⛔ 人永不需要手动 sync / index
异常          只报一行（库损坏 / 建议重建），健康时零输出
```

`init.sh` 只探测不安装（改全局环境是高风险操作，且脚本无法交互），装不装由人决定。

### 铁律：codegraph 只答「是什么」，不答「应该是什么」

| 角色 | 权限 | 说明 |
| --- | --- | --- |
| PM | ❌ 完全禁止 | 用现状反推意图 = L1/L2 被 L3 污染 = 系统失效 |
| Architect | ✅ 完全开放 | 校准 L3 契约，`explore`/`node`/`files`/`callers`/`callees`/`impact` |
| Dev | ⚠️ 只读定位 | 找现有实现避免重复造轮子，不推翻契约 |
| QA | ⚠️ 双重限制 | 只用于找入口 / 算回归面，**永不当需求尺子** |

### `affected` 精准回归的前提

测试基建契约登记在 `active/project.md` §六。三条铁律：

1. **测试代码必须入 git** —— codegraph 尊重 `.gitignore`，被 ignore 的测试不进索引 → `affected` 永久失效。该 ignore 的是测试**产物**（`coverage/` / `*.png`），不是测试**代码**。`init` 新建的 `.cc_code/test/` 默认不 ignore。
2. **测试必须 import 被测源码** —— 静态 `import` ✅ 动态 `await import()` ✅ 纯 HTTP 打接口 ⛔（无 import 边可追）。
3. **非标准命名必须登记 glob** —— 默认只认 `*.spec.*` / `*.test.*` / `__tests__/`，其余需 `--filter`。

## Skill（13 个）

**框架核心（管流程）**

| skill | 触发 | 用途 |
| --- | --- | --- |
| `init` | `/cc-code:init` | **入场 + 升级** 三轨初始化（新建/已最新/旧版升级迁移）；判定链迁移散落物；升级走「归档→清点→迁移→校验→归位」，**全程零删除** |
| `cc-code` | 自动 | **运行时协议** 角色路由 + 文件分层 + 状态机约束 |
| `plan-prd-mvp` | `/cc-code:plan-prd-mvp` | PRD 生成器（第一动作 EnterPlanMode，plan 模式逐点交谈至逻辑通顺） |
| `plan-prd-feature` | `/cc-code:plan-prd-feature` | **增量需求规划器**（MVP 后迭代：规范体检 + codegraph 算爆炸半径 + 冲突逐条硬门控 + 按层分批切角色落 L1/L2/L3） |
| `agent-to-mvp` | `/cc-code:agent-to-mvp` | MVP 生命周期编排（PM→Architect→Dev→QA + qa→dev 循环） |
| `whole-qa` | `/cc-code:whole-qa` | **全量验收 + 修复闭环**（逐页逐按钮逐接口 + 冗余检测，FAIL≤3轮回环） |
| `experience-summary` | `/cc-code:experience-summary` | **项目级经验沉淀器**（踩坑/复盘 → 提炼准则 → 主人过目 → 落 `references/[角色]-[事件域]-references.md` + INDEX 按需读取） |
| `short` | `/cc-code:short` | 极简回复（不需要思考时，≤50 字符） |

**工具外挂（干活的，与状态机无关）**

| skill | 用途 |
| --- | --- |
| `project_resume` | 读取真实技术栈生成标准化项目介绍文案 |
| `login_auto` | Supabase Auth + Resend 通用登录系统 |
| `vercel_supabase_deployment` | Vercel + Supabase 一键部署 |
| `cf_online` | Next.js 部署到 Cloudflare Pages (Edge) |
| `next2taro` | Next.js UI → Taro 小程序转换 |

## Agent（3 个，cc-code 配套）

三 agent 与 cc-code 角色串行绑定，**独立于任何具体项目**，所有项目约定一律 defer 到 `.cc_code/active/project.md`：

| agent | 模型 | cc-code 角色 | 职责 |
| --- | --- | --- | --- |
| `prd-plan` | opus | PM + Architect | 需求→规范→技术方案；产出 prd/ux/project/data/api + `docs/plans/phaseN-plan.md` |
| `dev` | haiku | Dev | 按规格实现代码 + 三层测试；自检 lint/tsc/test/e2e |
| `qa` | sonnet | QA（灰盒） | 写+跑三层测试（逻辑/接口/浏览器），结构化 FAIL 清单回 dev，≤3 轮循环 |

> agent 定义「怎么干」，cc-code 定义「干什么+在哪干」，`.cc_code/active/` 是唯一耦合接口。

## 文件分层（L0~L4）

```
┌ L0 控制 ─ Agent.md(宪法/权限表)  status.md(坐标+里程碑) ─ 人/AI ┐
├ L1 意图 ─ prd.md(分模块逻辑+规则+验收断言 A1..An) ────── PM ───┤
├ L2 表现 ─ ux.md(视觉规格+五态矩阵, U 编号发号处) ────── PM ───┤
├ L3 实现 ─ project.md  data.md  api.md ───────────── Architect ┤
├ L4 验收 ─ gates.md(A+U 追溯矩阵, 标准在 prd/ux) ─────── QA ───┤
└ backup/ ─ 冷归档（AI 按需移入，默认不入库）─────────────────────┘
```

### 信息流铁律（单向，违反即失效）

```
   L1 意图 ──► L2 表现 ──► L3 实现 ──► 代码
    ▲                                   │
    └───────── L4 验收 ◄────────────────┘

  ① L4 只拿 L1/L2 当尺子，绝不拿 L3/代码当尺子
     否则 QA 退化为「拿代码验代码」，验收彻底失效
  ② codegraph 只准校准 L3（事实层），永不生成 L1/L2/L4
  ③ Dev/QA 禁改 prd/ux/api 让测试通过
  ④ 标准与结果永不同文件：标准在 L1/L2（PM 写），结果在 L4（QA 写）
     写标准的人 ≠ 判结果的人 → 制衡成立
```

## 目录架构

### 插件侧（github.com/weiyi88/cc-code）

```
cc-code/
├── .claude-plugin/   marketplace.json + plugin.json
├── skills/           13 个 skill 目录
├── agents/           3 个 agent（prd-plan / dev / qa）
├── scripts/          init.sh（三轨脚手架 + 散落物迁移 + 升级归档/清点/归位，零 rm）
├── templates/        8 个 md 骨架（L0~L4，含写入纪律 + 变更台账）
├── docs/             ARCHITECTURE.md
└── 无 hooks/         （0.5.0 砍除，无自动化机械活）
```

### 项目侧（/cc-code:init 生成）

```
项目根/
├── CLAUDE.md              🧭 入口引导（Claude 原生自动加载，纯协议不含业务状态）
└── .cc_code/
    ├── README.md          🧭 使用手册（每次 init 刷新：项目逻辑 / Skill / 使用方案 / 示例）
    ├── active/          🔴 热数据（每次对话必读，按 L0~L4 分层）
    │   ├── Agent.md       L0 角色路由表 / 最高宪法
    │   ├── status.md      L0 当前坐标 + 里程碑（AI 自管长度）
    │   ├── prd.md         L1 分模块业务逻辑 + 规则 + 验收断言（PM）
    │   ├── ux.md          L2 视觉规格 + 交互五态矩阵（PM）
    │   ├── project.md     L3 技术宪法（Architect）
    │   ├── data.md        L3 数据契约 interface ↔ DB 列（Architect）
    │   ├── api.md         L3 接口契约 method/path/入参/出参/错误码（Architect）
    │   └── gates.md       L4 A+U 验收追溯矩阵 + 未关闭 FAIL（QA，Dev 禁读）
    ├── docs/plans/      🔵 阶段方案（Architect 产出，Dev 按 phase 读）
    ├── docs/qa/         🔵 全量验收报告 + 元素清单（whole-qa 产出）
    ├── images/          🔵 截图（init 迁移，扁平存放）
    ├── scripts/         🔵 散落脚本归档
    ├── references/      🟢 项目级经验资料库（experience-summary 产出，INDEX 索引 + 角色按需读）
    ├── README.md        🧭 使用手册（init 每次刷新到最新版：逻辑/Skill/使用方案/示例，新手零门槛）
    ├── backup/          🧊 冷数据（含 CLAUDE.md.legacy / migration_manifest / needs_review；默认不入库）
    │   └── YYYY-MM/     升级时：pre-upgrade-<旧版>/ 只读快照 + upgrade_audit.md + superseded/ 归位物
    └── .cc_code_version 🔖 场域版本戳（决定 init 是否走升级迁移）
```

## 角色串行

```
PM ──► Architect ──► Dev ──► QA
(逻辑)   (契约)      (编码)   (验收)
```

每个角色由 `active/Agent.md` 路由表锁定「必读/可写/禁读」，禁止越权。

| 角色 | 掌 | 可写 | 禁读 |
| --- | --- | --- | --- |
| PM | L1+L2 | prd, ux | src/, project, data, api |
| Architect | L3 | project, data, api, docs/plans | src/ 业务码 |
| Dev | 代码 | src/, 测试目录 | gates |
| QA | L4（灰盒） | gates, 测试目录 | 无关历史码 |

## 经验沉淀（references）

开发中踩坑/排障/方案复盘暴露的**设计经验**，用 `/cc-code:experience-summary` 沉淀为项目级 references：

```
/cc-code:experience-summary
       ↓
提炼「必答问题 + 设计准则」→ 主人过目 → 落盘
       ↓
.cc_code/references/[角色]-[事件域]-references.md
  例：architect-bull-redis-queue-references.md
       ↓
INDEX.md 登记一行「何时读」→ 角色接到任务先扫索引，命中才读（按需，非全读）
```

- **项目级**：跟随项目走，不进插件、不进全局。
- **精炼**：只写「设计/验收时怎么思考、怎么做」，≤30 行，禁溯源流水账。
- **准出价值**：每条准则必须可执行 —— 能据此否决一个方案。

## 无 Hook 设计

cc-code **不使用 Stop Hook**。所有 `.cc_code/` 文件都由 AI 在对话内顺手写，无自动化机械活。

> 设计沿革：早期版本有 Stop Hook 做 `errors.md` 冷切片。0.5.0 起 `errors.md` 废除（坑写进 commit message / git blame，天然留痕），Hook 失去唯一职责，一并砍除。符合「一个东西只做自己的逻辑」—— 没逻辑就别留。

## 散落物迁移（init 判定链）

`/cc-code:init` 用「默认不动」判定链清理项目根散落文件，宁可漏搬绝不误杀：

```
项目根文件 ──► ① 保护白名单？ ──► ② git 已追踪？ ──► ③ 被引用？ ──► ④ 名字像临时物？
                 (任一命中即 SKIP)                              (才搬)
                                                                  ↓ 都不匹配
                                                              原地保留 + 记 needs_review.md
```

旧版「默认搬走」会误杀 `setup.py`/`manage.py`/`AGENTS.md`/`build.sh` 等基建 —— 已反转。

## 新手入门（降低上手难度）

每个项目 init 后，`.cc_code/README.md` 会生成一份**使用手册**（项目逻辑 / Skill 一览 / 使用方案 / 使用示例），并且**每次 `/cc-code:init` 自动刷新到最新版** —— 不熟悉 cc-code 的协作者直接读它即可，无需翻本仓库。

## 版本变更

### 0.10.0 — codegraph 全静默深度集成

本版解决一个结构性缺陷：**codegraph 是「被引用的假设」**。0.9.0 的文档 4 处写着它的纪律（「只准校准 L3」），却零处告诉人怎么让它就位 —— 没有装载、没有体检、`whole-qa` 声明用它扫冗余但 `allowed-tools` 一个工具都没给。能力覆盖仅 4/15。

| # | 改动 | 病根 |
| --- | --- | --- |
| 1 | `init.sh` 新增 `ensure_codegraph()`：探测 CLI → 探测库 → 后台建索引，静默五铁则，任何分支 `return 0` | 装载缺口：新项目跑完 init 索引库根本不存在，`plan-prd-feature` 一调就空 |
| 2 | `whole-qa` `allowed-tools` 补 4 个 codegraph MCP 工具 | ⭐真 BUG：`inventory.md` §六 明写用它扫死代码，权限却没给，声明的能力调不动 |
| 3 | `project.md` 新增 §六 **测试基建契约** + `init` 新建 `.cc_code/test/` | 模板全文零处提「测试」，`agent-to-mvp` 却要求 `tests/{unit,api,e2e}` → 约定悬空；测试被 gitignore 屏蔽则 `affected` 永久失效 |
| 4 | `affected` 接入 4 处回归门（`agent-to-mvp` Dev→QA / qa→dev 循环 / `whole-qa` 第5条 + FIX轮） | 原「同模块已 PASS 项」是人凭直觉画的圈，跨模块隐式依赖抓不到 |
| 5 | `plan-prd-feature` Step2 扩为四路侦察，补 `impact` / `files` / `affected` | `callers` 只有一层视野 → 半径估小 → 规划以为改一处、Dev 实际动五处 |
| 6 | Step2 前置 **新鲜度保险**（`pendingChanges` 非 0 先 `sync`） | daemon 空闲 5min 自杀，期间改动无人追写，存在「第一次查询拿到旧索引」的竞态窗口 |
| 7 | 索引体检门 ×2（`agent-to-mvp` 前置 + MVP 收口） | 冗余清单与回归范围都建立在索引之上，索引坏了这两项结论不可信 |
| 8 | `Agent.md` / `CLAUDE.md` 新增 **codegraph 角色权限矩阵** | 原文只有「只准校准 L3」一句，未落到角色粒度 |
| 9 | `gates.md` 新增 **回归范围来源**表 | 回归跑了「哪些」比跑了「多少」更重要，范围算错全绿也是假绿 |

**能力覆盖 4/15 → 15/15**：查询 9（explore/query/node/callers/callees/impact/affected/files/status）+ 写入 3（init 静默建库 / sync 新鲜度保险 / index 只提示不执行）+ 运维 3（install 注册 MCP / unlock 清僵死锁 / daemon 自管）。

**为什么不装 Hook 自动同步**：codegraph 自带 watcher + catch-up 已自愈，装 Hook 是重复劳动；且 cc-code 的卖点是「无 Hook，状态由 AI 顺手写」。

**为什么脚本不自动 `npm i -g`**：改全局环境是高风险操作，且 shell 脚本无法交互。改由 AI 弹选择框介绍收益后由人决定 —— 一次性告知，不是持续负担。

**升级方式**：旧项目跑 `/cc-code:init` 即判 Track D。装了 codegraph 则索引自动就位；未装则弹一次选择框。

### 0.9.0 — active 三判据 + U 编号 + 就地收敛

本版解决一个结构性缺陷：**`active/` 被当成日志在写**。增量协议原本是「追加 `## 增量 F-n` 章节」，N 次迭代后同一个 interface / path / 规则散成 N 段补丁，`active` 行数线性膨胀且无收敛出口。

| # | 改动 | 病根 |
| --- | --- | --- |
| 1 | `plan-prd-feature` 落盘协议：**追加章节 → 就地收敛改写** + 文末变更台账 1 行 + 过程产物落 `docs/plans/` | 旧协议明写「追加增量章节，不覆写」，无收敛出口 |
| 2 | `ux.md` 新增 **`U` 编号**（`U<页>.<元素>.<态>`），与 `A` 编号同款铁律（永久稳定 / 禁重排 / 作废加删除线） | 旧版只有 `testid`（定位锚点，非判定项）→ 一元素 5 个态却只有 1 个锚点，「哪个态没过」无号可挂 |
| 3 | `gates.md` 追溯矩阵扩为 **`A` 段 + `U` 段**；明禁新开「第 N 轮」章节，改为**就地更新对应行**；覆盖率四分母 | 旧实践把 gates 写成逐轮流水，「某断言现在什么状态」要跨 N 轮 grep |
| 4 | `whole-qa` 元素分母改 **`ux.md` 声明 ∪ 运行时 DOM**，差集必报（声明未实现 / 实现未声明） | 分母纯来自运行时 → 每轮重扫，编号不稳定，跨轮无法机器对比 |
| 5 | `init` **D4 由「只体检 `Agent.md`」扩为 8 文件骨架格式体检** + D4.1 存量归位表 | ⭐ 旧版 D3 判据是「文件在 active/ 里就算 OK」，内部格式无人过问 |
| 6 | `init` **Track C 增加轻量骨架体检** | 旧版 Track C 零体检 → 盖戳后格式再也无人检查，旧格式永久留存 |
| 7 | `init` **D5 校验门增加「骨架完备」硬门** | 旧版只查内容不丢，不查格式对不对 |
| 8 | 5 个 L1~L3 模板加**写入纪律段 + 变更台账**；`Agent.md` / `CLAUDE.md` 加 **active 三判据铁律** | 纪律不进模板 = 不进每次会话的上下文 = 等于没有 |

**升级方式**：旧项目跑 `/cc-code:init` 即判 Track D，D4 会逐文件体检并报归位清单（全程零删除，D1 快照是回滚点）。

**为什么不做独立的 converge 清理工具**：收敛应该是**写入动作的一部分**（写完即收敛），而不是事后清理。若靠常设工具定期清，每次增量仍会先碎再清，无限循环且依赖人工触发。

## License

MIT
