import 'dart:async';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:poka_fugou_app/constants/strings.dart';
import 'package:poka_fugou_app/models/api/response.dart';
import 'package:poka_fugou_app/repository/request_interface.dart';
import 'package:poka_fugou_app/views/view_container/dialog/progress_dialog.dart';

/// API通信
class ApiConnection {
  static final Dio _dio = Dio(
    BaseOptions(
      baseUrl: AppStrings.baseUrl,
      headers: const {'Content-Type': 'application/json; charset=utf-8'},
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 10),
    ),
  );

  /// API開始
  ///
  /// [request] リクエストデータ
  /// [isShowProgress] 通信中ダイアログを表示させるかどうか
  Future<T?> startRequest<T>(
    BuildContext context,
    RequestInterface<T> request, {
    bool isShowProgress = true,
  }) async {
    if (isShowProgress) {
      showProgressDialog(context);
    }
    final completer = Completer<T?>();
    () async {
      try {
        Response response;

        switch (request.method) {
          case 'GET':
            response = await _dio.get(
              request.segment,
              queryParameters: request.data,
            );
            break;
          case 'POST':
            response = await _dio.post(request.segment, data: request.data);
            break;
          case 'PUT':
            response = await _dio.put(request.segment, data: request.data);
            break;
          default:
            response = await _dio.delete(request.segment, data: request.data);
            break;
        }

        final json = response.data as Map<String, dynamic>;
        if (json["success"]) {
          debugPrint('成功 ${request.segment}');
          completer.complete(request.parse(json));
        } else {
          if (!context.mounted) return;
          debugPrint('失敗 ${request.segment}');
          final error = ApiError(json["success"], json["error"]);
          await request.error(context, error, completer);
          completer.complete(null);
        }
      } catch (e) {
        if (!context.mounted) return;
        debugPrint('例外 ${e.toString()}');
        final error = ApiError(false, e.toString());
        await request.error(context, error, completer);
        completer.complete(null);
      } finally {
        if (isShowProgress) {
          if (context.mounted) {
            dismissProgressDialog(context);
          }
        }
      }
    }();
    return completer.future;
  }
}
