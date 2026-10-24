---
name: agent-debug
description: 按修复方案改代码，跑相关测试全绿才算修好
allowed-tools: Read, Write, Edit, Bash, Glob, Grep, Agent, TaskCreate, TaskUpdate, TaskList, mcp__codegraph__codegraph_explore
disable-model-invocation: true
---

# agent-debug — 双 agent × cc-code 驱动 bug 修复执行编排器

> **纯执行器**：只修已诊断的 bug，**不诊断**。根因与方案由 `/cc-code:plan-debug` 经 qa 自动整理进 `active/bugs.md` 的 B-n 条目，**只接 状态 = 待修复 的条目**（状态定义见 `templates/bugs.md`），本命令读 B-n 直接开发，**中途零确认**，只在 3 轮仍不过、或 dev 撞上需求 / 契约冲突时交人。
> **主控是编排者，不扮演任何角色**：派哪个 agent 就是哪个角色；角色权限唯一出处 = `active/Agent.md` §三。主控的写权限见 `active/Agent.md` §一，⛔ 不写 `gates.md` / `bugs.md` / L1~L3 文件。
> **与 agent-feature 的分工**：feature 是「加一个房间」（执行 F-n 需求增量）；本命令是「修房子里的漏水点」（执行 B-n bug 修复）。执行循环、回归策略同构；结算不同——本命令由 qa 把 B-n 搬 retired。
> **初衷铁律**：完整地修复 bug —— 修复面 = B-n 用例 + affected 算出的爆炸半径，⛔ 无 agent-whole-qa、无全量回归。

## 前置检查（启动时一次性）
1. 确认项目根存在 `.cc_code/`（否则提示先 `/cc-code:init`）。
2. 确认双 agent 可用：`dev` / `qa`。
3. **增量定位（⭐第一动作，见下节）**——定位失败即拒跑，后续检查全免。
4. 确认测试基建：读 `project.md` §六「测试基建契约」（测试 / 构建 / 自检命令的唯一来源）。契约不存在或未填实 → ⛔ 不猜命令，停下报告交人；契约已填实但测试基建尚未落地 → 把「按契约搭测试基建」作为 Dev 段首个任务。
5. **索引体检（静默）**：`codegraph status --json` —— `pendingChanges` 非 0 → 静默 `codegraph sync`；`initialized:false` → 报一行（⛔ 不自动重建）。CLI 未装则静默跳过（精准回归降级为全量）。⛔ 健康时一个字都不提。
6. 执行 `/cc-code:cc-code` 完成会话开启协议，锁定当前坐标。

## ⭐ 增量定位（第一动作，纯查表，零推理）

```
 ① 读 status.md「下一步」
      └─ 期望形态：「B-n 待修复」+（bugs.md 里有对应条目，状态 = 待修复）
           ├─ 没有 B-n / 下一步是别的事
           │     → ⛔ 拒跑：「没有待修复的 bug，请先走 /cc-code:plan-debug」
           │       （本命令绝不现场诊断根因——根因唯一来源 = B-n 条目）
           └─ 拿到 B 号 + 条目内容（现象/复现/期望出处/根因/爆炸半径/方案）
 ② 对账（B-n 修复 PASS 时 qa 已把条目搬 retired，所以仍在 bugs.md 的就是没修好的）：
      条目已不在 bugs.md → 报「B-n 已修复，无事可做」，结束
      条目在 bugs.md，按状态分流：
        ├─ 待修复 → B-n 即本次执行范围，进 Dev 段
        ├─ 待诊断 → ⛔ 拒跑：「诊断还没做完，请先走 /cc-code:plan-debug」
        └─ 待裁决 → ⛔ 拒跑：把条目里「待裁决」那句话原样交主人，等裁决后再来
```

## 生命周期总览

```
启动 → 增量定位 → ①Dev → 校准 → ②QA → 校准
                              │
                    ┌─────────┴──────────┐
                    ▼                    ▼
              FAIL→回Dev(≤3)         PASS→结算→结束
                    │                （⛔ 无全量清算）
            3轮仍FAIL→qa 把 B-n 状态写回「待裁决」+ 卡点→交人决策
```

## 阶段执行规范

### ① Dev 段（agent: dev）
| 项 | 内容 |
| --- | --- |
| 范围 | bugs.md 只读本次 B-n 条目；prd / ux 只读期望出处命中的断言 / 判定项；data / api 只读命中小节（读写权限以 `Agent.md` §三 为准） |
| 做 | 只按 B-n 方案修：根因处修复 + 按「爆炸半径」里的技术备注（文件清单）逐文件核对连带；遵循 project.md 约定；⛔ 不重构无关代码；实现细节缺信息可自行决定并写进报告 |
| 冲突 | 发现 B-n 方案要动契约（data / api）或需求（prd / ux）→ 停下，不动，在报告「冲突上报」里用业务语言写（技术细节另列）；主控把 dev 的冲突上报原样交人（见「编排器行为准则」） |
| 探针 | B-n「需加探针」非「无」时：先按其加临时日志，每条带标记 `CC-PROBE-B<n>`，走 `project.md` §七 门面（DEBUG 级）→ 复现取证 → 修复 → ⛔ 交 QA 前删光（`rg CC-PROBE-B<n>` 零命中） |
| 跑 | Agent(dev) → 自检：按 `project.md` §六 测试基建契约登记的命令，依次跑代码规范检查、类型检查、单测、e2e（有哪些跑哪些，⛔ 不自带命令） |
| 输出 | 修复代码 + 完成报告（文件清单 + 自检 pass/fail） |
| ✅ 完成后 | 执行 `/cc-code:cc-code` 校准（静默） |

### ② QA 段（agent: qa，灰盒）
| 项 | 内容 |
| --- | --- |
| 范围 | bugs.md 只读本次 B-n 条目；`src/` 只读本段改动（读写权限以 `Agent.md` §三 为准） |
| 做 | ① 按「复现」写 bug 用例（修复前应不过、修复后应通过）②⭐**落一个永久回归测试进测试根**（`project.md` §六 声明）③ 完整跑一遍 B-n 用例 + 爆炸半径回归 ④ 全库搜探针标记 `CC-PROBE-` 零命中，否则不过回 Dev |
| 跑 | Agent(qa) → Dev 段改动文件的 `affected` 回归范围优先（拿不到则全量）；疑难交互用浏览器 MCP 取证；测试命令取自 `project.md` §六 |
| 写 | `gates.md`、`bugs.md`（结算时搬条目；3 轮仍 FAIL 时把状态写回「待裁决」）——qa 是这两处的唯一写者，主控不代写；回归测试落测试根（dev / qa 都可写，以 `Agent.md` §三 为准） |
| 输出 | QA 报告（Verdict + B-n 用例结果 + 回归范围来源标注） |
| ✅ 完成后 | 执行 `/cc-code:cc-code` 校准（静默） |

> **⭐ 修复 PASS 硬条件**：回归测试存在且通过才许记通过。没有测试的修复不算修完 —— 没有回归测试，gates 的 ✅ 就是假账，下次这段代码被改动没人兜底。
> **期望行为永远只来自 B-n 条目**（出处为主人原话或 prd / ux 既有断言），⛔ 不拿代码或 dev 的解释当尺子；qa 用 codegraph 的权限见 Agent.md codegraph 权限矩阵。

## qa → dev 循环（QA 段内）

1. qa 出 FAIL 清单 → 主控原样喂回 dev。
2. dev 只修不改方案不改需求 → 修完重算 `codegraph affected <本轮修改文件>`，主控再调 qa 复测（B-n 用例 + affected 爆炸半径；拿不到则退回全量）。
3. 每轮循环后执行 `/cc-code:cc-code` 校准（静默）。
4. 最多 3 轮：仍 FAIL → qa 把 B-n 状态写回「待裁决」，在「待裁决」字段用业务语言写清卡点，主控把这句话交人决策（⛔ 不回诊断、不点名去找谁），禁止无限循环。
   > 修复期间 B-n 状态保持「待修复」不变：派 dev 修之前不改状态（此时 qa 尚未派出）；只有复测 PASS（条目搬 retired）或 3 轮仍 FAIL（写回待裁决）才动它。
5. 全绿 → QA 段 PASS。

## 修复结算（QA PASS 即结束，⛔ 无全量清算）

```
 qa 复测 PASS
    │
    ▼
 ① qa 记账 gates.md（按 B-n「期望出处」分两路）
      ├─ 出处 = 既有 A/U 断言 → 就地改写该断言行为通过（换新测试位置，不新开行）
      └─ 出处 = 主人原话      → 追溯矩阵 B 段追加一行 B-n 通过
    ▼
 ② qa 结算 bugs.md：该条目原文整段搬 backup/retired/bugs.md
      （带搬运头：日期 ｜ 来源 ｜ 退役原因「B-n 修复 PASS」），再从 active 移除
      ⛔ 不直接删——内容一个字都不许丢
    ▼
 ③ 主控追加 backup/milestone-log.md 一行
      （日期 ｜ 模块 ｜ B-n <简述> 修复 PASS ｜ 期望出处断言号或 B-n）
    ▼
 ④ 主控更新 status.md（下一步清空 B-n 指向，或指向遗留待办）
    ▼
 ⑤ 报告：修复交付（用例通过 + 回归范围 + 回归测试位置）
```

- 追溯 = retired 原文 + milestone-log 一行 + 留守的回归测试。
- **不跑 agent-whole-qa、不做全量回归** —— bug 修复的验收面就是 B-n 用例 + affected 精准回归面；全量清算只属于 MVP 收口或主人显式调用 `/cc-code:agent-whole-qa`。

> ⭐ **写 active 前必过「就地更新 + 搬运归档」**（规则单一出处 = `active/Agent.md` §四第 5 条），各写者只动自己负责的文件。

## 编排器行为准则

- **你是编排器**：按阶段派对应 agent，不在主控里替角色思考，不扮演任何角色。
- **纯执行定位**：发现 B-n 条目缺漏（方案说不清 / 爆炸半径为空 / 根因存疑，但状态标成了待修复）→ 停下报告交人，⛔ 绝不现场重新诊断（那是 `/cc-code:plan-debug` 的职责）。
- **subagent 不能问用户**：dev / qa 要问人的事一律交回主控，由主控交人。
- **契约 / 需求出错**：dev 或 qa 发现根因其实是契约错 / 需求错 → 停下，主控把 dev 的冲突上报原样交人（dev 已用业务语言写）；主人拍板后契约错派 `architect` 改 L3、需求错派 `pm` 改 prd / ux，改完再续跑本命令。主控自己不改。
- **每次切阶段前必须 `/cc-code:cc-code` 校准**，禁止凭记忆推进；校准静默，不打扰人。
- **agent 通用、cc-code 项目特定**：项目约定一律让 agent 读 `.cc_code/active/project.md`，不替它假设。
- 进度以 `status.md` 为准、验收以 `gates.md` 为准、待修 bug 以 `bugs.md` 为准。
- 不向用户报告归档细节；只报阶段结果与交人决策点。
