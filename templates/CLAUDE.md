# 🧭 CLAUDE.md — cc-code 工作流入口

> 本项目由 **cc-code 极简开发工作流系统**管控。
> 本文件是入口引导，**不存业务状态**。真正的状态机在 `.cc_code/active/`。
> 本文件（及软链 `AGENTS.md`）与 `active/Agent.md` 同为**插件规范文件**，唯一写者 = init 脚本（升级时先快照、再机械覆盖为插件模板新版）；⛔ 主控 / 任何 agent 都不手改，项目差异一律写进 `active/project.md`（architect 写）。
> ⚠️ 每次会话开启，必须先执行下述「会话开启协议」，再回答任何问题。

## 🚪 会话开启协议（每次必执行，顺序不可变）

1. Read `.cc_code/active/Agent.md` → 认清分工（主控是编排者，角色 = 被派出的 agent）+【agent 权限卡片】
2. Read `.cc_code/active/status.md` → 获取当前坐标（现在在做什么、卡在哪）
3. 仅按 `Agent.md` §三 对应 agent 的权限读写文件，禁止越权；主控不扮演任何 agent、不代写任何角色文件

## 🏛️ 宪法原则（凌驾于下列铁律之上，冲突时以此为准）

**只对结果负责，不在乎过程。** agent 写代码很快，唯一要问的是：结果符合需求吗？

```
   尺子   ── 结果对照需求（prd / ux / api / data），由 qa 用测试取证；不审实现过程
   落盘   ── 只存结论（是什么、错在哪、影响什么、怎么修）；过程不落盘
   对主人 ── 只讲结果和影响（业务语言），不讲怎么实现
   人介入 ── 只在结果对不上需求、或需求本身要改时；其余流程自行推进
```

## ⚖️ 五大铁律（贯穿全会话）

1. **上下文最小化** — 只读当前任务所需最小文件集，禁止全量读取。
2. **决策串行** — 严守 pm → architect → dev → qa，派哪个 agent 就是哪个角色，禁止越权、禁止主控代笔（含 init / 升级 / 迁移：要改某角色文件，一律派它的写者 agent，主控自己不 Edit / Write）。
3. **记忆外部化** — 进度/踩坑/归档全部落到 `.cc_code/` 静态文件，禁止凭记忆作答。
4. **active 三判据** — `active/` 永远保持**最新 + 最完整 + 最纯净**：

```
   最新   ── 同一对象只有一处描述且是当前态 ⛔禁新开「增量 F-n」章节, 就地改写
   最完整 ── 每个待验维度都有稳定编号: A(prd §1.5) 管逻辑/链路/接口, U(ux §2.3) 管 UI/五态
   最纯净 ── 只答「现在是什么」; 过程不落盘(change-log 留痕), 逐轮验收→docs/qa/
             过期内容 → backup/retired/<源文件名>.md（原文整段搬走, 一字不丢）
```

写入前三问：① 已有对应小节吗？→ 就地改写。② 在答「现在是什么」吗？→ 否则落 `docs/`。③ 别的层有了吗？→ 只留指针。

5. **就地更新 + 搬运归档** — 写 `active/` 只动有变化的那几行；新增插进它该在的小节；过期内容原文整段搬进 `backup/retired/` 后从 active 移除。⛔ 不整份重写、⛔ 不往末尾追加、⛔ 不删内容、⛔ 不碰别人负责的文件。细则见 `Agent.md` §四第 5 条（单一出处，此处仅指向）。

> 🗣️ **对用户说话**：给用户的话一律说人话——逻辑用图、数据用表、不出现编号和内部术语、不贴代码。细则见 `Agent.md` §四第 6 条（单一出处，此处仅指向）。

## 🔁 agent 串行流水线

```
pm ──► architect ──► dev ──► qa          旁路：uiux（只被 plan-uiux 派）
(逻辑)   (契约)      (编码)   (验收)       主控 = 编排者，只传话、只写 status / 里程碑行
```

每个 agent 的「必读 / 可写 / 禁读」只在 `.cc_code/active/Agent.md` §三 写一次（单一出处，此处仅指向）。

## 🗂️ 文件索引（按层查，按需读，不要全读）

> 每个文件归谁写、谁能读，只看 `active/Agent.md` §二 / §三（单一出处，此处不列写者）。

| 层 | 文件 | 用途 |
| :-- | :--- | :--- |
| **L0** | `active/Agent.md` | 最高宪法：agent 分工 + 权限卡片 + 谁写哪个文件 |
| | `active/status.md` | 当前坐标 + 卡点 + 下一步（里程碑不落此文件） |
| **L1** | `active/prd.md` | 分模块业务逻辑 + 规则 + 验收断言 |
| **L2** | `active/ux.md` | 视觉规格 + 交互五态矩阵 |
| **L3** | `active/project.md` | 技术宪法（架构 / 选型 / 目录 / 测试基建契约 / 部署契约 / 阶段与泳道） |
| | `active/data.md` | 数据契约（interface ↔ DB 列） |
| | `active/api.md` | 接口契约（method/path/入参/出参/错误码） |
| **L4** | `active/gates.md` | QA 实测结果 + FAIL 清单 |
| — | `active/bugs.md` | 未修复 bug 工作上下文（B-n 施工便签，常态为空） |
| — | 根目录 `design.pen` | 前端可视化原型（pen 模式时视觉唯一出处；⭐加密文件只准 pencil MCP 读写） |
| — | `backup/` | 冷数据归档：change-log.md / milestone-log.md / `retired/` 退役原文（人看历史，AI 工作时禁读；格式见 `active/Agent.md` 归档规范） |
| — | `references/` | 项目级经验资料库（INDEX 索引，agent 按需读） |
| — | `README.md` | 🧭 使用手册（每次 init 自动刷新到最新版，新手指南） |
| — | `docs/` | 活跃文档（规格 / 指南 / QA 全量报告） |
| — | `images/` | 截图（扁平存放） |
| — | `scripts/` | 散落脚本归档 |
| — | `.cc_code_version` | 场域版本戳（决定 init 是否升级迁移） |

> ⭐ `plan-feature` 是 MVP 交付后的**增量迭代支线**：主控只传话，先派 pm 把需求问通并经主人批准后落盘 L1 / L2，再派 architect 把技术方案问通并经主人批准后落盘 L3，均**就地收敛改写**对应小节（绝不碰 L4 与代码）。
>
> 🖌️ **uiux 支线（前端可视化原型，可选）**：`/cc-code:plan-uiux`（风格锁 → 串行逐页派 uiux agent 画 design.pen → 主人逐页确认 → 自动保存）。分工：`ux.md` 是行为半边（清单/testid/流转/五态），`design.pen` 是视觉半边（布局/色值/组件长相），同一事实只落一处。
>
> 🐛 **debug 链路（bug 修复支线，需求明确但实现错了时用）**：`/cc-code:plan-debug`（不进 plan 模式，主控只传话：派 qa 复现取证并即时记 B-n → 派 dev 只读诊断 → qa 补全，记录不等批准；仅契约错 / 需求错 / 找不到期望出处 / 复现不了才停下交人裁决）→ `/cc-code:agent-debug`（只接 状态 = 待修复 的 B-n → dev 修 → qa 复测 + affected 精准回归，修复通过的硬条件 = 回归测试存在且通过）。与 `plan-feature` 的分界：那个处理**需求模糊**，debug 处理**需求明确但实现错了**；根因落在契约 / 需求上 → 主人裁决后由 architect / pm 改文档，再修。

### 信息流铁律

```
   L1 意图 ──► L2 表现 ──► L3 实现 ──► 代码
    ▲                                   │
    └───────── L4 验收 ◄────────────────┘

  L4 只拿 L1 / L2 当尺子；codegraph 只准校准 L3，永不生成 L1 / L2 / L4
```

> 角色权限（pm 两产物边界等）唯一出处 = `active/Agent.md` §三，codegraph 谁能用到什么程度见其 codegraph 权限矩阵，此处不复述。索引由 init 静默建立、watcher 自动维护，人无需手动 sync。

## 📌 唯一真相源

- 规则 → `.cc_code/active/prd.md`
- 进度 → `.cc_code/active/status.md`
- 契约 → `.cc_code/active/data.md` / `.cc_code/active/api.md`
- 实测 → `.cc_code/active/gates.md`
- 宪法 → `.cc_code/active/Agent.md`

禁止凭记忆作答；禁止向用户报告归档细节。
