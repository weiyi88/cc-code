---
name: experience-summary
description: 手动整理经验：把你当场说的话原样交给 curator，由它静默归档进经验库
allowed-tools: Read, Agent, SendMessage, ToolSearch
disable-model-invocation: true
---

# /cc-code:experience-summary — 手动经验入口

> 经验平时由 curator 在每次结算后自动整理，主人零操作。
> 这条命令只给一种场合：**你想当场补一条自动流程没抓到的经验**。

## 它做什么

```
  主人：/cc-code:experience-summary <当场说的话>
        │
        ▼
  主控：把主人的话【原样】交给 curator（后台派单，不改写、不总结、不替它分级）；本回合不等结果
        │
        ▼
  curator：自己决定写不写、写到哪一级、怎么写；静默完成
        │
        ▼
  主控：curator 完成的通知到达后，把它那一行原样告诉主人（「无变化」就只说没有新增）；
        这是主人主动发起的入口，所以无论有无变化都回一句，不适用 `Agent.md` §五 的「无变化不出声」
```

## 主控怎么做

- 任务说明只写两样：**主人原话**，以及「手动整理：按 curator 规范第二节『手动整理』处理」。
- ⛔ 主控不判断值不值得写、不分级、不命名主题、不读写任何经验库——这些全是 curator 的事。
- 整理细则（分级、条目格式、去重、自检、生命周期）和经验的使用规则，只在 `curator` agent 规范与 `Agent.md` §四第 7 条各写一次，本文件不复述。
- 主人没说内容：这是本命令**唯一允许的追问**——只回一句请他把要记的话直接说出来，其余不追问细节。
