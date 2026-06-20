#!/usr/bin/env bash
# organize: skill 発火漏れを塞ぐ soft nudge。
#
# skill は signal 駆動の discoverable な仕組みで、ツール経路を塞ぐ gate ではない。
# 会話の流れで作業に入ると意図フレーズが出ず、最短経路の git commit / gh issue create /
# gh pr create を直接叩いて create-issue / commit / create-pr skill が発火しないことがある。
# この hook は直接経路を検出した瞬間に、対応 skill の規律をコンテキストへ再浮上させる。
#
# 設計（公式 hooks 仕様に準拠）:
#   - exit 0 で {hookSpecificOutput:{additionalContext}} を stdout に出すと、ツールを
#     ブロックせずモデルのコンテキストに文字列を差し込める（＝soft nudge）。
#   - permissionDecision は出さない。出すと "allow" が許可プロンプトを自動承認してしまい、
#     「副作用のあるコマンドは許可プロンプトを残す」規律を骨抜きにする。nudge に徹する。
#   - jq には依存しない。install 先に jq が無くても効くよう pure bash で書く。
#     stdin 全体を case で部分一致（matcher: Bash なので tool_input.command が含まれる）。
set -uo pipefail

input=$(cat)

nudge=""
case "$input" in
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

# additionalContext のみを出す（permissionDecision は出さない＝許可フローに触らない）。
# nudge は固定文字列。" や \ を含めないこと（素の printf で JSON を組むため）。
if [ -n "$nudge" ]; then
  printf '{"hookSpecificOutput":{"hookEventName":"PreToolUse","additionalContext":"%s"}}\n' "$nudge"
fi
exit 0
