# cc-code 架构说明

## 双层清单（参考 claude-seo marketplace 模式）

- `.claude-plugin/marketplace.json` — marketplace 元数据 + plugins 列表，供 `/plugin marketplace add` 消费。
- `.claude-plugin/plugin.json` — 单插件清单，声明 name/version/author。

两者并存：marketplace.json 让仓库可作为「插件市场」被添加，plugin.json 描述插件本身。

## 资产分布

```
skills/      11 个目录  → /cc-code:<name> 显式调用 或 自然语言自动触发
agents/       3 个 .md  → prd-plan / dev / qa
scripts/     init.sh  (脚手架 + 散落物迁移)
templates/   8 个 .md 骨架  → init 时 cp 进 .cc_code/active/
```

> 历史沿革：早期版本有 `commands/` 目录，现已全部并入 `skills/`。
> 0.5.0 起删除 `hooks/`（Stop Hook 机制废除）与 `templates/errors.md` —— 所有 `.cc_code/` 文件由 AI 顺手写，无自动化机械活。

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
