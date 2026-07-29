# INVENTORY 清点规则

> 被 `whole-qa` 的 ❶ 阶段引用。目标：产出**可锁定、可追溯、可证明**的三个分母。

## 一、页面发现 `P[]`

### 1.1 按框架扫路由

| 框架 | 扫描位置 | 路由规则 |
| --- | --- | --- |
| Next.js App Router | `app/**/page.{tsx,jsx,ts,js}` | 目录路径即路由；`(group)` 不入路径；`[param]` 为动态 |
| Next.js Pages Router | `pages/**/*.{tsx,jsx}` | 文件路径即路由；`_app`/`_document`/`api` 排除 |
| React Router | 搜 `createBrowserRouter` / `<Route` | 从配置对象提取 `path` |
| Vue Router | `router/index.*` 的 `routes` | 同上 |
| Nuxt | `pages/**` | 同 Next Pages |
| SvelteKit | `src/routes/**/+page.svelte` | 目录即路由 |
| 服务端模板（Django/Rails/Laravel） | `urls.py` / `routes.rb` / `routes/web.php` | 从路由表提取 |

> 拿不准框架时，读 `project.md` 的技术栈段；仍不确定则问用户，**不猜**。

### 1.2 动态路由处理

```
/user/[id]        → 必须准备真实样本 id（从 seed 数据取）
/post/[...slug]   → 准备 1 段 / 多段 两种样本
```
无样本可用的动态路由 → 标 `SKIPPED(缺样本数据)`，并在报告中列出。

### 1.3 准入分层

同一页面在不同身份下是**不同的测试对象**：

| 身份 | 必测 |
| --- | --- |
| 未登录 | 受保护页应正确重定向 |
| 普通用户 | 正常功能 + 越权入口应不可见/不可用 |
| 管理员/特殊角色 | 特权功能 |

`ux.md` 标注了准入的页面，按其身份列表逐一进入。

---

## 二、元素清点 `E[]`

### 2.1 ⭐ 从运行时 DOM 拿，不读源码

```
理由三条：
① 穷尽性  —— 条件渲染、动态插入的元素，读源码看不全
② 黑盒性  —— 不读实现，需求判断不会被代码带偏
③ 权限   —— 绕开「QA 禁读无关业务代码」的边界
```

流程：浏览器 MCP 导航到页面 → `snapshot` → 从可访问性树提取可交互节点。

### 2.2 什么算「可交互元素」

| 类型 | 匹配 |
| --- | --- |
| button | `<button>`、`role="button"`、`<input type="button/submit/reset">` |
| link | `<a href>`、`role="link"` |
| input | `<input>` 各 type（text/email/password/number/date/checkbox/radio/file…） |
| select | `<select>`、`role="combobox"`、`role="listbox"` |
| textarea | `<textarea>` |
| form | `<form>`（整体提交行为单独算一项） |
| tab | `role="tab"` |
| modal 触发器 | 点击后出现 `role="dialog"` 的元素 |
| 可拖拽 | `draggable="true"`、拖拽库标记 |
| 其他可点击 | 带 `onClick` 的 `div`/`span`（有 `cursor:pointer` 或 `tabindex`） |

**排除**：纯展示文本、装饰图标、`disabled` 且业务上永久禁用的（但「当前禁用、条件满足后启用」的必须测两态）。

### 2.3 定位锚点优先级

```
① data-testid          ← 最稳，文案改了不影响
② role + accessible name
③ 可见文本
④ CSS 选择器            ← 最脆，仅兜底
```
若 `ux.md` 的「可交互元素清单」已给 testid，直接用；实际 DOM 没有该 testid → 记为 FAIL（规格与实现不一致），不要自己换选择器蒙过去。

### 2.4 同构组识别

判定为同构组的条件（全部满足）：
1. DOM 结构路径相同（同一列表/表格的重复行）
2. 同一 testid 前缀或同一 class 组合
3. 行为只随数据变化，不随位置变化

```
处理：
  同构组 N 个 ──► 实测 首 / 末 / 边界样本（如：唯一项、最后一项、超长文本项）
  报告写明：  「M3-删除按钮 同构组 N=137，实测 3（首/末/超长文本行）」
```
⛔ 唯一元素**不许**当同构组处理。拿不准是否同构 → 按唯一元素逐个点。

---

## 三、接口发现 `A[]`

三个来源取并集，**差集必须报告**：

| 来源 | 方法 |
| --- | --- |
| ① 代码路由 | Next.js `app/api/**/route.ts` / `pages/api/**`；Express `app.{get,post,...}`；Django `urls.py`；等 |
| ② 契约表 | `api.md` 的接口清单 |
| ③ 运行时 | 页面操作过程中浏览器实际发出的请求（`list_network_requests`） |

```
差集含义：
  ②有 ①无  → 契约已定但未实现          → FAIL（No implementation found）
  ①有 ②无  → 影子接口，契约未登记        → FAIL（契约缺失，Architect 需补）
  ③有 ①②无 → 外部服务或未纳管路由        → 列入报告，标 EXTERNAL
```

每个接口的 5 类断言见 `assertions.md`。

---

## 四、断言清点 `ASSERT[]`

```
逐模块读 prd.md 的 §1.5 验收断言表
  ├─ 编号原样引用（A1、A2…），⛔禁止另起编号
  ├─ 标了 ~~作废~~ 的跳过，但要在报告里列为 VOID
  └─ 某模块没有 §1.5 → 中止本模块，报告「缺尺子」，绝不自己编断言
```

---

## 五、模块归组 `M[]`

以 `prd.md` 的「模块清单」为准。把 `P[]`/`E[]`/`A[]` 归属到模块：

```
归属规则：
  页面 → 按 ux.md 的页面-模块对应，或按路由前缀
  元素 → 跟随所在页面
  接口 → 按 api.md 的「模块：xxx」分段
  
孤儿项（归不进任何模块）→ 单列「M0 未归属」组，照测，
                          并在报告中提示 PM 补 prd.md 模块归属
```

---

## 六、落盘格式

`.cc_code/docs/qa/<YYYY-MM-DD>-inventory.md`

```markdown
# 全量验收清单 — <日期> 第 N 轮
BASE_URL: <url>　　身份样本: <账号列表>

## 分母摘要（已锁定，本轮不可变更）
| 维度 | 数量 |
| --- | --- |
| 页面（含身份分层） | |
| 可交互元素（唯一 + 同构组代表） | |
| 接口 | |
| 验收断言 | |

## M1. <模块名>
### 页面
| # | 路由 | 身份 | 动态参数样本 |
### 可交互元素
| # | 页面 | 元素 | 类型 | testid | 同构组 | 期望行为 |
### 接口
| # | method | path | 来源(代码/契约/运行时) | 副作用 |
### 断言
| # | 断言原文（引自 prd.md） |

## M0. 未归属
...

## 本轮 SKIPPED（分母内但不测，逐条给原因）
| # | 项 | 原因 |
```
