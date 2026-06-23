# ADR-0002: skill すり抜けは soft nudge（事後）＋ permission プロンプト（事前）で対処し、blocking gate を採らない

- ステータス: 採用
- 日付: 2026-06-23

## 文脈

skill は description の signal をモデルが読んで自発選択する discoverable な仕組みで、ツール経路を塞ぐ gate ではない（ARCHITECTURE「発火漏れへの soft nudge hook」）。作業モーメンタム下では Claude が完了最適化で最短経路（`gh issue create` / `git commit` / `gh pr create` の直叩き）に流れ、skill が発火しないすり抜けが繰り返し観測された（create-issue だけでなく create-pr も）。description への signal 追加（提案→同意でも発火）は決定の瞬間に signal を置けず、塞ぎきれない。

対策として 2 案が並んだ — soft nudge hook（非ブロックで規律を再浮上）と、AI 署名を検出して commit を deny する blocking gate。どちらを plugin に載せるかを決める。

## 決定

PreToolUse の **soft nudge hook**（`hooks/hooks.json` 同梱）を採用する。`permissionDecision` は一切出さず、`additionalContext` のみを差し込む。**blocking gate（AI 署名 deny）は採らない**。

ただし役割を正確に置く:

- **nudge は事後リカバリ**。公式仕様上 `permissionDecision` 無しの `additionalContext` はツール結果の隣＝**実行後**に届くため、直叩きを阻止できない。できるのは事後の自己修正誘導のみ。
- **実行前に止める関所は permission プロンプト**。対象 3 コマンドは既定でプロンプトが出る。nudge を出さない＝通常フローへ defer なのでこのプロンプトが残り、これが唯一の preventive 層になる。nudge はその上の second chance。
- コマンド文字列照合は等価経路（`gh api` / `curl` / `git -C ... commit`）を取りこぼす leaky blocklist であり、完全網羅は追わない。漏れは各ユーザーの permission 運用（allow を絞り直叩きをプロンプトに晒す）が per-user backstop として補完する。

## 理由

- **nudge は末端反射**。中央オーケストレータでなくステートレスな per-call の反射なので「重い中央制御は作らない」と矛盾しない。「発火提案すらしない」状態に対し、事後でも規律を文脈へ戻して自己修正の機会を作る最小手。
- **blocking の保証は幻**。署名は剥がせる／issue 本文に署名は無い／`gh api`・`curl` 等の等価経路は別軸。決定性は得られないのに、全 commit のクリティカルパス化・誤爆・自己ブロック（skill 自身の commit も止まる）の代償だけ恒久的に払う。
- **`permissionDecision` を出さないのが backstop と噛み合う**。`allow` を返すと許可プロンプトを自動承認し、「副作用コマンドは許可プロンプトを残す」規律（ARCHITECTURE §規律）を hook 自身が骨抜きにする。出さないことで、permission プロンプト（人間の関所・事前）と nudge（Claude の自己修正・事後）の二層が両立する。
- **本物の規制が要るなら層が違う**。決定的な強制は、規制対象（直叩きする Claude）が触れないサーバ側（GitHub branch protection・required CI checks で成果物＝Conventional Commits / 署名無し / issue linkage / テンプレ充足を reject）でしか作れない。これは「空ディレクトリでも即使える・config 要求しない・重い中央制御は作らない」という organize の射程と衝突するため、plugin では持たない。plugin は nudge ＋ permission の非侵襲な二層に留める。

3 条件の確認: 後戻り困難（hook は plugin identity の一部で、install 先全員の Bash 実行挙動を変える）／文脈なしには驚く（「skill は signal 駆動で gate を作らない」と読んだ者が PreToolUse hook を見ると驚く）／実トレードオフ（signal 純度・discoverability vs 信頼性、非ブロック vs ブロック、blocklist の漏れ受容 vs 完全性）。
