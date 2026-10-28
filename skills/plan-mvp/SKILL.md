---
name: plan-mvp
description: 做新项目前逐条问清需求，顺手替你定好前端形态与技术栈，画出页面原型，一次确认后写成方案文档
allowed-tools: Read, Write, Edit, Bash, Agent, SendMessage, AskUserQuestion, EnterPlanMode, ExitPlanMode, Skill
disable-model-invocation: true
---

# /cc-code:plan-mvp — MVP 规划编排器（第一动作即 plan 模式）

> ⭐⭐⭐ **触发后第一动作 = call `EnterPlanMode` 工具。**
> ⚙️ 引擎分支（双端同一条规则）：无 `EnterPlanMode` 工具的引擎（如 Codex）→ 第一动作改跑 Bash `mkdir -p .cc_code/.runtime && touch .cc_code/.runtime/plan-lock` 开护栏（此后写盘被 gate.sh 拦）。**一次批准窗口只解锁一次**：每个「主人批准」之后 `rm .cc_code/.runtime/plan-lock`，把这一批该落的全部落完（批准一：先 pm 落 prd、再 uiux 落 ux；批准二：冲突修订先落 prd / ux，再落 L3），落完立刻 `touch` 回锁；进入技术阶段前保持锁定。**规划结束（批准二落完）⛔ 不再回锁**：锁要放开给接下来的执行命令写盘。
> **本命令的主控只是传话员**：问需求的是 `pm` agent，问界面、布局与交互原型的是 `uiux` agent，问技术的是 `architect` agent。主控不读代码、不读技术文档、不思考需求、不替主人回答。
> **产出全部规划产物**：prd（pm）+ ux（uiux）+ project / data / api（architect）。`design.md` 的视觉内容本命令不写（留给 `/cc-code:plan-uiux` 定风格）；仅无前端项目由 uiux 把 §0 状态行改写为「不适用（无前端）」。
> **主人批准两次**：需求与原型一次、技术方案一次。批准即定稿，落盘后无二次验收；想改直接改对应文件或重跑本命令。

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
pm / uiux / architect 每轮只交回**一个**问题；主控不合并、不拆分、不追加。

### 铁律 4：逐点循环至通顺
pm 一直问到所有业务逻辑 + 配置通顺；uiux 一直问到页面、布局与交互五态通顺；architect 同理对技术方案。通不通顺由 agent 判，主控只看它交回的是「问题」还是「已通顺」。

> **前端形态不发问卷**：pm 按 `skills/cc-code/references/frontend-forms.md` 从主人的产品雏形推断「有哪几端、每端什么形态」，连同默认技术栈与组件库家族写进需求摘要（格式：我替你选了……原因……想改就说）；真推不出才问一句。

### 铁律 5：严格串行 pm → uiux → architect
需求（pm）与原型（uiux）都通顺、并在批准一之后落盘，才派 architect。architect 的输入是已落盘的 prd / ux，不是主控的转述；architect ⛔ 不读 `design.md`。

> 两段输入别混：uiux 在**问答期**吃主控原样转交的 pm 待落盘摘要（plan 模式写不了盘，此时 prd 还没落）；在**落盘期**读已落盘的 prd，再写 `ux.md`。

---

## 一、流程

```
触发 /cc-code:plan-mvp
     ↓
Step0 ⭐ 进入规划模式（第一动作）
     ↓ ════════ 需求与原型阶段（规划模式内，只读 + 文字）════════
Step1 派 pm（全新上下文）
      读：status、prd ＋ 主人原话
      推断：有哪几端、每端什么形态、默认技术栈与组件库家族（写进需求摘要）
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
      （摘要含：需求摘要 §〇 / 项目逻辑图 / 模块与断言要点，由 pm 出；
        问答中 pm 可画 ASCII 草图帮主人确认，⛔ 草图不落盘）
     ↓
Step2.5 派 uiux（全新上下文；主控把 pm 的待落盘摘要原样转交）
      读：status ＋ 主控转交的 pm 摘要（落盘期才读 prd）
      交回：下一个问题（一次一个，页面 / 布局 / 交互五态层面）
      uiux 交回「原型已通顺 + 待落盘摘要」才出循环
      （摘要含：前端形态表、页面清单、每页 ASCII 原型、可交互元素、
        交互五态要点、断点布局、跨页流转）
     ↓
Step3 ⭐ 退出规划模式，两份摘要原样交主人批准【批准一：需求与原型】
     ├─ 不批 → 回对应循环：需求问题回 pm、页面问题回 uiux，主人原话续接
     └─ 批准 ↓
Step4 落盘（同一解锁窗口内按序全部落完）
      ① 续接同一个 pm 落盘：prd.md（旧版归档）
      ② 续接同一个 uiux 落盘：ux.md（读①刚落盘的 prd）
         无前端项目：uiux 同时把 design.md §0 状态写「不适用（无前端）」
      回报落盘清单 → 主控更新 status.md 坐标与「风格：」行
     ↓ ════════ 技术阶段 ════════
Step5 ⭐ 重新进入规划模式
Step6 派 architect（全新上下文）
      读：status、prd、ux、三处经验 INDEX（项目 / 个人 / 团队，不存在跳过）、代码索引与代码 ＋ 主人原话
      （不读 design.md；前端形态只从 ux.md §一 取自）
      交回：下一个问题（一次一个）
     ↓
Step7 问答循环（同 Step2，对象换成 architect）
      architect 交回「技术方案已通顺 + 待落盘摘要」才出循环
      （摘要含：差异点表、选型与架构、阶段拆分与泳道、§一.1 家族、§六 视觉检查基建、§九 视觉地基阶段）
      ├─ architect 发现需求冲突 ──► 走「冲突回流」（见第二节）后继续
          （plan 模式写不了盘：pm / uiux 只交修订摘要，prd / ux 在批准二之后才落）
     ↓
Step8 ⭐ 退出规划模式，把摘要原样交主人批准【批准二：技术方案】
     ├─ 主人不批 → 回 Step7，主人原话续接 architect
     └─ 批准 ↓
Step9 落盘（同一解锁窗口内按序，全部落完再回锁）
      ① 若有冲突回流产生的修订摘要 → 先续接 pm 落 prd、再续接 uiux 落 ux
      ② 再续接同一个 architect 落 project + data + api
      （阶段拆分 + 并行泳道写进 project.md §九；首个阶段固定「视觉地基」）
     ↓
Step9.5 ⭐ 开工前断言体检（有无前端都要过；主人还在场，问题在这里问完）
      编排单一出处 = `active/Agent.md` §五「开工前断言体检」；判据单一出处 = `agents/qa.md`
      「开工前断言体检（plan 收尾，只读）」，本命令不复述
      派 qa（全新上下文，只读）：读 prd / ux / api / data ＋ 主人原话
      ├─ 有缺口 → 逐条原样问主人（带推荐答案；主人说「都按推荐」一次收齐）
      │           → 按归属续接原写者就地改（prd → pm、ux → uiux、L3 → architect）→ 再派 qa 复检
      └─ 通过 ↓（⛔ 没通过不许分流）
Step10 主控更新 status.md 坐标（含「风格：」行）→ 按有无前端分流提示
       有前端 → 提示走 /cc-code:plan-uiux（定风格；定完由它自动接 agent-mvp）
       无前端 → 直接调用 /cc-code:agent-mvp 自动开工（⛔ 不再停下等主人敲命令；入口检查不过它会自己拒跑；
               运行中零提问，规格缺口挂起、结尾一次交人，规则见 `../cc-code/references/dev-qa-loop.md` §九）
```

> ⭐ **plan 模式下 agent 写不了文件**：落盘一律放在 ExitPlanMode 之后（Step4、Step9），规划模式内 agent 只问答不写盘。
> ⭐ **落盘前必过「就地更新 + 搬运归档」**：规则单一出处 = `active/Agent.md` §四第 5 条，本命令不复述；落盘 agent 自己执行。

---

## 二、冲突回流（architect → pm / uiux → architect）

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
修订涉及页面 / 布局 / 交互五态？
     ├─ 是 ──► 修订摘要原样续接给原来那个 uiux，uiux 交回页面侧的修订摘要
     └─ 否 ──► 跳过 uiux
     ↓
主控把修订摘要原样续接给 architect，architect 以该摘要为准继续问答
     ↓
……批准二之后，才落盘：先续接 pm 落 prd、再续接 uiux 落 ux，最后 architect 落 L3
```

> 落盘顺序始终是 pm → uiux → architect：修订摘要在批准二之前只是对话内的口径，落盘在批准二之后。

---

## 三、任务说明（轮次表）

任务说明的固定格式（读哪些文件 + 主人原话 + 本轮要交回什么，不夹带主控的理解与任何技术内容）单一出处 = `active/Agent.md` §五，本命令不复述，只列各轮「读什么、交回什么」：

| 轮次 | 读哪些文件 | 本轮要交回什么 |
| --- | --- | --- |
| 首派 pm | `active/status.md`、`active/prd.md`（pm ⛔ 不读 `ux.md`、⛔ 不读 `design.md`） | 下一个问题（一次一个；有明确选项就列出选项）；需求摘要（端 / 形态 / 默认栈 / 家族 / 理由 / 想改就说） |
| 续接 pm | 同上 | 下一个问题；或「需求已通顺 + 待落盘摘要」 |
| pm 落盘 | 同上 | 落盘 prd.md，回报落盘清单 |
| 首派 uiux | `active/status.md`、主控原样转交的 pm 摘要（落盘期加读刚落的 `active/prd.md` 与已有 `active/ux.md`） | 下一个问题（一次一个，页面 / 布局 / 五态层面）；或「原型已通顺 + 待落盘摘要」（形态表、页面清单、每页 ASCII 原型、可交互元素、五态要点、断点布局、跨页流转） |
| 续接 uiux | 同上 | 下一个问题；或「原型已通顺 + 待落盘摘要」 |
| uiux 落盘 | 同上（读已落盘的 prd） | 落盘 `ux.md`（就地更新；无前端项目同步把 `design.md` §0 写「不适用（无前端）」），回报落盘清单 |
| 首派 architect | `active/status.md`、`active/prd.md`、`active/ux.md`、`references/INDEX.md`、`~/.cc-code/lessons/INDEX.md`、`~/.cc-code/team/<仓库名>/INDEX.md`（三处经验索引，不存在则跳过）、代码索引与代码（⛔ 不读 `design.md`） | 下一个问题（一次一个）；发现需求冲突就交回冲突 |
| 续接 architect | 同上 | 下一个问题；或「技术方案已通顺 + 待落盘摘要」 |
| architect 落盘 | 同上 | 落盘 project.md、data.md、api.md（含 §一.1 家族、§六 视觉检查基建、§九 阶段与泳道；采纳的跨项目经验写进 project.md §五 特殊约束），回报落盘清单与「采纳经验」一行 |
| qa 断言体检（Step9.5） | `active/prd.md`、`active/ux.md`、`active/api.md`、`active/data.md`（只读）＋ 主人原话 | 「体检通过」；或缺口清单（每条一句业务语言问题 + 推荐答案 + 归哪个文件、哪个写者改）。判据见 `agents/qa.md`「开工前断言体检」；⛔ 不写 `gates.md` |

> 经验的读法、转写、「采纳经验」行格式与优先级单一出处 = `active/Agent.md` §四第 7 条，本命令不复述。architect 落盘完成后，主控后台派一次 curator 记采纳（派发方式见 `Agent.md` §五「派 curator」）。

---

## 四、产物（谁写哪个文件见 `active/Agent.md` §二 / §三）

本命令产出三批文件：pm 写 `prd.md`（含 §〇 需求摘要）；uiux 写 `ux.md`（§一 前端形态与页面清单、每页 ASCII 原型 / 组件清单 / 五态矩阵 / 可交互元素 / 断点布局 / 边界 Case、跨页流转）；architect 写 `project.md`（含 §一.1 前端组件库家族、§六 测试基建契约、§七 日志契约、§八 部署契约、§九 阶段拆分 + 并行泳道，首个阶段固定「视觉地基」）、`data.md`、`api.md`。主控只写 `status.md`（坐标 / 卡点 / 下一步 / 「风格：」行，业务语言）。

> `design.md` 的视觉内容不在本命令落盘（仅无前端项目由 uiux 把 §0 状态行改写为「不适用（无前端）」）：`/cc-code:plan-uiux` 定风格时由 uiux 写视觉内容并按需锁定（状态四值与 `status.md`「风格：」五值的对应关系以 `templates/design.md` §0.2 为准）。
> 判据：能脱离界面存在的 → `prd.md`；页面结构、布局与交互五态 → `ux.md`；换一套皮肤就会变的视觉数值与长相 → `design.md`（归 `plan-uiux`）。各文件的章节结构以 `templates/` 下同名模板为准，本命令不复述。
> uiux ⛔ 不在 `ux.md` 写任何色值、字体、圆角、阴影、样式实现。
> 角色权限（谁能读什么、写什么）唯一出处 = `active/Agent.md` §三，本命令不复述。
> 阶段拆分与泳道并入 `project.md` §九，**不另建方案文件**；格式与铁律见该节，泳道协议见 `skills/cc-code/references/parallel-lanes.md`。`agent-mvp` 是纯执行器，**不再细化任何规划产物**——缺什么本命令补齐。

---

## 五、三件套（谁出什么）

三件套是交谈辅助，**不是 ux.md**；全部由 agent 产出，主控原样展示。

| 件 | 产出者 | 出现阶段 | 内容 |
| --- | --- | --- | --- |
| 项目逻辑图（ascii） | pm | 需求阶段，随问题或摘要 | 业务生命周期、数据流向（只讲业务，不讲技术架构） |
| 页面 ASCII 原型（ascii） | uiux | 需求阶段，随问题或摘要 | 页面结构、布局骨架、主要元素位置与跨页流转（⛔ 不写色值、字体、样式实现） |
| MVP 差异点表（ascii 框线：模块 / 现状 / 目标 / gap / 风险） | architect | 技术阶段，随摘要 | 现状来自代码探测，gap 与风险为技术判断 |

> pm 在需求问答里也可以画 ASCII 草图帮主人确认，但那只是对话内的辅助、⛔ 不落盘、不进三件套；正式页面原型归 uiux。

---

## 六、关键约束

| 约束 | 说明 |
| --- | --- |
| ⭐ 第一动作 call EnterPlanMode | 触发后不许先做别的 |
| 主控只传话 | 不读代码 / L3，不跑 codegraph，不思考需求，不替主人回答 |
| 串行顺序 | pm → uiux → architect；两次批准（需求与原型、技术方案） |
| 前端形态不发问卷 | pm 按 `frontend-forms.md` 推断端与形态，默认栈与家族写进需求摘要；真推不出才问一句 |
| 续接不新派 | 同一阶段同一个 agent 一直续接，保留全部记忆；⛔ 不另派顶替 |
| ⛔ 禁批量决策清单 | 一次一个问题 |
| 任务说明格式 | 单一出处 = `active/Agent.md` §五 |
| 规划模式内只问答 | 一切写盘等 ExitPlanMode 之后 |
| 落盘顺序 | prd → ux → L3；同一解锁窗口内落完，Codex 侧落完立即回锁 |
| 收尾分流 | 先过 Step9.5 断言体检（缺口当场问完，不过不分流）；有前端（`ux.md` §一 有任一非「无前端」的端）→ 提示 `plan-uiux`；无前端 → 直接调用 `agent-mvp` 自动开工 |
| 不越界 | 主控只写 `status.md`；不动 Agent.md、gates.md、bugs.md、src/、测试目录 |
| 对主人说话 | 规则单一出处 = `active/Agent.md` §四第 6 条，本命令不复述 |
| 不找 bug | bug 是 qa 职责 |

---

## 七、与主线的关系

```
plan-mvp（规划，人参与）                    cc-code 主线
────────────────────────                  ──────────────────
进入规划模式                                /cc-code:plan-uiux（定风格）
pm 问答 ─┐                                   └─ uiux 写 design.md + 样板板
uiux 问答 ┴─► 主人批准【需求与原型】             │
pm 落 prd、uiux 落 ux                          ▼
architect 问答 ─► 主人批准【技术方案】        /cc-code:agent-mvp（纯执行）
architect 落 project + data + api ──►        ├─ dev（视觉地基 → 编码）
qa 断言体检（缺口当场问完）                    └─ qa（四层验收 → gates.md）
                                              → agent-whole-qa（收口全量验收）
```

> 功能迭代不走本命令，走 `plan-feature`（规划）→ `agent-feature`（执行）。无前端项目跳过 `plan-uiux`，直接 `agent-mvp`。

---

## 八、触发后首步动作

⭐ **第一个动作：call `EnterPlanMode` 工具。不许先做任何其他事。**

进入规划模式后，按 Step1-10 执行。