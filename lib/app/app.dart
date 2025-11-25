// import 'package:curemate/app/locale/locale_provider.dart';
// import 'package:curemate/app/theme/app_theme.dart';
// import 'package:curemate/app/theme/theme_provider.dart';
// import 'package:curemate/app/token_manager.dart';
// import 'package:curemate/features/auth/viewmodel/auth_viewmodel.dart';
// import 'package:curemate/features/guardian/view/add_guardian_screen.dart';
// import 'package:curemate/features/patient/view/choose_patient_screen.dart';
// import 'package:curemate/features/auth/view/login_screen.dart';
// import 'package:curemate/features/test/view/test_screen.dart';
// import 'package:flutter/material.dart';
// import 'package:provider/provider.dart';
// import 'package:supabase_flutter/supabase_flutter.dart';
// import 'package:flutter_localizations/flutter_localizations.dart';
// import '../l10n/app_localizations.dart';
// import 'package:curemate/app/route_observer.dart';
//
// class App extends StatelessWidget {
//   const App({super.key});
//
//   @override
//   Widget build(BuildContext context) {
//     final themeProvider = Provider.of<ThemeProvider>(context);
//     final localeProvider = Provider.of<LocaleProvider>(context);
//
//     return Consumer<AuthViewModel>(
//       builder: (context, authViewModel, child) {
//         print('isLoggedIn : ${authViewModel.isLoggedIn}');
//
//         return MaterialApp(
//           key: ValueKey(authViewModel.isLoggedIn), // isLoggedIn 변경 시 MaterialApp 재생성
//           title: 'Curemate',
//           theme: AppThemes.lightTheme,
//           darkTheme: AppThemes.darkTheme,
//           themeMode: themeProvider.themeMode,
//           locale: localeProvider.locale,
//           navigatorObservers: [routeObserver],
//
//           // 다국어 설정
//           localizationsDelegates: const [
//             AppLocalizations.delegate,
//             GlobalMaterialLocalizations.delegate,
//             GlobalWidgetsLocalizations.delegate,
//             GlobalCupertinoLocalizations.delegate,
//           ],
//           supportedLocales: const [
//             Locale('en'),
//             Locale('ko'),
//           ],
//
//           home: _buildHome(authViewModel),
//         );
//       },
//     );
//   }
//
//   Widget _buildHome(AuthViewModel authViewModel) {
//     // 1. 자동 로그인 시도 중 (앱 첫 실행)
//     if (authViewModel.isLoading) {
//       return const Scaffold(
//         body: Center(child: CircularProgressIndicator()),
//       );
//     }
//
//     // 2. 로그인 완료 상태 감지
//     if (authViewModel.isLoggedIn) {
//       return TestScreen();
//     }
//
//     // 3. 비로그인 상태 감지
//     return const LoginScreen();
//   }
// }

// lib/app/app.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'locale/locale_provider.dart';
import 'theme/app_theme.dart';
import 'theme/theme_provider.dart';
import '../features/auth/viewmodel/auth_viewmodel.dart';
import '../routes/app_router.dart';
import '../l10n/app_localizations.dart';

class App extends StatelessWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final localeProvider = Provider.of<LocaleProvider>(context);
    final authViewModel = Provider.of<AuthViewModel>(context);

    return MaterialApp.router(
      title: 'Curemate',

      // Theme
      theme: AppThemes.lightTheme,
      darkTheme: AppThemes.darkTheme,
      themeMode: themeProvider.themeMode,

      // Locale
      locale: localeProvider.locale,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('en'),
        Locale('ko'),
      ],

      // GoRouter 적용
      routerConfig: AppRouter.createRouter(authViewModel),
    );
  }
}