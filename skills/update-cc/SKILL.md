---
name: update-cc
description: 把工作环境内改进的 cc-code 机制（三 agent / hook / skills / 模板等）同步回源仓库 /Users/blue_focus/Desktop/printingMoney/cc-code 并 commit + push 到 master。用户显式调用 /cc-code:update-cc 触发，手动不自动加载。
---

# update-cc — 同步 cc-code 机制到源仓库并发布

> **手动触发**：仅由用户显式 `/cc-code:update-cc` 调用，不自动加载。
> **用途**：在工作环境里改进了 cc-code 机制后，把变更回写源仓库 → 校验 → commit → push master。
> **源仓库**：`/Users/blue_focus/Desktop/printingMoney/cc-code`（remote `weiyi88/cc-code`，branch `master`）

## 工件同步映射（FROM 工作环境 → TO 源仓库）

| 工件 | 工作环境源（FROM） | 仓库目标（TO） |
| --- | --- | --- |
| 三 agent | `~/.claude/agents/{prd-plan,dev,qa}.md` | `agents/` |
| hook | `$CLAUDE_PROJECT_DIR/.cc_code/scripts/cc_code_hook.py`（项目内改进版） | `hooks/cc_code_hook.py` |
| skills | `~/.claude/plugins/marketplaces/cc-code-marketplace/skills/<name>/` | `skills/<name>/` |
| init.sh / templates/ / README / plugin.json / marketplace.json | 直接在仓库内编辑 | 原地 |

## 执行流程

```
1. 预检 ──► 2. 同步工件(仅 diff 者) ──► 3. 校验 ──► 4. commit ──► 5. push master ──► 6. 提示同步 marketplace 克隆
```

### 1. 预检
- 确认源仓库存在且 `branch=master`：`git -C <repo> branch --show-current`
- `git -C <repo> status --short` 查未提交改动
- 确认 remote：`git -C <repo> remote -v`（应为 `weiyi88/cc-code`）

### 2. 同步工件（逐项 diff，仅同步有变更的）
- **agents**：先 `diff ~/.claude/agents/<name>.md <repo>/agents/<name>.md`，有变更才 `cp`
- **hook**：若 `$CLAUDE_PROJECT_DIR/.cc_code/scripts/cc_code_hook.py` 存在且与仓库版有 diff → `cp` 到 `<repo>/hooks/cc_code_hook.py`
- **skills**：对 marketplace 克隆里每个与仓库有 diff 的 skill，`cp -r` 到 `<repo>/skills/<name>/`
- **仓库原生文件**：机制变更涉及 README/init.sh/templates/plugin.json/marketplace.json 时，直接在仓库内编辑同步描述与计数

### 3. 校验（全过才提交）
```bash
python3 -c "import json;json.load(open('.claude-plugin/plugin.json'));json.load(open('.claude-plugin/marketplace.json'))"
bash -n scripts/init.sh
python3 -c "import ast;ast.parse(open('hooks/cc_code_hook.py').read())"
```

### 4. commit
```bash
git -C <repo> add -A
git -C <repo> commit -F - <<'MSG'
<类型>: <简述>

<正文，逐项列变更>

Co-Authored-By: Claude <noreply@anthropic.com>
MSG
```

### 5. push
```bash
git -C <repo> push origin master
```

### 6. 提示同步 marketplace 克隆（让变更在本环境生效）
push 后远程已更新，本地 marketplace 克隆落后。提示用户：
```bash
cd ~/.claude/plugins/marketplaces/cc-code-marketplace
git fetch origin && git pull --ff-only origin master
```
> 若克隆内有未提交的本地副本与远程冲突，先 `rm -rf` 冲突项再 pull。

## 行为准则
- **只同步有 diff 的工件**，不做无谓改动；无变更的工件跳过。
- **commit message 用中文**，逐项列明变更；结尾必带 `Co-Authored-By: Claude <noreply@anthropic.com>`。
- **push 前必须过校验**；校验失败则修后再提交，绝不带病推送。
- **不擅自删用户全局 agent**（`~/.claude/agents/`）——去重由用户决策，本 skill 只负责回写源仓库。
- 进度/状态以源仓库 `git status` 为准，禁止凭记忆。
