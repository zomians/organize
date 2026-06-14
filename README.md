# organize

**「情報を整理したい」と思った瞬間から終わりまでを一気通貫で支援する Claude Code plugin。**

整理という行為に、最初から最後まで伴走する。各 skill が「次は何をするか」を能動的に示し、迷う箇所をなくす。

## なにをするか

整理の流れを、直線の手続きではなく **現状把握をハブにした放射状** として捉える。
入口の壁打ち（spar）で頭が整理できたら、その成果を「どう残すか／残さないか」が出口として分岐する。

```
現状把握（壁打ち / 必要ならリサーチ）
   ↓  spar
[ 出口の分岐 ]
 ├─ 残す ──→ issue 起点で main へ反映（md は issue に添える）
 ├─ 何も残さず終える
 └─ handoff して中断（揮発・commit しない）
   ↓  残すと決めたら
 リポ化（新規なら git init / gh repo create・既存なら該当リポへ）
   ↓
 issue → 作業ブランチ → PR → squash merge → branch 削除
```

フェーズ間の遷移に中央のオーケストレータを置かない。各 skill が末尾で次を能動的に促し、利用者は途中フェーズだけを単独で使うこともできる。

## skill 一覧

| skill | 役割 |
|---|---|
| **spar** | 整理の入口。計画を鍛える壁打ちを一問一答・推奨案付きで行い、矛盾・曖昧さ・未検証の前提を突く。surface した signal から必要な doc を逆引きして残し、最後に出口へ案内する。 |
| **create-issue** | GitHub issue をテンプレートに沿って高クオリティに起票する。 |
| **commit** | 変更を規律（Conventional Commits・適切な粒度・branch 運用）に沿って commit する。 |
| **create-pr** | commit 後に PR を作成し、TDD チェック・ブラウザ目視・確認を経て squash merge + branch 削除まで伴走する。 |

## インストール

Claude Code 上で marketplace を追加し、plugin を入れる:

```
/plugin marketplace add zomians/organize
/plugin install organize
```

更新は plugin update で全ディレクトリに一括反映される。

## 使いかた

整理したくなったら、そのまま声をかけるだけでよい。

```
整理したい
何から始めればいいか分からない
頭の中を整理したい
整理して残したい
```

これらの意図で **spar** が発火し、現状把握の壁打ちが始まる。あとは各 skill が次を促すので、流れに乗れば issue / PR まで辿り着く。

## 規律

plugin が全案件に持たせる規律:

- **DRY / YAGNI / TDD / Frequent commits**
- **Conventional Commits**。1 PR = 1 squashed commit に収まる粒度
- **GitHub Flow** / branch 命名 `feature/<#>-<summary>` / squash merge → branch 削除
- **「残す」は issue を起点に main へ反映する**。md は issue に添えて同じ branch で残す
- コミットメッセージ・PR 本文・Issue 本文に AI 生成の旨を記載しない

## ドキュメント

- [BRIEF.md](./BRIEF.md) — 目的・スコープ・成功基準
- [ARCHITECTURE.md](./ARCHITECTURE.md) — 構造・skill の座組み・運用規約（なぜその形か）
- [CONTEXT.md](./CONTEXT.md) — この案件固有の用語集

## ライセンス

[MIT License](./LICENSE) で公開している。
