# 🧭 .cc_code 使用手册（cc-code 0.8.0）

> 本文件由 `/cc-code:init` 生成并随插件版本刷新，是**给「不熟悉 cc-code 的人」的上手说明书**。
> 项目业务状态永远在 `active/`；本手册只讲「这套系统怎么用」。

---

## 一、这套系统在解决什么问题

LLM 写代码有三病：**写着写着忘了目标、上下文越滚越脏、凭记忆瞎答**。
cc-code 的处方：**把记忆、状态、规则全部外部寄存到 `.cc_code/` 静态文件**，AI 每次会话按协议读文件定位自己，而不是靠脑容量。

```
① 记忆/逻辑/状态全外部寄存 ── 落 .cc_code/ 静态文件
② 责任垂直化 ── 每角色只掌一层，禁止越权
③ 决策串行 ── PM → Architect → Dev → QA，一次只干一个角色
```

---

## 二、核心逻辑：角色串行 + 文件分层

### 角色流水线（同一时刻只有一个角色被激活）

```
PM ──► Architect ──► Dev ──► QA
(需求)   (架构)      (编码)   (验收)
```

「当前是谁」由 `active/Agent.md` 顶部【当前激活角色】锁定。AI 只许按该角色的权限表读写文件，越权即违规。

### 文件分层（先认层，再认角色）

| 层 | 文件 | 装什么 | 谁写 |
| --- | --- | --- | --- |
| **L0 控制** | `active/Agent.md` | 最高宪法：角色 + 权限路由表 | 人 |
| | `active/status.md` | 当前坐标 + 下一步 + 里程碑 | 当前角色 AI |
| **L1 意图** | `active/prd.md` | 分模块业务逻辑 + 规则 + 验收断言 A1..An | PM |
| **L2 表现** | `active/ux.md` | 视觉规格 + 交互五态矩阵 | PM |
| **L3 实现** | `active/project.md` | 技术宪法（架构/选型/决策记录） | Architect |
| | `active/data.md` | 数据契约（interface ↔ DB 列） | Architect |
| | `active/api.md` | 接口契约（method/path/入参/出参/错误码） | Architect |
| **L4 验收** | `active/gates.md` | QA 实测结果 + FAIL 清单（Dev 禁读） | QA |
| — | `references/` | 项目级经验资料库（INDEX 索引，角色按需读；含 bull-redis-queue 示例） | experience-summary |
| — | `docs/plans/` | 阶段实现方案 | Architect |
| — | `docs/qa/` | QA 全量报告 | QA |
| — | `backup/` | 冷数据归档（溯源才翻） | — |
| — | `.cc_code_version` | 场域版本戳 | init |

**信息流单向**：`L1 → L2 → L3 → 代码 → L4 回验`。L4 只拿 L1/L2 当尺子，绝不拿代码当尺子。

---

## 三、Skill 一览（13 个）

### 框架核心（管流程）

| skill | 触发 | 什么时候用 |
| --- | --- | --- |
| `init` | `/cc-code:init` | **入场**。新项目搭场域 / 旧项目接管 / 旧版升级（全程零删除）。装完插件第一件事 |
| `cc-code` | 自动 | 运行时协议（角色路由 + 分层约束），不用手动调 |
| `plan-prd-mvp` | `/cc-code:plan-prd-mvp` | **0→1 定全量需求**。plan 模式内逐点交谈至逻辑通顺，产出 prd.md |
| `plan-prd-feature` | `/cc-code:plan-prd-feature` | **MVP 交付后的功能迭代**。锁基线 + codegraph 算爆炸半径 + 冲突逐条裁决 |
| `agent-to-mvp` | `/cc-code:agent-to-mvp` | **编排实现**。PM→Architect→Dev→QA 串行推进，FAIL≤3 轮回环 |
| `whole-qa` | `/cc-code:whole-qa` | **全量验收**。逐页逐按钮逐接口 + 冗余检测，FAIL≤3 轮修到 PASS |
| `experience-summary` | `/cc-code:experience-summary` | **经验沉淀**。踩坑复盘 → 提炼准则 → 落 `references/` 资料库 |
| `short` | `/cc-code:short` | 极简回复模式（≤50 字符） |

### 工具外挂（干活的，与状态机无关）

| skill | 用途 |
| --- | --- |
| `project_resume` | 读真实技术栈生成项目介绍文案 |
| `login_auto` | Supabase Auth + Resend 通用登录 |
| `vercel_supabase_deployment` | Vercel + Supabase 一键部署 |
| `cf_online` | Next.js 部署到 Cloudflare Pages |
| `next2taro` | Next.js UI → Taro 小程序 |

---

## 四、使用方案：两条路线

### 路线 A：全新项目（0 → MVP）

```
/cc-code:init            ← ① 搭场域（1 分钟）
/cc-code:plan-prd-mvp    ← ② 跟 AI 聊需求，产出 prd.md（最重要的投入）
/cc-code:agent-to-mvp    ← ③ 自动编排实现到验收
/cc-code:whole-qa        ← ④ 全量验收 + 修复闭环
```

### 路线 B：MVP 已交付，加新功能

```
/cc-code:plan-prd-feature  ← ① 增量规划（冲突逐条裁决，出三件套）
/cc-code:agent-to-mvp      ← ② Dev→QA 编排实现
```

### 任意时刻

```
/cc-code:experience-summary  ← 踩了有价值的坑 → 沉淀成 references
/cc-code:init                ← 插件升级后再跑一次，自动迁移场域（零删除）
```

---

## 五、使用示例

### 示例 1：第一次用，项目已有代码

```
你：/cc-code:init
AI：检测到旧项目（Track A）→ 备份旧 CLAUDE.md → 搭场域 → 请你补需求
你：/cc-code:plan-prd-mvp 我要做一个「上传产品图自动生成小红书种草图」的工具
AI：（plan 模式内逐点提问：一套几张？要不要文案？……直到逻辑通顺）
AI：产出 prd.md（含验收断言 A1..A12），请你验收
```

### 示例 2：功能迭代

```
你：/cc-code:plan-prd-feature 加一个「429 限流自动退避重试」
AI：codegraph 侦察现状 → 判定需求三态 → 有冲突逐条请你裁决
AI：落盘增量章节（prd.md F-4 / project.md 第十章 / api.md F-4）
你：切 Dev 角色实现 → 切 QA 验收断言 A12.21~A12.24
```

### 示例 3：踩坑沉淀

```
你：（发现 Redis 重启后队列任务变僵尸，复盘完）
你：/cc-code:experience-summary
AI：提炼「必答三问 + 5 条设计准则」→ 给你过目
你：确认
AI：落 references/architect-bull-redis-queue-references.md + 登记 INDEX
    → 下次任何架构设计涉及队列时，Architect 会先读它
```

---

## 六、references 经验库怎么用

```
角色接到任务 → 先扫 references/INDEX.md → 命中主题才读对应文件
未命中 → 一个都不读，零负担
```

- 文件命名：`[角色]-[事件域]-references.md`（如 `architect-bull-redis-queue-references.md`）
- 内容准则：只写「设计/验收时怎么思考、怎么做」，≤30 行，每条能据此否决一个方案
- 新增入口：永远走 `/cc-code:experience-summary`，不手写

---

## 七、常见疑问

| 疑问 | 答案 |
| --- | --- |
| 我要手动切角色吗？ | 是。更新 `active/Agent.md` 顶部【当前激活角色】一行即可 |
| AI 会自己乱改需求吗？ | 权限表禁止：Dev/QA 禁改 prd/ux；改不动就上报 |
| 旧版场域升级会丢东西吗？ | 不会。全程零删除，旧物只 cp 快照与 mv 归位，永远可回溯 |
| 验收标准在哪？ | `prd.md` §1.5 断言 A1..An（编号永久稳定，作废只加删除线） |
| 实测结果在哪？ | `gates.md`（QA 写，Dev 禁读 —— 防拿答案做题） |

---

> 更多细节：`active/Agent.md`（宪法）+ 插件 README。
