#!/usr/bin/env bash
# organize: skill 発火漏れを塞ぐ soft nudge。
#
# skill は signal 駆動の discoverable な仕組みで、ツール経路を塞ぐ gate ではない。
# 会話の流れで作業に入ると意図フレーズが出ず、最短経路の git commit / gh issue create /
# gh pr create を直接叩いて create-issue / commit / create-pr skill が発火しないことがある。
# この hook は直接経路を検出した瞬間に、対応 skill の規律をコンテキストへ再浮上させる。
#
# ブロックはしない（permissionDecision は常に allow）。全ディレクトリ有効な plugin でも
# 無害であり、skill 実行中の redundant 発火でも no-op で済むよう「規律に沿っているか」基調にする。
set -euo pipefail

input=$(cat)
command=$(printf '%s' "$input" | jq -r '.tool_input.command // empty')

nudge=""
case "$command" in
  *"git commit"*)
    nudge="この commit は commit skill の規律（Conventional Commits / 1 PR = 1 squashed commit 粒度 / handoff.md は除外 / branch 判断）に沿っていますか。逸れていれば commit skill を通してください。"
    ;;
  *"gh issue create"*)
    nudge="この起票は create-issue skill のテンプレート（背景・要件・受け入れ基準・工数見積）を満たしていますか。薄ければ create-issue skill を通してください。"
    ;;
  *"gh pr create"*)
    nudge="この PR 作成は create-pr skill の規律に沿っていますか。逸れていれば create-pr skill を通してください。"
    ;;
esac

if [ -n "$nudge" ]; then
  jq -n --arg ctx "$nudge" \
    '{hookSpecificOutput: {hookEventName: "PreToolUse", permissionDecision: "allow", additionalContext: $ctx}}'
fi
