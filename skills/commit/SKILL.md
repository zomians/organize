---
name: commit
description: 変更を規律（Conventional Commits・適切な粒度・branch 運用）に沿って commit する。「commit したい」「コミットして」という意図が出たとき、または整理の出口・作業の区切りで commit が必要になったときに使う。
---

# commit

変更を規律に沿って commit する。

## 手順

1. **観察**: `git status` / `git diff` で変更を観察する。観察で分かることは聞かない。
2. **粒度判断**: 1 PR = 1 squashed commit に収まる粒度か見る。無関係な変更が混在していれば分割を提案する。
3. **branch 判断**: 現在地を `git branch --show-current` で確認する。
   - main 上で対応する issue があれば `feature/<#>-<summary>` を切ってから commit する
   - main 上で対応する issue が無ければ、先に `create-issue` skill を発動して issue を起こし、その番号で `feature/<#>-<summary>` を切る
   - 既に feature branch 上ならそのまま commit する
4. **ステージ**: 対象の変更をステージする。`handoff.md` はステージしない（commit 対象外）。
5. **メッセージ下書き**: Conventional Commits の型でメッセージを下書きし、利用者に提示して確認を得る。
6. **commit**: 確認後に commit する。
7. **次へ**: commit 後、PR を出すか問い、出すなら `create-pr` skill（PR 完了フェーズ）へ促す。

## 禁止

- commit メッセージに AI 生成の旨を記載しない（`🤖 Generated with...` / `Co-Authored-By: Claude...` 等を付けない）
- commit メッセージに機密情報（トークン・内部 URL 等）を含めない
- `handoff.md` を commit しない
