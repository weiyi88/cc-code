# 🏗️ 项目技术架构与开发宪法 (project.md)

> 本文件由 [Architect] 角色维护。Dev 工程师必须将此文件作为唯一的编码准则。
> **数据结构细节不在本文件**——interface / 字段规则 / DB 列对齐统一由 `active/data.md` 承载，本文件只在第四节引用。

### ⛔ 写入纪律（active = 最新 + 最完整 + 最纯净）

| 纪律 | 说明 |
| :--- | :--- |
| **就地收敛** | 架构变更**直接改写对应章节**，⛔ 禁新开 `## 增量 F-n` 章节。同一项选型 / 目录约定在本文件永远只有一处描述 |
| **过程外置** | 决策过程 ⛔ 不落盘（对话内裁决即用即弃，留痕 = `back_up/change-log.md` 一行）；本文件只留「架构现在是什么」。阶段实现方案 / 任务拆分**并入本文件对应章节**（agent-mvp 的阶段来源） |
| **台账外置** | 每次增量在 `back_up/change-log.md` 追加**一行**（格式见 `Agent.md` 归档规范）；本文件内不留任何台账/附录/历史痕迹 |
| **历史靠 git** | 旧版本不在本文件留存，`git log -p` 即完整历史 |

## 一、 技术栈概览 (Tech Stack)
*   **核心框架：** [待填写]
*   **语言：** [待填写]
*   **样式方案：** [待填写]
*   **状态管理：** [待填写]
*   **数据请求：** [待填写]
*   **部署环境：** [待填写]

## 二、 核心编程原则 (cc-code Philosophy)
所有提交的代码，必须经受以下原则的拷问：

1.  **KISS** — 拒绝炫技，可读性大于极致抽象。函数尽量 < 50 行。
2.  **YAGNI** — 仅实现当前明确所需功能，抵制过度设计，不预留「未来可能用到」的接口。
3.  **DRY** — 出现三次的重复代码必须抽离为 Hook / Utils。
4.  **SOLID 强制落地：**
    *   **SRP** 组件只负责渲染，逻辑抽到 Custom Hook。
    *   **OCP** 多用 children 扩展，少用 boolean props 堆叠。
    *   **DIP** 高层模块不直接调用底层 API，中间必须有 Service 层。
5.  **⛔ 零硬编码（铁律）** — 业务代码只引用，⛔ 禁止出现值的字面量。新出现的值先按下表定去处：

    | 值的类型 | 去处 | 例子 |
    | :--- | :--- | :--- |
    | 随环境变化、可调的值 | `config.json` | API 地址、端口、超时、重试次数、分页大小、功能开关、限流阈值 |
    | 敏感值 | `.env` | 密钥、token、数据库密码、第三方 secret |
    | 业务上固定的值 | `constants` 常量文件 | 状态枚举、角色名、错误码、路由路径、存储 key、事件名、队列名、缓存 key 前缀、定时任务名、正则、MIME 类型 |

    | 豁免（不算硬编码） | 原因 |
    | :--- | :--- |
    | `0` / `1` / `-1` / 空串 / `true` / `false` 这类语义自明的值 | 抽成常量反而难读（KISS） |
    | 测试夹具里的数据 | 测试数据本来就要写死 |
    | `config.json`、`constants`、`.env` 本身 | 它们就是定义值的地方 |

    | 文件 | 入 git | 作用 |
    | :--- | :--- | :--- |
    | `.env` | ⛔ 不入（写进 `.gitignore`） | 存真实敏感值 |
    | `.env.example` | ✅ 入 | 只列 key 不写值，一看就知道要配哪些变量 |

    > `config.json` 用 JSON 格式（TS / Python 等均可直接读）；三个文件的具体路径见第三节。

## 三、 目录结构规约 (Directory Rules)
*   **配置文件：** `config.json` → [待填写路径]
*   **常量文件：** `constants` → [待填写路径，按技术栈命名，如 `src/constants.ts` / `app/constants.py`]
*   **敏感值：** `.env` + `.env.example` → [待填写路径，默认项目根]
*   [待填写]

## 四、 数据契约 (Data Contract)
> 数据层唯一真相源：`.cc_code/active/data.md`（Architect 维护，Dev/QA 必读）。
> 本文件不重复 interface 字段定义。涉及数据结构时，统一 `@active/data.md` 引用。
> Architect 须保证：DB schema 列名 ↔ `data.md` interface 字段一一对齐；跨 ORM 栈时在 `data.md` 第五节记录差异。

## 五、 特殊约束 (Constraints)
*   [待填写]

## 六、 测试基建契约 (Test Infrastructure)

> ⭐ 本节是 **`affected` 精准回归的前提契约**。Architect 在 MVP 前必须填实，
> QA 与 `agent-mvp` / `agent-whole-qa` 据此计算「改了 X 该跑哪些测试」。

| 项 | 值 | 说明 |
| :--- | :--- | :--- |
| **测试根目录** | `.cc_code/test/` | ⛔ **必须入 git**，绝不可 `.gitignore` |
| 单元测试 | `.cc_code/test/unit/**/*.spec.ts` | `affected` 默认 glob 直接命中 |
| 接口测试 | `.cc_code/test/api/**/*.spec.ts` | 同上 |
| E2E 测试 | `.cc_code/test/e2e/**/*.spec.ts` | 同上 |
| 冒烟脚本 | `.cc_code/test/smoke/*.ts` | 非 `.spec` 命名，需 `affected --filter` |
| 测试框架 | [待填写] | 如 vitest / jest / playwright |
| 运行命令 | [待填写] | 如 `pnpm test` / `npx tsx <file>` |

### ⛔ 三条铁律（违反即 `affected` 永久失效）

```
① 测试代码必须入 git
   codegraph 尊重 .gitignore → 被 ignore 的测试不进索引
   → affected 查不到 → 精准回归退化为全量瞎跑
   ✅ 该 ignore 的是「测试产物」: coverage/ test-results/ *.png
   ⛔ 绝不能 ignore 的是「测试代码」: *.spec.ts *.test.ts

② 测试必须 import 被测源码
   affected 沿 import 依赖图反向回溯算影响面
   静态 import ✅  动态 await import() ✅  纯 HTTP 打接口 ⛔（无边可追）
   → HTTP 型测试在本表「说明」列标注「affected 不覆盖」

③ 非标准命名必须在本表登记 glob
   affected 默认只认 *.spec.* / *.test.* / __tests__/
   smoke-f5.ts 这类需显式 --filter，glob 不登记 = 无人知道怎么调
```
