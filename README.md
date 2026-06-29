# cc_code Plugin

> 极简开发工作流系统 —— 把 LLM 装进「认知沙盒」，让它成为精确、稳定、可溯源的自动化软件工业母机。
> 基于三大铁律：**上下文最小化 · 决策串行 · 记忆外部化**。

## 安装

```bash
# 1. 添加本仓库为 marketplace
/plugin marketplace add <your-github-repo-url>

# 2. 安装 cc_code 插件
/plugin install cc_code
```

安装后自动获得 `/cc_code:*` 命令族与 5 个 skill。

## 快速开始

在任意项目根目录：

```
/cc_code:init
```

Skill 会：① 双轨判定（新项目 / 旧项目接管）→ ② 生成 `.cc_code/` 黑匣子 → ③ 进入角色串行状态机循环。

## 命令（10 个，命名空间 `/cc_code:`）

| 命令 | 用途 |
| --- | --- |
| `/cc_code:init` | **核心** 初始化工作流场域 |
| `/cc_code:project_resume` | 读取真实技术栈生成标准化项目介绍文案 |
| `/cc_code:short` | 极简回复（不需要思考时，≤50 字符） |
| `/cc_code:cf_online` | Next.js 部署到 Cloudflare Pages (Edge) |
| `/cc_code:next2taro` | Next.js UI → Taro 小程序转换 |
| `/cc_code:login_auto` | 登录流自动化 |
| `/cc_code:team` | 多 agent 团队编排 |
| `/cc_code:search_history` | 历史事件检索 |
| `/cc_code:vercel_supabase_deployment` | Vercel + Supabase 部署 |
| `/cc_code:witness` | 第一人称历史短剧脚本生成 |

## Skill（5 个，自然语言自动触发）

- `cc_code` — 工作流运行时协议（角色路由 + 状态机）
- `project_resume` / `cf_online` / `next2taro` / `witness`

## 目录结构（安装后在项目内生成）

```
.cc_code/
├── active/          🔴 热数据 (每次对话必读)
│   ├── Agent.md        角色路由表/最高宪法
│   ├── status.md       当前坐标 (AI 顺手写)
│   ├── errors.md       避坑指南 (Dev 顺手写)
│   ├── project.md      技术宪法 (Architect)
│   ├── flow.md         交互状态矩阵 (PM)
│   ├── front.md        前端交接规格 (PM)
│   └── gates.md        QA 验收关卡 (Dev 禁读)
├── backup/          🧊 冷数据 (Hook 超阈值切片归档)
├── docs/            🔵 会话存档
├── scripts/cc_code_hook.py   Stop Hook (纯脚本)
├── changelog.md     里程碑
└── index.md         对话索引
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
| 冷热切片 / 归档 / 骨架 | **Hook 脚本** | 纯机械活，毫秒级，零 LLM |

## Hook 接入

插件自带 `hooks/hooks.json`。若手动接入，加入 `settings.json`：

```json
{
  "hooks": {
    "Stop": [{
      "matcher": "*",
      "hooks": [{
        "type": "command",
        "command": "python3 .cc_code/scripts/cc_code_hook.py"
      }]
    }]
  }
}
```

`cc_code_hook.py` 顶部常量可调：`ERRORS_HOT_LIMIT=100`、`ERRORS_KEEP_HEAD=50`、`STATUS_MAX_LINES=120`。

## License

MIT
