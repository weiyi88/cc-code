# cc-code 架构说明

## 双层清单（参考 claude-seo marketplace 模式）

- `.claude-plugin/marketplace.json` — marketplace 元数据 + plugins 列表，供 `/plugin marketplace add` 消费。
- `.claude-plugin/plugin.json` — 单插件清单，声明 name/version/author。

两者并存：marketplace.json 让仓库可作为「插件市场」被添加，plugin.json 描述插件本身。

## 资产分布

```
skills/      17 个目录  → /cc-code:<name> 显式调用 或 自然语言自动触发
agents/       6 个 .md → pm / architect / dev / qa / uiux / curator（角色 = agent：主控只编排、派谁谁就是当前角色；uiux 为 L2 双文件写者，只在规划侧出场；curator 为经验整理 agent，后台静默，是经验库唯一写者）
hooks/        hooks.json + curator-reminder.sh（唯一的 Stop hook：经验整理保底提醒，只比时间戳，不调 AI、不联网）
scripts/     init.sh + sync-codex.sh（codex 生成器）+ verify-codex.sh（codex 漂移校验）
templates/   10 个 .md 骨架（L0~L4 九件 + bugs.md debug 施工便签）+ references-INDEX.md（init 时 cp 进 .cc_code/references/）+ references-example-async-queue.md（主题文件写法范本，不拷贝）
assets/codex/  codex 侧生成物与分发源（hooks 模板 + agents toml）→ init.sh --codex 落用户项目
```

> 历史沿革：早期版本有 `commands/` 目录，现已全部并入 `skills/`。
> 0.5.0 起删除 `hooks/`（Stop Hook 机制废除）与 `templates/errors.md` —— 所有 `.cc_code/` 文件由 AI 顺手写，无自动化机械活。
> 1.1.0 起 `assets/codex/` 回归 hooks —— 性质不同：0.5.0 删的是「自动写文件」的机械活，1.1.0 加的是「拦写操作」的守门护栏。
> 1.10.0 起重新引入**唯一的 Stop hook**（`hooks/`，经验整理保底：只比 `gates.md` 与 curator 开工时间戳，不调 AI、不联网、同一次改动最多提醒一次）；0.5.0 的废除沿革保留，该 hook 不写任何文件内容。
> 1.11.0 起新增**前端与视觉子系统**：`plan-uiux` ⇄ `agent-uiux` 一对新命令、`templates/design.md`、四份共用参考（`ui-gates` / `frontend-forms` / `dev-qa-loop` / `assertions`，后者由 agent-whole-qa 参考迁址）；pen 主链降级为方向卡可选介质。
> 1.12.0 起新增**交付命令** `pr`（与 `deploy` 同为出口命令，配 `skills/pr/references/mr-template.md` 格式唯一出处）；主控的唯一显式例外改称「版本库操作」，交付只限该命令内；qa 新增「提交证据」一节。外部审查平台与 cc-code 的边界：pr 是唯一出口，打回与线上 bug 照常走 debug / feature 链。
> 1.13.0 起 **plan 批准后自动开工**：`agent-mvp` / `agent-feature` / `agent-debug` / `agent-uiux` 四个执行命令去掉触发闸门，由对应 plan 命令在批准（或「定了」）后直接调起；没批准的规划由执行命令自己的入口检查拒跑。plan / 出口（`deploy` / `pr`）/ `just-do-it` / `init` / `agent-whole-qa` 等其余命令闸门不变。Codex 侧 plan 结束不再回锁，放开给执行命令写盘。
> 1.14.0 起 **执行命令运行中零提问**：plan-mvp / plan-feature 收尾加「开工前断言体检」（编排 = `templates/Agent.md` §五，判据 = `agents/qa.md`），缺口趁主人在场问完才开工；agent-* 运行中的规格缺口一律挂起（不问、不发明，其余照跑），结尾一份交人报告附下一步命令与可直接粘贴的完整 prompt（单一出处 = `skills/cc-code/references/dev-qa-loop.md` §九；能自己定 / 必须挂起的分界只在 `agents/dev.md`）。

## Codex 适配生成链（1.1.0）

**SSOT 纪律**：`skills/` `agents/` `.claude-plugin/` 是唯一源；一切 codex 侧文件是生成物，禁手改。

```
   唯一源(人改)                        生成物(sync-codex.sh 产出)          校验(verify-codex.sh)
   ────────────                        ──────────────────────────          ─────────────────────
   .claude-plugin/plugin.json    ──► .codex-plugin/plugin.json          ┐
   .claude-plugin/marketplace.json ► .agents/plugins/marketplace.json   │
   skills/*/SKILL.md frontmatter ──► skills/*/agents/openai.yaml        ├─ 快照→重生成→diff,
   agents/*.md                   ──► assets/codex/agents/*.toml         ┘   漂移即 FAIL exit 1
   templates/CLAUDE.md           ──► templates/AGENTS.md(软链)
```

映射规则：`disable-model-invocation: true` → `allow_implicit_invocation: false`，无闸门的命令 → `allow_implicit_invocation: true`（显式写出）；model 档位 haiku/sonnet/opus → gpt-5.3-codex-spark / gpt-5.4-mini / gpt-5.4(+effort high)，`inherit` 不写 model 行（继承父会话；本版不重设计 Codex 模型映射）。uiux 自 1.11.0 起为 **opus** 档（L2 双文件 + 方向卡与样板板），Codex 侧即 gpt-5.4 + effort high。角色沙箱 pm/architect/dev/qa/uiux/curator 六个一律 workspace-write（都要落盘）。源 `agents/*.md` 删除后，sync 清掉对应旧 toml，`init.sh --codex` 也会把用户项目里残留的旧 toml 搬走（零 rm）。

**闸门覆盖（1.11.0，1.13.0 修订）**：除协议体 `cc-code` 外，每个命令都必须在 frontmatter 显式声明 `disable-model-invocation: true`，并由 sync 生成 `skills/<name>/agents/openai.yaml`；唯一例外是 `verify-codex.sh` 里 `GATE_OPEN` 登记的四个执行命令（`agent-mvp` / `agent-feature` / `agent-debug` / `agent-uiux`）——它们必须**没有**闸门、Codex 配置必须放开隐式调用。`verify-codex.sh` 逐个命令核对，不符即 FAIL —— 漏写闸门会让 Codex 端可被隐式调用，误放开名单外的命令同样拦下。

**codex 插件不分发 custom agents 与 hooks** → 由 `init.sh --codex` 落盘到用户项目 `.codex/`（AGENTS.md 软链 + gate.sh plan 护栏 + agents toml）。plan 笼子全自动：plan-mvp / plan-feature 首行「引擎分支」条款（plan-debug 不进 plan 模式，不开护栏）让 AI 自查有无 `EnterPlanMode`——Claude 走原路，Codex 自己 `touch plan-lock` 开护栏（1.1.1 起，用户零额外操作）；另可敲内建 `/plan` 双层加固；`--yolo` 亦不可击穿（实测 0.149.0）。

## 寻址约定

- 插件内文件引用统一用 `$CLAUDE_PLUGIN_ROOT/...`。
- skill 内部配套文件用相对路径（如 `agent-whole-qa` 的 `references/*.md`）。

## 前端与视觉子系统（1.11.0）

> 目标：生成项目的前端**剔除 AI 味、有格调、视觉对齐**（元素在栅格、边缘、基线、间距上对整齐）。
> 基本单位是**项目**：一个项目可含网页 / 移动 / 后台多端，只用一个组件库家族、各端用家族对应版本、全项目一份 `design.md`，数值灌进各端主题。

### 五段链路

```
 pm ──► uiux ──► architect ──► dev ──► qa
(推断端与形态) (ux.md + design.md) (家族与视觉基建契约) (生成主题/实现页面) (视觉第四层)
   │           │                     │                     │                  │
 prd.md    L2 双文件             project.md §一.1/§六/§九   主题文件是生成物      V 段 + 基线 + 合集板
          （只在规划侧）          （不读 design.md）        （禁手改）          （唯一写判词的人）
```

| 边界 | 唯一出处 |
| :--- | :--- |
| 十种形态、默认栈、家族决策、三旋钮、翻译表 | 插件 `skills/cc-code/references/frontend-forms.md` |
| 视觉判词、规则号、阈值、允许值集合、基线纪律、`gates.md` V 段写法 | 插件 `skills/cc-code/references/ui-gates.md` |
| 一轮定义、按失败项计轮、≤3 轮、升级包、任务单最小字段 | 插件 `skills/cc-code/references/dev-qa-loop.md` |
| 页面 / 五态 / 断点 / 转场的断言写法 | 插件 `skills/cc-code/references/assertions.md`（1.11.0 起从 agent-whole-qa 迁址，语义未变） |
| 设计规格章节 | `templates/design.md`（生成项目 `.cc_code/active/design.md`） |

### 两个模式与一个视觉门

```
 plan-uiux（人参与）                              agent-uiux（纯机器）
 ─────────────────                              ────────────────
 模式一 定风格：方向卡（有条件）→ design.md 草稿    只接「风格：已定未实现」
        → 风格样板板 → 自检 → 主人「定了」→ 锁定     dev 重生成主题 + 调长相布局
 模式二 改版：qa 现状体检 → 目标 design.md          qa 全量五态回归 + 全页视觉 + 基线对比
        → 改前改后对照样板板 →「定了」→ 改版待实现   ≤3 轮；PASS 后冻结新基线
```

- **唯一视觉门 = 主人说「定了」**；`design.md` §0 状态四值（草稿 / 已锁定 / 改版待实现 / 不适用（无前端））与 `status.md`「风格：」五值一一对应（对应关系只写在 `templates/design.md` §0.2）。
- **uiux 只在规划侧**：`plan-mvp` / `plan-feature` / `plan-uiux` 派它，任何 `agent-*` 都不派。风格落地由 dev 执行，改版落地由 `agent-uiux` 执行，验收由 qa 执行。
- **执行器的开工视觉门按阶段判定**：本阶段涉及页面且 `design.md` 未锁 → 拒跑；纯后端 / 无 UI 阶段放行并标「不适用」；老项目冷启动只豁免一次。
- **三个检查时机**（名称固定）：现状体检（qa，模式二）／锁定前（uiux 自检；agent-mvp 视觉地基 qa 复核）／开发后（qa，各执行命令）。真正的视觉判词从「锁定前 · 复核」开始。
- **pen 降级**：旧 `design.pen` 只作方向卡可选介质，**原地保留、不读不写不转换**；「加密禁读 / osascript 保存 / pen 底稿三步 / pen 导出格式」全部退役。

### 视觉地基与基线

- `project.md` §九 首个阶段固定为**视觉地基**：主题入口 + 全局框架 + 组件陈列页（不上线路由）；业务页面泳道在视觉门过之前不开工。
- 视觉测试 `.cc_code/test/visual/`、截图基线 `.cc_code/test/visual/baseline/`、允许值集合：**qa 独占写、入 git**；`init.sh` 只建目录并写忽略注释，⛔ 不许用 `*.png` / `screenshots/` 全局通配忽略截图。
- 运行时视觉检查（浏览器层）只在 qa 与并行泳道的**汇合回归**跑；泳道内 qa 只回逻辑层报告。

---

## 状态机

详见 `skills/cc-code/SKILL.md`。核心：所有 `.cc_code/` 文件都由 AI 在对话内顺手写（需理解力），无自动化机械活。`status.md` 只答坐标 / 卡点 / 下一步，长度恒定一屏；里程碑一律落 `backup/milestone-log.md`。

## 规则归属：单一出处（SSOT）分层 — 0.13.1 立规

> **铁律：规则只写在「受众的必经之路」上，且只写一次。**
> 副本是漂移的必要条件 —— 同一条规则一旦存在 N 份，改的时候必然漏改几份，
> 而提示词库**没有测试也没有 CI**，漂移不会报错，只能靠人肉 grep 发现。
> 所以治理方向永远是**删副本**，不是**补副本**。

一条新规则诞生时，按三问定位唯一出处：

```
   ① 换个角色还成立吗？
        ├─ 成立   ──────► templates/Agent.md §四 强制执行协议（全员通用区）
        └─ 不成立 ──────► templates/Agent.md §三 对应那张角色卡
   ② pm / architect / dev / qa / uiux / curator 这六个 agent 需要吗？
        └─ 需要   ──────► 追加写进 agents/{pm,architect,dev,qa,uiux,curator}.md
                          （subagent 独立上下文，读不到 Agent.md，
                            自带系统提示词才是它的必经之路 → 不算副本）
   ③ 约束的是「产物长什么样」吗？
        └─ 是     ──────► 写进该文件的模板头部（gates.md / prd.md 等）
   ⛔ 任何情况都不写进 skills/*/SKILL.md 正文
```

| 规则性质 | 唯一出处 | 覆盖谁 | 传导机制 |
| :--- | :--- | :--- | :--- |
| 全员行为 / 输出条款 | `templates/Agent.md` §四 | 所有角色 + 编排器主控 | 校准协议必读 `Agent.md` |
| 角色专属权限 / 能力 | `templates/Agent.md` §三 角色卡（角色权限只写这一处，其他地方一句指针） | 该角色 | 角色 = 被派出的 agent，各 agent 只读到自己那一张 |
| subagent 自带纪律 | `agents/{pm,architect,dev,qa,uiux,curator}.md` | 该 subagent | 系统提示词 |
| 产物格式纪律 | 该文件模板头部 | 写它的角色 | 写前必读该文件 |
| 编排纪律（串行 / ≤3 轮 / 拒跑 / 增量定位） | `skills/*/SKILL.md` 正文 | 编排器主控自己 | 命令本体 |
| 多个执行器共用的编排纪律（并行泳道） | `skills/cc-code/references/parallel-lanes.md` | agent-mvp / agent-feature / agent-uiux / agent-whole-qa 主控 | 执行器正文一行指针，⛔ 不复述 |
| 前端视觉判词 / 规则号 / 阈值 / 允许值集合 / 基线纪律 / `gates.md` V 段写法（1.11.0） | `skills/cc-code/references/ui-gates.md` | pm / uiux / architect / dev / qa 与全部执行器 | 各文件一行指针，⛔ 不复述规则内容 |
| 十种形态 / 默认栈 / 家族决策 / 三旋钮 / 格调范式卡 / 灵感配额 / 片段五步 / 原话→数值翻译（1.11.0） | `skills/cc-code/references/frontend-forms.md` | pm / uiux / architect / dev / qa | 各文件一行指针 |
| 开发 → 测试循环协议（一轮定义 / 按失败项计轮 / ≤3 轮 / 升级包 / 任务单字段）（1.11.0） | `skills/cc-code/references/dev-qa-loop.md` | 各执行器主控 / dev / qa | 执行器一行指针 |
| 页面五态 / 元素 9 类 / 接口 5 类 / 全局断言（1.11.0 从 agent-whole-qa 参考迁入共享参考，语义未变） | `skills/cc-code/references/assertions.md` | qa / dev | agent-whole-qa 内的旧位置退役，其余命令引用新路径 |
| 触发闸门 | frontmatter `disable-model-invocation` | Claude Code 引擎 | 引擎强制 |

**角色隔离靠「角色 = agent」（独立上下文），不靠开关、也不靠拆文件** —— 主控是编排者、不扮演任何角色，
只传话与写 status；每个角色在自己的 agent 里干活，别的角色的规则一个字都不会污染它。

### 触发闸门只认 frontmatter

`disable-model-invocation: true` 是唯一有效的「禁止模型自动调用」闸门。
正文里写「本命令仅由用户显式触发」**零作用** —— 正文的读者是**已经被调用起来的模型**，
它都跑起来了，再告诉它「你只能被手动调用」毫无意义。
⛔ 故正文不复述触发方式；闸门只在 frontmatter 声明一次。

### codegraph 的两条通道（别再往 allowed-tools 里加不存在的名字）

```
   codegraph status --json / affected / node / callers / impact / files
        └──► CLI 子命令，走 Bash ──► allowed-tools 只需 Bash

   自然语言问「X 怎么工作」
        └──► MCP 工具 ──────────► mcp__codegraph__codegraph_explore
```

codegraph MCP server **只暴露 `codegraph_explore` 一个工具**。
`codegraph_search` / `codegraph_node` / `codegraph_callers` **不是 MCP 工具**，
写进 `allowed-tools` 是死声明：不报错、不生效、只误导后续读者。

## 并行泳道（1.6.0）

> 串行锁的是角色顺序与派活顺序，不是「同一角色只能派一个人」。dashboard 的「进行中只放 1 张卡」是**卡片级**串行，泳道只在一张卡内部。

| 部件 | 唯一出处 | 写者 / 读者 |
| :--- | :--- | :--- |
| 泳道表格式 + 四条拆分铁律 | `templates/project.md` §九 表头 | Architect 写（plan-mvp / plan-feature）· 执行器只读 |
| 栅栏 / 体检 / 退回 / 汇合回归 / 写回纪律 | `skills/cc-code/references/parallel-lanes.md` | 三个执行器主控 |
| dev 泳道纪律（只准写 / 自检范围 / 文件清单列全） | `agents/dev.md`「泳道模式」 | dev subagent |
| qa 泳道纪律（断言范围 / 不跑浏览器层 / 只回报告 / 运行时视觉检查只在汇合回归） | `agents/qa.md`「泳道模式」 | qa subagent |
| whole-qa fan-out 的 Workflow 脚本 | `skills/agent-whole-qa/references/whole-qa.workflow.js` | agent-whole-qa 主控传 args · Workflow 引擎执行 |

```
 §九 没写泳道 / 体检不过 ──► 单线程（1.5.x 行为，老项目零影响）
 体检通过              ──► 地基 → 同层泳道 Dev 并发 → 栅栏 → QA 并发 → 栅栏
                           → 没过的泳道单独退回 → 全过后汇合回归 → 阶段结算
```

> 选型：栅栏同步（不选各泳道各跑各的，后者会让进度坐标与写者出现多头）；同一工作区 + 只准写边界（不选每泳道一个 git worktree，免合并步骤；冲突多了再升级）。`agent-debug` / `just-do-it` 不并行。`agent-whole-qa` 按功能模块 fan-out，不读 §九；泳道只服务 `agent-mvp` / `agent-feature` / `agent-uiux`（运行时视觉检查只在汇合回归跑）。

## 散落物迁移（init.sh 的判定链）

```
项目根文件 ──► ① 保护白名单？ ──► ② git 已追踪？ ──► ③ 被引用？ ──► ④ 名字像临时物？
                 (任一命中即 SKIP)                              (才搬)
                                                                  ↓ 都不匹配
                                                              原地保留 + 记 needs_review.md
```

旧版「默认搬走 + 排除两个已知文件」会误杀 `setup.py`/`manage.py`/`AGENTS.md`/`build.sh` 等基建 —— 已反转为「默认不动」。

## 场域版本戳与三轨升级

`.cc_code/.cc_code_version` 记录场域形态对应的插件版本，是 `init` 的分流判据：

```
active/Agent.md 存在？
  ├─ 否 ────────────────► Track A/B 新建 + 盖戳
  └─ 是 → 读版本戳
        ├─ == 插件版本 ──► Track C 已最新，只搬散落物
        └─ 缺失 / 更旧 ──► Track D 升级迁移
```

Track D 的顺序是 **归档 → 清点 → 迁移 → 校验 → 归位 → 盖戳**：

```
D1 cp 快照 → backup/YYYY-MM/pre-upgrade-<旧版>/   原位不动，中断不瘸
D2 机械清点 → upgrade_audit.md（四类差异 + 前端与视觉探测）
D3 按文件派写者迁移（prd→pm；ux/design→uiux；project/data/api→architect；gates/bugs→qa）  理解力活
D4 各写者按 templates/ 骨架补段（Agent.md / CLAUDE.md / AGENTS.md 已由脚本机械覆盖）
D5 ⛔校验门：未着落清单 / 骨架缺失清单非空即停手
D6 mv 归位 → backup/YYYY-MM/superseded/
D7 盖戳（未过 D5 不许盖）
```

### 为何不裸删

`init.sh` 中 `rm` 出现 0 次。删除会让「迁移有 bug」等价于「用户数据蒸发」，
而 `mv` 让最坏情况退化为「文件位置不对，内容还在」。
配合 D1 只读快照，同一份内容有两处副本，D5 校验门再挡一层。

**戳未盖 = 迁移未完成。** 半成品不会被下次 `init` 误认为已完成 —— 这是幂等性与
「进度必须可信」的交点。
