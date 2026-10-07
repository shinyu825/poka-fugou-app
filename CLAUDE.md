# ポカ富豪 (poka_fugou_app)

ポーカーと大富豪を組み合わせたトランプゲームの Flutter アプリ。ルールの詳細は README.md を参照。
ユーザーはアプリエンジニア(Kotlin / SwiftUI / Flutter 経験あり)。インフラ・バックエンドの説明は初心者向けに。

## 構成 (MVVM)

- `lib/constants/` 文言(`AppStrings`)、役(`HandRank`)、難易度(`Difficulty`)
- `lib/models/` 役判定(`HandEvaluator`)、AI(`SimpleAI` / `AdvancedAI`)、API レスポンス、カード(`PlayingCard`)、ゲーム状態(`GameState`)
- `lib/repository/` API 通信(`ApiClient` インターフェースと実装 `ApiConnection`)、端末保存(`PreferencesRepository`)、リクエスト定義
- `lib/view_models/` `BaseViewModel` を継承。`MainViewModel` が `GameState`(手札・ポイント・山札・捨て札)の持ち主で、状態の変更は必ず `MainViewModel` のメソッド経由(`setMyCards` / `addCards1` / `addPoints` など)。外からは読み取り専用のリストしか見えない
- `lib/views/` 画面と部品。ViewModel は画面遷移時に `ChangeNotifierProvider` で生成し、画面側は `context.watch` で受け取る(画面が自前で new しない)。ポーカー画面は `view_container/poker/` の 3 エリア(相手・中央・自分)に分割
- `test/` ユニットテスト 46 件。カード生成は `test/helpers/test_cards.dart` の `hand(['9/S', 'K/H', 'JOKER/B'])`、通信の差し替えは `test/helpers/fake_api_client.dart` の `FakeApiClient` を使う

## コードのルール

- ViewModel と repository に `BuildContext` や `SharedPreferences` を持ち込まない。通信中・エラーは `BaseViewModel` の状態(`isLoading` / `errorMessage`)で表し、画面側の `ApiStateHandler` が表示する
- 複数の通信をまとめる処理は `withLoading` で包み、ぐるぐるが途中で途切れないようにする
- ViewModel は `api:` で通信を差し替えられる(テストでは `FakeApiClient`)。本物の通信を new するのは `BaseViewModel` の既定値だけ
- 演出の待ち時間は `PokerViewModel` の `resultDelay`(既定 2 秒)で、`Timer` を使い `dispose` で止める。テストでは `Duration.zero` を渡す
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
- AI の強さは必ず対戦シミュレーションで計測してから報告する(「強いはず」で済ませない)。計測は一時テストで行い、勝率・累計ポイント・役分布を出す

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

- 大富豪のゲーム進行。ユーザー指定の UI 仕様:
  - 自分のターン以外はボタン非表示。相手が出していて未選択なら左「パス」のみ。選択中は左「キャンセル」右「出す」。自分が最初に出す番で未選択なら両方非表示
  - 10(捨て)/ 7(渡し)はカードをタップで浮かせて選択。未選択は左「パス」のみ、選択中は左「キャンセル」右「捨てる」/「渡す」。選択可能枚数は出した枚数まで(上限に達したら再タップで外さないと選べない)
  - Q(ボンバー)は電卓風の数字表(2,A,K,J / 10,9,8,7 / 6,5,4,3。Q とジョーカーは出さない)。タップで明るく。未選択は左「パス」、選択中は左「キャンセル」右「決定」。選択数は出した枚数まで
- 山札切れ時に `discardedCards` を API で山札に戻してシャッフル。それでも足りなければダイアログを出してスタート画面へ
- 途中から再開する機能(スタート画面に「続きから」ボタン)。ゲーム状態(手札・ポイント・山札・捨て札・進行段階)の保存が必要で、戻るボタンの挙動も「中断」に変わる。大富豪実装後に設計する
- 1 対 1 以外(人数追加)、相手の交換枚数の分析、オンライン対戦、ジョーカーの大富豪での扱い
