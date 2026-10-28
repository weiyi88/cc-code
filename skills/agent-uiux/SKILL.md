---
name: agent-uiux
description: 把已定的新风格落到代码里：重新生成主题、调长相与布局，qa 跑全量交互回归与视觉比对，最多 3 轮
allowed-tools: Read, Write, Edit, Bash, Glob, Grep, Agent, TaskCreate, TaskUpdate, TaskList, mcp__codegraph__codegraph_explore
---

# agent-uiux — 「风格已定未实现」落地执行器

> **纯执行器**：只执行已批准的改版（`status.md`「风格：」= `已定未实现`，且 `design.md` §0 = 改版待实现），**不定风格、不规划**。判据以 `status.md` 为准（`design.md` §0 只在 status 缺失时兜底）。风格由 `/cc-code:plan-uiux`（模式二 改版）经主人「定了」落盘，本命令只把它落进代码。
> **主控是编排者，不扮演任何角色**：派哪个 agent 就是哪个角色，角色权限唯一出处 = `active/Agent.md` §三；主控的写权限见 `active/Agent.md` §一，⛔ 不写 `gates.md` 与 L1~L3 文件。
> **运行中零提问**：碰「不可改」的部分挂起、3 轮仍不过的项记账，其余照跑，结尾一次交人（唯一出处 = `../cc-code/references/dev-qa-loop.md` §九）。
> **⛔ 本命令不派 uiux**：uiux 只在 `plan-mvp` / `plan-feature` / `plan-uiux` 出场；本命令的执行角色只有 `dev`（改实现）与 `qa`（验收）。
> **单一出处**：视觉规则与判词唯一出处 = `../cc-code/references/ui-gates.md`；循环协议唯一出处 = `../cc-code/references/dev-qa-loop.md`；形态、栈、家族与三旋钮 = `../cc-code/references/frontend-forms.md`；并行泳道 = `../cc-code/references/parallel-lanes.md`。

## 与 plan-uiux / agent-feature 的分工（两两配对）

```
 plan-uiux 模式二（人参与）                     agent-uiux（本命令，纯机器）
 现状体检 → 目标 design.md → 样板板              读已定稿的 design.md
 「定了」→ design.md = 改版待实现 + status         Dev 重生成主题 → 调长相与布局
 → 交回并指路 agent-uiux                ──►      QA 全量交互回归 + 全页视觉 + 基线对比（≤3 轮）
                                                   ↓ PASS → qa 冻 / 重冻基线（限陈列页 / 样板页）+ 合集板 → 结算
```

> 与 agent-feature 的分界：feature 是「按新需求加功能 / 加页面」（需求变了）；本命令是「需求不变、长相与布局按新风格变」（视觉变了）。功能与长相都改 → 拆两次，先本命令后 `agent-feature`。

## 前置检查（启动时一次性，七项）

1. 确认项目根存在 `.cc_code/`（否则提示先 `/cc-code:init`）。
2. 确认角色可用：`dev` / `qa`（⛔ 不派 uiux）。
3. **开工定位（⭐第一动作，见下节）**——定位失败即拒跑，后续检查全免。
4. **设计规格**：**先读 `status.md`「风格：」并以它为准**——`已锁` → ⛔ 报「风格已落地，无事可做」并结束（`design.md` §0 待 uiux 下次出场补写，以 status 为准）；`未锁 / 未锁（冷启动豁免）` → ⛔ 拒跑（未定 → `plan-uiux`）；`无前端` → ⛔ 拒跑，本命令不适用；`已定未实现` → 继续核对 `active/design.md` §0 = `改版待实现` 且「本次改版范围」写清受影响页面与改动面，不符 → ⛔ 拒跑（未规划 → `plan-feature`；缺陷 → `agent-debug`）。status 缺失时才回退按 `design.md` §0 判。
5. **家族与主题**：`project.md` §一.1 有家族 / 各端组件库 / 主题入口 / 图标库 / 片段白名单；`project.md` §六 有界面驱动工具 / 视觉测试位置 / 视觉门命令 / 基线目录 / 视口集合 / 亮暗模式。缺任一 → ⛔ 拒跑，按 `../cc-code/references/dev-qa-loop.md` §九 出交人报告（下一步 `/cc-code:plan-feature`，补契约归 `architect`），⛔ 不自带命令。
6. **基线**：确认基线目录与既有基线。首次落地且项目尚无基线 → 本次只生成候选、不判回归；基线目录入 git、`qa` 独占。
7. 执行 `/cc-code:cc-code` 完成会话开启协议，锁定当前坐标。

## ⭐ 开工定位（第一动作，先读 status）

```
 ① 读 status.md「下一步」+ status.md「风格：」（design.md §0 只在 status 缺失时兜底）
      └─ 按「风格：」分流：
           ├─ 已锁                     → ⛔ 报「风格已落地，无事可做」，结束
           │                               （design.md §0 仍 = 改版待实现 属 uiux 尚未补写的滞后，以 status 为准）
           ├─ 未锁 / 未锁（冷启动豁免） → ⛔ 拒跑：「风格还没定，请先走 /cc-code:plan-uiux」
           ├─ 无前端                   → ⛔ 拒跑：本命令不适用
           ├─ 已定未实现               → 继续核对 design.md §0（下一段）
           └─ status 缺失              → 按 design.md §0 兜底：草稿 → 拒跑（plan-uiux）；
                                          已锁定 → 报「风格已落地，无事可做」；不适用（无前端）→ 拒跑
      design.md §0 核对（status = 已定未实现 时必须）：
           ├─ = 改版待实现     → 通过
           ├─ = 草稿           → ⛔ 拒跑：「风格还没定，请先走 /cc-code:plan-uiux」
           ├─ = 已锁定         → ⛔ 报「风格已实现，无事可做」，结束（与 status 不一致，主控核对）
           └─ = 不适用（无前端）→ ⛔ 拒跑：本命令不适用
      另：下一步指向 F-n / B-n → ⛔ 拒跑：走 /cc-code:agent-feature 或 /cc-code:agent-debug
 ② 取范围：design.md §0「本次改版范围」= 受影响页面清单 + 改动面
      ⛔ 不自行扩范围；范围外的页面不动
```

## 生命周期总览

```
启动校准 → 开工定位 → ①Dev（重生成主题 + 调长相/布局）→ 校准
                              │
                              ▼
        ②QA（全量交互回归 + 全页视觉 + 基线对比）→ 校准
                              │
                    ┌─────────┴──────────┐
                    ▼                    ▼
              FAIL→回Dev(≤3)         PASS→冻结新基线 → 合集板 → 结算 → 校准
                    │
            3轮仍FAIL→记账，其余照常结算
```

> 有泳道时按 `project.md` §九 与 `parallel-lanes.md` 并发；**运行时视觉检查只在汇合回归跑**。细则见并行协议，本节不复述。

## 阶段执行规范

### ① Dev 段（agent: dev）

| 项 | 内容 |
| --- | --- |
| 范围 | `design.md` 全文件（视觉唯一依据）；`project.md` §一.1（家族 / 主题入口 / 图标库）与 §六（视觉门命令 / 视口 / 亮暗）；`ux.md` 只读本次改版范围内的页章（仅在 `design.md` 要求调整布局时）；派单另列 `.cc_code/references/INDEX.md`（经验索引，命中主题才打开；规则见 `Agent.md` §四第 7 条） |
| 做 | ① 按 `design.md` **重新生成各端主题文件**（生成物，⛔ 禁手改）② 按 `design.md` 调组件长相与页面布局（栅格 / 间距 / 构图 / 图标图像 / 动效按已锁数值）③ 只改本次改版范围；⛔ 不新造数值、不引第二家族 / 第二图标库、不在主题入口外写色值字面量 |
| 挂起 | 碰到跨页流转 / 五态 / testid / 接口契约 / 数据契约 / 需要新增页面 → 挂起该部分及依赖它的部分，不动，在报告「挂起」里用业务语言写（技术细节另列），其余照做；`design.md` 自相矛盾或与 `ux.md` 布局相抵 → 同样挂起（规格归 uiux）。主控按 `../cc-code/references/dev-qa-loop.md` §九 记进挂起清单，⛔ 运行中不问主人 |
| 跑 | Agent(dev) → 自检：按 `project.md` §六 登记的命令依次跑代码规范检查、类型检查、单测、e2e、视觉门（有哪些跑哪些；视觉门只跑不改，⛔ 不写基线） |
| 输出 | 主题再生成清单 + 改动页清单 + 完成报告（自检 pass/fail + 「采纳经验」一行，格式见 `Agent.md` §四第 7 条） |
| ⭐ 完成后 | 算精准回归面：`codegraph affected <本段改动的源文件...>` → 测试文件清单传给 ②QA 段；契约里登记的非常规命名测试按 `project.md` §六 glob 补跑 |
| ✅ 完成后 | 执行 `/cc-code:cc-code` 校准（静默） |

### ② QA 段（agent: qa，灰盒）

| 项 | 内容 |
| --- | --- |
| 范围 | `design.md` 只读（视觉唯一尺子）；`ux.md` 只读受影响页的五态与流转判定项；`src/` 只读本段改动（读写权限以 `Agent.md` §三 为准） |
| 做 | ① **全量交互回归**：主题全局生效，全部页面逐页跑五态，⛔ 不只测改版范围 ② **全页视觉**：每一页 × 声明视口 × 亮暗（尺子 = `design.md` + `ui-gates.md`，查 02~09 组）③ **基线对比**：只比组件陈列页与样板页；范围内差异 → 候选，范围外 → 判回归 ④ 完整跑一遍，不抽样 |
| 跑 | Agent(qa) → Dev 段 `affected` 回归范围优先（拿不到则全量）；视觉门命令取自 `project.md` §六；机器检查写成测试运行器测试；界面驱动工具只做探索取证；性能只在全量验收与部署用 Lighthouse 命令行 |
| 写 | `gates.md` V 段（qa 唯一写者，主控不代写）；视觉测试落 `project.md` §六 视觉测试位置；**截图基线 qa 独占、入 git**；逐轮报告与合集板落 `.cc_code/docs/qa/` |
| 输出 | QA 报告（Verdict + V 段结果 + Critical Failures + 基线差异清单 + 回归范围来源） |
| ✅ 完成后 | 执行 `/cc-code:cc-code` 校准（静默） |

## qa → dev 循环（QA 段内）

> **循环协议唯一出处 = `../cc-code/references/dev-qa-loop.md`**（一轮定义、按失败项计轮、≤3 轮、升级包、任务单字段）。本命令只写差异：

1. dev 每轮修完**重新生成主题**再自检；重算 `codegraph affected <本轮修改文件>`；qa 复测范围 = FAIL 项 + affected 影响面（拿不到则同模块已 PASS 项）+ 本轮受影响页 × 视口 × 亮暗 × 五态。
2. 视觉失败项按失败项计轮：VH 由 qa 判、dev 修，⛔ 主控不代判、不删项；VS 只进合集板，不阻断、不进分母。
3. 每轮执行 `/cc-code:cc-code` 校准（静默）；3 轮仍 FAIL → 该项进挂起清单（§九），其余照常结算（⛔ 不回规划链、不点名去找谁）；全绿 → QA 段 PASS。

## 改动边界（可改 / 不可改）

| 可改（按 `design.md` 已定值） | 不可改（碰即挂起，§九） |
| :--- | :--- |
| 各端主题文件（重新生成） | 跨页流转 / 路由结构 |
| 组件长相（§八 的覆盖值） | 该页交互五态判定项（`ux.md` 该页 <页章号>.3 五态矩阵） |
| 页面布局与构图（栅格 / 间距 / 断点表现 / 构图族） | 该页可交互元素与 testid（`ux.md` 该页 <页章号>.4 元素清单） |
| 图标与图像处理、动效时长与曲线 | 接口契约 / 数据契约 |
| 组件陈列页的状态呈现 | 新增页面（归 `plan-feature`） |
| — | 需求断言（`prd.md` §1.5）与设计数值本身（归 `plan-uiux`） |

> 需要动「不可改」列 → 挂起该部分，其余照做；结尾交人报告的下一步把它转给对应写者（uiux / pm / architect，经 `plan-feature` / `plan-uiux`），改完再回本命令；⛔ 边做边改。

## 视觉结算（QA PASS 即结束）

```
 qa 复测 PASS
    │
    ▼
 ① qa 只在本命令的基线范围内冻结 / 重冻基线（即组件陈列页与样板页里、本次改版受影响且原本已在基线范围内的页，
      细则唯一出处 = `../cc-code/references/ui-gates.md` §7.2 ③）
      （其他受影响页只出截图证据、不做像素基线；失败轮 ⛔ 不冻；范围外差异判回归）
    ▼
 ② qa 出合集板（VS 汇总：一条一行 + 截图 + 一句观察），落 .cc_code/docs/qa/
      （不卡流程、不进分母、不触发回环）
    ▼
 ③ 主控追加 backup/milestone-log.md 一行
    ▼
 ④ 主控更新 status.md：「风格：」已定未实现 → 已锁；下一步清空本改版指向
      ⛔ 本命令不改 design.md §0（uiux 唯一写者，且 uiux 不出场）
      主控在下一步留一句「design.md §0 待 uiux 下次出场补写已锁定」，补写前执行器以 status.md 为准
    ▼
 ⑤ 后台派 curator（规则见 active/Agent.md §四第 7 条、§五；视觉段只做台账）
    ▼
 ⑥ 报告：按 dev-qa-loop.md §九 三段出（结果 = 改了什么、看哪张截图、新基线位置；待你补答 = 挂起清单；
      下一步命令 + 完整 prompt），下一步同步写进 status.md
```

> 基线冻结、重冻、差异判定的唯一出处 = `../cc-code/references/ui-gates.md` §七；本命令不复述。⛔ 主控不代写 `gates.md`、不代冻基线。

## 编排器行为准则

- **你是编排器**：按段派 `dev` / `qa`，不替角色思考；⛔ 不派 uiux、不代写任何文件。
- **只认一态**：开工定位以 `status.md`「风格：」为准——`已锁` 报「风格已落地，无事可做」结束，不是「已定未实现」就拒跑并指路对应命令；⛔ 不用「顺手改改」开工。
- **不扩范围**：只改 `design.md` §0 登记的本次改版范围；发现范围写错 / 与其他需求冲突 → 挂起该部分（§九，下一步 `plan-uiux`）。
- **视觉判词只认 qa**：主控不代判、不因为「看着还行」把 VH 改 PASS；人判 VS 只进合集板，不卡流程。
- **功能与长相都改 → 拆两次**：先本命令，再 `agent-feature`；⛔ 混在一次里跑。
- **运行中零提问**：dev / qa 不能问用户，主控运行中也不问；要人的事一律按 `../cc-code/references/dev-qa-loop.md` §九 挂起、结尾一次交人。
- **每次切段前必须 `/cc-code:cc-code` 校准**，禁止凭记忆推进；校准静默。
- 进度以 `status.md` 为准、验收以 `gates.md` 为准；不向用户报告归档细节。