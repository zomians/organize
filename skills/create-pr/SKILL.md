---
name: create-pr
description: commit 後に PR を作成し、TDD チェック・ブラウザ目視・diff レビュー・確認を経て squash merge + branch 削除まで伴走する。「PR を出したい」「PR にして」という意図が出たとき、または commit skill の手順7から促されたときに使う。アシスタント自身が「PR にしておきますか？」等と提案し利用者が「お願い」「うん」等で同意したときも、提案主体に関わらず発火する（同意で PR 意図が成立するため、伴走を通さない素の gh pr create に流さない）。
allowed-tools:
  - Bash(git:*)
  - Bash(gh pr:*)
---

# create-pr

整理ワークフローの終端「PR 完了」フェーズ。commit の次に発火し、PR 作成から merge まで伴走する。

## 手順

1. **TDD チェック**: 変更にテストがあるか観察する。
   - テストあり → 実行して green を確認する。red なら PR を止め、利用者に伝える
   - テストなし → そのテストが必要かを判断し、必要ならテスト作成を提案する。不要ならスキップして次へ進む
2. **PR 作成**: `gh pr create` で PR を作る。本文は下記の軽量な型で下書きし、利用者に提示して確認を得てから作成する（spar の「PRまで自動実行」で yes を選んだ連鎖から起動された自動実行モードのときに限り、この事前確認を省いてそのまま作成する。単発呼び出しや迷ったときは省かない＝fail-closed）。本文は stdin で渡す（`gh pr create --title "<title>" --body-file -`）。
3. **ブラウザ表示**: `gh pr view --web` で PR を必ずブラウザ表示し、利用者に目視させる。続く手順4 の diff レビューはこの目視と並走する（人間の目視時間に計算を重ねる）。
4. **code-review（diff レビュー・ソフトゲート）**: 前景 `/code-review`（既定 low〜medium）を走らせ、merge 前に diff をレビューする。
   - findings を利用者に提示する。**ソフトゲート** — 判断は人間に委ねる（そのまま merge / `--fix` で直して再確認 / 中断）。findings が空・軽微なら次へ進む。findings は助言的で false positive を含むため、手順1 の TDD（red で止める hard block）と違い、**findings で機械的に merge を止めない**（この非対称の根拠は ADR-0003）。
   - 重い diff は利用者が effort を high / ultra に上げられる（ultra はクラウドで user-triggered。create-pr からは起動しないので、必要なら利用者に促す）。
   - **自動実行モードのとき**: read-only で走らせ findings を提示して止まる（`--fix` しない）。**自動実行モードの終点はここ** — findings に基づく修正と続く merge（手順5-6）・締め（手順7）は自動実行でも畳まず、必ず人間が握る。
5. **merge 権限の確認**: 利用者に merge 権限があるか問う。
6. **merge**:
   - 権限あり → 確認を得た上で `gh pr merge --squash --delete-branch` で squash merge + branch 削除する
   - 権限なし → merge 権限のある管理者に委ねて終了する（squash + branch 削除は委ね先が行う）
7. **次へ**: merge 完了で整理ワークフローは終端。やり残しがあれば次の一手を一言で示して終える。

## PR 本文の型

```markdown
## 概要

[1-2 文で変更内容を説明]

Closes #<n>
```

- 対応する issue があれば `Closes #<n>` で閉じる。無ければその行を省く
- タイトルは Conventional Commits の型に合わせる（1 PR = 1 squashed commit の粒度）

## 禁止

- PR 本文に AI 生成の旨を記載しない（`🤖 Generated with...` / `Co-Authored-By: Claude...` 等を付けない）
- PR 本文に機密情報（トークン・内部 URL 等）を含めない
- merge 権限の有無を外部 API で照会しない（利用者に問う）
