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

# ══════════════════════════════════════════════════════════════════════════
# 散落物迁移 —— 判定链「默认不动」
# ══════════════════════════════════════════════════════════════════════════
# 设计反转：旧版「默认搬走 + 排除两个已知文件」会误杀项目基建
#   (setup.py / manage.py / conftest.py / AGENTS.md / build.sh / logo.png ...)
# 新版「默认不动 + 只搬明确是 AI 过程垃圾的」，判定顺序（任一命中即 SKIP）：
#
#   ① 保护白名单              → SKIP
#   ② git 已追踪              → SKIP  ⭐最强判据：人 commit 过 = 不是垃圾
#   ③ 被仓库其他文件引用      → SKIP
#   ↓ 三关全过，才做正向识别
#   ④ 名字像临时物 / 过程报告 → MOVE
#   ⑤ 都不匹配                → SKIP + 记入 needs_review.md 交人工判断
# ══════════════════════════════════════════════════════════════════════════

PROTECTED='^(CLAUDE|README|AGENTS|LICENSE|LICENCE|CONTRIBUTING|SECURITY|CODE_OF_CONDUCT|CHANGELOG|HISTORY|NOTICE|AUTHORS|INSTALL|USAGE|SETUP)\.(md|txt|rst)$|^LICEN[CS]E$|^(setup|manage|conftest|wsgi|asgi|noxfile|fabfile|tasks|__init__|main|app)\.py$|^(Makefile|Dockerfile)$'
TEMP_RE='^(tmp|temp|debug|scratch|draft|wip|check|verify|demo|untitled)[-_.]|[-_.](bak|old|orig|copy)\.|~$'
REPORT_RE='(REPORT|COMPLETED|COMPLETION|HANDOFF|NEXT_STEPS|MVP|FINAL|VERIFICATION|VERIFIED|IMPLEMENTATION|REVIEW|BATCH|DELIVERY|STATUS|SUMMARY|PHASE|PROGRESS|ANALYSIS)'
ALLCAPS_MD='^[A-Z0-9_]+\.md$'
SHOT_RE='(screenshot|screen-shot|screen_shot|snap|capture|Snipaste|CleanShot|图片|截图)'

IS_GIT_REPO=0
if git -C "$PROJECT_ROOT" rev-parse --git-dir >/dev/null 2>&1; then IS_GIT_REPO=1; fi

is_git_tracked() {
  [ "$IS_GIT_REPO" -eq 1 ] || return 1
  git -C "$PROJECT_ROOT" ls-files --error-unmatch "$1" >/dev/null 2>&1
}

# 被 package.json / CI / Dockerfile / 源码引用过 = 项目基建，绝不能搬
is_referenced() {
  local base="$1"
  grep -rlF "$base" "$PROJECT_ROOT" \
    --exclude-dir=.git --exclude-dir=node_modules --exclude-dir=.cc_code \
    --exclude-dir=dist --exclude-dir=build --exclude-dir=.next \
    --exclude-dir=venv --exclude-dir=.venv --exclude-dir=__pycache__ \
    --include='package.json' --include='*.json' --include='*.yml' --include='*.yaml' \
    --include='*.toml' --include='*.cfg' --include='*.ini' --include='*.mk' \
    --include='Dockerfile*' --include='Makefile' --include='*.sh' --include='*.py' \
    --include='*.ts' --include='*.tsx' --include='*.js' --include='*.jsx' \
    --exclude="$base" >/dev/null 2>&1
}

# 输出: SKIP | REPORTS | DOCS | IMAGES | SCRIPTS | REVIEW
decide() {
  local base="$1" ext="$2" temp=0
  if [[ "$base" =~ $PROTECTED ]]; then echo SKIP; return; fi
  if is_git_tracked "$base";     then echo SKIP; return; fi
  if is_referenced  "$base";     then echo SKIP; return; fi

  if [[ "$base" =~ $TEMP_RE ]]; then temp=1; fi

  case "$ext" in
    md)
      if [[ "$base" =~ $REPORT_RE ]];  then echo REPORTS; return; fi
      if [[ "$base" =~ $ALLCAPS_MD ]]; then echo REPORTS; return; fi
      if [ "$temp" -eq 1 ];            then echo DOCS;    return; fi
      ;;
    png|jpg|jpeg|gif|webp)
      if [[ "$base" =~ $SHOT_RE ]]; then echo IMAGES; return; fi
      if [ "$temp" -eq 1 ];         then echo IMAGES; return; fi
      ;;
    sh|py)
      if [ "$temp" -eq 1 ];              then echo SCRIPTS; return; fi
      if [[ "$base" =~ $REPORT_RE ]];    then echo SCRIPTS; return; fi
      ;;
  esac
  echo REVIEW
}

migrate_scattered() {
  local YM DOCS IMAGES SCRIPTS_DIR REPORTS MANIFEST REVIEW_FILE
  YM="$(date +%Y-%m)"
  DOCS="$TARGET/docs"
  IMAGES="$TARGET/images"
  SCRIPTS_DIR="$TARGET/scripts"
  REPORTS="$TARGET/backup/$YM/reports"
  MANIFEST="$TARGET/backup/$YM/migration_manifest.md"
  REVIEW_FILE="$TARGET/backup/$YM/needs_review.md"
  mkdir -p "$DOCS" "$IMAGES" "$SCRIPTS_DIR" "$REPORTS"

  local moved=0 kept=0 review=0
  local manifest_rows="" review_rows=""

  shopt -s nullglob
  for f in "$PROJECT_ROOT"/*.md "$PROJECT_ROOT"/*.png "$PROJECT_ROOT"/*.jpg \
           "$PROJECT_ROOT"/*.jpeg "$PROJECT_ROOT"/*.gif "$PROJECT_ROOT"/*.webp \
           "$PROJECT_ROOT"/*.sh "$PROJECT_ROOT"/*.py; do
    [ -f "$f" ] || continue
    local base ext verdict dest rel
    base="$(basename "$f")"
    ext="${base##*.}"
    verdict="$(decide "$base" "$ext")"
    case "$verdict" in
      REPORTS) dest="$REPORTS/$base";     rel=".cc_code/backup/$YM/reports/$base" ;;
      DOCS)    dest="$DOCS/$base";        rel=".cc_code/docs/$base" ;;
      IMAGES)  dest="$IMAGES/$base";      rel=".cc_code/images/$base" ;;
      SCRIPTS) dest="$SCRIPTS_DIR/$base"; rel=".cc_code/scripts/$base" ;;
      REVIEW)
        review=$((review + 1))
        review_rows+="| \`$base\` | 未匹配任何迁移规则 | **原地保留**，请人工判断 |"$'\n'
        continue ;;
      *)
        kept=$((kept + 1)); continue ;;
    esac
    mv "$f" "$dest"
    moved=$((moved + 1))
    manifest_rows+="| $base | $rel | $verdict |"$'\n'
  done
  shopt -u nullglob

  if [ "$moved" -gt 0 ]; then
    {
      echo "# 散落物迁移清单 ($(date +%Y-%m-%d))"
      echo ""
      echo "> 由 init.sh 自动生成。AI 分拆 legacy 时若引用了下列旧文件名，须改写为新路径。"
      echo ""
      echo "| 原文件 | 新路径 | 判定 |"
      echo "| --- | --- | --- |"
      printf '%s' "$manifest_rows"
    } > "$MANIFEST"
  fi

  if [ "$review" -gt 0 ]; then
    {
      echo "# 待人工判断清单 ($(date +%Y-%m-%d))"
      echo ""
      echo "> 这些文件未被任何迁移规则匹配，**已原地保留未动**。"
      echo "> cc-code 的判定链默认不动文件 —— 宁可漏搬，绝不误杀。"
      echo ""
      echo "| 文件 | 原因 | 处置 |"
      echo "| --- | --- | --- |"
      printf '%s' "$review_rows"
    } > "$REVIEW_FILE"
  fi

  log "迁移结果：搬走 $moved 个 / 保护 $kept 个 / 待人工判断 $review 个"
  if [ "$moved" -gt 0 ];  then log "  → 清单 backup/$YM/migration_manifest.md"; fi
  if [ "$review" -gt 0 ]; then warn "  → $review 个文件未匹配规则已原地保留，见 backup/$YM/needs_review.md"; fi
}

# ══════════════════════════════════════════════════════════════════════════
# Stop Hook —— 项目层级注册（不做全局注册，不污染其他项目）
# ══════════════════════════════════════════════════════════════════════════
install_project_hook() {
  mkdir -p "$PROJECT_ROOT/.claude" "$TARGET/scripts"
  cp "$PLUGIN_ROOT/hooks/cc_code_hook.py" "$TARGET/scripts/cc_code_hook.py"
  chmod +x "$TARGET/scripts/cc_code_hook.py"

  python3 - "$PROJECT_ROOT/.claude/settings.json" <<'PY'
import json, pathlib, sys

p = pathlib.Path(sys.argv[1])
CMD = 'python3 "$CLAUDE_PROJECT_DIR/.cc_code/scripts/cc_code_hook.py"'
cfg = {}

if p.exists():
    raw = p.read_text(encoding="utf-8").strip()
    if raw:
        try:
            cfg = json.loads(raw)
        except json.JSONDecodeError as e:
            print(f"[cc-code] settings.json 解析失败({e}) — 已跳过 hook 注册，未修改任何内容")
            sys.exit(0)

hooks = cfg.setdefault("hooks", {})
stop = hooks.setdefault("Stop", [])
if not isinstance(stop, list):
    print("[cc-code] hooks.Stop 结构异常 — 已跳过 hook 注册，未修改任何内容")
    sys.exit(0)

already = any(
    "cc_code_hook.py" in h.get("command", "")
    for grp in stop if isinstance(grp, dict)
    for h in grp.get("hooks", []) if isinstance(h, dict)
)
if already:
    print("[cc-code] Stop hook 已注册，跳过")
    sys.exit(0)

stop.append({
    "matcher": "*",
    "hooks": [{
        "type": "command",
        "command": CMD,
        "description": "cc-code 静默结算: errors.md 冷切片 (纯脚本零 LLM)",
    }],
})
p.write_text(json.dumps(cfg, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
print("[cc-code] 已在 .claude/settings.json 注册项目级 Stop hook")
PY
}

# ══════════════════════════════════════════════════════════════════════════
# .gitignore 联动：冷归档与 hook 日志不入库
# ══════════════════════════════════════════════════════════════════════════
update_gitignore() {
  local GI="$PROJECT_ROOT/.gitignore"
  touch "$GI"
  if grep -qF '.cc_code/backup/' "$GI"; then
    return 0
  fi
  {
    echo ""
    echo "# cc-code 冷归档（过程报告 / 历史快照）与 hook 日志不入库"
    echo ".cc_code/backup/"
    echo ".cc_code/scripts/hook_error.log"
  } >> "$GI"
  log "已追加 .cc_code/backup/ 到 .gitignore"
}

# ══════════════════════════════════════════════════════════════════════════
# 主流程
# ══════════════════════════════════════════════════════════════════════════

# 幂等：已就绪则只做迁移 + 重装 hook（插件升级后重跑可刷新 hook 副本）
if [ -f "$TARGET/active/Agent.md" ]; then
  warn "检测到 .cc_code/ 已存在，跳过脚手架生成。"
  install_project_hook
  migrate_scattered
  update_gitignore
  exit 0
fi

log "在 $PROJECT_ROOT 创建 .cc_code/ 目录树..."
mkdir -p "$TARGET/active" "$TARGET/backup" "$TARGET/docs/plans" "$TARGET/docs/qa" \
         "$TARGET/images" "$TARGET/scripts"

# 热区骨架（9 个 active 文件，按 L0~L5 分层）
cp "$TEMPLATES/Agent.md"      "$TARGET/active/Agent.md"      # L0 控制
cp "$TEMPLATES/status.md"     "$TARGET/active/status.md"     # L0 控制
cp "$TEMPLATES/prd.md"        "$TARGET/active/prd.md"        # L1 意图
cp "$TEMPLATES/ux.md"         "$TARGET/active/ux.md"         # L2 表现
cp "$TEMPLATES/project.md"    "$TARGET/active/project.md"    # L3 实现
cp "$TEMPLATES/data.md"       "$TARGET/active/data.md"       # L3 实现
cp "$TEMPLATES/api.md"        "$TARGET/active/api.md"        # L3 实现
cp "$TEMPLATES/gates.md"      "$TARGET/active/gates.md"      # L4 验收
cp "$TEMPLATES/errors.md"     "$TARGET/active/errors.md"     # L5 教训

# 冷区占位
mkdir -p "$TARGET/backup/$(date +%Y-%m)"
touch "$TARGET/backup/$(date +%Y-%m)/errors_archive.md"

# 项目级 Stop hook（脚本副本 + .claude/settings.json 注册）
install_project_hook

# 根目录 CLAUDE.md 入口引导（新/旧项目统一生成）
#   - 旧项目：先备份 legacy → backup/YYYY-MM/CLAUDE.md.legacy，再覆盖
#   - 新项目：直接生成
#   注：旧 CLAUDE.md 的内容分拆（理解力活）由 AI 在 /cc-code:init 对话内完成，
#       读取 backup 里的 legacy 按 init 的映射表归并到 active/ 各文件。
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
log "  active/   L0 Agent status │ L1 prd │ L2 ux │ L3 project data api │ L4 gates │ L5 errors"
log "  docs/plans/  阶段方案（Architect 产出，Dev 按 phase 读）"
log "  docs/qa/     全量验收报告（whole-qa 产出）"
log "  images/ scripts/  截图归档 + Stop hook 脚本"
log "  backup/   冷数据归档（旧项目含 CLAUDE.md.legacy + migration_manifest.md）"
log "  根目录 CLAUDE.md  工作流入口引导"
log "  .claude/settings.json  项目级 Stop hook 已注册（不做全局注册）"
warn "让 AI Read 根目录 CLAUDE.md → 进入状态机循环。"
