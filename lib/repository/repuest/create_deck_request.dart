import 'dart:async';
import 'package:flutter/material.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:poka_fugou_app/constants/strings.dart';
import 'package:poka_fugou_app/models/api/create_deck_response.dart';
import 'package:poka_fugou_app/repository/request_interface.dart';
import 'package:poka_fugou_app/models/api/response.dart';
import 'package:poka_fugou_app/views/view_container/dialog/error_dialog.dart';

// 新規デッキ取得リクエスト
@JsonSerializable()
class CreateDeckRequest extends RequestInterface<CreateDeckResponse> {
  final int deckCount;
  CreateDeckRequest({required this.deckCount});

  @override
  String get method => "GET";
  @override
  String get segment => "new/shuffle";
  @override
  Map<String, dynamic>? get data => {"deck_count": deckCount};

  @override
  CreateDeckResponse parse(Map<String, dynamic> json) =>
      CreateDeckResponse.fromJson(json);

  @override
  Future<void> error(
    BuildContext context,
    ApiError error,
    Completer<CreateDeckResponse?> completer,
  ) async {
    if (!context.mounted) return;
    await showErrorDialog(context, AppStrings.error, error.error);
  }
}
