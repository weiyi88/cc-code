---
name: plan-uiux
description: 先试画 2 页定风格，再逐页画进设计稿，每页经你确认才保存
allowed-tools: Read, Write, Edit, Bash, Glob, Grep, Agent, SendMessage, ToolSearch
disable-model-invocation: true
---

# /cc-code:plan-uiux — 前端原型绘制器

> **状态：占位骨架（1.0.0）。** 本 skill 已定方向但施工规格未定稿，多个前端风格 skill 尚在并行调试中。
> 在正式定稿前，本文件只锁边界与铁律，具体阶段流程由 uiux agent 调试结论回填。
> **编排器只传话、不画图**：本命令的主控是编排者，不扮演任何角色，不碰 pencil；所有画图（含风格锁的组件与样板页）一律派 `uiux` agent。

## 一、定位

| 项 | 说明 |
| --- | --- |
| 解决什么 | ux.md 文字规格 → design.pen 可视化原型（主人看得见、改得动的真图） |
| 不解决什么 | 业务逻辑（plan-mvp 管）、代码生成（agent-mvp Dev 阶段的 pen 底稿管） |
| 前置 | `ux.md` 已有页面清单（plan-mvp / plan-feature 由 pm 落盘） |
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

- ⛔ 同一事实只落一处：改视觉只动 pen（派 uiux 写）；改行为只动 ux.md（派 pm 写；pen 对应帧再派 uiux 跟进视觉）。编排器自己不写任何一个
- pen 模式下 ux.md 的「全局设计系统」表只留一行指针 → design.pen（指针行由 pm 写，见收尾步骤）

## 三、风格叠加机制

```
/cc-code:plan-uiux                    → 无参：pencil get_style 内置风格目录选一
/cc-code:plan-uiux gpt-taste          → Skill 工具加载该风格 skill，风格主张提炼进 pen
/cc-code:plan-uiux gpt-taste dataviz  → 多个按序叠加
```

- args 里的名字是主人亲手敲的 = 合法加载依据；编排器只把名字原样写进风格锁任务单，**由 uiux agent 自己加载**
- 风格 skill 的主张最终由 uiux 物化为 pen 的 design tokens + 布局原则，不是文字引用

## 四、铁律（定稿前即生效）

1. **.pen 加密文件**：只准 pencil MCP 读写，⛔ 禁 Read/Grep/Bash cat design.pen
2. **一页一帧**：P-n 页面 / M-n 弹窗，就地改画，⛔ 禁并排新旧帧（对照帧属决策过程，定稿即删）
3. **组件优先**：Nav/按钮/卡片先建 reusable 组件再铺页，改组件一次全页传播
4. **串行绘制（单 .pen 唯一写者）**：单 .pen 文件禁并发写，同一时刻最多一个 uiux 在写；风格锁、样板页、逐页绘制都派 uiux，一个完成→验收→下一个。编排器自己不碰 pencil，不是第二个写者
   并行泳道不适用于本命令（出处 `skills/cc-code/references/parallel-lanes.md`，此处不复述）
5. **截图自检**：每帧完成后 TakeScreenshot（MCP 能力）亲眼看过再交——禁闭眼作画
6. **保存自动化**：收尾由编排器跑 osascript Cmd+S（macOS，只触发保存、不改内容）→ stat 验证字节增长 → git commit design.pen（这是编排器仅有的两个写例外，其余画图 / 改 ux.md / 改 project.md 一律派 uiux / pm / architect）；⛔ 禁把「手动保存」推给主人
7. **禁生成断言**：A/U 编号唯一出处是 plan-mvp / plan-feature，本 skill 只画图不发明判定项

## 五、流程骨架（细节待调试回填）

```
入口判定
   ├─ ux.md 有页面清单 → 直接开始
   └─ 没有页面清单     → 停：先走 /cc-code:plan-mvp 或 /cc-code:plan-feature，
                          由 pm 与主人问答补齐页面清单，再回来画
                          （编排器不读 src/、不扫路由代笔）
        ↓
① 风格锁（派 uiux，编排器只传话）
   派 uiux：风格名（主人敲的）+ 主人原话 → 加载风格、建 tokens、
            建 reusable 组件、画 1~2 页样板 → 交回截图自检报告
   主人看真图 → 逐点说改哪里
   主人原话原样续接给同一个 uiux（SendMessage）→ 就地改 → 再看
   主人说「定了」→ 风格锁完成
   uiux 遇到决定不了的事（风格没选、规格自相矛盾）→ 交回编排器 → 原样转给主人
        ↓
② 串行批量（一次一个 uiux）
   页面清单逐页：派 uiux（任务单 → 就地改画 → 截图自检 → 报告）
   → 主人逐页确认 → 下一页
        ↓
③ 收尾
   编排器：osascript 保存 + 字节验证 → git commit design.pen
   派 pm：任务说明写「落盘指针行 + 帧号范围」，pm 只改 ux.md 一行指针（登记 pen 模式）并追加 change-log 一行（规则见 `agents/pm.md` 指针行任务）
   派 architect：任务说明写「项目已有 design.pen，登记 project.md §一 pen 导出格式」，architect 按项目样式方案填该行（dev 画 UI 前按它导出底稿；已登记且仍适用则交回「无变化」）
   编排器：status.md 刷新坐标；backup/milestone-log.md 追加一行
```

### 任务单固定格式（编排器写给 uiux / pm）

| 只写 | 不写 |
| --- | --- |
| 读哪些文件（ux.md 的哪一节、design.pen 路径） | 编排器自己对页面、风格、配色的理解 |
| 主人原话（逐字） | 任何视觉判断、token 值、布局建议 |
| 本轮要交回什么（帧 id + 节点数 + 截图自检） | 模型或工具选择 |

## 六、越权红线

角色权限唯一出处：`.cc_code/active/Agent.md` §三（主控的写权限与两个显式例外见 §一），此处只列本命令直接相关的几行。

| 谁 | 可落盘 |
| --- | --- |
| uiux agent | 根目录 `design.pen`（仅 pencil MCP；风格锁与逐帧绘制都是它） |
| pm agent | `ux.md` 指针行（收尾时） |
| architect agent | `project.md` §一 pen 导出格式（收尾时） |
| 编排器 | 仅 Agent.md §一 列的两个例外：触发保存 `design.pen`（osascript，只保存不改内容）+ git 提交；其余按主控写权限，见 Agent.md |
