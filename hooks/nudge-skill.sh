#!/usr/bin/env bash
# organize: skill 発火漏れへの soft nudge（事後リカバリ。実行前の阻止ではない）。
#
# skill は signal 駆動の discoverable な仕組みで、ツール経路を塞ぐ gate ではない。
# 会話の流れで作業に入ると意図フレーズが出ず、最短経路の git commit / gh issue create /
# gh pr create を直接叩いて create-issue / commit / create-pr skill が発火しないことがある。
# この hook は直接経路を検出し、対応 skill の規律をコンテキストへ差し込む。ただし
# additionalContext はツール実行"後"に届くため直叩きは止められない（事後リカバリのみ）。
# 実行前に止める関所は permission プロンプト側（このコマンド群は既定でプロンプトが出る）。
#
# 設計（公式 hooks 仕様に準拠）:
#   - exit 0 で {hookSpecificOutput:{additionalContext}} を stdout に出すと、ツールを
#     ブロックせずモデルのコンテキストに文字列を差し込める。additionalContext はツール
#     結果の隣＝実行"後"に挿入される（＝事前阻止でなく事後ナッジ）。
#   - permissionDecision は出さない。出すと "allow" が許可プロンプトを自動承認してしまい、
#     「副作用のあるコマンドは許可プロンプトを残す」規律を骨抜きにする。nudge に徹する。
#   - jq には依存しない（tr のみ／POSIX）。tool_input.command の値だけを取り出し、
#     compound（&& ; |）をセグメント分割して各セグメントの先頭プログラムと git/gh の
#     サブコマンドを判定する。これで `git -C/-c ... commit` を拾い、`commit-tree` や
#     語を含むだけの echo/grep の誤爆を避ける。等価経路（gh api / curl）は対象外で
#     permission プロンプトに委ねる（ADR-0002 の leaky blocklist 受容）。
set -uo pipefail

input=$(cat)

# tool_input.command の値だけを取り出す（cwd / transcript_path 等の混入を防ぐ）。
# pure bash の best-effort 抽出: "command":"..." の値を最初の引用符まで。引用符で
# 囲まれた引数（-m "msg" 等）は切り落とされるが、サブコマンドはそれより前に出るので
# 判定には十分。
cmd=""
case "$input" in
  *'"command":"'*)
    cmd=${input#*'"command":"'}
    cmd=${cmd%%'"'*}
    ;;
esac

# compound を分割し、各セグメントの先頭プログラムと git/gh サブコマンドを見て種別を返す。
detect() {
  local seg norm
  norm=$(printf '%s' "$cmd" | tr ';|&' '\n\n\n')   # 区切りを改行化（&& も || も分割される）
  while IFS= read -r seg; do
    set -f; set -- $seg; set +f                     # noglob で単語分割
    [ $# -eq 0 ] && continue
    local prog=$1; shift
    case "$prog" in
      git)
        while [ $# -gt 0 ]; do                       # global option を読み飛ばす
          case "$1" in
            -C|-c) shift 2 2>/dev/null || shift ;;   # 値を取るオプション
            -*)    shift ;;                           # その他フラグ
            *)     break ;;
          esac
        done
        [ "${1:-}" = "commit" ] && { echo commit; return; }
        ;;
      gh)
        case "${1:-} ${2:-}" in
          "issue create") echo issue; return ;;
          "pr create")    echo pr; return ;;
        esac
        ;;
    esac
  done <<EOF
$norm
EOF
}

nudge=""
case "$(detect)" in
  commit)
    nudge="この commit は commit skill の規律（Conventional Commits / 1 PR = 1 squashed commit 粒度 / handoff.md は除外 / branch 判断）に沿っていますか。逸れていれば commit skill を通してください。"
    ;;
  issue)
    nudge="この起票は create-issue skill のテンプレート（背景・要件・受け入れ基準・工数見積）を満たしていますか。薄ければ create-issue skill を通してください。"
    ;;
  pr)
    nudge="この PR 作成は create-pr skill の規律に沿っていますか。逸れていれば create-pr skill を通してください。"
    ;;
esac

# additionalContext のみを出す（permissionDecision は出さない＝許可フローに触らない）。
# nudge は固定文字列。" や \ を含めないこと（素の printf で JSON を組むため）。
if [ -n "$nudge" ]; then
  printf '{"hookSpecificOutput":{"hookEventName":"PreToolUse","additionalContext":"%s"}}\n' "$nudge"
fi
exit 0
