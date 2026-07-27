# 📊 数据契约 (data.md)

> 本文件由 [Architect] 角色维护。承载 interface 定义、字段规则、原型↔真实切换约定。
> **Dev / QA 必读；PM 禁读**（PM 不关心接口细节，避免被技术约束带偏、污染需求纯粹性）。
> 来源：V0 原型 `docs/api.md` / 产品规格 §数据模型。Architect 须把散落的 interface 提炼至此，作为数据层唯一真相源。

## 一、 数据模型 Interface

> 用 TypeScript interface 定义所有数据结构。**字段名即数据库列名，类型即列类型**。
> 新增字段时同步更新本段 + 第二节字段规则 + 第五节 DB 列对齐。

```typescript
// 示例结构（Architect 按 V0 原型 api.md 填充）：
// interface Task {
//   id: string
//   type: 'brief' | 'single' | 'batch'
//   status: 'draft' | 'ai_splitting' | 'queued' | 'generating' | 'refining' | 'done' | 'paused'
//   ...
// }
```

[待 Architect 填写]

## 二、 字段规则矩阵

| 字段 | 类型 | 必填 | 枚举/范围 | 备注 |
| --- | --- | --- | --- | --- |
| [待填写] | | | | |

## 三、 原型 ↔ 真实切换约定

> 原型阶段前端用 `useState` 持有 mock（形状 = 上述 interface）；真实联调阶段替换为 `fetch` / API 调用，**形状不变**。
> Architect 须在此背书「interface 字段 ↔ DB 列」对齐关系，Dev 切原型→真实时只换数据源、不改形状。

| 字段/功能 | 原型阶段 | 真实联调 | 切换方式 |
| --- | --- | --- | --- |
| [待填写] | useState mock | fetch API | 形状不变 |

## 四、 MOCK 标记区

> 标记哪些功能/字段处于原型 mock 态，对应组件文件，以及真实化优先级。

| 功能 | 组件文件 | MOCK 内容 | 真实化优先级 |
| --- | --- | --- | --- |
| [待填写] | | | P0 / P1 / P2 |

## 五、 DB 列对齐表

> interface 字段与实际 schema 列的对齐关系。跨 ORM 栈（如 Prisma + Drizzle 并存）时尤其重要——
> Architect 须保证两栈列名与本表一致，或在此记录差异。

| interface 字段 | schema 列 | 表 | ORM 栈 |
| --- | --- | --- | --- |
| [待填写] | | | A / B |
