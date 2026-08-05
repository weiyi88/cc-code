# cc-code Plugin

> 极简开发工作流系统 —— 把 LLM 装进「认知沙盒」，让它成为精确、稳定、可溯源的自动化软件工业母机。
> 基于三大铁律：**上下文最小化 · 决策串行 · 记忆外部化**。

## 设计哲学

```
① 记忆/逻辑/状态全外部寄存 ── 不交给 agent，落 .cc_code/ 静态文件
② 责任垂直化 ── 每角色只掌一层，上下文干净，禁止越权
③ 防 vibecoding 三病：
   逻辑偏离 → 信息流单向 + codegraph 不生成意图层
   冗余堆积 → whole-qa 冗余检测
   自傲跳过 → 多角色 + 测修独立上下文
```

## 安装

```bash
# 1. 添加本仓库为 marketplace
/plugin marketplace add https://github.com/weiyi88/cc-code

# 2. 安装 cc-code 插件
/plugin install cc-code
```

安装后自动获得 `/cc-code:*` 命令族、12 个 skill 与 3 个配套 agent。

## 完整生命周期

```
/cc-code:init          搭场域（8模板 + 迁移散落物）
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
```

**主线是 3 个 skill 串起来**：产需求 → 编排实现 → 全量验收。
`cc-code` skill 在背后管运行时协议（角色路由 + 分层），`init` 是入场。无 Stop Hook，所有状态由 AI 顺手写。

## 快速开始

在任意项目根目录：

```
/cc-code:init
```

- **新项目**：直接搭场域，切 PM 等需求。
- **旧项目**：备份旧 `CLAUDE.md` → `.cc_code/backup/YYYY-MM/CLAUDE.md.legacy`，AI 按映射表分拆归并到 `active/` 各文件，再用入口模板覆盖根目录 `CLAUDE.md`。

> 根目录 `CLAUDE.md` 是纯入口引导（会话开启协议 + 三铁律 + 文件索引），不含业务状态。Claude Code 原生自动加载它，从而被引导进 `.cc_code/` 状态机。

## Skill（12 个）

**框架核心（管流程）**

| skill | 触发 | 用途 |
| --- | --- | --- |
| `init` | `/cc-code:init` | **入场** 初始化场域（判定链迁移散落物） |
| `cc-code` | 自动 | **运行时协议** 角色路由 + 文件分层 + 状态机约束 |
| `plan-prd-mvp` | `/cc-code:plan-prd-mvp` | PRD 生成器（第一动作 EnterPlanMode，plan 模式逐点交谈至逻辑通顺） |
| `plan-prd-feature` | `/cc-code:plan-prd-feature` | **增量需求规划器**（MVP 后迭代：规范体检 + codegraph 算爆炸半径 + 冲突逐条硬门控 + 按层分批切角色落 L1/L2/L3） |
| `agent-to-mvp` | `/cc-code:agent-to-mvp` | MVP 生命周期编排（PM→Architect→Dev→QA + qa→dev 循环） |
| `whole-qa` | `/cc-code:whole-qa` | **全量验收 + 修复闭环**（逐页逐按钮逐接口 + 冗余检测，FAIL≤3轮回环） |
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
├ L2 表现 ─ ux.md(视觉规格+交互五态) ─────────────────── PM ───┤
├ L3 实现 ─ project.md  data.md  api.md ───────────── Architect ┤
├ L4 验收 ─ gates.md(实测结果，标准在 prd §1.5) ───────── QA ───┤
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
```

## 目录架构

### 插件侧（github.com/weiyi88/cc-code）

```
cc-code/
├── .claude-plugin/   marketplace.json + plugin.json
├── skills/           12 个 skill 目录
├── agents/           3 个 agent（prd-plan / dev / qa）
├── scripts/          init.sh（脚手架 + 散落物迁移）
├── templates/        8 个 md 骨架（L0~L4）
├── docs/             ARCHITECTURE.md
└── 无 hooks/         （0.5.0 砍除，无自动化机械活）
```

### 项目侧（/cc-code:init 生成）

```
项目根/
├── CLAUDE.md              🧭 入口引导（Claude 原生自动加载，纯协议不含业务状态）
└── .cc_code/
    ├── active/          🔴 热数据（每次对话必读，按 L0~L4 分层）
    │   ├── Agent.md       L0 角色路由表 / 最高宪法
    │   ├── status.md      L0 当前坐标 + 里程碑（AI 自管长度）
    │   ├── prd.md         L1 分模块业务逻辑 + 规则 + 验收断言（PM）
    │   ├── ux.md          L2 视觉规格 + 交互五态矩阵（PM）
    │   ├── project.md     L3 技术宪法（Architect）
    │   ├── data.md        L3 数据契约 interface ↔ DB 列（Architect）
    │   ├── api.md         L3 接口契约 method/path/入参/出参/错误码（Architect）
    │   └── gates.md       L4 QA 实测结果 + FAIL 清单（QA，Dev 禁读）
    ├── docs/plans/      🔵 阶段方案（Architect 产出，Dev 按 phase 读）
    ├── docs/qa/         🔵 全量验收报告 + 元素清单（whole-qa 产出）
    ├── images/          🔵 截图（init 迁移，扁平存放）
    ├── scripts/         🔵 散落脚本归档
    └── backup/          🧊 冷数据（含 CLAUDE.md.legacy / migration_manifest / needs_review；默认不入库）
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

## License

MIT
