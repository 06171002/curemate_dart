// lib/app/token_manager.dart
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class TokenManager {
  static final TokenManager _instance = TokenManager._internal();
  factory TokenManager() => _instance;
  TokenManager._internal();

  final _storage = const FlutterSecureStorage();
  static const _accessTokenKey  = 'curemate_access_token';
  static const _refreshTokenKey = 'curemate_refresh_token';

  // CureMate 전용 JWT 저장
  Future<void> saveAccessToken(String token) async {
    await _storage.write(key: _accessTokenKey, value: token);
  }

  // CureMate 전용 JWT 읽기
  Future<String?> getAccessToken() async {
    return await _storage.read(key: _accessTokenKey);
  }

  // Refresh Token 저장
  Future<void> saveRefreshToken(String token) async {
    await _storage.write(key: _refreshTokenKey, value: token);
  }

  // Refresh Token 읽기
  Future<String?> getRefreshToken() async {
    return await _storage.read(key: _refreshTokenKey);
  }

  // CureMate 전용 JWT 삭제 (로그아웃)
  Future<void> deleteToken() async {
    await _storage.delete(key: _accessTokenKey);
    await _storage.delete(key: _refreshTokenKey);
  }

  // --- 기존 초대 토큰 로직 (유지) ---
  static String? inviteToken;

  static void loadFromUrl() {
    final uri = Uri.base;
    inviteToken = uri.queryParameters['token'];
  }

  static void clear() {
    inviteToken = null;
  }
}