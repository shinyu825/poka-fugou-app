import 'package:flutter/foundation.dart';
import 'package:poka_fugou_app/repository/api_connection.dart';
import 'package:poka_fugou_app/repository/request_interface.dart';

/// 通信中・エラーの状態を持つViewModelの共通部分
abstract class BaseViewModel extends ChangeNotifier {
  final ApiClient _api;

  /// [api] はテスト用に差し替え可能（省略時は本物の通信）
  BaseViewModel({ApiClient? api}) : _api = api ?? ApiConnection();

  /// 通信中の処理の数（0より大きければ通信中）
  int _loadingCount = 0;

  /// 通信中かどうか（画面側でぐるぐる表示に使う）
  bool get isLoading => _loadingCount > 0;

  /// エラーメッセージ（画面側でダイアログ表示に使う。表示後にclearErrorで消す）
  String? errorMessage;

  /// 複数の通信をまとめて1つの「通信中」として実行する
  Future<T> withLoading<T>(Future<T> Function() action) async {
    _loadingCount++;
    notifyListeners();
    try {
      return await action();
    } finally {
      _loadingCount--;
      notifyListeners();
    }
  }

  /// APIを実行し、成功ならレスポンスを返す（失敗ならnullを返しエラーを保持）
  Future<T?> runApi<T>(RequestInterface<T> request) {
    return withLoading(() async {
      final result = await _api.request(request);
      if (!result.isSuccess) {
        errorMessage = result.error;
      }
      return result.data;
    });
  }

  void clearError() {
    errorMessage = null;
    notifyListeners();
  }
}
