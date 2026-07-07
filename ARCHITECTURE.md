# ARCHITECTURE.md

zomians/organize plugin の構造・skill の座組み・運用規約。なぜその形かを含む。

## 全体像

organize は Claude Code plugin。空ディレクトリでも skill が即使えるよう全ディレクトリで有効。改善は plugin update で全案件に一括反映される。

整理のワークフローを直線の手続きではなく、**現状把握をハブにした放射状**として捉える。spar で頭が整理できたら、その成果を「どう残すか（あるいは残さないか）」が出口として分岐する。

入口は 2 つある。整理したい話題が既に手にあるときは spar（いきなり疑うから入る）。話題がまだ**無く**、何を整理 / 作業するか自体を探すときは patrol（既存の repo / ディレクトリを深く読んで話題を掘り起こす）。spar と patrol は同じ「疑う」エンジンを共有し、**話題が手にあるか / これから掘るか**だけが差す。patrol が掘り起こした話題は出口（残す）か spar での深掘りへ放射状につながる（探す → 疑う → 残す）。

## skill の座組み

フェーズ間の遷移を中央のオーケストレータが統括するのではなく、各 skill が末尾で次を能動的に促し、整理の入口に壁打ち skill（spar）を置く。重い中央制御は作らない（skill が重くなり、途中フェーズだけ使う自由度が下がり、層が増えると分類論が再燃するため。Claude Code の skill は本来 signal 駆動で疎結合に発火する）。

### spar（入口・現状把握）

整理の入口で計画を鍛える壁打ちをする単一のエントリ skill。現状把握の最初のフェーズを兼ねる。

**対話の作法**: 一問一答・推奨案付き・決定木を一枝ずつ潰す。各質問への回答を待ってから次へ進む。

**計画を鍛える壁打ち**: 質問は情報を集めるためでなく計画を鍛えるためにある。対話前に案件の既存 doc（ADR を含む）を読んで照合の土台にし、共有理解に達するまで問い尽くす。既存 doc（用語・スコープ・構造・過去の決定）との矛盾と曖昧語は即指摘して正準化し、具体シナリオ（エッジケース）で境界をストレステストし、発言とコードの食い違いは突きつける。

**リサーチ内蔵**: コードや web で答えが出る問いは、聞かずに自分で調べる。「事実を確認しないと答えが出ない」論点が出たら、その場で裏取りする。重い調査は `deep-research` skill に委譲する。リサーチを独立 skill にはしない。

**コードとの照合はコード有り案件のみ**。コード無し案件（マーケ・リサーチ等）では skip する。

### patrol（第二の入口・探す）

整理すべき話題を掘り起こす入口 skill。spar が既に手にある話題をいきなり疑うのに対し、patrol は話題がまだ無い状態で、既存の repo / ディレクトリを1つ深く読んで話題を掘り起こす。両者は同じ「疑う」エンジンを共有し、話題が手にあるか / これから掘るかだけが差す。素プロンプトでも plugin のプラットフォーム化でもなく、Claude Code の skill 追加で実現する（「層を増やすな」に沿う）。

**内部は三段の一本道**: 把握（対象を深く読む）→ 疑う（敵対的に叩いて綻びを surface）→ 探す（綻びを整理すべき話題に翻訳）。「疑う」を patrol の外（下流）に委ねず、その場で完結させる。

**判定は organize の核心から演繹する**。負債レンズ（リポの「複雑さ × 活動量」に対する言語化負債 + flow 負債のギャップ）を疑うの一レンズに使い、綻びの大きい順に置く。判定基準を場当たりなヒューリスティクスにせず核心から導くことで、ドリフトしない。深く読む前提なので、負債はメタデータだけでなく実体（コード ↔ doc の矛盾・書かれざる決定）まで届く。

**放置は flow 負債として拾う**。把握で活動量と手元の in-flight（未 commit・未 push branch・stash・TODO）を読み、疑うで「作業が issue → PR → merge の規律に乗っていない」綻びに翻訳する。1リポ深掘りでも `gh pr list` / `git branch` / `git status` で放置 PR・放置 branch・長期滞留の未 commit・main 直 commit は捕まる。放置は活動量でスケールするので、動いていない若いリポの放置は自然に足切りされる。

**lazy 原則を守る弁別子**: 「doc が無い」では叩かない。doc 不在そのものは負債でない（lazy 作成が正常）。負債は活動量でスケールし、活動の無い若いリポは自然に足切りされる。patrol は督促チェッカーではなく、「signal が repo の歴史で繰り返し surface しているのに doc / flow に乗っていない」状態の検出器。

**patrol は確定・実行しない**。疑って揮発する話題リストを出し、人間が 1 件選ぶ（何を整理するかの選択権は人間が握る）。選ばれた話題は、疑い済みで打ち手が見えていれば出口（残す＝ create-issue / commit / close 等）へ、さらに鍛える必要があれば spar へ。read-only の把握だけで断定できない論点（放置 PR を close すべきか等）は断定せず「疑うべき話題」として置く。出力をファイル化しないのは「作業ファイルを作らない」規律に沿う。

**既定は1リポ深掘り**。対象は引数か「今いる repo / ディレクトリ」で、config ファイルは作らない・要求しない（空でも即使える思想／設定ドリフトを避ける）。複数 repo / org 横断は二次モードとし、コスト対策に二段構え（Pass1 で横断的に安価にランク付け → Pass2 で上位だけ三段を回す）を使う。全リポ精読はコストで破綻するため、深掘りは既定で1つに絞る。

### 後続フェーズ skill

issue 作成（`create-issue`）/ commit（`commit`）/ PR 完了（`create-pr`）。それぞれ末尾で次フェーズを促す。doc 化・repo 化は独立 skill にせず、spar が出口で内包する。

`create-pr` は merge 前に Claude Code 組み込みの `/code-review` を**ソフトゲート**として挟む（ブラウザ目視と並走する前景レビュー。findings は提示するだけで判断は人間に委ね、機械的には止めない）。手順1 の TDD が red で止める hard block なのに対し review findings を止めないのは、findings が助言的で false positive を含むため（非対称の根拠は ADR-0003）。

## Doc Catalog（plugin 同梱の辞書）

spar は Catalog を辞書として持ち、対話前に signal 列へ目を通したうえで（読んでいなければ signal に気づけない）、対話中に話題が踏み込んだら逆引きする。該当 doc が無ければ作成を能動提案し、有ればその場で更新する。Catalog は案件側の CLAUDE.md ではなく plugin に同梱する（plugin update で全案件に一括反映でき、案件ごとに Catalog がドリフトしない）。skill 側に doc リストを埋め込まず、Catalog を単一の真実とする。

### doc 作成のルール（全 doc 共通）

- **全 doc は lazy 作成**。signal が出るまで作らない。空の placeholder ファイルは一切置かない。doc の違いは「Catalog 辞書に載っているか否か」だけで、doc 別に常設/lazy を決めることはしない
- **inline 更新**: 関連話題が出るたびその場で更新する（まとめて後でやらない）
- **配置**: リポ root に置く（ファイル名は Catalog の通り）。肥大化したら `docs/` 配下を検討
- **Catalog にない doc** が必要になったら、その場で必要性を判断し、表に行を足す

### handoff.md は commit しない

情報を残すか否かの判断は出口の分岐（残す / 何も残さず / handoff）で完結しており、ファイル命名等で再表現しない。唯一の例外が handoff 出口の `handoff.md` で、次セッションの自分または別の AI / ツールへの引き継ぎ専用にリポ直下へ置くが commit はしない。doc が複数あっても handoff は必ず 1 ファイルにし、ディレクトリ化・複数ファイルへの分割はしない。issue / PR 下書きなどの作業ファイルは作らない（本文は会話で提示し、コマンドへは stdin で渡す）。

### Catalog

表（doc 一覧・主問い・signal シナリオ / 1 行ガード）は plugin 同梱の [skills/spar/catalog.md](./skills/spar/catalog.md) が単一の真実。本書には複製しない。すべて領域非依存で、signal が surface したら spar が逆引きする。

## spar の出口

spar は対話が一段落したら、同じ作法（一問一答・推奨付き）で出口を 1 問問い、選ばれた先へ案内する。出口は 3 通り:

| 出口 | いつ |
|---|---|
| 残す | 残す価値がある、または着手する |
| 何も残さず動く / 終える | 整理で十分、git 管理不要 |
| handoff して中断（handoff.md・揮発） | 次のセッションに引き継ぎたい |

「残す」は issue を起点に main 反映を開始する単一の出口。md（spar が §2 catalog 逆引きで作成 / 更新した doc）はそのタスクの成果物として issue に添え、同じ branch で残す。md を生まない純タスクなら issue だけ。ローカル完結しない限り、md を main に入れるにも GitHub Flow が要るので、出口の判断は「残すか否か」一軸で、doc / issue の振り分けを出口で問わない。新規案件は `git init` / `gh repo create` で repo 化してから始める。

## 自動実行（execution-phase automation）

「残す」出口で、内包 skill（`create-issue` → `commit` → `create-pr`）を**事前確認ゲートを畳んで PR まで連続実行する**かを affordance として問える（spar が yes / no を問う。運用契約の正準は `skills/spar/SKILL.md` §3）。

**なぜ畳んでよいか**: issue・PR は**成果物が返る実行フェーズ**で、人間は成果物（ブラウザで開く issue / PR）を事後レビューで検証でき、誤りは編集で直せる。だから各 skill の起票前 / commit / 作成前の確認を畳んでも出戻らない。一方、**真の探索フェーズ**（成果物が返らず、途中の判断を見ないと検証できないタスク）はこのモードに乗せない — 畳むと丸投げに滑る。

**境界（畳まないもの）**:

- **終点は PR 作成＋ブラウザ表示＋diff レビュー結果（read-only）**。findings に基づく修正（`--fix`）と squash merge は人間が握る（畳まない）。レビュー findings は成果物なので、人間は merge 判断の前に「PR ＋ findings」をまとめて事後レビューできる。
- 接点は両端に集約 — 壁打ち（spar）と、issue / PR の成果物レビュー＋merge。中間の機械的実行だけを畳む。
- **誤爆を防ぐ**: 自動実行は「spar の『PRまで自動実行』で yes を選んだ連鎖」という素性に限り発火する。各 skill を単発で呼んだときは確認を省かない（fail-closed）。
- フォアグラウンドで回す（subagent / worktree は使わない）。「伴走 _Avoid_: オーケストレーション」と矛盾しない — 中央統括は導入せず、各 skill が末尾で次を促す既存の座組みのまま、確認ゲートだけを畳む。この subagent 不使用は **organize 自身のフェーズ orchestration に係る制約**（自フェーズを subagent / worktree に委譲しない＝中央オーケストレータ化しない）であって、フォアグラウンドで呼ぶ成果物ツール（merge 前の `/code-review` 等）が内部で finder/verifier に fan-out するのは妨げない — 成果物（findings）が返り人間が事後検証できる以上「丸投げ」ではない。code-review 起動時に出る許可プロンプトは、自動実行が温存する per-user backstop（ADR-0002）であって畳む対象ではない。

ARCHITECTURE は runtime の skill ロード経路に載らない（設計の根拠の置き場）。skill が実行時に従う契約は各 SKILL.md に自己完結で書く。

## 発火漏れへの soft nudge hook（事後リカバリ）

skill は description の signal を見てモデルが自発的に選ぶ **discoverable な仕組み**で、ツール経路を塞ぐ gate ではない。`create-issue` / `commit` の description は「issue にしたい」「commit したい」という *意図の言語化* を signal にしているため、会話の流れで作業に入ると誰もそのフレーズを口にせず、最短経路の `git commit` / `gh issue create` / `gh pr create` を直接叩いて skill が発火しないことがある。

これに `PreToolUse`（matcher: `Bash`）の **soft nudge hook**（[hooks/nudge-skill.sh](./hooks/nudge-skill.sh)）を当て、3 コマンドを検出したら対応 skill の規律を `additionalContext` で差し込む。

**何をして・何をしないか（実態を正確に）**:

- **阻止ではなく事後ナッジ**。公式 hooks 仕様上、`permissionDecision` を伴わない `additionalContext` は「ツール結果の隣」に挿入される＝**コマンド実行の"後"**にモデルが見る。よって hook は直叩きを *止められない*。できるのは事後のリカバリ誘導（薄い issue を `gh issue edit` で直す・commit を amend する等）で、フローの強制や順序の gate ではない。
- **実行前の関所は permission プロンプトの方**。`git commit` / `gh issue create` / `gh pr create` は既定で許可プロンプトが出る（allow リストに足さない限り）。これが実行前に止める唯一の層で、hook はその上に乗る「人間が承認を素通ししても Claude 側が自己修正する」second chance。
- **leak は別動詞のみ（縮小済み）**。`tool_input.command` を取り出して compound（`&&` `;` `|`）を分割し、git/gh のサブコマンドを判定する。よって `git -C/-c ... commit` や `cd x && git commit` は拾い、`git commit-tree` や語を含むだけの `echo` / `grep` には誤爆しない。取りこぼすのは別動詞の等価経路（`gh api .../issues|pulls` / `curl`）だけで、これは permission プロンプトが per-user backstop する（完全網羅は追わない）。

**なぜ hook が許されるか**:

- **末端反射であって中央オーケストレータではない**。ツール境界で発火する per-tool の反射で、フェーズ遷移を統括する層を足すわけではない。「重い中央制御は作らない」「伴走 _Avoid_: オーケストレーション」と矛盾しない。
- **`permissionDecision` を出さない**。`allow` を返すと許可プロンプトを自動承認し、「副作用コマンドは許可プロンプトを残す」規律（§規律）を骨抜きにする＝permission backstop を hook 自身が潰す。出さない＝通常フローへ defer＝プロンプトが残る。
- **jq に依存しない（`tr` のみ／POSIX）**。command フィールドを取り出し、compound 分割＋サブコマンド判定で実装する。移植性（jq 不要）と precision（誤爆排除・`git` の global option 形の捕捉）を両立する。
- **文言は scold でなく reinforce**。skill 実行中の `git commit` で redundant に発火しても no-op で済む（skill 内かを hook は判別できないため）。

blocking gate（AI 署名 deny）を採らない理由と決定の全体は ADR-0002。検出コマンドの追加は `case` の 1 行で済む。

## 規律

plugin が全案件に持たせる規律:

- **DRY / YAGNI / TDD / Frequent commits**
- **Conventional Commits**。1 PR = 1 squashed commit に収まる粒度
- GitHub Flow / branch 命名 `feature/<#>-<summary>` / squash merge → branch 削除
- **「残す」は issue を起点に main 反映する**。md は issue に添えて同じ branch で残す（詳細・根拠は「spar の出口」を参照）
- **コミットメッセージ・PR 本文・Issue 本文に AI 生成の旨を記載しない**（`🤖 Generated with...`、`Co-Authored-By: Claude...` 等は付与しない）
- skill の `allowed-tools` には**副作用がありプロンプトが出るツールだけ書く**（`Bash(git:*)` 等）。read-only（Read/Grep/Glob/WebSearch/WebFetch）は既定でプロンプトが出ないので書かない。上書き系（doc の Write/Edit、`gh issue edit` 等）は自動許可せずプロンプトを残す
