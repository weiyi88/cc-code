---
description: 显式触发的 PRD 生成器。触发后先探测项目，输出 ascii 项目逻辑图 + ascii 前端原型图 + MVP 差异点表格（三件套），然后【强制调用 EnterPlanMode 工具】进入 plan 模式，逐点循环提问直至项目距 MVP 的所有逻辑与配置完全通顺，才 ExitPlanMode 放行落地 prd.md。⛔ 禁止用"全量决策清单请全量接受/逐项修订/否决"替代 plan 模式。不找 bug、不写代码。
allowed-tools: Read, Write, Edit, Bash, Glob, Grep, EnterPlanMode, ExitPlanMode
disable-model-invocation: true
---

# /cc-code:plan-prd-mvp — PRD 生成器（强制 plan 模式交谈收敛）

> cc-code 框架内的支线命令。定位：项目距 MVP 的「最后一公里整理器」。
> **产出**：`.cc_code/active/prd.md`（分模块逻辑 + 规则 + 验收断言）。

## ⛔ 两条铁律（违反即本次执行失败）

### 铁律 1：强制 call EnterPlanMode 工具
阶段一输出三件套后，**下一个动作必须是调用 `EnterPlanMode` 工具**。
- ✅ 正确：call `EnterPlanMode` 工具 → 系统进入 plan 模式
- ❌ 错误：用文字说"现在进入 plan 模式" / "请主人审阅决策清单" —— 这是逃避 plan 模式，不许

### 铁律 2：禁止批量决策清单
⛔ **绝对禁止**用「全量输出决策清单，可全量接受 / 逐项修订 / 否决某项」这种批量模式替代 plan 模式交谈。
- 交谈方式必须是**逐点提问**：一次只问一个模糊点，等主人答，更新 plan，再问下一个。
- 不允许一次性全量输出所有待决策项让主人批量选。

---

## 一、执行流程

### 阶段一：探测 + 三件套（plan 模式外）

```
Step1 动态探测（不固定文件清单，按项目实际结构）
  ├─ .cc_code/active/* + .cc_code/docs/*
  ├─ 技术栈: package.json / go.mod / pom.xml
  ├─ 数据层: schema（prisma/drizzle/gorm...）
  └─ 业务入口: app/ src/ routes/
  守上下文最小化：只读整理架构所需，不全量扫。

Step2 输出「三件套」（全 ascii，给主人看，不写文件）
  ├─ 项目逻辑图（ascii）：架构图 + 业务生命周期 + 数据流
  ├─ 前端原型图（ascii）：关键页面 / 核心流程线框
  └─ MVP 差异点表格（ascii 框线）：模块 / 现状 / 目标 / gap / 风险
     ⚠️ 三件套是探测输出，辅助交谈，不是 ux.md
        （ux.md 由 agent-to-mvp 的 PM 段基于 prd 细化产出）
```

### 阶段二：强制 EnterPlanMode + 逐点循环（核心）

```
Step3 ⭐ 立即调用 EnterPlanMode 工具（不是文字描述！是 call 工具！）
       → 主人 approve 进入 plan 模式

Step4 三件套 + PRD 草案写进 plan 文件

Step5 逐点循环提问（一直保持在 plan 模式，不退出）
  循环：
    ├─ 浮浮酱列出【当前一个】逻辑模糊点 / 配置待确认点
    │  （一次只问一个，不批量输出）
    │  问清楚：项目距 MVP 还差什么逻辑 / 配置 / 状态机 / 边界
    ├─ 主人答疑 / 修订 / 补充
    ├─ 浮浮酱更新 plan 文件
    └─ 检查：项目距 MVP 的所有逻辑 + 配置是否完全通顺？
       ├─ 还有模糊 → 回循环顶，问下一个点
       └─ 全部通顺 → 进 Step6

  ⛔ 此阶段禁止：
     - 退出 plan 模式（未通顺不许 ExitPlanMode）
     - 用"全量决策清单 全量接受/逐项修订/否决"替代逐点提问
     - 一次性输出所有待决策项让主人批量选

Step6 全部通顺 → 调用 ExitPlanMode 提交 plan → 请求最终 approve
  └─ 主人 reject → 回 Step5 继续
  └─ 主人 approve → 进阶段三
```

### 阶段三：落地 prd.md + 交接

```
Step7 approve → 把定稿 plan 落地为 .cc_code/active/prd.md
  └─ 旧版归档 .cc_code/backup/YYYY-MM/
  └─ prd.md 结构按模板：模块清单 / 核心规则R / 验收断言A1..An
     （编号永久稳定，whole-qa 的分母）/ 状态机 / 边界 / 依赖

Step8 提示: 可走 /cc-code:agent-to-mvp 进入主线
```

---

## 二、prd.md 产出结构（对齐模板）

```
1. 模块清单（# / 模块 / 优先级 P0P1P2 / 依赖 / 状态）
2. 逐模块：
   ├─ 职责（一句话，写不成一句话 = 该拆）
   ├─ 核心规则 R1..Rn（每条可判真假，禁"优化/友好"等模糊词）
   ├─ 状态机（ascii，若有流转）
   ├─ 边界与异常
   ├─ 验收断言 A1..An（⭐编号永久稳定，作废只加删除线不重排）
   └─ 依赖
3. 全局规则 G1..Gn
4. 明确不做（Out of Scope）
```

> 不含：bug 清单（→ gates.md）、UI 规格（→ ux.md）、接口参数（→ api.md）

---

## 三、PM 产物边界

| 文件 | 定位 | 不写 |
| --- | --- | --- |
| `prd.md` | 分模块业务逻辑 + 规则 + 验收断言（规则是什么） | UI 规格、接口参数 |
| `ux.md` | 视觉规格 + 交互五态（长什么样、点了怎么变） | 业务规则、字段类型 |

> 判据：能脱离界面存在的 → `prd.md`；离开界面就没意义的 → `ux.md`。
> plan-prd-mvp 只产 `prd.md`，`ux.md` 由 agent-to-mvp 的 PM 段基于 prd 细化。

---

## 四、关键约束

| 约束 | 说明 |
| --- | --- |
| ⭐ 强制 EnterPlanMode | 阶段二必须 call `EnterPlanMode` 工具，不是文字描述"进入 plan 模式" |
| ⛔ 禁批量决策清单 | 不许"全量接受/逐项修订/否决"，必须逐点提问 |
| 逐点循环至通顺 | 一次一个模糊点，循环至所有逻辑+配置通顺才 ExitPlanMode |
| 先探后入 | 阶段一 plan 外探测+三件套，再 EnterPlanMode |
| plan 内只写 plan | plan 模式内只写 plan 文件，prd.md 等 approve 后才落地 |
| 动态读取 | 按项目结构探测，守上下文最小化 |
| 不越界 | 只写 `prd.md`，不碰 active/ 其他 md，不改代码 |
| 不找 bug | bug 是 QA 职责 |

---

## 五、与主线的关系

```
plan-prd-mvp（支线）                  cc-code 主线
────────────────────                  ──────────────────
阶段一 探测+三件套(ascii)              /cc-code:agent-to-mvp
   ↓ ⭐强制 call EnterPlanMode           ├─ PM（基于 prd 产 ux.md）
阶段二 逐点循环至通顺                   ├─ Architect（产 project/data/api）
   ↓ ExitPlanMode approve              ├─ Dev（编码）
阶段三 落地 prd.md ──────────────►     └─ QA（验收 → gates.md）

                                    /cc-code:whole-qa（收口全量验收）
```

---

## 六、触发后首步动作

1. Read `.cc_code/active/Agent.md` → 确认角色（独立 agent，先按 Architect 视角盘点）。
2. Read `.cc_code/active/status.md` → 同步坐标。
3. 动态探测项目结构（Step1）。
4. Step2 输出三件套（ascii 逻辑图 + ascii 原型图 + ascii 框线差异表）。
5. ⭐ Step3 立即 call `EnterPlanMode` 工具 → Step4 写 plan → Step5 逐点循环至通顺。
6. 通顺后 Step6 `ExitPlanMode` → approve → Step7 落地 prd.md。
