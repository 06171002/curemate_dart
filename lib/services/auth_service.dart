// lib/services/auth_service.dart

import 'package:dio/dio.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../app/token_manager.dart';
import 'api_service.dart';

class SocialLoginRequest {
  final String provider;
  final String token;
  final String? fcmToken;
  final String? deviceId;
  final String? appName;
  final String? platform;

  SocialLoginRequest({
    required this.provider,
    required this.token,
    this.fcmToken,
    this.deviceId,
    this.appName,
    this.platform,
  });

  Map<String, dynamic> toJson() {
    return {
      'provider': provider,
      'token': token,
      if (fcmToken != null) 'fcmToken': fcmToken,
      if (deviceId != null) 'deviceId': deviceId,
      if (appName  != null) 'appName' : appName,
      if (platform != null) 'platform': platform,
    };
  }
}

class AuthResponse {
  final String accessToken;
  final String refreshToken;
  final int custSeq;
  final String custNm;
  final String? custEmail;

  AuthResponse({
    required this.accessToken,
    required this.refreshToken,
    required this.custSeq,
    required this.custNm,
    this.custEmail,
  });

  factory AuthResponse.fromJson(Map<String, dynamic> json) {
    return AuthResponse(
      accessToken: json['accessToken'] as String,
      refreshToken: json['refreshToken'] as String,
      custSeq: json['custSeq'] as int,
      custNm: json['custNm'] as String,
      custEmail: json['custEmail'] as String?,
    );
  }
}

class AuthService {
  // 싱글톤 패턴
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;

  final ApiService _apiService;
  final TokenManager _tokenManager = TokenManager();

  AuthService._internal() : _apiService = ApiService();

  /// 통합 소셜 로그인 API 호출
  Future<AuthResponse> socialLogin(SocialLoginRequest request) async {
    try {
      final Map<String, dynamic> apiVoPayload = {
        'param': request.toJson()
      };

      final Response response = await _apiService.post(
        '/api/auth/social-login',
        data: apiVoPayload,
      );

      final apiData = response.data['data'] as Map<String, dynamic>?;

      if (apiData == null) {
        throw Exception('API 응답에 data 필드가 없습니다.');
      }

      final authResponse = AuthResponse.fromJson(apiData);

      // 로그인 성공 시 토큰 저장
      await _tokenManager.saveAccessToken(authResponse.accessToken);
      await _tokenManager.saveRefreshToken(authResponse.refreshToken);

      return authResponse;

    } on DioException catch (dioErr) {
      final data = dioErr.response?.data;
      if (data is Map && data['message'] != null) {
        throw Exception(data['message']);
      }
      throw Exception(dioErr.message ?? '로그인 중 네트워크 오류가 발생했습니다.');
    } catch (e) {
      rethrow;
    }
  }

  /// Refresh Token을 이용한 Access Token 갱신 (별도 Dio 인스턴스 사용)
  Future<AuthResponse> refreshLogin(String accessToken, String refreshToken) async {
    // 인터셉터 우회를 위해 별도 Dio 인스턴스 생성
    final dio = Dio(BaseOptions(
      baseUrl: dotenv.env['BASE_URL']!,
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 10),
    ));

    try {
      final Response response = await dio.post(
        '/api/loginRefresh',
        options: Options(
          headers: {
            'Authorization': 'Bearer $accessToken',
            'RefreshToken': 'Bearer $refreshToken',
          },
        ),
      );

      final apiData = response.data['data'] as Map<String, dynamic>?;

      if (apiData == null) {
        throw Exception('API 응답에 data 필드가 없습니다.');
      }

      return AuthResponse.fromJson(apiData);

    } on DioException catch (dioErr) {
      print('RefreshLogin DioException: ${dioErr.response?.statusCode}');

      final data = dioErr.response?.data;
      if (data is Map && data['message'] != null) {
        throw Exception(data['message']);
      }
      throw Exception(dioErr.message ?? '토큰 갱신 중 네트워크 오류가 발생했습니다.');
    } catch (e) {
      print('RefreshLogin Error: $e');
      rethrow;
    }
  }

  /// 로그아웃
  Future<void> logout() async {
    try {
      await _apiService.post('/api/auth/logout');
    } catch (e) {
      print('로그아웃 API 호출 실패: $e');
    } finally {
      await _tokenManager.deleteToken();
    }
  }
}