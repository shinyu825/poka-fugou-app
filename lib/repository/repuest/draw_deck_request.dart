import 'dart:async';
import 'package:flutter/material.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:poka_fugou_app/constants/strings.dart';
import 'package:poka_fugou_app/models/api/draw_response.dart';
import 'package:poka_fugou_app/repository/request_interface.dart';
import 'package:poka_fugou_app/models/api/response.dart';
import 'package:poka_fugou_app/views/view_container/dialog/error_dialog.dart';

// カードドローリクエスト
@JsonSerializable()
class DrawDeckRequest extends RequestInterface<DrawResponse> {
  final String deckId;
  final int cardCount;
  DrawDeckRequest({required this.deckId, required this.cardCount});

  @override
  String get method => "GET";
  @override
  String get segment => '$deckId/draw';
  @override
  Map<String, dynamic>? get data => {"count": cardCount};

  @override
  DrawResponse parse(Map<String, dynamic> json) => DrawResponse.fromJson(json);

  @override
  Future<void> error(
    BuildContext context,
    ApiError error,
    Completer<DrawResponse?> completer,
  ) async {
    if (!context.mounted) return;
    await showErrorDialog(context, AppStrings.error, error.error);
  }
}
