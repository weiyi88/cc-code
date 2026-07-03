---
name: next2taro
description: 将 Next.js (App Router + Tailwind + shadcn/ui) 的 UI 页面/组件转换为 Taro 小程序 (View/Text + SCSS + PNG)。当用户说"next2taro"、"转换页面"、"Next转Taro"、"页面迁移" 时触发。
disable-model-invocation: true
---

# Next.js → Taro UI 转换技能

将 Next.js (App Router + Tailwind CSS + shadcn/ui) 的 UI 精确还原为 Taro 小程序 (View/Text + 手写 SCSS + PNG 图片)，遵循转换宪法规则。

## 适用场景

- Next.js 项目迁移到微信/支付宝/抖音小程序
- 已有 Next.js UI 设计稿，需要在小程序端还原
- Taro 项目中某个页面/组件需要对照 Next.js 原版修正

---

## 转换宪法（铁律）

### §1 标签映射

| 铁律 | Next.js | Taro | 说明 |
|------|---------|------|------|
| 1.1 | `<div>` | `<View>` | 所有块级容器 |
| 1.2 | `<span>` / `<p>` / `<h1>`~`<h6>` | `<Text>` | 所有文本，必须用 Text 包裹 |
| 1.3 | `<svg>` / 内联 SVG | `<Image>` + PNG | SVG 必须导出为 PNG，禁止内联 |
| 1.4 | `<img>` | `<Image mode="aspectFit">` | 图片组件，必须设置 mode |
| 1.5 | `<a>` / `<Link href>` | `Taro.navigateTo` / `switchTab` | 路由跳转（见 §6） |
| 1.6 | `<button>` | `<View>` + onClick | 按钮用 View 模拟 |
| 1.7 | `<input>` / `<textarea>` | `<Input>` / 自定义 `<Input type="textarea">` | 表单组件 |
| 1.8 | `<label>` / `<form>` | `<View>` 模拟 | 无语义标签 |
| 1.9 | `<header>` / `<main>` / `<footer>` | `<View>` | 语义标签 → View |

### §2 样式系统

| 铁律 | 规则 | 原因 |
|------|------|------|
| 2.1 | 单一 class 选择器（`.foo`），禁止嵌套/后代/标签选择器 | RN 兼容 + 小程序样式隔离 |
| 2.2 | 只用 `px` 单位，禁止 `rpx` / `rem` / `em` | pxtransform 自动转换 |
| 2.3 | 禁止 `grid` 布局，只用 `flex` | RN 不支持 grid |
| 2.4 | 禁止伪类/伪元素（`:hover` / `::before` / `::after`） | RN 不支持，用额外 View 模拟 |
| 2.5 | `box-shadow` 小程序可用，RN 需用 `elevation` 替代 | 跨端兼容 |
| 2.6 | `transition` 小程序可用，RN 需用 `Animated` 替代 | 跨端兼容 |
| 2.7 | 所有值引用 `variables.scss`，禁止魔法数字 | 可维护性 |
| 2.8 | 禁止 `calc()` 表达式，用 `width:50%` + `padding` 间距替代 | 小程序兼容性差 |
| 2.9 | Taro `<Text>` 多行文字必须设 `word-break: break-word` + `line-height: $leading-loose` | 防止文字重叠（实战踩坑） |
| 2.10 | 渐变背景容器的子元素需 `overflow: hidden` + `border-radius: 9999px` | 防止渐变在方圆角下溢出（实战踩坑） |

### §3 设计像素体系（designWidth:750）

```
SCSS 中的 px 值 = 实际像素 × 2
例：14px 实际 → SCSS 写 28px
原因：designWidth:750 下 pxtransform 按 1:1 转换 rpx
     而 750 设计稿中 1rpx = 0.5 物理像素
```

常用映射表：

| 实际像素 | SCSS 值 | Tailwind 对应 |
|----------|---------|---------------|
| 12px | 24px | text-xs |
| 14px | 28px | text-sm |
| 16px | 32px | text-base / p-4 |
| 18px | 36px | text-lg |
| 20px | 40px | text-xl |
| 24px | 48px | text-2xl |
| 30px | 60px | text-3xl |
| 8px | 16px | gap-2 / p-2 |
| 10px | 20px | gap-2.5 / p-2.5 |
| 12px | 24px | gap-3 / p-3 |
| 16px | 32px | gap-4 / p-4 |
| 20px | 40px | gap-5 / p-5 |
| 24px | 48px | gap-6 / p-6 |
| 4px | 8px | rounded-sm |
| 8px | 16px | rounded-md |
| 16px | 32px | rounded-lg |
| 20px | 40px | rounded-xl |
| 24px | 48px | rounded-2xl |

### §4 颜色转换

| 规则 | 说明 | 示例 |
|------|------|------|
| oklch → hex | 必须精确转换，使用在线工具或公式 | `oklch(0.98 0.01 80)` → `#faf9f7` |
| Tailwind 色板 → hex | 引用 variables.scss 扩展色板 | `bg-rose-100` → `$color-rose-100` → `#FFE4E6` |
| 渐变 → linear-gradient | 小程序支持，135deg 为常用角度 | `from-rose-50 to-amber-50` → `linear-gradient(135deg, $color-rose-50, $color-amber-50)` |
| 半透明色 → rgba | 用于边框、背景半透明等 | `border-border/50` → `rgba($color-border, 0.5)` |
| CSS 变量 → SCSS 变量 | `bg-[--tag-cold-war]` → `$color-tag-cold-war` | 统一归入 variables.scss |

**关键实战经验：页面底色必须加深**

Next.js 使用 `bg-background` (#faf9f7 近白色) 作为页面底色，白色卡片在近白底上对比度极差。转换时必须：

```
Next.js:  bg-background (#faf9f7)  →  Taro: $gradient-page-xxx (#FEEADB → #FFDFDF 暖橙渐变)
Next.js:  bg-background (#faf9f7)  →  Taro: $color-page-bg (#FFF0E8 暖橙纯色)
```

### §5 SVG → PNG 转换流程

```
1. 分析 Next.js SVG 组件，确定 type × status 组合矩阵
2. 为每个组合创建独立 SVG 文件（含渐变定义）
3. 用 rsvg-convert 批量渲染为 4x 分辨率 PNG：
   rsvg-convert -w 400 -h 400 input.svg -o output.png
4. PNG 放入 src/assets/monsters/ (或对应目录)
5. 组件中用 require('@/assets/xxx.png') 引用
6. 删除旧的手绘 View/Text 图标代码
```

**实战踩坑：MonsterIcon 渐变溢出**

Next.js 使用 `rounded-2xl` (方圆角)，Taro 中渐变背景会在圆角处溢出显示底色。修复：

```scss
// ❌ 错误：方圆角，渐变在角落溢出
.monster-icon { border-radius: 32px; }

// ✅ 正确：正圆 + overflow hidden，完全裁剪渐变
.monster-icon { border-radius: 9999px; overflow: hidden; }
```

**命名规范：** `{type}_{status}.png`，如 `attitude_wild.png`、`happy_tamed.png`

### §6 路由映射

| Next.js | Taro | 说明 |
|---------|------|------|
| `<Link href="/page">` | `Taro.navigateTo({url: '/pages/page/index'})` | 普通页面 |
| tabBar 页面跳转 | `Taro.switchTab({url: '/pages/tab/index'})` | 底部导航页 |
| `router.back()` | `Taro.navigateBack()` | 返回 |
| `router.push('/page?id=1')` | `Taro.navigateTo({url: '/pages/page/index?id=1'})` | 带参跳转 |
| `app/dex/[id]/page.tsx` (动态路由) | `Taro.navigateTo({url: '/pages/detail/index?id=xxx'})` | 详情页 |
| `useParams()` | `Taro.getCurrentInstance().router.params` | 获取路由参数 |

### §7 shadcn/ui 组件拆解规则

Next.js 使用 56 个 shadcn/ui Radix 组件，Taro 中全部替换为 `<View>` + `<Text>` + SCSS。核心拆解模式：

| shadcn/ui 组件 | Taro 替换方案 | 说明 |
|----------------|--------------|------|
| `<Card>` / `<CardContent>` / `<CardHeader>` / `<CardTitle>` | `<View className="xxx-card">` | 每张卡片一个顶层 View，内部直接排布 |
| `<Button variant="outline" size="sm">` | `<View className="xxx-btn">` + onClick | 移除 variant/size，手写 SCSS 状态 |
| `<Badge variant="secondary">` | `<Text className="xxx-badge">` | badge 降级为 Text + 背景色 |
| `<Textarea rows={4}>` | `<Input type="textarea" className="xxx-textarea">` | shadcn → Taro Input |
| `<Avatar>` / `<AvatarFallback>` | 自定义 `<Avatar>` 组件 | 渐变色首字母头像 |

**拆解原则：**

1. **Card → View**：shadcn Card 的 `border-0 shadow-lg` 等属性全部转入 SCSS class
2. **Button → View+onClick**：移除 variant/size/className 体系，每个按钮写独立 SCSS
3. **Badge → Text**：badge 的 variant 通过不同 class 实现（如 `.tag-badge-wild`、`.tag-badge-tamed`）
4. **不引入任何 UI 库**：Taro 端全部手写，保持零依赖

### §8 lucide 图标 → emoji 映射表

lucide-react SVG 图标在小程序中不可用，全部替换为 Text emoji。本项目的完整映射：

| lucide 图标 | emoji | 用途 |
|------------|-------|------|
| `Heart` | ♥ / ❤️ / 💚 | 爱心（不同场景用不同变体） |
| `ArrowLeft` | ← | 返回（通常用原生导航栏） |
| `Snowflake` | ❄️ | 冷战标签 |
| `Home` | 🏠 | 家务标签 |
| `Frown` | 😤 | 态度标签 |
| `EyeOff` | 🙈 | 忽视标签 |
| `HelpCircle` | ❓ | 其他标签 |
| `PartyPopper` | 🎉 | 开心标签 |
| `MessageCircleHeart` | 💕 | 心动标签 / 暖心话语选项 |
| `Star` | ⭐ | 想你标签 |
| `Gift` | 🎁 | 感谢标签 / 送礼物选项 |
| `Sparkles` | ✨ | AI 翻译标识 / 温柔版本 |
| `Wand2` | 🪄 | AI 翻译按钮 |
| `CheckCircle` | ✅ | 成功页面 |
| `Send` | 💌 | 发送按钮 |
| `Clock` | ⏰ | 时间线标题 |
| `MessageCircle` | 💬 | 消息时间线 / 暖心话语选项 |
| `Check` | ✓ (白色文字) | 时间线已查看事件 |
| `Hand` | 🤝 | 求抱抱选项 |
| `Coffee` | ☕ | 约会邀请选项 |
| `Music` | 🎵 | 一首歌选项 |
| `Share2` | 📤 | 分享按钮 |
| `Calendar` | 📅 | 天数统计 |
| `Zap` | ⚡ | 连续天数 |
| `BookOpen` | 📖 | 图鉴标题 |
| `Settings` | ⚙️ | 设置菜单 |
| `LogOut` | 🚪 | 退出登录 |
| `ChevronRight` | › | 菜单箭头（文字符号） |
| `Share2` | 📤 | 分享卡片 |

**替换原则：**

1. **功能图标**（导航、操作）→ 选择语义最接近的 emoji
2. **装饰图标**（标签、徽章）→ 选视觉辨识度高的 emoji
3. **动画图标**（`animate-spin`、`animate-pulse`）→ emoji 无法做动画，移除或用文字替代
4. **箭头/方向** → 优先用文字符号 `›` `←` `→`，而非 emoji

### §9 Taro 特有视觉陷阱与修复

基于实战踩坑总结，以下问题在转换中极易出现：

#### 陷阱 1：Taro Text 多行文字重叠

**现象：** 长文本在 Taro `<Text>` 组件中换行后行与行重叠。

**修复：** 所有多行 Text 必须显式设置行高和断词：

```scss
.translated-text {
  font-size: $text-sm;
  line-height: $leading-loose;   // 1.75，比 Next.js 的 leading-relaxed(1.625) 更宽松
  word-break: break-word;        // 强制长词断行
}
```

**适用场景：** 翻译结果、原始文本、任意可能多行的 Text 内容。

#### 陷阱 2：渐变背景容器溢出

**现象：** 容器使用渐变 `background` + `border-radius` 非圆形时，渐变在角落溢出。

**修复：** 渐变背景容器必须 `overflow: hidden`，圆角图标用正圆：

```scss
// 方圆角容器 — 加 overflow
.card-header-gradient {
  background: $gradient-detail-header;
  overflow: hidden;
}

// 圆形图标 — 用 9999px 正圆
.monster-icon {
  border-radius: 9999px;  // 不是 $radius-2xl
  overflow: hidden;
}

// 白色圆圈包裹渐变图标 — 也要 overflow
.card-monster-circle {
  border-radius: $radius-full;
  overflow: hidden;
}
```

#### 陷阱 3：calc() 兼容性差

**现象：** `width: calc(50% - 8px)` 在部分小程序版本渲染异常。

**修复：** 用 flex + width + padding + 内层 View 替代：

```scss
// ❌ 错误
.option-item { width: calc(50% - 8px); margin: 4px; }

// ✅ 正确：外层 50% 宽 + padding 间距，内层实际内容
.option-item {
  width: 50%;
  box-sizing: border-box;
  padding: $space-1;
}
.option-item-inner {
  background-color: $color-option-bg;
  border-radius: $radius-xl;
  padding: $space-2_5;
  // 实际内容
}
```

```tsx
// JSX 结构必须加内层 View
<View className="option-item">
  <View className="option-item-inner">
    <View className="option-icon-bg">...</View>
    <Text className="option-name">...</Text>
  </View>
</View>
```

#### 陷阱 4：页面底色对比度不足

**现象：** Next.js `bg-background` (#faf9f7) 几乎纯白，白色卡片浮不起来。

**修复：** 所有页面底色加深为暖橙渐变，见 §4 颜色转换。

#### 陷阱 5：日期未格式化

**现象：** 直接显示 ISO 字符串 `"2024-01-15T14:30:00"`。

**修复：** 必须使用 `formatDate()` 工具函数：

```ts
export function formatDate(dateString: string): string {
  const date = new Date(dateString)
  const month = date.getMonth() + 1
  const day = date.getDate()
  const hours = date.getHours().toString().padStart(2, '0')
  const minutes = date.getMinutes().toString().padStart(2, '0')
  return `${month}月${day}日 ${hours}:${minutes}`
}
```

#### 陷阱 6：阴影不够立体

**现象：** Tailwind `shadow-sm` 太弱，卡片看起来"贴在纸面上"。

**修复：** 使用双层阴影变量，分场景选用：

```scss
// variables.scss 中定义
$shadow-sm: 0 1px 2px rgba(0, 0, 0, 0.05);           // 内嵌子元素微浮
$shadow-md: 0 4px 6px rgba(0, 0, 0, 0.1);             // 小型交互元素
$shadow-card: 0 8px 24px rgba(0, 0, 0, 0.08),         // 标准卡片浮起
             0 2px 8px rgba(0, 0, 0, 0.04);
$shadow-card-lg: 0 12px 32px rgba(0, 0, 0, 0.1),      // 主卡片/大卡片
                0 4px 12px rgba(0, 0, 0, 0.05);
```

**选用规则：**
- 内嵌子元素（today-monster、recent-item）→ `$shadow-sm`
- 普通卡片（dex monster、stats、menu、sweet-words）→ `$shadow-card`
- 主卡片/详情卡（detail monster、resolve section）→ `$shadow-card-lg`
- 带色彩辉光（couple-card、today-card）→ 专用 `$shadow-couple` / `$shadow-today`

### §10 底部导航转换规则

| Next.js | Taro | 说明 |
|---------|------|------|
| `<BottomNav>` 自定义组件 (fixed + usePathname) | `app.config.ts` tabBar 原生配置 | 原生 tabBar 性能更好 |
| lucide 图标 (Home/PlusCircle/BookOpen/User) | PNG 图片 (home.png / capture.png / dex.png / profile.png) | 每个图标需 normal + active 两态 |
| `<Link>` 跳转 | 原生自动切换 | 无需手写跳转逻辑 |
| `usePathname()` 高亮当前 | 原生自动高亮 | 无需手写判断 |

**TabBar PNG 图标配额：**

```
src/assets/tabbar/
├── home.png          # 首页-未选中
├── home-active.png   # 首页-选中
├── capture.png       # 捕获-未选中
├── capture-active.png # 捕获-选中
├── dex.png           # 图鉴-未选中
├── dex-active.png    # 图鉴-选中
├── profile.png       # 我的-未选中
├── profile-active.png # 我的-选中
```

### §11 数据层转换规则

| Next.js | Taro | 说明 |
|---------|------|------|
| `lib/data.ts` + `data/mock-data.json` 分离 | `src/data/mock.ts` 内联数据 | 小程序不便读取 JSON 文件 |
| `export function getUser()` 等函数式取数 | `export const mockUser` 等常量导出 | 简化，去掉间接层 |
| `formatDistanceToNow()` 相对时间 | `formatDate()` 绝对日期 | 小程序场景绝对时间更实用 |
| 服务端数据获取 (Server Component) | 纯客户端数据 | Taro 无服务端组件 |

**数据模型差异注意：**

```
Next.js Monster: complaintText, capturedAt, resolved, resolveMethod, resolutionNote, emotion
Taro Monster:    mode, mediaList
→ 两者共享核心字段 (id, tag, status, intensity, originalText, translatedText, createdAt)
→ 各自有扩展字段，转换时需同步 types/index.ts
```

### §12 API 转换规则

| Next.js | Taro | 说明 |
|---------|------|------|
| `fetch('/api/translate')` | `Taro.request()` 或云函数 | 服务端路由 → 云函数 |
| `window.localStorage` | `Taro.setStorageSync()` / `getStorageSync` | 本地存储 |
| `router.push()` | `Taro.navigateTo()` | 路由 |
| `useParams()` | `Taro.getCurrentInstance().router.params` | 路由参数 |
| `alert()` | `Taro.showModal()` 或 `Taro.showToast()` | 弹窗 |
| Vercel AI SDK | 云函数 + AI API | AI 功能 |

### §13 页面结构转换规则

| Next.js 模式 | Taro 模式 | 说明 |
|-------------|----------|------|
| 自定义 `<header>` (sticky + backdrop-blur) | **移除**，用原生导航栏 | 小程序原生导航栏更稳定 |
| `<main className="max-w-md mx-auto">` | **移除 max-w-md**，小程序全宽 | 小程序无桌面端宽度限制 |
| `<BottomNav />` 每页引入 | `app.config.ts` tabBar 全局配置 | 原生 tabBar |
| `pb-20` 底部留白 | `padding-bottom: $space-20` (tabBar) 或 `120px~180px` (固定按钮) | 按场景调整 |
| `space-y-5` 垂直间距 | `gap: $space-5` (flex) 或各元素 `margin-bottom` | 小程序无 Tailwind space 工具 |

---

## 转换工作流

### Phase 1: 审计对照

1. 读取 Next.js 源页面/组件 TSX + CSS
2. 读取 Taro 目标页面/组件 TSX + SCSS
3. 列出所有宪法违规项（按 §1-§13 逐条检查）
4. 输出差异报告：合规率 + 具体违规列表

### Phase 2: 变量基建

1. 检查 `variables.scss` 是否覆盖所需色板、间距、阴影
2. 补充缺失的 Tailwind 色板变量（rose/amber/sky/indigo/emerald 等）
3. 补充渐变定义（`$gradient-xxx`）
4. 补充语义透明色（`$color-border-light`, `$color-card-semi` 等）
5. 补充双层/彩色阴影变量（`$shadow-card`, `$shadow-card-lg` 等）
6. 补充页面底色渐变（`$gradient-page-xxx`，注意加深对比度）

### Phase 3: 组件转换

按以下优先级逐个转换：

1. **标签替换**：div→View, span→Text, img→Image, a→navigateTo
2. **shadcn/ui 拆解**：Card→View, Button→View+onClick, Badge→Text, Textarea→Input
3. **lucide→emoji**：按 §8 映射表替换所有图标
4. **SVG→PNG**：内联 SVG 导出为 PNG，组件改用 Image
5. **样式重写**：
   - 嵌套选择器 → 扁平单一 class
   - rpx/rem → px
   - grid → flex（grid-cols-2 → flex + width:50% + padding + inner View）
   - calc() → width:50% + padding 间距（见 §9 陷阱3）
   - 伪类/伪元素 → 额外 View 模拟
   - 魔法数字 → variables 引用
   - 多行 Text → 加 line-height + word-break（见 §9 陷阱1）
   - 渐变容器 → 加 overflow:hidden（见 §9 陷阱2）
6. **路由替换**：Link → Taro.navigateTo/switchTab
7. **API 替换**：fetch → Taro.request, localStorage → Taro.setStorageSync 等
8. **页面底色加深**：bg-background → $gradient-page-xxx 暖橙渐变
9. **阴影升级**：shadow-sm → $shadow-card / $shadow-card-lg

### Phase 4: 立体感还原

Next.js 中常见但 Taro 易丢失的视觉效果：

| 视觉效果 | Next.js 原版 | Taro 还原方式 |
|----------|-------------|---------------|
| 双层阴影 | `shadow-md shadow-sm` | `box-shadow: 0 10px 15px rgba(...), 0 4px 6px rgba(...)` |
| 彩色辉光 | 渐变卡片 + shadow | `box-shadow: 0 10px 25px rgba(rose, 0.12), 0 4px 10px rgba(amber, 0.08)` |
| ring 光环 | `ring-1 ring-border` | `border: 1px solid $color-border-light` |
| border-left 状态条 | `border-l-4 border-l-red-500` | `border-left: 6px solid $color-monster-wild` + 动态 class |
| 渐变背景 | `bg-gradient-to-br from-rose-50 to-amber-50` | `background: linear-gradient(135deg, $color-rose-50, #FFF, $color-amber-50)` |
| 圆形辉光 | shadow + ring 组合 | `box-shadow: 0 8px 24px rgba(...), 0 0 0 3px rgba(...)` |
| 带色彩按钮投影 | 无 | `box-shadow: 0 8px 24px rgba(232, 93, 93, 0.3)` |

### Phase 5: 自检清单

转换完成后逐项验证：

- [ ] 所有 div → View, span/p → Text
- [ ] SVG 内联 → PNG Image
- [ ] shadcn/ui Card/Button/Badge/Textarea 全部拆解为 View/Text/Input
- [ ] lucide 图标全部替换为 emoji
- [ ] 无嵌套/后代/标签选择器
- [ ] 无 rpx/rem，只用 px
- [ ] 无 grid，只用 flex
- [ ] 无 calc()，用 width+padding 替代
- [ ] 无伪类/伪元素
- [ ] 无魔法数字，全部引用 variables
- [ ] 路由用 Taro API
- [ ] 阴影/渐变/ring 还原
- [ ] px 值为实际像素 × 2（designWidth:750）
- [ ] 颜色精确转换（oklch→hex）
- [ ] 页面底色已加深（非近白色）
- [ ] 卡片阴影使用 $shadow-card / $shadow-card-lg
- [ ] 多行 Text 设 line-height + word-break
- [ ] 渐变容器设 overflow:hidden
- [ ] 圆角图标用 border-radius: 9999px（非 2xl）
- [ ] 日期使用 formatDate() 格式化
- [ ] 编译通过无错误

---

## 输出规范

转换时必须输出：

1. **差异报告**：列出所有违规项（审计阶段）
2. **变更清单**：每个文件的修改说明（执行阶段）
3. **自检结果**：逐项勾选自检清单（验证阶段）
4. **编译验证**：`npm run build:weapp` 结果

---

## 注意事项

- 优先还原视觉 fidelity，其次追求代码优雅
- 遇到宪法规则与视觉效果冲突时，优先遵守宪法（如伪类不可用则用 View 模拟）
- 每个页面/组件转换后立即编译验证，不要攒一批再验证
- PNG 图片建议 4x 分辨率（400×400 for 100×100 渲染尺寸）
- 渐变色值必须与 Next.js 原版一致，不能凭感觉调
- 所有 Taro `<Text>` 多行内容必须加 `word-break: break-word` + `line-height: $leading-loose`
- 所有渐变背景容器必须加 `overflow: hidden`
- 页面底色绝对不能用近白色，必须加深到暖橙渐变以形成卡片对比度
