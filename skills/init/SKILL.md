---
description: 初始化 cc-code 极简开发工作流场域。双轨判定(新项目/旧项目接管) → 生成 .cc_code/ 黑匣子目录树与模板骨架 → 进入角色串行状态机循环。
allowed-tools: Read, Write, Edit, Bash, Glob, Grep
disable-model-invocation: true
---

# /cc-code:init — 项目场域初始化

执行 cc-code 工作流的入场协议。

## 第 1 步：双轨判定

扫描当前工作区：

| 探测条件 | 轨道 | 行为 |
| --- | --- | --- |
| 已存在 `.cc_code/active/Agent.md` | — | 场域已就绪，跳过脚手架，直接第 3 步 |
| 存在 `src/` / `package.json` / `go.mod` 等旧代码，或根目录已有 `CLAUDE.md` | Track A 旧项目 | 扫描技术栈+断层，与用户多轮补 PRD，预填 project.md；并执行第 2A 步分拆旧 CLAUDE.md |
| 全空目录 | Track B 新项目 | 直接搭场域，切 PM 角色等待需求 |

## 第 2 步：执行脚手架

```bash
bash "$CLAUDE_PLUGIN_ROOT/scripts/init.sh" "$(pwd)"
```

脚本幂等：已存在 `.cc_code/` 则仅重装 hook + 执行散落物迁移。生成 `active/ backup/ docs/{plans,qa}/ images/ scripts/` + **9 个 active 模板骨架**（按 L0~L5 分层：`Agent status` / `prd` / `ux` / `project data api` / `gates` / `errors`）+ **根目录 `CLAUDE.md` 入口引导** + **项目级 Stop hook 注册**。

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
| 踩过的坑、注意事项、禁用做法 | `active/errors.md` | 按「现象 / 根因 / 预防规则」格式追加；预防规则须能写成「以后禁止/必须…」 |
| 已知 bug、待修清单 | `active/gates.md` | 填入 Critical / Minor Failures |
| 用户交互流程、页面状态机、UI 规格、组件清单、响应式规则 | `active/ux.md` | 填入「全局设计系统 / 逐页布局 + 五态矩阵」 |
| 无法归类的杂项 / 项目背景 | `active/project.md` 的「特殊约束」 | 兜底，绝不丢弃 |

铁律：分拆时每一段信息都要有着落，拿不准的归 `project.md` 兜底；归并完成后旧 `CLAUDE.md` 已被入口模板覆盖，无须保留原状。
**路径联动**：若 legacy 内容引用了被迁移的旧文件名（如 `PRODUCT_SPEC_V2.md`），分拆时须按 `backup/YYYY-MM/migration_manifest.md` 的映射改写为新相对路径（如 `.cc_code/docs/PRODUCT_SPEC_V2.md`）。

## 第 3 步：进入状态机循环

1. Read 根目录 `CLAUDE.md` → 按其「会话开启协议」执行。
2. Read `.cc_code/active/Agent.md` → 锁定当前角色与文件路由权限表。
3. Read `.cc_code/active/status.md` + `errors.md` → 同步坐标与避坑清单。
4. 按 `cc-code` skill 协议持续约束后续行为（热数据由 AI 顺手写，Hook 只做冷热切片）。

## 第 4 步：Hook 接入（项目层级，init.sh 已自动完成）

`init.sh` 已把 `cc_code_hook.py` 复制到 `.cc_code/scripts/`，并**安全合并**进项目 `.claude/settings.json` 注册 Stop 事件（保留用户原有 hooks 与 permissions；已注册则跳过；JSON 解析失败则放弃注册且不修改任何内容）。

```
<项目>/.claude/settings.json  ──注册──►  .cc_code/scripts/cc_code_hook.py
                                              │
                                    __file__ 自定位 parent.parent = .cc_code/
                                              │
                                    唯一职责：errors.md >100 行时冷切片到 backup/
```

**插件不做全局注册**（`hooks/hooks.json` 已删除），因此不会影响其他项目。Hook 为纯 Python 脚本，零 LLM 调用，毫秒级结算，异常吞掉绝不阻塞回合。
`hooks/cc_code_hook.py` 顶部常量可调：`ERRORS_HOT_LIMIT=100`、`ERRORS_KEEP_TAIL=50`。
插件升级后，在项目里重跑 `/cc-code:init` 即可刷新 hook 副本（幂等）。
