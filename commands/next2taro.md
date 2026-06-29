---
name: cc-code:next2taro
description: 将 Next.js (App Router + Tailwind + shadcn/ui) 的 UI 页面/组件转换为 Taro 小程序 (View/Text + SCSS + PNG)，遵循转换宪法规则。当用户说"next2taro"、"转换页面"、"Next转Taro"、"页面迁移"时触发。
allowed-tools: Read, Glob, Grep, Bash, Edit, Write, Agent, AskUserQuestion
argument-hint: <Next.js页面路径或组件名> [--audit-only] [--page <页面名>]
---

$ARGUMENTS

# /cc-code:next2taro — Next.js → Taro UI 转换器

将 Next.js UI 精确还原为 Taro 小程序，遵循转换宪法规则。

---

## 调用方式

```
/cc-code:next2taro                          审计整个 Taro 项目的宪法合规率
/cc-code:next2taro --page index             转换指定页面
/cc-code:next2taro components/monster-icon  转换指定组件
/cc-code:next2taro --audit-only             只做审计，不执行修改
```

---

## 执行流程

### 第一步：读取转换宪法

用 Read 工具读取 `$CLAUDE_PLUGIN_ROOT/skills/next2taro/SKILL.md`，获取完整的转换宪法规则（§1-§6 + 工作流 + 自检清单）。

### 第二步：定位源文件与目标文件

1. 扫描项目根目录，找到 Next.js 源项目（含 `app/` 目录）
2. 找到 Taro 目标项目（含 `taro-project/src/` 目录）
3. 根据 `$ARGUMENTS` 确定要转换的页面/组件范围
4. 若未指定参数，先输出审计报告供用户选择

### 第三步：审计对照

对目标页面/组件逐条检查宪法 §1-§6：

| 检查项 | 违规示例 |
|--------|----------|
| §1 标签映射 | 使用了 div/span/a/svg 等未转换标签 |
| §2 样式系统 | 嵌套选择器、rpx/rem、grid、伪类伪元素 |
| §3 设计像素 | px 值不是实际像素×2 |
| §4 颜色转换 | oklch 未转 hex、Tailwind 色未入变量 |
| §5 SVG→PNG | 内联 SVG 未导出为 PNG |
| §6 路由映射 | 使用 Link/router 而非 Taro API |

输出审计报告：合规率 + 具体违规列表。

### 第四步：变量基建

检查 `variables.scss` 是否覆盖所需变量，补充缺失项：

```scss
// 补充 Tailwind 扩展色板（rose/amber/sky/indigo/emerald 等）
$color-rose-50: #FFF1F2;
// 补充渐变定义
$gradient-xxx: linear-gradient(135deg, ...);
// 补充双层/彩色阴影
$shadow-xxx: 0 10px 15px rgba(...), 0 4px 6px rgba(...);
```

### 第五步：组件转换

按优先级执行：

1. **标签替换**：div→View, span→Text, img→Image, a→navigateTo
2. **SVG→PNG**：
   - 分析 SVG 的 type×status 组合矩阵
   - 创建独立 SVG 文件（含渐变定义）
   - `rsvg-convert -w 400 -h 400 input.svg -o output.png` 批量渲染
   - 组件改用 `<Image src={require('@/assets/xxx.png')} />`
3. **样式重写**：
   - 嵌套选择器 → 扁平单一 class
   - rpx/rem → px
   - grid → flex
   - 伪类伪元素 → 额外 View 模拟
   - 魔法数字 → variables 引用
4. **路由替换**：Link → Taro.navigateTo/switchTab
5. **API 替换**：window.localStorage → Taro.setStorageSync 等

### 第六步：立体感还原

Next.js 常见但 Taro 易丢失的视觉效果：

| 视觉效果 | 还原方式 |
|----------|----------|
| 双层阴影 | `box-shadow: 0 10px 15px rgba(...), 0 4px 6px rgba(...)` |
| 彩色辉光 | `box-shadow: 0 10px 25px rgba(rose, 0.12), 0 4px 10px rgba(amber, 0.08)` |
| ring 光环 | `border: 1px solid $color-border-light` |
| border-left 状态条 | `border-left: 6px solid $color-monster-wild` + 动态 class |
| 渐变背景 | `background: linear-gradient(135deg, $color-rose-50, #FFF, $color-amber-50)` |
| 圆形辉光 | `box-shadow: 0 8px 24px rgba(...), 0 0 0 3px rgba(...)` |

### 第七步：自检清单

- [ ] 所有 div→View, span→Text
- [ ] SVG 内联→PNG Image
- [ ] 无嵌套/后代/标签选择器
- [ ] 无 rpx/rem，只用 px
- [ ] 无 grid，只用 flex
- [ ] 无伪类/伪元素
- [ ] 无魔法数字，全部引用 variables
- [ ] 路由用 Taro API
- [ ] 阴影/渐变/ring 还原
- [ ] px 值为实际像素×2（designWidth:750）
- [ ] 颜色精确转换（oklch→hex）
- [ ] 编译通过：`npx taro build --type weapp`

---

## 重要约束

- 优先还原视觉 fidelity，其次追求代码优雅
- 宪法规则与视觉效果冲突时，优先遵守宪法
- 每个页面/组件转换后立即编译验证
- PNG 图片建议 4x 分辨率（400×400 for 100×100 渲染尺寸）
- 渐变色值必须与 Next.js 原版一致，不能凭感觉调
