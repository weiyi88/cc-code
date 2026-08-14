---
description: 幂等拉起/复用 cc-code dashboard 只读镜子 + 串行派活控制台。每次进项目都可以敲，活着就只回地址不重起，死了就重新拉起。
allowed-tools: Bash
disable-model-invocation: true
---

# /cc-code:dashboard — 拉起项目仪表盘

`init` 只搭场域，是一次性动作；**看仪表盘是每次进项目都可能要做的事**，所以是独立命令，不挂在 `init` 上。

## 执行

```bash
bash "$CLAUDE_PLUGIN_ROOT/scripts/init.sh" --dashboard
```

脚本内部 `ensure_dashboard()` 的幂等逻辑：

```
  读 .cc_code/.runtime/dashboard.pid
        │
        ├─ 进程还活着(kill -0)? ──是──► 只回地址, 不重起
        │
        └─ 没起 / 已死 ──► 清僵尸 pid → 后台起新进程 → 写新 pid/port
```

## 输出

- 正常：一行 `📊 Dashboard → http://localhost:<port>`，AI 原样转达给用户，不要复述内部实现细节。
- `DASHBOARD_NODE_MISSING`：Node.js 未装，静默降级。告知用户一句「dashboard 需要 Node.js，未检测到，跳过（不影响主流程）」，⛔ 不自动装 Node。
- 无 `.cc_code/`：提示先跑 `/cc-code:init`。

## 铁律（贯穿本命令）

- **纯只读镜子**：dashboard 页面本身零写入 `.cc_code/`；唯一的「写」路径是页面上拖动卡片触发的**派活**（起一个真实的 `dev`/`qa` agent 子进程去改文件），AI 本身不因为这个命令去改任何业务文件。
- **`.cc_code/.runtime/` 是运行时产物**（pid / 端口 / dashboard 派发用的固定 session id），AI 禁止读写这个目录，也不算作 `.cc_code` 的规范 8 文件之一。
- 本命令不产生任何业务状态变更，禁止在 `status.md` / `gates.md` 留痕。
