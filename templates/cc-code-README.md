# 🧭 .cc_code 使用手册（cc-code 1.8.1）

> 本文件由 `/cc-code:init` 生成并随插件版本刷新，是**给「不熟悉 cc-code 的人」的上手说明书**。
> 项目业务状态永远在 `active/`；本手册只讲「这套系统怎么用」。

---

## 一、这套系统在解决什么问题

LLM 写代码有三病：**写着写着忘了目标、上下文越滚越脏、凭记忆瞎答**。
cc-code 的处方：**把记忆、状态、规则全部外部寄存到 `.cc_code/` 静态文件**，AI 每次会话按协议读文件定位自己，而不是靠脑容量。

```
① 记忆/逻辑/状态全外部寄存 ── 落 .cc_code/ 静态文件
② 责任垂直化 ── 每个 agent 只掌一层，禁止越权
③ 决策串行 ── pm → architect → dev → qa，一次只派一个 agent
```

---

## 二、核心逻辑：agent 串行 + 文件分层

### 角色 = agent（主控只传话）

```
pm ──► architect ──► dev ──► qa          旁路：uiux（只画前端原型）
(需求)   (架构)      (编码)   (验收)           后台：curator（结算后静默整理经验）

主控 = 编排者：派 agent、原样转问、原样续接你的回答；
         不读代码、不替你回答、不代写任何角色的文件（含 init 升级迁移，要改一律派该文件的写者 agent），只记坐标和里程碑
```

派哪个 agent，它就是哪个角色，没有「切角色」这一步。每个 agent 只许按自己的权限卡片读写文件（卡片只在 `active/Agent.md` §三 写一次），越权即违规。

> **串行 ≠ 单线程（1.6.0）**：`project.md` §九 把一个阶段拆成几条互不相干的泳道后，执行时同一角色可以多人同时干（Dev 一起写 → 全部写完 → QA 一起验 → 没过的泳道单独退回）。agent 顺序不变，每个文件仍只有一个写者。没写泳道就照旧单线程。

### 文件分层（先认层，再认谁写）

| 层 | 文件 | 装什么 |
| --- | --- | --- |
| **L0 控制** | `active/Agent.md` | 最高宪法：agent 分工 + 权限卡片 |
| | `active/status.md` | 当前坐标 + 卡点 + 下一步（里程碑不落此文件） |
| **L1 意图** | `active/prd.md` | 分模块业务逻辑 + 规则 + 验收断言 A1..An |
| **L2 表现** | `active/ux.md` | 视觉规格 + 交互五态矩阵 |
| **L3 实现** | `active/project.md` | 技术宪法（架构/选型/决策记录） |
| | `active/data.md` | 数据契约（interface ↔ DB 列） |
| | `active/api.md` | 接口契约（method/path/入参/出参/错误码） |
| **L4 验收** | `active/gates.md` | QA 实测结果 + FAIL 清单（dev 禁读） |
| — | `active/bugs.md` | 未修复 bug 工作上下文（B-n 施工便签，修完搬走） |
| — | 根目录 `design.pen` | 前端可视化原型（pen 模式时视觉唯一出处；⭐加密文件只准 pencil MCP 读写） |
| — | `references/` | 项目级经验库（curator 全自动整理；INDEX 索引，architect / dev 按需读）。个人库 `~/.cc-code/lessons/`、团队库 `~/.cc-code/team/` 在项目外；主题文件写法范本见插件 `templates/references-example-async-queue.md` |
| — | `docs/qa/` | QA 全量报告 |
| — | `backup/` | 冷数据归档：change-log.md / milestone-log.md / `retired/` 退役原文（人看历史，AI 工作时禁读） |
| — | `.cc_code_version` | 场域版本戳 |

> 谁写哪个文件、各 agent 的读写范围，单一出处 = `active/Agent.md` §二 / §三，此处不抄副本。`Agent.md` 与根目录 `CLAUDE.md` / `AGENTS.md` 是插件规范文件，唯一写者 = init 脚本（升级时机械覆盖，旧版先快照），项目内不手改。

**信息流单向**：`L1 → L2 → L3 → 代码 → L4 回验`。L4 只拿 L1/L2 当尺子，绝不拿代码当尺子。

### active 为什么不会越用越胖（1.7.0）

`active/` 只放**项目最新的状态和内容**。任何 agent 写它之前，先按下面处置一遍：

```
          要写 active 文件
                 │
    ┌────────────┼──────────────┬────────────────┐
    ▼            ▼              ▼                ▼
 内容变了     内容是新的      内容过期了        内容没变
                            (做完/修好/作废)
    │            │              │                │
    ▼            ▼              ▼                ▼
只改那几行   插进它该在的    原文整段搬进        一行不碰
其余不动     小节, 不堆末尾  backup/retired/
                            再从 active 移除
    │            │              │                │
    └────────────┴──────┬───────┴────────────────┘
                        ▼
   active 只剩最新状态　旧内容在 backup 全文可查　一个字都没丢
```

| 好处 | 怎么来的 |
| --- | --- |
| 文件不随对话次数变胖 | 过期内容每次都搬走，active 行数由「现在有多少规则」决定，不由「用了多少次」决定 |
| 省钱、不丢缓存 | 没变的行一次都不重写 |
| 旧内容照样查得到 | 全在 `backup/retired/<源文件名>.md`，一字不丢；`backup/` 不进 git，不怕大 |

> ⚠️ `backup/` 是历史的唯一载体且不进 git —— 别手动清它。

---

## 三、Skill 一览（16 个）

### 框架核心（管流程）

| skill | 触发 | 什么时候用 |
| --- | --- | --- |
| `init` | `/cc-code:init` | 首次使用建好整个管理文件夹和核心文档；已有项目自动升级，全程零删除 |
| `cc-code` | 自动 | 含 `.cc_code/` 的项目自动加载的流程管家：规划→开发→测试→验收，四步走完才准上线 |
| `plan-mvp` | `/cc-code:plan-mvp` | 做新项目：先由产品 agent 逐条问清需求，你批准后落盘；再由架构 agent 逐条问清技术方案，你批准后落盘 |
| `plan-feature` | `/cc-code:plan-feature` | 加新功能：同样先问清需求、再问清技术方案（架构 agent 负责扫现有代码查冲突），两次批准后落盘 |
| `plan-uiux` | `/cc-code:plan-uiux` | 先试画 2 页定风格，再逐页画进 `design.pen` 设计稿，每页经你确认才保存 |
| `agent-mvp` | `/cc-code:agent-mvp` | 按定好的方案写码，写完自动测试，不过就改到过（最多 3 轮） |
| `agent-feature` | `/cc-code:agent-feature` | 只写新功能涉及的代码，只跑相关测试，又快又稳 |
| `agent-whole-qa` | `/cc-code:agent-whole-qa` | 上线前开浏览器把每个页面每个按钮全点一遍，FAIL 自动修 |
| `plan-debug` | `/cc-code:plan-debug` | 出 bug 后先由 QA 复现取证并当场记进 bugs.md，再由工程师只读查到根因，记录自动整理、不等你批准；只在需要你拍板时才停下问你 |
| `agent-debug` | `/cc-code:agent-debug` | 按修复方案改代码，跑相关测试全绿才算修好 |
| `experience-summary` | `/cc-code:experience-summary` | 手动补一条经验：你当场说的话原样交给 curator 静默归档（平时经验全自动整理） |
| `short` | `/cc-code:short` | 简单问题只回一句话（≤50 字），绝不啰嗦 |
| `just-do-it` | `/cc-code:just-do-it` | 小改动一句话就干：dev 写完 qa 验，记一笔就完事 |
| `deploy` | `/cc-code:deploy` | 按部署契约把各组件发上线，qa 线上验过才算数，出事一键回滚 |

### 工具外挂（干活的，与状态机无关）

| skill | 用途 |
| --- | --- |
| `project_resume` | 扫描代码库，替你写一段项目介绍文案 |
| `login_auto` | 一套现成方案装好登录注册：密码/谷歌/邮箱验证码+改密 |

---

## 四、使用方案：两条路线

### 路线 A：全新项目（0 → MVP）

```
/cc-code:init            ← ① 搭场域（1 分钟；前端项目可选 pen 原型）
/cc-code:plan-mvp    ← ② 先聊需求（pm）、再聊技术方案（architect），各批准一次，产出五件规划文档（最重要的投入）
/cc-code:plan-uiux   ← ②'（可选）前端原型：ux.md 页面清单 → design.pen 真图
                            可叠加风格：/cc-code:plan-uiux gpt-taste
/cc-code:agent-mvp    ← ③ 纯执行：Dev→QA 到收口（有 pen 则 Dev 走底稿三步）
/cc-code:agent-whole-qa        ← ④ 全量验收 + 修复闭环
```

### 路线 B：MVP 已交付，加新功能

```
/cc-code:plan-feature  ← ① 增量规划（冲突逐条裁决，落盘即定稿）
/cc-code:agent-feature  ← ② 增量纯执行：定位 → Dev→QA（精准回归）
```

### 路线 C：修 bug（需求明确，只是实现错了）

```
/cc-code:plan-debug        ← ① 诊断（qa 复现取证并当场写 B-n 到 active/bugs.md
                               → dev 只读查根因 → qa 补全；不等你批准，
                               只在契约错/需求错/找不到期望/复现不了时问你一句）
/cc-code:agent-debug      ← ② 修复纯执行：定位 B-n → Dev→QA
                               （B-n 用例 + affected 精准回归 + 回归测试留守）
```

**何时走哪条线（决策表）**：

| 你的情况 | 走 | 不走 |
| --- | --- | --- |
| 需求模糊，要新增/改动功能 | 路线 B（plan-feature） | debug 链（bug 不发明需求） |
| 行为错了，期望行为说得清（或有既有断言） | 路线 C（plan-debug） | 路线 B（别用 30 分钟需求仪式修 bug） |
| 修复需要改契约/改需求 | 先走路线 C 诊断；根因落在契约/需求上时会停下问你，你裁决后由架构/产品 agent 改文档，再修 | 别绕开诊断直接走路线 B |

### 任意时刻

```
/cc-code:experience-summary  ← 想当场补一条自动流程没抓到的经验 → 原样交给 curator（平时全自动，不用调用）
/cc-code:init                ← 插件升级后再跑一次，自动迁移场域（零删除）
```

---

## 五、使用示例

### 示例 1：第一次用，项目已有代码

```
你：/cc-code:init
AI：检测到旧项目（Track A）→ 备份旧 CLAUDE.md → 搭场域 → 请你补需求
你：/cc-code:plan-mvp 我要做一个「上传产品图自动生成小红书种草图」的工具
AI：（产品 agent 逐点提问：一套几张？要不要文案？……直到逻辑通顺 → 你批准需求 → 落盘 prd / ux）
AI：（架构 agent 逐点问技术方案 → 你批准 → 落盘 project / data / api）
```

### 示例 2：功能迭代

```
你：/cc-code:plan-feature 加一个「429 限流自动退避重试」
AI：产品 agent 先把需求问通 → 你批准；架构 agent 侦察现状 → 有冲突逐条请你裁决 → 你批准技术方案
AI：就地收敛落盘（prd.md 改写模块小节 + 断言进 §1.5 主表 / api.md 改写该 path 小节）
    过程不落盘　过期内容搬 backup/retired/　change-log 追加 1 行　status.md 点名 F-n
你：/cc-code:agent-feature
AI：增量定位 → Dev 实现 → QA 验收断言 A12.21~A12.24（affected 精准回归）
```

### 示例 3：修 bug

```
你：/cc-code:plan-debug 登录连点两次，第二次 401
AI：QA 复现取证、定位期望出处 → 当场写入 active/bugs.md 的 B-1 条目（状态：待诊断）
    → 工程师只读追链路定位根因 → QA 补上根因/爆炸半径/方案，状态改为待修复；主控把「现象 / 根因 / 爆炸半径 / 修法」四段用业务语言告诉你（只告知，不等批准）
    （纯代码层的 bug 不用你批准；只有根因在需求/契约上、找不到期望、复现不了时才问你）
你：/cc-code:agent-debug
AI：定位 B-1 → Dev 修 → QA 复验（B-1 用例 + affected 回归 + 留一个回归测试）
    → gates 记 ✅ → QA 把 B-1 原文搬进 backup/retired/bugs.md → milestone-log 一行
```

### 示例 4：踩坑沉淀（全自动，你什么都不用做）

```
你：/cc-code:agent-feature
AI：Dev 写 → QA 验：同一条断言连着两轮没过（QA 标「连续」，根因：实现缺陷）→ Dev 修好 → 全部通过
    （结算）主控后台派 curator，你不用管
    最终报告多一行：经验沉淀：新增 1 条（项目 1）
    → 下次任何架构设计涉及同类主题时，architect 会先看到它
你：（想当场补一条自动流程没抓到的）/cc-code:experience-summary 队列任务在 Redis 重启后会变僵尸，要有恢复机制
AI：原话原样交给 curator，它静默归档，只回一行结果
你：（团队有共享经验库）把 git 地址发给 AI 并说「这是团队经验」→ 克隆到 ~/.cc-code/team/，之后只读
```

---

## 六、references 经验库怎么用

经验由 **curator** 在每次执行器结算后后台静默整理，你零操作；它是所有经验库的唯一写者，qa 只在验收矩阵上做标记。

```
执行器结算 → 主控后台派 curator → 三道筛（连续/回归 → 实现缺陷或设计遗漏 → 证据齐）
          → 分级（项目 / 个人）→ 追加进主题文件 → 重建 INDEX → 最终报告多一行结果（无变化不写）
漏派 → 唯一的 Stop hook 只比时间戳，提醒主控补派
```

| 级别 | 位置 | 说明 |
| --- | --- | --- |
| 项目 | `.cc_code/references/` | 跟项目走；architect / dev 读 |
| 个人 | `~/.cc-code/lessons/` | 跟人走；curator 写，architect 读，经 architect 转写进 `project.md` §五 才影响开发 |
| 团队 | `~/.cc-code/team/<仓库名>/` | 只读；把 git 地址发给 AI 并说明是团队经验，由 curator 克隆 |

- **渐进式披露**：每级一个 `INDEX.md`（每个主题一行：主题、何时读、有效条数、休眠条目）+ 按主题的资料文件（如 `async-queue.md`）+ `archive/`。读的人先扫 INDEX，命中主题才打开，未命中一个都不读，零负担。
- **条目五字段**：背景、输入、输出、发生什么、约束；不写断言编号、数值、密钥、客户名、内部地址、代码。
- **只追加**：不覆盖不删除；7 个活跃日未被采纳 → 休眠（读者可跳过，被采纳即恢复）；14 个活跃日未被采纳或被报告「不适用」→ 归档到 `archive/`，原文保留。
- **谁读**：architect（规划阶段首次派出时）读三处 INDEX；dev 读项目 INDEX；qa / pm / uiux 不读。完成报告里的「采纳经验」一行就是采纳记录。
- **优先级**：active 文件 ＞ 项目 ＞ 个人 ＞ 团队；经验只当自检问题，不当验收尺子。
- **新增入口**：平时不用管；想当场补一条走 `/cc-code:experience-summary`，原话原样交给 curator。

---

## 七、常见疑问

| 疑问 | 答案 |
| --- | --- |
| 我要手动切角色吗？ | 不用。角色就是被派出的 agent，命令会按顺序派；`Agent.md` 里没有「当前角色」字段 |
| AI 会自己乱改需求吗？ | 权限卡片禁止：dev / qa 禁改 prd/ux；改不动就上报，由主控交你裁决 |
| 我能直接改 `Agent.md` / `CLAUDE.md` 吗？ | 不用也不建议：它们是插件规范文件，只有 init 脚本写，升级时会整份覆盖（旧版有快照）。项目自己的约定写进 `project.md` 的「特殊约束」，由 architect 写 |
| 旧版场域升级会丢东西吗？ | 不会。全程零删除，旧物只 cp 快照与 mv 归位，永远可回溯 |
| 验收标准在哪？ | `prd.md` §1.5 断言 A1..An（编号永久稳定、永不复用；作废条目搬进 `backup/retired/prd.md`，active 里不留） |
| 实测结果在哪？ | `gates.md`（QA 写，Dev 禁读 —— 防拿答案做题） |

---

> 更多细节：`active/Agent.md`（宪法）+ 插件 README。
