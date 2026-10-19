# Supabase（数据库 / 登录 / 存储 / Edge Functions）

> 命令为参考，执行前按 `SKILL.md` 铁律查最新官方文档校准。

## 适用前提

托管 Postgres + 登录 + 对象存储。前端 / 接口放别的平台（Vercel / Cloudflare / VPS），Supabase 只承担数据和登录。

## 登录检查

```bash
supabase projects list                          # 已登录（未登录：supabase login，浏览器授权）
supabase link --project-ref <项目ref>           # 首次关联
```

CI 用 `SUPABASE_ACCESS_TOKEN` / `SUPABASE_DB_PASSWORD` 环境变量。⛔ 不让主人把 `sbp_` 令牌贴进对话。

## 连接串（两条，别混）

| 用途 | 地址 | 原因 |
| --- | --- | --- |
| 应用运行时（尤其 Serverless） | 连接池地址（事务模式，6543） | 防连接耗尽 |
| 迁移 / 管理 | 直连或会话模式（5432） | 迁移需要会话级特性 |

## 数据库迁移

按 project.md 声明的迁移工具走，⛔ 禁止 `pg_dump` 导表结构直接灌生产（没有迁移历史，下次就对不上）。

| 迁移工具 | 预览 | 执行 |
| --- | --- | --- |
| Supabase CLI | `supabase db push --dry-run` | `supabase db push` |
| Prisma | `prisma migrate status` | `prisma migrate deploy`（用直连地址） |
| Drizzle | `drizzle-kit check` | `drizzle-kit migrate` |

记下迁移后的**最新迁移版本**交 qa 记入 §八。

## 登录（Auth）

| 配置 | 位置 |
| --- | --- |
| Site URL + Redirect URLs | 控制台 Authentication → URL Configuration，加正式域名 |
| 第三方登录（GitHub / Google 等） | 第三方应用里的回调地址填 `https://<项目ref>.supabase.co/auth/v1/callback` |

这些都登记在 project.md §8.4，预检逐条确认。

## 上线前安全检查

- `public` schema 下对外暴露的表全部开启 RLS（控制台 Advisors 或查询 `pg_tables.rowsecurity`）
- `service_role` 密钥只在服务端变量里，⛔ 不进任何 `NEXT_PUBLIC_*`

## Edge Functions / 机密

```bash
supabase secrets list
supabase secrets set --env-file <生产env文件>     # 从文件读，不进对话
supabase functions deploy <函数名>
```

## 回滚

数据库**不回滚**：出错写一条新迁移向前修。备份恢复 / PITR 是最后手段，会丢数据，必须主人决定。Edge Functions 用上一可用提交重新 deploy。

## 常见坑

| 坑 | 处理 |
| --- | --- |
| 国内网络直连数据库 DNS 失败 | 换网络；兜底用 Management API `POST /v1/projects/<ref>/database/query` 执行 SQL（用 curl，Python urllib 会被 WAF 拦） |
| 免费项目闲置被暂停 | 上线前确认项目处于活动状态 |
| 迁移卡在历史不一致 | `supabase migration list` 对比，`supabase migration repair` 修历史表——需确认 |
