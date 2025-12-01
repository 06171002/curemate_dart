// lib/features/auth/viewmodel/auth_viewmodel.dart

import 'dart:io';

import 'package:curemate/features/auth/model/customer_model.dart';
import 'package:curemate/features/auth/model/policy_model.dart';
import 'package:curemate/services/device_service.dart';
import 'package:curemate/utils/logger.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:kakao_flutter_sdk_user/kakao_flutter_sdk_user.dart' hide TokenManager;

import 'package:curemate/app/token_manager.dart';
import 'package:curemate/services/auth_service.dart';
import 'package:curemate/services/terms_service.dart';
import 'package:curemate/services/permission_service.dart';
import 'package:curemate/services/fcm_service.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';

class AuthViewModel with ChangeNotifier {
  final AuthService _authService = AuthService();
  final TermsService _termsService = TermsService();
  final TokenManager _tokenManager = TokenManager();
  final PermissionService _permissionService = PermissionService();
  final FcmService _fcmService = FcmService();
  final DeviceService _deviceService = DeviceService();

  final GoogleSignIn _googleSignIn = GoogleSignIn(
    serverClientId:
    '594911842190-0oqiimsfdoepg7tv1n36j2eiovb346do.apps.googleusercontent.com',
  );

  // 상태 분리: 앱 초기화 여부 (스플래시용)
  bool _isInitializing = true;
  bool get isInitializing => _isInitializing;

  // UI 로딩 여부 (로그인 버튼 등) - 초기값 false
  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  // 로그인 여부
  bool _isLoggedIn = false;
  bool get isLoggedIn => _isLoggedIn;

  // 약관 동의 필요 여부 (true: 약관 동의 필요, false: 약관 동의 불필요)
  bool _needsTermsAgreement = false;
  bool get needsTermsAgreement => _needsTermsAgreement;

  List<PolicyModel> _policies = [];
  List<PolicyModel> get policies => _policies;

  // 앱 권한 설정 여부
  bool _needsInitialPermissionCheck = false;
  bool get needsInitialPermissionCheck => _needsInitialPermissionCheck;

  // 로그인 사용자 정보
  CustomerModel? _customer;
  CustomerModel? get customer => _customer;

  String? get userName => _customer?.custNm;
  String? get userEmail => _customer?.custEmail;
  int? get custSeq => _customer?.custSeq;
  String? get profileImgUrl => _customer?.profileImgUrl;

  /// 앱 시작 시 자동 로그인 시도
  Future<void> tryAutoLogin() async {
    Logger.section('자동 로그인 시도');
    // 초기화 시작 (이미 true이지만 명시적으로)
    _isInitializing = true;
    notifyListeners();

    // 앱 권한 설정 여부를 읽어 온다. (_needsInitialPermissionCheck 변수 할당)
    await _loadInitialPermissionCheckStatus();

    try {
      Logger.d('토큰 읽기 시도...', tag: 'AUTH');
      final accessToken = await _tokenManager.getAccessToken();

      if (accessToken != null && accessToken.isNotEmpty) {
        final customer = await _authService.getUserInfo();
        await _handleLoginSuccess(customer);
        Logger.i('✅ 자동 로그인 및 정보 복구 성공: ${customer.custNm}', tag: 'AUTH');
      } else {
        _isLoggedIn = false;
        Logger.w('❌ 토큰 없음 - 로그인 필요', tag: 'AUTH');
      }
    } catch (e, stackTrace) {
      Logger.e('자동 로그인 실패', tag: 'AUTH', error: e, stackTrace: stackTrace);
      _isLoggedIn = false;
      await _tokenManager.deleteToken();
    } finally {
      // ✅ 초기화 완료 처리 (스플래시 해제)
      _isInitializing = false;
      notifyListeners();
      Logger.sectionEnd();
    }
  }

  Future<void> _loadInitialPermissionCheckStatus() async {
    final prefs = await SharedPreferences.getInstance();
    final isChecked = prefs.getBool('initial_permission_checked') ?? false;
    _needsInitialPermissionCheck = !isChecked;
  }

  Future<void> completeInitialPermissionCheck() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('initial_permission_checked', true);
    _needsInitialPermissionCheck = false;
    notifyListeners();
  }

  Future<String?> getFcmToken() async {
    return await _fcmService.getToken();
  }

  String _getPlatformName() {
    if (Platform.isAndroid) {
      return 'android';
    } else if (Platform.isIOS) {
      return 'ios';
    }
    return 'other'; // 웹이나 데스크톱 등 예외 처리
  }

  // 공통 로그인 처리 로직 (Google, Kakao 등에서 호출)
  Future<void> _handleLoginSuccess(CustomerModel customer) async {
    _customer = customer;

    // 로그인 성공 후 약관 동의 여부 체크
    try {
      _needsTermsAgreement = await _termsService.checkTermsNeeded();
    } catch (e) {
      Logger.w('약관 상태 확인 실패, 일단 진행', tag: 'AUTH');
      _needsTermsAgreement = false;
    }

    _isLoggedIn = true;
  }

  /// Google 로그인
  Future<void> signInWithGoogle() async {
    Logger.section('Google 로그인');

    _isLoading = true; // ✅ UI 로딩 시작 (스플래시와 무관)
    _errorMessage = null;
    notifyListeners();

    // 로딩바 렌더링 대기
    await Future.delayed(const Duration(milliseconds: 100));

    try {
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();

      if (googleUser == null) {
        Logger.w('사용자가 로그인 취소', tag: 'AUTH');
        _isLoading = false;
        notifyListeners();
        return;
      }

      Logger.i('Google 계정 선택됨: ${googleUser.email}', tag: 'AUTH');
      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      final String? idToken = googleAuth.idToken;

      if (idToken == null) {
        throw Exception('Google idToken을 가져올 수 없습니다.');
      }

      final String? fcmToken = await _fcmService.getToken();
      final String deviceId = await _deviceService.getDeviceId();

      final requestVo = SocialLoginRequest(
        provider: "GOOGLE",
        token: idToken,
        fcmToken: fcmToken,
        deviceId: deviceId,
        appName: 'curemate',
        platform: _getPlatformName(),
      );

      final CustomerModel customer = await _authService.socialLogin(requestVo);
      await _handleLoginSuccess(customer);

      Logger.i('✅ Google 로그인 완료', tag: 'AUTH');
    } catch (error, stackTrace) {
      _errorMessage = 'Google 로그인 실패: ${error.toString()}';
      _isLoggedIn = false;
      Logger.e('로그인 실패', tag: 'AUTH', error: error, stackTrace: stackTrace);
    } finally {
      _isLoading = false; // ✅ UI 로딩 종료
      notifyListeners();
      Logger.sectionEnd();
    }
  }

  /// Kakao 로그인
  Future<void> signInWithKakao() async {
    Logger.section('Kakao 로그인');

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      OAuthToken token;

      // 1. 카카오톡 설치 여부 확인
      if (await isKakaoTalkInstalled()) {
        try {
          // 카카오톡 앱으로 로그인 시도
          token = await UserApi.instance.loginWithKakaoTalk();
          Logger.i('카카오톡 앱으로 로그인 성공', tag: 'AUTH');
        } catch (error) {
          Logger.w('카카오톡 앱 로그인 실패', tag: 'AUTH', data: error);

          // 사용자가 카카오톡 로그인 화면에서 취소한 경우
          if (error is PlatformException && error.code == 'CANCELED') {
            _isLoading = false;
            notifyListeners();
            return;
          }

          // 카카오톡 앱 로그인 실패 시 웹(계정)으로 재시도
          try {
            token = await UserApi.instance.loginWithKakaoAccount();
            Logger.i('카카오 계정으로 로그인 성공 (Fallback)', tag: 'AUTH');
          } catch (accountError) {
            throw accountError;
          }
        }
      } else {
        // 카카오톡이 설치되어 있지 않으면 웹(계정)으로 로그인
        try {
          token = await UserApi.instance.loginWithKakaoAccount();
          Logger.i('카카오 계정으로 로그인 성공', tag: 'AUTH');
        } catch (error) {
          if (error is PlatformException && error.code == 'CANCELED') {
            _isLoading = false;
            notifyListeners();
            return;
          }
          rethrow;
        }
      }

      final String? fcmToken = await _fcmService.getToken();
      final String deviceId = await _deviceService.getDeviceId();

      // 2. 백엔드에 액세스 토큰 전송 및 검증 요청
      final requestVo = SocialLoginRequest(
        provider: "KAKAO", // 백엔드에서 'KAKAO'로 식별한다고 가정
        token: token.accessToken, // 카카오 액세스 토큰
        fcmToken: fcmToken, // 필요 시 실제 FCM 토큰 로직 연결
        deviceId: deviceId,
        appName: 'curemate',
        platform: _getPlatformName(),
      );

      final CustomerModel customer = await _authService.socialLogin(requestVo);
      await _handleLoginSuccess(customer);

      Logger.i('✅ Kakao 로그인 완료', tag: 'AUTH');
    } catch (error, stackTrace) {
      _errorMessage = 'Kakao 로그인 실패: ${error.toString()}';
      _isLoggedIn = false;
      Logger.e('Kakao 로그인 에러', tag: 'AUTH', error: error, stackTrace: stackTrace);
    } finally {
      _isLoading = false;
      notifyListeners();
      Logger.sectionEnd();
    }
  }

  /// Apple 로그인
  Future<void> signInWithApple() async {
    Logger.section('Apple 로그인');

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final credential = await SignInWithApple.getAppleIDCredential(
        scopes: [
          AppleIDAuthorizationScopes.email,
          AppleIDAuthorizationScopes.fullName,
        ],
      );

      Logger.i('Apple 계정 인증 성공', tag: 'AUTH');

      // identityToken이 백엔드 검증에 사용됩니다.
      final String? idToken = credential.identityToken;
      if (idToken == null) {
        throw Exception('Apple identityToken을 가져올 수 없습니다.');
      }

      final String? fcmToken = await _fcmService.getToken();
      final String deviceId = await _deviceService.getDeviceId();

      String? userName;
      if (credential.givenName != null || credential.familyName != null) {
        userName = "${credential.familyName ?? ''}${credential.givenName ?? ''}";
      }

      final String? userEmail = credential.email;

      // 백엔드 요청 객체 생성
      final requestVo = SocialLoginRequest(
        provider: "APPLE",
        token: idToken,
        fcmToken: fcmToken,
        deviceId: deviceId,
        appName: 'curemate',
        platform: _getPlatformName(),
        name: userName,
        email: userEmail,
      );

      final CustomerModel customer = await _authService.socialLogin(requestVo);
      await _handleLoginSuccess(customer);

      Logger.i('✅ Apple 로그인 완료', tag: 'AUTH');

    } catch (error, stackTrace) {
      _errorMessage = 'Apple 로그인 실패: ${error.toString()}';
      _isLoggedIn = false;
      Logger.e('Apple 로그인 에러', tag: 'AUTH', error: error, stackTrace: stackTrace);
    } finally {
      _isLoading = false;
      notifyListeners();
      Logger.sectionEnd();
    }
  }

  /// 로그아웃
  Future<void> signOut() async {
    try {
      await _googleSignIn.signOut();
      await _tokenManager.deleteToken();
      _isLoggedIn = false;
      _customer = null;
      _errorMessage = null;
      notifyListeners();
    } catch (error) {
      _errorMessage = '로그아웃 실패: ${error.toString()}';
      notifyListeners();
    }
  }

  /// 약관목록조회
  Future<void> fetchPolicies() async {
    _isLoading = true;
    notifyListeners();

    try {
      _policies = await _termsService.getPolicyList();
    } catch (e) {
      _errorMessage = '약관 정보를 불러오는데 실패했습니다.';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// 약관동의
  Future<void> completeTermsAgreement(List<int> agreedIds) async {
    _isLoading = true;
    notifyListeners();

    try {
      final int? custSeq = _customer?.custSeq;

      if (custSeq == null) {
        throw Exception('사용자 정보를 찾을 수 없습니다.');
      }

      // API 요청 데이터 생성
      // 전체 정책 목록(_policies)을 순회하며 동의 여부(Y/N)를 매핑합니다.
      // agreedIds에 포함되어 있으면 'Y', 없으면 'N'
      List<Map<String, dynamic>> consentList = _policies.map((policy) {
        return {
          "custSeq": custSeq,
          "consentIndCmcd": policy.policyTypeCmcd, // 예: "ServicePolicy"
          "policySeq": policy.policySeq,           // 예: 1
          "consentYn": agreedIds.contains(policy.policySeq) ? "Y" : "N",
        };
      }).toList();

      // 서비스 호출
      await _termsService.submitTermsAgreement(consentList);

      // 성공 시 약관 동의 필요 상태 해제 -> 라우터가 이를 감지하여 메인으로 이동
      _needsTermsAgreement = false;

    } catch (e) {
      _errorMessage = '약관 동의 처리에 실패했습니다: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// 사용자조회
  Future<void> fetchUserInfo() async {
    try {
      // AuthService의 getUserInfo()를 재사용
      final updatedCustomer = await _authService.getUserInfo();

      // 내부 상태 갱신
      _customer = updatedCustomer;
      notifyListeners(); // 구독 중인 모든 화면(헤더, 마이페이지 등) 갱신 알림

      Logger.i('회원 정보 갱신 완료: ${updatedCustomer.custNm}', tag: 'AUTH');
    } catch (e) {
      Logger.e('회원 정보 갱신 실패', tag: 'AUTH', error: e);
      // 필요하다면 에러 처리 (예: 토스트 메시지)
    }
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}