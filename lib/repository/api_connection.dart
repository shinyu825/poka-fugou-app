import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:poka_fugou_app/constants/strings.dart';
import 'package:poka_fugou_app/models/api/response.dart';
import 'package:poka_fugou_app/repository/request_interface.dart';

/// API通信の結果（成功ならdata、失敗ならerror）
class ApiResult<T> {
  final T? data;
  final String? error;

  const ApiResult.success(this.data) : error = null;
  const ApiResult.failure(this.error) : data = null;

  bool get isSuccess => error == null;
}

/// API通信のインターフェース（テストでは差し替える）
abstract class ApiClient {
  Future<ApiResult<T>> request<T>(RequestInterface<T> request);
}

/// API通信
class ApiConnection implements ApiClient {
  static final Dio _dio = Dio(
    BaseOptions(
      baseUrl: AppStrings.baseUrl,
      headers: const {'Content-Type': 'application/json; charset=utf-8'},
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 10),
    ),
  );

  /// API実行（画面には触らず、結果だけを返す。エラーは利用者向けの文言に変換する）
  @override
  Future<ApiResult<T>> request<T>(RequestInterface<T> request) async {
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
      if (json['success'] == true) {
        debugPrint('成功 ${request.segment}');
        return ApiResult.success(request.parse(json));
      }
      debugPrint('失敗 ${request.segment}: ${ApiError.fromJson(json).error}');
      return const ApiResult.failure(AppStrings.serverError);
    } on DioException catch (e) {
      debugPrint('通信エラー ${request.segment}: ${e.message}');
      return const ApiResult.failure(AppStrings.networkError);
    } catch (e) {
      debugPrint('例外 ${request.segment}: $e');
      return const ApiResult.failure(AppStrings.unexpectedError);
    }
  }
}
