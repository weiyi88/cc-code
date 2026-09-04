# cc-code 架构说明

## 双层清单（参考 claude-seo marketplace 模式）

- `.claude-plugin/marketplace.json` — marketplace 元数据 + plugins 列表，供 `/plugin marketplace add` 消费。
- `.claude-plugin/plugin.json` — 单插件清单，声明 name/version/author。

两者并存：marketplace.json 让仓库可作为「插件市场」被添加，plugin.json 描述插件本身。

## 资产分布

```
skills/      16 个目录  → /cc-code:<name> 显式调用 或 自然语言自动触发
agents/       3 个 .md  → prd-plan / dev / qa
scripts/     init.sh  (脚手架 + 散落物迁移)
templates/   9 个 .md 骨架（L0~L4 八件 + bugs.md debug 施工便签）+ references-INDEX.md → init 时 cp 进 .cc_code/
```

> 历史沿革：早期版本有 `commands/` 目录，现已全部并入 `skills/`。
> 0.5.0 起删除 `hooks/`（Stop Hook 机制废除）与 `templates/errors.md` —— 所有 `.cc_code/` 文件由 AI 顺手写，无自动化机械活。

## 寻址约定

- 插件内文件引用统一用 `$CLAUDE_PLUGIN_ROOT/...`。
- skill 内部配套文件用相对路径（如 `whole-qa` 的 `references/*.md`）。

## 状态机

详见 `skills/cc-code/SKILL.md`。核心：所有 `.cc_code/` 文件都由 AI 在对话内顺手写（需理解力），无自动化机械活。`status.md` 长度由 AI 自管（里程碑保留最近 10 条）。

## 规则归属：单一出处（SSOT）分层 — 0.13.1 立规

> **铁律：规则只写在「受众的必经之路」上，且只写一次。**
> 副本是漂移的必要条件 —— 同一条规则一旦存在 N 份，改的时候必然漏改几份，
> 而提示词库**没有测试也没有 CI**，漂移不会报错，只能靠人肉 grep 发现。
> 所以治理方向永远是**删副本**，不是**补副本**。

一条新规则诞生时，按三问定位唯一出处：

```
   ① 换个角色还成立吗？
        ├─ 成立   ──────► templates/Agent.md §四 强制执行协议（全员通用区）
        └─ 不成立 ──────► templates/Agent.md §三 对应那张角色卡
   ② dev / qa / prd-plan 这三个 subagent 需要吗？
        └─ 需要   ──────► 追加写进 agents/{dev,qa,prd-plan}.md
                          （subagent 独立上下文，读不到 Agent.md，
                            自带系统提示词才是它的必经之路 → 不算副本）
   ③ 约束的是「产物长什么样」吗？
        └─ 是     ──────► 写进该文件的模板头部（gates.md / prd.md 等）
   ⛔ 任何情况都不写进 skills/*/SKILL.md 正文
```

| 规则性质 | 唯一出处 | 覆盖谁 | 传导机制 |
| :--- | :--- | :--- | :--- |
| 全员行为 / 输出条款 | `templates/Agent.md` §四 | 所有角色 + 编排器主控 | 校准协议必读 `Agent.md` |
| 角色专属权限 / 能力 | `templates/Agent.md` §三 角色卡 | 该角色 | 「当前激活角色」开关只加载那一张 |
| subagent 自带纪律 | `agents/{dev,qa,prd-plan}.md` | 该 subagent | 系统提示词 |
| 产物格式纪律 | 该文件模板头部 | 写它的角色 | 写前必读该文件 |
| 编排纪律（串行 / ≤3 轮 / 拒跑 / 增量定位） | `skills/*/SKILL.md` 正文 | 编排器主控自己 | 命令本体 |
| 触发闸门 | frontmatter `disable-model-invocation` | Claude Code 引擎 | 引擎强制 |

**角色隔离靠「当前激活角色」开关，不靠拆文件** —— 未激活角色的规则物理上在同一文件，
但被开关挡在外面，一个字都不会污染当前角色。

### 触发闸门只认 frontmatter

`disable-model-invocation: true` 是唯一有效的「禁止模型自动调用」闸门。
正文里写「本命令仅由用户显式触发」**零作用** —— 正文的读者是**已经被调用起来的模型**，
它都跑起来了，再告诉它「你只能被手动调用」毫无意义。
⛔ 故正文不复述触发方式；闸门只在 frontmatter 声明一次。

### codegraph 的两条通道（别再往 allowed-tools 里加不存在的名字）

```
   codegraph status --json / affected / node / callers / impact / files
        └──► CLI 子命令，走 Bash ──► allowed-tools 只需 Bash

   自然语言问「X 怎么工作」
        └──► MCP 工具 ──────────► mcp__codegraph__codegraph_explore
```

codegraph MCP server **只暴露 `codegraph_explore` 一个工具**。
`codegraph_search` / `codegraph_node` / `codegraph_callers` **不是 MCP 工具**，
写进 `allowed-tools` 是死声明：不报错、不生效、只误导后续读者。

## 散落物迁移（init.sh 的判定链）

```
项目根文件 ──► ① 保护白名单？ ──► ② git 已追踪？ ──► ③ 被引用？ ──► ④ 名字像临时物？
                 (任一命中即 SKIP)                              (才搬)
                                                                  ↓ 都不匹配
                                                              原地保留 + 记 needs_review.md
```

旧版「默认搬走 + 排除两个已知文件」会误杀 `setup.py`/`manage.py`/`AGENTS.md`/`build.sh` 等基建 —— 已反转为「默认不动」。

## 场域版本戳与三轨升级

`.cc_code/.cc_code_version` 记录场域形态对应的插件版本，是 `init` 的分流判据：

```
active/Agent.md 存在？
  ├─ 否 ────────────────► Track A/B 新建 + 盖戳
  └─ 是 → 读版本戳
        ├─ == 插件版本 ──► Track C 已最新，只搬散落物
        └─ 缺失 / 更旧 ──► Track D 升级迁移
```

Track D 的顺序是 **归档 → 清点 → 迁移 → 校验 → 归位 → 盖戳**：

```
D1 cp 快照 → backup/YYYY-MM/pre-upgrade-<旧版>/   原位不动，中断不瘸
D2 机械清点 → upgrade_audit.md（四类差异）
D3 AI 按层判据迁移内容                            理解力活
D4 AI 补齐 Agent.md 缺失规范段
D5 ⛔校验门：未着落清单非空即停手
D6 mv 归位 → backup/YYYY-MM/superseded/
D7 盖戳（未过 D5 不许盖）
```

### 为何不裸删

`init.sh` 中 `rm` 出现 0 次。删除会让「迁移有 bug」等价于「用户数据蒸发」，
而 `mv` 让最坏情况退化为「文件位置不对，内容还在」。
配合 D1 只读快照，同一份内容有两处副本，D5 校验门再挡一层。

**戳未盖 = 迁移未完成。** 半成品不会被下次 `init` 误认为已完成 —— 这是幂等性与
「进度必须可信」的交点。
