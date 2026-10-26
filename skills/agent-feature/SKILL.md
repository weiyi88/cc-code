---
name: agent-feature
description: 只写新功能涉及的代码，只跑相关测试，又快又稳；有泳道则同角色并发
allowed-tools: Read, Write, Edit, Bash, Glob, Grep, Agent, TaskCreate, TaskUpdate, TaskList, mcp__codegraph__codegraph_explore
disable-model-invocation: true
---

# agent-feature — 双 agent × cc-code 驱动功能增量执行编排器

> **纯执行器**：只执行增量需求，**不规划**。需求与契约由 `/cc-code:plan-feature` 商讨定稿落盘，本命令读定稿文档直接开发，**中途零确认**，只在 3 轮仍 FAIL、或 dev 撞上需求 / 契约冲突时交人。
> **主控是编排者，不扮演任何角色**：派哪个 agent 就是哪个角色，角色权限唯一出处 = `active/Agent.md` §三；主控的写权限见 `active/Agent.md` §一，⛔ 不写 `gates.md` 与 L1~L3 文件。
> **增量铁律**：只做「规划了但还没验过」的断言，绝不重推存量需求、绝不重做已 PASS 项。
> **与 agent-mvp 的分工**：mvp 是「盖整栋楼」（含 agent-whole-qa 全量清算收口）；feature 是「在楼里加一个房间」（affected 精准回归，无全量清算）。
> **视觉门**：与 `agent-mvp` 完全同一套（判据唯一出处 = `skills/agent-mvp/SKILL.md` 前置检查第 7 条），本命令不另立判据、不另设豁免。⛔ 本命令不派 uiux。
> **风格延用铁律**：新页只沿用已锁定的 `design.md` 数值 / 已锁组件 / 已知构图范式；⛔ 不现场发明新数值、新组件、新视觉母题——那属 `plan-uiux`（两档规则唯一出处 = `/cc-code:plan-feature` 命令正文）。
> **循环与视觉规则**：循环唯一出处 = `../cc-code/references/dev-qa-loop.md`；视觉规则与判词唯一出处 = `../cc-code/references/ui-gates.md`。
> **并行泳道（1.6.0）**：`project.md` §九 9.2 有本 F 号的泳道行 → 按 `../cc-code/references/parallel-lanes.md`（本 skill 目录的同级，插件内单一出处） 同一角色多人并发；没有 → 单线程照旧。

## 前置检查（启动时一次性）
1. 确认项目根存在 `.cc_code/`（否则提示先 `/cc-code:init`）。
2. 确认双 agent 可用：`dev` / `qa`（视觉层由 qa 执行；⛔ 不派 uiux）。
3. **增量定位（⭐第一动作，见下节）**——定位失败即拒跑，后续检查全免。
4. **视觉门（按本次增量判定）**：判据与 `agent-mvp` 前置检查第 7 条完全同一套，**先读 `status.md`「风格：」**（`design.md` §0 只在 status 缺失时兜底）——`已定未实现` → ⛔ 拒跑，指路 `/cc-code:agent-uiux`；本次增量涉及页面且 `未锁`（或 status 缺失而 `design.md` §0 = 草稿 / 缺失）→ ⛔ 拒跑，指路 `/cc-code:plan-uiux`；`已锁` → 放行（`design.md` §0 仍写「改版待实现」属 uiux 尚未补写的滞后，以 status 为准）；`无前端` / 纯后端 → 放行并标「不适用」；`未锁（冷启动豁免）` → 放行，范围仅存量未改页面（⛔ 不再二次豁免）；冷启动豁免的判定与发放流程同 `agent-mvp`。
5. 确认测试基建：读 `project.md` §六「测试基建契约」——**测试 / 构建 / 自检命令的唯一来源**，⛔ 本命令不自带命令。契约不存在或未填实 → 停下报告交人（补契约 = 派 `architect`，由主人裁决后再续跑）；契约已填实但测试基建尚未落地 → 把「按契约搭测试基建」作为 Dev 段首个任务。
   同理读 `project.md` §七「日志契约」：不存在或未填实（老项目常见）→ 停下报告交人（补契约 = 派 `architect`）；契约已填实但基建未落地 → 把「按契约搭日志基建」并入 Dev 段首个任务。
   视觉契约五项与缺项处置同 `agent-mvp` 前置检查第 4 条（`ux.md` §1.1 / `project.md` §一.1 / `design.md` §0 / §六 视觉门命令与基线目录 / §六 视口与亮暗）。
6. **索引体检（静默）**：`codegraph status --json` —— `pendingChanges` 非 0 → 静默 `codegraph sync`（增量回归面建立在索引之上，旧索引 = 漏回归）；`initialized:false` → 报一行（⛔ 不自动重建）。CLI 未装则静默跳过（精准回归降级为全量）。⛔ 健康时一个字都不提。
7. 执行 `/cc-code:cc-code` 完成会话开启协议，锁定当前阶段与坐标。

## ⭐ 增量定位（第一动作，纯查表，零推理）

```
 ⓪ 先看串线（只认一个方向，命中即分流，本命令不接）：
     读 status.md「下一步」+ status.md「风格：」（design.md §0 只在 status 缺失时兜底）
       ├─ 风格：已定未实现 /（status 缺失时）design.md §0 = 改版待实现
       │     → ⛔ 拒跑：「这是风格落地，走 /cc-code:agent-uiux」
       ├─ 风格：已锁 → 忽略 design.md §0 的「改版待实现」（uiux 尚未补写，以 status 为准），继续往下
       ├─ 主人在说「某功能坏了 / 显示不对 / 行为不符」，且能落到某页某断言
       │     → ⛔ 拒跑：「这是缺陷，先走 /cc-code:plan-debug，再走 /cc-code:agent-debug」
       └─ 都不是 → ①

 ① 读 status.md「下一步」
      └─ 期望形态（只认这一态）：「F-n <需求名>，已规划未开发」+ 点名断言号（如 A28.1~A28.10 / U23）
           ├─ 没有 F-n / 写的是「未规划」/「需求已落盘，技术待规划」/ 下一步是别的事
           │     → ⛔ 拒跑：「增量未规划完（或技术方案未定），请先走 /cc-code:plan-feature」
           │       （本命令绝不现场推需求——需求唯一来源 = 定稿文档）
           └─ 拿到 F 号 + 新断言清单
 ② 读 prd.md §1.5 主表 / ux.md 本次命中页的五态矩阵（该页 <页章号>.3）→ 取这些断言号的具体内容
 ③ 读 gates.md 追溯矩阵 → 取已 PASS 断言集合
 ④ 对账：
      增量范围 = F-n 点名断言 − gates.md 已 PASS
           ├─ 差集为空 → 报「F-n 已全部 PASS，无事可做」，结束
           └─ 差集非空 → 即本次执行范围，进 ⑤
 ⑤ 新页风格核对（仅当本增量新增页面）：
       ├─ 只用已锁数值 / 已锁组件 / 已知构图范式 → 可执行，登记进本次改动范围
       └─ 引入新数值 / 新组件 / 新视觉母题 → ⛔ 拒跑：回 /cc-code:plan-uiux 过「定了」
           （两档规则唯一出处 = /cc-code:plan-feature 命令正文）
```

> 断言编号永久稳定（A 序列不重排不复用），所以这个对账天然精确——已 PASS 的不会重做，没 PASS 的就是本次的活。
> 三种增量不串线：风格落地 → `agent-uiux`；缺陷 → `agent-debug`；已规划未开发 → 本命令。

## 生命周期总览

```
启动 → 增量定位 → ①Dev → 校准 → ②QA 四层（逻辑/接口/交互/视觉）→ 校准
                                 │
                       ┌─────────┴──────────┐
                       ▼                    ▼
                 FAIL→回Dev(≤3)         PASS→结算→结束
                       │                  （⛔ 无全量清算）
               3轮仍FAIL→交人决策
```

> 增量定位之后：§九 有本 F 号两条以上泳道 → 先过并行协议的启用体检（泳道断言取增量差集，已全部通过的泳道整条跳过），过了 ①Dev / ②QA 按泳道并发 + 栅栏 + 汇合回归，不过单线程跑。**运行时视觉检查只在汇合回归跑**。细则见并行协议，本节不复述。

## 阶段执行规范

### ① Dev 段（agent: dev）
| 项 | 内容 |
| --- | --- |
| 范围 | prd 只读 F-n 命中模块小节 + §1.5 命中断言；ux 只读命中 U 项；design 只读本次新页 / 改动页的构图与已锁数值（不整份改，⛔ 不写）；data / api 只读命中契约小节（读写权限以 `Agent.md` §三 为准）；派单另列 `.cc_code/references/INDEX.md`（经验索引，命中主题才打开；规则见 `Agent.md` §四第 7 条） |
| 做 | 只按增量范围实现：改写命中模块 + 新增/补齐测试；遵循 project.md 约定；⛔ 不重构无关代码；实现细节缺信息可自行决定并写进报告。有页面时只引用已锁主题数值、只用 `project.md` §一.1 登记的一个家族与一套图标；需要新数值 → 停下交人回 `plan-uiux` |
| 冲突 | 需求或契约（prd / ux / design / api / data）有冲突 → 停下，不动，在报告「冲突上报」里用业务语言写（技术细节另列）；主控把 dev 的冲突上报原样交人（见「编排器行为准则」）。视觉规格矛盾同样停下，改规格归 `uiux`（`plan-uiux`），⛔ dev 不自改数值 |
| 跑 | Agent(dev) → 自检：按 `project.md` §六 测试基建契约登记的命令，依次跑代码规范检查、类型检查、单测、e2e、视觉门（有哪些跑哪些；视觉门只跑不改，⛔ 不写基线） |
| 输出 | 增量代码 + 测试（落 `project.md` §六 声明的测试根）+ 完成报告（文件清单 + 自检 pass/fail + 「采纳经验」一行，格式见 `Agent.md` §四第 7 条） |
| ⭐ 完成后 | **算精准回归面**：`codegraph affected <本段改动的源文件...>` → 测试文件清单传给 ②QA 段；契约里登记的非常规命名测试，按 `project.md` §六 登记的 glob 补跑，合并去重即「本段回归范围」 |
| ✅ 完成后 | 执行 `/cc-code:cc-code` 校准（静默） |

> **`affected` 空结果处置**：返回空 → 报一行「affected 未匹配到测试，本段回归用全量」+ 自查 ① 测试被 `.gitignore` 屏蔽？② 测试是否 import 被测源码（纯 HTTP 型无 import 边）③ 命名需 `--filter`？。CLI 未装 → 静默用全量，不报。

### ② QA 段（agent: qa，灰盒）
| 项 | 内容 |
| --- | --- |
| 范围 | prd 只读命中断言；design 只读本次新页 / 改动页构图与已锁数值（视觉尺子）；`src/` 只读本段改动（读写权限以 `Agent.md` §三 为准） |
| 做 | 只为增量范围的断言建验收清单 + 三层测试 + 视觉层（尺子 = `design.md` + `ui-gates.md`）；完整跑一遍（不抽样）。视觉查本次受影响页面 × 声明视口 × 亮暗 × 五态；本增量新增页按「开发后」查 |
| 跑 | Agent(qa) → ① 段 `affected` 回归范围优先（拿不到则全量）；疑难交互用界面驱动工具探索取证；测试与视觉门命令取自 `project.md` §六 |
| 输出 | QA 报告（Verdict + 断言追溯矩阵 + Critical Failures 清单 + V 段视觉结果 + 回归范围来源标注）；新增页的人判 VS 进合集板，不卡流程 |
| 写 | `gates.md`（qa 唯一写者，主控不代写）；补测落测试根；视觉测试与截图基线落 `project.md` §六 登记的视觉测试位置与基线目录（**基线 qa 独占、入 git**）；逐轮报告与合集板落 `.cc_code/docs/qa/` |
| ✅ 完成后 | 执行 `/cc-code:cc-code` 校准（静默） |

> 需求永远只来自 `prd.md` / `ux.md` / `design.md` / `api.md`，⛔ 不拿代码当尺子；qa 用 codegraph 的权限见 Agent.md codegraph 权限矩阵。

**四层测试矩阵：** 同 `agent-mvp`（逻辑 / 接口 / 交互 / 视觉四层，命令取自 `project.md` §六；视觉层尺子 = `design.md` + `ui-gates.md`）。

## qa → dev 循环（QA 段内）

> **循环协议唯一出处 = `../cc-code/references/dev-qa-loop.md`**（一轮定义、按失败项计轮、≤3 轮、升级包、任务单字段）。本命令只写差异：

1. dev 每轮修完重算 `codegraph affected <本轮修改文件>`；qa 复测范围 = FAIL 项 + affected 影响面（拿不到则退回「同模块已 PASS 项」）+ 本轮受影响的视觉页 × 视口 × 亮暗 × 五态。
2. 视觉失败项同样按失败项计轮：VH 由 qa 判、dev 修，⛔ 主控不代判、不删项、不把 VS 当阻断。
3. 每轮循环后执行 `/cc-code:cc-code` 校准（静默）；3 轮仍 FAIL → 交人（⛔ 直接报告卡点，不回规划、不点名去找谁）；全绿 → QA 段 PASS。

## 增量结算（QA PASS 即结束，⛔ 无全量清算）

- **主控**在 `backup/milestone-log.md` 追加一行（格式见 `active/Agent.md` 归档规范），⛔ 不写进 `status.md`。
- 主控顺手更新 `status.md`「当前坐标 + 卡点 + 下一步」（下一步清空 F-n 指向，或指向遗留待办）；`gates.md` 由 qa 写。
- 本增量**新增页面**且视觉层 PASS → **qa 按 `../cc-code/references/ui-gates.md` §7.2 处置基线**：只有本身属于「组件陈列页 / 该形态样板必含页」的新增页才冻结基线，新增业务页只落截图证据、不做像素基线（失败轮 ⛔ 禁止冻结；范围外差异判回归）。视觉地基的基线不重冻，除非本次改动命中它并被判回归。
- **后台派 `curator`**（QA PASS 或 3 轮仍 FAIL 交人，每次结算都派；规则见 `active/Agent.md` §四第 7 条，派发与结果并入方式见 §五「派 curator」）。
- 报告：F-n 增量交付（断言 PASS 清单 + 回归范围 + 新增页合集板指针）。
- **不跑 agent-whole-qa、不做全量回归** —— 增量的验收面就是 affected 精准回归面；全量清算只属于 MVP 收口（`/cc-code:agent-mvp`）或主人显式调用 `/cc-code:agent-whole-qa`。

> ⭐ **写 active 前必过「就地更新 + 搬运归档」**（规则单一出处 = `active/Agent.md` §四第 5 条），各写者只动自己负责的文件。

## 编排器行为准则

- **你是编排器**：按阶段派对应 agent，不在主控里替角色思考，不扮演任何角色。
- **纯执行定位**：发现增量文档缺漏 / 自相矛盾 / 断言查无内容 → 停下，主控把 dev 的冲突上报原样交人（dev 已用业务语言写），⛔ 绝不现场发明需求（那是 `/cc-code:plan-feature` 的职责）。主人裁决后按文件路由：契约问题派 `architect` 改 L3、需求问题 `prd` 派 `pm` 改、`ux` 派 `uiux` 改、视觉规格问题走 `plan-uiux` 改 `design.md`，再续跑；主控自己不改。
- **视觉门不可绕**：本次增量涉及页面而风格未锁 → 拒跑并指路 `plan-uiux`；`已定未实现` → 拒跑并指路 `agent-uiux`；⛔ 不用「先做再说」放行；冷启动豁免只发一次。
- **三种增量不串线**：风格落地 → `agent-uiux`；缺陷 → `agent-debug`；已规划未开发 → 本命令。⛔ 抢别的命令的活。
- **视觉判词只认 qa**：主控不代判；人判 VS 只进合集板，不卡流程、不进分母。
- **subagent 不能问用户**：dev / qa 要问人的事一律交回主控，由主控交人。
- **dev 完成报告缺「采纳经验」一行** → 续接同一个 dev 补（规则见 `active/Agent.md` §五）。
- **每次切阶段前必须 `/cc-code:cc-code` 校准**，禁止凭记忆推进；校准静默，不打扰人。
- **agent 通用、cc-code 项目特定**：项目约定一律让 agent 读 `.cc_code/active/project.md`，不替它假设。
- 进度以 `status.md` 为准、验收以 `gates.md` 为准。
- 不向用户报告归档细节；只报阶段结果与交人决策点。
