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
  static const String put = 'カードを出す';
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
}
