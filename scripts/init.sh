#!/usr/bin/env bash
# cc-code Plugin - 项目场域脚手架
# 用法: bash init.sh <project_root>
set -euo pipefail

PROJECT_ROOT="${1:-$(pwd)}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PLUGIN_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
TEMPLATES="$PLUGIN_ROOT/templates"
TARGET="$PROJECT_ROOT/.cc_code"

GREEN='\033[0;32m'; YELLOW='\033[1;33m'; NC='\033[0m'
log()  { echo -e "${GREEN}[cc-code]${NC} $1"; }
warn() { echo -e "${YELLOW}[cc-code]${NC} $1"; }

# 幂等
if [ -f "$TARGET/active/Agent.md" ]; then
  warn "检测到 .cc_code/ 已存在，跳过脚手架生成。"
  exit 0
fi

log "在 $PROJECT_ROOT 创建 .cc_code/ 目录树..."
mkdir -p "$TARGET/active" "$TARGET/backup" "$TARGET/docs/plans" \
         "$TARGET/tests"

# 热区骨架
cp "$TEMPLATES/Agent.md"      "$TARGET/active/Agent.md"
cp "$TEMPLATES/status.md"     "$TARGET/active/status.md"
cp "$TEMPLATES/errors.md"     "$TARGET/active/errors.md"
cp "$TEMPLATES/project.md"    "$TARGET/active/project.md"
cp "$TEMPLATES/flow.md"       "$TARGET/active/flow.md"
cp "$TEMPLATES/front.md"      "$TARGET/active/front.md"
cp "$TEMPLATES/gates.md"      "$TARGET/active/gates.md"

# 冷区占位
mkdir -p "$TARGET/backup/$(date +%Y-%m)"
touch "$TARGET/backup/$(date +%Y-%m)/errors_archive.md"

# Hook 由插件 hooks/hooks.json 自动注册（$CLAUDE_PLUGIN_ROOT），项目无需本地副本

# changelog（唯一时间线，Hook 按 session 去重写入）
cp "$TEMPLATES/changelog.md" "$TARGET/changelog.md"

# 根目录 CLAUDE.md 入口引导（新/旧项目统一生成）
#   - 旧项目：先备份 legacy → backup/YYYY-MM/CLAUDE.md.legacy，再覆盖
#   - 新项目：直接生成
#   注：旧 CLAUDE.md 的内容分拆（理解力活）由 AI 在 /cc-code:init 对话内完成，
#       读取 backup 里的 legacy 按 init.md 的映射表归并到 active/ 各文件。
LEGACY_CLAUDE="$PROJECT_ROOT/CLAUDE.md"
YM="$(date +%Y-%m)"
if [ -f "$LEGACY_CLAUDE" ]; then
  mkdir -p "$TARGET/backup/$YM"
  cp "$LEGACY_CLAUDE" "$TARGET/backup/$YM/CLAUDE.md.legacy"
  warn "检测到旧 CLAUDE.md，已备份至 .cc_code/backup/$YM/CLAUDE.md.legacy"
  warn "→ AI 须读取该 legacy，按 /cc-code:init 映射表分拆归并到 active/ 各文件。"
fi
cp "$TEMPLATES/CLAUDE.md" "$LEGACY_CLAUDE"
log "已生成根目录 CLAUDE.md（入口引导，纯协议不含业务状态）。"

log "脚手架完成："
log "  active/   Agent status errors project flow front gates"
log "  docs/plans/  阶段方案（prd-plan 产出，Dev 按 phase 读）"
log "  backup/   冷数据归档（旧项目含 CLAUDE.md.legacy）"
log "  根目录 CLAUDE.md  工作流入口引导"
warn "Hook 由 cc-code 插件自动注册（需已 /plugin install cc-code）。"
warn "让 AI Read 根目录 CLAUDE.md → 进入状态机循环。"
