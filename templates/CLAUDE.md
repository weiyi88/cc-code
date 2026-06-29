# 🧭 CLAUDE.md — cc-code 工作流入口

> 本项目由 **cc-code 极简开发工作流系统**管控。
> 本文件是入口引导，**不存业务状态**。真正的状态机在 `.cc_code/active/`。
> ⚠️ 每次会话开启，必须先执行下述「会话开启协议」，再回答任何问题。

## 🚪 会话开启协议（每次必执行，顺序不可变）

1. Read `.cc_code/active/Agent.md` → 锁定【当前激活角色】+【文件权限路由表】
2. Read `.cc_code/active/status.md` → 获取当前坐标（现在在做什么、卡在哪）
3. Read `.cc_code/active/errors.md` → 扫描避坑清单（写码前必看）
4. 仅按当前角色权限读写对应文件，禁止越权

## ⚖️ 三大铁律（贯穿全会话）

1. **上下文最小化** — 只读当前任务所需最小文件集，禁止全量读取。
2. **决策串行** — 严守 PM → Architect → Dev → QA，当前角色由 `Agent.md` 锁定，禁止跨角色思考。
3. **记忆外部化** — 进度/踩坑/归档全部落到 `.cc_code/` 静态文件，禁止凭记忆作答。

## 🔁 角色串行流水线

```
PM ──► Architect ──► Dev ──► QA
(需求)   (架构)      (编码)   (验收)
```

每个角色由 `.cc_code/active/Agent.md` 路由表锁定「必读/可写/禁读」，禁止越权。

## 🗂️ 文件索引（按需读取，不要全读）

| 文件 | 用途 | 维护者 |
| --- | --- | --- |
| `.cc_code/active/Agent.md` | 最高宪法：角色 + 权限路由表 | 人 / Hook |
| `.cc_code/active/status.md` | 当前坐标 + 下一步 | 当前角色 AI |
| `.cc_code/active/errors.md` | 避坑清单 | Dev |
| `.cc_code/active/project.md` | 技术宪法（架构 / 原则） | Architect |
| `.cc_code/active/flow.md` | 交互状态矩阵 | PM |
| `.cc_code/active/front.md` | 前端交接规格 | PM |
| `.cc_code/active/gates.md` | QA 验收关卡（Dev 禁读） | QA |
| `.cc_code/changelog.md` | 里程碑（Hook 自动写） | Hook |
| `.cc_code/backup/` | 冷数据归档（溯源才翻） | Hook |

## ⚙️ 角色切换

当当前阶段产物完成或用户明确要求切换：

1. 人 / Hook 更新 `.cc_code/active/Agent.md` 的「当前激活角色」字段。
2. AI 重新 Read `Agent.md` 加载新权限表。
3. 切换前严禁预读下一角色的禁读文件。

## 📌 唯一真相源

- 进度 → `.cc_code/active/status.md`
- 踩坑 → `.cc_code/active/errors.md`
- 宪法 → `.cc_code/active/Agent.md`

禁止凭记忆作答；禁止向用户报告归档 / 进度流转细节（Hook 静默完成）。
