---
description: 初始化 cc_code 极简开发工作流场域。双轨判定(新项目/旧项目接管) → 生成 .cc_code/ 黑匣子目录树与模板骨架 → 进入角色串行状态机循环。
allowed-tools: Read, Write, Edit, Bash, Glob, Grep
---

# /cc_code:init — 项目场域初始化

执行 cc_code 工作流的入场协议。

## 第 1 步：双轨判定

扫描当前工作区：

| 探测条件 | 轨道 | 行为 |
| --- | --- | --- |
| 已存在 `.cc_code/active/Agent.md` | — | 场域已就绪，跳过脚手架，直接第 3 步 |
| 存在 `src/` / `package.json` / `go.mod` 等旧代码 | Track A 旧项目 | 扫描技术栈+断层，与用户多轮补 PRD，预填 project.md |
| 全空目录 | Track B 新项目 | 直接搭场域，切 PM 角色等待需求 |

## 第 2 步：执行脚手架

```bash
bash "$CLAUDE_PLUGIN_ROOT/scripts/init.sh" "$(pwd)"
```

脚本幂等：已存在 `.cc_code/` 则跳过。生成 `active/ backup/ docs/ images/ scripts/ tests/` + 7 个模板骨架 + 本地 Hook 副本。

## 第 3 步：进入状态机循环

1. Read `.cc_code/active/Agent.md` → 锁定当前角色与文件路由权限表。
2. Read `.cc_code/active/status.md` + `errors.md` → 同步坐标与避坑清单。
3. 按 `cc_code` skill 协议持续约束后续行为（热数据由 AI 顺手写，Hook 只做冷热切片）。

## 第 4 步：Hook 接入提示

若用户尚未配置 Stop Hook，提示把 `.cc_code/scripts/cc_code_hook.py` 接入 `settings.json`（参考 README）。Hook 为纯 Python 脚本，零 LLM 调用，毫秒级结算。
