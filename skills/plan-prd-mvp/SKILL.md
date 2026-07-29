---
description: 显式触发的 PRD 生成器。在 cc-code 框架内，独立 agent：先动态探测项目，输出完整项目逻辑图+原型图+距离 MVP 差异点表单，再调用 EnterPlanMode 进入 plan 模式与主人交谈逻辑模糊点，一直保持在 plan 模式直至整个 PRD 逻辑与 MVP 通顺，才 ExitPlanMode 放行落地 .cc_code/active/prd.md 并交接 cc-code 主线。不找 bug（QA 职责）、不写代码（Dev 职责）。
allowed-tools: Read, Write, Edit, Bash, Glob, Grep, EnterPlanMode, ExitPlanMode
disable-model-invocation: true
---

# /cc-code:plan-prd-mvp — PRD 生成器（plan 模式交谈收敛）

> cc-code 框架内的支线命令。定位：项目距 MVP 的「最后一公里整理器」。
> 目的：整理清楚整个项目逻辑、原型、差异点 → 进入 plan 模式与主人交谈 → PRD 与 MVP 完全通顺才放行。
> **不负责**：找 bug（QA → gates.md）、写代码（Dev）、改 active/ 其他 md。
> **产出**：`.cc_code/active/prd.md`（单文件动态更新，重大变更归档 `backup/`）。

## 一、定位

```
触发:    /cc-code:plan-prd-mvp（显式，disable-model-invocation）
性质:    cc-code 框架内独立 agent
目的:    整理项目逻辑/原型/差异点 → plan 模式交谈至通顺 → 产完备 prd.md
交谈:    EnterPlanMode 进入 plan 模式，一直保持至 PRD 与 MVP 通顺才 ExitPlanMode
交接:    prd 定稿后提示主人走 /cc-code:cc-code，不自动切角色
```

## 二、PM 三产物边界（守这层约束）

| 文件 | 定位 | 不写 |
| --- | --- | --- |
| `prd.md` | 功能清单 + 验收标准（做什么） | 交互细节、UI 规格 |
| `ux.md` | 交互状态流转（用户怎么走） | 功能清单、组件规格 |
| `ux.md` | 组件规格 + 响应式（界面长啥样） | 功能清单、状态流转 |

上游关系：`prd.md` 先行 → `ux.md` 基于 prd 细化，不反向。

## 三、执行逻辑（三阶段）

### 阶段一：探测项目 + 输出三件套（plan 模式外）

```
Step1 动态探测读取（不固定文件清单，按项目实际结构）
  ├─ cc_code 框架内: .cc_code/active/* + .cc_code/docs/*
  ├─ 项目结构: package.json / go.mod / pom.xml 等 → 定技术栈
  ├─ 数据层: 按栈定位 schema（prisma / drizzle / gorm / sequelize...）
  └─ 业务入口: app/ src/ routes/ 等 → 按需读
  守上下文最小化：只读整理架构所需，不全量扫。

Step2 输出「三件套」给主人看
  ├─ 项目逻辑图：架构图 + 业务生命周期 + 数据流
  ├─ 原型图：关键页面 / 核心流程的线框描述（文字版骨架）
  └─ MVP 差异点表单：现状 vs MVP 目标的 gap，按模块组织
     （字段：模块 / 现状 / 目标 / gap / 风险）
  └─ 不找 bug（bug 是 QA 职责）
```

### 阶段二：EnterPlanMode 进入 plan 模式（交谈收敛，核心）

> 调用 `EnterPlanMode` 进入 plan 模式。**一直保持在 plan 模式**，与主人交谈逻辑模糊点，
> 直至整个 PRD 逻辑与 MVP 完全通顺，才调 `ExitPlanMode` 放行。
> plan 模式内可读文件、可写 plan 文件、可对话澄清；**不**写 prd.md（未放行不写盘）。

```
Step3 调用 EnterPlanMode → 主人 approve 进入 plan 模式

Step4 把「三件套 + PRD 草案」写进 plan 文件（结构见第四节）

Step5 交谈循环（一直保持在 plan 模式）
  ├─ 浮浮酱列出逻辑模糊点 / 待确认决策点（按模块）
  ├─ 主人答疑 / 修订 / 补充 → 浮浮酱更新 plan 文件
  ├─ 仍有模糊 → 继续澄清，不退出 plan 模式
  └─ 循环直至 PRD 逻辑与 MVP 完全通顺、无遗留模糊点

Step6 全部通顺 → 调用 ExitPlanMode 提交 plan 文件 → 请求主人最终 approve
  └─ 主人 reject → 回到 Step5 继续交谈
  └─ 主人 approve → 进阶段三
```

### 阶段三：落地 PRD + 交接

```
Step7 approve → 把定稿 plan 落地为 .cc_code/active/prd.md
  └─ 旧版归档 .cc_code/backup/YYYY-MM/

Step8 提示: 可走 /cc-code:cc-code 进入主线
```

## 四、plan 文件 / prd.md 产出结构

```
1. 项目全景
   ├─ 架构图 + 业务生命周期 + 数据流
   └─ 原型图（关键页面 / 流程线框）
2. MVP 差异点表单（模块 / 现状 / 目标 / gap / 风险）
3. PRD 草案
   ├─ MVP 范围（P0/P1/P2 模块清单）
   ├─ 模块逻辑（功能 + 输入输出 + 闭环）
   ├─ 数据契约（interface + 关键字段）
   ├─ 状态机（任务/业务生命周期）
   └─ 验收标准（每模块的验收点）
```

> 不含：bug 清单（→ QA gates.md）、UI 规格（→ ux.md）、交互细节（→ ux.md）
> 注：plan 文件是 plan 模式交谈的载体；prd.md 是定稿落地，二者结构一致。

## 五、关键约束

| 约束 | 说明 |
| --- | --- |
| EnterPlanMode 主导 | 阶段二必须 EnterPlanMode 进入 plan 模式，交谈收敛全程不退出 |
| 通顺才放行 | PRD 逻辑与 MVP 完全通顺、无遗留模糊点，才调 ExitPlanMode |
| 先探后入 | 阶段一在 plan 模式外完成探测与三件套输出，再 EnterPlanMode |
| plan 模式内只写 plan | plan 模式内只写 plan 文件，prd.md 等 approve 后才落地 |
| 动态读取 | 不固定文件清单，按项目结构探测，守上下文最小化 |
| 不越界 | 只写 `.cc_code/active/prd.md`，不碰 active/ 其他 md，不改代码 |
| 不找 bug | bug 是 QA 职责，prd 只管完备 MVP 逻辑 |
| 单文件 | prd.md 唯一真相源，旧版归档 `.cc_code/backup/YYYY-MM/` |

## 六、与 cc-code 主线的关系

```
plan-prd-mvp（支线）                  cc-code 主线（串行）
────────────────────                  ──────────────────
阶段一 探测+三件套                       PM（读 prd）
   ↓ EnterPlanMode                       ↓
阶段二 plan 模式交谈至通顺              Architect（产 project.md）
   ↓ ExitPlanMode approve                ↓
阶段三 落地 prd.md ──────────────►     Dev（编码）
                                        ↓
                                     QA（验收，找 bug → gates.md）
```

plan-prd-mvp 是主线上游的「PRD 生成器」，产出后主线消费。

## 七、触发后首步动作清单

1. Read `.cc_code/active/Agent.md` → 确认角色（独立 agent，先按 Architect 视角盘点）。
2. Read `.cc_code/active/status.md` → 同步坐标。
3. 动态探测项目结构（按 Step1 规则）。
4. 阶段一 Step2 输出三件套（项目逻辑图 + 原型图 + MVP 差异点表单）。
5. Step3 调用 EnterPlanMode 进入 plan 模式 → Step4 写 plan 文件 → Step5 交谈至通顺。
6. 通顺后 Step6 ExitPlanMode → approve → Step7 落地 prd.md。
