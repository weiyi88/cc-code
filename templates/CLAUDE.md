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
   尺子   ── 结果对照需求（prd / ux / design / api / data），由 qa 用测试取证；不审实现过程
   落盘   ── 只存结论（是什么、错在哪、影响什么、怎么修）；过程不落盘
   对主人 ── 只讲结果和影响（业务语言），不讲怎么实现
   人介入 ── 只在结果对不上需求、或需求本身要改时；其余流程自行推进
```

## ⚖️ 五大铁律（贯穿全会话）

1. **上下文最小化** — 只读当前任务所需最小文件集，禁止全量读取。
2. **决策串行** — 严守 pm → uiux → architect → dev → qa，派哪个 agent 就是哪个角色，禁止越权、禁止主控代笔（含 init / 升级 / 迁移：要改某角色文件，一律派它的写者 agent，主控自己不 Edit / Write）。
3. **记忆外部化** — 进度/踩坑/归档全部落到 `.cc_code/` 静态文件，禁止凭记忆作答。
4. **active 三判据** — `active/` 永远保持**最新 + 最完整 + 最纯净**：

```
   最新   ── 同一对象只有一处描述且是当前态 ⛔禁新开「增量 F-n」章节, 就地改写
   最完整 ── 每个待验维度都有稳定编号: A(prd §1.5) 管逻辑/链路/接口,
             U(ux §2.3) 管 UI/五态, V(gates §2.4 V 段) 管视觉(页面 × 适用规则组)
   最纯净 ── 只答「现在是什么」; 过程不落盘(change-log 留痕), 逐轮验收→.cc_code/docs/qa/
             过期内容 → backup/retired/<源文件名>.md（原文整段搬走, 一字不丢）
```

写入前三问：① 已有对应小节吗？→ 就地改写。② 在答「现在是什么」吗？→ 否则落 `docs/`。③ 别的层有了吗？→ 只留指针。

5. **就地更新 + 搬运归档** — 写 `active/` 只动有变化的那几行；新增插进它该在的小节；过期内容原文整段搬进 `backup/retired/` 后从 active 移除。⛔ 不整份重写、⛔ 不往末尾追加、⛔ 不删内容、⛔ 不碰别人负责的文件。细则见 `Agent.md` §四第 5 条（单一出处，此处仅指向）。

> 🗣️ **对用户说话**：给用户的话一律说人话——逻辑用图、数据用表、不出现编号和内部术语、不贴代码。细则见 `Agent.md` §四第 6 条（单一出处，此处仅指向）。

## 🔁 agent 串行流水线

```
pm ──► uiux ──► architect ──► dev ──► qa
(逻辑) (交互+长相) (契约)     (编码)   (验收)
                                     主控 = 编排者，只传话、只写 status / 里程碑行
                                     结算后：curator 后台静默整理经验（唯一写者）
                                     风格实现：agent-uiux 编排 dev → qa（不派 uiux）
```

每个 agent 的「必读 / 可写 / 禁读」只在 `.cc_code/active/Agent.md` §三 写一次（单一出处，此处仅指向）。

## 🗂️ 文件索引（按层查，按需读，不要全读）

> 每个文件归谁写、谁能读，只看 `active/Agent.md` §二 / §三（单一出处，此处不列写者）。

| 层 | 文件 | 用途 |
| :-- | :--- | :--- |
| **L0** | `active/Agent.md` | 最高宪法：agent 分工 + 权限卡片 + 谁写哪个文件 |
| | `active/status.md` | 当前坐标 + 卡点 + 下一步（含「风格：」坐标行；里程碑不落此文件） |
| **L1** | `active/prd.md` | 分模块业务逻辑 + 规则 + 验收断言 + §〇 需求摘要（端与形态结论、推荐栈与家族） |
| **L2** | `active/ux.md` | 交互与布局：前端形态表 / 页面清单 / ASCII 原型 / 组件清单 / 五态矩阵 / 断点布局 / 跨页流转 |
| | `active/design.md` | 风格与长相：色彩 / 字体排版 / 间距栅格 / 形状深度 / 动效 / 图标图像 / 组件长相 / 各端主题映射 |
| **L3** | `active/project.md` | 技术宪法（架构 / 选型 / 目录 / §一.1 前端组件库家族 / §六 视觉检查基建 / §九 视觉地基阶段 / 测试基建契约 / 部署契约 / 阶段与泳道） |
| | `active/data.md` | 数据契约（interface ↔ DB 列） |
| | `active/api.md` | 接口契约（method/path/入参/出参/错误码） |
| **L4** | `active/gates.md` | QA 实测结果 + FAIL 清单（含 §2.4 V 段视觉结果） |
| — | `active/bugs.md` | 未修复 bug 工作上下文（B-n 施工便签，常态为空） |
| — | `.cc_code/design/` | 方向卡、风格样板板与样板板截图（`plan-uiux` 产物，不是项目代码；uiux 写） |
| — | `.cc_code/test/visual/` | 视觉机器检查测试（qa 写）；`baseline/` 为截图基线（qa 独占写、入 git） |
| — | `.cc_code/docs/qa/` | 逐轮验收报告与合集板（qa 写） |
| — | `backup/` | 冷数据归档：change-log.md / milestone-log.md / `retired/` 退役原文（人看历史，AI 工作时禁读；格式见 `active/Agent.md` 归档规范） |
| — | `references/` | 项目级经验资料库（INDEX 渐进式披露 + 主题文件 + `archive/` + `log/`；curator 结算后全自动整理，architect / dev 按需读，规则见 `active/Agent.md` §四第 7 条） |
| — | `README.md` | 🧭 使用手册（每次 init 自动刷新到最新版，新手指南） |
| — | `docs/` | 活跃文档（规格 / 指南 / QA 全量报告） |
| — | `images/` · `scripts/` | 截图（扁平存放）· 散落脚本归档 |
| — | `.cc_code_version` | 场域版本戳（决定 init 是否升级迁移） |

> 🧭 **命令怎么选**：需求模糊 → `plan-feature`；需求明确但实现错了 → `plan-debug` → `agent-debug`；定风格 / 改版 → `plan-uiux` → `agent-uiux`；交付审查平台 → `pr`；上线 → `deploy`。各命令的流程与门只在命令正文，完整用法见 `.cc_code/README.md`。

### 信息流铁律

```
   L1 意图 ──► L2 表现 ──► L3 实现 ──► 代码
    ▲                                   │
    └───────── L4 验收 ◄────────────────┘

  L4 只拿 L1 / L2 当尺子（L2 含 ux.md 与 design.md）；codegraph 只准校准 L3，永不生成 L1 / L2 / design / L4
```

> 角色权限（pm 单产物边界、uiux 双文件边界等）唯一出处 = `active/Agent.md` §三，codegraph 谁能用到什么程度见其 codegraph 权限矩阵，此处不复述。索引由 init 静默建立、watcher 自动维护，人无需手动 sync。

## 📌 唯一真相源

规则 → `prd.md` · 风格 → `design.md`（视觉数值唯一处）· 进度 → `status.md` · 契约 → `data.md` / `api.md` · 实测 → `gates.md` · 宪法 → `Agent.md`（均在 `.cc_code/active/`）。禁止凭记忆作答；禁止向用户报告归档细节。
