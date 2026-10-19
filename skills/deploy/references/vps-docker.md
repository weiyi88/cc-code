# VPS + Docker（兜底方案）

> 命令为参考，执行前按 `SKILL.md` 铁律查最新官方文档校准。

## 适用前提

| 适合 | 说明 |
| --- | --- |
| 常驻进程 / 队列消费者（如 BullMQ + Redis） | Serverless 平台跑不了的都放这里 |
| WebSocket / 长任务 / 原生依赖 | 没有平台限制 |
| 自建 Postgres / Redis | 用容器 + 数据卷 |

前提：服务器已装 Docker 与 Compose 插件；反向代理推荐 Caddy（自动 HTTPS），或 Nginx + certbot。

## 登录检查

```bash
ssh <主机> 'docker compose version'     # 能免密登录且 Docker 可用
```

⛔ 不让主人在对话里贴服务器密码，只用 SSH 密钥。

## 密钥注入

服务器上放 `.env`（权限 600），compose 用 `env_file` 读取：

```bash
scp .env.production <主机>:<部署目录>/.env && ssh <主机> 'chmod 600 <部署目录>/.env'
```

⛔ 密钥不打进镜像、不进 git。

## 首次开通

1. 服务器建部署目录，放 `docker-compose.yml`（每个组件一个服务，带 `healthcheck`）
2. 反向代理配置正式域名 → 对应服务端口
3. 请主人在 DNS 加 A 记录指向服务器 IP
4. 防火墙只开 22 / 80 / 443
5. 数据库 / Redis 容器挂数据卷，确认有备份方案

## 日常发布

镜像 tag 一律用 **git 提交号**（回滚依据），⛔ 禁用 `latest`。

| 方式 | 步骤 |
| --- | --- |
| 镜像仓库（推荐） | 本地或 CI 构建并推送 `<镜像>:<提交号>` → 服务器改 tag → `docker compose pull && docker compose up -d` |
| 服务器构建 | `git pull` 到指定提交 → `docker compose up -d --build` |

有数据库迁移时，先跑迁移容器 / 迁移命令，再起新版应用。发布后把各服务 tag 交 qa 记入 §八。

## 回滚

把 tag 改回 §八「上一可用版本」的提交号 → `docker compose up -d`。数据库不回滚。

## 日志（冒烟取证）

```bash
ssh <主机> 'cd <部署目录> && docker compose ps && docker compose logs --since 10m <服务>'
```

应用按 project.md §七 输出 JSON 到 stdout，可按 `level` / `requestId` 过滤。

## 常见坑

| 坑 | 处理 |
| --- | --- |
| 发版时队列任务被打断 | 消费者处理 SIGTERM，做完当前任务再退出；compose 设足够的 `stop_grace_period` |
| 磁盘被旧镜像 / 日志塞满 | 配置日志滚动；清理镜像需主人确认 |
| 容器起了但服务没就绪 | 依赖用 `depends_on: condition: service_healthy` |
