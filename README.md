# cc-code Plugin

> 极简开发工作流系统 —— 把 LLM 装进「认知沙盒」，让它成为精确、稳定、可溯源的自动化软件工业母机。
> 基于三大铁律：**上下文最小化 · 决策串行 · 记忆外部化**。

## 安装

```bash
# 1. 添加本仓库为 marketplace
/plugin marketplace add https://github.com/weiyi88/cc-code

# 2. 安装 cc-code 插件
/plugin install cc-code
```

安装后自动获得 `/cc-code:*` 命令族、11 个 skill 与 3 个配套 agent。

## 快速开始

在任意项目根目录：

```
/cc-code:init
```

Skill 会：① 双轨判定（新项目 / 旧项目接管）→ ② 生成 `.cc_code/` 黑匣子 + 根目录 `CLAUDE.md` 入口引导 → ③ 进入角色串行状态机循环。

> **入口设计**：根目录 `CLAUDE.md` 是纯引导文件（会话开启协议 + 三铁律 + 文件索引），不含业务状态。Claude Code 原生自动加载它，从而被引导进 `.cc_code/` 状态机。
>
> - **新项目**：直接生成 `CLAUDE.md` 入口模板。
> - **旧项目**：先把旧 `CLAUDE.md` 备份至 `.cc_code/backup/YYYY-MM/CLAUDE.md.legacy`，AI 按 `/cc-code:init` 映射表把旧内容分拆归并到 `active/` 各文件，再用入口模板覆盖根目录 `CLAUDE.md`。

## Skill（11 个，命名空间 `/cc-code:`）

**框架核心（管流程）**

| skill | 触发 | 用途 |
| --- | --- | --- |
| `init` | `/cc-code:init` | **入场** 初始化工作流场域（判定链迁移散落物 + 注册项目级 hook） |
| `cc-code` | 自动 | **运行时协议** 角色路由 + 文件分层 + 状态机约束 |
| `plan-prd-mvp` | `/cc-code:plan-prd-mvp` | PRD 生成器（plan 模式交谈至逻辑通顺才落地 `active/prd.md`） |
| `agentToMVP` | `/cc-code:agentToMVP` | MVP 生命周期编排（PM→Architect→Dev→QA + qa→dev 循环） |
| `whole-qa` | `/cc-code:whole-qa` | **全量验收 + 修复闭环**（逐页逐按钮逐接口穷尽测试，分模块 fan-out，FAIL 自动回环 ≤3 轮） |
| `short` | `/cc-code:short` | 极简回复（不需要思考时，≤50 字符） |

**工具外挂（干活的，与状态机无关）**

| skill | 用途 |
| --- | --- |
| `project_resume` | 读取真实技术栈生成标准化项目介绍文案 |
| `login_auto` | Supabase Auth + Resend 通用登录系统 |
| `vercel_supabase_deployment` | Vercel + Supabase 一键部署 |
| `cf_online` | Next.js 部署到 Cloudflare Pages (Edge) |
| `next2taro` | Next.js UI → Taro 小程序转换 |

## Agent（3 个，cc-code 配套，通用零项目假设）

三 agent 与 cc-code 角色串行绑定，**独立于任何具体项目**，所有项目约定一律 defer 到 `.cc_code/active/project.md`：

| agent | 模型 | cc-code 角色 | 职责 |
| --- | --- | --- | --- |
| `prd-plan` | opus | PM + Architect | 需求→规范→技术方案；产出 prd/ux/project/data/api + `docs/plans/phaseN-plan.md` |
| `dev` | haiku | Dev | 按规格实现代码 + 三层测试；自检 lint/tsc/test/e2e |
| `qa` | sonnet | QA（灰盒） | 写+跑三层测试（逻辑/接口/浏览器），结构化 FAIL 清单回 dev，≤3 轮循环 |

> agent 定义「怎么干」，cc-code 定义「干什么+在哪干」，`.cc_code/active/` 是唯一耦合接口。

## 目录结构（安装后在项目内生成）

```
项目根/
├── CLAUDE.md              🧭 入口引导（Claude 原生自动加载，纯协议不含业务状态）
└── .cc_code/
    ├── active/          🔴 热数据 (每次对话必读，按 L0~L4 分层)
    │   ├── Agent.md       L0 角色路由表 / 最高宪法
    │   ├── status.md      L0 当前坐标 + 里程碑 (AI 自管长度)
    │   ├── prd.md         L1 分模块业务逻辑 + 规则 + 验收断言 (PM)
    │   ├── ux.md          L2 视觉规格 + 交互五态矩阵 (PM)
    │   ├── project.md     L3 技术宪法 (Architect)
    │   ├── data.md        L3 数据契约 interface ↔ DB 列 (Architect)
    │   ├── api.md         L3 接口契约 method/path/入参/出参/错误码 (Architect)
    │   ├── gates.md       L4 QA 实测结果 + FAIL 清单 (QA，Dev 禁读)
    ├── docs/plans/      🔵 阶段方案 (Architect 产出，Dev 按 phase 读)
    ├── docs/qa/         🔵 全量验收报告 + 元素清单 (whole-qa 产出)
    ├── images/          🔵 截图 (init 迁移，扁平存放)
    ├── scripts/         🔵 散落脚本归档
    └── backup/          🧊 冷数据 (含 CLAUDE.md.legacy / migration_manifest / needs_review；默认不入库)
```

### 信息流铁律

```
   L1 意图 ──► L2 表现 ──► L3 实现 ──► 代码
    ▲                                   │
    └───────── L4 验收 ◄────────────────┘

  L4 只拿 L1 / L2 当尺子，绝不拿 L3 / 代码当尺子
     否则 QA 退化为「拿代码验代码」，验收环节彻底失效
  codegraph 只准校准 L3（事实层），永不生成 L1 / L2 / L4
```

## 角色串行流水线

```
PM ──► Architect ──► Dev ──► QA
(需求)   (架构)      (编码)   (验收)
```

每个角色由 `active/Agent.md` 路由表锁定「必读/可写/禁读」，禁止越权。

## 无 Hook 设计

cc-code **不使用 Stop Hook**。所有 `.cc_code/` 文件都由 AI 在对话内顺手写，无自动化机械活。

> 设计沿革：早期版本有 Stop Hook 做 `errors.md` 冷切片。0.5.0 起 `errors.md` 废除（坑写进 commit message / git blame，天然留痕），Hook 失去唯一职责，一并砍除。符合「一个东西只做自己的逻辑」—— 没逻辑就别留。

## License

MIT
