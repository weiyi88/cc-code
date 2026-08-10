# [Architect] Bull / Redis 队列设计经验（示例）

> 涉及异步队列 / 中间件设计时必读。
> 由 `/cc-code:experience-summary` 沉淀，INDEX 见 `.cc_code/references/INDEX.md`。
> 本文件是插件自带示例：新项目 init 时作为 references 写法范本参考，可按项目实情删改。

## 必答三问（plan 准出门槛）

1. Redis 清空 / 重启丢 job → DB 状态谁兜底？
2. 服务重启 → 队列里老 job 谁消费？
3. 事件丢失（完成/失败回调没发出来）→ 状态死锁谁解？

答不出 → 方案不准进 Dev。

## 设计准则

- **Bull 不是数据库**：Redis 无 AOF = 重启即丢。状态真相源永远放 DB，队列只负责驱动。
- **双通道推进**：事件驱动为主 + 定时对账兜底（用 Bull 内建 repeatable job，同进程，不外挂脚本）。
- **幂等是补偿前提**：确定性 jobId（任务+方案+序号），重复入队自动去重，对账器才能无脑补投。
- **内建机制用满再自研**：stalled 检测 / repeatable / jobId / timeout / maxStalledCount，先列清单逐个配置。
- **processor 注册放启动钩子**：不能只在新入队时注册，否则重启后老 job 无人消费。
