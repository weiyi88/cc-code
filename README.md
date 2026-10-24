# cc-code

> Version: **1.8.2** ｜ [English](./README.en.md) ｜ 简体中文

> 极简开发工作流系统 —— 把 LLM 装进「认知沙盒」，让它成为精确、稳定、可溯源的自动化软件工业母机。
> 宪法原则：**只对结果负责，不在乎过程**（结果是否符合需求是唯一尺子）。
> 基于四大铁律：**上下文最小化 · 决策串行 · 记忆外部化 · active 三判据**。

---

## 目录

- [设计哲学](#设计哲学)
- [核心逻辑](#核心逻辑)
- [编排方式（1.8.0）](#编排方式180角色--agent主控只传话)
- [就地更新 + 搬运归档（1.7.0）](#就地更新--搬运归档170)
- [安装](#安装)
- [完整生命周期](#完整生命周期)
- [快速开始](#快速开始)
- [Codex CLI 适配（1.1.0）](#codex-cli-适配110)
- [可选增强：codegraph](#可选增强codegraph)
- [Skill 一览（16 个）](#skill-一览16-个)
- [Agent（5 个）](#agent5-个)
- [文件分层（L0~L4）](#文件分层l0l4)
- [目录架构](#目录架构)
- [角色串行](#角色串行)
- [经验沉淀（references）](#经验沉淀references)
- [无 Hook 设计](#无-hook-设计)
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

### 角色串行（先 PM 后 Architect，再 Dev、QA）

```
PM ──► Architect ──► Dev ──► QA
(逻辑)   (契约)      (编码)   (验收)
```

各角色「必读 / 可写 / 禁读」权限只写在 `templates/Agent.md` §三（单一出处，此处不抄副本）。

### 编排方式（1.8.0）：角色 = agent，主控只传话

```
 主人 ◄──────────────► 主控（编排者：不扮演任何角色、不读代码、不替主人回答）
                         │  只写 status.md（坐标/卡点/下一步）+ backup/milestone-log.md 追加行
                         │
   规划（plan-mvp / plan-feature）          严格先 PM 后 Architect
     ① 派 pm（全新上下文）─ 一次一个问题 ◄──► 主人原话原样续接同一个 pm
            └─ 主人批准需求（第 1 次批准）→ pm 落盘 prd / ux
     ② 派 architect（全新上下文）─ 逐点问技术 ◄──► 主人
            ├─ 发现需求冲突 → 业务语言转述 → 主人裁决 → pm 交修订摘要（plan 模式不写盘）→ 回 architect；批准后先 pm 后 architect 落盘
            └─ 主人批准方案（第 2 次批准）→ architect 落盘 project / data / api / §九
   执行（agent-*）
     派 dev 写 ─► 派 qa 验 ─► FAIL ≤3 轮 ─► 仍 FAIL：交人决策
   debug（不进 plan 模式，bugs.md 自动整理，不等批准）
     qa 复现取证，复现成功当场写 B-n（待诊断）─► dev 只读诊断（不改码）─► 主控转 qa 补根因/爆炸半径/方案，再把四段（现象/根因/爆炸半径/修法）用业务语言告知主人
     ├─ 纯实现层 ─► 待修复 ─► dev 修 ─► qa 复测 ─► PASS 则 qa 把条目搬 backup/retired/bugs.md
     └─ 契约错 / 需求错 / 找不到期望出处 / 复现不了 ─► 待裁决：问主人一句话 ─► 裁决后 architect / pm 改文档（或 qa 重新复现）─► 待修复
```

| agent | 模型档位 |
| --- | --- |
| `pm` | opus |
| `architect` | opus |
| `dev` | inherit（继承主会话） |
| `qa` | sonnet |
| `uiux` | inherit（继承主会话） |

谁写哪个文件见 `templates/Agent.md` §二 / §三，此处不抄副本。

所有 agent 开 `memory: project`（记忆存在生成项目的 `.claude/agent-memory/<agent>/`，只记本角色经验）；项目约定永远从 `.cc_code/active/*` 读，不从记忆读。Codex 端本版只保证生成链不坏（inherit 档继承父会话，不写 model 行）。

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

### 文件分层（先认层，再认角色）

```
┌ L0 控制 ─ Agent.md(宪法/权限表)  status.md(坐标+里程碑) ─ 人/AI ┐
├ L1 意图 ─ prd.md(分模块逻辑+规则+验收断言 A1..An) ────── PM ───┤
├ L2 表现 ─ ux.md(视觉规格+五态矩阵, U 编号发号处) ────── PM ───┤
├ L3 实现 ─ project.md  data.md  api.md ───────────── Architect ┤
├ L4 验收 ─ gates.md(A+U 追溯矩阵, 标准在 prd/ux) ─────── QA ───┤
└ backup/ ─ 冷归档：流水表 + retired/ 退役原文（默认不入库）───────┘
```

### 信息流铁律（单向，违反即失效）

```
   L1 意图 ──► L2 表现 ──► L3 实现 ──► 代码
    ▲                                   │
    └───────── L4 验收 ◄────────────────┘

  ① L4 只拿 L1/L2 当尺子，绝不拿 L3/代码当尺子
     否则 QA 退化为「拿代码验代码」，验收彻底失效
  ② codegraph 只准校准 L3（事实层），永不生成 L1/L2/L4
  ③ Dev/QA 禁改 prd/ux/api 让测试通过
  ④ 标准与结果永不同文件：标准在 L1/L2（PM 写），结果在 L4（QA 写）
     写标准的人 ≠ 判结果的人 → 制衡成立
```

### active 三判据

`active/` 是唯一真相源，必须**永远**保持最新、最完整、最纯净：

```
   最新   ── 同一对象在 active 只有一处描述, 且是当前态
             ⛔ 禁新开「## 增量 F-n」章节 → 就地改写对应小节

   最完整 ── 每个待验维度都有永久稳定编号, 分母算得出
             A 编号 (prd.md §1.5 主表) = 业务逻辑 / 链路 / 接口
             U 编号 (ux.md  §2.3 矩阵) = UI 布局 / 交互五态

   最纯净 ── 每一行都在答「现在是什么」, 不是「当时怎么决定的」
             过程产物不落盘（change-log 留痕） ·  逐轮验收详情 → docs/qa/
             过期内容 → backup/retired/<源文件名>.md（原文整段搬走, 一字不丢）
```

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

## 安装

```bash
# 1. 添加本仓库为 marketplace
/plugin marketplace add https://github.com/weiyi88/cc-code

# 2. 安装 cc-code 插件
/plugin install cc-code
```

安装后自动获得 `/cc-code:*` 命令族、16 个 skill 与 5 个配套 agent。

## 完整生命周期

```
/cc-code:init          搭场域（8模板 + bugs.md debug 便签 + 迁移散落物 + 盖版本戳
                       + 刷新 .cc_code/README.md 使用手册）
                       旧版场域自动走升级迁移（零删除）
       ↓
会话开启(2步)          Read Agent.md(读权限表) → status.md(定坐标)
       ↓
/cc-code:plan-mvp  ⭐第一动作 call EnterPlanMode → plan 内探测+三件套
                       +逐点交谈至通顺 → 落盘五件（prd/ux/project/data/api）
                       （落盘即定稿，无二次验收）
       ↓
/cc-code:plan-uiux   （可选，前端项目）ux.md 页面清单 → design.pen 可视化
                       原型真图；风格叠加：plan-uiux gpt-taste；AI 自动保存落盘
       ↓
/cc-code:agent-mvp  纯执行（读定稿文档，Dev→QA，FAIL≤3轮回环，中途零确认；
                       阶段内有泳道则同角色多人并发；
                       有 pen 则 Dev 先走底稿三步：Export html-tailwind → 薄装配 → 截图比对）
       ↓
/cc-code:agent-whole-qa      全量验收（功能 + 冗余，FAIL≤3轮回环；修复按文件分组并发）
       ↓
/cc-code:deploy     上线（读 project.md 部署契约，任意平台组合；qa 线上冒烟，
                       出事 /cc-code:deploy rollback 一键回退）

────────── MVP 交付后，功能迭代走这条支线 ──────────

/cc-code:plan-feature  ⭐第一动作 call EnterPlanMode → 规范体检+锁基线
                           +codegraph 算爆炸半径 → 冲突逐条硬门控裁决
                           +三件套交谈至通顺 → 就地收敛落盘（落盘即定稿）
                           +status.md 点名 F-n 与新断言号
       ↓
/cc-code:agent-feature  增量纯执行（增量定位 → Dev→QA，affected 精准回归；有泳道则并发）

────────── 任意时刻修 bug 走这条支线（需求明确但实现错了）──────────

/cc-code:plan-debug          不进 plan 模式 → qa 问诊复现，复现成功当场写 B-n 到 active/bugs.md（待诊断）
                             → dev 只读查脉络（链路/半径/测试面）→ qa 补根因/爆炸半径/方案（待修复）→ 主控用四段业务语言告知你（只告知，不等批准）
                             记录不等批准；只在契约错/需求错/找不到期望出处/复现不了时
                             标「待裁决」问你一句（施工便签，修完原文搬 backup/retired/bugs.md）
       ↓
/cc-code:agent-debug        bug 修复纯执行（只接待修复的 B-n → Dev→QA，affected 精准回归
                             + 回归测试留守，无全量清算）

────────── 任意时刻 ──────────

/cc-code:experience-summary  踩坑/复盘 → 提炼设计准则 → references/ 资料库
/cc-code:init                插件升级后再跑一次：场域迁移 + 手册刷新到最新
```

**主线是 6 个 skill 三对配对串起来**：规划（商讨落盘定稿）→ 执行（纯机器推进）→ 全量验收。
`cc-code` skill 在背后管运行时协议（角色路由 + 分层），`init` 是入场。无 Stop Hook，所有状态由 AI 顺手写。

## 快速开始

在任意项目根目录：

```
/cc-code:init
```

- **新项目**：直接搭场域 + 盖版本戳，切 PM 等需求。
- **旧项目（无 `.cc_code/`）**：备份旧 `CLAUDE.md` → `.cc_code/backup/YYYY-MM/CLAUDE.md.legacy`，AI 按映射表分拆归并到 `active/` 各文件，再用入口模板覆盖根目录 `CLAUDE.md`。
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

`--codex` 做三件事：`AGENTS.md → CLAUDE.md` 软链（宪法双端同源）、`.codex/hooks.json + gate.sh`（plan 写盘拦截）、`.codex/agents/*.toml`（五角色沙箱；源已删除的旧角色 toml 会被清掉）。**首次运行 codex 会要求在 `/hooks` 里审查信任 gate.sh —— trust 一次即生效。**

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
- 16 个 skill 描述可能被 Codex 的上下文预算自动压短（隐式触发灵敏度略降，`$` 显式调用不受影响）。

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

1. **测试代码必须入 git** —— codegraph 尊重 `.gitignore`，被 ignore 的测试不进索引 → `affected` 永久失效。该 ignore 的是测试**产物**（`coverage/` / `*.png`），不是测试**代码**。`init` 新建的 `.cc_code/test/` 默认不 ignore。
2. **测试必须 import 被测源码** —— 静态 `import` ✅ 动态 `await import()` ✅ 纯 HTTP 打接口 ⛔（无 import 边可追）。
3. **非标准命名必须登记 glob** —— 默认只认 `*.spec.*` / `*.test.*` / `__tests__/`，其余需 `--filter`。

## Skill 一览（16 个）

**框架核心（管流程）**

| skill | 触发 | 用途 |
| --- | --- | --- |
| `init` | `/cc-code:init` | 首次使用建好整个管理文件夹和核心文档；已有项目自动升级，全程零删除 |
| `cc-code` | 自动 | 含 `.cc_code/` 的项目自动加载的流程管家：规划→开发→测试→验收，四步走完才准上线 |
| `plan-mvp` | `/cc-code:plan-mvp` | 做新项目前逐条问清需求，画流程图和页面草图，确认后写成方案文档 |
| `plan-feature` | `/cc-code:plan-feature` | 加新功能前先扫现有代码查冲突，列出改哪建哪，写成方案文档 |
| `plan-uiux` | `/cc-code:plan-uiux` | 先试画 2 页定风格，再逐页画进 `design.pen` 设计稿，每页经你确认才保存 |
| `agent-mvp` | `/cc-code:agent-mvp` | 按定好的方案写码，写完自动测试，不过就改到过（最多 3 轮） |
| `agent-feature` | `/cc-code:agent-feature` | 只写新功能涉及的代码，只跑相关测试，又快又稳 |
| `plan-debug` | `/cc-code:plan-debug` | 出 bug 后顺着代码调用链查到根因，bugs.md 自动整理、不等批准，不写码 |
| `agent-debug` | `/cc-code:agent-debug` | 按修复方案改代码，跑相关测试全绿才算修好 |
| `agent-whole-qa` | `/cc-code:agent-whole-qa` | 上线前开浏览器把每个页面每个按钮全点一遍，FAIL 自动修 |
| `experience-summary` | `/cc-code:experience-summary` | 把踩过的坑写成经验笔记并编号索引，下次直接翻 |
| `short` | `/cc-code:short` | 简单问题只回一句话（≤50 字），绝不啰嗦 |
| `just-do-it` | `/cc-code:just-do-it` | 小改动一句话就干：dev 写完 qa 验，记一笔就完事 |
| `deploy` | `/cc-code:deploy` | 按部署契约把各组件发上线，qa 线上验过才算数，出事一键回滚 |

**工具外挂（干活的，与状态机无关）**

| skill | 用途 |
| --- | --- |
| `project_resume` | 扫描代码库，替你写一段项目介绍文案 |
| `login_auto` | 一套现成方案装好登录注册：密码/谷歌/邮箱验证码+改密 |

## Agent（5 个）

五个 agent 与 cc-code 角色一一对应（**角色 = agent**，主控只编排），**独立于任何具体项目**，所有项目约定一律 defer 到 `.cc_code/active/project.md`；测试 / 构建 / 自检命令只认其中的测试基建契约：



| agent | 模型 | cc-code 角色 | 职责 |
| --- | --- | --- | --- |
| `pm` | opus | PM | 逐点问需求至通顺，批准后落盘 prd/ux；服务 plan-mvp / plan-feature |
| `architect` | opus | Architect | codegraph 侦察 + 逐点问技术，批准后落盘 project/data/api 与 project.md §九（阶段+泳道）、§八 部署契约 |
| `dev` | inherit | Dev | 按 prd/ux/api/data 实现代码；自检命令来自 project.md 测试基建契约 |
| `qa` | sonnet | QA（灰盒） | 写+跑分层测试，直接写 gates/bugs/测试目录，结构化 FAIL 清单回 dev，≤3 轮仍 FAIL 交人决策 |
| `uiux` | inherit | UIUX（原型工人） | 收单页任务单 → pencil MCP 画 P-n/M-n 帧 → 截图自检 → 报 frameId；服务 plan-uiux |

> agent 定义「怎么干」，cc-code 定义「干什么+在哪干」，`.cc_code/active/` 是唯一耦合接口。

## 文件分层（L0~L4）

```
┌ L0 控制 ─ Agent.md(宪法/权限表)  status.md(坐标+里程碑) ─ 人/AI ┐
├ L1 意图 ─ prd.md(分模块逻辑+规则+验收断言 A1..An) ────── PM ───┤
├ L2 表现 ─ ux.md(视觉规格+五态矩阵, U 编号发号处) ────── PM ───┤
├ L3 实现 ─ project.md  data.md  api.md ───────────── Architect ┤
├ L4 验收 ─ gates.md(A+U 追溯矩阵, 标准在 prd/ux) ─────── QA ───┤
└ backup/ ─ 冷归档：流水表 + retired/ 退役原文（默认不入库）───────┘
```

### 信息流铁律（单向，违反即失效）

```
   L1 意图 ──► L2 表现 ──► L3 实现 ──► 代码
    ▲                                   │
    └───────── L4 验收 ◄────────────────┘

  ① L4 只拿 L1/L2 当尺子，绝不拿 L3/代码当尺子
     否则 QA 退化为「拿代码验代码」，验收彻底失效
  ② codegraph 只准校准 L3（事实层），永不生成 L1/L2/L4
  ③ Dev/QA 禁改 prd/ux/api 让测试通过
  ④ 标准与结果永不同文件：标准在 L1/L2（PM 写），结果在 L4（QA 写）
     写标准的人 ≠ 判结果的人 → 制衡成立
```

## 目录架构

### 插件侧（github.com/weiyi88/cc-code）

```
cc-code/
├── .claude-plugin/   marketplace.json + plugin.json
├── skills/           16 个 skill 目录
├── agents/           5 个 agent（pm / architect / dev / qa / uiux）
├── scripts/          init.sh（三轨脚手架 + 散落物迁移 + 升级归档/清点/归位，零 rm）
├── templates/        9 个 md 骨架（L0~L4 + bugs.md debug 施工便签）
├── docs/             ARCHITECTURE.md
└── 无 hooks/         （0.5.0 砍除，无自动化机械活）
```

### 项目侧（/cc-code:init 生成）

```
项目根/
├── CLAUDE.md              🧭 入口引导（Claude 原生自动加载，纯协议不含业务状态）
└── .cc_code/
    ├── README.md          🧭 使用手册（每次 init 刷新：项目逻辑 / Skill / 使用方案 / 示例）
    ├── active/          🔴 热数据（每次对话必读，按 L0~L4 分层）
    │   ├── Agent.md       L0 角色路由表 / 最高宪法
    │   ├── status.md      L0 当前坐标 + 里程碑（AI 自管长度）
    │   ├── prd.md         L1 分模块业务逻辑 + 规则 + 验收断言（PM）
    │   ├── ux.md          L2 视觉规格 + 交互五态矩阵（PM）
    │   ├── project.md     L3 技术宪法（Architect）
    │   ├── data.md        L3 数据契约 interface ↔ DB 列（Architect）
    │   ├── api.md         L3 接口契约 method/path/入参/出参/错误码（Architect）
    │   ├── gates.md       L4 A+U 验收追溯矩阵 + 未关闭 FAIL（QA，Dev 禁读）
    │   └── bugs.md        🐛 未修复 bug 工作上下文 B-n（qa 写，修复 PASS 后原文搬 backup/retired/bugs.md，常态为空）
    ├── docs/qa/         🔵 全量验收报告 + 元素清单（agent-whole-qa 产出）
    ├── test/           ⭐ 测试代码（源码，必须入库；affected 精准回归的索引基础）
    ├── images/          🔵 截图（init 迁移，扁平存放）
    ├── scripts/         🔵 散落脚本归档
    ├── references/      🟢 项目级经验资料库（experience-summary 产出，INDEX 索引 + 角色按需读）
    ├── backup/          🧊 冷数据（change-log / milestone-log / retired/ 退役原文 / CLAUDE.md.legacy；默认不入库）
    │   └── YYYY-MM/     升级时：pre-upgrade-<旧版>/ 只读快照 + upgrade_audit.md + superseded/ 归位物
    └── .cc_code_version 🔖 场域版本戳（决定 init 是否走升级迁移）
```

## 角色串行

```
PM ──► Architect ──► Dev ──► QA
(逻辑)   (契约)      (编码)   (验收)
```

各角色「必读 / 可写 / 禁读」权限只写在 `templates/Agent.md` §三（单一出处，此处不抄副本）。

## 经验沉淀（references）

开发中踩坑/排障/方案复盘暴露的**设计经验**，用 `/cc-code:experience-summary` 沉淀为项目级 references：

```
/cc-code:experience-summary
       ↓
提炼「必答问题 + 设计准则」→ 主人过目 → 落盘
       ↓
.cc_code/references/[角色]-[事件域]-references.md
  例：architect-bull-redis-queue-references.md
       ↓
INDEX.md 登记一行「何时读」→ 角色接到任务先扫索引，命中才读（按需，非全读）
```

- **项目级**：跟随项目走，不进插件、不进全局。
- **精炼**：只写「设计/验收时怎么思考、怎么做」，≤30 行，禁溯源流水账。
- **准出价值**：每条准则必须可执行 —— 能据此否决一个方案。

## 无 Hook 设计

cc-code **不使用 Stop Hook**。所有 `.cc_code/` 文件都由 AI 在对话内顺手写，无自动化机械活。

> 设计沿革：早期版本有 Stop Hook 做 `errors.md` 冷切片。0.5.0 起 `errors.md` 废除（坑写进 commit message / git blame，天然留痕），Hook 失去唯一职责，一并砍除。符合「一个东西只做自己的逻辑」—— 没逻辑就别留。

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
