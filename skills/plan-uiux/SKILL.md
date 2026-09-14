---
name: plan-uiux
description: 先试画 2 页定风格，再逐页画进设计稿，每页经你确认才保存
allowed-tools: Read, Write, Edit, Bash, Glob, Grep, Agent, ToolSearch, Skill, mcp__pencil__execute, mcp__pencil__get_app_state, mcp__pencil__get_style, mcp__pencil__read_skill
disable-model-invocation: true
---

# /cc-code:plan-uiux — 前端原型绘制器

> **状态：占位骨架（1.0.0）。** 本 skill 已定方向但施工规格未定稿，多个前端风格 skill 尚在并行调试中。
> 在正式定稿前，本文件只锁边界与铁律，具体阶段流程由 uiux subagent 调试结论回填。

## 一、定位

| 项 | 说明 |
| --- | --- |
| 解决什么 | ux.md 文字规格 → design.pen 可视化原型（主人看得见、改得动的真图） |
| 不解决什么 | 业务逻辑（plan-mvp 管）、代码生成（agent-mvp Dev 阶段的 pen 底稿管） |
| 前置 | `ux.md` 已有页面清单（plan-mvp / plan-feature 落盘），或存量项目有前端代码可逆向 |
| 产出 | 根目录 `design.pen`：P-n 页面帧 + M-n 弹窗帧 + reusable 组件 + design tokens |
| 配对 | 画完之后执行走 `/cc-code:agent-mvp` / `/cc-code:agent-feature`（Dev 读 pen 当视觉依据） |

## 二、与 ux.md 的分工（SSOT，零重叠）

```
  ux.md（行为半边）                  design.pen（视觉半边）
  ────────────────────             ──────────────────────
  页面清单 / 路由 / 准入             精确布局（像素级）
  元素清单（testid）                 配色 / 字体 / 间距（tokens）
  流转 / 五态 U 矩阵                 组件视觉长相
```

- ⛔ 同一事实只落一处：改视觉只动 pen；改行为只动 ux.md（pen 对应帧跟进视觉）
- pen 模式下 ux.md 的「全局设计系统」表只留一行指针 → design.pen

## 三、风格叠加机制

```
/cc-code:plan-uiux                    → 无参：pencil get_style 内置风格目录选一
/cc-code:plan-uiux gpt-taste          → Skill 工具加载该风格 skill，风格主张提炼进 pen
/cc-code:plan-uiux gpt-taste dataviz  → 多个按序叠加
```

- args 里的名字是主人亲手敲的 = 合法加载依据
- 风格 skill 的主张最终物化为 pen 的 design tokens（SetVariables）+ 布局原则，不是文字引用

## 四、铁律（定稿前即生效）

1. **.pen 加密文件**：只准 pencil MCP 读写，⛔ 禁 Read/Grep/Bash cat design.pen
2. **一页一帧**：P-n 页面 / M-n 弹窗，就地改画，⛔ 禁并排新旧帧（对照帧属决策过程，定稿即删）
3. **组件优先**：Nav/按钮/卡片先建 reusable 组件再铺页，改组件一次全页传播
4. **串行绘制**：单 .pen 文件禁并发写，逐页派 uiux subagent（一页完成→验收→下一页）
5. **截图自检**：每帧完成后 TakeScreenshot（MCP 能力）亲眼看过再交——禁闭眼作画
6. **保存自动化**：收尾跑 osascript Cmd+S（macOS）→ stat 验证字节增长 → git commit design.pen；⛔ 禁把「手动保存」推给主人
7. **禁生成断言**：A/U 编号唯一出处是 plan-mvp / plan-feature，本 skill 只画图不发明判定项

## 五、流程骨架（细节待调试回填）

```
入口判定
   ├─ 增量态：ux.md 有页面清单 → 直接画
   └─ 存量态：有前端代码无清单 → 扫路由回填页面骨架（只答「现在是什么」）→ 再画
        ↓
① 风格锁：加载风格 → 建 reusable 组件 → 画 1~2 页样板
   → 主人看真图 → 逐点改 → 锁 design tokens
        ↓
② 串行批量：逐页派 uiux subagent（任务单随行 + 就地改画 + 截图自检）
        ↓
③ 收尾：主人逐页确认 → osascript 保存 + 字节验证 → git commit
   → ux.md 落一行指针（登记 pen 模式）→ status.md 刷新坐标
```

## 六、越权红线

```
⛔ active/prd.md / api.md / data.md / project.md —— 绝不改写
⛔ active/gates.md                                —— QA 唯一域
⛔ src/ 与测试目录                                 —— Dev 唯一域
✅ 根目录 design.pen + ux.md 指针行 + status.md   —— 唯一落盘动作
```
