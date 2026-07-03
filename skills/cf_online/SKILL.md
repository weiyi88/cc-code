---
name: cf_online
description: 将 Next.js 项目部署到 Cloudflare Pages（Edge Runtime）。当用户说"cf_online"、"上线cloudflare"、"部署cloudflare"、"CF部署" 时触发。
disable-model-invocation: true
---

# Cloudflare Pages 上线技能

将 Next.js (App Router) 项目部署到 Cloudflare Pages Edge Runtime，包含完整的预检、构建、部署、域名配置流程。

## 适用场景

- Next.js App Router 项目部署到 Cloudflare Pages
- 已有 GitHub 仓库，需要上线到 Cloudflare
- 需要为 Cloudflare Pages 配置自定义域名

---

## 完整流程

### Phase 0: 预检（必做）

部署前必须检查以下项目配置，逐项修复：

#### 0.1 wrangler.toml

确认项目根目录存在 `wrangler.toml`，内容必须包含：

```toml
#:schema node_modules/wrangler/config-schema.json

name = "<project-name>"
compatibility_date = "2024-12-01"
compatibility_flags = ["nodejs_compat"]
pages_build_output_dir = ".vercel/output/static"
```

- `name`：项目名（小写，将作为 `<name>.pages.dev` 子域名）
- `compatibility_flags`：**必须**包含 `nodejs_compat`，否则运行时 503 错误
- `pages_build_output_dir`：**必须**设置，否则 wrangler 不会应用 compatibility_flags

#### 0.2 next.config.mjs

```javascript
/** @type {import('next').NextConfig} */
const nextConfig = {
  reactStrictMode: true,
  images: {
    unoptimized: true,  // Cloudflare Pages 不支持 Next.js 图片优化
  },
  // 注意：不要设置 output: 'export'，@cloudflare/next-on-pages 会处理输出格式
};

export default nextConfig;
```

#### 0.3 Edge Runtime 声明

所有动态页面和 API 路由**必须**添加 Edge Runtime 声明：

```typescript
// app/page.tsx
export const runtime = 'edge';

// app/api/xxx/route.ts
export const runtime = 'edge';

// app/generator/[param]/page.tsx
export const runtime = 'edge';
```

**⚠️ 关键限制（Next.js 15）：**
- `export const runtime = 'edge'` 和 `generateStaticParams` 不能共存
- 选择 edge runtime 就必须是动态渲染，放弃静态生成
- `params` 类型变为 `Promise<{...}>`，需要 `await params`

```typescript
// Next.js 15 正确写法
export default async function Page({
  params,
}: {
  params: Promise<{ platform: string }>;
}) {
  const { platform } = await params;
  // ...
}
```

#### 0.4 依赖版本兼容

| 依赖 | 要求 | 原因 |
|------|------|------|
| `next` | >= 14.3.0 | `@cloudflare/next-on-pages` 最低要求 |
| `@cloudflare/next-on-pages` | 最新版 | 构建适配器 |
| `eslint` + `eslint-config-next` | 版本匹配 | ESLint v9 与 eslint-config-next 不兼容，用 v8 |

```bash
# 安装必要依赖
npm install -D @cloudflare/next-on-pages
# 如有 ESLint 冲突
npm install -D eslint@8 eslint-config-next@14
```

#### 0.5 package.json scripts

确保有以下 scripts：

```json
{
  "scripts": {
    "build:cf": "npx @cloudflare/next-on-pages",
    "preview": "npx wrangler pages dev .vercel/output/static",
    "deploy": "npm run build:cf && npx wrangler pages deploy .vercel/output/static"
  }
}
```

#### 0.6 域名引用检查

检查项目中硬编码的域名（sitemap.ts、robots.ts、layout.tsx 等），更新为目标域名：

```bash
rg "old-domain\.com" -l
```

### Phase 1: 构建验证

```bash
# 本地构建测试
npm run build:cf
```

**成功输出示例：**
```
⚡️ Edge Function Routes (3)
⚡️   ┌ /
⚡️   ├ /api/agent
⚡️   └ /generator/[platform]
⚡️
⚡️ Prerendered Routes (2)
⚡️   ┌ /robots.txt
⚡️   └ /sitemap.xml
⚡️
⚡️ Other Static Assets (34)
```

**常见构建错误：**

| 错误 | 原因 | 修复 |
|------|------|------|
| `routes not configured to run with Edge Runtime` | 缺少 `export const runtime = 'edge'` | 在所有动态路由添加声明 |
| `Page cannot use both edge runtime and generateStaticParams` | Next.js 15 限制 | 删除 `generateStaticParams` |
| `output: 'export' incompatible with API routes` | 不能同时用静态导出和 API 路由 | 从 next.config 移除 `output: 'export'` |
| npm ERESOLVE peer dep conflict | 依赖版本冲突 | 使用 `--legacy-peer-deps` |

### Phase 2: Wrangler 登录

```bash
npx wrangler login
```

浏览器会弹出 Cloudflare OAuth 授权页面，点击允许即可。

**验证登录：**
```bash
npx wrangler whoami
```

### Phase 3: 创建 Pages 项目

```bash
npx wrangler pages project create <project-name> --production-branch master
```

- `<project-name>` 将成为 `<name>.pages.dev` 子域名
- `--production-branch` 通常为 `master` 或 `main`

### Phase 4: 部署

```bash
npx wrangler pages deploy .vercel/output/static \
  --project-name <project-name> \
  --branch master \
  --commit-dirty=true
```

**`--commit-dirty=true`**：跳过 git clean 检查（本地有未提交更改时需要）

**验证部署：**
```bash
curl -s -o /dev/null -w "HTTP %{http_code}" "https://<project-name>.pages.dev"
# 期望: HTTP 200
```

**如果返回 503 + "no nodejs_compat compatibility flag"：**

1. 删除项目重建：
   ```bash
   npx wrangler pages project delete <project-name>
   npx wrangler pages project create <project-name> --production-branch master
   ```
2. 确保 `wrangler.toml` 包含 `pages_build_output_dir`
3. 重新部署

### Phase 5: 自定义域名

#### 5.1 前提

- 域名必须已在 Cloudflare 管理（NS 指向 Cloudflare）
- 用 `dig <domain> NS +short` 验证 nameserver

#### 5.2 通过 API 添加（推荐）

从 wrangler 配置文件提取 OAuth Token：

```bash
# macOS: token 存储位置
cat ~/Library/Preferences/.wrangler/config/default.toml
# 提取 oauth_token 值
```

添加自定义域名到 Pages 项目：

```bash
CF_TOKEN="<oauth_token>"
ACCOUNT_ID="<from wrangler whoami>"

# 添加主域名
curl -s -X POST \
  "https://api.cloudflare.com/client/v4/accounts/$ACCOUNT_ID/pages/projects/<project-name>/domains" \
  -H "Authorization: Bearer $CF_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"name":"<custom-domain.com>"}'

# 添加 www 子域名
curl -s -X POST \
  "https://api.cloudflare.com/client/v4/accounts/$ACCOUNT_ID/pages/projects/<project-name>/domains" \
  -H "Authorization: Bearer $CF_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"name":"www.<custom-domain.com>"}'
```

#### 5.3 添加 DNS CNAME 记录

OAuth Token 默认只有 `zone:read` 权限，**没有 `zone:write`**，无法通过 API 添加 DNS 记录。

**方式 A：Dashboard 手动添加（推荐）**

1. 打开 [Cloudflare Dashboard](https://dash.cloudflare.com)
2. 选择目标域名 → DNS → Records → Add Record
3. 添加两条 CNAME：

| Type | Name | Target | Proxy |
|------|------|--------|-------|
| CNAME | `@` | `<project-name>.pages.dev` | ✅ Proxied |
| CNAME | `www` | `<project-name>.pages.dev` | ✅ Proxied |

**方式 B：创建 API Token 添加**

1. Dashboard → My Profile → API Tokens → Create Token
2. 选择 "Edit zone DNS" 模板
3. 指定 `shopifypolicy.com` 区域
4. 用生成的 Token 调用 API：

```bash
CF_API_TOKEN="<your-api-token>"
ZONE_ID="<from API: /zones?name=<domain>>"

curl -X POST "https://api.cloudflare.com/client/v4/zones/$ZONE_ID/dns_records" \
  -H "Authorization: Bearer $CF_API_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "type": "CNAME",
    "name": "<custom-domain.com>",
    "content": "<project-name>.pages.dev",
    "proxied": true
  }'
```

#### 5.4 验证域名

```bash
# 检查域名状态
curl -s "https://api.cloudflare.com/client/v4/accounts/$ACCOUNT_ID/pages/projects/<project-name>/domains" \
  -H "Authorization: Bearer $CF_TOKEN" | python3 -c "
import sys, json
d = json.load(sys.stdin)
for r in d['result']:
    print(f'{r[\"name\"]}: {r[\"status\"]}')
"

# 测试访问
curl -s -o /dev/null -w "HTTP %{http_code}" "https://<custom-domain.com>"
```

状态从 `pending` 变为 `active` 即表示生效（通常 1-2 分钟，SSL 证书签发需要时间）。

### Phase 6: 后续更新部署

代码更新后，只需重新构建部署：

```bash
npm run deploy
# 或分步执行：
npm run build:cf
npx wrangler pages deploy .vercel/output/static --project-name <project-name> --branch master
```

---

## 故障排查速查表

| 问题 | 症状 | 解决方案 |
|------|------|---------|
| nodejs_compat 缺失 | 503 + "no nodejs_compat" | wrangler.toml 添加 `compatibility_flags = ["nodejs_compat"]` + `pages_build_output_dir` |
| Edge Runtime 未声明 | 构建成功但路由 404 | 所有动态路由添加 `export const runtime = 'edge'` |
| Next.js 版本过低 | `@cloudflare/next-on-pages` peer dep 报错 | 升级 Next.js >= 14.3.0 |
| ESLint v9 冲突 | `eslint-config-next` 不兼容 | 降级 `eslint@8` + `eslint-config-next@14` |
| params 类型错误 | Next.js 15 页面报错 | `params` 改为 `Promise<{}>` 类型，使用 `await` |
| generateStaticParams 冲突 | 构建失败 | Edge Runtime 下删除 `generateStaticParams` |
| DNS 未配置 | 自定义域名 pending | 添加 CNAME 记录指向 `<name>.pages.dev` |
| OAuth Token 权限不足 | API 返回 Authentication error | Token 仅有 zone:read，需 Dashboard 或创建专用 API Token |
| 图片优化失败 | 图片 500 错误 | `next.config.mjs` 设置 `images: { unoptimized: true }` |
| 静态导出冲突 | API 路由不工作 | 移除 `output: 'export'` |

---

## 环境变量配置

Cloudflare Pages 环境变量通过 Dashboard 设置：

1. Workers & Pages → 项目 → Settings → Environment variables
2. 分别配置 Production 和 Preview 环境

或通过 wrangler CLI：

```bash
npx wrangler pages secret put VARIABLE_NAME --project-name <project-name>
```

**注意：** `NEXT_PUBLIC_*` 变量需要在构建时注入，在 Pages 设置中标记为 "Build" 可见。

---

## 自动化部署（GitHub 集成）

### 方式 A：Cloudflare Dashboard 连接 GitHub

1. Workers & Pages → Create → Connect to Git
2. 选择 GitHub 仓库
3. 配置：
   - Framework preset: `Next.js (Static HTML Export)` 或 None
   - Build command: `npx @cloudflare/next-on-pages`
   - Build output directory: `.vercel/output/static`
   - Environment variable: `NODE_VERSION=20`

### 方式 B：GitHub Actions

```yaml
name: Deploy to Cloudflare Pages
on:
  push:
    branches: [master]
jobs:
  deploy:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: actions/setup-node@v4
        with:
          node-version: 20
      - run: npm ci --legacy-peer-deps
      - run: npx @cloudflare/next-on-pages
      - uses: cloudflare/wrangler-action@v3
        with:
          apiToken: ${{ secrets.CF_API_TOKEN }}
          command: pages deploy .vercel/output/static --project-name=<project-name>
```

---

## 变量说明

当调用此 skill 时，需要确认以下变量：

| 变量 | 说明 | 示例 |
|------|------|------|
| `<project-name>` | Cloudflare Pages 项目名 | `shopifypolicy` |
| `<custom-domain.com>` | 自定义域名 | `shopifypolicy.com` |
| `<production-branch>` | 生产分支 | `master` 或 `main` |
| `<ACCOUNT_ID>` | Cloudflare 账户 ID | 从 `wrangler whoami` 获取 |
| `<CF_TOKEN>` | Wrangler OAuth Token | 从 `~/Library/Preferences/.wrangler/config/default.toml` 获取 |

**执行逻辑：** 从项目代码和 `wrangler whoami` 输出中自动提取变量值，无需用户手动输入。
