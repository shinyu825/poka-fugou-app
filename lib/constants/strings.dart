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
  static const String settings = '設定';
  static const String exit = '終了';
  static const String ok = 'OK';
  static const String error = '通信エラー';
  static const String drawError = 'ドローエラー';
  static const String back = "閉じる";
  static const String cancel = 'キャンセル';

  // 戻る確認
  static const String backConfirmTitle = '最初からになります';
  static const String backConfirmMessage =
      'ゲームスタート画面に戻ると、ゲームは最初からやり直しになります。\n戻ってもよろしいですか？';

  // ゲーム関連
  static const String startGame = 'ゲームスタート';
  static const String nocard = 'カードがありません';
  static const String cardDraw = 'カードドロー';
  static const String exchange = 'カードを交換する';
  static const String daifugo = '大富豪へ';
  static const String myHand = 'あなたの役：';
  static const String player1Hand = '相手の役：';
  static const String youWin = 'You WIN.';
  static const String youLose = 'You LOSE.';
  static const String draw = 'DRAW.';
  static const String put = 'カードを出す';
  static String remaining(int count) => '残り: $count枚';
  static const String pass = 'パス';
}
