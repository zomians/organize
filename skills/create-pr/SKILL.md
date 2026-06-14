---
name: create-pr
description: commit 後に PR を作成し、TDD チェック・ブラウザ目視・確認を経て squash merge + branch 削除まで伴走する。「PR を出したい」「PR にして」という意図が出たとき、または commit skill の手順7から促されたときに使う。
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
2. **PR 作成**: `gh pr create` で PR を作る。本文は下記の軽量な型で下書きし、利用者に提示して確認を得てから作成する。本文は stdin で渡す（`gh pr create --title "<title>" --body-file -`）。
3. **ブラウザ表示**: `gh pr view --web` で PR を必ずブラウザ表示し、利用者に目視させる。
4. **merge 権限の確認**: 利用者に merge 権限があるか問う。
5. **merge**:
   - 権限あり → 確認を得た上で `gh pr merge --squash --delete-branch` で squash merge + branch 削除する
   - 権限なし → merge 権限のある管理者に委ねて終了する（squash + branch 削除は委ね先が行う）
6. **次へ**: merge 完了で整理ワークフローは終端。やり残しがあれば次の一手を一言で示して終える。

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
