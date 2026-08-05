---
description: 初始化 cc-code 极简开发工作流场域。三轨判定(新建/已最新/升级迁移) → 生成 .cc_code/ 黑匣子目录树与模板骨架 → 旧版场域按「归档→清点→迁移→校验→归位」升级到当前插件规范(全程零删除) → 进入角色串行状态机循环。
allowed-tools: Read, Write, Edit, Bash, Glob, Grep
disable-model-invocation: true
---

# /cc-code:init — 项目场域初始化 / 版本升级

执行 cc-code 工作流的入场协议。**同时负责把旧版场域升级到当前插件规范。**

## 第 1 步：三轨判定

扫描当前工作区，由 `.cc_code/.cc_code_version` 版本戳分流：

| 探测条件 | 轨道 | 行为 |
| --- | --- | --- |
| 无 `active/Agent.md`，且存在 `src/` / `package.json` / `go.mod` 等旧代码或根目录已有 `CLAUDE.md` | **Track A** 旧项目接管 | 扫描技术栈+断层，与用户多轮补 PRD，预填 `project.md`；执行第 2A 步分拆旧 `CLAUDE.md` |
| 无 `active/Agent.md`，全空目录 | **Track B** 新项目 | 直接搭场域 + 盖版本戳，切 PM 角色等待需求 |
| 有 `active/Agent.md`，且版本戳 **==** 插件版本 | **Track C** 已最新 | 跳过脚手架，仅执行散落物迁移，直接第 3 步 |
| 有 `active/Agent.md`，但版本戳**缺失或更旧** | **Track D** ⭐升级迁移 | 脚本做 D1 归档 + D2 清点，**AI 按第 2C 步做 D3~D7** |

> ⭐ 版本戳是升级的唯一判据。**戳未盖 = 迁移未完成**，下次 `init` 仍判 Track D，不会把半成品误认为已完成。

## 第 2 步：执行脚手架

```bash
bash "$CLAUDE_PLUGIN_ROOT/scripts/init.sh" "$(pwd)"
```

脚本按三轨自动分流。Track B/A 生成 `active/ backup/ docs/{plans,qa}/ images/ scripts/` + **8 个 active 模板骨架**（按 L0~L4 分层：`Agent status` / `prd` / `ux` / `project data api` / `gates`）+ **根目录 `CLAUDE.md` 入口引导** + **版本戳**。Track C 仅搬散落物。Track D 见第 2C 步。

子命令（供 AI 在升级阶段调用）：

| 命令 | 用途 |
| --- | --- |
| `bash init.sh --relocate <相对路径...>` | 冗余归位：`mv` 进 `backup/YYYY-MM/superseded/`。**零删除**，且拒绝归位规范 8 文件 |
| `bash init.sh --stamp` | 盖版本戳。**仅在 D5 校验门全过后才允许调用** |

散落物迁移采用**「默认不动」判定链**（任一命中即跳过）：① 保护白名单 → ② **git 已追踪**（最强判据：人 commit 过 = 不是垃圾）→ ③ 被 package.json/CI/Dockerfile/源码引用 → 三关全过才做正向识别（名字像临时物/过程报告才搬）→ ④ 都不匹配则**原地保留**并记入 `backup/YYYY-MM/needs_review.md` 交人工判断。搬走的记入 `migration_manifest.md`。同时把 `.cc_code/backup/` 追加进根 `.gitignore`。

> ⚠️ 判定链宁可漏搬也绝不误杀 —— `setup.py` / `manage.py` / `conftest.py` / `AGENTS.md` / `build.sh` / `logo.png` 这类项目基建必须原地不动。

CLAUDE.md 处理（init.sh 自动完成，机械活）：

- **Track B 新项目**：直接 `cp templates/CLAUDE.md → 根目录/CLAUDE.md`。
- **Track A 旧项目**：先把旧 `CLAUDE.md` 备份至 `.cc_code/backup/YYYY-MM/CLAUDE.md.legacy`，再用入口模板覆盖根目录 `CLAUDE.md`。

> 新生成的 `CLAUDE.md` 是**纯入口引导**（会话开启协议 + 三铁律 + 文件索引），不含任何业务状态。Claude Code 原生会自动加载它，从而被引导进 `.cc_code/` 状态机。

## 第 2A 步：Track A 旧 CLAUDE.md 分拆协议（理解力活，由 AI 完成）

仅 Track A 执行。读取 `.cc_code/backup/YYYY-MM/CLAUDE.md.legacy`，按下表把旧内容**只搬运不丢失**地归并到对应文件：

| 旧 CLAUDE.md 中的内容 | 目标文件 | 归并方式 |
| --- | --- | --- |
| 项目角色定义、权限规则、工作流约定、agent 路由 | `active/Agent.md` | 合并进「角色权限路由表」段落，保留模板原有结构 |
| 业务规则、功能逻辑、模块职责、边界约束 | `active/prd.md` | 按模块填入「核心规则 / 边界与异常」 |
| 验收标准、测试要求 | `active/prd.md` 的 §1.5 | 填为**编号稳定**的验收断言（A1..An）；`gates.md` 只装实测结果，不装标准 |
| 技术栈、框架、语言、目录结构、编码原则（KISS/SOLID 等） | `active/project.md` | 填入「技术栈概览 / 目录规约 / 特殊约束」 |
| 数据模型 interface、字段规则、DB 列对齐 | `active/data.md` | 填入「Interface / 字段规则矩阵 / 原型↔真实切换 / DB 列对齐」 |
| API 路由、请求响应格式、错误码 | `active/api.md` | 按模块填入接口契约 + 状态标记 |
| 当前进度、待办、卡点、正在做的模块 | `active/status.md` | 填入「当前坐标 / 下一步目标」 |
| 历史变更、版本记录、里程碑 | `active/status.md` | 填入「最近完成里程碑」，只留最近 10 条 |
| 已知 bug、待修清单 | `active/gates.md` | 填入 Critical / Minor Failures |
| 用户交互流程、页面状态机、UI 规格、组件清单、响应式规则 | `active/ux.md` | 填入「全局设计系统 / 逐页布局 + 五态矩阵」 |
| 无法归类的杂项 / 项目背景 | `active/project.md` 的「特殊约束」 | 兜底，绝不丢弃 |

铁律：分拆时每一段信息都要有着落，拿不准的归 `project.md` 兜底；归并完成后旧 `CLAUDE.md` 已被入口模板覆盖，无须保留原状。
**路径联动**：若 legacy 内容引用了被迁移的旧文件名（如 `PRODUCT_SPEC_V2.md`），分拆时须按 `backup/YYYY-MM/migration_manifest.md` 的映射改写为新相对路径（如 `.cc_code/docs/PRODUCT_SPEC_V2.md`）。

## 第 2C 步：Track D 升级迁移协议（理解力活，由 AI 完成）

仅 Track D 执行。**⛔ 全程零删除铁律：`init.sh` 里没有一句 `rm`。旧物只会被 `cp` 快照与 `mv` 归位，内容永远可回溯。**

```
D1 归档快照   脚本已做：cp active/ + .cc_code 根层 md
              → backup/YYYY-MM/pre-upgrade-<旧版>/    ← 只读后悔药
              原位一个字未动，active/ 全程可用，中断也不瘸
     ▼
D2 清点       脚本已做：→ backup/YYYY-MM/upgrade_audit.md（四类差异表）
     ▼
D3 迁移       ⭐AI：读 audit → 按层判据把内容搬到规范位，一段不丢
     ▼
D4 补层       ⭐AI：按 templates/Agent.md 补齐缺失规范段
     ▼
D5 ⛔校验门   ⭐AI：逐节核对，未全命中即停手报清单，禁止归位
     ▼
D6 归位       ⭐AI：init.sh --relocate（mv 进 superseded/，零删除）
     ▼
D7 盖戳       ⭐AI：init.sh --stamp（仅校验全过才允许）
```

### D3 迁移映射表（按 audit 的四类分别处置）

| audit 类别 | 判据 | 迁移动作 |
| --- | --- | --- |
| ① 规范位缺失 | `active/<canon>.md` 不存在 | 先找同层等价物（见下表）迁入；确实没有 → `cp` 对应 `templates/` 骨架 |
| ② 位置偏离 | 规范文件躺在 `.cc_code/` 根层 | 内容整体迁入 `active/<同名>`；原件留待 D6 归位 |
| ③ 规范外多余 | 文件名不在规范 8 之列 | 按下表分流归并；**兜底 `project.md` 的「特殊约束」，绝不丢弃** |
| ④ 规范位已就位 | 位置对 | 只校验内容是否缺规范段落（D4 处理） |

**规范外文件的归并判据（按内容性质，不看文件名）：**

| 旧文件典型内容 | 归并目标 | 层 |
| --- | --- | --- |
| 交互流程 / 页面状态机 / 五态矩阵 | `active/ux.md` 五态矩阵段 | L2 |
| 视觉规格 / 逐页布局 / 组件清单 / i18n key | `active/ux.md` 视觉规格段 | L2 |
| 业务规则 / 模块职责 / 验收标准 | `active/prd.md` | L1 |
| 阶段实现方案 / 任务拆分 | `docs/plans/` | — |
| 历史变更 / 版本记录 / 里程碑 | `active/status.md` 里程碑（只留最近 10 条），全文留在 D1 快照 | L0 |
| 踩坑记录（`errors.md`，**0.5.0 已废除**） | 不并入 active/；D1 快照已存档，在 `project.md` 特殊约束留一行指针 | — |
| 数据模型 / 字段规则 | `active/data.md` | L3 |
| 接口 / 错误码 | `active/api.md` | L3 |
| 无法归类 | `active/project.md` 特殊约束（兜底） | L3 |

> ⚠️ **拆分偏离**（旧版把 L2 拆成多个文件，如 `flow.md` + `front.md`）→ 按上表两行分别并入同一个 `ux.md` 的不同段落，**不是二选一，是都要**。
> ⚠️ 断言编号迁移时**永久稳定**：旧编号原样保留，作废只加删除线，绝不重排、绝不复用。若旧版另起了字母段（如 `B1..Bn`），**报告主人由其定夺**沿用还是归正，AI 不擅自改。

### D4 补层：Agent.md 缺失规范段

比对项目 `active/Agent.md` ⟷ `templates/Agent.md`，补齐缺失段落，**保留项目已填的角色权限自定义**（只加不覆盖）：

| 规范段落 | 缺了会怎样 |
| --- | --- |
| 「文件分层」L0~L4 表 | AI 不知道层模型，落盘会串层 |
| 「信息流铁律」（含 codegraph 只准校准 L3） | codegraph 会反向污染需求层 |
| PM「两产物边界」+ 断言编号永久稳定纪律 | `prd.md` 与 `ux.md` 内容互相渗透 |
| Architect「契约纪律」（漂移禁沉默） | 代码偏离契约无人发现 |
| QA「灰盒定义」 | QA 退化为拿代码验代码 |

### D5 校验门（⛔ 未过禁止进 D6）

```
逐条核对 D1 快照里每个旧文件的每一节：
  ├─ 在新规范位找到对应内容？
  │    ├─ 是 → 记入迁移映射表
  │    └─ 否 → 记入「未着落清单」
  └─ 未着落清单非空
       ⛔ 停手：报清单给主人，禁止调 --relocate、禁止调 --stamp
       → 主人裁决每一条（补迁 / 确认可弃 / 延后）后才放行
```

辅助校验（机械，可跑）：新规范位文件字节数 ≥ 对应旧文件之和的合理比例；旧文件的每个 `## ` 标题都能在新位置检索到。

### D6 归位（零删除的「清理」）

```bash
bash "$CLAUDE_PLUGIN_ROOT/scripts/init.sh" --relocate \
     active/<已迁移的旧文件> ... <根层冗余.md> ...
```

| 类别 | 举例 | 归位么 |
| --- | --- | --- |
| 位置偏离的原件 | `prd.md`（已迁入 `active/`） | ✅ 归位 |
| 拆分偏离的分片 | `flow.md` `front.md`（已并入 `ux.md`） | ✅ 归位 |
| 规范外已归并 | `plan.md` `changelog.md` `index.md` | ✅ 归位 |
| 规范外已废除 | `errors.md` | ✅ 归位（内容在 D1 快照 + superseded） |
| 规范 8 文件本体 | `active/prd.md` 等 | ❌ 脚本会**拒绝**，绝不归位 |
| `backup/` | 全部 | ❌ 绝不动，冷数据是最后防线 |
| `docs/` `images/` `scripts/` `tests/` | 全部 | ❌ 只在报告里清点，交主人处置 |
| 项目源码 / 测试目录 | `src/` 等 | ❌ Dev 域，绝不碰 |

### D7 盖戳 + 报告

```bash
bash "$CLAUDE_PLUGIN_ROOT/scripts/init.sh" --stamp
```

最后向主人报三张表：**迁移映射表**（旧位 → 新位 → 校验结果）、**归位清单**（原位 → `superseded/`）、**未着落清单**（应为空）。并注明 D1 快照位置作为回滚点。

## 第 3 步：进入状态机循环

1. Read 根目录 `CLAUDE.md` → 按其「会话开启协议」执行。
2. Read `.cc_code/active/Agent.md` → 锁定当前角色与文件路由权限表。
3. Read `.cc_code/active/status.md` → 同步坐标。
4. 按 `cc-code` skill 协议持续约束后续行为（所有热数据由 AI 顺手写）。
