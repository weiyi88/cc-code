---
name: agent-mvp
description: 按定好的方案写码，写完自动测试，不过就改到过（最多 3 轮）
allowed-tools: Read, Write, Edit, Bash, Glob, Grep, Agent, TaskCreate, TaskUpdate, TaskList, mcp__codegraph__codegraph_explore
disable-model-invocation: true
---

# agent-mvp — 双 agent × cc-code 驱动 MVP 执行编排器

> **纯执行器**：需求与契约**只读不产**——一切规划产物（prd / ux / project / data / api）由 `/cc-code:plan-mvp` 商讨定稿。本命令读定稿文档直接开发，**中途零确认**，只在 3 轮仍 FAIL、或 dev 撞上需求 / 契约冲突时交人。
> **校准铁律**：每一个阶段完成后，**必须**先执行 `/cc-code:cc-code` 校准当前状态（重读 `Agent.md`/`status.md`，重锁坐标），确认无误后再进入下一阶段。未校准禁止推进。校准是机器自检，**静默进行，不以「请确认」的姿态打扰人**。
> **串行铁律**：严守 Dev → QA 顺序，禁止跳序。**主控是编排者，不扮演任何角色**：派哪个 agent 就是哪个角色，角色权限唯一出处 = `active/Agent.md` §三；主控的写权限见 `active/Agent.md` §一，⛔ 不写 `gates.md` 与 L1~L3 文件。
> **并行泳道（1.6.0）**：阶段之间串行；阶段内 `project.md` §九 写了泳道 → 按 `../cc-code/references/parallel-lanes.md`（本 skill 目录的同级，插件内单一出处） 同一角色多人并发，没写 → 单线程照旧。

## 与规划命令的分工（两两配对，单一职责）

```
 plan-mvp（人参与）              agent-mvp（本命令，纯机器）
 商讨 → 逐点循环至通顺               读定稿文档
 落盘 prd/ux/project/data/api  ──►  Dev 编码 → QA 验收（≤3 轮回环）
 对话内确认，落盘即定稿               阶段全 PASS → agent-whole-qa 收口
```

## 前置检查（启动时一次性）
1. 确认项目根存在 `.cc_code/`（否则提示先 `/cc-code:init`）。
2. **定稿体检**：`active/prd.md` 有 §1.5 验收断言主表，且 `ux.md` / `project.md` / `data.md` / `api.md` 齐备。缺任一 → ⛔ 拒跑，报「规划产物未定稿，请先走 `/cc-code:plan-mvp`」，**绝不现场补需求**。
3. 确认双 agent 可用：`dev` / `qa`。
4. 确认测试基建：读 `project.md` §六「测试基建契约」取测试根 / glob / 运行命令——**测试 / 构建 / 自检命令的唯一来源**，⛔ 本命令不自带命令。契约不存在或未填实 → 停下报告交人（补契约 = 派 `architect`，由主人裁决后再续跑）；契约已填实但测试基建尚未落地 → 把「按契约搭测试基建」作为 Dev 阶段首个任务。
   同理读 `project.md` §七「日志契约」：选库 / 配置值未填实 → 停下报告交人（补契约 = 派 `architect`）；契约已填实但门面与 requestId 入口未落地 → 把「按契约搭日志基建」并入 Dev 首个任务。
5. **索引体检（静默）**：`codegraph status --json` 读三字段 —— `initialized:false` → 报一行（⛔ 不自动重建）；`pendingChanges` 非 0 → 静默 `codegraph sync`；`reindexRecommended:true` → 报一行建议。CLI 未装则静默跳过，全流程照跑（精准回归降级为全量）。⛔ 健康时一个字都不提。
6. 执行 `/cc-code:cc-code` 完成会话开启协议，锁定当前阶段与坐标。
7. **阶段来源**：读 `project.md` §九（9.1 阶段 / 9.2 泳道）。有阶段 → 按阶段逐段推进；无 → 整体作单阶段跑完。阶段内有两条以上泳道 → 先过并行协议的启用体检，过了并发跑、不过单线程跑（⛔ 不自行拆阶段 / 拆泳道，拆分是规划的职责）。

## 生命周期总览

```
启动校准 → ①Dev → 校准 → ②QA → 校准
                              │
                    ┌─────────┴──────────┐
                    ▼                    ▼
              FAIL→回Dev(≤3)         PASS→阶段结算→校准
                    │                    ▼
            3轮仍FAIL→交人决策       还有阶段? →回①
                                         ▼
                                 全PASS → MVP收口
```

> 阶段内有泳道时，①Dev / ②QA 两段各自变成「同角色多人并发 + 栅栏」，FAIL 只退回没过的泳道，阶段末多一次汇合回归 —— 全部细则见并行协议，本节不复述。

## 阶段执行规范

每阶段严格按「读 / 做 / 跑 / 输出 / 写」执行，完成即校准。

### ① Dev 段（agent: dev）
| 项 | 内容 |
| --- | --- |
| 做 | 按规格实现代码 + 三层测试；遵循 project.md 约定；实现细节缺信息可自行决定并写进报告 |
| 冲突 | 需求或契约（prd / ux / api / data）有冲突 → 停下，不动，在报告「冲突上报」里用业务语言写（技术细节另列）；主控把 dev 的冲突上报原样交人（见「编排器行为准则」） |
| 跑 | Agent(dev) → 自检：按 `project.md` §六 测试基建契约登记的命令，依次跑代码规范检查、类型检查、单测、e2e（有哪些跑哪些） |
| 输出 | 业务代码 + 测试（落 `project.md` §六 声明的测试根）+ 完成报告（文件清单 + 自检 pass/fail） |
| ⭐ 完成后 | **算精准回归面**：`codegraph affected <本段改动的源文件...>` → 得测试文件清单，传给 ②QA 段。契约里登记的非常规命名测试，按 `project.md` §六 登记的 glob 补跑，合并去重后即「本段回归范围」 |
| ✅ 完成后 | 执行 `/cc-code:cc-code` 校准 |

> **`affected` 空结果处置**（不做前置检测，出问题当场报一行即可）：
> 返回空 → 报「affected 未匹配到测试，本段回归用全量」+ 按序自查 ① 测试代码是否被 `.gitignore` 屏蔽（codegraph 不索引被 ignore 的文件）② 测试是否 import 了被测源码（纯 HTTP 打接口的脚本无 import 边，天然追不到）③ 命名是否需 `--filter`。CLI 未装 → 静默用全量，不报。

### ② QA 段（agent: qa，灰盒）
| 项 | 内容 |
| --- | --- |
| 范围 | `src/` 只读本阶段改动（读写权限以 `Agent.md` §三 为准） |
| 做 | 建验收断言清单；为每条断言写三层测试；完整跑一遍（不抽样） |
| 跑 | Agent(qa) → ① 段传来的 `affected` 回归范围优先（拿不到则全量）；疑难交互用浏览器 MCP 取证；测试命令取自 `project.md` §六 |
| 输出 | QA 报告（Verdict + 断言追溯矩阵 + Critical Failures 清单 + 回归范围来源标注） |
| 写 | `gates.md`（qa 唯一写者，主控不代写）；补测落测试根（dev / qa 都可写，以 `Agent.md` §三 为准） |
| ✅ 完成后 | 执行 `/cc-code:cc-code` 校准 |

> 需求永远只来自 `prd.md` / `ux.md` / `api.md`，⛔ 不拿代码当尺子；qa 用 codegraph 的权限见 Agent.md codegraph 权限矩阵。

**三层测试矩阵：**

| 层 | 断言类型 | 工具与命令 |
| --- | --- | --- |
| 逻辑 | 纯函数/规则/边界 | 取自 `project.md` §六 |
| 接口 | method/path/状态码/schema/错误码/鉴权/分页 | 取自 `project.md` §六（所需环境变量也在契约里登记） |
| 交互 | ux 五态 + 角色门控 | 取自 `project.md` §六 |

## qa → dev 循环（QA 段内）

1. qa 出 FAIL 清单 → 主控原样喂回 dev。
2. dev 只修不改需求 → ⭐修完重算 `codegraph affected <本轮修改文件>`，主控再调 qa 复测（FAIL 项 + affected 算出的真实影响面；拿不到则退回「同模块已 PASS 项」）。
3. **每轮循环后执行 `/cc-code:cc-code` 校准**。
4. 最多 3 轮：仍 FAIL → 一律交人决策（⛔ 本命令无规划能力，不回规划链，不点名去找谁，直接报告卡点），禁止无限循环。
5. 全绿 → QA 段 PASS。

```
   dev(修复) ◄──── FAIL 清单 ──── qa(复测)
      │                                │
      └────────── 只修不改需求 ─────────┘
                    ≤ 3 轮
        3 轮仍 FAIL → 交人决策
        全绿       → QA 段 PASS
```

## 阶段结算

- QA PASS 后，**主控**在 `backup/milestone-log.md` 追加一行（格式见 `active/Agent.md` 归档规范），⛔ 不写进 `status.md`。
- 主控顺手更新 `status.md`「当前坐标 + 卡点 + 下一步」；`gates.md` 由 qa 写（两个文件都按下方铁律处置）。
- 执行 `/cc-code:cc-code` 校准，确认进入下一阶段。

> ⭐ **写 active 前必过「就地更新 + 搬运归档」**（规则单一出处 = `active/Agent.md` §四第 5 条），各写者只动自己负责的文件。

## MVP 收口（全部阶段 PASS）

1. 执行 `/cc-code:cc-code` 校准，确认 N/N 阶段 PASS、`gates.md` 全关卡通过。
2. **执行 `/cc-code:agent-whole-qa` 做一次全量清算** —— 阶段验收只覆盖各阶段增量，收口前必须逐页逐按钮逐接口穷尽一遍，并跑完修复回环。未过不得收口。
3. **索引体检（静默）**：`codegraph status --json` 确认索引健康 —— 收口报告里的冗余清单与回归范围都建立在索引之上，索引坏了这两项结论不可信。⛔ 只体检不重建，健康时不提。
4. 全量回归：按 `project.md` §六 登记的构建 / 全量测试 / e2e / 冒烟命令全部跑一遍（收口必须全量，不用 `affected` 裁剪 —— 收口的意义就是穷尽）。
5. 派 `dev` 产出 `SETUP.md`（启动与环境说明，内容取自 `project.md` §六 / §八，⛔ 不另立事实）；部署清单以 `project.md` §八 为准，上线走 `/cc-code:deploy`。
6. `backup/milestone-log.md` 追加一行记 MVP 里程碑；`status.md` 只刷新坐标 / 卡点 / 下一步。
7. 报告：可部署 MVP。

## 编排器行为准则

- **你是编排器**：按当前阶段派对应 agent，不在主控里替角色思考，不扮演任何角色。
- **纯执行定位**：发现需求/契约缺漏或自相矛盾 → 停下，主控把 dev 的冲突上报原样交人（dev 已用业务语言写），⛔ 绝不现场发明需求补洞（那是 `/cc-code:plan-mvp` 的职责）。主人裁决后：契约问题派 `architect` 改、需求问题派 `pm` 改，再续跑；主控自己不改。
- **subagent 不能问用户**：dev / qa 要问人的事一律交回主控，由主控交人。
- **每次切阶段前必须 `/cc-code:cc-code` 校准**，禁止凭记忆推进。
- **agent 通用、cc-code 项目特定**：项目约定一律让 agent 读 `.cc_code/active/project.md`，不替它假设。
- 进度以 `status.md` 为准、验收以 `gates.md` 为准。
- 不向用户报告归档细节（Hook 静默）；只报阶段结果与交人决策点。
