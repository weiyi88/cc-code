---
description: 显式触发的 PRD 生成器。在 cc-code 框架内，独立 agent 内部串行切角色（Architect→PM）：先动态探测项目整理架构全景+MVP 差异点/疑问点，再按模块与用户一问一答，产出完备 MVP 逻辑的 .cc_code/prd.md。不找 bug（QA 职责）、不写代码（Dev 职责）。
allowed-tools: Read, Write, Edit, Bash, Glob, Grep
disable-model-invocation: true
---

# /cc-code:plan-prd-mvp — PRD 生成器（探讨式）

> cc-code 框架内的支线命令。目的：了解项目 → 找 MVP 差异点/逻辑缺陷 → 产出完备 MVP 逻辑的 `prd.md`。
> **不负责**：找 bug（QA → gates.md）、写代码（Dev）、改 active/ 其他 md。
> **产出**：`.cc_code/prd.md`（单文件动态更新，重大变更归档 `backup/` + changelog 记里程碑）。

## 一、定位

```
触发:    /cc-code:plan-prd-mvp（显式，disable-model-invocation）
性质:    cc-code 框架内独立 agent，内部串行切角色
目的:    产出完备 MVP 逻辑的 prd.md
交接:    提示主人走 /cc-code:cc-code，不自动切角色
```

## 二、PM 三产物边界（守这层约束）

| 文件 | 定位 | 不写 |
| --- | --- | --- |
| `prd.md` | 功能清单 + 验收标准（做什么） | 交互细节、UI 规格 |
| `flow.md` | 交互状态流转（用户怎么走） | 功能清单、组件规格 |
| `front.md` | 组件规格 + 响应式（界面长啥样） | 功能清单、状态流转 |

上游关系：`prd.md` 先行 → `flow.md` / `front.md` 基于 prd 细化，不反向。

## 三、执行逻辑（两阶段串行切角色）

### 阶段一：持 Architect 角色（了解项目 + 找差异）

```
Step1 动态探测读取（不固定文件清单，按项目实际结构）
  ├─ cc_code 框架内: .cc_code/active/* + .cc_code/docs/* + changelog.md
  ├─ 项目结构: package.json / go.mod / pom.xml 等 → 定技术栈
  ├─ 数据层: 按栈定位 schema（prisma / drizzle / gorm / sequelize...）
  └─ 业务入口: app/ src/ routes/ 等 → 按需读
  守上下文最小化：只读整理架构所需，不全量扫。

Step2 输出「项目全景」
  └─ 架构图 + 业务生命周期 + 数据流

Step3 找「MVP 差异点 + 逻辑缺陷 + 疑问点」
  └─ 现状 vs MVP 目标的 gap，按模块组织
  └─ 不找 bug（bug 是 QA 职责）

Step4 疑问点翻译成需求语言 → 写进 prd.md 草案
```

切换角色前：重读 `.cc_code/active/Agent.md` 加载 PM 权限表；切换前严禁预读下一角色禁读文件。

### 阶段二：持 PM 角色（探讨 + 产出 PRD）

```
Step5 按模块逐个问主人
  模块按项目实际划分（如 认证/风格/生图/结果/回收站）
  每模块抛疑问点 → 主人答 → 确认才进下一模块
  探讨模式：不直接产出，一问一答

Step6 收齐答案 → 收口汇总

Step7 产出完整 prd.md（见第四节结构）

Step8 提示: 可走 /cc-code:cc-code 执行
```

## 四、prd.md 产出结构

```
1. MVP 范围（P0/P1/P2 模块清单）
2. 模块逻辑（每个模块的功能 + 输入输出 + 闭环）
3. 数据契约（interface + 关键字段）
4. 状态机（任务/业务生命周期）
5. 验收标准（每模块的验收点）
```

> 不含：bug 清单（→ QA gates.md）、UI 规格（→ front.md）、交互细节（→ flow.md）

## 五、关键约束

| 约束 | 说明 |
| --- | --- |
| 串行切角色 | Architect → PM，每时刻只持一个角色，切换重读 Agent.md |
| 产物隔离 | Architect 草案不直接喂 PM，以 prd.md 需求语言重述（PM 禁读 project.md） |
| 探讨模式 | 阶段二一问一答，主人确认才进，不直接产出 |
| 动态读取 | 不固定文件清单，按项目结构探测，守上下文最小化 |
| 不越界 | 只写 `.cc_code/prd.md`，不碰 active/ 其他 md，不改代码 |
| 不找 bug | bug 是 QA 职责，prd 只管完备 MVP 逻辑 |
| 单文件 | prd.md 唯一真相源，旧版归档 `.cc_code/backup/YYYY-MM/` + changelog 记里程碑 |

## 六、与 cc-code 主线的关系

```
plan-prd-mvp（支线）              cc-code 主线（串行）
──────────────────              ──────────────────
Architect 整理                    PM（读 prd）
   ↓ 切角色                          ↓
PM 问 + 产 prd.md ──► prd.md ──► Architect（产 project.md）
                                    ↓
                                 Dev（编码）
                                    ↓
                                 QA（验收，找 bug → gates.md）
```

plan-prd-mvp 是主线上游的「PRD 生成器」，产出后主线消费。

## 七、触发后首步动作清单

1. Read `.cc_code/active/Agent.md` → 确认当前角色，先切 Architect。
2. Read `.cc_code/active/status.md` + `errors.md` → 同步坐标与避坑。
3. 动态探测项目结构（按 Step1 规则）。
4. 进入阶段一 Step2 输出项目全景。
