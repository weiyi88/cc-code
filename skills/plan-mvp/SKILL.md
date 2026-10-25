---
name: plan-mvp
description: 做新项目前逐条问清需求，画流程图和页面草图，确认后写成方案文档
allowed-tools: Read, Write, Edit, Bash, Agent, SendMessage, AskUserQuestion, EnterPlanMode, ExitPlanMode
disable-model-invocation: true
---

# /cc-code:plan-mvp — MVP 规划编排器（第一动作即 plan 模式）

> ⭐⭐⭐ **触发后第一动作 = call `EnterPlanMode` 工具。**
> ⚙️ 引擎分支（双端同一条规则）：无 `EnterPlanMode` 工具的引擎（如 Codex）→ 第一动作改跑 Bash `mkdir -p .cc_code/.runtime && touch .cc_code/.runtime/plan-lock` 开护栏（此后写盘被 gate.sh 拦），每次「主人批准」之后、agent 落盘之前 `rm .cc_code/.runtime/plan-lock`，进入技术阶段时再 `touch` 回去。
> **本命令的主控只是传话员**：问需求的是 `pm` agent，问技术的是 `architect` agent，主控不读代码、不读技术文档、不思考需求、不替主人回答。
> **产出全部规划产物**：prd / ux（pm 写）+ project / data / api（architect 写）。
> **主人批准两次**：需求一次、技术方案一次。批准即定稿，落盘后无二次验收；想改直接改对应文件或重跑本命令。

## ⛔ 五条铁律（违反即失败）

### 铁律 1：第一动作 call EnterPlanMode
触发后，在 call `EnterPlanMode` 之前，**不许做任何动作**：
- ❌ 不许先 Read 任何文件
- ❌ 不许先派 agent
- ❌ 不许先输出任何内容
- ✅ 唯一允许的第一动作：call `EnterPlanMode` 工具

### 铁律 2：主控只传话
主控能做 / 不能做的清单单一出处 = `active/Agent.md` §一、§五，本命令不复述；本命令一个字不改 Agent.md。

### 铁律 3：禁批量决策清单，一次一个问题
⛔ 禁止「全量输出决策清单，可全量接受 / 逐项修订 / 否决某项」。
pm / architect 每轮只交回**一个**问题；主控不合并、不拆分、不追加。

### 铁律 4：逐点循环至通顺
pm 一直问到所有业务逻辑 + 配置通顺，才交回「需求已通顺」；architect 同理对技术方案。通不通顺由 agent 判，主控只看它交回的是「问题」还是「已通顺」。

### 铁律 5：先 PM 后 Architect，严格串行
需求（pm）批准并落盘之后，才派 architect。architect 的输入是已落盘的 prd / ux，不是主控的转述。

---

## 一、流程

```
触发 /cc-code:plan-mvp
     ↓
Step0 ⭐ 进入规划模式（第一动作）
     ↓ ════════ 需求阶段（规划模式内，只读 + 文字）════════
Step1 派 pm（全新上下文）
      读：status、prd、ux ＋ 主人原话
      交回：下一个问题（一次一个）
     ↓
Step2 问答循环（主控只传话）
      ┌──────────────────────────────────────────┐
      │ pm 的问题 ──原样──► 主人                    │
      │   有明确选项 → 选项卡片；没有 → 直接文字      │
      │ 主人的话 ──原样──► 同一个 pm（续接，不新派）  │
      │ pm 交回下一个问题 ─┐                        │
      └────────────────────┘                       │
      pm 交回「需求已通顺 + 待落盘摘要」才出循环 ◄─────┘
      （摘要含：项目逻辑图 / 页面原型图 / 模块与断言要点，均由 pm 出）
     ↓
Step3 ⭐ 退出规划模式，把摘要原样交主人批准【批准一：需求】
     ├─ 主人不批 → 回 Step2，主人原话续接 pm
     └─ 批准 ↓
Step4 续接同一个 pm 落盘：prd + ux（旧版归档）
      pm 回报落盘清单 → 主控更新 status.md 坐标
     ↓ ════════ 技术阶段 ════════
Step5 ⭐ 重新进入规划模式
Step6 派 architect（全新上下文）
      读：status、prd、ux、三处经验 INDEX（项目 / 个人 / 团队，不存在跳过）、代码索引与代码 ＋ 主人原话
      交回：下一个问题（一次一个）
     ↓
Step7 问答循环（同 Step2，对象换成 architect）
      architect 交回「技术方案已通顺 + 待落盘摘要」才出循环
      （摘要含：差异点表、选型与架构、阶段拆分与泳道）
      ├─ architect 发现需求冲突 ──► 走「冲突回流」（见第二节）后继续
          （plan 模式写不了盘：pm 只交修订摘要，prd / ux 在批准二之后才落）
     ↓
Step8 ⭐ 退出规划模式，把摘要原样交主人批准【批准二：技术方案】
     ├─ 主人不批 → 回 Step7，主人原话续接 architect
     └─ 批准 ↓
Step9 落盘（先 pm 后 architect）
      ① 若有冲突回流产生的修订摘要 → 先续接同一个 pm 落 prd / ux
      ② 再续接同一个 architect 落 project + data + api
      （阶段拆分 + 并行泳道写进 project.md §九）
     ↓
Step10 主控更新 status.md 坐标 → 提示走 /cc-code:agent-mvp
```

> ⭐ **plan 模式下 agent 写不了文件**：落盘一律放在 ExitPlanMode 之后（Step4、Step9），规划模式内 agent 只问答不写盘。
> ⭐ **落盘前必过「就地更新 + 搬运归档」**：规则单一出处 = `active/Agent.md` §四第 5 条，本命令不复述；落盘 agent 自己执行。

---

## 二、冲突回流（architect → pm → architect）

architect 在技术阶段发现需求写不通（与已落盘的 prd / ux 矛盾、或需求在技术上无法成立），**不许自行改需求**，按下图走：

```
architect 交回「需求冲突」（只用业务语言，不带技术细节）
     ↓
主控原样问主人（选项卡片 / 文字）
     ↓
主人回答
     ↓
主人原话 ──原样──► 原来那个 pm（续接，保留它的全部记忆）
     ↓
pm 交回「修订摘要」（业务语言；规划模式下写不了盘，此时不改 prd / ux）
     ↓
主控把修订摘要原样续接给 architect，architect 以该摘要为准继续问答
     ↓
……批准二之后，才落盘：先续接 pm 落 prd / ux，再续接 architect 落 L3
```

> 落盘顺序始终是先 pm 后 architect：修订摘要在批准二之前只是对话内的口径，落盘在批准二之后。

---

## 三、任务说明（轮次表）

任务说明的固定格式（读哪些文件 + 主人原话 + 本轮要交回什么，不夹带主控的理解与任何技术内容）单一出处 = `active/Agent.md` §五，本命令不复述，只列各轮「读什么、交回什么」：

| 轮次 | 读哪些文件 | 本轮要交回什么 |
| --- | --- | --- |
| 首派 pm | `active/status.md`、`active/prd.md`、`active/ux.md` | 下一个问题（一次一个；有明确选项就列出选项） |
| 续接 pm | 同上 | 下一个问题；或「需求已通顺 + 待落盘摘要」 |
| pm 落盘 | 同上 | 落盘 prd.md、ux.md，回报落盘清单 |
| 首派 architect | `active/status.md`、`active/prd.md`、`active/ux.md`、`references/INDEX.md`、`~/.cc-code/lessons/INDEX.md`、`~/.cc-code/team/<仓库名>/INDEX.md`（三处经验索引，不存在则跳过）、代码索引与代码 | 下一个问题（一次一个）；发现需求冲突就交回冲突 |
| 续接 architect | 同上 | 下一个问题；或「技术方案已通顺 + 待落盘摘要」 |
| architect 落盘 | 同上 | 落盘 project.md、data.md、api.md（含 §九 阶段与泳道；采纳的跨项目经验写进 project.md §五 特殊约束），回报落盘清单与「采纳经验」一行 |

> 经验的读法、转写、「采纳经验」行格式与优先级单一出处 = `active/Agent.md` §四第 7 条，本命令不复述。architect 落盘完成后，主控后台派一次 curator 记采纳（派发方式见 `Agent.md` §五「派 curator」）。

---

## 四、产物（谁写哪个文件见 `active/Agent.md` §二 / §三）

本命令产出两批文件：pm 写 `prd.md`、`ux.md`；architect 写 `project.md`（含 §九 阶段拆分 + 并行泳道、§六 测试基建契约、§七 日志契约、§八 部署契约）、`data.md`、`api.md`。主控只写 `status.md`（坐标 / 卡点 / 下一步，业务语言）。

> 判据：能脱离界面存在的 → `prd.md`；离开界面就没意义的 → `ux.md`。各文件的章节结构以 `templates/` 下同名模板为准，本命令不复述。
> 角色权限（谁能读什么、写什么）唯一出处 = `active/Agent.md` §三，本命令不复述。
> 阶段拆分与泳道并入 `project.md` §九，**不另建方案文件**；格式与铁律见该节，泳道协议见 `skills/cc-code/references/parallel-lanes.md`。`agent-mvp` 是纯执行器，**不再细化任何规划产物**——缺什么本命令补齐。

---

## 五、三件套（谁出什么）

三件套是交谈辅助，**不是 ux.md**；全部由 agent 产出，主控原样展示。

| 件 | 产出者 | 出现阶段 | 内容 |
| --- | --- | --- | --- |
| 项目逻辑图（ascii） | pm | 需求阶段，随问题或摘要 | 业务生命周期、数据流向（只讲业务，不讲技术架构） |
| 前端原型图（ascii） | pm | 需求阶段，随问题或摘要 | 关键页面 / 核心流程线框 |
| MVP 差异点表（ascii 框线：模块 / 现状 / 目标 / gap / 风险） | architect | 技术阶段，随摘要 | 现状来自代码探测，gap 与风险为技术判断 |

---

## 六、关键约束

| 约束 | 说明 |
| --- | --- |
| ⭐ 第一动作 call EnterPlanMode | 触发后不许先做别的 |
| 主控只传话 | 不读代码 / L3，不跑 codegraph，不思考需求，不替主人回答 |
| 先 pm 后 architect | 严格串行；两次批准（需求、技术方案） |
| 续接不新派 | 同一阶段同一个 agent 一直续接，保留全部记忆；⛔ 不另派顶替 |
| ⛔ 禁批量决策清单 | 一次一个问题 |
| 任务说明格式 | 单一出处 = `active/Agent.md` §五 |
| 规划模式内只问答 | 一切写盘等 ExitPlanMode 之后 |
| 不越界 | 主控只写 `status.md`；不动 Agent.md、gates.md、bugs.md、src/、测试目录 |
| 对主人说话 | 规则单一出处 = `active/Agent.md` §四第 6 条，本命令不复述 |
| 不找 bug | bug 是 qa 职责 |

---

## 七、与主线的关系

```
plan-mvp（规划，人参与）                 cc-code 主线
────────────────────────                ──────────────────
进入规划模式                              /cc-code:agent-mvp（纯执行）
pm 问答 ─► 主人批准【需求】                 ├─ dev（编码）
pm 落盘 prd + ux                          └─ qa（验收 → gates.md）
architect 问答 ─► 主人批准【技术方案】          → agent-whole-qa（收口全量验收）
architect 落盘 project + data + api ──►
```

> 功能迭代不走本命令，走 `plan-feature`（规划）→ `agent-feature`（执行）。

---

## 八、触发后首步动作

⭐ **第一个动作：call `EnterPlanMode` 工具。不许先做任何其他事。**

进入规划模式后，按 Step1-10 执行。
