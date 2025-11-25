// lib/routes/route_paths.dart

class RoutePaths {
  // Private constructor
  RoutePaths._();

  // Auth
  static const String splash = '/';
  static const String permission = '/permission';
  static const String login = '/login';
  static const String termsAgreement = '/terms_agreement';
  static const String termsDetail = '/terms_detail';

  // Main
  static const String test = '/test';
  static const String main = '/main';
  static const String home = '/home';
  static const String profile = '/profile';
  static const String settings = '/settings';

  // Profile 상세 (동적 경로)
  static String profileDetail(int userId) => '/profile/$userId';

  // 쿼리 파라미터 헬퍼
  static String homeWithTab(int tabIndex) => '/home?tab=$tabIndex';

  // 약관 상세 헬퍼
  static String termsDetailWithSeq(int seq) => '/terms_detail?seq=$seq';
}