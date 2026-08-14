# cc-code 架构说明

## 双层清单（参考 claude-seo marketplace 模式）

- `.claude-plugin/marketplace.json` — marketplace 元数据 + plugins 列表，供 `/plugin marketplace add` 消费。
- `.claude-plugin/plugin.json` — 单插件清单，声明 name/version/author。

两者并存：marketplace.json 让仓库可作为「插件市场」被添加，plugin.json 描述插件本身。

## 资产分布

```
skills/      14 个目录  → /cc-code:<name> 显式调用 或 自然语言自动触发
agents/       3 个 .md  → prd-plan / dev / qa
scripts/     init.sh  (脚手架 + 散落物迁移 + dashboard 幂等拉起)
templates/   8 个 .md 骨架 + references-INDEX.md → init 时 cp 进 .cc_code/
dashboard/   parse.js / dispatch.js / server.js / public/index.html
             （0.11.0 新增：只读镜子 + 串行派活控制台，见下方专章）
```

> 历史沿革：早期版本有 `commands/` 目录，现已全部并入 `skills/`。
> 0.5.0 起删除 `hooks/`（Stop Hook 机制废除）与 `templates/errors.md` —— 所有 `.cc_code/` 文件由 AI 顺手写，无自动化机械活。
> 0.11.0 起插件首次引入 Node 运行时（仅 `dashboard/`），是对「零运行时」架构的破坏性变更 —— 详见下方专章。CLI/纯 markdown 形态存档在 `cli` 分支。

## 寻址约定

- 插件内文件引用统一用 `$CLAUDE_PLUGIN_ROOT/...`。
- skill 内部配套文件用相对路径（如 `whole-qa` 的 `references/*.md`）。

## 状态机

详见 `skills/cc-code/SKILL.md`。核心：所有 `.cc_code/` 文件都由 AI 在对话内顺手写（需理解力），无自动化机械活。`status.md` 长度由 AI 自管（里程碑保留最近 10 条）。

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

## Dashboard 只读镜子（0.11.0 新增）

**目的只有两条**：减少用户心智负担、展示 cc-code 系统的运作过程。任何超出这两条
的功能（趋势图、多项目聚合、指标堆砌）都不做。

```
        ┌──────────────── 唯一真相源 ────────────────┐
        │        .cc_code/active/*.md  +  git        │
        └───────────────────────────────────────────┘
              ▲                          │
              │ 写(agent 子进程)           │ 读(解析)
              │                          ▼
        ┌──────────┐              ┌─────────────┐
        │ Dev/QA   │◄─────────────┤  Dashboard  │
        │ agent    │  派活(拖拽)   └─────────────┘
        └──────────┘
```

- **零回 TUI**：看板拖动卡片直接起一个真实的 `claude -p --agent dev/qa` 子进程去改
  代码/测试，不是复制一句话让人回终端粘贴。
- **串行唯一**：cc-code 本身不支持并行，看板"进行中"列硬性只容 1 张卡，其余排 FIFO
  队列，只排不抢，不叫插队。
- **人拖不出 PASS**：拖到"已过"列 = 派 QA 去复验，不是标记通过；卡片最终落位永远由
  `active/*.md` 的内容决定，拖动只是扣扳机。
- **会话续命机制**：dashboard 派出去的 agent 共用一个固定 session id（存
  `.cc_code/.runtime/session`）。`claude --session-id` 只能用一次「出生」，
  之后必须用 `--resume` 续命，否则报 `already in use`。
- **生命周期与 `init` 解耦**：`init` 只搭场域，一次性动作；拉起/复用 dashboard 服务
  是独立命令 `/cc-code:dashboard`，幂等（活着只回地址，死了才重起），每次进项目
  都可以敲。`.cc_code/.runtime/`（pid/端口/session）是运行时产物，不入库、AI 禁读写。
- **零 npm 依赖**：裸 Node.js + 原生 http/fs.watch + 单个 `index.html`（内联
  CSS/JS）。Node 未装 → 静默降级，不阻塞主流程，不自动装 Node。
