# ARCHITECTURE.md

zomians/organize plugin の構造・skill の座組み・運用規約。なぜその形かを含む。

## 全体像

organize は Claude Code plugin。空ディレクトリでも skill が即使えるよう全ディレクトリで有効。改善は plugin update で全案件に一括反映される。

整理のワークフローを直線の手続きではなく、**現状把握をハブにした放射状**として捉える。spar で頭が整理できたら、その成果を「どう残すか（あるいは残さないか）」が出口として分岐する。

## skill の座組み

フェーズ間の遷移を中央のオーケストレータが統括するのではなく、各 skill が末尾で次を能動的に促し、整理の入口に壁打ち skill（spar）を置く。重い中央制御は作らない（skill が重くなり、途中フェーズだけ使う自由度が下がり、層が増えると分類論が再燃するため。Claude Code の skill は本来 signal 駆動で疎結合に発火する）。

### spar（入口・現状把握）

整理の入口で計画を鍛える壁打ちをする単一のエントリ skill。現状把握の最初のフェーズを兼ねる。

**対話の作法**: 一問一答・推奨案付き・決定木を一枝ずつ潰す。各質問への回答を待ってから次へ進む。

**計画を鍛える壁打ち**: 質問は情報を集めるためでなく計画を鍛えるためにある。対話前に案件の既存 doc（ADR を含む）を読んで照合の土台にし、共有理解に達するまで問い尽くす。既存 doc（用語・スコープ・構造・過去の決定）との矛盾と曖昧語は即指摘して正準化し、具体シナリオ（エッジケース）で境界をストレステストし、発言とコードの食い違いは突きつける。

**リサーチ内蔵**: コードや web で答えが出る問いは、聞かずに自分で調べる。「事実を確認しないと答えが出ない」論点が出たら、その場で裏取りする。重い調査は `deep-research` skill に委譲する。リサーチを独立 skill にはしない。

**コードとの照合はコード有り案件のみ**。コード無し案件（マーケ・リサーチ等）では skip する。

### 後続フェーズ skill

issue 作成（`create-issue`）/ commit（`commit`）/ PR 完了（`create-pr`）。それぞれ末尾で次フェーズを促す。doc 化・repo 化は独立 skill にせず、spar が出口で内包する。

## Doc Catalog（plugin 同梱の辞書）

spar は Catalog を辞書として持ち、対話前に signal 列へ目を通したうえで（読んでいなければ signal に気づけない）、対話中に話題が踏み込んだら逆引きする。該当 doc が無ければ作成を能動提案し、有ればその場で更新する。Catalog は案件側の CLAUDE.md ではなく plugin に同梱する（plugin update で全案件に一括反映でき、案件ごとに Catalog がドリフトしない）。skill 側に doc リストを埋め込まず、Catalog を単一の真実とする。

### doc 作成のルール（全 doc 共通）

- **全 doc は lazy 作成**。signal が出るまで作らない。空の placeholder ファイルは一切置かない。doc の違いは「Catalog 辞書に載っているか否か」だけで、doc 別に常設/lazy を決めることはしない
- **inline 更新**: 関連話題が出るたびその場で更新する（まとめて後でやらない）
- **配置**: リポ root に置く（ファイル名は Catalog の通り）。肥大化したら `docs/` 配下を検討
- **Catalog にない doc** が必要になったら、その場で必要性を判断し、表に行を足す

### handoff.md は commit しない

情報を残すか否かの判断は出口の分岐（A〜E）で完結しており、ファイル命名等で再表現しない。唯一の例外が出口 E の `handoff.md` で、セッション間の引き継ぎ専用にリポ直下へ置くが commit はしない。issue / PR 下書きなどの作業ファイルは作らない（本文は会話で提示し、コマンドへは stdin で渡す）。

### Catalog

表（doc 一覧・主問い・signal シナリオ / 1 行ガード）は plugin 同梱の [skills/spar/catalog.md](./skills/spar/catalog.md) が単一の真実。本書には複製しない。すべて領域非依存で、signal が surface したら spar が逆引きする。

## spar の出口

spar は対話が一段落したら、同じ作法（一問一答・推奨付き）で出口を 1 問問い、選ばれた先へ案内する。出口は 5 通り:

| 出口 | いつ |
|---|---|
| A. doc に残す（Catalog doc） | 残す価値がある |
| B. issue を直接発行 | やることが明確、doc を経ずタスク化したい |
| C. doc も issue も両方 | 残す価値があり、かつ着手もする |
| D. 何も残さず動く / 終える | 整理で十分、git 管理不要 |
| E. handoff して中断（handoff.md・揮発） | 次のセッションに引き継ぎたい |

## 規律

plugin が全案件に持たせる規律:

- **DRY / YAGNI / TDD / Frequent commits**
- **Conventional Commits**。1 PR = 1 squashed commit に収まる粒度
- GitHub Flow / branch 命名 `feature/<#>-<summary>` / squash merge → branch 削除
- **コミットメッセージ・PR 本文・Issue 本文に AI 生成の旨を記載しない**（`🤖 Generated with...`、`Co-Authored-By: Claude...` 等は付与しない）
- skill の `allowed-tools` には**副作用がありプロンプトが出るツールだけ書く**（`Bash(git:*)` 等）。read-only（Read/Grep/Glob/WebSearch/WebFetch）は既定でプロンプトが出ないので書かない。上書き系（doc の Write/Edit、`gh issue edit` 等）は自動許可せずプロンプトを残す
