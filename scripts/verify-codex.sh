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

# 源已删除的旧 toml（快照里有、重生成后消失）单独点名 —— sync 负责清, 这里只报
if [[ -d "$SNAP/assets__codex__agents" ]]; then
  for t in "$SNAP"/assets__codex__agents/*.toml; do
    [[ -f "$t" ]] || continue
    if [[ ! -f "$PLUGIN_ROOT/assets/codex/agents/$(basename "$t")" ]]; then
      echo -e "${RED}  ✗ 过期 toml: $(basename "$t") —— 对应 agents/*.md 已删, 已由 sync 清除, 请再跑一次 verify 确认${NC}"
    fi
  done
fi

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

# ══════════════════════════════════════════════════════════════════════════
# 5. 闸门覆盖：除协议体外，每个命令都要有显式调用闸门 + 对应 Codex 闸门配置
#    - 显式调用闸门 = SKILL.md frontmatter 的 disable-model-invocation: true
#    - Codex 闸门配置 = skills/<name>/agents/openai.yaml（sync 生成，内容为
#      allow_implicit_invocation: false）
#    - 协议体 cc-code 是自动加载的运行时协议，按设计不生成闸门（codex 默认
#      implicit=true 即对齐 Claude 侧行为），登记在 GATE_EXEMPT，唯一豁免。
#    缺一即 FAIL：漏写闸门会被 Codex 隐式调用，正文里写「只能手动触发」零作用。
# ══════════════════════════════════════════════════════════════════════════
GATE_EXEMPT="cc-code"
gate_fail=0
gate_n=0
for skill_md in "$PLUGIN_ROOT"/skills/*/SKILL.md; do
  [[ -f "$skill_md" ]] || continue
  name="$(basename "$(dirname "$skill_md")")"
  case " $GATE_EXEMPT " in *" $name "*) continue ;; esac
  gate_n=$((gate_n + 1))

  front="$(awk 'NR==1 && /^---$/{f=1; next} f && /^---$/{exit} f {print}' "$skill_md")"
  if ! printf '%s\n' "$front" | grep -qE '^disable-model-invocation:[[:space:]]*true[[:space:]]*$'; then
    echo -e "${RED}  ✗ 命令 $name 缺显式调用闸门（frontmatter 缺 disable-model-invocation: true）${NC}"
    gate_fail=1
    continue
  fi
  yaml="$PLUGIN_ROOT/skills/$name/agents/openai.yaml"
  if [[ ! -f "$yaml" ]]; then
    echo -e "${RED}  ✗ 命令 $name 缺 Codex 闸门配置（skills/$name/agents/openai.yaml）—— 重跑 scripts/sync-codex.sh${NC}"
    gate_fail=1
  elif ! grep -qE '^[[:space:]]*allow_implicit_invocation:[[:space:]]*false[[:space:]]*$' "$yaml"; then
    echo -e "${RED}  ✗ 命令 $name 的 Codex 闸门配置未关闭隐式调用 —— 重跑 scripts/sync-codex.sh${NC}"
    gate_fail=1
  fi
done
if [[ "$gate_fail" -eq 0 ]]; then
  echo -e "${GREEN}  ✓ 闸门覆盖完整（$gate_n 个命令均有显式闸门 + Codex 配置；协议体 cc-code 豁免）${NC}"
else
  FAIL=1
fi

[[ "$FAIL" -eq 0 ]] && echo -e "${GREEN}[verify-codex] 全过${NC}" \
                    || echo -e "${RED}[verify-codex] 有漂移, 见 ✗ 清单${NC}"
exit "$FAIL"
