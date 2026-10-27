# cc-code

> Version: **1.12.1** ｜ [English](./README.en.md) ｜ 简体中文

> 极简开发工作流系统 —— 把 LLM 装进「认知沙盒」，让它成为精确、稳定、可溯源的自动化软件工业母机。
> 宪法原则：**只对结果负责，不在乎过程**（结果是否符合需求是唯一尺子）。
> 基于四大铁律：**上下文最小化 · 决策串行 · 记忆外部化 · active 三判据**。

---

## 目录

- [设计哲学](#设计哲学)
- [核心逻辑](#核心逻辑)
- [编排方式（1.8.0）](#编排方式180角色--agent主控只传话)
- [就地更新 + 搬运归档（1.7.0）](#就地更新--搬运归档170)
- [前端与视觉（1.11.0）](#前端与视觉110)
- [安装](#安装)
- [完整生命周期](#完整生命周期)
- [快速开始](#快速开始)
- [Codex CLI 适配（1.1.0）](#codex-cli-适配110)
- [可选增强：codegraph](#可选增强codegraph)
- [Skill 一览（17 个）](#skill-一览17-个)
- [Agent（6 个）](#agent6-个)
- [文件分层（L0~L4）](#文件分层l0l4)
- [目录架构](#目录架构)
- [角色串行](#角色串行)
- [经验沉淀（1.10.0 全自动）](#经验沉淀全自动)
- [唯一的 Stop hook](#唯一的-stop-hook)
- [散落物迁移](#散落物迁移)
- [新手入门](#新手入门)
- [License](#license)

---

## 设计哲学

LLM 写代码有三病：**写着写着忘了目标、上下文越滚越脏、凭记忆瞎答**。
cc-code 的处方：**把记忆、状态、规则全部外部寄存到 `.cc_code/` 静态文件**，AI 每次会话按协议读文件定位自己，而不是靠脑容量。

```
① 记忆/逻辑/状态全外部寄存 ── 不交给 agent，落 .cc_code/ 静态文件
② 责任垂直化 ── 每角色只掌一层，上下文干净，禁止越权
③ active 三判据 ── 最新 + 最完整 + 最纯净（硬铁律）
④ 规则单一出处 ── 一条规则只写在「受众必经之路」上一次，⛔禁复述
                   （副本是漂移的必要条件；提示词库无测试无 CI，漂移不报错）
⑤ 防 vibecoding 三病：
   逻辑偏离 → 信息流单向 + codegraph 不生成意图层
   冗余堆积 → 就地收敛写入 + agent-whole-qa 冗余检测
   自傲跳过 → 多角色 + 测修独立上下文
```

规则该落哪一层由三问定位（换角色还成立→全员区／角色专属→角色卡／subagent 需要→其系统提示词／产物格式→模板头部），判据表见 [`docs/ARCHITECTURE.md`](./docs/ARCHITECTURE.md#规则归属单一出处ssot分层--0131-立规)。

## 核心逻辑

### 角色串行（pm → uiux → architect → dev → qa）

```
pm ──► uiux ──► architect ──► dev ──► qa
(逻辑)  (交互+长相)  (契约)      (编码)   (验收)
```

各角色「必读 / 可写 / 禁读」权限只写在 `templates/Agent.md` §三（单一出处，此处不抄副本）。
uiux 只在规划侧出场（`plan-mvp` / `plan-feature` / `plan-uiux`），写 `ux.md`（交互与布局）与 `design.md`（风格与长相）两份；⛔ 不写项目代码、⛔ 不出现在任何 `agent-*` 命令里。风格落地由 dev 执行，改版落地由 `agent-uiux` 执行。

### 编排方式（1.8.0）：角色 = agent，主控只传话

```
 主人 ◄──────────────► 主控（编排者：不扮演任何角色、不读代码、不替主人回答）
                         │  只写 status.md（坐标/卡点/下一步 + 「风格：」行）+ backup/milestone-log.md 追加行
                         │
   规划（plan-mvp / plan-feature）        严格 pm → uiux → architect
     ① 派 pm（全新上下文）─ 一次一个问题 ◄──► 主人原话原样续接同一个 pm
            ├─ 推断端与形态、默认技术栈与组件库家族 → 写进需求摘要（不发问卷，「我替你选了…想改就说」）
            └─ 主人批准【需求与原型】→ pm 落盘 prd；uiux 落盘 ux.md（页面清单 / ASCII 原型 / testid / 五态 / 断点 / 流转）
     ② 派 architect（全新上下文）─ 逐点问技术 ◄──► 主人
            ├─ 发现需求冲突 → 业务语言转述 → 主人裁决 → pm / uiux 交修订摘要（plan 模式不写盘）→ 回 architect
            └─ 主人批准【技术批准】→ architect 落盘 project / data / api / §九
   定风格（plan-uiux，有前端）
     派 uiux ─ 方向卡（营销/品牌类且主人没给方向时才给）→ design.md 草稿 → 风格样板板
            └─ 主人说「定了」（唯一视觉门）→ design.md 锁定 → 进 agent-mvp 的视觉地基
   执行（agent-*）
     派 dev 写 ─► 派 qa 验（逻辑三层 + 视觉第四层）─► FAIL ≤3 轮 ─► 仍 FAIL：交人决策
   改版（plan-uiux 模式二 ─► agent-uiux）
     qa 现状体检 ─► uiux 目标 design.md ─► 改前改后对照样板板 ─►「定了」─► agent-uiux 落地
   debug（不进 plan 模式，bugs.md 自动整理，不等批准）
     qa 复现取证，复现成功当场写 B-n（待诊断）─► dev 只读诊断（不改码）─► 主控转 qa 补根因/爆炸半径/方案，再把四段（现象/根因/爆炸半径/修法）用业务语言告知主人
     ├─ 纯实现层 ─► 待修复 ─► dev 修 ─► qa 复测 ─► PASS 则 qa 把条目搬 backup/retired/bugs.md
     └─ 契约错 / 需求错 / 视觉规格错 / 找不到期望出处 / 复现不了 ─► 待裁决：问主人一句话 ─► 裁决后 architect / pm / uiux 改文档（或 qa 重新复现）─► 待修复
```

| agent | 模型档位 |
| --- | --- |
| `pm` | opus |
| `architect` | opus |
| `dev` | inherit（继承主会话） |
| `qa` | sonnet |
| `uiux` | opus |
| `curator` | sonnet |

谁写哪个文件见 `templates/Agent.md` §二 / §三，此处不抄副本。

除 curator 外，所有 agent 开 `memory: project`（记忆存在生成项目的 `.claude/agent-memory/<agent>/`，只记本角色经验）；项目约定永远从 `.cc_code/active/*` 读，不从记忆读。Codex 端本版只保证生成链不坏（inherit 档继承父会话，不写 model 行；uiux 的 opus 档映射 gpt-5.4 + effort high）。

**主人参与点（全流程只有这几处）**：

| 时刻 | 你要做什么 | 不参与什么 |
| :--- | :--- | :--- |
| **需求与原型批准**（plan-mvp / plan-feature） | 看 pm 的需求摘要（端/形态/默认栈/家族）+ uiux 的页面原型，一次批准 | 技术细节、视觉数值 |
| **技术批准**（plan-mvp / plan-feature） | 看 architect 的技术方案，一次批准 | 页面长相 |
| **风格「定了」**（plan-uiux，唯一视觉门） | 看风格样板板，说「定了」才锁定；同方向最多 3 轮 | 代码实现 |
| **方向卡**（有条件） | 仅营销 / 品牌类且你没给方向时，从推荐 1 + 对照 2 里挑；不说话就用推荐 | 具体色值 |
| **合集板**（收口与加新页后，不卡流程） | 看 qa 汇总的「只能人看」的审美问题（VS），可选择性提意见 | 阻断发布（VS 不阻断） |

### 并行泳道（1.6.0）：角色串行 ≠ 单线程

串行锁的是**角色顺序**和**派活顺序**，不是「同一角色只能派一个人」（编排方式见下节）。规划时把一个阶段拆成互不相干的泳道，执行时同一角色多人同时干：

```
 规划（架构师）：拆阶段 → 拆泳道 → 给每条泳道划「只准写哪些文件」
                 几条泳道都要改的文件 → 单列「地基」泳道，排最前
        ▼
 执行（主控）：  地基（单线程）
                   ▼
                 Dev 甲 ┃ Dev 乙 ┃ Dev 丙     同时写
                 ━━━━━━ 栅栏：全部写完 ━━━━━━
                 QA 甲  ┃ QA 乙  ┃ QA 丙      同时验，只回报告
                 ━━━━━━ 栅栏：全部验完 ━━━━━━
                   ├─ 没过的泳道 → 只退回这几条（各自 ≤3 轮）
                   └─ 全过 → 汇合回归（合并影响面 + 端到端）→ 阶段结算
```

| 不变的 | 怎么守住 |
| --- | --- |
| Dev → QA 角色顺序 | 两道栅栏之间全员同一角色 |
| 执行器不规划 | 泳道只来自 `project.md` §九，不合规就退回单线程 |
| 每个文件一个写者 | 泳道内子 agent 只回报告；落盘写者按 `parallel-lanes.md` |
| 一次只派一张卡 | 并行只发生在一个阶段 / 一个增量内部 |

没写泳道的老项目自动单线程，零影响。细则：`skills/cc-code/references/parallel-lanes.md`。

#### 全命令并行对照

| 命令 | 会并行吗 | 并行单位 | 谁在并行 | 触发条件 | 同时最多 |
| --- | --- | --- | --- | --- | --- |
| `plan-*` | ❌ | — | — | 一问一答，人全程在场 | 1 |
| `agent-mvp` | ⚠️ 有条件 | 泳道 | 多个 dev，或 多个 qa（分两批） | `project.md` §九 本阶段 ≥2 条泳道且体检通过 | 3（缺省） |
| `agent-feature` | ⚠️ 有条件 | 泳道 | 多个 dev / 多个 qa | §九 9.2 本 F 号 ≥2 条泳道 | 3（缺省） |
| `agent-uiux` | ⚠️ 有条件 | 泳道 | 多个 dev / 多个 qa | §九 本次改版范围 ≥2 条泳道；运行时视觉检查只在汇合回归 | 3（缺省） |
| `agent-debug` | ❌ | — | — | 一条 bug 一条线，拆开丢根因 | 1 |
| `agent-whole-qa` | ✅ 默认 | 功能模块 fan-out | 多个 qa；修复轮多个 dev | 清点完成即开；Claude Code 端走 Workflow，工具不可用则回退 Agent 多开 | 模块数 / 修复组 ≤3 |
| `just-do-it` | ❌ | — | — | 改动太小，开泳道不划算 | 1 |
| `deploy` | ❌ | — | — | 单命令串行 | 1 |
| `pr` | ❌ | — | — | 单命令串行 | 1 |

**绝不并行的三件事**：dev 与 qa（两道栅栏隔开）、两个阶段、同一份账本的两个写者。

### 文件分层（先认层，再认角色）

```
┌ L0 控制 ─ Agent.md(宪法/权限)  status.md(坐标+卡点+下一步+风格) ─ 人/AI ┐
├ L1 意图 ─ prd.md(分模块逻辑+规则+断言 A1..An+需求摘要) ──────── PM ───┤
├ L2 表现 ─ ux.md(交互与布局+五态矩阵, U 编号发号处) ─────────── uiux ──┤
│           design.md(设计规格: 色彩/字体/间距/形状/动效/各端映射) ─ uiux ┤
├ L3 实现 ─ project.md  data.md  api.md ─────────────────── Architect ┤
├ L4 验收 ─ gates.md(A+U+V 追溯矩阵, 标准在 prd/ux/design) ───── QA ───┤
└ backup/ ─ 冷归档：流水表 + retired/ 退役原文（默认不入库）────────────┘
```

### 信息流铁律（单向，违反即失效）

```
   L1 意图 ──► L2 表现（ux 交互布局 + design 设计规格）──► L3 实现 ──► 代码
    ▲                                                                │
    └──────────────── L4 验收（A + U + V）◄──────────────────────────┘

  ① L4 只拿 L1/L2 当尺子（L2 含设计规格），绝不拿 L3/代码当尺子
     否则 QA 退化为「拿代码验代码」，验收彻底失效
  ② codegraph 只准校准 L3（事实层），永不生成 L1/L2/L4
  ③ Dev/QA 禁改 prd/ux/design/api 让测试通过
  ④ 标准与结果永不同文件：标准在 L1/L2（pm 写 prd、uiux 写 ux / design），结果在 L4（qa 写）
     写标准的人 ≠ 判结果的人 → 制衡成立
  ⑤ V 刻度的来源 = design.md 数值 × ui-gates 规则；V 编号发号处 = gates.md §2.4 V 段
```

### active 三判据

`active/` 是唯一真相源，必须**永远**保持最新、最完整、最纯净：

```
   最新   ── 同一对象在 active 只有一处描述, 且是当前态
             ⛔ 禁新开「## 增量 F-n」章节 → 就地改写对应小节

   最完整 ── 每个待验维度都有永久稳定编号, 分母算得出
             A 编号 (prd.md §1.5 主表) = 业务逻辑 / 链路 / 接口
             U 编号 (ux.md  §2.3 矩阵) = UI 布局 / 交互五态
             V 编号 (gates.md §2.4 V 段) = 视觉（design.md 数值 × ui-gates 规则；页章号 + 组码）

   最纯净 ── 每一行都在答「现在是什么」, 不是「当时怎么决定的」
             过程产物不落盘（change-log 留痕） ·  逐轮验收详情 → docs/qa/
             过期内容 → backup/retired/<源文件名>.md（原文整段搬走, 一字不丢）
```

**1.12.0：** 新增 `/cc-code:pr`——把已验收的改动交给外部审查平台：规范 commit → 推送功能分支 → 带描述建合并请求（改了什么 / 怎么测的 / 出事怎么撤 / 关联规格 / 影响面，高风险加决策日志），然后停手。qa 新增「提交证据」：重跑本次断言的命令，原始输出与截图写成证据文件，主控原样拼进描述、不改一字。主控的唯一显式例外改为「版本库操作」，交付只限 pr 命令内、不碰主干。被打回或线上 bug 照常走 debug / feature 链。入口说明 `CLAUDE.md` 压到 100 行以内。skill 16 → 17，agent 6 不变。

**1.12.1：** 定风格提速。对比度提前到写数值时就算（设计规格新增「文字与底色配对表」，不达标直接改色值，不用等页面渲染出来再返工）；uiux 锁前自检规定检查顺序（先修溢出、再量其余、最后可访问性复核），修复轮只复查没过的项，截图只在终检拍一次；修复轮最多 3 轮，超了交回卡点和推荐解法问主人，绝不带瑕疵锁定。

**1.11.0：** 前端 UI/UX 全链路上线——十种前端形态由 pm 从产品雏形推断（不发问卷），默认 React + Next.js + shadcn 家族；一个项目只用一个组件库家族、全项目一份 `active/design.md`（L2 视觉半边，uiux 写），数值灌进各端主题。新增 `plan-uiux`（模式一 定风格 / 模式二 改版，唯一视觉门「定了」）与 `agent-uiux`（把「已定未实现」落进代码），uiux 改为 opus 且只在规划侧出场；qa 新增**视觉第四层**（VH/VM/VS 三级判词、截图基线、主题漂移、合集板），`agent-mvp` 首阶段固定为**视觉地基**。pen 主链降级为方向卡可选介质（旧 `design.pen` 原地保留、不读不写不转换）。skill 15 → 16，agent 6 不变，模板骨架 9 → 10。

**1.10.1：** 删除 `/cc-code:experience-summary`：经验只由 curator 从验收里真实发生过的错自动整理，不再有手动入口（手动整理会跳过三道筛、写进未经验证的经验，也违背零人工）。skill 16 → 15。

**1.10.0：** 经验沉淀交给新增的 **curator** agent，全自动、静默，主人零操作、零确认、零裁决，最终报告只多一行结果（无变化不写）。
- 执行器（agent-mvp / agent-feature / agent-debug / just-do-it）每次结算后，主控后台派 curator；qa 只在验收矩阵上标「连续 / 回归」与根因类别，curator 过三道筛后按级别分库，architect / dev 按渐进式披露读 INDEX 并在完成报告里写「采纳经验」一行。
- 经验库三级同构：项目 `.cc_code/references/`、个人 `~/.cc-code/lessons/`、团队 `~/.cc-code/team/<仓库名>/`（只读）；只追加不覆盖，7 个活跃日未采纳休眠、14 个归档。
- 新增唯一的 **Stop hook** 做保底（只比时间戳，不调 AI、不联网），漏派 curator 时提醒主会话补派；agent 5 → 6。
- `init` 一次配好：建经验库骨架，并幂等合并 `.claude/settings.local.json` 权限，写个人库、拉团队库不弹确认。
- codex 暂不适配（生成链照常、校验不破）；agent-whole-qa 本次不接入。

**1.9.3：** 升级与迁移也严守单一写者——`init` 按文件派 pm / architect / qa 回填，主控只分拣、只派、不写；`Agent.md` / `CLAUDE.md` 由 init 脚本按插件模板覆盖；pm 不读 milestone-log。

**1.9.2：** 修 1.9.1 的落地缺口——主控 `allowed-tools` 不含浏览器工具，生命周期改为「首个 qa 开（owner）/ 收口 qa 关（closer）」；qa 协议与 Workflow 脚本补上 owner / closer、失联只上报不自建、产物显式落盘；PREFLIGHT 自动识别唯一浏览器工具，`Workflow` 纳入工具白名单；`project.md` §六 增加「QA 数据隔离」契约。

**1.9.1：** 浏览器验收改为**单实例复用**——全流程只起一个浏览器，所有 qa 照常并发测，各自建 tab 并在每次操作前切回自己的 tab；⛔ 不新开实例、⛔ 不关闭整个浏览器。`project.md` §六 新增「浏览器工具 / 实例 / 产物目录」三行契约；qa agent、清点流程与 Workflow 脚本同步该协议。

**1.9.0：** `agent-whole-qa` 接入 Workflow 编排——清点 → 按模块 fan-out → 汇总 → 修复回环（≤3 轮），工具不可用时自动回退 Agent 多开；三个执行命令的描述补上并行边界；泳道并发报告改固定骨架，单线程时明示「本阶段单线程（无泳道）」；README 增加全命令并行对照表。

**1.8.2：** 宪法原则写入生成项目 `CLAUDE.md` 首节——只对结果负责、不在乎过程：尺子是结果对照需求，落盘只存结论，对主人只讲结果和影响，人只在结果对不上需求或需求要改时介入。

**1.8.1：** bug 诊断给主人的「三件套」改为「四段告知」——现象 / 根因 / 爆炸半径 / 修法，全部业务语言，只告知不落盘；B-n 的「影响面」字段改名「爆炸半径」（业务语言写影响的功能 / 页面 + 回归测试面，文件清单作为技术备注保留）。

### 就地更新 + 搬运归档（1.7.0）

`active/` 只放项目**最新的状态和内容**。写之前先按下图处置，角色只动自己负责的文件：

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
其余不动     小节, 不堆末尾  backup/retired/    (省 token,
                            再从 active 移除     不惊动缓存)
    │            │              │                │
    └────────────┴──────┬───────┴────────────────┘
                        ▼
      backup/change-log.md 追加 1 行（详情列写 retired 路径）
```

| ⛔ 禁止 | 为什么 |
| --- | --- |
| 整份重写文件 | 没变的行被重写 = 白烧 token + 缓存失效 |
| 往文件末尾追加新内容/新章节 | 同一对象散成 N 段，读者得脑内拼接 |
| 在 active 留历史（旧轮次 / 已修 / 已作废 / 删除线尸体） | active 一胖，每次会话都得整份读进来 |
| 直接删除过期内容 | 内容一个字都不许丢 —— 先搬 `backup/retired/`，再从 active 移除 |

> 效果：active 行数由「现在有多少规则」决定，**不由「用了多少次」决定**。
> `backup/` 不进 git，不怕大；旧内容在 `retired/` 全文可查。

## 前端与视觉（1.11.0）

> 目标：生成项目的前端**剔除 AI 味、有格调、视觉对齐**（元素在栅格、边缘、基线、间距上对整齐）。
> 规则唯一出处：判词 / 规则号 / 阈值 = `skills/cc-code/references/ui-gates.md`；形态 / 默认栈 / 家族 / 三旋钮 / 翻译表 = `skills/cc-code/references/frontend-forms.md`；循环协议 = `skills/cc-code/references/dev-qa-loop.md`。

### 五段链路

```
pm ──► uiux ──► architect ──► dev ──► qa
(推断端与形态) (ux.md + design.md) (家族/视觉基建契约) (生成主题/实现页面) (视觉第四层)
   │             │                      │                      │                    │
 §〇 需求摘要   L2 双文件            project.md §一.1/§六/§九    主题文件=生成物       V 段 + 基线 + 合集板
              （只在规划侧）          （不读 design.md）        （禁手改）           （唯一写判词的人）
```

| 角色 | 只做什么 | 绝不做什么 |
| :--- | :--- | :--- |
| pm | 从产品雏形推断有哪几端、每端什么形态，把默认技术栈与家族写进 `prd.md` §〇 | 发问卷、写视觉数值、读 `ux.md` / `design.md` |
| uiux | 写 `ux.md`（布局与交互）与 `design.md`（风格与长相），`plan-uiux` 里出方向卡与样板板 | 写项目代码、出现在任何 `agent-*` 里、碰 `status.md` / `gates.md` |
| architect | 写 `project.md` §一.1 家族 / §六 视觉基建 / §九 视觉地基阶段 | 读 `design.md`（视觉数值不归它） |
| dev | 按 `design.md` **生成**各端主题文件、实现页面、搭视觉地基 | 手改主题生成物、在主题入口外写死色值、混第二家族 |
| qa | 视觉第四层：写 V 段、视觉测试、截图基线（独占）、合集板 | 改 `design.md` 让测试过、把 VS 当阻断 |

### 十种形态 · 默认栈 · 单家族

| 项 | 口径 |
| :--- | :--- |
| 十种形态 | 营销落地页 / SaaS 或 Web App 生产力工具 / B 端中后台 / 内容与文档门户 / 跨平台原生 App / 移动 H5 营销微站 / 混合 App / 跨端编译小程序 / 原生小程序 / 无前端 |
| 第一版范围 | 网页四种 + 移动 H5（混合 App 按 H5）；原生 App 不承诺（视觉段标「无法判定」）；小程序只留驱动工具契约位，规则包推迟 |
| 默认技术栈 | React + Next.js（主人没要求就不问）；文档类默认 Next.js 文档框架；纯内部重型后台只求快可改 Ant Design |
| 一个家族 | 全项目只用一个组件库家族（默认 shadcn 家族），各端用家族对应版本；没有家族能覆盖全部端 → pm 在 §〇 说明后果请主人定，⛔ 不自行拼第二个家族 |
| 一份设计规格 | `active/design.md` 是全项目唯一视觉事实源；各端差异只写 §九 主题映射，数值灌进各端主题入口；dev 生成的主题文件是生成物，⛔ 禁手改 |
| 判据一句话 | 换一套皮肤仍然成立 → `ux.md`；换皮肤就会变 → `design.md` |

### 两个模式 · 视觉三级门（开工 / 定了 / 基线）

```
 plan-uiux（人参与）                                agent-uiux（纯机器）
 ─────────────────                                ────────────────
 模式一 定风格（新项目）                            只接「风格：已定未实现」
   方向卡（有条件）→ design.md 草稿 → 风格样板板      dev 重生成主题 + 调长相与布局
   → 自检 → 主人「定了」→ 已锁定 → agent-mvp         qa 全量五态回归 + 全页视觉 + 基线对比
 模式二 改版（已上线界面）                          ≤3 轮；PASS → 冻结新基线 → 合集板
   qa 现状体检 → uiux 目标 design.md → 改前改后对照
   →「定了」→ 改版待实现 → agent-uiux
```

| 门 | 内容 |
| :--- | :--- |
| ① 开工视觉门（按阶段） | 本阶段涉及页面且 `design.md` 未锁 → 执行器**拒跑**并指路 `plan-uiux`；纯后端 / 无 UI 阶段放行并标「不适用」；老项目冷启动**只豁免一次** |
| ② 唯一视觉门 | 主人亲口说「定了」，`design.md` 才锁定；同方向最多 3 轮，换方向重计 3 轮，再不定停下交人 |
| ③ 基线门 | qa PASS 后冻结截图基线；**失败轮禁止冻结**；范围内差异 → 生成新候选（标主人未目视），范围外 → 判回归 |

**三个检查时机**（名称固定）：现状体检（qa，模式二）／锁定前（uiux 自检；视觉地基 qa 复核）／开发后（qa，各执行命令）。真正的视觉判词从「锁定前 · 复核」开始。

### 视觉第四层：qa 怎么判

| 判词 | 前缀 | 阻断 | 进分母 | 去向 |
| :--- | :--- | :--- | :--- | :--- |
| 阻断 | `VH` | 是 | 是 | `gates.md` §2.4 V 段 → Critical Failures → 回 dev（≤3 轮） |
| 次要 | `VM` | 否 | 是（随组行） | 行内 + Minor Failures |
| 人判 | `VS` | 否 | 否 | **合集板**（`.cc_code/docs/qa/`），主人看 |

- **机器检查写成测试运行器测试**（Playwright），提交进 `.cc_code/test/visual/`；Playwright 浏览器工具只做探索取证；性能只走 Lighthouse 命令行。
- **视觉模型只给证据，不给判词**：输出只能进 VS 线索与合集板，⛔ 不阻断。
- 九个组码：01 设计数值（锁前）／02 依赖与源码／03 颜色与主题一致／04 字体与排版／05 布局与构图／06 视觉对齐／07 文本与内容／08 动效／09 响应式与可访问性与性能与基线。

### 视觉地基 · 基线归属 · 合集板 · 双屏宽冒烟

| 事项 | 口径 |
| :--- | :--- |
| 视觉地基 | `project.md` §九 **首个阶段固定**：主题入口 + 全局框架 + 组件陈列页（项目里**不上线**的路由）；业务页面排在它之后，主题未过视觉门不开工 |
| 基线归属 | 截图基线 `.cc_code/test/visual/baseline/` 与允许值集合：**qa 独占写、入 git**；只比组件陈列页与样板页（数据固定），按「浏览器 + 系统」分文件 |
| 合集板 | qa 产出、主人看、**不卡流程**；收口与加新页后给一次 |
| 双屏宽冒烟 | `deploy` 上线后 qa 在 **390 / 1440** 各截首页 + 一页主流程，并在同页同屏宽采样性能；只作证据，不新增阈值 |
| 目录归属 | `.cc_code/design/`（uiux 写：方向卡、样板板与截图）／`.cc_code/test/visual/`（qa 写：视觉测试）／`.cc_code/test/visual/baseline/`（qa 独占：基线）／`.cc_code/docs/qa/`（qa 写：逐轮报告与合集板） |
| 忽略口径 | 只忽略临时产物（`docs/qa/artifacts/`、`coverage/`、`test-results/`）；⛔ 绝不用 `*.png` / `screenshots/` 全局通配 ignore 截图，⛔ 设计目录与基线必须入库 |

### 其它命令的视觉边界

| 命令 | 视觉上做什么 |
| :--- | :--- |
| `agent-mvp` / `agent-feature` | 开工按阶段判视觉门；dev 只引用主题、只用一个家族；qa 开发后查本次受影响页面 × 视口 × 亮暗 × 五态 |
| `agent-uiux` | 风格改版专用：dev 重生成主题、调长相与布局；qa 全量五态回归 + 全部页面视觉 + 基线对比；碰流转 / 五态 / 接口就停下交人 |
| `agent-whole-qa` | 全部页面 × 屏宽 × 亮暗；视觉组合子行只记覆盖，不乘进 V 主行；合集板不卡流程 |
| `agent-debug` | 视觉 bug 同链；修复通过的硬条件 = 回归测试存在且通过 |
| `just-do-it` | 命中前端文件只做 `ui-gates` 组的**静态扫描**：只记录、不出判词、不阻断、不进分母 |
| `deploy` | 首页 + 一页主流程 × 390 / 1440 截图与性能采样（同 §双屏宽冒烟） |
| `login_auto` | 登录页颜色 / 字号 / 间距 / 圆角 / 阴影只取项目主题与已选家族 |

---

## 安装

```bash
# 1. 添加本仓库为 marketplace
/plugin marketplace add https://github.com/weiyi88/cc-code

# 2. 安装 cc-code 插件
/plugin install cc-code
```

安装后自动获得 `/cc-code:*` 命令族、17 个 skill、6 个配套 agent 与 1 个 Stop hook。

## 完整生命周期

```
/cc-code:init          搭场域（9 个规范骨架 + bugs.md debug 便签 + 迁移散落物 + 盖版本戳
                       + 设计目录与截图基线目录 + 刷新 .cc_code/README.md 使用手册）
                       旧版场域自动走升级迁移（零删除）
       ↓
会话开启(2步)          Read Agent.md(读权限表) → status.md(定坐标 + 「风格：」行)
       ↓
/cc-code:plan-mvp  ⭐第一动作 call EnterPlanMode → plan 内探测+三件套
                       pm 推断端与形态、默认栈与家族（不发问卷）
                       → uiux 写页面原型 →【批准一：需求与原型】
                       → architect 问技术方案 →【批准二：技术方案】
                       → 落盘五件（prd/ux/project/data/api；design.md 留给 plan-uiux）
       ↓
/cc-code:plan-uiux   （有前端必走）模式一 定风格：方向卡（有条件）→ design.md 草稿
                       → 风格样板板 → 你说「定了」（唯一视觉门）→ 锁定
       ↓
/cc-code:agent-mvp  纯执行（读定稿文档，Dev→QA，FAIL≤3轮回环，中途零确认；
                       阶段内有泳道则同角色多人并发，运行时视觉检查只在汇合回归；
                       首阶段视觉地基：主题 + 全局框架 + 组件陈列页，之后页面只引用主题）
       ↓
/cc-code:agent-whole-qa      全量验收（断言 + 五态 + 元素 + 接口 + 视觉第四层，FAIL≤3轮回环；
                       修复按文件分组并发；合集板不卡流程）
       ↓
/cc-code:pr         交付审查平台（规范 commit → 推送功能分支 → 带描述建合并请求，提交后停手；
                       走外部平台流水线的项目用它，平台负责审查与合并）
       ↓
/cc-code:deploy     上线（读 project.md 部署契约，任意平台组合；qa 线上冒烟含
                       390 / 1440 截图与性能采样，出事 /cc-code:deploy rollback 一键回退）

────────── MVP 交付后，功能迭代走这条支线 ──────────

/cc-code:plan-feature  ⭐第一动作 call EnterPlanMode → 规范体检+锁基线
                           +codegraph 算爆炸半径 → 冲突逐条硬门控裁决
                           +新页版式两档（只用已锁数值免门但登记 / 引入新数值回 plan-uiux）
                           +就地收敛落盘（落盘即定稿）
                           +status.md 点名 F-n 与新断言号
       ↓
/cc-code:agent-feature  增量纯执行（增量定位 → Dev→QA，affected 精准回归；有泳道则并发）

────────── 已上线界面要改长相（需求不变）走这条支线 ──────────

/cc-code:plan-uiux     模式二 改版：qa 现状体检（截图 + 机检）→ uiux 写目标 design.md
                       → 改前改后对照样板板 → 你说「定了」→ status「已定未实现」
       ↓
/cc-code:agent-uiux    落地：dev 重生成主题 + 调长相与布局；qa 全量五态回归 + 全部页面视觉
                       + 基线对比（≤3 轮）；碰流转/五态/接口就停下交人

────────── 任意时刻修 bug 走这条支线（需求明确但实现错了）──────────

/cc-code:plan-debug          不进 plan 模式 → qa 问诊复现，复现成功当场写 B-n 到 active/bugs.md（待诊断）
                             → dev 只读查脉络（链路/半径/测试面）→ qa 补根因/爆炸半径/方案（待修复）→ 主控用四段业务语言告知你（只告知，不等批准）
                             记录不等批准；只在契约错/需求错/视觉规格错/找不到期望出处/复现不了时
                             标「待裁决」问你一句（施工便签，修完原文搬 backup/retired/bugs.md）
       ↓
/cc-code:agent-debug        bug 修复纯执行（只接待修复的 B-n → Dev→QA，affected 精准回归
                             + 回归测试留守，无全量清算；视觉 bug 同链）

────────── 任意时刻 ──────────

/cc-code:init                插件升级后再跑一次：场域迁移 + 手册刷新到最新
```

**主线是 8 个 skill 四对配对串起来**：plan-mvp ⇄ agent-mvp、plan-feature ⇄ agent-feature、plan-uiux ⇄ agent-uiux、plan-debug ⇄ agent-debug —— 规划（商讨落盘定稿）→ 执行（纯机器推进）→ 全量验收。`plan-uiux` 模式一定完风格接 `agent-mvp` 的视觉地基，模式二改版接 `agent-uiux`。
`cc-code` skill 在背后管运行时协议（角色路由 + 分层），`init` 是入场。仅一个 Stop hook 做经验整理保底，其余状态由 AI 顺手写。

## 快速开始

在任意项目根目录：

```
/cc-code:init
```

- **新项目**：直接搭场域 + 盖版本戳，切 PM 等需求。
- **旧项目（无 `.cc_code/`）**：备份旧 `CLAUDE.md` → `.cc_code/backup/YYYY-MM/CLAUDE.md.legacy`，主控只分拣，按文件派 pm / uiux / architect / qa 按映射表分拆回填 `active/` 各文件（`prd`→pm、`ux`/`design`→uiux、`project/data/api`→architect、`gates/bugs`→qa），`Agent.md` 与根目录 `CLAUDE.md` 由 init 脚本按插件模板覆盖。
- **前端项目**：`init` 建好 `.cc_code/design/`（方向卡与样板板）与 `.cc_code/test/visual/baseline/`（截图基线）两个目录，两者都入 git；升级轨会做一次机械前端探测，无前端时 `design.md` 只建骨架并标「不适用（无前端）」，不派 uiux。
- **旧版场域（已有 `.cc_code/` 但版本戳缺失或更旧）**：自动走升级迁移 —— **归档 → 清点 → 迁移 → 校验 → 归位 → 盖戳**，`init.sh` 中 `rm` 出现 0 次，旧物只 `cp` 快照与 `mv` 归位，内容永远可回溯。校验门未过则停手，戳不盖，下次 `init` 仍判为待升级。

> 根目录 `CLAUDE.md` 是纯入口引导（会话开启协议 + 三铁律 + 文件索引），不含业务状态。Claude Code 原生自动加载它，从而被引导进 `.cc_code/` 状态机。

## Codex CLI 适配（1.1.0）

同一仓库双端分发：`skills/`、`agents/`、`CLAUDE.md` 是**唯一源**（Claude Code 直接吃），Codex 侧全部是**生成物**（`scripts/sync-codex.sh` 产出，禁手改；`scripts/verify-codex.sh` 负责漂移报警）。

### 安装（Codex CLI ≥ 0.149.0）

```bash
codex plugin marketplace add weiyi88/cc-code
codex plugin add cc-code@cc-code-marketplace
```

项目侧（场域初始化后跑一次，分发护栏）：

```bash
bash "$CLAUDE_PLUGIN_ROOT/scripts/init.sh" --codex   # 或指向本仓库 scripts/init.sh
```

`--codex` 做三件事：`AGENTS.md → CLAUDE.md` 软链（宪法双端同源）、`.codex/hooks.json + gate.sh`（plan 写盘拦截）、`.codex/agents/*.toml`（六角色沙箱；源已删除的旧角色 toml 会被清掉）。**首次运行 codex 会要求在 `/hooks` 里审查信任 gate.sh —— trust 一次即生效。**

### Codex 侧的 plan 笼子

用户永远只敲一条命令（如 `$cc-code:plan-mvp 做一个番茄钟网页`）——开锁由 AI 自查引擎完成，零额外操作：

```
$cc-code:plan-mvp 触发
   └─ AI 第一动作自查: 有 EnterPlanMode 工具?
       ├─ Claude Code ──► call EnterPlanMode（原路不变）
       └─ Codex      ──► 自己 Bash touch plan-lock（护栏自动成立）
                           出关也是 AI 自己 rm，人只点头确认落盘清单
```

| 层 | 机制 | 强度 |
| :--- | :--- | :--- |
| 自动 | plan-mvp / plan-feature 触发即 AI 自开 plan-lock，hook 拦下一切 Edit/Write/apply_patch（plan-debug 不进 plan 模式，不开） | 引擎级拦截 |
| 加固 | 人可先敲内建 `/plan`（引擎级只读，双层更硬） | 引擎级只读 |
| 出关 | AI 呈落盘清单 → 人点头 → AI `rm .cc_code/.runtime/plan-lock` | 对话内确认 |

### 已知残余差异（诚实清单）

- Claude 侧 `allowed-tools` 工具白名单在 Codex 无等价物，由角色沙箱（`sandbox_mode`）承接主要权限边界。
- skill 正文提及的 `EnterPlanMode` 等 Claude 工具名，Codex 读到时会忽略 —— 写盘安全由上表护栏兜底，流程安全靠人按序操作。
- 17 个 skill 描述可能被 Codex 的上下文预算自动压短（隐式触发灵敏度略降，`$` 显式调用不受影响）。新增命令 `pr` 的显式闸门随生成链产出，`verify-codex.sh` 会核对每个命令的闸门覆盖。

## 可选增强：codegraph

[codegraph](https://github.com/colbymchenry/codegraph) 是代码知识图谱索引。cc-code **不依赖它也能全流程跑通**，装了则四项能力升级：

| 能力 | 装了 | 不装（降级形态） |
| --- | --- | --- |
| 增量规划爆炸半径 | `impact` 算传递闭包，改一处知道炸到哪 | Glob/Grep 表层猜测，半径估偏 |
| 冗余检测 | 自动扫死代码 / 孤儿文件 / 重复实现 | `agent-whole-qa` 冗余项基本瞎 |
| 精准回归 | `affected` 沿 import 图算出只需跑的测试 | 全量跑，QA 时间成本高 |
| 契约校准 | Architect 自动核对 `api.md` / `data.md` 实现状态 | 手工 Grep 核对，易漏 |

### 全静默设计（人零心智负担）

```
装一次        /cc-code:init 检测到未装 → 弹选择框介绍收益 → 人点头后装
              npm i -g @colbymchenry/codegraph   ⚠️包名带 scope
建索引        init 静默后台建，绝不阻塞入场
保持新鲜      codegraph 自带 watcher 自动追写 + daemon 复活时 catch-up 补账
              ⛔ 人永不需要手动 sync / index
异常          只报一行（库损坏 / 建议重建），健康时零输出
```

`init.sh` 只探测不安装（改全局环境是高风险操作，且脚本无法交互），装不装由人决定。

### 铁律：codegraph 只答「是什么」，不答「应该是什么」

| 角色 | 权限 | 说明 |
| --- | --- | --- |
| PM | ❌ 完全禁止 | 用现状反推意图 = L1/L2 被 L3 污染 = 系统失效 |
| Architect | ✅ 完全开放 | 校准 L3 契约，`explore`/`node`/`files`/`callers`/`callees`/`impact` |
| Dev | ⚠️ 只读定位 | 找现有实现避免重复造轮子，不推翻契约 |
| QA | ⚠️ 双重限制 | 只用于找入口 / 算回归面，**永不当需求尺子** |

### `affected` 精准回归的前提

测试基建契约登记在 `active/project.md` §六。三条铁律：

1. **测试代码必须入 git** —— codegraph 尊重 `.gitignore`，被 ignore 的测试不进索引 → `affected` 永久失效。该 ignore 的是测试**产物**（`coverage/` / `test-results/` / `.cc_code/docs/qa/artifacts/`），不是测试**代码**。`init` 新建的 `.cc_code/test/` 默认不 ignore；视觉测试 `.cc_code/test/visual/`、截图基线 `baseline/` 与设计目录 `.cc_code/design/` 同样必须入库——⛔ 不许用 `*.png` / `screenshots/` 全局通配忽略截图。
2. **测试必须 import 被测源码** —— 静态 `import` ✅ 动态 `await import()` ✅ 纯 HTTP 打接口 ⛔（无 import 边可追）。
3. **非标准命名必须登记 glob** —— 默认只认 `*.spec.*` / `*.test.*` / `__tests__/`，其余需 `--filter`。

## Skill 一览（17 个）

**框架核心（管流程）**

| skill | 触发 | 用途 |
| --- | --- | --- |
| `init` | `/cc-code:init` | 首次使用建好整个管理文件夹和核心文档；已有项目自动升级，全程零删除 |
| `cc-code` | 自动 | 含 `.cc_code/` 的项目自动加载的流程管家：规划→开发→测试→验收，四步走完才准上线 |
| `plan-mvp` | `/cc-code:plan-mvp` | 做新项目：pm 逐条问清需求并推断端与形态（不发问卷），uiux 画页面原型；【需求与原型批准】后 architect 问技术方案，【技术批准】后落盘 |
| `plan-feature` | `/cc-code:plan-feature` | 加新功能前先扫现有代码与已锁的视觉规格查冲突，列出改哪建哪；新页版式两档（免门登记 / 回门转 `plan-uiux`） |
| `plan-uiux` | `/cc-code:plan-uiux` | 定前端风格：方向卡（有条件）→ `design.md` 草稿 → 风格样板板，你说「定了」才锁；已上线界面要改版也走这里（模式二，qa 先体检） |
| `agent-mvp` | `/cc-code:agent-mvp` | 按定好的方案写码：首阶段视觉地基（主题 + 全局框架 + 组件陈列页），之后页面只引用主题数值；Dev→QA 不过就改到过（≤3 轮） |
| `agent-uiux` | `/cc-code:agent-uiux` | 把「风格已定未实现」落进代码：dev 重新生成主题、调长相与布局；qa 全量五态回归 + 全页视觉 + 基线对比（≤3 轮） |
| `agent-feature` | `/cc-code:agent-feature` | 只写新功能涉及的代码，只跑相关测试，又快又稳 |
| `plan-debug` | `/cc-code:plan-debug` | 出 bug 后顺着代码调用链查到根因（含视觉规格错），bugs.md 自动整理、不等批准，不写码 |
| `agent-debug` | `/cc-code:agent-debug` | 按修复方案改代码，跑相关测试全绿才算修好；视觉 bug 同链，回归测试必须存在且通过 |
| `agent-whole-qa` | `/cc-code:agent-whole-qa` | 上线前开浏览器把每个页面每个按钮全点一遍（含视觉第四层），FAIL 自动修 |
| `short` | `/cc-code:short` | 简单问题只回一句话（≤50 字），绝不啰嗦 |
| `just-do-it` | `/cc-code:just-do-it` | 小改动一句话就干：dev 写完 qa 验，记一笔就完事；命中前端文件只做静态扫描、只记录 |
| `deploy` | `/cc-code:deploy` | 按部署契约把各组件发上线，qa 线上验过才算数（含 390 / 1440 截图与性能采样），出事一键回滚 |
| `pr` | `/cc-code:pr` | 点一下就交付：已验收的改动按规范 commit、推送功能分支、带五项描述建合并请求；证据只取 qa 实测原文 |

**工具外挂（干活的，与状态机无关）**

| skill | 用途 |
| --- | --- |
| `project_resume` | 扫描代码库，替你写一段项目介绍文案 |
| `login_auto` | 一套现成方案装好登录注册：密码/谷歌/邮箱验证码+改密；登录页视觉只取项目主题 |

## Agent（6 个）

六个 agent 与 cc-code 角色一一对应（**角色 = agent**，主控只编排），**独立于任何具体项目**，所有项目约定一律 defer 到 `.cc_code/active/project.md`；测试 / 构建 / 自检命令只认其中的测试基建契约：



| agent | 模型 | cc-code 角色 | 职责 |
| --- | --- | --- | --- |
| `pm` | opus | PM | 逐点问需求至通顺；推断有哪几端、每端什么形态，把默认技术栈与组件库家族写进 `prd.md` §〇（不发问卷）；批准后只落盘 `prd.md`。服务 plan-mvp / plan-feature；不读 `ux.md` / `design.md` |
| `architect` | opus | Architect | codegraph 侦察 + 逐点问技术，批准后落盘 project/data/api 与 project.md §一.1（组件库家族）、§六（测试与视觉基建）、§八（部署契约）、§九（阶段+泳道，首阶段视觉地基）；不读 `design.md` |
| `dev` | inherit | Dev | 按 prd/ux/design/api/data 实现代码；按 `design.md` **生成**各端主题文件（生成物禁手改）、搭视觉地基、只引用主题数值；自检命令来自 project.md 测试基建契约 |
| `qa` | sonnet | QA（灰盒） | 写+跑分层测试，直接写 gates/bugs/测试目录；**视觉第四层**：写 V 段、视觉测试、截图基线（独占）、合集板；结构化 FAIL 清单回 dev，≤3 轮仍 FAIL 交人决策 |
| `uiux` | opus | UIUX（L2 双文件作者） | 写 `ux.md`（形态表 / 页面清单 / ASCII 原型 / testid / 五态 / 断点 / 流转）与 `design.md`（风格与长相）；`plan-uiux` 里出方向卡、风格样板板与截图；**不写项目代码**，只在 plan-mvp / plan-feature / plan-uiux 出场 |
| `curator` | sonnet | Curator（经验整理，后台静默） | 所有经验库的唯一写者：结算后过三道筛、分级、追加、去重、休眠 / 归档、重建 INDEX；只回一行结果；不碰 active、源码与视觉段 |

> agent 定义「怎么干」，cc-code 定义「干什么+在哪干」，`.cc_code/active/` 是唯一耦合接口。

## 文件分层（L0~L4）

```
┌ L0 控制 ─ Agent.md(宪法/权限)  status.md(坐标+卡点+下一步+风格) ─ 人/AI ┐
├ L1 意图 ─ prd.md(分模块逻辑+规则+断言 A1..An+需求摘要) ──────── PM ───┤
├ L2 表现 ─ ux.md(交互与布局+五态矩阵, U 编号发号处) ─────────── uiux ──┤
│           design.md(设计规格: 色彩/字体/间距/形状/动效/各端映射) ─ uiux ┤
├ L3 实现 ─ project.md  data.md  api.md ─────────────────── Architect ┤
├ L4 验收 ─ gates.md(A+U+V 追溯矩阵, 标准在 prd/ux/design) ───── QA ───┤
└ backup/ ─ 冷归档：流水表 + retired/ 退役原文（默认不入库）────────────┘
```

### 信息流铁律（单向，违反即失效）

```
   L1 意图 ──► L2 表现（ux 交互布局 + design 设计规格）──► L3 实现 ──► 代码
    ▲                                                                │
    └──────────────── L4 验收（A + U + V）◄──────────────────────────┘

  ① L4 只拿 L1/L2 当尺子（L2 含设计规格），绝不拿 L3/代码当尺子
     否则 QA 退化为「拿代码验代码」，验收彻底失效
  ② codegraph 只准校准 L3（事实层），永不生成 L1/L2/L4
  ③ Dev/QA 禁改 prd/ux/design/api 让测试通过
  ④ 标准与结果永不同文件：标准在 L1/L2（pm 写 prd、uiux 写 ux / design），结果在 L4（qa 写）
     写标准的人 ≠ 判结果的人 → 制衡成立
  ⑤ V 刻度的来源 = design.md 数值 × ui-gates 规则；V 编号发号处 = gates.md §2.4 V 段
```

## 目录架构

### 插件侧（github.com/weiyi88/cc-code）

```
cc-code/
├── .claude-plugin/   marketplace.json + plugin.json
├── skills/           17 个 skill 目录
├── agents/           6 个 agent（pm / architect / dev / qa / uiux / curator）
├── scripts/          init.sh（三轨脚手架 + 散落物迁移 + 升级归档/清点/归位，零 rm）/ sync-codex.sh / verify-codex.sh
├── templates/        md 骨架（L0~L4 九件（含 design.md）+ bugs.md debug 施工便签 + 经验库 INDEX / 主题文件骨架）
├── docs/             ARCHITECTURE.md
└── hooks/            唯一的 Stop hook（经验整理保底提醒：只比时间戳，不调 AI、不联网）
```

### 项目侧（/cc-code:init 生成）

```
项目根/
├── CLAUDE.md              🧭 入口引导（Claude 原生自动加载，纯协议不含业务状态）
└── .cc_code/
    ├── README.md          🧭 使用手册（每次 init 刷新：项目逻辑 / Skill / 使用方案 / 示例）
    ├── active/          🔴 热数据（每次对话必读，按 L0~L4 分层）
    │   ├── Agent.md       L0 角色路由表 / 最高宪法
    │   ├── status.md      L0 当前坐标 + 卡点 + 下一步 + 「风格：」行（主控写；里程碑在 backup/milestone-log.md）
    │   ├── prd.md         L1 分模块业务逻辑 + 规则 + 验收断言 + §〇 需求摘要（PM）
    │   ├── ux.md          L2 交互与布局 + 五态矩阵（uiux）
    │   ├── design.md      L2 设计规格（颜色/字体/间距/形状/动效/组件长相/各端映射；uiux）
    │   ├── project.md     L3 技术宪法（Architect；§一.1 组件库家族 / §六 视觉基建 / §九 视觉地基）
    │   ├── data.md        L3 数据契约 interface ↔ DB 列（Architect）
    │   ├── api.md         L3 接口契约 method/path/入参/出参/错误码（Architect）
    │   ├── gates.md       L4 A+U+V 验收追溯矩阵（含 §2.4 视觉段）+ 未关闭 FAIL（QA，Dev 禁读）
    │   └── bugs.md        🐛 未修复 bug 工作上下文 B-n（qa 写，修复 PASS 后原文搬 backup/retired/bugs.md，常态为空）
    ├── design/          🎨 方向卡 / 风格样板板 / 样板板截图（uiux 写，不是项目代码，**入 git**）
    ├── docs/qa/         🔵 全量验收报告 + 合集板 + 证据产物（agent-whole-qa / qa 产出）
    ├── test/           ⭐ 测试代码（源码，必须入库；affected 精准回归的索引基础）
    │   └── visual/       👁 视觉机器检查测试（qa 写，入 git）；baseline/ 截图基线（qa 独占，入 git）
    ├── images/          🔵 截图（init 迁移，扁平存放）
    ├── scripts/         🔵 散落脚本归档
    ├── references/      🟢 项目级经验库（curator 全自动整理：INDEX + 主题文件 + archive/ + log/，角色按需读）
    ├── backup/          🧊 冷数据（change-log / milestone-log / retired/ 退役原文 / CLAUDE.md.legacy；默认不入库）
    │   └── YYYY-MM/     升级时：pre-upgrade-<旧版>/ 只读快照 + upgrade_audit.md + superseded/ 归位物
    └── .cc_code_version 🔖 场域版本戳（决定 init 是否走升级迁移）

跨项目经验库（不在 .cc_code/ 里，init 建好）：
~/.cc-code/
    ├── lessons/         🟢 个人库（curator 写，跟人走，结构同项目库）
    └── team/<仓库名>/   🟢 团队库（只读，curator 只负责克隆与拉取）
```

> 忽略口径：只忽略临时产物（`.cc_code/docs/qa/artifacts/`、`coverage/`、`test-results/`）；⛔ 不许用 `*.png` / `screenshots/` 全局通配忽略截图——`.cc_code/design/` 与 `.cc_code/test/visual/baseline/` 必须入库。

## 角色串行

```
pm ──► uiux ──► Architect ──► Dev ──► QA
(逻辑)  (交互+长相)  (契约)      (编码)   (验收)
```

各角色「必读 / 可写 / 禁读」权限只写在 `templates/Agent.md` §三（单一出处，此处不抄副本）。uiux 只在规划侧出场，写 `ux.md` / `design.md` 两份 L2 文件。

## 经验沉淀（全自动）

经验沉淀由 **curator** agent 全自动、静默完成：主人零操作、零确认、零裁决，只在最终报告看到一行结果（无变化不写）。没有手动入口——只沉淀验收里真实发生过、已修好的错。

### 谁整理 · 何时整理

| 角色 | 在经验沉淀里做什么 |
| --- | --- |
| **curator** | 所有经验库的**唯一写者**：过三道筛、分级、追加、去重、休眠 / 归档、重建 INDEX |
| **qa** | 只在 `gates.md` 验收矩阵的同一断言行标「连续 / 回归」与根因类别；不整理 |
| **主控** | 只派单、原样转交报告；不写经验库 |
| **architect / dev** | 读经验当自检问题，完成报告必含一行「采纳经验」 |
| **pm / uiux** | 不读任何经验库 |

```
 执行器结算（全部通过 / 三轮仍未通过交人）
        │
        ▼
 主控后台派 curator ── 原样转交：本次验收报告、dev 修复报告、采纳经验行
        │
        ▼
 ① 写开工时间戳
 ② 记采纳 / 失效，③ 记活跃日
 ④ 三道筛 ─► ⑤ 级别五问 ─► ⑥ 去重 / 恢复 / 追加（写前机械自检）
 ⑦ 休眠 / 归档扫描 ─► ⑧ 团队库拉取（每活跃日最多一次）─► ⑨ 重建 INDEX
        │
        ▼
 一行结果 ─► 并入最终报告（无变化不写）

 保底：主控漏派 ─► Stop hook 发现验收记录比开工时间戳新 ─► 提醒补派一次
```

agent-whole-qa 本次不接入。

### 三道筛：值不值得写

```
 验收矩阵某断言行的标记
        │
 ① 触发？「连续」（上一轮败、这轮又败）或「回归」（上一轮过、这轮败） ──否──► 忽略
        │是
 ② 根因？「实现缺陷」或「设计遗漏」 ──否（测试自身错 / 环境 / 第三方 / 规格歧义）──► 不整理
        │是
 ③ 证据？有根因 · 有源码改动 · 可复现 ──缺一──► 跳过（标记留着，下次再看）
        │齐
        ▼
      进入分级
```

处理日志防止同一标记重复处理。证据来自主控转交的报告，以及 curator 可读的 `active/gates.md`、`active/bugs.md`、`docs/qa/`；⛔ 不读 `backup/`。

### 怎么分类：三个级别

| 级别 | 位置 | 谁写 |
| --- | --- | --- |
| 项目 | `.cc_code/references/` | curator |
| 个人 | `~/.cc-code/lessons/` | curator |
| 团队 | `~/.cc-code/team/<仓库名>/` | 只读；curator 只负责克隆与拉取（每个活跃日最多一次，限时，失败静默跳过） |

```
 一条值得写的教训
        │
 协作者需要吗？ ──是──► 项目
        │否
 去掉项目名词还成立吗？ ──否──► 项目
        │是
 技术自身行为，还是本项目选择？ ──本项目选择──► 项目
        │技术自身行为
 换业务会再犯吗？ ──否──► 项目
        │是
 换业务 / 合规 / 成本目标，答案会反转吗？ ──会（取舍型）──► 只进项目
        │不会
        ▼
      个人            （拿不准一律项目）
```

### 结构：渐进式披露

三级同一套结构：

| 文件 | 作用 |
| --- | --- |
| `INDEX.md` | 入口。每个主题一行：主题、何时读、有效条数、休眠条目；派生物，每次由 curator 重新生成 |
| `<主题>.md` | 一个主题一个文件，英文 kebab-case 文件名（如 `async-queue.md`、`db-timezone.md`）；同主题追加进同一文件，约束与已有条目相同则不新增，只记一次采纳 |
| `archive/<同名主题>.md` | 归档条目，原文完整保留 |
| `log/` | 追加日志：采纳日志、活跃日日志（项目库另有处理日志与开工时间戳，个人库另有团队拉取记录） |

每条经验五个字段，不允许一个废字、不加代码：

| 字段 | 内容 |
| --- | --- |
| 标题 | `<项目>-<角色>-<日期>`（同日重复末尾加 -2） |
| 背景 | 当时在做什么 |
| 输入 | 当时的条件和依赖 |
| 输出 | 期望得到什么 |
| 发生什么 | 实际错在哪、为什么错 |
| 约束 | 以后必须遵守的一句话；有适用范围写在句末括号里 |

禁写：断言编号、实测数值 / 期望值、密钥、账号、客户名、内部地址、代码；curator 写入前机械自检，命中则改写成不含这些的版本。

### 只追加 · 生命周期

条目文件只追加不覆盖、不删除，追加用末尾直接追加的方式，多会话并发安全。**活跃日** = 该库所在范围当天有 curator 结算运行（个人库按任意项目）。

| 状态 | 判据 | 动作 |
| --- | --- | --- |
| 正常 | 近 7 个活跃日内被采纳过（或刚写入） | — |
| 休眠 | 连续 7 个活跃日未被采纳 | INDEX 标注，读者可跳过；被采纳即恢复 |
| 归档 | 连续 14 个活跃日未被采纳，或被报告「不适用 / 失效」 | 搬到 `archive/` 同名主题文件（curator 唯一的搬运动作，原文完整保留）；同主题再出现新事件时先查归档，能恢复就恢复 |

### 谁读 · 何时读

| 谁 | 何时 | 读什么 |
| --- | --- | --- |
| architect | plan-mvp / plan-feature 第 6 步首次派它；plan-debug 因契约错路由派它时 | 项目 / 个人 / 团队三处 INDEX（不存在跳过），命中主题才打开。项目级直接用于设计；个人 / 团队级在方案落盘时写进 `project.md` §五 特殊约束 |
| dev | 执行器派单明确列出 | 项目 `references/INDEX.md` + `project.md`（含 architect 转写的跨项目经验） |
| qa / pm / uiux | — | 不读任何经验库 |

architect 与 dev 的完成报告都必含一行「采纳经验：<条目标题> / 无 / 不适用：<条目标题>」，dev 缺这一行主控续接补；主控把这些行原样转给 curator（执行器结算时随结算材料；plan-* 里 architect 落盘后另派一次只记采纳的后台 curator），采纳记入日志，「不适用」立即归档。

优先级：active 文件 ＞ 项目 ＞ 个人 ＞ 团队；经验之间冲突写进那一行上报，不自动取舍；经验只当自检问题，不当验收尺子。

### 团队导入 · 一次配好 · 复查

- **团队导入**：在对话里给出 git 地址并说明是团队经验，主控派 curator 克隆到 `~/.cc-code/team/<仓库名>/`；不新增命令。
- **init 一次配好**：建好项目与个人经验库骨架，并向生成项目的 `.claude/settings.local.json`（本机生效、不入 git）幂等合并所需权限（不破坏已有设置），之后写个人库、拉团队库不弹确认。
- **上线复查**：上线后 30 天总采纳次数为 0，则复查或下线这套机制。

## 唯一的 Stop hook

cc-code 只有**一个** Stop hook，职责单一：经验整理的保底提醒。其余 `.cc_code/` 文件仍由 AI 在对话内顺手写。

```
 会话收尾（Stop）
      │
      ▼
 已处于 hook 续跑中？ ──是──► 立即退出（防循环）
      │否
 项目有 .cc_code/ 且有开工时间戳？ ──否──► 静默退出
      │是
 验收记录修改时间 新于 curator 开工时间戳？ ──否──► 静默退出
      │是
      ▼
 给主会话一条非错误提示 ─► 主控后台补派一次 curator（已派过则忽略）
```

- **极快**：只比两个文件的时间戳，不调 AI、不联网。
- **不误报**：curator 第一步就写开工时间戳。
- **只是提醒**：永不报错、不卡住主会话。

> 设计沿革：早期版本有 Stop Hook 做 `errors.md` 冷切片。0.5.0 起 `errors.md` 废除（坑写进 commit message / git blame，天然留痕），Hook 失去唯一职责，一并砍除——符合「一个东西只做自己的逻辑」，没逻辑就别留。1.10.0 起经验整理由 agent 后台完成，而「执行器结算后是否真的派了 curator」恰好是一件**机械可判**的事（比两个时间戳），于是重新引入这唯一的一个 hook，只做保底。

## 散落物迁移（init 判定链）

`/cc-code:init` 用「默认不动」判定链清理项目根散落文件，宁可漏搬绝不误杀：

```
项目根文件 ──► ① 保护白名单？ ──► ② git 已追踪？ ──► ③ 被引用？ ──► ④ 名字像临时物？
                 (任一命中即 SKIP)                              (才搬)
                                                                  ↓ 都不匹配
                                                              原地保留 + 记 needs_review.md
```

旧版「默认搬走」会误杀 `setup.py`/`manage.py`/`AGENTS.md`/`build.sh` 等基建 —— 已反转。

## 新手入门

每个项目 init 后，`.cc_code/README.md` 会生成一份**使用手册**（项目逻辑 / Skill 一览 / 使用方案 / 使用示例），并且**每次 `/cc-code:init` 自动刷新到最新版** —— 不熟悉 cc-code 的协作者直接读它即可，无需翻本仓库。

## License

MIT
