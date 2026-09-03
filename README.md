# cc-code

> Version: **0.12.0** ｜ [English](./README.en.md) ｜ 简体中文

> 极简开发工作流系统 —— 把 LLM 装进「认知沙盒」，让它成为精确、稳定、可溯源的自动化软件工业母机。
> 基于四大铁律：**上下文最小化 · 决策串行 · 记忆外部化 · active 三判据**。

---

## 目录

- [设计哲学](#设计哲学)
- [核心逻辑](#核心逻辑)
- [安装](#安装)
- [完整生命周期](#完整生命周期)
- [快速开始](#快速开始)
- [可选增强：codegraph](#可选增强codegraph)
- [Skill 一览（14 个）](#skill-一览14-个)
- [Agent（3 个）](#agent3-个)
- [文件分层（L0~L4）](#文件分层l0l4)
- [目录架构](#目录架构)
- [角色串行](#角色串行)
- [经验沉淀（references）](#经验沉淀references)
- [无 Hook 设计](#无-hook-设计)
- [散落物迁移](#散落物迁移)
- [新手入门](#新手入门)
- [License](#license)

---

## 设计哲学

LLM 写代码有三病：**写着写着忘了目标、上下文越滚越脏、凭记忆瞎答**。
cc-code 的处方：**把记忆、状态、规则全部外部寄存到 `.cc_code/` 静态文件**，AI 每次会话按协议读文件定位自己，而不是靠脑容量。

```
① 记忆/逻辑/状态全外部寄存 ── 不交给 agent，落 .cc_code/ 静态文件
② 责任垂直化 ── 每角色只掌一层，上下文干净，禁止越权
③ active 三判据 ── 最新 + 最完整 + 最纯净（硬铁律）
④ 防 vibecoding 三病：
   逻辑偏离 → 信息流单向 + codegraph 不生成意图层
   冗余堆积 → 就地收敛写入 + whole-qa 冗余检测
   自傲跳过 → 多角色 + 测修独立上下文
```

## 核心逻辑

### 角色串行（同一时刻只有一个角色被激活）

```
PM ──► Architect ──► Dev ──► QA
(逻辑)   (契约)      (编码)   (验收)
```

每个角色由 `active/Agent.md` 路由表锁定「必读 / 可写 / 禁读」，禁止越权。

| 角色 | 掌 | 可写 | 禁读 |
| --- | --- | --- | --- |
| PM | L1+L2 | prd, ux | src/, project, data, api |
| Architect | L3 | project, data, api | src/ 业务码 |
| Dev | 代码 | src/, 测试目录 | gates |
| QA | L4（灰盒） | gates, 测试目录 | 无关历史码 |

### 文件分层（先认层，再认角色）

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

### active 三判据

`active/` 是唯一真相源，必须**永远**保持最新、最完整、最纯净：

```
   最新   ── 同一对象在 active 只有一处描述, 且是当前态
             ⛔ 禁新开「## 增量 F-n」章节 → 就地改写对应小节

   最完整 ── 每个待验维度都有永久稳定编号, 分母算得出
             A 编号 (prd.md §1.5 主表) = 业务逻辑 / 链路 / 接口
             U 编号 (ux.md  §2.3 矩阵) = UI 布局 / 交互五态

   最纯净 ── 每一行都在答「现在是什么」, 不是「当时怎么决定的」
             过程产物不落盘（change-log 留痕） ·  逐轮验收详情 → docs/qa/
             历史版本靠 git (.cc_code 在版本控制内, 不另存快照)
```

## 安装

```bash
# 1. 添加本仓库为 marketplace
/plugin marketplace add https://github.com/weiyi88/cc-code

# 2. 安装 cc-code 插件
/plugin install cc-code
```

安装后自动获得 `/cc-code:*` 命令族、14 个 skill 与 3 个配套 agent。

## 完整生命周期

```
/cc-code:init          搭场域（8模板 + 迁移散落物 + 盖版本戳
                       + 刷新 .cc_code/README.md 使用手册）
                       旧版场域自动走升级迁移（零删除）
       ↓
会话开启(2步)          Read Agent.md(锁角色) → status.md(定坐标)
       ↓
/cc-code:plan-prd-mvp  ⭐第一动作 call EnterPlanMode → plan 内探测+三件套
                       +逐点交谈至通顺 → 落盘五件（prd/ux/project/data/api）
                       （落盘即定稿，无二次验收）
       ↓
/cc-code:agent-to-mvp  纯执行（读定稿文档，Dev→QA，FAIL≤3轮回环，中途零确认）
       ↓
/cc-code:whole-qa      全量验收（功能 + 冗余，FAIL≤3轮回环）
       ↓
部署                   /cc-code:vercel_supabase 或 /cc-code:cf_online

────────── MVP 交付后，功能迭代走这条支线 ──────────

/cc-code:plan-prd-feature  ⭐第一动作 call EnterPlanMode → 规范体检+锁基线
                           +codegraph 算爆炸半径 → 冲突逐条硬门控裁决
                           +三件套交谈至通顺 → 就地收敛落盘（落盘即定稿）
                           +status.md 点名 F-n 与新断言号
       ↓
/cc-code:agent-to-feature  增量纯执行（增量定位 → Dev→QA，affected 精准回归）

────────── 任意时刻 ──────────

/cc-code:experience-summary  踩坑/复盘 → 提炼设计准则 → references/ 资料库
/cc-code:init                插件升级后再跑一次：场域迁移 + 手册刷新到最新
```

**主线是 4 个 skill 两两配对串起来**：规划（商讨落盘定稿）→ 执行（纯机器推进）→ 全量验收。
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

## 可选增强：codegraph

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

## Skill 一览（14 个）

**框架核心（管流程）**

| skill | 触发 | 用途 |
| --- | --- | --- |
| `init` | `/cc-code:init` | **入场 + 升级** 三轨初始化（新建/已最新/旧版升级迁移）；判定链迁移散落物；升级走「归档→清点→迁移→校验→归位」，**全程零删除** |
| `cc-code` | 自动 | **运行时协议** 角色路由 + 文件分层 + 状态机约束 |
| `plan-prd-mvp` | `/cc-code:plan-prd-mvp` | **MVP 规划器**（第一动作 EnterPlanMode，plan 模式逐点交谈至逻辑通顺；产出五件 prd/ux/project/data/api，落盘即定稿） |
| `plan-prd-feature` | `/cc-code:plan-prd-feature` | **增量需求规划器**（MVP 后迭代：规范体检 + codegraph 算爆炸半径 + 冲突逐条硬门控 + 就地收敛落 L1/L2/L3，落盘即定稿 + status.md 点名 F-n） |
| `agent-to-mvp` | `/cc-code:agent-to-mvp` | **MVP 纯执行编排**（读定稿文档，Dev→QA + qa→dev 循环，中途零确认，whole-qa 收口） |
| `agent-to-feature` | `/cc-code:agent-to-feature` | **增量纯执行编排**（增量定位 → Dev→QA + qa→dev 循环，affected 精准回归，无全量清算） |
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

## Agent（3 个）

三 agent 与 cc-code 角色串行绑定，**独立于任何具体项目**，所有项目约定一律 defer 到 `.cc_code/active/project.md`：

| agent | 模型 | cc-code 角色 | 职责 |
| --- | --- | --- | --- |
| `prd-plan` | opus | PM + Architect | 需求→规范→技术方案；产出 prd/ux/project/data/api（阶段拆分并入 project.md，服务 plan-prd-mvp / plan-prd-feature） |
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
├── skills/           14 个 skill 目录
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
    ├── docs/qa/         🔵 全量验收报告 + 元素清单（whole-qa 产出）
    ├── test/           ⭐ 测试代码（源码，必须入库；affected 精准回归的索引基础）
    ├── images/          🔵 截图（init 迁移，扁平存放）
    ├── scripts/         🔵 散落脚本归档
    ├── references/      🟢 项目级经验资料库（experience-summary 产出，INDEX 索引 + 角色按需读）
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
| Architect | L3 | project, data, api | src/ 业务码 |
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

## 新手入门

每个项目 init 后，`.cc_code/README.md` 会生成一份**使用手册**（项目逻辑 / Skill 一览 / 使用方案 / 使用示例），并且**每次 `/cc-code:init` 自动刷新到最新版** —— 不熟悉 cc-code 的协作者直接读它即可，无需翻本仓库。

## License

MIT
