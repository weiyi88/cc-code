# 🏗️ 项目技术架构与开发宪法 (project.md)

> 本文件由 [Architect] 角色维护。Dev 工程师必须将此文件作为唯一的编码准则。
> **数据结构细节不在本文件**——interface / 字段规则 / DB 列对齐统一由 `active/data.md` 承载，本文件只在第四节引用。

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

## 三、 目录结构规约 (Directory Rules)
*   [待填写]

## 四、 数据契约 (Data Contract)
> 数据层唯一真相源：`.cc_code/active/data.md`（Architect 维护，Dev/QA 必读）。
> 本文件不重复 interface 字段定义。涉及数据结构时，统一 `@active/data.md` 引用。
> Architect 须保证：DB schema 列名 ↔ `data.md` interface 字段一一对齐；跨 ORM 栈时在 `data.md` 第五节记录差异。

## 五、 特殊约束 (Constraints)
*   [待填写]
