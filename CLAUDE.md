# ポカ富豪 (poka_fugou_app)

ポーカーと大富豪を組み合わせたトランプゲームの Flutter アプリ。ルールの詳細は README.md を参照。
ユーザーはアプリエンジニア(Kotlin / SwiftUI / Flutter 経験あり)。インフラ・バックエンドの説明は初心者向けに。

## 構成 (MVVM)

- `lib/constants/` 文言(`AppStrings`)、役(`HandRank`)、難易度(`Difficulty`)、ルール画面の文言(`Rules`: 節ごとの見出し・箇条書き・表。README のルールを変えたらここも直す)
- `lib/models/` 役判定(`HandEvaluator`)、AI(`SimpleAI` / `AdvancedAI`)、API レスポンス、カード(`PlayingCard`)、ゲーム状態(`GameState`)
- `lib/models/daifugo/` 大富豪のルール判定(`DaifugoRules`: 出せるか・出した結果・縛り・効果・禁止あがり。状態を持たない静的メソッド)、進行状態(`DaifugoState`: 場・革命・縛り・手番。`GameState.daifugo` に入る)、場の 1 回分(`FieldPlay`)、CPU の思考(`DaifugoAI`)、プレイヤー(`DaifugoPlayer`)
- `lib/repository/` API 通信(`ApiClient` インターフェースと実装 `ApiConnection`)、端末保存(`PreferencesRepository`)、リクエスト定義
- `lib/view_models/` `BaseViewModel` を継承。`MainViewModel` が `GameState`(手札・ポイント・山札・捨て札)の持ち主で、状態の変更は必ず `MainViewModel` のメソッド経由(`setMyCards` / `addCards1` / `addPoints` など)。外からは読み取り専用のリストしか見えない
- `lib/views/` 画面と部品。ViewModel は画面遷移時に `ChangeNotifierProvider` で生成し、画面側は `context.watch` で受け取る(画面が自前で new しない)。ポーカー画面は `view_container/poker/` の 3 エリア(相手・中央・自分)に分割。大富豪の部品は `view_container/daifugo/`(場のカード `FieldCards`、Q の数字表 `BomberSelector`、左右ボタン `DaifugoActionButtons`、中央エリア)。結果ダイアログは `GameResultDialog`(ポーカー・大富豪共通)と `FinalResultDialog`(最終結果)。ルール画面は `RulesScreen`(3 タブ。スタート画面の「ルールを見る」と、ポーカー・大富豪画面の AppBar の ? から開く)
- `test/` ユニットテスト 105 件。カード生成は `test/helpers/test_cards.dart` の `hand(['9/S', 'K/H', 'JOKER/B'])`、通信の差し替えは `test/helpers/fake_api_client.dart` の `FakeApiClient` を使う

## コードのルール

- ViewModel と repository に `BuildContext` や `SharedPreferences` を持ち込まない。通信中・エラーは `BaseViewModel` の状態(`isLoading` / `errorMessage`)で表し、画面側の `ApiStateHandler` が表示する
- 複数の通信をまとめる処理は `withLoading` で包み、ぐるぐるが途中で途切れないようにする
- ViewModel は `api:` で通信を差し替えられる(テストでは `FakeApiClient`)。本物の通信を new するのは `BaseViewModel` の既定値だけ
- 演出の待ち時間は `PokerViewModel` の `resultDelay`(既定 2 秒)で、`Timer` を使い `dispose` で止める。テストでは `Duration.zero` を渡す。`DaifugoViewModel` も同様に `cpuDelay`(CPU の行動まで 1 秒)・`resultDelay`・`flowDelay`(場が流れる前に出したカードを見せる 2 秒)、乱数は `random:` で差し替える
- 大富豪のボタン文言・押せるかの判定は `DaifugoViewModel` の `leftButtonLabel` / `rightButtonLabel` / `isRightButtonEnabled` に集約し、画面は表示するだけ(テストで検証できるように)
- 大富豪の進行は `DaifugoPhase`(配布中 / 手番 / 7 の選択 / 10 の選択 / Q の選択 / 決着)で管理。手番は `DaifugoState.turn`。CPU の行動は `_startWaiting` → `_cpuTurn` の `Timer` 経由
- 通信エラーは `ApiConnection` で利用者向けの文言(`AppStrings.networkError` など)に変換する。生の例外文字列は `debugPrint` のみ
- カード画像は `cached_network_image` で端末にキャッシュする
- 画面が長くなったら `view_container/` 配下に部品として切り出す(目安: 1 つの build が 100 行を超えたら)
- 部品(`HandList` など)には ViewModel を丸ごと渡さず、必要な値とコールバックだけ渡す
- lint は `analysis_options.yaml` で厳しめに設定(単一引用符、末尾カンマ、final 推奨、await 漏れ検出など)。`dart fix --apply` で自動修正できるものは直してから解析する
- 画面に出す文言は `AppStrings` に定義する
- カード画像は `CardImage` を使う(固定サイズ 72x100、読み込み失敗時はタップで再読み込み)
- 役判定 `HandEvaluator.evaluate5` は渡したリストを並び替えない(コピーして処理する)
- カードの値は文字列(`"10"`, `"ACE"`)。比較は必ず `parsePorkerRank` / `parseDaifugoRank` で数値にしてから行う(文字列比較のバグが過去にあった)
- コメントは最小限。既存の日本語コメントのスタイルに合わせる
- 新しいファイルは指示があったときだけ作る
- commit / push は明示的に頼まれたときだけ行う

## ドキュメントの更新(毎回)

機能追加・仕様変更・ルール追加のたびに、作業の一部として次を更新する。頼まれなくても行う。

- `README.md`: ルール・仕様の変更、「今後の対応予定」の増減、「開発での AI の使い方」(自分が決めたこと / AI に任せたこと / AI の提案を採用しなかった箇所と理由)
- `CLAUDE.md`: 新しいルール、仕様メモ、環境の注意点、ハマったことと回避方法、今後の予定

## 仕様メモ(コードから読み取りにくいもの)

- デッキはジョーカー 2 枚込みの 54 枚(`jokers_enabled: true`)。手放したカードは山札に戻らない。`MainViewModel.discardedCards` に記録している(山札切れ時に戻すため)
- 役のポイントは `HandRank.point`(役なし・ワンペア 1 〜 ロイヤルフラッシュ 9、ファイブカード 10)
- ジョーカーはワイルドカード。ジョーカー入りの役と素の役は同じ強さ。サドンデスではジョーカーが最強(A より上)
- 判定後の相手の手札は、役を作っているカードだけ表向き(`HandEvaluator.roleCards`。ワンペア〜フォーカードは組のカード、役なし・5 枚で作る役は全部)。`PokerViewModel.openCards1` で画面に渡す
- 引き分けはサドンデス(自分 → CPU の順に 1 枚ずつ引き、裏向き → 「表にする」で判定。同じなら引き直し)
- 演出の待ち時間は 2 秒(交換後の判定・サドンデスの判定とも)。待ち中(`isWaiting`)は戻る操作を含めて画面全体を操作不可にする
- ポイントは結果ダイアログを「閉じる」で反映する(先に反映しない)。画面には「相手: Xpt」「あなた: Xpt」
- ボタン文言: カード未選択「このまま勝負」/ 選択中「カードを交換する」/ 引き分け後「サドンデスへ」→「表にする」/ 決着後「大富豪へ」
- 戻る操作(AppBar / スワイプ)は確認ダイアログを出し、OK なら `resetGame()` してスタート画面へ(大富豪画面からは `popUntil`)
- 並び順: ポーカーはジョーカー先頭 → 枚数の多いランク → 数値の大きい順。大富豪は弱い順(左が弱く右が強い、2 の次にジョーカー)。右のカードが上に重なる
- 難易度は「かんたん」(定石の `SimpleAI`)と「げきつよ」(`AdvancedAI`、`drawCount = 4`)。選択は端末に保存
- 「げきつよ」の方式(4 枚多く引いて 9 枚から最強の 5 枚を選ぶハンデ方式)は README で公開している。経緯(モンテカルロ法 → 相手の手札参照 → ハンデ方式、勝率の数値)も README の「げきつよ CPU ができるまで」に記載。変更したら両方を更新する
- README では「コードを書く AI」は Claude Code、「対戦相手」は CPU と呼び分ける(「AI」とだけ書かない)
- 2 人対戦なので相手のポイントは常に自分の符号反転。人数を増やすときは順位ごとの加減算に拡張する

### 大富豪の仕様(ユーザー決定。README のルールと合わせる)

- 禁止あがりのカードは出せる(選択不可・暗くしない)。上がりを放棄するだけ。禁止あがりで上がったら出した側の負けで ±10 固定(革命倍率なし)。手番開始時に手札が禁止あがりのカードだけなら強制的に負け(±10)。2 を 4 枚で上がるのも禁止(革命は手札 0 の後)
- 5 スキップ: 一周以上なら場が流れて出した人から。2 人では常に流れる(`DaifugoRules.playerCount` で判定)
- パス: 相手がパスしたら場が流れて自分から出し直す
- 縛り: 直前の出し方と全部のスートが一致したときだけ(6♦6♥ → 9♦9♠ は縛りなし)。数縛りは直前のちょうど 1 つ上(逆順中は 1 つ下)。10 → J は数縛りになり、J バックで次は 10 → 9。ジョーカー入りはスート縛りを作らず(3♦3♥ → 4♦+JOKER は数縛りだけ。その後 5♦5♥ でも激縛りにならない)、縛り中でもジョーカーは出せる
- ジョーカーは一緒に出したカードの扱い(3 + JOKER で上がっても OK)。単体・2 や 8 と一緒・スペ 3 入りで上がるのは禁止。革命中もジョーカーが最強。ジョーカーだけの場にジョーカーだけは出せない。スペ 3 返しはジョーカー 1 枚の場だけ
- 革命: 4 枚以上(ジョーカー込み可)。場は流れない。革命返しも回数に数える(倍率は回数 + 1)
- 7 渡し / 10 捨て: パス可(渡さない・捨てない)。手札が 0 になれば上がり(渡したカードにジョーカーがあっても OK)
- Q ボンバー: 出した枚数分の数字を必ず選ぶ(パスなし。未選択時はボタンなし、選択中は左「キャンセル」右「決定」で、枚数が揃うまで決定は無効)。自分のカードも捨てる。手札 0 になった人は上がり。複数人同時なら Q を出した人から手番順に上位(A の Q で A・B・D が上がれば 1 位 A・2 位 B・3 位 D・4 位 C)。2 人では本人 → 相手の順に判定
- 6 ドロー: 自動で引く。山札が足りなければ `discardedCards` を API(`ReturnCardsRequest` → `ShuffleDeckRequest`)で戻してから引き、それでも足りなければ `isDeckExhausted` → ダイアログ → スタート画面。大富豪で場に出した・10 や Q で捨てたカードは山札に戻さない
- CPU の思考(`DaifugoAI`)は難易度に関係なく固定: 出せる中で一番弱い組み合わせ(同じ数字はまとめて出す、ジョーカーは必要なときだけ)。渡す・捨てる・ボンバーは一番弱いカードから。禁止あがりのカードだけが残る手は避け、最後の 1 枚が禁止あがりになるなら場にカードがあるうちはパス
- 画面: 場のカードは山札と残り枚数の右隣に、新しいものほど少し下にずらして重ね(直近 4 回分)、同時に出したカードは横に重ねる。出せないカード(枚数・強さ・縛り)は黒の半透明(`ColorFiltered`、濃さ 0.5)を重ねてタップ不可(`Opacity` だと背景に溶けて読みにくいので不採用)。選択中のカードに合わせて選べるカードが絞られる。相手の行動や効果は中央のメッセージ 1 行で見せる。場が流れるとき(5・8・スペ 3・パス)は流れる前の場を 2 秒見せてから片付ける(`fieldPlays` getter が `_playsBeforeFlow` を優先。その間は操作不可)
- 決着後は相手の手札を表向きにし、2 秒後に結果ダイアログ(残り枚数・革命倍率・±pt)→ 閉じるとポイント反映 → 最終結果ダイアログ(ポーカー・大富豪・合計)→「スタート画面へ」で `resetGame`

## 変更後の確認

```bash
dart analyze
flutter test
flutter build ios --simulator --debug
```

- 変更したら必ず解析・テスト・ビルドを通し、結果を正直に報告する(出力の末尾だけ見て「エラーなし」と言わない)
- `flutter analyze` はフォルダ名(日本語パス)が原因でクラッシュするため `dart analyze` を使う
- `flutter build ios` や `pod` 系コマンドは `LANG=en_US.UTF-8 LC_ALL=en_US.UTF-8` を付けて実行する
- 一時的な検証用テストは `test/tmp_*.dart` に作り、実行後に削除する。恒久的に残す価値があるものは正式なテストにする
- UI の変更はシミュレータ(iPhone 16)で実際に操作して確認する。インストールは `xcrun simctl install` → `xcrun simctl terminate app.pokafugou` → `xcrun simctl launch app.pokafugou`(terminate しないと古いビルドが前面に出るだけで再起動されない)
- 引き分けを手動で再現したいときは `PokerViewModel.resultHands` の先頭に一時的に `mainViewModel.sortedCardList1([...myCardList]);` を入れる(確認後に必ず削除)
- Q ボンバーの数字表を手動で確認したいときは `DaifugoViewModel._startGame` の `_beginTurn()` の前に一時的に `_startSelecting(DaifugoPhase.selectingBomber, 2); return;` を入れる(確認後に必ず削除)
- シミュレータの操作でカードを選んだ直後にボタンを押すと反映前で効かないことがある。1 秒置いてから押す
- AI の強さは必ず対戦シミュレーションで計測してから報告する(「強いはず」で済ませない)。計測は一時テストで行い、勝率・累計ポイント・役分布を出す
- 大富豪のテストでハマりやすい点: 2 人では 5 を出すと場が流れる(「場に 5 がある状態」は作れない)、`3/S` はスペ 3 で禁止あがり扱い、同じスートを続けて出すと縛りが発生する。場を作るときは 4・9・10・K など効果のない数字を使う
- 大富豪の API 通信が途中で失敗した場合(6 のドローなど)はエラーダイアログを出すだけで、効果は未完了のまま手番が止まる(再開の仕組みはない)

## この環境の注意点

- 対象は iOS / Android のみ。`macos/` `linux/` `windows/` `web/` は削除済み(必要になれば `flutter create . --platforms=macos` などで再生成)
- iOS は Swift Package Manager でプラグインを管理している。CocoaPods は使わない(Podfile なし)
- Android は Flutter テンプレートと同じ構成(Gradle 9.1.0 / AGP 9.0.1 / Kotlin 2.3.20 組み込み / Java 17)。更新時はテンプレートに揃える
- Flutter が実機ビルド時に `ios/Runner.xcodeproj/project.pbxproj` へ `DEVELOPMENT_TEAM` を書き戻す。commit 前にその行を除外する
- git の作者情報はリポジトリローカルで GitHub の noreply アドレスに設定済み。グローバル設定(会社メール)を使わない
- GitHub のリモート名は `github`(`origin` は Bitbucket)。push 先は `github main`
- push 前に秘密情報・個人パス・不要ファイルの混入をチェックする
- バンドル ID は `app.pokafugou`(iOS / Android 共通。本名を含めない方針)。アプリアイコンは未着手(保留中)

## 今後の予定

- 大富豪の CPU の強さを難易度で分ける(今は `DaifugoAI` が固定。分けるときは対戦シミュレーションで計測する)
- 途中から再開する機能(スタート画面に「続きから」ボタン)。`GameState`(手札・ポイント・山札・捨て札・`daifugo`)に加えて `DaifugoPhase` と選択中の枚数の保存が必要で、戻るボタンの挙動も「中断」に変わる
- 1 対 1 以外(人数追加)。`DaifugoPlayer` を人数対応にし、5 スキップの一周判定(`playerCount`)、Q ボンバーの同時上がりの順位(出した人から手番順)、順位ごとの加減算を拡張する。相手の交換枚数の分析、オンライン対戦
