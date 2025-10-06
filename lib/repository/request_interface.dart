import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:poka_fugou_app/models/api/response.dart';

abstract class RequestInterface<T> {
  // "GET" | "POST" など
  String get method;

  // 例: "new/shuffle"
  String get segment;

  // クエリやボディの元データ
  Map<String, dynamic>? get data;

  // GETパラメータ用のJSON（必要ならbodyにも流用）
  String getRequestJson() => jsonEncode(data ?? {});

  // success==true のときに JSON から目的の T を作る
  T parse(Map<String, dynamic> json);

  // エラー時に呼ばれる
  Future<void> error(
    BuildContext context,
    ApiError error,
    covariant Completer<T?> completer,
  );
}
