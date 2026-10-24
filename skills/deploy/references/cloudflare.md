# Cloudflare（Workers / Pages / Queues / D1 / R2 / KV / Cron）

> 命令为参考，执行前按 `SKILL.md` 铁律查最新官方文档校准。

## 适用前提

| 组件 | 用什么 |
| --- | --- |
| Next.js 全栈 | Workers + `@opennextjs/cloudflare` 适配器（旧 `@cloudflare/next-on-pages` 已不推荐） |
| 纯静态站 | Pages |
| 接口 / 定时任务 | Workers + Cron Triggers |
| 队列 | Queues（消费者本身是一个 Worker） |
| 数据 | D1（SQLite）/ R2（对象）/ KV（键值） |

| 不适合 | 换平台 |
| --- | --- |
| 依赖原生 Node 模块、超出 Worker CPU / 体积限制、需要常驻进程 | `vps-docker.md` |

## 登录检查

```bash
wrangler whoami
```

CI 用 `CLOUDFLARE_API_TOKEN` 环境变量。⛔ 禁止从本机 wrangler 配置文件里抠 OAuth 令牌拿去调 API——权限不够还泄露。需要改 DNS 时请主人在控制台建「Edit zone DNS」范围的 API Token。

## 代码适配（属于代码改动 → 走 just-do-it，不在部署里做）

Next.js 项目未适配时，预检给出一句话需求，例如：
「用 `npx @opennextjs/cloudflare migrate` 把项目适配到 Cloudflare Workers」。

适配后 wrangler 配置必须满足：

| 项 | 要求 |
| --- | --- |
| `compatibility_flags` | 含 `nodejs_compat` |
| `compatibility_date` | ≥ `2024-09-23` |
| `main` / `assets` | 指向 `.open-next/` 产物，不要改 |

## 密钥注入

```bash
wrangler secret list                                       # 只比名字
grep '^NAME=' .env | cut -d= -f2- | wrangler secret put NAME   # 值走管道
```

非机密配置写 wrangler 配置的 `vars`。构建时变量（如 `NEXT_PUBLIC_*`）必须在构建环境里存在。

## 首次开通（产出的资源标识由主控派 dev 写回已存在的 wrangler 配置，主控单独提交）

```bash
wrangler d1 create <库名>
wrangler queues create <队列名>
wrangler r2 bucket create <桶名>
wrangler kv namespace create <名字>
```

域名：区域必须已托管在 Cloudflare（`dig <域名> NS +short` 验证）；Workers 用 Custom Domains，Pages 在项目里加自定义域名。

## 日常发布

| 组件 | 命令 |
| --- | --- |
| D1 迁移 | `wrangler d1 migrations list <库> --remote` 预览 → `wrangler d1 migrations apply <库> --remote` |
| Next.js（OpenNext） | `npm run deploy`（= `opennextjs-cloudflare build && opennextjs-cloudflare deploy`） |
| 普通 Worker / 队列消费者 | `wrangler deploy` |
| Pages 静态站 | `wrangler pages deploy <产物目录> --project-name <项目>` |

发布后 `wrangler deployments list` 取 **Worker 版本 ID** 交 qa 记入 §八。

## 回滚

```bash
wrangler deployments list
wrangler rollback <上一可用版本ID>     # 不带 ID = 回到上一个稳定版本
```

⚠️ 回滚**只回 Worker 代码**，D1 / R2 / KV / Durable Object 数据不回滚。Pages 在控制台 Deployments 里对旧部署点 Rollback。

## 日志（冒烟取证）

```bash
wrangler tail <worker名> --status error
```

长期查询需在 wrangler 配置开启 `observability`，在控制台 Workers Logs 按字段筛。

## 常见坑

| 坑 | 处理 |
| --- | --- |
| 运行时报缺 Node API | 检查 `nodejs_compat` 与兼容日期 |
| 应用内 fetch 自身域名失败 | 加 `global_fetch_strictly_public` 标志 |
| 改了 secret 没生效 | secret 绑定到新版本，需重新部署 |
| Cron 本地不跑 | Cron Triggers 只在已部署 Worker 上触发 |
