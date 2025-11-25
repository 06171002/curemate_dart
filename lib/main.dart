// lib/main.dart
import 'package:curemate/app/locale/locale_provider.dart';
import 'package:curemate/app/theme/theme_provider.dart';
import 'package:curemate/app/token_manager.dart';
import 'package:curemate/features/auth/viewmodel/auth_viewmodel.dart';
import 'package:curemate/features/guardian/viewmodel/guardian_viewmodel.dart';
import 'package:curemate/features/patient/viewmodel/patient_viewmodel.dart';
import 'package:curemate/features/widgets/common/bottom_nav_provider.dart';
import 'package:curemate/features/widgets/common/header_provider.dart';
import 'package:curemate/firebase_options.dart';
import 'package:curemate/utils/logger.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:kakao_flutter_sdk_user/kakao_flutter_sdk_user.dart';
import 'services/fcm_service.dart';
import 'config/EnvConfig.dart';

import 'app/app.dart'; // app.dart 파일 import

void main() async {
  // 1. Flutter 엔진과 위젯 트리 바인딩 보장
  // main 함수에서 async/await를 사용하기 위해 필수입니다.
  WidgetsFlutterBinding.ensureInitialized();

  const envFile = String.fromEnvironment('ENV_FILE', defaultValue: '.env');
  await dotenv.load(fileName: envFile);

  // 1. Firebase Core 초기화
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // 2. FCM 서비스 초기화 (리스너 등록 등)
  await FcmService().initialize();

  KakaoSdk.init(
    nativeAppKey: dotenv.env['KAKAO_NATIVE_APP_KEY'],
  );

  try {
    Logger.i('카카오 키 해시: ${await KakaoSdk.origin}');
  } catch (e) {
    Logger.e('키 해시 가져오기 실패: $e');
  }

  //  초대토큰 로드
  // TokenManager.loadFromUrl();

  // 4. 앱 실행
  runApp(
    // MultiProvider가 App 위젯보다 상위에 있어서,
    // App 위젯과 그 모든 자손들은 아래 ViewModel들을 사용할 수 있습니다.
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (context) => ThemeProvider()),  // 테마
        ChangeNotifierProvider(create: (_) => LocaleProvider()),       // 언어
        ChangeNotifierProvider(create: (context) => AuthViewModel()),  // 인증
        ChangeNotifierProvider(create: (_) => HeaderProvider()),       // 헤더
        ChangeNotifierProvider(create: (_) => BottomNavProvider()),    // 네비
        ChangeNotifierProvider(create: (_) => PatientViewModel()),
        ChangeNotifierProvider(create: (_) => GuardianViewModel()),
      ],
      child: const App(), // 2. App 위젯이 MultiProvider의 자식으로 들어갑니다.
    ),
  );
}
