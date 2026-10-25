#!/usr/bin/env bash
# cc-code Stop hook · curator 保底提醒（纯 bash 内建，不起子进程、不调 AI、不联网）
# 触发: .cc_code/active/gates.md 修改时间 同时新于 log/started（curator 开工时间戳）和 log/reminded（上次提醒记号）
# 动作: 输出非错误的 additionalContext，提醒主会话后台补派 curator，并刷新 reminded（同一次改动最多提醒一次）；其余一律静默退出
# 铁律: 永远 exit 0（hook 出错不能卡住主会话）；stop_hook_active 为 true 立刻退出防循环
# 规则出处: templates/Agent.md §四 第 7 条；时间戳约定出处: agents/curator.md 第三节

ROOT="${CLAUDE_PROJECT_DIR:-$PWD}"
[ -d "$ROOT/.cc_code" ] || exit 0

# 读 hook 输入（内建 read，不 fork）；只为判 stop_hook_active
INPUT=""
IFS= read -r -d '' INPUT || true
[[ "$INPUT" =~ \"stop_hook_active\"[[:space:]]*:[[:space:]]*true ]] && exit 0

GATES="$ROOT/.cc_code/active/gates.md"
STARTED="$ROOT/.cc_code/references/log/started"
REMINDED="$ROOT/.cc_code/references/log/reminded"
# 无 gates 或无时间戳文件（未经 1.10.0 init）：无从比较，静默
[ -f "$GATES" ] && [ -f "$STARTED" ] || exit 0
[ "$GATES" -nt "$STARTED" ] || exit 0
# 同一次 gates 改动最多提醒一次：已提醒过（reminded 比 gates 新）则静默
if [ -f "$REMINDED" ] && [ ! "$GATES" -nt "$REMINDED" ]; then exit 0; fi
# 记号写不进去就静默退出：宁可漏提醒，也不每次 Stop 都重复提醒
{ : > "$REMINDED"; } 2>/dev/null || exit 0

printf '%s' '{"hookSpecificOutput":{"hookEventName":"Stop","additionalContext":"cc-code 保底提醒（仅此一次）：仅当执行器（agent-mvp / agent-feature / agent-debug / just-do-it）刚刚结算——全部通过，或 3 轮仍未通过已交人——且尚未派过 curator 时，请立即在后台补派一次（规则见 Agent.md §四 第 7 条）。其余情形一律忽略本提醒，包括尚未结算、已派过、以及 agent-whole-qa / plan-debug / deploy 引起的验收记录变化；忽略时不要输出任何文字，也不要向主人提及。"}}'
exit 0
