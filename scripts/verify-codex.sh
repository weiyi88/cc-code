#!/usr/bin/env bash
# cc-code Plugin — Codex 侧漂移校验器（verify）
# 用法: bash verify-codex.sh        全过 exit 0 / 有漂移 exit 1
#
# 原理(零映射副本): 快照磁盘生成物 → 重跑 sync-codex.sh 重生成 → 逐字节 diff。
#   映射逻辑只活在 sync 一处(SSOT); 本脚本只回答一个问题 —— 磁盘上的生成物
#   是否等于「唯一源此刻重生成」的结果。手改生成物 / 改源没跑 sync, 都会被抓出。
set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PLUGIN_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

RED='\033[0;31m'; GREEN='\033[0;32m'; NC='\033[0m'
FAIL=0

echo "[verify-codex] 快照 → 重生成 → diff"

SNAP="$(mktemp -d)"
trap 'rm -rf "$SNAP"' EXIT

# ══════════════════════════════════════════════════════════════════════════
# 1. 快照磁盘现状（软链按实体拷, 保持内容比对）
# ══════════════════════════════════════════════════════════════════════════
for path in ".codex-plugin/plugin.json" ".agents/plugins/marketplace.json" \
            "skills" "assets/codex/agents"; do
  src="$PLUGIN_ROOT/$path"
  [[ -e "$src" ]] && cp -RL "$src" "$SNAP/${path//\//__}" || true
done

# ══════════════════════════════════════════════════════════════════════════
# 2. 重跑 sync（唯一映射逻辑原地重生成）—— 输出吞掉, 只留 diff 结论
# ══════════════════════════════════════════════════════════════════════════
if ! bash "$SCRIPT_DIR/sync-codex.sh" >/dev/null 2>&1; then
  echo -e "${RED}  ✗ sync-codex.sh 执行失败${NC}"; exit 1
fi

# ══════════════════════════════════════════════════════════════════════════
# 3. 逐对象 diff: 快照(曾是什么) vs 磁盘(该是什么)
# ══════════════════════════════════════════════════════════════════════════
declare -a PAIRS=(
  ".codex-plugin/plugin.json"
  ".agents/plugins/marketplace.json"
  "assets/codex/agents"
)
n_yaml=$(find "$PLUGIN_ROOT/skills" -path "*/agents/openai.yaml" | wc -l | tr -d ' ')
n_toml=$(find "$PLUGIN_ROOT/assets/codex/agents" -name "*.toml" 2>/dev/null | wc -l | tr -d ' ')
echo "  生成物在盘: openai.yaml ×$n_yaml  agents toml ×$n_toml"

for pair in "${PAIRS[@]}"; do
  name="${pair//\//__}"
  if diff -r "$SNAP/$name" "$PLUGIN_ROOT/$pair" >/dev/null 2>&1; then
    echo -e "${GREEN}  ✓ $pair 与唯一源一致${NC}"
  else
    echo -e "${RED}  ✗ $pair 漂移 —— 重跑 scripts/sync-codex.sh（生成物禁手改）${NC}"
    FAIL=1
  fi
done

# skills 下的 openai.yaml 散点单独扫（快照打平在 SNAP/skills）
yaml_drift=0
while IFS= read -r f; do
  rel="${f#"$PLUGIN_ROOT/"}"
  snap="$SNAP/skills/${rel#skills/}"
  if ! diff -q "$snap" "$f" >/dev/null 2>&1; then
    echo -e "${RED}  ✗ $rel 漂移 —— 重跑 scripts/sync-codex.sh${NC}"
    yaml_drift=1
  fi
done < <(find "$PLUGIN_ROOT/skills" -path "*/agents/openai.yaml")
[[ "$yaml_drift" -eq 0 ]] && echo -e "${GREEN}  ✓ openai.yaml ×$n_yaml 与唯一源一致${NC}"
[[ "$yaml_drift" -eq 1 ]] && FAIL=1

# ══════════════════════════════════════════════════════════════════════════
# 4. AGENTS.md 软链形态 + skills 本体存在性
# ══════════════════════════════════════════════════════════════════════════
if [[ "$(readlink "$PLUGIN_ROOT/templates/AGENTS.md" 2>/dev/null || true)" == "CLAUDE.md" ]]; then
  echo -e "${GREEN}  ✓ templates/AGENTS.md → CLAUDE.md 软链正确${NC}"
else
  echo -e "${RED}  ✗ templates/AGENTS.md 缺失或不是 → CLAUDE.md 软链${NC}"; FAIL=1
fi

n_skills=$(find "$PLUGIN_ROOT/skills" -name SKILL.md -mindepth 2 -maxdepth 2 | wc -l | tr -d ' ')
if [[ "$n_skills" -ge 1 ]]; then
  echo -e "${GREEN}  ✓ skills 唯一源就位（$n_skills 个 SKILL.md）${NC}"
else
  echo -e "${RED}  ✗ skills/ 下没有 SKILL.md —— 双端共用本体断供${NC}"; FAIL=1
fi

[[ "$FAIL" -eq 0 ]] && echo -e "${GREEN}[verify-codex] 全过${NC}" \
                    || echo -e "${RED}[verify-codex] 有漂移, 见 ✗ 清单${NC}"
exit "$FAIL"
