// lib/services/auth_service.dart

import 'package:dio/dio.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:curemate/app/token_manager.dart';
import 'package:curemate/features/auth/model/customer_model.dart';
import 'package:curemate/services/api_service.dart';

class SocialLoginRequest {
  final String provider;
  final String token;
  final String? fcmToken;
  final String? deviceId;
  final String? appName;
  final String? platform;

  // 애플만 사용
  final String? name;
  final String? email;

  SocialLoginRequest({
    required this.provider,
    required this.token,
    this.fcmToken,
    this.deviceId,
    this.appName,
    this.platform,
    this.name,
    this.email,
  });

  Map<String, dynamic> toJson() {
    return {
      'provider': provider,
      'token': token,
      if (fcmToken != null) 'fcmToken': fcmToken,
      if (deviceId != null) 'deviceId': deviceId,
      if (appName  != null) 'appName' : appName,
      if (platform != null) 'platform': platform,
      if (name     != null) 'name'    : name,
      if (email    != null) 'email'   : email,
    };
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
  Future<CustomerModel> socialLogin(SocialLoginRequest request) async {
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

      final customer = CustomerModel.fromJson(apiData);

      // 로그인 성공 시 토큰 저장
      if (customer.accessToken != null && customer.refreshToken != null) {
        await _tokenManager.saveAccessToken(customer.accessToken!);
        await _tokenManager.saveRefreshToken(customer.refreshToken!);
      }

      return customer;

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
  Future<CustomerModel> refreshLogin(String accessToken, String refreshToken) async {
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

      return CustomerModel.fromJson(apiData);

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

  /// 토큰으로 내 정보 가져오기 (자동 로그인용)
  Future<CustomerModel> getUserInfo() async {
    try {
      final Map<String, dynamic> apiVoPayload = {
        'param': {}
      };

      final Response response = await _apiService.post('/rest/customer/info', data: apiVoPayload);

      final apiData = response.data['data'] as Map<String, dynamic>?;

      if (apiData == null) {
        throw Exception('사용자 정보를 찾을 수 없습니다.');
      }

      return CustomerModel.fromJson(apiData);
    } on DioException catch (dioErr) {
      // 토큰 만료 등 에러 처리
      throw Exception(dioErr.message ?? '사용자 정보 조회 실패');
    } catch (e) {
      rethrow;
    }
  }

  /// 회원정보 수정
  Future<void> updateProfile(Map<String, dynamic> updateData) async {
    try {
      final Response response = await _apiService.post(
        '/rest/customer/updateInfo',
        data: {
          'param': updateData
        },
      );

      if (response.statusCode != 200) {
        throw Exception('회원정보 수정 실패: ${response.statusCode}');
      }

      // 필요하다면 여기서 최신 유저 정보를 다시 조회해서 리턴하거나 캐시 갱신 로직 추가 가능
    } on DioException catch (dioErr) {
      final data = dioErr.response?.data;
      if (data is Map && data['message'] != null) {
        throw Exception(data['message']);
      }
      throw Exception(dioErr.message ?? '회원정보 수정 중 오류가 발생했습니다.');
    } catch (e) {
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