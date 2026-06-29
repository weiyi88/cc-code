#!/usr/bin/env bash
# cc_code Plugin - 项目场域脚手架
# 用法: bash init.sh <project_root>
set -euo pipefail

PROJECT_ROOT="${1:-$(pwd)}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PLUGIN_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
TEMPLATES="$PLUGIN_ROOT/templates"
TARGET="$PROJECT_ROOT/.cc_code"

GREEN='\033[0;32m'; YELLOW='\033[1;33m'; NC='\033[0m'
log()  { echo -e "${GREEN}[cc_code]${NC} $1"; }
warn() { echo -e "${YELLOW}[cc_code]${NC} $1"; }

# 幂等
if [ -f "$TARGET/active/Agent.md" ]; then
  warn "检测到 .cc_code/ 已存在，跳过脚手架生成。"
  exit 0
fi

log "在 $PROJECT_ROOT 创建 .cc_code/ 目录树..."
mkdir -p "$TARGET/active" "$TARGET/backup" "$TARGET/docs" \
         "$TARGET/images" "$TARGET/scripts" "$TARGET/tests"

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

# Hook 本地副本
cp "$PLUGIN_ROOT/hooks/cc_code_hook.py" "$TARGET/scripts/cc_code_hook.py"
chmod +x "$TARGET/scripts/cc_code_hook.py"

# changelog + index
cp "$TEMPLATES/changelog.md" "$TARGET/changelog.md"
cat > "$TARGET/index.md" <<EOF
# cc_code 对话索引

> 由 Hook 静默维护。按日期倒序记录会话归档。
EOF

log "脚手架完成："
log "  active/   Agent status errors project flow front gates"
log "  backup/   冷数据归档"
log "  scripts/cc_code_hook.py  Stop Hook (纯脚本)"
warn "下一步：把 .cc_code/scripts/cc_code_hook.py 接入 settings.json 的 Stop Hook。"
warn "然后让 AI Read .cc_code/active/Agent.md 进入状态机循环。"
