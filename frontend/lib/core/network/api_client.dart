import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../config/app_config.dart';
import '../storage/token_storage.dart';
import 'api_failure.dart';

class ApiClient {
  ApiClient({required this._storage, Dio? dio})
      : _dio = dio ?? Dio() {
    _dio.options
      ..baseUrl = AppConfig.apiBaseUrl
      ..connectTimeout = AppConfig.connectTimeout
      ..receiveTimeout = AppConfig.receiveTimeout
      ..headers['Accept'] = 'application/json';

    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          final token = _storage.token;
          if (token != null && token.isNotEmpty) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          handler.next(options);
        },
        onError: (e, handler) {
          if (e.response?.statusCode == 401) {
            onUnauthorized?.call();
          }
          handler.next(e);
        },
      ),
    );

    if (kDebugMode) {
      _dio.interceptors.add(LogInterceptor(
        requestBody: false,
        responseBody: false,
        logPrint: (o) => debugPrint('[api] $o'),
      ));
    }
  }

  final Dio _dio;
  final TokenStorage _storage;

  void Function()? onUnauthorized;

  Future<dynamic> get(String path, {Map<String, dynamic>? query}) =>
      _request(() => _dio.get(path, queryParameters: query), retry: true);



  Future<List<int>> getBytes(String path) async {
    try {
      final res = await _dio.get<List<int>>(
        path,
        options: Options(responseType: ResponseType.bytes),
      );
      return res.data ?? const [];
    } on DioException catch (e) {
      throw _map(e);
    }
  }

  Future<dynamic> post(String path, {Object? data, Duration? receiveTimeout}) =>
      _request(() => _dio.post(
            path,
            data: data,
            options: receiveTimeout == null
                ? null
                : Options(receiveTimeout: receiveTimeout),
          ));

  Future<dynamic> patch(String path, {Object? data}) =>
      _request(() => _dio.patch(path, data: data));

  Future<dynamic> put(String path, {Object? data}) =>
      _request(() => _dio.put(path, data: data));

  Future<dynamic> delete(String path, {Object? data}) =>
      _request(() => _dio.delete(path, data: data));

  Future<dynamic> postMultipart(String path, {required FormData data}) =>
      _request(() => _dio.post(path, data: data));

  Future<dynamic> _request(
    Future<Response> Function() run, {
    bool retry = false,
  }) async {
    try {
      final res = await run();
      return res.data;
    } on DioException catch (e) {
      final isRetryable = e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.receiveTimeout ||
          e.type == DioExceptionType.connectionError;
      if (retry && isRetryable) {
        try {
          final res = await run();
          return res.data;
        } on DioException catch (e2) {
          throw _map(e2);
        }
      }
      throw _map(e);
    }
  }

  ApiFailure _map(DioException e) {
    switch (e.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return const ApiFailure(
          code: 'timeout',
          message: 'The server took too long to respond. Check the backend is running.',
        );
      case DioExceptionType.connectionError:
        return const ApiFailure(
          code: 'network',
          message: 'Cannot reach the site server. Is the backend running on port 8000?',
        );
      default:
        final data = e.response?.data;
        final status = e.response?.statusCode;
        if (data is Map && data['error'] is Map) {
          final err = data['error'] as Map;
          return ApiFailure(
            code: (err['code'] ?? 'error').toString(),
            message: (err['message'] ?? 'Something went wrong.').toString(),
            statusCode: status,
          );
        }
        return ApiFailure(
          code: 'error',
          message: 'Request failed (${status ?? 'unknown'}).',
          statusCode: status,
        );
    }
  }
}
