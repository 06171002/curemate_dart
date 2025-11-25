// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Korean (`ko`).
class AppLocalizationsKo extends AppLocalizations {
  AppLocalizationsKo([String locale = 'ko']) : super(locale);

  @override
  String get testPageTitle => '개발 테스트 페이지';

  @override
  String get changeToLight => '라이트 모드로 변경';

  @override
  String get changeToDark => '다크 모드로 변경';

  @override
  String get logout => '로그아웃';
}
