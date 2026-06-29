# cc_code 架构说明

## 双层清单（参考 claude-seo marketplace 模式）

- `.claude-plugin/marketplace.json` — marketplace 元数据 + plugins 列表，供 `/plugin marketplace add` 消费。
- `.claude-plugin/plugin.json` — 单插件清单，声明 name/version/author。

两者并存：marketplace.json 让仓库可作为「插件市场」被添加，plugin.json 描述插件本身。

## 资产分布

```
commands/   10 个 .md  → /cc_code:<name>  (显式调用)
skills/      5 个目录  → 自然语言自动触发
hooks/       cc_code_hook.py + hooks.json  (Stop, 纯脚本)
scripts/     init.sh  (脚手架)
templates/   7 个 .md 骨架 + changelog
```

## 寻址约定

- 插件内文件引用统一用 `$CLAUDE_PLUGIN_ROOT/...`（如命令读取 skill 配套文件）。
- skill 内部配套文件用相对路径（如 witness 的 `engine.md`、`protocol/*.md`）。

## 状态机与冷热分离

详见 `skills/cc_code/SKILL.md` 与 `hooks/cc_code_hook.py`。核心：AI 写热数据（需要理解力），Hook 做冷热切片（纯机械），互不越界。
