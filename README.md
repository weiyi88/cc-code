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

安装后自动获得 `/cc-code:*` 命令族、6 个 skill 与 3 个配套 agent。

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

## 命令（8 个，命名空间 `/cc-code:`）

| 命令 | 用途 |
| --- | --- |
| `/cc-code:init` | **核心** 初始化工作流场域 |
| `/cc-code:project_resume` | 读取真实技术栈生成标准化项目介绍文案 |
| `/cc-code:short` | 极简回复（不需要思考时，≤50 字符） |
| `/cc-code:cf_online` | Next.js 部署到 Cloudflare Pages (Edge) |
| `/cc-code:next2taro` | Next.js UI → Taro 小程序转换 |
| `/cc-code:login_auto` | 登录流自动化 |
| `/cc-code:team` | 多 agent 团队编排 |
| `/cc-code:vercel_supabase_deployment` | Vercel + Supabase 部署 |

## Skill（6 个）

- `cc-code` — 工作流运行时协议（角色路由 + 状态机，自然语言自动触发）
- `agentToMVP` — **手动触发** `/cc-code:agentToMVP`：三 agent × cc-code 驱动 MVP 完整生命周期（PM→Architect→Dev→QA + qa→dev 循环，每阶段后 `/cc-code:cc-code` 校准）
- `update-cc` — **手动触发** `/cc-code:update-cc`：把工作环境改进的 cc-code 机制（agent/hook/skill 等）同步回源仓库并 commit + push master
- `project_resume` / `cf_online` / `next2taro`

## Agent（3 个，cc-code 配套，通用零项目假设）

三 agent 与 cc-code 角色串行绑定，**独立于任何具体项目**，所有项目约定一律 defer 到 `.cc_code/active/project.md`：

| agent | 模型 | cc-code 角色 | 职责 |
| --- | --- | --- | --- |
| `prd-plan` | opus | PM + Architect | 需求→规范→技术方案；产出 prd/flow/front/project + `docs/plans/phaseN-plan.md` |
| `dev` | haiku | Dev | 按规格实现代码 + 三层测试；自检 lint/tsc/test/e2e |
| `qa` | sonnet | QA（灰盒） | 写+跑三层测试（逻辑/接口/浏览器），结构化 FAIL 清单回 dev，≤3 轮循环 |

> agent 定义「怎么干」，cc-code 定义「干什么+在哪干」，`.cc_code/active/` 是唯一耦合接口。

## 目录结构（安装后在项目内生成）

```
项目根/
├── CLAUDE.md          🧭 入口引导（Claude 原生自动加载，纯协议不含业务状态）
└── .cc_code/
    ├── active/          🔴 热数据 (每次对话必读)
    │   ├── Agent.md        角色路由表/最高宪法
    │   ├── status.md       当前坐标 (AI 顺手写)
    │   ├── errors.md       避坑指南 (Dev 顺手写)
    │   ├── project.md      技术宪法 (Architect)
    │   ├── flow.md         交互状态矩阵 (PM)
    │   ├── front.md        前端交接规格 (PM)
    │   └── gates.md        QA 验收关卡 (QA 灰盒维护)
    ├── docs/plans/      🔵 阶段方案 (prd-plan 产出，Dev 按 phase 读)
    ├── backup/          🧊 冷数据 (Hook 超阈值切片归档；旧项目含 CLAUDE.md.legacy)
    └── changelog.md     里程碑（唯一时间线，Hook 按 session 去重写入）
```

## 角色串行流水线

```
PM ──► Architect ──► Dev ──► QA
(需求)   (架构)      (编码)   (验收)
```

每个角色由 `active/Agent.md` 路由表锁定「必读/可写/禁读」，禁止越权。

## ⚡ Hook 为何是纯脚本（关键设计）

Stop Hook **绝不调用 LLM**，避免每次对话结束都烧 token、拖慢响应。分工如下：

| 数据 | 谁写 | 为什么 |
| --- | --- | --- |
| `status.md` 推进进度 | **AI**（对话内顺手） | 需要理解力，但本就在生成文本，零额外成本 |
| `errors.md` 新坑根因 | **Dev**（对话内顺手） | 同上 |
| 冷热切片 / 归档 / changelog 去重 | **Hook 脚本** | 纯机械活，毫秒级，零 LLM |

> Hook 仅维护 `changelog.md`（按 `session_id` 去重，不刷屏）；不再生成 `index.md` 与 `session_skeleton.md`（重复 status/changelog 的僵尸层，已砍）。

## Hook 接入

**插件 `hooks/hooks.json` 已自动注册 Stop hook**（`$CLAUDE_PLUGIN_ROOT/hooks/cc_code_hook.py`），装了 cc-code 插件即生效——**项目无需自带 hook、无需改 `settings.json`**。

> ⚠️ 不要在项目 `.claude/settings.json` 再加 Stop hook，否则与插件 hook **双跑**。Hook 脚本靠 `find_cc_code(cwd)` 定位项目 `.cc_code/`，跨项目通用。

`hooks/cc_code_hook.py` 顶部常量可调：`ERRORS_HOT_LIMIT=100`、`ERRORS_KEEP_HEAD=50`、`STATUS_MAX_LINES=120`。

## License

MIT
