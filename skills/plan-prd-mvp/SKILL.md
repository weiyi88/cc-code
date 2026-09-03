---
name: plan-prd-mvp
description: ⭐显式触发的 MVP 规划器（商讨+落盘定稿，0→1 全量）。触发后【第一动作必须 call EnterPlanMode 工具】（不许先做任何其他动作）。进入 plan 模式后在其中探测项目、输出 ascii 三件套（逻辑图+原型图+差异表）、逐点循环提问直至所有逻辑与配置通顺，才 ExitPlanMode 落盘。落盘按 PM 批 → Architect 批切角色（免请示）：prd/ux（PM）+ project/data/api 含阶段拆分（Architect）。落盘即定稿，无二次验收；产出供 /cc-code:agent-to-mvp 纯执行。⛔禁批量决策清单。不找 bug、不写代码。
allowed-tools: Read, Write, Edit, Bash, Glob, Grep, EnterPlanMode, ExitPlanMode
disable-model-invocation: true
---

# /cc-code:plan-prd-mvp — MVP 规划器（第一动作即 plan 模式）

> ⭐⭐⭐ **触发后第一动作 = call `EnterPlanMode` 工具。**
> 所有探测 / 三件套 / 交谈都在 plan 模式内做，**没有 plan 外窗口**。
> AI 从第一秒就在 plan only，Write/Edit 被锁死，无法逃避。
> **产出全部规划产物**：prd / ux（PM 域）+ project / data / api（Architect 域）。
> **落盘即定稿**：对话内的逐点交谈就是主人的确认，落盘后无二次验收；想改直接改对应文件或重跑本命令。

## ⛔ 三条铁律（违反即失败）

### 铁律 1：第一动作 call EnterPlanMode
触发后，在 call `EnterPlanMode` 之前，**不许做任何动作**：
- ❌ 不许先 Read Agent.md / status.md
- ❌ 不许先探测项目
- ❌ 不许先输出三件套
- ❌ 不许先输出"请主人审阅决策清单"
- ✅ 唯一允许的第一动作：call `EnterPlanMode` 工具

进入 plan 模式后，再做 Read / 探测 / 输出三件套 / 交谈（plan 模式允许 Read/Glob/Grep 和文字输出）。

### 铁律 2：禁批量决策清单
⛔ 禁止「全量输出决策清单，可全量接受 / 逐项修订 / 否决某项」。
必须逐点提问：一次只问一个模糊点，等主人答，再问下一个。

### 铁律 3：逐点循环至通顺
plan 模式内一直逐点提问，直到项目距 MVP 的所有逻辑 + 配置完全通顺，才 call `ExitPlanMode`。

---

## 一、流程

```
触发 /cc-code:plan-prd-mvp
     ↓
Step0 ⭐ call EnterPlanMode 工具（第一动作，不许先做别的）
     ↓ ──── 进入 plan 模式（只能 Read/Glob/Grep + 文字输出）────
Step1 Read Agent.md + status.md（同步角色与坐标）
Step2 探测项目（Read/Glob/Grep，守上下文最小化）
Step3 输出三件套（ascii 文字）：
      ├─ 项目逻辑图（ascii：架构 + 业务生命周期 + 数据流）
      ├─ 前端原型图（ascii：关键页面 / 核心流程线框）
      └─ MVP 差异点表格（ascii 框线：模块/现状/目标/gap/风险）
      ⚠️ 三件套是探测输出，辅助交谈，不是 ux.md
Step4 逐点循环提问（一次一个模糊点，不批量）：
      ├─ 列出当前一个逻辑/配置模糊点
      ├─ 主人答疑 → 更新认知
      └─ 检查：所有逻辑+配置通顺？
         ├─ 否 → 问下一个
         └─ 是 → Step5
     ↓ ──── 通顺后 ────
Step5 call ExitPlanMode → 主人 approve
     ↓ ──── 退出 plan 模式 ────
Step6 分批切角色落盘（⭐免请示：对话定稿即授权）：
      ├─ PM 批：Write prd.md（旧版归档 backup/YYYY-MM/）+ ux.md
      │    └─ Edit Agent.md「当前激活角色」→ PM → 落盘 → 复位
      └─ Architect 批：Write project.md / data.md / api.md
           └─ 阶段拆分（phaseN）并入 project.md 对应章节（Dev 按此分阶段编码）
Step7 顺手更新 status.md 坐标 → 提示走 /cc-code:agent-to-mvp
```

---

## 二、为什么第一动作就进 plan（最硬设计）

旧设计有「阶段一 plan 外探测 + 三件套」，AI 在 plan 外就有机会输出决策清单逃避 EnterPlanMode。
新设计第一动作就进 plan，AI **没有 plan 外窗口**，从第一秒就在 plan only，Write/Edit 被锁死，无法逃避。

> 架构诚实：Claude Code 没有「系统级强制 AI call 某工具」的机制。把 EnterPlanMode 放第一动作 + 无 plan 外窗口，是软约束的极限 —— AI 要违反，得主动无视本文件第一行铁律。要再硬只能加 PreToolUse hook（检测 skill 激活时阻止未 plan 先 Write），但 hook 检测 skill 激活很复杂，且违背「一个东西只做自己的逻辑」。本方案是架构内最硬。

---

## 三、prd.md 产出结构（对齐模板）

```
1. 模块清单（# / 模块 / 优先级 P0P1P2 / 依赖 / 状态）
2. 逐模块：
   ├─ 职责（一句话，写不成 = 该拆）
   ├─ 核心规则 R1..Rn（每条可判真假，禁"优化/友好"等模糊词）
   ├─ 状态机（ascii，若有流转）
   ├─ 边界与异常
   ├─ 验收断言 A1..An（⭐编号永久稳定，whole-qa 的分母）
   └─ 依赖
3. 全局规则 G1..Gn
4. 明确不做（Out of Scope）
```

> 不含：bug 清单（→ gates.md）、UI 规格（→ ux.md）、接口参数（→ api.md）

## 三·五、其余规划产物（Architect 域）

| 文件 | 落什么 | 说明 |
| --- | --- | --- |
| `project.md` | 技术选型 / 架构决策 / 目录规约 / **阶段拆分（phaseN + 各阶段验收断言范围）** / §六 测试基建契约 | 阶段拆分是 agent-to-mvp 的阶段来源；无阶段拆分则整体单阶段跑 |
| `data.md` | 数据契约（interface ↔ DB 列） | Architect 契约纪律 |
| `api.md` | 接口契约（method/path/入参/出参/错误码） | 同上 |

> 阶段拆分并入 `project.md` 对应章节，**不另建方案文件** —— active 只答「现在是什么」，过程靠 git。

---

## 四、PM 产物边界

| 文件 | 定位 | 不写 |
| --- | --- | --- |
| `prd.md` | 分模块业务逻辑 + 规则 + 验收断言（规则是什么） | UI 规格、接口参数 |
| `ux.md` | 视觉规格 + 交互五态（长什么样、点了怎么变） | 业务规则、字段类型 |

> 判据：能脱离界面存在的 → `prd.md`；离开界面就没意义的 → `ux.md`。
> 本命令产全部五件：`prd.md` + `ux.md`（PM 域）→ `project.md` / `data.md` / `api.md`（Architect 域）。
> `agent-to-mvp` 是纯执行器，**不再细化任何规划产物**——缺什么本命令补齐。

---

## 五、关键约束

| 约束 | 说明 |
| --- | --- |
| ⭐ 第一动作 call EnterPlanMode | 触发后不许先做别的，立即 call 工具 |
| 无 plan 外窗口 | 探测/三件套/交谈全在 plan 模式内 |
| ⛔ 禁批量决策清单 | 不许"全量接受/逐项修订/否决"，逐点提问 |
| 逐点循环至通顺 | 所有逻辑+配置通顺才 ExitPlanMode |
| plan 内只读 + 输出 | plan 模式内不 Write 业务文件，prd.md 等 ExitPlanMode 后落地 |
| 动态读取 | 按项目结构探测，守上下文最小化 |
| 不越界 | 只写 `prd.md` / `ux.md` / `project.md` / `data.md` / `api.md`，不碰 active/ 其他 md，不改代码 |
| 不找 bug | bug 是 QA 职责 |

---

## 六、与主线的关系

```
plan-prd-mvp（规划，人参与）             cc-code 主线
────────────────────                  ──────────────────
Step0 call EnterPlanMode               /cc-code:agent-to-mvp（纯执行）
Step1-4 plan 内探测+三件套+逐点交谈      ├─ Dev（编码）
Step5 ExitPlanMode approve             └─ QA（验收 → gates.md）
Step6 落盘五件 ──────────────►           → whole-qa（收口全量验收）
（prd/ux + project/data/api）
```

> 功能迭代不走本命令，走 `plan-prd-feature`（规划）→ `agent-to-feature`（执行）。

---

## 七、触发后首步动作

⭐ **第一个动作：call `EnterPlanMode` 工具。不许先做任何其他事。**

进入 plan 模式后，按 Step1-7 执行。
