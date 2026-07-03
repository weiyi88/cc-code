---
name: witness
description: 第一人称视角生成中国近代史短剧脚本。输入历史事件名，自动查证史实、生成沉浸式剧本并标注虚实。当用户说"写脚本"、"历史剧本"、"witness"、"第一人称历史"时触发。
allowed-tools: Read, Glob, Grep, Bash, Edit, Write, Agent, WebSearch, mcp__exa__web_search_exa, mcp__exa__crawling_exa, AskUserQuestion
disable-model-invocation: true
---

# Witness — 第一人称历史短剧脚本生成器

将你放入历史现场，以亲历者的视角生成完整短剧脚本。

## 调用方式

```
/cc-code:witness 鸦片战争              模糊匹配事件，生成脚本
/cc-code:witness 五四运动 --role 学生   指定第一人称角色
/cc-code:witness 辛亥革命 --output ./   指定输出目录
```

## 执行流程

### 第一步：读取引擎协议（用 Read 工具，路径相对本 skill 目录）

1. `engine.md`（脚本生成引擎）
2. `protocol/research.md`（史料查证协议）
3. `protocol/script-format.md`（脚本格式规范）
4. `protocol/annotation.md`（虚实标注规范）

### 第二步：匹配事件

读取 `events/catalog.yaml`，用模糊匹配找到用户请求的历史事件。
- 匹配规则：事件名、别名、关键词、年份均可匹配
- 未匹配到时，用 Exa 搜索确认是否为有效历史事件，再动态添加

### 第三步：查证史实

按 `protocol/research.md` 执行史料查证，获取：事件时间线（精确到日）、核心人物及立场、关键地点与场景、争议点与不同史学观点。

### 第四步：确认角色

- 若用户指定了 `--role`，使用指定角色
- 若未指定，呈现 3 个可选第一人称视角供用户选择：亲历者 / 旁观者 / 决策圈内人

### 第五步：生成脚本

按 `engine.md` 流程生成完整脚本，输出格式遵循 `script-format.md`，虚实标注遵循 `annotation.md`。

### 第六步：保存与追踪

1. 将脚本保存到 `.cc_code/scripts/witness_[event_id]_[date].md`
2. 在记忆系统中记录：事件ID、角色、完成日期、脚本路径
3. 更新 `catalog.yaml` 中该事件的 `completed` 状态

## 重要约束

- 史实查证必须先于脚本生成，不可跳过
- 脚本中每幕必须有虚实标注
- 不美化、不歪曲历史事实
- 人物对白基于史料记载，艺术加工部分必须标注
- 涉及敏感历史事件时，保持客观中立的叙事立场
