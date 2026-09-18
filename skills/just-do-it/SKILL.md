---
name: just-do-it
description: 小改动一句话就干：dev 写完 qa 验，记一笔就完事
allowed-tools: Read, Write, Edit, Bash, Glob, Grep, Agent, TaskCreate, TaskUpdate, TaskList
disable-model-invocation: true
---

# just-do-it — 小改动直通车（零规划零责任）

> **纯执行器**：主人一句话说清的小活（微小改动 / 单个页面 / 小工具），不规划、不定位、不锁角色，dev 写完 qa 验，记一笔就结束。
> **零责任声明**：不做断言对账、不做全量回归、不更新 status/milestone——快，是拿深度换的。
> **与 agent-feature 的分界**：需求一句话说不清、要动契约/动架构、要追溯既有断言 → 拒绝执行，指路 `/cc-code:plan-feature`。

## 前置检查（启动时一次性）

1. 确认双 agent 可用：`dev` / `qa`。
2. 需求可一句话说清（说不清 → 拒跑指路规划，⛔ 不现场推需求）。
3. ⛔ 不需要 `.cc_code/`、不读 prd/ux/project、不读 status.md——需求唯一来源 = 主人原话。

## 运行逻辑

```
主人一句话需求
      │
      ▼
① dev 直接改 + 能跑的自检（lint / build / test，有就跑）
      │
      ▼
② qa 只拿「主人原话」当尺子验一遍
      │
   ┌──┴───────────┐
   ▼              ▼
 FAIL→回dev     PASS
 (≤2轮)          │
   │             ▼
 仍FAIL→报告  ③ gates.md 追加完整记录 → 结束
```

## ① Dev 段（agent: dev）

| 项 | 内容 |
| --- | --- |
| 读 | 仅需求涉及的代码文件（最小集） |
| 做 | 只按主人原话实现；⛔ 不顺手重构无关代码、不擅自扩大范围 |
| 自检 | 项目有 lint / build / test 就跑，没有就跳过（不补基建） |
| 输出 | 改动文件清单 + 每个文件干了啥 + 自检结果 |

## ② QA 段（agent: qa）

| 项 | 内容 |
| --- | --- |
| 尺子 | **只有主人原话**（⛔ 不读 prd 断言、不做追溯矩阵） |
| 验 | 需求点逐条过一遍；能跑则实测，跑不了则代码走查 |
| 输出 | Verdict（PASS / FAIL 清单） |
| 回环 | FAIL → 主控原样喂回 dev，≤2 轮；仍 FAIL → 直接报告交人，⛔ 不硬修 |

## ③ gates.md 记录（唯一善后）

**落点**：项目有 `.cc_code/active/gates.md` → 追加到末尾；没有 → 项目根建 `gates.md`。**只追加，⛔ 不改历史段落。**

每段必须五件套：

```
## just-do-it YYYY-MM-DD HH:mm
- 需求原话：<主人原话，一字不改>
- 改动文件：<文件清单>
- 每个文件干了啥：<逐文件一行说明>
- qa 结论：<PASS / FAIL 要点 + 复测轮数>
- 遗留：<没做完 / 没验到的，没有就写「无」>
```

## 铁律

- **不碰**：status.md / milestone-log.md / prd.md / ux.md / 契约文档。
- **不负责**：不改回滚方案、不做回归承诺、不测无关面——记录在案即免责。
- **中途零确认**：跑完一次性报告结果；只有「需求说不清」和「2 轮仍 FAIL」两种情况才打断主人。
