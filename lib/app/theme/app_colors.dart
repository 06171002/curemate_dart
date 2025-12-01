// lib/app/theme/app_colors.dart

import 'package:flutter/material.dart';

// 앱의 전체 색상을 관리하는 클래스
abstract class AppColors {
  // ----------------------------------------------------
  // 1. 핵심 컬러 팔레트 (따뜻한 회복 & 치유 테마)
  // ----------------------------------------------------
  static const Color healingGreen = Color(0xFF88C9A1);
  static const Color careCoral = Color(0xFFFFB7B2);
  static const Color warmCream = Color(0xFFFDFCF8);

  // ----------------------------------------------------
  //  2. 텍스트/중립 컬러
  // ----------------------------------------------------
  static const Color textMainDark = Color(0xFF404A55);       // 본문/제목 (소프트 차콜)
  static const Color textSecondaryLight = Color(0xFF8D9BA8);  // 보조 텍스트
  static const Color textDarkOnLight = textMainDark;
  static const Color textLightOnDark = Color(0xFFF5F5F5);

  // ----------------------------------------------------
  // 3. 기본 컬러
  // ----------------------------------------------------
  static const Color white = Colors.white;
  static const Color black = Color(0xFF2D2D2D);
  static const Color grey = Colors.grey;
  static const Color lightGrey = Color(0xFFF5F5F5);
  static const Color blue = Colors.blue;

  // ----------------------------------------------------
  // 4. 라이트/다크 모드 테마 컬러
  // ----------------------------------------------------
  // Light Mode
  static const Color lightPrimary = healingGreen;
  static const Color lightBackground = warmCream;
  static const Color lightSurface = Colors.white;
  static const Color lightTextPrimary = textDarkOnLight;
  static const Color lightTextSecondary = textSecondaryLight;
  static const Color lightOutline = Color(0xFFE0E0E0);

  // Dark Mode
  static const Color darkPrimary = healingGreen;
  static const Color darkBackground = Color(0xFF1E1E1E);
  static const Color darkSurface = Color(0xFF121212);
  static const Color darkTextPrimary = textLightOnDark;
  static const Color darkTextSecondary = Color(0xFFB0BEC5);
  static const Color darkOutline = Color(0xFF3A3A3A);
  static const Color darkAccent = Color(0xFF4A4A4A);

  // ----------------------------------------------------
  // 5. 기능/상태 색상
  // ----------------------------------------------------
  static const Color kakaoYellow = Color(0xFFFEE500);
  static const Color error = Color(0xFFFF6B6B);
  static const Color mainBtn = healingGreen;
  static const Color activeColor = healingGreen;
  static const Color inputBorder = Color(0xFFE0E0E0);

  // 버튼 상태
  static const Color activeBtn = Color(0xFFE0E0E0);
  static const Color medicineBtn = Color(0xFFF1F8E9);

  // ----------------------------------------------------
  // 6. 투명도 적용 컬러 (withValues 사용)
  // ----------------------------------------------------

  // 그림자: 기존 Colors.grey.withOpacity(0.1) 대체
  // withValues(alpha: 0.0 ~ 1.0) 사용
  static final Color shadow = grey.withValues(alpha: 0.1);
  static final Color shadowStrong = grey.withValues(alpha: 0.2);

  // 오버레이 (모달 배경 등)
  static final Color overlay = black.withValues(alpha: 0.3);

  // ----------------------------------------------------
  // 7. 기존 코드 호환성 및 별칭 (Legacy Support)
  // ----------------------------------------------------
  static const Color darkBlue = textMainDark;
  static const Color deepDarkBlue = textMainDark;
  static const Color skyBlue = textSecondaryLight;
  static const Color blueTextSecondary = textMainDark;
  static const Color iconColor = healingGreen;

  static const pinkIconColor = Color(0xFFFFCDD2);
  static const yellowIconColor = Color(0xFFFFF59D);
  static const greenIconColor = Color(0xFFA5D6A7);

  static const Color blueBtnText = Color(0xFF2E7D32);
  static const Color pinkBtnText = Color(0xFFC62828);

  static const Color blueBtn = healingGreen;
  static const Color pinkBtn = careCoral;

  static const statusOngoing = Color(0xFFFFB74D);
  static const statusDone = healingGreen;
  static const statusWarning = error;

  // 뱃지 배경색
  static const memberBg = Color(0xFFE8F5E9);
  static const nonMemberBg = Color(0xFFFFEBEE);

  // 대화 말풍선 색상
  static const speakerColor1 = Color(0xFF4DB6AC);
  static const speakerColor2 = healingGreen;
  static const speakerBackground = Color(0xFFE8F5E9);

  // 기타 UI
  static const inactiveThumbColor = Color(0xFFEEEEEE);
  static const inactiveTrackColor = Color(0xFFE0E0E0);
  static const Color loginBtn = healingGreen;
}