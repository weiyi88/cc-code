# Vercel

> 命令为参考，执行前按 `SKILL.md` 铁律查最新官方文档校准。

## 适用前提

| 适合 | 不适合（换平台） |
| --- | --- |
| Next.js / 静态前端 / 短时 Serverless 接口 / Vercel Cron | 常驻进程、队列消费者、WebSocket 长连接、超过函数时限的长任务 → `vps-docker.md` 或 Cloudflare Queues |

## 登录检查

```bash
vercel whoami          # 已登录
vercel link            # 首次：本地目录关联到 Vercel 项目（生成 .vercel/，应被 gitignore）
```

CI 场景用 `VERCEL_TOKEN` 环境变量，⛔ 不把令牌写进仓库或对话。

## 密钥注入

```bash
vercel env ls production                                   # 只比名字
grep '^NAME=' .env | cut -d= -f2- | vercel env add NAME production   # 值走管道，不出现在对话
```

| 要点 | 说明 |
| --- | --- |
| 分环境 | production / preview / development 各配一份，互不继承 |
| 构建时变量 | `NEXT_PUBLIC_*` 在构建时写进产物，改了必须重新部署 |
| 改值生效 | 任何变量改动都要重新部署才生效 |

## 首次开通

1. `vercel link` 关联项目，确认框架预设与构建命令
2. 按 §8.3 注入生产变量
3. 绑定域名：控制台 Settings → Domains（或 `vercel domains add`），按提示让主人在 DNS 加记录
4. 连接 Git 仓库（推荐）：生产分支推送即自动发布

## 日常发布

| 方式 | 命令 |
| --- | --- |
| Git 集成 | 推送生产分支（危险动作，需确认）→ 自动构建 |
| 命令行 | `vercel deploy --prod` |

发布后 `vercel list --prod` / `vercel inspect <部署地址>` 取**部署 ID** 交 qa 记入 §八。

## 回滚

```bash
vercel rollback <上一可用部署地址或ID>
vercel rollback status
vercel promote <部署地址>        # 撤销回滚 / 直接提升某个好版本
```

指定任意历史版本回滚需 Pro 及以上套餐；Hobby 只能回到上一个生产部署。

## 日志（冒烟取证）

```bash
vercel logs --environment production --since 10m --level error
```

## 常见坑

| 坑 | 处理 |
| --- | --- |
| Serverless 连数据库连接耗尽 | 运行时用连接池地址（如 Supabase 事务池 6543 端口），迁移才用直连 |
| 函数超时 | 长任务拆到队列 + 常驻 Worker |
| Cron 不触发 | 只在生产部署生效；配置写在 `vercel.json` 的 `crons` |
| preview 用了生产库 | preview 环境变量单独指向测试库 |
