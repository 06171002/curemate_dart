// lib/app/theme/app_colors.dart

import 'package:flutter/material.dart';

// 앱의 전체 색상을 관리하는 클래스
abstract class AppColors {
  // ----------------------------------------------------
  // ✅ 1. 핵심 컬러 팔레트 (파스텔 & 포근함)
  // ----------------------------------------------------
  static const Color primaryPastelBlue = Color(0xFFA0C4FF);   // 메인 강조색 (버튼, 아이콘)
  static const Color secondaryCozyPink = Color(0xFFFFDDDE);   // 보조 강조색 (따뜻한 포인트)

  // ----------------------------------------------------
  // ✅ 2. 텍스트/중립 컬러 (가독성 확보를 위한 소프트 차콜)
  // ----------------------------------------------------
  static const Color textMainDark = Color(0xFF404A55);       // 본문/제목 (소프트 차콜)
  static const Color textSecondaryLight = Color(0xFF7CA0BB);  // 보조 텍스트 (스카이 블루)
  static const Color textDarkOnLight = textMainDark;          // 라이트 모드 기본 텍스트
  static const Color textLightOnDark = Color(0xFFE0E0E0);     // 다크 모드 기본 텍스트

  // ----------------------------------------------------
  // 3. 라이트 모드 (Light Mode)
  // ----------------------------------------------------
  static const Color lightPrimary = primaryPastelBlue;
  static const Color lightBackground = Color(0xFFF0F8FF); // 옅은 하늘색 배경
  static const Color lightAccent = Color.fromARGB(255, 224, 223, 223);
  static const Color lightTextPrimary = textDarkOnLight;
  static const Color lightTextSecondary = textSecondaryLight;
  static const Color lightOutline = Color(0xFFE5E5E5);
  static const Color lightSurface = Colors.white;

  // ----------------------------------------------------
  // 4. 다크 모드 (Dark Mode)
  // ----------------------------------------------------
  static const Color darkPrimary = primaryPastelBlue;
  static const Color darkBackground = Color(0xFF1E1E1E);
  static const Color darkAccent = Color.fromARGB(255, 224, 223, 223);
  static const Color darkTextPrimary = textLightOnDark;
  static const Color darkTextSecondary = textSecondaryLight;
  static const Color darkOutline = Color(0xFF3A3A3A);
  static const Color darkSurface = Color(0xFF121212);

  // ----------------------------------------------------
  // 5. 공통 기능/상태 색상 (기존 사용처를 위해 유지하고 값 조정)
  // ----------------------------------------------------
  static const Color kakaoYellow = Color(0xFFFEE500);
  static const Color error = Color(0xFFD34242);
  static const Color white = Colors.white;
  static const Color black = Colors.black;
  static const Color blue = Colors.blue;

  // 기존의 진한/어두운 블루 계열은 소프트 차콜로 통일 (textMainDark)
  static const Color darkBlue = textMainDark;
  static const Color deepDarkBlue = textMainDark;

  static const Color grey = Colors.grey;
  static const Color lightGrey = Color(0xFFEEEEEE);
  static const Color loginBtn = primaryPastelBlue;

  // 버튼 텍스트 색상 (기존 값 유지 - 기능적 역할)
  static const Color blueBtnText = Color(0xFF1565C0);
  static const Color pinkBtnText = Color(0xFFAD1457);

  static const Color blueBtn = Colors.blue;
  static const Color pinkBtn = Color.fromARGB(255, 224, 223, 223);

  // 메인 버튼/액티브 컬러 통일
  static const Color mainBtn = primaryPastelBlue;
  static const Color skyBlue = textSecondaryLight;
  static const Color blueTextSecondary = textMainDark;
  static const Color iconColor = primaryPastelBlue;

  // 아이콘 컬러 팔레트 (기존 파스텔톤 유지)
  static const pinkIconColor = Color.fromARGB(255, 233, 196, 199);
  static const yellowIconColor = Color.fromARGB(255, 245, 228, 137);
  static const greenIconColor = Color.fromARGB(255, 184, 209, 182);

  static const activeColor = primaryPastelBlue;
  static const inactiveThumbColor = Color(0xFFD9D9D9);
  static const inactiveTrackColor = Color(0xFFBFBFBF);

  // 대화 말풍선 색상 (기존 값 유지)
  static const speakerColor1 = Color(0xFF1E88E5);
  static const speakerColor2 = Color(0xFF10B981);
  static const speakerBackground = Color(0xFFD1FAE5);

  // 뱃지 배경색
  static const memberBg = Color(0xFFCAE7FF);
  static const nonMemberBg = secondaryCozyPink;

  // 기타 UI 요소
  static const inputBorder = Color(0xFFE5E7EB);
  static const statusOngoing =Color(0xFFFFC107);
  static const statusDone =Color(0xFF4CAF50);
  static const statusWarning =Color(0xFFFF6B6B);
  static const activeBtn = Color.fromARGB(255, 206, 211, 219);
  static const medicineBtn = Color(0xFFE6F0FF);
}