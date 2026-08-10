---
name: experience-summary
description: ⭐显式触发的【项目级开发经验沉淀器】。把本次开发中踩坑/排障/方案复盘中暴露的「设计经验」提炼成 references 文件，落项目级 .cc_code/references/，并登记 INDEX.md 实现按需读取。命名规范 [角色]-[具体事件域]-references.md。当主人说 /cc-code:experience-summary 或「沉淀经验」「总结成 references」时触发。不写代码、不动 active/ 状态机。
allowed-tools: Read, Write, Edit, Bash, Glob, Grep, ToolSearch
disable-model-invocation: true
---

# /cc-code:experience-summary — 项目级开发经验沉淀器

> 把「这次踩的坑」变成「下次的准出门槛」。
> 落点是**项目级** `.cc_code/references/`（跟随项目走，不进插件、不进全局）。

## ⛔ 五条铁律

1. **项目级唯一落点**：只写当前项目 `.cc_code/references/`，⛔ 禁写插件目录、全局 `~/.claude/`。
2. **命名规范**：`[角色]-[具体事件域]-references.md`
   - 角色小写：`architect` / `dev` / `qa` / `pm`
   - 事件域 = 技术或流程主题，kebab-case，不含日期
   - ✅ `architect-bull-redis-queue-references.md`
   - ❌ `arch-xp.md`（无事件域）❌ `20260807-bug-references.md`（含日期）
3. **内容精炼**：只写「设计/验收时应该怎么思考、怎么做」，⛔ 禁写溯源叙事、清理修复过程、流水账。
4. **按需读取**：必须登记 `.cc_code/references/INDEX.md`（按角色分组，一行式「何时读」），⛔ 禁要求角色每次全读。
5. **不越权**：⛔ 禁改 `active/` 任何状态文件（Agent.md 权限表、status.md 等）——references 是补充资料，不是状态机。唯一例外：主人当场明确要求把 INDEX 挂进 `Agent.md` 某角色 `[按需读]`，可代笔加一行。

## 执行流程

```
① 定位角色      本次经验归谁：architect / dev / qa / pm
② 提炼准则      从对话/踩坑中抽出「必答问题 + 设计准则」
                每条准则 = 一句话规则 + 一句话为什么
③ 主人过目      先输出草稿给主人看，确认后才落盘（禁先斩后奏）
④ 落盘          写 .cc_code/references/[角色]-[事件域]-references.md
⑤ 登记索引      更新 .cc_code/references/INDEX.md（无则新建）：
                | 文件 | 何时读 |
⑥ 挂载请示      若该角色 Agent.md 未挂 INDEX，请示主人是否加 [按需读] 行
```

## 文件模板

```markdown
# [角色] 事件域经验标题

> 何时读：一句话触发条件（如「设计异步队列/中间件时必读」）。
> 由 /cc-code:experience-summary 沉淀，索引见 INDEX.md。

## 必答 N 问（准出门槛）

1. 故障场景 A → 谁兜底？
2. 故障场景 B → 谁消费？
（答不出 → 方案不准进下一角色）

## 设计准则

- **加粗规则**：一句话解释为什么。
- ……
```

## 质量标准

- 全文 ≤ 30 行；读一遍 ≤ 2 分钟。
- 准则必须可执行（能据此否决一个方案），禁空泛口号（如「注意性能」）。
- 同一事件域已有文件 → 更新该文件，不开新文件。
