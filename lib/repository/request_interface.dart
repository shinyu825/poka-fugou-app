/// リクエストインターフェース
abstract class RequestInterface<T> {
  /// "GET" | "POST" など
  String get method;

  /// 例: "new/shuffle"
  String get segment;

  /// クエリやボディの元データ
  Map<String, dynamic>? get data;

  /// success==true のときに JSON から目的の T を作る
  T parse(Map<String, dynamic> json);
}
