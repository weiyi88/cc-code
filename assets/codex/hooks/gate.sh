#!/bin/bash
# cc-code plan 护栏（codex PreToolUse hook · 零依赖）
# 触发: .cc_code/.runtime/plan-lock 存在 → 拦 Edit / Write / apply_patch
# 放行: plan-lock 不存在 → 静默退出(⛔ 不可输出 allow —— codex 会判 unsupported)
# 出关: 向主人确认落盘清单后 rm .cc_code/.runtime/plan-lock(走 Bash 不受拦, 属正常出关动作)
input=$(cat)
cwd=$(printf '%s' "$input" | sed -n 's/.*"cwd":"\([^"]*\)".*/\1/p')
[ -z "$cwd" ] && exit 0
[ -f "$cwd/.cc_code/.runtime/plan-lock" ] || exit 0
printf '%s' '{"hookSpecificOutput":{"hookEventName":"PreToolUse","permissionDecision":"deny","permissionDecisionReason":"cc-code plan 护栏: 当前处于 plan 模式, 禁止写盘。出关流程: 向主人确认落盘清单 → rm .cc_code/.runtime/plan-lock → 再落盘。"}}'
exit 0
