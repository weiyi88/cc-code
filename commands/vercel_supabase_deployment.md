---
name: cc_code:vercel_supabase_deployment
description: 一键将 Next.js 项目部署到 Vercel + Supabase。自动完成：读取本地 .env、提取本地 PostgreSQL schema、创建/导入 Supabase 数据库、推送 GitHub、配置 Vercel 环境变量、触发生产部署。当用户说"帮我部署"、"deploy"、"部署项目"、"上线"时触发。
---

# Vercel + Supabase 一键部署

## 前置条件（用户需提前完成）

1. **本地 `.env` 已配置**（我直接读取，无需用户手动提供）
2. **Supabase Access Token**（`sbp_` 开头），用户在对话中提供
3. **GitHub 远程仓库已配置**（`git remote -v` 可见）
4. **Vercel CLI 已本地登录**（`vercel whoami` 可用）
5. **GitHub OAuth App Callback URL** 已改为新生产域名（唯一需要用户手动操作的步骤）

---

## 部署流程

### Step 1：读取环境配置

```bash
cat .env
```

从 `.env` 提取：
- `DATABASE_URL`（Supabase Transaction Pooler，端口 6543）
- `DIRECT_URL`（Supabase Direct Connection，端口 5432）
- `NEXTAUTH_URL`（生产域名）
- 其他所有变量

从 `DIRECT_URL` 解析出 Supabase Project Ref（格式：`db.<ref>.supabase.co`）

---

### Step 2：提取本地 PostgreSQL Schema

```bash
pg_dump -h localhost -U <本地DB用户> -d <本地DB名> \
  --schema-only --no-owner --no-acl \
  -f .cc_code/scripts/schema_export.sql
```

> 注意：用户名不是 `postgres`，是本地系统用户（如 `blue_focus`）。如果失败，用 `psql -l` 查看实际用户。

---

### Step 3：通过 Supabase Management API 导入 Schema

**不能用直连**（中国网络 DNS 解析失败），必须用 REST API + curl。

```python
import subprocess, re

access_token = "<用户提供的 sbp_ token>"
project_ref = "<从 DIRECT_URL 解析的 ref>"

with open(".cc_code/scripts/schema_export.sql") as f:
    sql_content = f.read()

# 逐行状态机解析 SQL 语句（处理多行 + dollar-quoting）
statements = parse_sql_statements(sql_content)

for i, stmt in enumerate(statements):
    payload = {"query": stmt}
    result = subprocess.run([
        "curl", "-s", "-X", "POST",
        f"https://api.supabase.com/v1/projects/{project_ref}/database/query",
        "-H", f"Authorization: Bearer {access_token}",
        "-H", "Content-Type: application/json",
        "-d", json.dumps(payload)
    ], capture_output=True, text=True)
    print(f"[{i+1}/{len(statements)}] {'✓' if '\"error\"' not in result.stdout else '✗'}")
```

**SQL 解析规则**（状态机，非正则）：
- 遇到 `$$` 进入 dollar-quote 模式，直到下一个 `$$` 退出
- 遇到 `'` 进入字符串模式，`''` 是转义不退出
- 遇到 `--` 跳过行注释
- `;` 在普通模式下才是语句分隔符

---

### Step 4：推送代码到 GitHub

```bash
git add -A
git commit -m "feat(deploy): deploy to Vercel + Supabase"
git push origin main
```

---

### Step 5：配置 Vercel 环境变量

```bash
# 检查项目是否已关联
vercel ls

# 如果是新项目，先关联
vercel link

# 批量设置环境变量（从 .env 读取）
vercel env add DATABASE_URL production
vercel env add DIRECT_URL production
vercel env add AUTH_SECRET production
vercel env add AUTH_GITHUB_ID production
vercel env add AUTH_GITHUB_SECRET production
vercel env add SMTP_USER production
vercel env add SMTP_PASS production
vercel env add SMTP_FROM production
vercel env add NEXTAUTH_URL production
vercel env add THIRD_PARTY_AI_KEY production
vercel env add THIRD_PARTY_AI_BASE_URL production
vercel env add THIRD_PARTY_AI_MODEL production
```

> 已存在的变量用 `vercel env rm` 先删除再添加，或用 `--force`。

---

### Step 6：触发生产部署

GitHub push 会自动触发 Vercel 部署。等待结果：

```bash
# 等待构建完成
sleep 30 && vercel ls | head -5
```

预期看到 `● Ready` 状态。

---

### Step 7：验证部署

```bash
vercel alias ls | head -10
```

输出生产域名，确认可访问。

---

## 常见问题与解决方案

| 问题 | 原因 | 解决 |
|------|------|------|
| `pg_dump` 报用户不存在 | 用户名不是 postgres | 改用 `whoami` 对应的系统用户名 |
| Supabase 直连 DNS 失败 | 中国网络限制 | 改用 Management REST API |
| Python urllib 403 | Cloudflare WAF | 改用 curl subprocess |
| Prisma P1012 错误 | Prisma 7 不支持 schema 里写 url | url/directUrl 移到 prisma.config.ts，datasource 用 `env('DIRECT_URL')` |
| `Module not found @/generated/prisma` | Prisma 7 无 index.ts + 文件被 gitignore | 导入改为 `@/generated/prisma/client`，解除 gitignore 并 commit 生成文件 |
| `directUrl` TS 类型错误 | prisma.config.ts 类型不支持 directUrl | prisma.config.ts 只放 url，schema.prisma 不放任何 url |

---

## Prisma 7 配置规范（本项目已验证）

**prisma/schema.prisma**（只留 provider，不放 url）：
```prisma
datasource db {
  provider = "postgresql"
}
```

**prisma.config.ts**（CLI 用 DIRECT_URL）：
```typescript
import { defineConfig, env } from "prisma/config";
type Env = { DIRECT_URL: string };
export default defineConfig({
  schema: "prisma/schema.prisma",
  datasource: { url: env<Env>("DIRECT_URL") },
});
```

**src/lib/prisma.ts**（运行时用 DATABASE_URL + adapter）：
```typescript
import { PrismaClient } from "@/generated/prisma/client"
import { PrismaPg } from "@prisma/adapter-pg"
const adapter = new PrismaPg({ connectionString: process.env.DATABASE_URL! })
export const prisma = new PrismaClient({ adapter })
```

---

## 用户只需做一件事

> **把 GitHub OAuth App 的 Callback URL 改成新生产域名**
> `https://新域名/api/auth/callback/github`

其余全部自动完成喵~
