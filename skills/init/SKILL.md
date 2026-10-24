---
description: 首次使用建好整个管理文件夹和核心文档；已有项目自动升级，全程零删除
allowed-tools: Read, Write, Edit, Bash, Glob, Grep, Agent, SendMessage
disable-model-invocation: true
---

# /cc-code:init — 项目场域初始化 / 版本升级

执行 cc-code 工作流的入场协议。**同时负责把旧版场域升级到当前插件规范。**

## 第 1 步：三轨判定

扫描当前工作区，由 `.cc_code/.cc_code_version` 版本戳分流：

| 探测条件 | 轨道 | 行为 |
| --- | --- | --- |
| 无 `active/Agent.md`，且存在 `src/` / `package.json` / `go.mod` 等旧代码或根目录已有 `CLAUDE.md` | **Track A** 旧项目接管 | 扫描技术栈+断层，与用户多轮补 PRD；执行第 2A 步：主控原文分拣旧 `CLAUDE.md`，再按顺序派各文件写者落盘 |
| 无 `active/Agent.md`，全空目录 | **Track B** 新项目 | 直接搭场域 + 盖版本戳，等待需求（规划时由主控派 pm agent，init 不扮演角色） |
| 有 `active/Agent.md`，且版本戳 **==** 插件版本 | **Track C** 已最新 | 跳过脚手架，搬散落物 + ⭐**跑 D4 骨架格式体检**（0.9.0 起），再进第 3 步 |
| 有 `active/Agent.md`，但版本戳**缺失或更旧** | **Track D** ⭐升级迁移 | 脚本做 D1 归档 + D2 清点 + 规范文件机械覆盖，**主控按第 2C 步按文件派写者 agent 做 D3~D5（主控只派不写），D6 / D7 是脚本机械动作** |

> ⭐ 版本戳是升级的唯一判据。**戳未盖 = 迁移未完成**，下次 `init` 仍判 Track D，不会把半成品误认为已完成。

> ⚠️ **Track C 也必须体检**（0.9.0 修正）：0.8.0 及以前 Track C「仅搬散落物」，**零格式体检**。一旦某文件盖戳时格式没归位，之后每次 `init` 都判 Track C 跳过检查 → **旧格式永久留存，永无自愈机会**。
> Track C 体检为**轻量版**：只检 D4 骨架清单，发现缺失即报主人并给归位建议，**不自动改写**（已最新的项目不该被 init 悄悄动内容）。

## 第 2 步：执行脚手架

```bash
bash "$CLAUDE_PLUGIN_ROOT/scripts/init.sh" "$(pwd)"
```

脚本按三轨自动分流。Track B/A 生成 `active/ backup/ docs/{plans,qa}/ images/ scripts/ references/` + **8 个 active 模板骨架**（按 L0~L4 分层：`Agent status` / `prd` / `ux` / `project data api` / `gates`）+ `bugs.md`（0.13.0 起，debug 链施工便签，常态为空）+ `references/INDEX.md` 索引 + **根目录 `CLAUDE.md` 入口引导** + **`.cc_code/README.md` 使用手册**（每次 init 无条件刷新到最新版）+ **版本戳**。Track C 搬散落物 + 补建缺失的 `bugs.md` + 刷新手册 + **主控跑 D4 轻量骨架体检（只读报告，不改文件）**。Track D 见第 2C 步（脚本 D2 阶段自动补建缺失的 `references/` 与 `bugs.md`）。

子命令（供 AI 在升级阶段调用）：

| 命令 | 用途 |
| --- | --- |
| `bash init.sh --relocate <相对路径...>` | 冗余归位：`mv` 进 `backup/YYYY-MM/superseded/`。**零删除**，且拒绝归位规范 8 文件 |
| `bash init.sh --stamp` | 盖版本戳。**仅在 D5 校验门全过后才允许调用** |

散落物迁移采用**「默认不动」判定链**（任一命中即跳过）：① 保护白名单 → ② **git 已追踪**（最强判据：人 commit 过 = 不是垃圾）→ ③ 被 package.json/CI/Dockerfile/源码引用 → 三关全过才做正向识别（名字像临时物/过程报告才搬）→ ④ 都不匹配则**原地保留**并记入 `backup/YYYY-MM/needs_review.md` 交人工判断。搬走的记入 `migration_manifest.md`。同时把 `.cc_code/backup/` 追加进根 `.gitignore`。

> ⚠️ 判定链宁可漏搬也绝不误杀 —— `setup.py` / `manage.py` / `conftest.py` / `AGENTS.md` / `build.sh` / `logo.png` 这类项目基建必须原地不动。

CLAUDE.md 处理（init.sh 自动完成，机械活）：

- **Track B 新项目**：直接 `cp templates/CLAUDE.md → 根目录/CLAUDE.md`。
- **Track A 旧项目**：先把旧 `CLAUDE.md` 备份至 `.cc_code/backup/YYYY-MM/CLAUDE.md.legacy`，再用入口模板覆盖根目录 `CLAUDE.md`。
- **Track D 升级**：D1 快照之后，脚本把 `active/Agent.md`、根目录 `CLAUDE.md`、`AGENTS.md` 机械覆盖为插件模板新版，旧版快照进 `backup/YYYY-MM/pre-upgrade-<旧版>/spec/`。这三件是插件规范文件，唯一写者 = init 脚本，项目不自定义 `Agent.md` 权限，项目差异一律写进 `project.md`；脚本不改任何其它已存在文件的内容。

> 新生成的 `CLAUDE.md` 是**纯入口引导**（会话开启协议 + 三铁律 + 文件索引），不含任何业务状态。Claude Code 原生会自动加载它，从而被引导进 `.cc_code/` 状态机。

## 第 2B 步：codegraph 装载引导（⭐0.10.0 新增，三轨通用）

`init.sh` 的 `ensure_codegraph()` 已做完**探测与建索引**（静默，不阻塞）。AI 只需处理一种情况：脚本输出 `CODEGRAPH_MISSING`。

### 静默五铁则（AI 必须遵守）

```
① 零新增用户命令   人永不需要敲 codegraph 任何子命令
② 零阻塞           建索引后台跑，init 绝不等它
③ 零噪音           已就绪时一个字都不提（⛔ 禁报「索引正常」这类废话）
④ 只在异常说一行   未装 / 库损坏 / 建议重建
⑤ 永不自动全量重建 index 可能耗时数分钟，只提示不执行
```

### 命中 `CODEGRAPH_MISSING` 时：用 `AskUserQuestion` 弹一次选择框

⛔ 禁止静默跳过（人会永远不知道自己少了什么），⛔ 禁止脚本自动 `npm i -g`（改全局环境是高风险操作，必须人点头）。

选择框必须讲清**装了得到什么**：

| 能力 | 装了 | 不装（降级形态） |
| :--- | :--- | :--- |
| 增量规划爆炸半径 | `impact` 算传递闭包，改一处知道炸到哪 | Glob/Grep 表层猜测，半径估偏 |
| 冗余检测 | 自动扫死代码 / 孤儿文件 / 重复实现 | `agent-whole-qa` 冗余项基本瞎 |
| 精准回归 | `affected` 算出只需跑的测试 | 全量跑，QA 时间成本高 |
| 契约校准 | Architect 自动核对 `api.md` / `data.md` 实现状态 | 手工 Grep 核对，易漏 |

- 选项 A「安装（推荐）」→ 执行 `npm i -g @colbymchenry/codegraph`（**注意包名带 scope**，裸 `codegraph` 是另一个包），装完依次跑 `codegraph install -y`（注册 MCP）→ `codegraph init`（建索引，后台）。
- 选项 B「跳过」→ 记一行到 `status.md`「当前卡点」，本次会话不再问。

> 安装是**一次性**动作。之后 watcher 自动追写 + daemon 复活时 catch-up 补账，人永不需要手动 sync。

### 索引体检（库已存在时，AI 读 `codegraph status --json` 三字段）

| 字段 | 命中 | 动作 |
| :--- | :--- | :--- |
| `initialized: false` | 库损坏 | 报一行，⛔ 不自动重建 |
| `pendingChanges` 非 0 | 有未追写改动 | 静默跑一次 `codegraph sync`（新鲜度保险） |
| `reindexRecommended: true` | 引擎版本升级过 | 报一行建议 `codegraph index -f`，⛔ 不自动执行 |

### `.cc_code/test/` 是测试代码目录（⛔ 绝不 ignore）

`init.sh` 新建 `.cc_code/test/`，且 `update_gitignore()` 只 ignore `backup/`，并写入注释警告。**测试代码是源码，被 ignore 就不进 codegraph 索引 → `affected` 永久失效**。该 ignore 的是测试产物（`coverage/` / `*.png`），不是测试代码。测试 glob 由 Architect 登记在 `project.md` §六。

## 第 2B' 步：design.pen 原型意向问询（⭐1.0.0 新增，前端项目专属）

脚本跑完后，AI 判定项目是否含前端（`package.json` 有 `react` / `vue` / `next` / `nuxt` / `taro` / `uni-app` 等依赖，或 `src/` 存在页面组件）。是前端项目且根目录**尚无** `design.pen` 时，用 `AskUserQuestion` 问一次：

| 选项 | 后续 |
| :--- | :--- |
| 要 pen 原型 | 跑 `bash "$CLAUDE_PLUGIN_ROOT/scripts/init.sh" --design-pen` 建根目录 0 字节锚点（脚本机械动作）；派 pm 在 `ux.md` §一登记 pen 模式；后续画图走 `/cc-code:plan-uiux` |
| 不要 | 什么都不做，`ux.md` 维持文字模式；本次会话不再问 |

问询铁律：
- ⛔ 禁静默跳过（前端项目主人可能永远不知道有这条路）
- ⛔ 禁对**非前端项目**弹问（后端/CLI 项目问了就是打扰）
- ⛔ 已有 `design.pen` 的项目**不问**（已在链上）
- 决策落 `ux.md` §一一行（pen 模式登记）：**主控不写，派 pm 登记**（`ux.md` 唯一写者），不落 status.md 卡点

> `.pen` 是加密文件：只准 pencil MCP 读写，⛔ 禁 Read/Grep。锚点在 pen 应用首次保存（`osascript` Cmd+S，见 plan-uiux）前是 0 字节——这不是 bug，是预期形态。

## 第 2B'' 步：codex 护栏分发（⭐1.1.0 新增，可选）

主人声明用 **Codex CLI** 使用本项目时（或项目根已有 `.codex/`、主人主动提到 codex），补跑一次机械分发：

```
bash "$CLAUDE_PLUGIN_ROOT/scripts/init.sh" --codex
```

产物三件：`AGENTS.md → CLAUDE.md` 软链（宪法双端同源）｜`.codex/hooks.json + hooks/gate.sh`（plan-lock 写盘拦截）｜`.codex/agents/*.toml`（pm/architect/dev/qa/uiux 角色沙箱，唯一源 `agents/*.md` 的生成物；重跑会清掉源已删除的旧角色 toml，如 1.8.0 删除的旧综合规划角色）。

告知主人两件事（一次性）：① codex 首跑会在 `/hooks` 要求审查信任 gate.sh，trust 一次生效；② codex 侧 plan 笼子用法 = 先 `/plan`（内建只读），或 `touch .cc_code/.runtime/plan-lock` 开护栏、出关 `rm`。⛔ 非.codex 用户不问不做（零打扰）。

## 写者分工与派发（2A / 2C 共用；⭐1.9.3）

> **主控只派不写。** 单一写者铁律的全文唯一出处 = `templates/Agent.md` §一（生成项目里的 `.cc_code/active/Agent.md` §一），本命令不复述，只列 init 里谁写哪个文件、按什么顺序派。

| 文件 | 唯一写者 | 派发顺序 |
| --- | --- | --- |
| `prd.md` / `ux.md` | **pm** | ① 先派 |
| `project.md` / `data.md` / `api.md` | **architect** | ② 再派 |
| `gates.md` / `bugs.md` | **qa** | ③ 最后派（无内容可迁则不派） |
| `status.md`、`backup/milestone-log.md` 行 | 主控 | 自己写 |
| `Agent.md` / 根 `CLAUDE.md` / `AGENTS.md` | init 脚本 | 机械覆盖，不派人 |

```
  主控（分拣 / 清点 / 派发 / 机械核对）
     │  任务说明 = 「读哪些文件 + 迁移要求 + 本轮要交回什么」（格式出处 Agent.md §五，不夹带主控的理解）
     ├─① pm        只收到：属于 prd / ux 的内容 ──► 写 prd.md / ux.md ──► 交回报告
     ├─② architect 只收到：属于 project / data / api 的内容 ──► 写 L3 三件 ──► 交回报告
     └─③ qa        只收到：属于 gates / bugs 的内容 ──► 写 gates.md / bugs.md ──► 交回报告
  ⛔ 严格串行，上一个交回才派下一个；每个 agent 只写自己的文件，别人的文件一个字不碰
  ⛔ subagent 不能问主人：拿不准的点写进报告交回主控，由主控交人
```

## 第 2A 步：Track A 旧 CLAUDE.md 分拆协议（理解力活，由各文件的写者 agent 完成）

仅 Track A 执行。读取 `.cc_code/backup/YYYY-MM/CLAUDE.md.legacy` 的只有主控，**主控只做「原文分拣」**：按下表把旧内容的段落**原文**（不改写、不总结、不丢）分到各层，然后按上一节顺序派写者落盘。

```
  A1 主控读 legacy 全文 ──► 按下表分拣：每段原文 → 一个目标文件（拿不准归 project.md 兜底）
        │                   并列一张「段落 → 去向」清单，每段必有着落
        ▼
  A2 派 pm         只收到分拣给它的 prd / ux 原文段落 + 模板路径 ──► 落 prd.md / ux.md
        ▼             （pm 不读旧 CLAUDE.md 全文，只看任务说明里这几段）
  A3 派 architect  只收到分拣给它的 project / data / api 原文段落 + 模板路径 ──► 落 L3 三件
        ▼
  A4 派 qa         只收到分拣给它的 gates / bugs 原文段落（有才派） ──► 落 gates.md / bugs.md
        ▼
  A5 主控自己写 status.md（进度类）与 milestone-log 行（历史类）
```

| 旧 CLAUDE.md 中的内容 | 目标文件 | 写者 | 归并方式 |
| --- | --- | --- | --- |
| 项目角色定义、权限规则、工作流约定、agent 路由 | `active/project.md` 的「特殊约束」 | architect | `Agent.md` 是插件规范文件（脚本已用模板新建），不再接收项目内容；项目差异一律写进 `project.md` |
| 业务规则、功能逻辑、模块职责、边界约束 | `active/prd.md` | pm | 按模块填入「核心规则 / 边界与异常」 |
| 验收标准、测试要求 | `active/prd.md` 的 §1.5 | pm | 填为**编号稳定**的验收断言（A1..An）；`gates.md` 只装实测结果，不装标准 |
| 技术栈、框架、语言、目录结构、编码原则（KISS/SOLID 等） | `active/project.md` | architect | 填入「技术栈概览 / 目录规约 / 特殊约束」 |
| 数据模型 interface、字段规则、DB 列对齐 | `active/data.md` | architect | 填入「Interface / 字段规则矩阵 / 原型↔真实切换 / DB 列对齐」 |
| API 路由、请求响应格式、错误码 | `active/api.md` | architect | 按模块填入接口契约 + 状态标记 |
| 当前进度、待办、卡点、正在做的模块 | `active/status.md` | 主控 | 填入「当前坐标 / 下一步目标」 |
| 历史变更、版本记录、里程碑 | `backup/milestone-log.md` | 主控 | 按 `Agent.md` 归档规范逐条追加流水行；全文已在 `CLAUDE.md.legacy` 快照留档；⛔ 不落 `active/status.md` |
| 已知 bug、待修清单 | `active/gates.md`（需要时同步 `bugs.md`） | qa | 填入 Critical / Minor Failures |
| 用户交互流程、页面状态机、UI 规格、组件清单、响应式规则 | `active/ux.md` | pm | 填入「全局设计系统 / 逐页布局 + 五态矩阵」 |
| 无法归类的杂项 / 项目背景 | `active/project.md` 的「特殊约束」 | architect | 兜底，绝不丢弃 |

铁律：分拣时每一段信息都要有着落，拿不准的归 `project.md` 兜底；落盘完成后主控用机械方式核对「段落 → 去向」清单无遗漏（清单里无「待定」行）；旧 `CLAUDE.md` 已被入口模板覆盖，无须保留原状。
**路径联动**：若 legacy 内容引用了被迁移的旧文件名（如 `PRODUCT_SPEC_V2.md`），主控把 `backup/YYYY-MM/migration_manifest.md` 里对应的映射行一并写进任务说明，由写者落盘时把原文里的旧路径改写为新相对路径（如 `.cc_code/docs/PRODUCT_SPEC_V2.md`）。

## 第 2C 步：Track D 升级迁移协议（理解力活，由各文件的写者 agent 完成）

仅 Track D 执行。**⛔ 全程零删除铁律：`init.sh` 里没有一句 `rm`。旧物只会被 `cp` 快照与 `mv` 归位，内容永远可回溯。**
**⛔ 主控全程不 Edit / Write 任何角色文件**：D3 ~ D5 按「写者分工与派发」逐文件派写者，每个 agent 只收到「自己文件的旧快照路径 + 对应模板路径 + 迁移要求」，只写自己的文件；先 pm、后 architect、再 qa；status 主控自己写。

```
D1 归档快照   脚本已做：cp active/ + .cc_code 根层 md
              → backup/YYYY-MM/pre-upgrade-<旧版>/    ← 只读后悔药
              原位一个字未动，active/ 全程可用，中断也不瘸
     ▼
D1.5 规范文件 脚本已做：Agent.md / 根 CLAUDE.md / AGENTS.md 先快照进 spec/，
              再机械覆盖为插件模板新版（项目不自定义 Agent.md 权限）
     ▼
D2 清点       脚本已做：→ backup/YYYY-MM/upgrade_audit.md（四类差异表）
              并对缺失的角色文件补建模板空骨架（已存在的一个字不动）
     ▼
D3 迁移       ⭐写者 agent：读 audit → 按层判据把内容搬到规范位，一段不丢
     ▼
D4 补层       ⭐写者 agent：按 templates/ 骨架补齐自己文件的缺失段
     ▼
D5 ⛔校验门   ⭐各写者自检交回 → 主控只跑机械检查（grep / 计数 / cmp），未全命中即停手报清单，禁止归位
     ▼
D6 归位       脚本机械动作：init.sh --relocate（mv 进 superseded/，零删除）
     ▼
D7 盖戳       脚本机械动作：init.sh --stamp（仅校验全过才允许）
```

### D3 迁移映射表（按 audit 的四类分别处置；动作由对应文件的写者执行）

| audit 类别 | 判据 | 迁移动作 |
| --- | --- | --- |
| ① 规范位缺失 | `active/<canon>.md` 不存在 | 脚本已按 `templates/` 补建空骨架（只补缺的）；该文件的写者再找同层等价物（见下表）迁入填充；确实没有则保持骨架；`status.md` 由主控填 |
| ② 位置偏离 | 规范文件躺在 `.cc_code/` 根层 | 内容整体由写者迁入 `active/<同名>`；原件留待 D6 归位 |
| ③ 规范外多余 | 文件名不在规范 8 之列 | 主控按下表**整文件分拣**（只分派快照路径，不改写不摘抄），写者按下表归并；**兜底 `project.md` 的「特殊约束」，绝不丢弃** |
| ④ 规范位已就位 | 位置对 | ⚠️ **位置对不代表格式对** —— 转 D4 做骨架格式体检（0.9.0 起 7 个角色文件全检；`Agent.md` 由脚本覆盖，不在此列） |

**规范外文件的归并判据（按内容性质，不看文件名）：**

| 旧文件典型内容 | 归并目标 | 层 | 写者 |
| --- | --- | --- | --- |
| 交互流程 / 页面状态机 / 五态矩阵 | `active/ux.md` 五态矩阵段 | L2 | pm |
| 视觉规格 / 逐页布局 / 组件清单 / i18n key | `active/ux.md` 视觉规格段 | L2 | pm |
| 业务规则 / 模块职责 / 验收标准 | `active/prd.md` | L1 | pm |
| 阶段实现方案 / 任务拆分 | `active/project.md` 对应章节 | L3 | architect |
| 历史变更 / 版本记录 / 里程碑 | `backup/milestone-log.md` 逐条追加（格式见 `Agent.md` 归档规范），全文留在 D1 快照 | — | 主控 |
| 踩坑记录（`errors.md`，**0.5.0 已废除**） | 不并入 active/；D1 快照已存档，在 `project.md` 特殊约束留一行指针 | — | architect |
| 数据模型 / 字段规则 | `active/data.md` | L3 | architect |
| 接口 / 错误码 | `active/api.md` | L3 | architect |
| 旧 `Agent.md`（D1 快照）里模板没有的项目自定义段（如角色权限自定义） | `active/project.md` 特殊约束（原文并入；`Agent.md` 本体已被模板覆盖） | L3 | architect |
| 无法归类 | `active/project.md` 特殊约束（兜底） | L3 | architect |

> ⚠️ **拆分偏离**（旧版把 L2 拆成多个文件，如 `flow.md` + `front.md`）→ 按上表两行分别并入同一个 `ux.md` 的不同段落，**不是二选一，是都要**（同一份快照路径可同时给多个写者，各取自己层的内容）。
> ⚠️ 断言编号迁移时**永久稳定**：旧编号原样保留，绝不重排、绝不复用。遇到已作废条目（含旧版的删除线条目）→ pm 原文整行搬 `backup/retired/prd.md`，⛔ 不留在 active（规则见 `Agent.md` §四第 5 条）。若旧版另起了字母段（如 `B1..Bn`），**写者在报告里交回主控报告主人由其定夺**沿用还是归正，写者不擅自改。

### D4 补层：7 个角色文件骨架格式体检（⭐0.9.0 扩容）

> ⚠️ **0.8.0 及以前只体检 `Agent.md`，另外 7 个文件「只要在 active/ 里就算 OK」** —— 内部是旧格式还是新格式无人过问。
> 后果：`gates.md` 停在旧的逐轮流水格式、`ux.md` 缺 `U` 编号，盖戳后判 Track C 更不体检，**旧格式永久留存、永无自愈机会**。
> 0.9.0 起：**逐个比对规范文件 ⟷ `templates/` 对应模板的骨架**。1.9.3 起 `Agent.md` 由脚本机械覆盖为模板新版，不再由 AI 体检 / 补段；其余 7 个文件各由自己的写者体检。

```
for 每个规范文件 X ∈ {status prd ux project data api gates}（由 X 的写者自己做）:
  ├─ 取 templates/X.md 的「骨架」= 全部 ## / ### 标题 + 关键表头 + 纪律段
  ├─ 检 active/X.md 是否具备该骨架
  │    ├─ 具备 → 过
  │    └─ 缺失 → ⭐补齐骨架，并把项目原有内容按语义**填入对应段**
  │              （项目已填内容原位保留，只在缺失处补骨架）
  └─ 项目有、模板没有的段落 → 判性质：
       ├─ 过程性 / 历史性（「第 N 轮回归」「增量 F-n」「迁移清单」「漂移登记」）
       │    → 迁冷归档（qa 报告去 docs/qa/，方案与裁决去 backup/YYYY-MM/）
       │      并在 `backup/change-log.md` 追加一行指针（⛔ 不在 active 文件内留台账）
       └─ 项目自定义业务内容 → 原样保留（不擅自删、不擅自搬）
```

**⛔ 零删除铁律照旧**：一律 `cp` / `mv`，无 `rm`。D1 快照是回滚点。

**各文件必检骨架项**（缺了会怎样）：

| 文件 | 写者 | 必检骨架 | 缺了会怎样 |
| --- | --- | --- | --- |
| `prd.md` | pm | §1.5 验收断言**主表** · 写入纪律段 | 断言散落各处，QA 拿不全尺子 |
| `ux.md` | pm | §2.3 `U` 编号五态矩阵 · §2.4 元素清单（含序号 / 适用态列）· 写入纪律段 | **UI/五态无判定编号 → gates 无法逐条溯源，覆盖率是黑洞** |
| `gates.md` | qa | §二 验收追溯矩阵（`A` 段 + `U` 段）· §六 四分母覆盖率 · 写入纪律段 | **退化成逐轮流水日志，「某断言现在什么状态」要跨 N 轮 grep** |
| `api.md` | architect | 写入纪律段 | 同一 path 散成 N 段补丁，Dev 得脑内拼接 |
| `data.md` | architect | 写入纪律段 | 同一张表散成主体 + N 个扩展段 |
| `project.md` | architect | 写入纪律段 | 架构决策堆积历史 |
| `status.md` | 主控 | 当前坐标 · 卡点 · 下一步；旧版残留的「当前激活角色」行清掉，「当前执行阶段」行改名「当前流程 / 步骤」（它是主控记录的坐标，不是角色） | 坐标丢失，AI 发散 |

#### D4.1 存量归位（旧格式 → 新骨架，一次性）

体检发现下列形态时，按表归位（**内容零删除，只换位置**；动作由「谁做」列的写者执行）：

| 发现的旧形态 | 谁做 | 归位动作 |
| --- | --- | --- |
| 任意 active 文件有 `## 增量 F-n` 章节 | 该文件的写者 | 章节内的**当前态规格**就地合并进对应小节（同 interface / 同 path / 同模块 / 同页面合成一段）；**过程性内容**（需求清单 / 冲突收敛表 / 漂移登记 / 迁移清单）迁 `backup/YYYY-MM/`（冷归档）；`backup/change-log.md` 补一行 |
| `prd.md` 断言散在多个增量小节 | pm | 全部**并回 §1.5 主表**（编号原样，禁重排）；原小节的过程内容迁 `backup/YYYY-MM/`（冷归档） |
| `gates.md` 有「第 N 轮回归 / 第 N 轮验收」章节 | qa | 各轮详情迁 `docs/qa/<日期>-round-N.md`，原文整段搬 `backup/retired/gates.md`；结果**汇总进 §二 追溯矩阵**（每断言一行，取最新一轮结论），章节从 active 移除 |
| active 文件文末有「附录 / 变更台账」章节 | 该文件的写者 | 台账行逐条迁 `backup/change-log.md`（格式见 `Agent.md` 归档规范），删除该附录章节；详情列指向旧 `docs/plans/` 的改指 `backup/change-log.md` 同 F 号行 |
| `ux.md` 五态矩阵无 `U` 编号 | pm | 按 `U<页章号>.<元素序>.<态>` 补编号（**首次发号即永久固定**）；报告里交回本次发号范围，由主控报主人 |
| `api.md` / `data.md` 混入验收断言 | architect → pm → architect | architect 先把混入的断言**原文**清单交回；主控原样转交 pm（pm 不读 L3，只看这份清单）确认 `prd.md` 确有对应断言，**没有则 pm 先补进主表**；pm 交回后，主控续接 architect 删除 `api.md` / `data.md` 里的副本（`prd.md` §1.5 是唯一源） |

> ⛔ 归位量大时（如 `gates.md` 数百行流水），**写者先交回清单，主控报主人，逐文件请示后再动手**，禁止一次性批量重写。

#### D4.2 Agent.md 规范段 → 脚本机械覆盖（⭐1.9.3 改）

`Agent.md` 是插件规范文件，唯一写者 = init 脚本：D1.5 已把它整份覆盖为 `templates/Agent.md`（旧版快照在 `backup/YYYY-MM/pre-upgrade-<旧版>/spec/Agent.md`）。**不再逐段比对、不再由 AI 补段**——旧版里模板没有的项目差异，已在 D3 交 architect 并入 `project.md` 特殊约束。

主控的机械核对：`cmp active/Agent.md "$CLAUDE_PLUGIN_ROOT/templates/Agent.md"` 无差异；旧 `status.md` 里「当前激活角色」行的清理属 `status.md`（主控自己的文件），见上表。

### D5 校验门（⛔ 未过禁止进 D6）

**各写者先对自己的文件自检、把结果写进报告交回；主控只汇总清单与跑机械检查（grep / 计数 / cmp），不改任何文件。**

**校验一：内容不丢**

```
各写者逐条核对 D1 快照里属于自己文件的每个旧文件的每一节：
  ├─ 在新规范位找到对应内容？
  │    ├─ 是 → 记入迁移映射表
  │    └─ 否 → 记入「未着落清单」
  └─ 主控汇总各写者的未着落清单；非空
       ⛔ 停手：报清单给主人，禁止调 --relocate、禁止调 --stamp
       → 主人裁决每一条（补迁 / 确认可弃 / 延后）后才放行
         （补迁 = 续接对应写者去补，主控不自己补）
```

**校验二：骨架完备**（⭐0.9.0 新增，与校验一同为硬门）

```
各写者逐个核对自己文件的 D4 骨架清单：
  ├─ templates/X.md 的每个 ## / ### 标题与关键表头，在 active/X.md 都能检索到？
  │    ├─ 是 → 过
  │    └─ 否 → 记入「骨架缺失清单」
  └─ 主控汇总；骨架缺失清单非空
       ⛔ 停手：报清单给主人，禁止盖戳
       → 这一门专治「文件在位置上、格式却停在旧版」（0.8.0 及以前 gates.md 的典型病灶）
```

辅助校验（主控机械跑，只读）：新规范位文件字节数 ≥ 对应旧文件之和的合理比例；旧文件的每个 `## ` 标题都能在新位置检索到；`grep -c '## 增量 F-' active/*.md` 应为 0（增量章节已就地收敛）；`cmp active/Agent.md` 与模板一致。

### D6 归位（零删除的「清理」，脚本机械动作）

```bash
bash "$CLAUDE_PLUGIN_ROOT/scripts/init.sh" --relocate \
     active/<已迁移的旧文件> ... <根层冗余.md> ...
```

| 类别 | 举例 | 归位么 |
| --- | --- | --- |
| 位置偏离的原件 | `prd.md`（已迁入 `active/`） | ✅ 归位 |
| 拆分偏离的分片 | `flow.md` `front.md`（已并入 `ux.md`） | ✅ 归位 |
| 规范外已归并 | `plan.md` `changelog.md` `index.md` | ✅ 归位 |
| 规范外已废除 | `errors.md` | ✅ 归位（内容在 D1 快照 + superseded） |
| 规范 8 文件本体 | `active/prd.md` 等 | ❌ 脚本会**拒绝**，绝不归位 |
| `backup/` | 全部 | ❌ 绝不动，冷数据是最后防线 |
| `references/` | 全部 | ❌ 经验资料库，绝不动（0.8.0 起脚本 D2 自动补建） |
| `docs/` `images/` `scripts/` `tests/` | 全部 | ❌ 只在报告里清点，交主人处置 |
| 项目源码 / 测试目录 | `src/` 等 | ❌ Dev 域，绝不碰 |

### D7 盖戳 + 报告（脚本机械动作）

```bash
bash "$CLAUDE_PLUGIN_ROOT/scripts/init.sh" --stamp
```

最后向主人报三张表：**迁移映射表**（旧位 → 新位 → 校验结果）、**归位清单**（原位 → `superseded/`）、**未着落清单**（应为空）。并注明 D1 快照位置作为回滚点。

## 第 3 步：进入状态机循环

1. Read 根目录 `CLAUDE.md` → 按其「会话开启协议」执行。
2. Read `.cc_code/active/Agent.md` → 读文件路由权限表（角色 = 被派出的 agent，Agent.md 不再有「当前激活角色」字段）。
3. Read `.cc_code/active/status.md` → 同步坐标。
4. 按 `cc-code` skill 协议持续约束后续行为（热数据由各文件的唯一写者写，主控只写自己的文件，见 `Agent.md` §一 / §二）。
