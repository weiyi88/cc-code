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

# ──────────────────────────────────────────────────────────────────────────
# 散落物迁移：把根目录的过程产物(md/png/脚本)迁入 .cc_code/，让根目录保持干净。
#   - 规格文档 / 指南文档 → .cc_code/docs/
#   - 过程报告             → .cc_code/backup/YYYY-MM/reports/
#   - 截图 png             → .cc_code/images/
#   - 散落脚本 .sh/.py     → .cc_code/scripts/   (不碰 .js/.ts/.mjs，避免误伤 Next.js config)
# 保留根目录：CLAUDE.md、README.md、配置文件、源码目录。
# 同时写 migration_manifest.md 记录原路径→新路径映射，供 AI 分拆时改引用。
# ──────────────────────────────────────────────────────────────────────────
migrate_scattered() {
  local YM DOCS IMAGES SCRIPTS_DIR REPORTS MANIFEST
  YM="$(date +%Y-%m)"
  DOCS="$TARGET/docs"
  IMAGES="$TARGET/images"
  SCRIPTS_DIR="$TARGET/scripts"
  REPORTS="$TARGET/backup/$YM/reports"
  MANIFEST="$TARGET/backup/$YM/migration_manifest.md"
  mkdir -p "$DOCS" "$IMAGES" "$SCRIPTS_DIR" "$REPORTS"

  {
    echo "# 散落物迁移清单 ($(date +%Y-%m-%d))"
    echo ""
    echo "> 由 init.sh 自动生成。AI 在第 2A 步分拆 legacy 时，若引用了下列旧文件名，"
    echo "> 须改写为新路径（相对项目根）。"
    echo ""
    echo "| 原路径 | 新路径 | 类别 |"
    echo "| --- | --- | --- |"
  } > "$MANIFEST"

  local moved=0
  # 过程报告关键词（文件名含任一即归 backup/reports/）
  local report_re='(REPORT|COMPLETED|HANDOFF|NEXT_STEPS|MVP|FINAL|VERIFICATION|IMPLEMENTATION|REVIEW|BATCH|DELIVERY|STATUS)'

  shopt -s nullglob
  # 1) 根目录 .md（排除 CLAUDE.md / README.md）
  for f in "$PROJECT_ROOT"/*.md; do
    local base dest
    base="$(basename "$f")"
    [ "$base" = "CLAUDE.md" ] && continue
    [ "$base" = "README.md" ] && continue
    if [[ "$base" =~ $report_re ]]; then
      dest="$REPORTS/$base"
      echo "| $base | .cc_code/backup/$YM/reports/$base | 过程报告 |" >> "$MANIFEST"
    else
      dest="$DOCS/$base"
      echo "| $base | .cc_code/docs/$base | 规格文档 |" >> "$MANIFEST"
    fi
    mv "$f" "$dest"
    moved=$((moved + 1))
  done

  # 2) 截图 png
  for f in "$PROJECT_ROOT"/*.png; do
    local base
    base="$(basename "$f")"
    mv "$f" "$IMAGES/$base"
    echo "| $base | .cc_code/images/$base | 截图 |" >> "$MANIFEST"
    moved=$((moved + 1))
  done

  # 3) 散落脚本 .sh / .py
  for ext in sh py; do
    for f in "$PROJECT_ROOT"/*."$ext"; do
      local base
      base="$(basename "$f")"
      mv "$f" "$SCRIPTS_DIR/$base"
      echo "| $base | .cc_code/scripts/$base | 脚本 |" >> "$MANIFEST"
      moved=$((moved + 1))
    done
  done
  shopt -u nullglob

  if [ "$moved" -gt 0 ]; then
    log "迁移 $moved 个散落文件到 .cc_code/（清单见 backup/$YM/migration_manifest.md）"
  else
    log "未发现散落文件，跳过迁移。"
  fi
}

# ──────────────────────────────────────────────────────────────────────────
# .gitignore 联动：冷归档 backup/ 不入库（用了 cc-code 就不回头）
# ──────────────────────────────────────────────────────────────────────────
update_gitignore() {
  local GI="$PROJECT_ROOT/.gitignore"
  touch "$GI"
  if grep -qF '.cc_code/backup/' "$GI"; then
    return 0
  fi
  {
    echo ""
    echo "# cc-code 冷归档（过程报告 / 历史快照）不入库"
    echo ".cc_code/backup/"
  } >> "$GI"
  log "已追加 .cc_code/backup/ 到 .gitignore"
}

# ──────────────────────────────────────────────────────────────────────────
# 主流程
# ──────────────────────────────────────────────────────────────────────────

# 幂等：已就绪则只做迁移（迁移本身也幂等：根目录无散落文件时 moved=0）
if [ -f "$TARGET/active/Agent.md" ]; then
  warn "检测到 .cc_code/ 已存在，跳过脚手架生成，仅执行散落物迁移。"
  migrate_scattered
  update_gitignore
  exit 0
fi

log "在 $PROJECT_ROOT 创建 .cc_code/ 目录树..."
mkdir -p "$TARGET/active" "$TARGET/backup" "$TARGET/docs/plans" \
         "$TARGET/images" "$TARGET/scripts" "$TARGET/tests"

# 热区骨架（8 个 active 文件）
cp "$TEMPLATES/Agent.md"      "$TARGET/active/Agent.md"
cp "$TEMPLATES/status.md"     "$TARGET/active/status.md"
cp "$TEMPLATES/errors.md"     "$TARGET/active/errors.md"
cp "$TEMPLATES/project.md"    "$TARGET/active/project.md"
cp "$TEMPLATES/data.md"       "$TARGET/active/data.md"
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

# 散落物迁移 + .gitignore 联动
migrate_scattered
update_gitignore

log "脚手架完成："
log "  active/   Agent status errors project data flow front gates"
log "  docs/plans/  阶段方案（prd-plan 产出，Dev 按 phase 读）"
log "  images/ scripts/  截图与散落脚本归档"
log "  backup/   冷数据归档（旧项目含 CLAUDE.md.legacy + migration_manifest.md）"
log "  根目录 CLAUDE.md  工作流入口引导"
warn "Hook 由 cc-code 插件自动注册（需已 /plugin install cc-code）。"
warn "让 AI Read 根目录 CLAUDE.md → 进入状态机循环。"
