---
name: cc-code:cf_online
description: 将 Next.js 项目部署到 Cloudflare Pages（Edge Runtime）。当用户说"cf_online"、"上线cloudflare"、"部署cloudflare"、"CF部署"时触发。
allowed-tools: Read, Glob, Grep, Bash, Edit, Write, Agent, AskUserQuestion
argument-hint: [--skip-build] [--skip-domain] [--domain <自定义域名>]
---

$ARGUMENTS

# /cc-code:cf_online — Cloudflare Pages 上线部署

将 Next.js (App Router) 项目部署到 Cloudflare Pages Edge Runtime。

---

## 调用方式

```
/cc-code:cf_online                  完整部署流程（预检→构建→部署→域名）
/cc-code:cf_online --skip-build     跳过构建，直接部署已有产物
/cc-code:cf_online --skip-domain    跳过自定义域名配置
/cc-code:cf_online --domain shopifypolicy.com  指定自定义域名
```

---

## 执行流程

### 第一步：读取部署技能

用 Read 工具读取 `$CLAUDE_PLUGIN_ROOT/skills/cf_online/SKILL.md`，获取完整的部署流程规则（Phase 0-6 + 故障排查 + 环境变量配置）。

### 第二步：预检（Phase 0）

从 SKILL.md Phase 0 逐项检查：

| 检查项 | 文件 | 关键要求 |
|--------|------|---------|
| wrangler.toml | 根目录 | `nodejs_compat` + `pages_build_output_dir` |
| next.config.mjs | 根目录 | `images: { unoptimized: true }`，无 `output: 'export'` |
| Edge Runtime | 所有动态路由 | `export const runtime = 'edge'` |
| 依赖版本 | package.json | `next >= 14.3.0`，`@cloudflare/next-on-pages` 已安装 |
| package.json scripts | package.json | `build:cf`、`preview`、`deploy` 三个脚本 |
| 域名引用 | sitemap/robots/layout | 硬编码域名与目标一致 |

发现不合规项立即修复，逐项确认通过。

### 第三步：构建验证（Phase 1）

```bash
npm run build:cf
```

检查构建输出是否包含 Edge Function Routes 和 Prerendered Routes。如果构建失败，查阅 SKILL.md 故障排查速查表修复。

### 第四步：登录与项目创建（Phase 2-3）

1. `npx wrangler whoami` 检查登录状态，未登录则 `npx wrangler login`
2. 确认 Pages 项目存在，不存在则创建：
   ```bash
   npx wrangler pages project create <project-name> --production-branch master
   ```

### 第五步：部署（Phase 4）

```bash
npx wrangler pages deploy .vercel/output/static \
  --project-name <project-name> \
  --branch master \
  --commit-dirty=true
```

验证：`curl -s -o /dev/null -w "HTTP %{http_code}" "https://<project-name>.pages.dev"` 期望 200。

### 第六步：自定义域名（Phase 5）

如果 `--skip-domain` 未指定：
1. 确认域名在 Cloudflare 管理
2. 通过 API 或 Dashboard 添加 CNAME 记录
3. 验证域名状态从 pending → active

### 第七步：环境变量配置

提示用户在 Cloudflare Dashboard 配置环境变量，特别是 `NEXT_PUBLIC_*` 变量需要标记为 Build 可见。

---

## 参数处理

- `--skip-build`：跳过第三步构建验证，直接使用已有 `.vercel/output/static` 产物
- `--skip-domain`：跳过第六步自定义域名配置
- `--domain <domain>`：指定自定义域名（如未指定，从项目 wrangler.toml 或询问用户获取）

---

## 重要约束

- 每一步必须确认成功后再进入下一步
- 503 错误优先检查 `nodejs_compat` 和 `pages_build_output_dir`
- 构建失败时查阅 SKILL.md 故障排查速查表
- 自定义域名 DNS 记录必须用 Proxied 模式（橙色云图标）
