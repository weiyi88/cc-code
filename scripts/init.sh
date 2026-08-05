#!/usr/bin/env bash
# cc-code Plugin - 项目场域脚手架
# 用法: bash init.sh [<project_root>]
#       bash init.sh --relocate <相对路径...>   冗余归位（mv 进 backup/superseded/，零删除）
#       bash init.sh --stamp                    盖场域版本戳
set -euo pipefail

# 参数解析：首参以 -- 开头即子命令（项目根取 cwd），否则视为项目根
SUBCMD=""
if [[ "${1:-}" == --* ]]; then
  SUBCMD="$1"; shift
  PROJECT_ROOT="$(pwd)"
else
  PROJECT_ROOT="${1:-$(pwd)}"
fi

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PLUGIN_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
TEMPLATES="$PLUGIN_ROOT/templates"
TARGET="$PROJECT_ROOT/.cc_code"
STAMP="$TARGET/.cc_code_version"
PLUGIN_VERSION="$(sed -n 's/.*"version"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p' \
                  "$PLUGIN_ROOT/.claude-plugin/plugin.json" | head -1)"
PLUGIN_VERSION="${PLUGIN_VERSION:-unknown}"

# 规范 8 文件（L0~L4），升级清点的分母
CANON="Agent.md status.md prd.md ux.md project.md data.md api.md gates.md"

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
# .gitignore 联动：冷归档不入库
# ══════════════════════════════════════════════════════════════════════════
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

# ══════════════════════════════════════════════════════════════════════════
# 版本戳 —— 场域形态的版本坐标，决定是否需要升级迁移
# ══════════════════════════════════════════════════════════════════════════
stamp_version() {
  printf '%s\n' "$PLUGIN_VERSION" > "$STAMP"
  log "场域版本戳 → $PLUGIN_VERSION"
}

read_stamp() {
  [ -f "$STAMP" ] && head -1 "$STAMP" | tr -d '[:space:]' || echo ""
}

# ══════════════════════════════════════════════════════════════════════════
# 升级 D1 —— 归档快照（只读后悔药）
# ⛔ 全程零 rm：只 cp，原位一个字不动，active/ 全程可用
# ══════════════════════════════════════════════════════════════════════════
archive_legacy() {
  local YM OLD SNAP
  YM="$(date +%Y-%m)"
  OLD="${1:-unstamped}"
  SNAP="$TARGET/backup/$YM/pre-upgrade-$OLD"

  if [ -d "$SNAP" ]; then
    SNAP="$SNAP-$(date +%H%M%S)"
  fi
  mkdir -p "$SNAP"

  # active/ 全量 + .cc_code 根层散落 md（规范外冗余的主要藏身处）
  [ -d "$TARGET/active" ] && cp -R "$TARGET/active" "$SNAP/active"
  shopt -s nullglob
  for f in "$TARGET"/*.md; do cp "$f" "$SNAP/"; done
  shopt -u nullglob

  log "D1 归档快照 → backup/$YM/$(basename "$SNAP")/（原位未动）"
}

# ══════════════════════════════════════════════════════════════════════════
# 升级 D2 —— 清点（四类差异，落 upgrade_audit.md 交 AI 迁移）
# ══════════════════════════════════════════════════════════════════════════
audit_layout() {
  local YM AUDIT rows_missing rows_stray rows_extra rows_ok f base
  YM="$(date +%Y-%m)"
  AUDIT="$TARGET/backup/$YM/upgrade_audit.md"
  rows_missing=""; rows_stray=""; rows_extra=""; rows_ok=""
  local _old; _old="$(read_stamp)"

  # ① 规范位在否
  for base in $CANON; do
    if [ -f "$TARGET/active/$base" ]; then
      rows_ok+="| \`active/$base\` | 规范位就位 | 校验内容是否缺规范段落 |"$'\n'
    else
      rows_missing+="| \`active/$base\` | **规范位缺失** | 找同层等价物迁入，无则用模板骨架 |"$'\n'
    fi
  done

  # ② .cc_code 根层散落 md = 位置偏离
  shopt -s nullglob
  for f in "$TARGET"/*.md; do
    base="$(basename "$f")"
    if printf ' %s ' $CANON | grep -qF " $base "; then
      rows_stray+="| \`$base\` | **位置偏离**（应在 active/） | 迁入 \`active/$base\` |"$'\n'
    else
      rows_extra+="| \`$base\` | **规范外** | 按层判据归并，兜底 project.md |"$'\n'
    fi
  done

  # ③ active/ 里的规范外文件 = 拆分偏离或已废除
  for f in "$TARGET"/active/*.md; do
    base="$(basename "$f")"
    printf ' %s ' $CANON | grep -qF " $base " && continue
    rows_extra+="| \`active/$base\` | **规范外**（拆分偏离 / 已废除） | 按层判据归并到规范文件 |"$'\n'
  done
  shopt -u nullglob

  {
    echo "# 升级清点报告 ($(date +%Y-%m-%d))"
    echo ""
    echo "> 由 init.sh 自动生成（机械清点）。**内容迁移是理解力活，由 AI 按 /cc-code:init 第 2C 步执行。**"
    echo "> ⛔ 本次升级全程零删除：迁移校验通过后，旧物 \`mv\` 进 \`backup/$YM/superseded/\`。"
    echo ""
    echo "旧形态：\`${_old:-无版本戳}\`  →  目标：\`$PLUGIN_VERSION\`"
    echo ""
    echo "## ① 规范位缺失"; echo ""
    echo "| 规范文件 | 判定 | 处置 |"; echo "| --- | --- | --- |"
    [ -n "$rows_missing" ] && printf '%s' "$rows_missing" || echo "| — | 无 | — |"
    echo ""
    echo "## ② 位置偏离"; echo ""
    echo "| 文件 | 判定 | 处置 |"; echo "| --- | --- | --- |"
    [ -n "$rows_stray" ] && printf '%s' "$rows_stray" || echo "| — | 无 | — |"
    echo ""
    echo "## ③ 规范外多余（含拆分偏离 / 已废除）"; echo ""
    echo "| 文件 | 判定 | 处置 |"; echo "| --- | --- | --- |"
    [ -n "$rows_extra" ] && printf '%s' "$rows_extra" || echo "| — | 无 | — |"
    echo ""
    echo "## ④ 规范位已就位（仍需 AI 校验缺失段落）"; echo ""
    echo "| 文件 | 判定 | 处置 |"; echo "| --- | --- | --- |"
    [ -n "$rows_ok" ] && printf '%s' "$rows_ok" || echo "| — | 无 | — |"
  } > "$AUDIT"

  log "D2 清点完成 → backup/$YM/upgrade_audit.md"
}

# ══════════════════════════════════════════════════════════════════════════
# 升级 D5 —— 冗余归位（AI 校验门通过后才调用）
# ⛔ 零 rm：mv 进 backup/YYYY-MM/superseded/，原位清空但内容永存
# 用法: relocate_superseded <相对 .cc_code 的路径> [更多...]
# ══════════════════════════════════════════════════════════════════════════
relocate_superseded() {
  local YM SUP rel src dest moved=0
  YM="$(date +%Y-%m)"
  SUP="$TARGET/backup/$YM/superseded"
  mkdir -p "$SUP"

  for rel in "$@"; do
    src="$TARGET/$rel"
    [ -e "$src" ] || { warn "  跳过（不存在）：$rel"; continue; }
    # 规范 8 文件本体绝不归位
    if printf ' %s ' $CANON | grep -qF " $(basename "$rel") " && [ "${rel#active/}" != "$rel" ]; then
      warn "  ⛔ 拒绝：$rel 是规范位文件，绝不归位"; continue
    fi
    dest="$SUP/$(echo "$rel" | tr '/' '_')"
    [ -e "$dest" ] && dest="$dest.$(date +%H%M%S)"
    mv "$src" "$dest"
    moved=$((moved + 1))
    log "  归位 $rel → backup/$YM/superseded/$(basename "$dest")"
  done
  log "D5 冗余归位完成：$moved 个（零删除，内容全在 backup）"
}

# ══════════════════════════════════════════════════════════════════════════
# 主流程
# ══════════════════════════════════════════════════════════════════════════

# ══════════════════════════════════════════════════════════════════════════
# 子命令入口（供 AI 在升级 D6 / D7 阶段调用）
#   bash init.sh --relocate <相对路径...>   冗余归位（mv 进 superseded/，零删除）
#   bash init.sh --stamp                    盖版本戳（迁移+校验全通过才盖）
# ══════════════════════════════════════════════════════════════════════════
case "$SUBCMD" in
  --relocate)
    [ -d "$TARGET" ] || { warn "无 .cc_code/，无处归位"; exit 1; }
    [ "$#" -gt 0 ]   || { warn "用法: init.sh --relocate <相对路径...>"; exit 1; }
    relocate_superseded "$@"
    exit 0 ;;
  --stamp)
    [ -d "$TARGET" ] || { warn "无 .cc_code/，无处盖戳"; exit 1; }
    stamp_version
    exit 0 ;;
esac

# ══════════════════════════════════════════════════════════════════════════
# 三轨闸门
#   Track B 新建   —— 无 active/Agent.md
#   Track C 已最新 —— 版本戳 == 插件版本，只搬散落物
#   Track D 升级   —— 版本戳缺失/更旧，走 D1 归档 → D2 清点 → 交 AI 迁移
# ══════════════════════════════════════════════════════════════════════════
if [ -f "$TARGET/active/Agent.md" ]; then
  OLD_STAMP="$(read_stamp)"

  if [ "$OLD_STAMP" = "$PLUGIN_VERSION" ]; then
    warn "Track C：场域已是 ${PLUGIN_VERSION}，跳过脚手架，仅执行散落物迁移。"
    migrate_scattered
    update_gitignore
    exit 0
  fi

  # ── Track D 升级迁移 ────────────────────────────────────────────────
  warn "Track D 升级：场域形态 [${OLD_STAMP:-无版本戳}] → 插件 [$PLUGIN_VERSION]"
  warn "⛔ 全程零删除：只 cp 快照 + mv 归位，原位内容在校验通过前一个字不动。"

  archive_legacy "${OLD_STAMP:-unstamped}"
  audit_layout
  migrate_scattered
  update_gitignore

  YM="$(date +%Y-%m)"
  warn ""
  warn "══════════ 脚手架侧完成，以下是 AI 的活 ══════════"
  warn "AI 必须按 /cc-code:init 第 2C 步「升级迁移协议」继续："
  warn "  D3 迁移   读 backup/$YM/upgrade_audit.md，把内容搬到规范位（一段不丢）"
  warn "  D4 补层   按 templates/Agent.md 补齐缺失规范段，保留项目自定义权限"
  warn "  D5 校验门 逐节核对，未全命中即停手报清单，禁止归位"
  warn "  D6 归位   校验通过 → bash init.sh --relocate <路径...> 把旧物 mv 进 superseded/"
  warn "  D7 盖戳   bash init.sh --stamp"
  warn "⛔ 版本戳未盖前，下次 init 仍判为待升级 —— 迁移没做完不会被误认为完成。"
  exit 0
fi

log "在 $PROJECT_ROOT 创建 .cc_code/ 目录树..."
mkdir -p "$TARGET/active" "$TARGET/backup" "$TARGET/docs/plans" "$TARGET/docs/qa" \
         "$TARGET/images" "$TARGET/scripts"

# 热区骨架（8 个 active 文件，按 L0~L4 分层）
cp "$TEMPLATES/Agent.md"      "$TARGET/active/Agent.md"      # L0 控制
cp "$TEMPLATES/status.md"     "$TARGET/active/status.md"     # L0 控制
cp "$TEMPLATES/prd.md"        "$TARGET/active/prd.md"        # L1 意图
cp "$TEMPLATES/ux.md"         "$TARGET/active/ux.md"         # L2 表现
cp "$TEMPLATES/project.md"    "$TARGET/active/project.md"    # L3 实现
cp "$TEMPLATES/data.md"       "$TARGET/active/data.md"       # L3 实现
cp "$TEMPLATES/api.md"        "$TARGET/active/api.md"        # L3 实现
cp "$TEMPLATES/gates.md"      "$TARGET/active/gates.md"      # L4 验收

# 冷区占位
mkdir -p "$TARGET/backup/$(date +%Y-%m)"

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
stamp_version   # ⭐新建即盖戳，否则下次 init 会误判为待升级

log "脚手架完成："
log "  active/   L0 Agent status │ L1 prd │ L2 ux │ L3 project data api │ L4 gates"
log "  docs/plans/  阶段方案（Architect 产出，Dev 按 phase 读）"
log "  docs/qa/     全量验收报告（whole-qa 产出）"
log "  images/ scripts/  截图归档 + 散落脚本"
log "  backup/   冷数据归档（旧项目含 CLAUDE.md.legacy + migration_manifest.md）"
log "  根目录 CLAUDE.md  工作流入口引导"
warn "让 AI Read 根目录 CLAUDE.md → 进入状态机循环。"
