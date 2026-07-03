---
description: 初始化 cc-code 极简开发工作流场域。双轨判定(新项目/旧项目接管) → 生成 .cc_code/ 黑匣子目录树与模板骨架 → 进入角色串行状态机循环。
allowed-tools: Read, Write, Edit, Bash, Glob, Grep
disable-model-invocation: true
---

# /cc-code:init — 项目场域初始化

执行 cc-code 工作流的入场协议。

## 第 1 步：双轨判定

扫描当前工作区：

| 探测条件 | 轨道 | 行为 |
| --- | --- | --- |
| 已存在 `.cc_code/active/Agent.md` | — | 场域已就绪，跳过脚手架，直接第 3 步 |
| 存在 `src/` / `package.json` / `go.mod` 等旧代码，或根目录已有 `CLAUDE.md` | Track A 旧项目 | 扫描技术栈+断层，与用户多轮补 PRD，预填 project.md；并执行第 2A 步分拆旧 CLAUDE.md |
| 全空目录 | Track B 新项目 | 直接搭场域，切 PM 角色等待需求 |

## 第 2 步：执行脚手架

```bash
bash "$CLAUDE_PLUGIN_ROOT/scripts/init.sh" "$(pwd)"
```

脚本幂等：已存在 `.cc_code/` 则跳过。生成 `active/ backup/ docs/ images/ scripts/ tests/` + 7 个模板骨架 + 本地 Hook 副本 + **根目录 `CLAUDE.md` 入口引导**。

CLAUDE.md 处理（init.sh 自动完成，机械活）：

- **Track B 新项目**：直接 `cp templates/CLAUDE.md → 根目录/CLAUDE.md`。
- **Track A 旧项目**：先把旧 `CLAUDE.md` 备份至 `.cc_code/backup/YYYY-MM/CLAUDE.md.legacy`，再用入口模板覆盖根目录 `CLAUDE.md`。

> 新生成的 `CLAUDE.md` 是**纯入口引导**（会话开启协议 + 三铁律 + 文件索引），不含任何业务状态。Claude Code 原生会自动加载它，从而被引导进 `.cc_code/` 状态机。

## 第 2A 步：Track A 旧 CLAUDE.md 分拆协议（理解力活，由 AI 完成）

仅 Track A 执行。读取 `.cc_code/backup/YYYY-MM/CLAUDE.md.legacy`，按下表把旧内容**只搬运不丢失**地归并到对应文件：

| 旧 CLAUDE.md 中的内容 | 目标文件 | 归并方式 |
| --- | --- | --- |
| 项目角色定义、权限规则、工作流约定、agent 路由 | `active/Agent.md` | 合并进「角色权限路由表」段落，保留模板原有结构 |
| 技术栈、框架、语言、目录结构、编码原则（KISS/SOLID 等） | `active/project.md` | 填入「技术栈概览 / 目录规约 / 特殊约束」 |
| 当前进度、待办、卡点、正在做的模块 | `active/status.md` | 填入「当前坐标 / 下一步目标」 |
| 历史变更、版本记录、里程碑 | `changelog.md` | 追加到现有 changelog |
| 踩过的坑、注意事项、已知 bug、禁用做法 | `active/errors.md` | 按「现象 / 根因 / 预防」格式追加 |
| 用户交互流程、页面状态机 | `active/flow.md` | 填入场景与状态矩阵 |
| UI 规格、组件清单、响应式规则 | `active/front.md` | 填入页面模块规格 |
| 验收标准、测试要求 | `active/gates.md` | 填入验收关卡 |
| 无法归类的杂项 / 项目背景 | `active/project.md` 的「特殊约束」 | 兜底，绝不丢弃 |

铁律：分拆时每一段信息都要有着落，拿不准的归 `project.md` 兜底；归并完成后旧 `CLAUDE.md` 已被入口模板覆盖，无须保留原状。

## 第 3 步：进入状态机循环

1. Read 根目录 `CLAUDE.md` → 按其「会话开启协议」执行。
2. Read `.cc_code/active/Agent.md` → 锁定当前角色与文件路由权限表。
3. Read `.cc_code/active/status.md` + `errors.md` → 同步坐标与避坑清单。
4. 按 `cc-code` skill 协议持续约束后续行为（热数据由 AI 顺手写，Hook 只做冷热切片）。

## 第 4 步：Hook 接入提示

若用户尚未配置 Stop Hook，提示把 `.cc_code/scripts/cc-code_hook.py` 接入 `settings.json`（参考 README）。Hook 为纯 Python 脚本，零 LLM 调用，毫秒级结算。
