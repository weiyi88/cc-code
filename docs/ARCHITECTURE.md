# cc-code 架构说明

## 双层清单（参考 claude-seo marketplace 模式）

- `.claude-plugin/marketplace.json` — marketplace 元数据 + plugins 列表，供 `/plugin marketplace add` 消费。
- `.claude-plugin/plugin.json` — 单插件清单，声明 name/version/author。

两者并存：marketplace.json 让仓库可作为「插件市场」被添加，plugin.json 描述插件本身。

## 资产分布

```
skills/      11 个目录  → /cc-code:<name> 显式调用 或 自然语言自动触发
agents/       3 个 .md  → prd-plan / dev / qa
hooks/       cc_code_hook.py  (Stop, 纯脚本；无 hooks.json —— 见下)
scripts/     init.sh  (脚手架 + 项目级 hook 注册)
templates/   10 个 .md 骨架  → init 时 cp 进 .cc_code/active/
```

> 历史沿革：早期版本有 `commands/` 目录，现已全部并入 `skills/`（skill 同时支持 `/cc-code:<name>` 显式调用与自动触发，无需两套资产）。

## 寻址约定

- 插件内文件引用统一用 `$CLAUDE_PLUGIN_ROOT/...`。
- skill 内部配套文件用相对路径（如 `whole-qa` 的 `references/*.md`）。

## Hook 为何是项目层级（关键设计）

```
插件不注册全局 Stop hook（已删除 hooks/hooks.json）
        │
        │  /cc-code:init 执行时
        ▼
① cp hooks/cc_code_hook.py ──► <项目>/.cc_code/scripts/cc_code_hook.py
② 安全合并 <项目>/.claude/settings.json 注册 Stop 事件
        │
        ▼
脚本用 __file__ 自定位（parent.parent 即 .cc_code/）
  ├─ 不看 cwd、不向上递归 ──► 绝无跨项目误伤
  └─ 未部署在 .cc_code/scripts/ 下则静默退出
```

旧版靠 `find_cc_code(cwd)` 向上递归找 `.cc_code/`，会跨项目边界误伤祖先目录带黑匣子的无关子项目 —— 已废弃。

## 状态机与冷热分离

详见 `skills/cc-code/SKILL.md` 与 `hooks/cc_code_hook.py`。核心：AI 写热数据（需要理解力），Hook 只做 `errors.md` 冷切片（纯机械），互不越界。`status.md` 由 AI 自管，Hook 不碰。
