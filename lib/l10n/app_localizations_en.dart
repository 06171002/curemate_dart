// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get testPageTitle => 'Test Page';

  @override
  String get changeToLight => 'Switch to Light Mode';

  @override
  String get changeToDark => 'Switch to Dark Mode';

  @override
  String get logout => 'Logout';
}
