// lib/services/api_service.dart

import 'dart:async';
import 'package:dio/dio.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:curemate/utils/logger.dart';
import 'package:curemate/app/token_manager.dart';
import 'auth_service.dart';

class ApiService {
  // 싱글톤 패턴
  static final ApiService _instance = ApiService._internal();
  factory ApiService() => _instance;

  final Dio _dio;
  final TokenManager _tokenManager = TokenManager();

  bool _isRefreshing = false;
  Completer<String?>? _refreshCompleter;

  // private 생성자: 외부에서 new 불가
  ApiService._internal() : _dio = Dio() {
    _dio.options.baseUrl = dotenv.env['BASE_URL']!;
    _dio.options.connectTimeout = const Duration(seconds: 10);
    _dio.options.receiveTimeout = const Duration(seconds: 10);

    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          // Refresh 요청은 인터셉터 스킵
          if (options.path.contains('/loginRefresh')) {
            return handler.next(options);
          }

          final accessToken = await _tokenManager.getAccessToken();
          final refreshToken = await _tokenManager.getRefreshToken();

          if (accessToken != null) {
            options.headers['Authorization'] = 'Bearer $accessToken';
          }
          if (refreshToken != null) {
            options.headers['RefreshToken'] = 'Bearer $refreshToken';
          }

          // 요청 로그
          Logger.httpRequest(
            method: options.method,
            url: options.uri.toString(),
            headers: options.headers,
            body: options.data,
            tag: 'API',
          );

          return handler.next(options);
        },

        onResponse: (response, handler) {
          Logger.httpResponse(
            statusCode: response.statusCode ?? 0,
            url: response.requestOptions.uri.toString(),
            headers: response.headers.map,
            body: response.data,
            tag: 'API',
          );
          return handler.next(response);
        },

        onError: (DioException e, handler) async {
          // 에러 로그
          Logger.e(
            'API 에러',
            tag: 'API',
            error: e,
            data: {
              'url': e.requestOptions.uri.toString(),
              'method': e.requestOptions.method,
              'statusCode': e.response?.statusCode,
              'message': e.message,
            },
          );

          final originalRequest = e.requestOptions;
          final is401 = e.response?.statusCode == 401;

          // Refresh 요청 자체가 401이면 바로 로그아웃
          if (is401 && originalRequest.path.contains('/loginRefresh')) {
            await _handleLogoutAndRedirect();
            return handler.reject(e);
          }

          if (is401) {
            final accessToken = await _tokenManager.getAccessToken();
            final refreshToken = await _tokenManager.getRefreshToken();

            if (accessToken == null || refreshToken == null) {
              await _handleLogoutAndRedirect();
              return handler.reject(e);
            }

            // 갱신 중이면 대기
            if (_isRefreshing && _refreshCompleter != null) {
              print('토큰 갱신 대기 중: ${originalRequest.path}');

              try {
                final newAccessToken = await _refreshCompleter!.future;
                originalRequest.headers['Authorization'] =
                'Bearer $newAccessToken';
                return handler.resolve(await _dio.fetch(originalRequest));
              } catch (refreshError) {
                return handler.reject(e);
              }
            }

            // 갱신 시작
            _isRefreshing = true;
            _refreshCompleter = Completer<String?>();

            try {
              print('Access Token 만료 감지, 갱신 시작...');

              // AuthService 싱글톤 인스턴스 사용
              final refreshResponse = await AuthService().refreshLogin(
                accessToken,
                refreshToken,
              );

              final newAccessToken = refreshResponse.accessToken;
              final newRefreshToken = refreshResponse.refreshToken;

              if (newAccessToken == null || newRefreshToken == null) {
                throw Exception('갱신된 토큰이 유효하지 않습니다.');
              }

              await _tokenManager.saveAccessToken(newAccessToken);
              await _tokenManager.saveRefreshToken(newRefreshToken);

              _refreshCompleter!.complete(newAccessToken);

              originalRequest.headers['Authorization'] = 'Bearer $newAccessToken';
              final response = await _dio.fetch(originalRequest);

              return handler.resolve(response);

            } catch (refreshError) {
              print('Refresh Token 갱신 실패: $refreshError');

              if (!_refreshCompleter!.isCompleted) {
                _refreshCompleter!.completeError(refreshError);
              }

              await _handleLogoutAndRedirect();
              return handler.reject(e);

            } finally {
              _isRefreshing = false;
              _refreshCompleter = null;
            }
          }

          return handler.next(e);
        },
      ),
    );
  }

  Future<Response> get(String path, {Map<String, dynamic>? queryParameters}) async {
    try {
      return await _dio.get(path, queryParameters: queryParameters);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<Response> post(String path, {dynamic data}) async {
    try {
      return await _dio.post(path, data: data);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<Response> put(String path, {Map<String, dynamic>? data}) async {
    try {
      return await _dio.put(path, data: data);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<Response> delete(String path) async {
    try {
      return await _dio.delete(path);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  String _handleError(DioException error) {
    if (error.response != null) {
      final statusCode = error.response?.statusCode;
      final message = error.response?.statusMessage;
      final data = error.response?.data;

      return "Error $statusCode: $message${data != null ? '\n$data' : ''}";
    } else if (error.type == DioExceptionType.connectionTimeout) {
      return "연결 시간 초과";
    } else if (error.type == DioExceptionType.receiveTimeout) {
      return "응답 시간 초과";
    } else {
      return "네트워크 오류: ${error.message}";
    }
  }

  String get baseUrl => _dio.options.baseUrl;

  Future<void> _handleLogoutAndRedirect() async {
    await _tokenManager.deleteToken();
    // TODO: 로그인 페이지로 리디렉션
  }
}