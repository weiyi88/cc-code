# 🧭 .cc_code 使用手册（cc-code 0.13.1）

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
| | `active/status.md` | 当前坐标 + 卡点 + 下一步（里程碑不落此文件） | 当前角色 AI |
| **L1 意图** | `active/prd.md` | 分模块业务逻辑 + 规则 + 验收断言 A1..An | PM |
| **L2 表现** | `active/ux.md` | 视觉规格 + 交互五态矩阵 | PM |
| **L3 实现** | `active/project.md` | 技术宪法（架构/选型/决策记录） | Architect |
| | `active/data.md` | 数据契约（interface ↔ DB 列） | Architect |
| | `active/api.md` | 接口契约（method/path/入参/出参/错误码） | Architect |
| **L4 验收** | `active/gates.md` | QA 实测结果 + FAIL 清单（Dev 禁读） | QA |
| — | `active/bugs.md` | 未修复 bug 工作上下文（B-n 施工便签，修完即删） | debug-plan 写 / debug-qa-dev 结算删 |
| — | `references/` | 项目级经验资料库（INDEX 索引，角色按需读；含 bull-redis-queue 示例） | experience-summary |
| — | `docs/qa/` | QA 全量报告 | QA |
| — | `backup/` | 冷数据归档：change-log.md / milestone-log.md（人看历史，AI 工作时禁读） | 各写者追加 |
| — | `.cc_code_version` | 场域版本戳 | init |

**信息流单向**：`L1 → L2 → L3 → 代码 → L4 回验`。L4 只拿 L1/L2 当尺子，绝不拿代码当尺子。

---

## 三、Skill 一览（16 个）

### 框架核心（管流程）

| skill | 触发 | 什么时候用 |
| --- | --- | --- |
| `init` | `/cc-code:init` | **入场**。新项目搭场域 / 旧项目接管 / 旧版升级（全程零删除）。装完插件第一件事 |
| `cc-code` | 自动 | 运行时协议（角色路由 + 分层约束），不用手动调 |
| `plan-prd-mvp` | `/cc-code:plan-prd-mvp` | **0→1 定全量需求**。plan 模式内逐点交谈至逻辑通顺，产出 prd/ux/project/data/api 五件（落盘即定稿） |
| `plan-prd-feature` | `/cc-code:plan-prd-feature` | **MVP 交付后的功能迭代**。锁基线 + codegraph 算爆炸半径 + 冲突逐条裁决，落盘即定稿 |
| `agent-to-mvp` | `/cc-code:agent-to-mvp` | **纯执行**。读定稿文档，Dev→QA 串行推进，FAIL≤3 轮回环，whole-qa 收口 |
| `agent-to-feature` | `/cc-code:agent-to-feature` | **增量纯执行**。增量定位（status.md 点名断言 − gates 已 PASS）→ Dev→QA，精准回归，无全量清算 |
| `whole-qa` | `/cc-code:whole-qa` | **全量验收**。逐页逐按钮逐接口 + 冗余检测，FAIL≤3 轮修到 PASS |
| `debug-plan` | `/cc-code:debug-plan` | **bug 诊断**。plan 模式内问诊 + codegraph 查脉络 + 裁决门 + 三件套确认，落盘 B-n 到 `bugs.md` |
| `debug-qa-dev` | `/cc-code:debug-qa-dev` | **bug 修复纯执行**。增量定位 B-n → Dev→QA + affected 精准回归，回归测试留守 |
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
/cc-code:plan-prd-mvp    ← ② 跟 AI 聊需求，产出五件规划文档（最重要的投入）
/cc-code:agent-to-mvp    ← ③ 纯执行：Dev→QA 到收口（中途零确认）
/cc-code:whole-qa        ← ④ 全量验收 + 修复闭环
```

### 路线 B：MVP 已交付，加新功能

```
/cc-code:plan-prd-feature  ← ① 增量规划（冲突逐条裁决，落盘即定稿）
/cc-code:agent-to-feature  ← ② 增量纯执行：定位 → Dev→QA（精准回归）
```

### 路线 C：修 bug（需求明确，只是实现错了）

```
/cc-code:debug-plan        ← ① 诊断（plan 模式问诊 + codegraph 查脉络
                               + 三件套确认 → 落盘 B-n 到 active/bugs.md）
/cc-code:debug-qa-dev      ← ② 修复纯执行：定位 B-n → Dev→QA
                               （B-n 用例 + affected 精准回归 + 回归测试留守）
```

**何时走哪条线（决策表）**：

| 你的情况 | 走 | 不走 |
| --- | --- | --- |
| 需求模糊，要新增/改动功能 | 路线 B（plan-prd-feature） | debug 链（bug 不发明需求） |
| 行为错了，期望行为说得清（或有既有断言） | 路线 C（debug-plan） | 路线 B（别用 30 分钟需求仪式修 bug） |
| 修复需要改契约/改需求 | 路线 B | debug 链会拒修并指路 |

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
AI：产出五件规划文档（prd 含验收断言 A1..A12 / ux / project / data / api），落盘即定稿
```

### 示例 2：功能迭代

```
你：/cc-code:plan-prd-feature 加一个「429 限流自动退避重试」
AI：codegraph 侦察现状 → 判定需求三态 → 有冲突逐条请你裁决
AI：就地收敛落盘（prd.md 改写模块小节 + 断言进 §1.5 主表 / api.md 改写该 path 小节）
    过程不落盘　back_up/change-log.md 追加 1 行　status.md 点名 F-n + 新断言号
你：/cc-code:agent-to-feature
AI：增量定位 → Dev 实现 → QA 验收断言 A12.21~A12.24（affected 精准回归）
```

### 示例 3：修 bug

```
你：/cc-code:debug-plan 登录连点两次，第二次 401
AI：（plan 模式内）问复现 → codegraph 追链路算影响半径 → 定位根因
    → 出三件套（逻辑图 + 差异表）请你确认
你：确认
AI：落盘 active/bugs.md 的 B-1 条目（复现/期望出处 A12.4/根因/方案/影响面）
你：/cc-code:debug-qa-dev
AI：定位 B-1 → Dev 修 → QA 复验（B-1 用例 + affected 回归 + 留一个回归测试）
    → gates 记 ✅ → bugs.md 删条目 → milestone-log 一行
```

### 示例 4：踩坑沉淀

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
