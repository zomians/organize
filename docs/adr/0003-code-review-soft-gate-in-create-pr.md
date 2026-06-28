# ADR-0003: create-pr の code-review は soft gate（findings は人間判断）とし、自動モードは read-only で走らせる

- ステータス: 採用
- 日付: 2026-06-28

## 文脈

create-pr の品質ゲートは手順1 の TDD チェック（test green）のみで、diff 全体のレビュー観点（correctness bug・整理）が抜けていた。Claude Code には組み込みの `/code-review`（current diff をレビューし findings を返す。effort 段階・`--fix`・ultra クラウドモードを持つ）があり、これを merge 前に挟む案が出た。

論点は 2 つ。(1) findings が出たとき merge を機械的に止める hard block にするか、人間判断のソフトゲートにするか。手順1 の TDD は red で PR を止める hard block で、揃えるべきか非対称にすべきかが問われた。(2) 自動実行モード（spar「PRまで自動実行」yes 連鎖。終点は PR 作成＋ブラウザ表示）でレビューを走らせるか。レビューゲートはブラウザ表示と merge の間＝終点のすぐ後ろに座るため、終点定義に触れる。

## 決定

`create-pr` の merge 前に前景 `/code-review`（既定 low〜medium）を**ソフトゲート**として挟む。ブラウザ目視と並走させ（目視時間に計算を重ねる）、findings は提示するだけで判断は人間に委ねる（そのまま merge / `--fix` で直して再確認 / 中断）。**findings で機械的に merge を止めない**（手順1 の TDD は hard block のまま据え置き、review は soft という非対称を採る）。

自動実行モードでは `/code-review` を **read-only で走らせ findings を提示して止まる**（`--fix` しない）。終点を「PR 作成＋ブラウザ表示」から「PR 作成＋ブラウザ表示＋diff レビュー結果（read-only）」へ更新する。findings に基づく修正と squash merge は人間が握る（畳まない）。重い diff の `ultra`（クラウド・user-triggered）は create-pr からは起動せず、必要なら人間に促すに留める。

## 理由

- **findings は test の green/red と違い助言的**。effort を上げるほど不確実な指摘（false positive）が混じる。機械的に止めると、ノイズ 1 件で詰まり「迷いをゼロにする伴走」がかえって阻害になる。binary な test 結果で成立する hard block を、性質の違う findings に流用しない。
- **自動モードでこそ走らせる価値が高い**。人間が最も手を離す自動連鎖で merge 前レビューが消えるのは逆。findings は成果物なので、人間は「PR ＋ findings」を merge 判断の前にまとめて事後レビューできる（自動実行モードの「成果物が返る実行フェーズは畳んでよい／接点は両端に集約」に乗る）。read-only に縛れば `--fix` による無確認の再 commit が起きず、「終点の後ろ（修正・merge）は人間」の線も保てる。
- **ultra を自動起動しない**。ultra は user-triggered で課金を伴い、create-pr からは起動できない。gate にしたい以上、自動起動できる前景 `/code-review` を既定に据える。
- **gate を強くしない系譜と整合**。ADR-0002「nudge over blocking gate」と同じく、強制ブロックでなく人間の判断余地を残す層に留める。

3 条件の確認: 後戻り困難（全案件に配布される create-pr の挙動契約で、利用者の期待が動く）／文脈なしには驚く（「TDD は red で止める」と読んだ者が「review findings は止めない」非対称を見ると驚く）／実トレードオフ（hard block の厳格さ・詰まり vs soft gate のノイズ耐性・見逃しうるリスク、自動レビューのコスト vs 手離し時の検出機会）。
