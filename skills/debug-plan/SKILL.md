---
name: debug-plan
description: ⭐显式触发的【bug 诊断器】（不是需求规划器）。触发后【第一动作必须 call EnterPlanMode 工具】（不许先做任何其他动作）。plan 内：把 bug 问清楚（逐点提问）→ codegraph 四路调查脉络（explore 读现状 + node/callers 追链路 + impact 算传递闭包半径 + affected 算测试面）→ 裁决门（期望无出处/修复需动契约 → 拒修指路 plan-prd-feature）→ 输出三件套（逻辑图 + 差异表格 + 涉前端时 ASCII 原型）→ ExitPlanMode 主人确认 → 落盘 active/bugs.md 新条目 B-n + status.md 指向。⛔禁改 prd/ux/api/data、禁生成新需求断言、禁写代码、禁碰 gates.md。三件套本体不落盘。
allowed-tools: Read, Write, Edit, Bash, Glob, Grep, EnterPlanMode, ExitPlanMode, ToolSearch, mcp__codegraph__codegraph_explore
disable-model-invocation: true
---

# /cc-code:debug-plan — bug 诊断器（第一动作即 plan 模式）

> ⭐⭐⭐ **触发后第一动作 = call `EnterPlanMode` 工具。**
> 所有问诊 / 侦察 / 三件套 / 交谈都在 plan 模式内做，**没有 plan 外窗口**。
> **定位：技术诊断器，不是需求规划器。** 与 `/cc-code:plan-prd-feature` 的分界：那个处理「需求模糊」，本命令处理「需求明确但实现错了」—— bug 本身就是需求，期望行为要么主人说了、要么 prd.md 已有断言。
> **配对**：本命令落盘 B-n 后，修复执行走 `/cc-code:debug-qa-dev`（增量定位 B-n → Dev→QA → affected 精准回归）。

## ⛔ 六条铁律（违反任一即本次诊断无效）

### 铁律 1：第一动作 call EnterPlanMode
触发后，在 call `EnterPlanMode` 之前，**不许做任何动作**：

- ❌ 不许先 Read `Agent.md` / `status.md`
- ❌ 不许先 codegraph 探测
- ❌ 不许先输出三件套
- ✅ 唯一允许的第一动作：call `EnterPlanMode` 工具

### 铁律 2：期望行为唯一来源 = 主人原话 + 既有 A/U 断言
这是 plan-prd-feature 铁律 2 在 debug 线的移植 —— **诊断时最容易犯的错就是拿实现当期望**。

```
期望行为的合法出处：
  ✅ 主人在对话里的原话
  ✅ prd.md §1.5 的既有 A 断言
  ✅ ux.md §2.3 的既有 U 判定项

  ⛔ 绝不许从「代码现状」反推「所以期望应该是 X」
  ⛔ 绝不许从 codegraph 产出反推期望 —— codegraph 只答「代码现在是什么样」
```

### 铁律 3：裁决门（bug ↔ 迭代的分界）
满足任一即**拒修**，指路 `/cc-code:plan-prd-feature`，本命令到此为止：

```
① 修复需要改 api.md / data.md 契约
② 修复需要改 prd.md / ux.md 需求（新规则 / 新断言 / 新交互态）
③ 期望行为在合法出处里找不到，且主人不愿当场拍板
```

> 「深层 bug 牵涉多文件」**不是**拒修理由 —— 影响面大小是事实问题，由 `impact` / `affected` 沿 import 图算出，不由规划仪式回答。**动契约才拒修，不动契约再深也修。**

### 铁律 4：三件套只确认不落盘
三件套服务当轮对话裁决，主人 ExitPlanMode 确认即弃。落盘物仅两处：`bugs.md` 的 B-n 条目 + `status.md` 一行指针。

### 铁律 5：B 编号独立序列
`bugs.md` 的 B-n 独立递增（读已有最大号取下一个），**绝不复用 A/U 序列**（那两个永久稳定，bug 断言生命周期是天级）。条目修完即删，不占 active 篇幅。

### 铁律 6：越权红线
```
⛔ active/prd.md / ux.md / api.md / data.md / project.md —— 本 skill 绝不改写
⛔ active/gates.md                                          —— QA 唯一域
⛔ src/ 与测试目录                                          —— Dev 唯一域
✅ active/bugs.md 新条目 + status.md「下一步」一行           —— 唯一落盘动作
```

---

## 一、生命周期总览

```
触发 /cc-code:debug-plan "<bug 描述>"
  │
Step0 ⭐ call EnterPlanMode（第一动作，Write/Edit 当场锁死）
  │ ══════════════ 以下全程 plan 模式内（只读 + 文字输出）══════════════
Step1 把 bug 问清楚（逐点提问，一次一个模糊点，禁批量决策清单）
  │   问什么：现象 / 复现步骤 / 期望行为（当场要出处：主人原话 or 既有 A/U 断言）
  │
Step2 codegraph 四路调查脉络（只取事实）
  │   ⓪ 新鲜度保险 → status --json：pendingChanges 非 0 则先 sync
  │   ① explore(bug 现象关键词) → node(涉事符号)  读现状
  │   ② callers(涉事符号)                        追触发链路
  │   ③ impact(核心符号)                         传递闭包真半径
  │   ④ affected(涉及文件)                       测试影响面
  │   CLI 未装 → 降级 Glob/Grep 表层扫描，三件套标注「半径为估算」
  │
Step3 根因定位（根因 = 一句话说得清的因果链；说不清 → 回 Step1 继续问）
  │
Step4 裁决门（铁律 3 三条逐一检查）
  │   ├─ 命中任一 → ⛔ 拒修：「这不是 bug 修复，是迭代，请走 /cc-code:plan-prd-feature」
  │   └─ 全过 → Step5
  │
Step5 输出三件套（bug 版，ascii）
  │   ① 逻辑图：bug 触发链路（只画逻辑，无函数无代码）
  │   ② 差异表格：现状(实然) vs 期望(应然) vs 修复方案 逐行对齐
  │   ③ ASCII 前端原型：仅涉前端改动时给（修前 / 修后对比）
  │
Step6 逐点交谈至通顺（主人对根因/方案有疑 → 修 → 刷新三件套）
  │
Step7 call ExitPlanMode → 主人确认三件套
  │ ══════════════ 退出 plan 模式 ══════════════
Step8 落盘（确认即授权）
  │   bugs.md 新条目 B-n（复现/期望出处/根因/方案/影响面，≈15 行）
  │   status.md「下一步」→ B-n 待修复（一行指针）
  │   提示主人走 /cc-code:debug-qa-dev
```

---

## 二、Step1 问诊规格

一次只问一个模糊点（禁批量决策清单），必问清单：

| # | 问题 | 要什么 |
| --- | --- | --- |
| 1 | 现象是什么 | 与期望的偏差描述 |
| 2 | 怎么复现 | 步骤化；不可复现 → 先陪主人定位触发条件 |
| 3 | 期望行为是什么 | **出处**：主人原话（记进 B-n 条目）or 引用既有 A/U 断言号 |
| 4 | 何时开始出现 | 若主人知道（版本/改动节点），可加速 Step2 定位 |

> 期望出处拿不到 → 直接走裁决门 ③ 拒修流程，不硬猜。

---

## 三、Step2 codegraph 侦察规格（只取事实）

与 plan-prd-feature Step2 同构，产出只许流向三处：根因定位的判据 / 影响半径的陈述 / affected 测试面清单。**一个字都不许流向「期望应该是什么」**（铁律 2）。

| 序 | 能力 | 回答什么 | 产出流向 |
| :-- | :-- | :-- | :--- |
| ① | `explore` → `node` | 「涉事代码现在怎么实现的」 | 根因定位 |
| ② | `callers` | 「谁触发这条链路」 | 逻辑图（触发链） |
| ③ | `impact` | 「修复会炸到哪」传递闭包 | B-n 影响面 + 差异表 |
| ④ | `affected` | 「该跑哪些测试」 | B-n 影响面（测试部分） |

---

## 四、三件套规格（bug 版）

### ① 逻辑图（bug 触发链路）
```
例（只画逻辑，无函数无代码）：

用户连点登录
  → 第二次请求携带旧 token
  → 旧请求后到，覆盖新 token
  → 后续请求全部 401
```

### ② 差异表格

| 维度 | 现状（实然） | 期望（应然，注明出处） | 修复方案 |
| --- | --- | --- | --- |
| 连点提交 | 旧请求覆盖新 token | 提交期间锁死，失败回滚（A12.4） | 提交态锁 + 失败回滚 |
| … | … | … | … |

### ③ ASCII 前端原型（仅涉前端时）

修前 / 修后对比；纯后端 / 纯逻辑 bug 跳过此项。

---

## 五、落盘规格（Step8，ExitPlanMode 后）

### bugs.md 条目模板（单条 ≈ 15 行）

```markdown
## B-1｜<模块-功能简述> | OPEN
*   **复现：** <步骤>
*   **期望出处：** <A12.4 / U2.1 / 主人原话>
*   **根因：** <一句话>
*   **方案：** <一句话；不动契约>
*   **影响面：** <文件清单（impact/affected 已算；估算则注明）>
```

### 落盘动作（仅两处）

| 动作 | 文件 | 内容 |
| --- | --- | --- |
| 1 | `active/bugs.md` | 追加 B-n 条目（读已有最大 B 号取下一个） |
| 2 | `active/status.md` | 「下一步」改写为「B-n 待修复，走 /cc-code:debug-qa-dev」 |

⛔ 三件套本体、侦察记录、问诊过程**均不落盘**。

---

## 六、关键约束速查

| 约束 | 说明 |
| --- | --- |
| ⭐ 第一动作 call EnterPlanMode | 触发后不许先做别的 |
| 无 plan 外窗口 | 问诊/侦察/三件套/交谈全在 plan 内 |
| 期望唯一来源 | 主人原话 + 既有 A/U 断言；⛔ 禁 codegraph 反推 |
| 裁决门三条 | 动契约 / 动需求 / 期望无出处 → 拒修转 plan-prd-feature |
| 深层不是拒修理由 | 影响面由 impact/affected 算，不由规划仪式回答 |
| 三件套只确认不落盘 | 落盘物仅 B-n 条目 + status 指针 |
| B 序列独立 | 不复用 A/U；修完条目即删 |
| 不修不写 | 不写代码、不碰 gates、不改五规范文件 |

---

## 七、与命令族谱的关系

| 场景 | 规划 | 执行 |
| --- | --- | --- |
| 0→1 全量 | plan-prd-mvp | agent-to-mvp |
| 增量功能 | plan-prd-feature | agent-to-feature |
| **bug 修复** | **debug-plan（本命令）** | debug-qa-dev |

---

## 八、触发后首步动作

⭐ **第一个动作：call `EnterPlanMode` 工具。不许先做任何其他事。**

进入 plan 模式后，按 Step1 → Step8 执行。
