class AppStrings {
  // APIベースURL
  static const String baseUrl = 'https://deckofcardsapi.com/api/deck/';
  static const String cardBackUrl =
      'https://deckofcardsapi.com/static/img/back.png';

  // タイトル
  static const String appTitle = 'ポカ富豪';
  static const String pokerTitle = 'ポーカー';
  static const String daifugoTitle = '大富豪';

  // 汎用
  static const String ok = 'OK';
  static const String error = '通信エラー';
  static const String networkError = '通信に失敗しました。電波状況を確認して、もう一度お試しください。';
  static const String serverError = 'カードの取得に失敗しました。もう一度お試しください。';
  static const String unexpectedError = '予期しないエラーが発生しました。';
  static const String back = '閉じる';
  static const String cancel = 'キャンセル';

  // 戻る確認
  static const String backConfirmTitle = '最初からになります';
  static const String backConfirmMessage =
      'ゲームスタート画面に戻ると、ゲームは最初からやり直しになります。\n戻ってもよろしいですか？';

  // 難易度
  static const String easy = 'かんたん';
  static const String hard = 'げきつよ';

  // ゲーム関連
  static const String startGame = 'ゲームスタート';
  static const String nocard = 'カードがありません';
  static const String cardDraw = 'カードドロー';
  static const String exchange = 'カードを交換する';
  static const String fightAsIs = 'このまま勝負';
  static const String daifugo = '大富豪へ';
  static const String suddenDeath = 'サドンデスへ';
  static const String openCards = '表にする';
  static const String myHand = 'あなたの役：';
  static const String player1Hand = '相手の役：';
  static const String youWin = 'You WIN.';
  static const String youLose = 'You LOSE.';
  static const String draw = 'DRAW.';
  static const String put = '出す';
  static String remaining(int count) => '残り: $count枚';
  static String myPoint(int point) => 'あなた: ${point}pt';
  static String opponentPoint(int point) => '相手: ${point}pt';
  static const String imageLoadFailed = '読み込み失敗';
  static const String tapToReload = 'タップで再読み込み';
  static String tieBreakHand(String hand, String card) => '$hand / 決着: $card';
  static String pointDelta(int delta) {
    if (delta > 0) return '+${delta}pt';
    if (delta < 0) return '${delta}pt';
    return '±0pt';
  }

  static const String pass = 'パス';

  // ルール
  static const String rulesTitle = 'ルール';
  static const String showRules = 'ルールを見る';

  // 大富豪
  static const String give = '渡す';
  static const String discard = '捨てる';
  static const String decide = '決定';
  static const String you = 'あなた';
  static const String opponent = '相手';
  static String startByDiamondThree(String who) => '♦3 を持っている$whoから開始';
  static String startByRandom(String who) => 'ランダムで$whoから開始';
  static String played(String who, String cards) => '$who: $cards';
  static String passed(String who) => '$who: パス';
  static const String revolution = '革命！';
  static const String backEffect = 'J バック';
  static const String cutEffect = '8 切り';
  static const String skipEffect = '5 スキップ';
  static const String spadeThreeReturn = 'スペ 3 返し';
  static String drawEffect(String who, int count) => '$whoが 6 で $count 枚引いた';
  static String receivedCards(int count) => '相手から $count 枚もらった';
  static String gaveCards(String who, int count) => '$whoが $count 枚渡した';
  static String discardedCards(String who, int count) => '$whoが $count 枚捨てた';
  static String bombed(String who, String values) => '$whoのボンバー: $values';
  static String noEffect(String who) => '$whoは何もしなかった';
  static String forbiddenOnly(String who) => '$whoの手札は禁止あがりのカードだけ';
  static String selectGive(int count) => '相手に渡すカードを $count 枚まで選ぶ';
  static String selectDiscard(int count) => '捨てるカードを $count 枚まで選ぶ';
  static String selectBomber(int count) => 'ボンバーする数字を $count 個選ぶ';
  static String remainingCards(String who, int count) => '$whoの残り: $count 枚';
  static String revolutionBonus(int count, int multiplier) =>
      '革命 $count 回（×$multiplier）';
  static const String forbiddenFinish = '禁止あがり（±10pt 固定）';
  static const String finalResultTitle = '最終結果';
  static const String finalWin = 'あなたの勝ち！';
  static const String finalLose = '相手の勝ち';
  static const String finalDraw = '引き分け';
  static const String total = '合計';
  static const String toStart = 'スタート画面へ';
  static const String deckExhaustedTitle = '山札切れ';
  static const String deckExhaustedMessage =
      '山札が足りなくなりました。ゲームを終了してスタート画面に戻ります。';
}
