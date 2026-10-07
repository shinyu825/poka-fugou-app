import 'package:poka_fugou_app/constants/difficulty.dart';
import 'package:poka_fugou_app/models/api/playing_card.dart';
import 'package:poka_fugou_app/models/game_state.dart';
import 'package:poka_fugou_app/repository/preferences_repository.dart';
import 'package:poka_fugou_app/repository/repuest/create_deck_request.dart';
import 'package:poka_fugou_app/view_models/base_viewmodel.dart';

/// メインViewModel（ゲーム全体で共有する状態の持ち主。状態の変更はここ経由で行う）
class MainViewModel extends BaseViewModel {
  final PreferencesRepository _preferences;

  MainViewModel({super.api, PreferencesRepository? preferences})
    : _preferences = preferences ?? PreferencesRepository();

  /// ゲームの状態
  GameState _state = const GameState();
  GameState get state => _state;

  String get deckId => _state.deckId;
  List<PlayingCard> get myCardList => List.unmodifiable(_state.myCards);
  List<PlayingCard> get cardList1 => List.unmodifiable(_state.cards1);
  int get remaining => _state.remaining;
  List<PlayingCard> get discardedCards =>
      List.unmodifiable(_state.discardedCards);
  int get myPoint => _state.myPoint;
  int get point1 => _state.point1;

  /// 難易度
  Difficulty difficulty = Difficulty.easy;

  /// 保存済みの難易度を読み込む
  Future<void> loadDifficulty() async {
    difficulty = await _preferences.loadDifficulty();
    notifyListeners();
  }

  /// 難易度を変更して保存する
  Future<void> setDifficulty(Difficulty value) async {
    difficulty = value;
    notifyListeners();
    await _preferences.saveDifficulty(value);
  }

  /// ゲームをリセット
  void resetGame() {
    _update(const GameState());
  }

  /// 新規デッキ作成（成功したらtrue）
  Future<bool> createDeck() async {
    final response = await runApi(CreateDeckRequest(deckCount: 1));
    if (response == null) return false;
    _update(
      const GameState().copyWith(
        deckId: response.deckId,
        remaining: response.remaining,
      ),
    );
    return true;
  }

  /// 自分の手札を差し替える
  void setMyCards(List<PlayingCard> cards) {
    _update(_state.copyWith(myCards: List.unmodifiable(cards)));
  }

  /// 相手の手札を差し替える
  void setCards1(List<PlayingCard> cards) {
    _update(_state.copyWith(cards1: List.unmodifiable(cards)));
  }

  /// 自分の手札に追加
  void addMyCards(List<PlayingCard> cards) {
    setMyCards([..._state.myCards, ...cards]);
  }

  /// 相手の手札に追加
  void addCards1(List<PlayingCard> cards) {
    setCards1([..._state.cards1, ...cards]);
  }

  /// 山札の残り枚数を更新
  void updateRemaining(int count) {
    _update(_state.copyWith(remaining: count));
  }

  /// 手放したカードを記録
  void addDiscardedCards(List<PlayingCard> cards) {
    _update(
      _state.copyWith(
        discardedCards: List.unmodifiable([..._state.discardedCards, ...cards]),
      ),
    );
  }

  /// ポイントを加算（マイナスも可）
  void addPoints({required int my, required int player1}) {
    _update(
      _state.copyWith(
        myPoint: _state.myPoint + my,
        point1: _state.point1 + player1,
      ),
    );
  }

  void _update(GameState state) {
    _state = state;
    notifyListeners();
  }
}
