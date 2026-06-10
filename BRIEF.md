# BRIEF.md

zomians/organize の目的・スコープ・成功基準。2026-06-10 の grill セッションの結論。

## 何を作るか

**「情報を整理したい」と思った瞬間から終わりまでを一気通貫で支援する Claude Code plugin。**

支援対象のワークフロー:

```
terminal 起動
   ↓
ディレクトリ名を決めて mkdir
   ↓
claude 起動
   ↓
現状把握 (壁打ち / リサーチ)
   ↓
ドキュメント化 (md 主体。html は閲覧用の派生物として必要時のみ)
   ↓
条件分岐
 ├─ 1: 情報を残すべき → そのディレクトリを repo 化 (git init + GitHub 新規リポ)
 │      高クオリティな issue を作成 → 作業ブランチ → PR → squash merge → branch 削除
 └─ 2: git 管理が不要 → その場に残すだけ (仕組みは作り込まない)
```

## 決定事項

| 論点 | 決定 |
|------|------|
| 実装形態 | Claude Code plugin。空ディレクトリでも skill が即使えるよう全ディレクトリで有効。改善は plugin update で全案件に一括反映 |
| git の単位 | 1 ディレクトリ = 1 リポ。「残すべき」と判断した時点で repo 化し、以降そのリポに issue/PR を積む |
| doc 形式 | md が正。html は図表・眺める用途の派生物として必要時のみ生成。ファイル名は内容に応じて AI が提案 |
| ローカル保管 (分岐 2) | その場に残すだけ。散らかりが痛くなったら検索・棚卸しを後から足す (YAGNI) |
| skill の出自 | **全部新規に書き下ろす**。旧 base の資産は参照に留め、移植しない |
| 旧 zomians/base | 放置。削除も archive もしない。議論履歴 (#21 #25 #27 等) は参照用に残る |
| 公開設定 | private。自分優先で作り、配布したくなった時点で汎用部分を抽出する |

## v1 で実装する skill (すべて新規)

| skill | 担当ステップ |
|-------|-------------|
| grill | 現状把握の壁打ち。一問一答・推奨案付きで意思決定ツリーを一枝ずつ潰す |
| doc 化 | 会話を読み、md にドキュメント化 (必要なら html 派生も) |
| repo 化 | 条件分岐 1 の入口。git init + gh repo create + push |
| issue 作成 | 高クオリティな GitHub issue の起票 |
| commit | Conventional Commits での commit |
| PR 完了 | PR 作成 → squash merge → branch 削除 |

条件分岐 (残すべきか否か) の判断基準は doc 化 / repo 化 skill の設計時に詰める。リサーチを独立 skill にするか grill 内で必要時に行うかも設計時の論点。

## 成功基準

- 「情報を整理したい」と思ってから迷う箇所がゼロになる (次に何をするかを常に skill が示す)
- 整理した情報が、残すべきものは GitHub に高クオリティな issue/PR 履歴つきで残り、そうでないものはローカルに残る
- skill の改善が plugin update だけで全ディレクトリに反映される

## 次のステップ

1. plugin 骨格 (`.claude-plugin/plugin.json` + `skills/`) の構築
2. 各 skill の設計・書き下ろし (grill → doc 化 → repo 化 → issue 作成 → commit → PR 完了 の順)

それぞれ issue として起票してから着手する。
