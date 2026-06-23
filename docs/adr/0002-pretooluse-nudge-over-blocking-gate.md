# ADR-0002: skill すり抜けは PreToolUse nudge で塞ぐ（blocking gate を採らない）

- ステータス: 採用
- 日付: 2026-06-23

## 文脈

skill は description の signal をモデルが読んで自発選択する discoverable な仕組みで、ツール経路を塞ぐ gate ではない（ARCHITECTURE「発火漏れを塞ぐ soft nudge hook」）。作業モーメンタム下では Claude が完了最適化で最短経路（`gh issue create` / `git commit` / `gh pr create` の直叩き）に流れ、skill が発火しないすり抜けが繰り返し観測された（create-issue だけでなく create-pr も）。description への signal 追加（提案→同意でも発火）は決定の瞬間に signal を置けず、塞ぎきれない。

この対策として 2 案が並んだ — soft nudge hook（非ブロックで規律を再浮上）と、AI 署名を検出して commit を deny する blocking gate。どちらを plugin に載せるかを決める。

## 決定

PreToolUse の **soft nudge hook**（`hooks/hooks.json` 同梱）を採用し、ツール境界で skill の規律をコンテキストへ再発行する。ブロックはしない。**blocking gate（AI 署名 deny）は採らない**。

実装上、hook は `permissionDecision` を一切出さない（`allow` すら出さない）。`additionalContext` のみを差し込む。コマンド文字列照合が等価コマンド（`gh api` / `curl` 経由等）を取りこぼす leaky blocklist であることは受け入れ、漏れは各ユーザーの permission 運用（allow を絞り直叩きをプロンプトに晒す）が per-user backstop として補完する。

## 理由

- **nudge は末端反射**。中央オーケストレータではなくステートレスな per-call の反射なので「重い中央制御は作らない」と矛盾せず、signal 駆動を“決定の瞬間”という正しい層で回復する。「発火提案すらしない＝signal が決定時に無い」を直す最小手。
- **blocking の保証は幻**。署名は剥がせる／issue 本文に署名は無い／`gh api`・`curl` 等の等価経路は別軸。決定性は得られないのに、全 commit のクリティカルパス化・誤爆・自己ブロックの代償だけ恒久的に払う。blocking gate の狙い（すり抜け検出）は nudge が境界で signal 再発行する形で吸収できる。
- **permissionDecision を出さないのが backstop と噛み合う**。`allow` を返すと許可プロンプトを自動承認し、「副作用コマンドは許可プロンプトを残す」規律（ARCHITECTURE §規律）を hook 自身が骨抜きにする。nudge は許可フローに触らず、permission 締め（人間の関所）と hook（Claude の自己修正）の二層を保つ。

3 条件の確認: 後戻り困難（hook は plugin identity の一部で、install 先全員の Bash 実行挙動を変える）／文脈なしには驚く（「skill は signal 駆動で gate を作らない」と読んだ者が PreToolUse hook を見ると驚く）／実トレードオフ（signal 純度・discoverability vs 信頼性、非ブロック vs ブロック、blocklist の漏れ受容 vs 完全性）。
