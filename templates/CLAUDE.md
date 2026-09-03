# 🧭 CLAUDE.md — cc-code 工作流入口

> 本项目由 **cc-code 极简开发工作流系统**管控。
> 本文件是入口引导，**不存业务状态**。真正的状态机在 `.cc_code/active/`。
> ⚠️ 每次会话开启，必须先执行下述「会话开启协议」，再回答任何问题。

## 🚪 会话开启协议（每次必执行，顺序不可变）

1. Read `.cc_code/active/Agent.md` → 锁定【当前激活角色】+【文件权限路由表】
2. Read `.cc_code/active/status.md` → 获取当前坐标（现在在做什么、卡在哪）
3. 仅按当前角色权限读写对应文件，禁止越权

## ⚖️ 四大铁律（贯穿全会话）

1. **上下文最小化** — 只读当前任务所需最小文件集，禁止全量读取。
2. **决策串行** — 严守 PM → Architect → Dev → QA，当前角色由 `Agent.md` 锁定，禁止跨角色思考。
3. **记忆外部化** — 进度/踩坑/归档全部落到 `.cc_code/` 静态文件，禁止凭记忆作答。
4. **active 三判据** — `active/` 永远保持**最新 + 最完整 + 最纯净**：

```
   最新   ── 同一对象只有一处描述且是当前态 ⛔禁新开「增量 F-n」章节, 就地改写
   最完整 ── 每个待验维度都有稳定编号: A(prd §1.5) 管逻辑/链路/接口, U(ux §2.3) 管 UI/五态
   最纯净 ── 只答「现在是什么」; 过程→docs/plans/, 逐轮验收→docs/qa/, 历史→git
```

写入前三问：① 已有对应小节吗？→ 就地改写。② 在答「现在是什么」吗？→ 否则落 `docs/`。③ 别的层有了吗？→ 只留指针。

## 🔁 角色串行流水线

```
PM ──► Architect ──► Dev ──► QA
(逻辑)   (契约)      (编码)   (验收)
```

每个角色由 `.cc_code/active/Agent.md` 路由表锁定「必读/可写/禁读」，禁止越权。

## 🗂️ 文件索引（按层查，按需读，不要全读）

| 层 | 文件 | 用途 | 维护者 |
| :-- | :--- | :--- | :--- |
| **L0** | `active/Agent.md` | 最高宪法：角色 + 权限路由表 | 人 |
| | `active/status.md` | 当前坐标 + 卡点 + 下一步（里程碑不落此文件） | 当前角色 AI |
| **L1** | `active/prd.md` | 分模块业务逻辑 + 规则 + 验收断言 | PM / plan-prd-mvp / plan-prd-feature |
| **L2** | `active/ux.md` | 视觉规格 + 交互五态矩阵 | PM / plan-prd-feature |
| **L3** | `active/project.md` | 技术宪法（架构 / 选型 / 目录） | Architect / plan-prd-feature |
| | `active/data.md` | 数据契约（interface ↔ DB 列） | Architect / plan-prd-feature |
| | `active/api.md` | 接口契约（method/path/入参/出参/错误码） | Architect / plan-prd-feature |
| **L4** | `active/gates.md` | QA 实测结果 + FAIL 清单（Dev 禁读） | QA |
| — | `backup/` | 冷数据归档：change-log.md / milestone-log.md（人看历史，AI 工作时禁读；格式见 `active/Agent.md` 归档规范） | 各写者追加 |
| — | `references/` | 项目级经验资料库（INDEX 索引，角色按需读） | experience-summary |
| — | `README.md` | 🧭 使用手册（每次 init 自动刷新到最新版，新手指南） | init |
| — | `docs/` | 活跃文档（规格 / 指南 / QA 全量报告） | Architect / PM / QA |
| — | `docs/plans/` | 阶段实现方案 | Architect |
| — | `images/` | 截图（扁平存放） | init 迁移 |
| — | `scripts/` | 散落脚本归档 | init |
| — | `.cc_code_version` | 场域版本戳（决定 init 是否升级迁移） | init |

> ⭐ `plan-prd-feature` 是 MVP 交付后的**增量迭代支线**：plan 模式内锁基线 + 冲突逐条裁决，出关后按层分批切角色**就地收敛改写** L1 / L2 / L3 对应小节（逐批请示，绝不碰 L4 与代码）。

### 信息流铁律

```
   L1 意图 ──► L2 表现 ──► L3 实现 ──► 代码
    ▲                                   │
    └───────── L4 验收 ◄────────────────┘

  L4 只拿 L1 / L2 当尺子；codegraph 只准校准 L3，永不生成 L1 / L2 / L4
```

> **codegraph 角色权限**：PM 完全禁用 ｜ Architect 完全开放 ｜ Dev 只读定位 ｜ QA 双限（只找入口 / 算回归面，**永不当需求尺子**）。完整矩阵见 `active/Agent.md`。索引由 init 静默建立、watcher 自动维护，人无需手动 sync。

### PM 两产物边界（防重合）

| 文件 | 定位 | 不写 |
| :--- | :--- | :--- |
| `prd.md` | 分模块业务逻辑 + 规则 + 验收断言（规则是什么） | UI 规格、接口参数 |
| `ux.md` | 视觉规格 + 交互五态（长什么样、点了怎么变） | 业务规则、字段类型 |

判据：**能脱离界面存在的 → `prd.md`；离开界面就没意义的 → `ux.md`**。
`prd.md` 由 `/cc-code:plan-prd-mvp` 或 PM 维护，单文件动态更新，重大变更归档 `backup/`。

## ⚙️ 角色切换

当当前阶段产物完成或用户明确要求切换：

1. 人更新 `.cc_code/active/Agent.md` 的「当前激活角色」字段。
2. AI 重新 Read `Agent.md` 加载新权限表。
3. 切换前严禁预读下一角色的禁读文件。

## 📌 唯一真相源

- 规则 → `.cc_code/active/prd.md`
- 进度 → `.cc_code/active/status.md`
- 契约 → `.cc_code/active/data.md` / `.cc_code/active/api.md`
- 实测 → `.cc_code/active/gates.md`
- 宪法 → `.cc_code/active/Agent.md`

禁止凭记忆作答；禁止向用户报告归档细节。
