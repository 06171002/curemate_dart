// lib/routes/app_router.dart

import 'package:curemate/features/auth/model/policy_model.dart';
import 'package:curemate/features/auth/view/terms_agreement_screen.dart';
import 'package:curemate/features/auth/view/terms_detail_screen.dart';
import 'package:curemate/features/main_layout/view/main_layout_screen.dart';
import 'package:curemate/services/permission_service.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:curemate/features/splash/view/splash_screen.dart';
import 'package:curemate/features/auth/view/login_screen.dart';
import 'package:curemate/features/test/view/test_screen.dart';
import 'package:curemate/features/home/view/home_tab.dart';
import 'package:curemate/features/permission/view/permission_screen.dart';
import 'package:curemate/features/profile/view/profile_screen.dart';
import 'package:curemate/features/profile/view/profile_detail_screen.dart';
import 'package:curemate/features/settings/view/settings_screen.dart';
import 'package:curemate/features/auth/viewmodel/auth_viewmodel.dart';
import 'route_paths.dart';

class AppRouter {
  // Private constructor
  AppRouter._();

  // GlobalKey for navigation without context
  static final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

  // GoRouter 인스턴스 생성
  static GoRouter createRouter(AuthViewModel authViewModel) {
    return GoRouter(
      navigatorKey: navigatorKey,
      initialLocation: RoutePaths.splash,
      debugLogDiagnostics: true, // 개발 중 로그 확인
      refreshListenable: authViewModel,

      // 리다이렉트 로직
      redirect: (context, state) {
        final isInitializing = authViewModel.isInitializing;
        final needsPermissionCheck = authViewModel.needsInitialPermissionCheck;
        final isLoggedIn = authViewModel.isLoggedIn;
        final needsTerms = authViewModel.needsTermsAgreement;
        final currentPath = state.matchedLocation;

        print('🔄 [REDIRECT] 실행');
        print('  - isInitializing: $isInitializing');
        print('  - needsPermissionCheck: $needsPermissionCheck');
        print('  - isLoggedIn: $isLoggedIn');
        print('  - needsTerms: $needsTerms');
        print('  - currentPath: $currentPath');

        // 1. 스플래시 (로딩 중)
        if (isInitializing) {
          print('  → Splash 유지 (로딩 중)\n');
          return currentPath == RoutePaths.splash ? null : RoutePaths.splash;
        }

        // 2. 로그인 상태와 무관하게, 최초 권한 확인 필요
        if (needsPermissionCheck) {
          if (currentPath == RoutePaths.permission) {
            print('  → Permission 화면 유지 (최초 실행)\n');
            return null;
          }
          // PermissionScreen으로 이동
          print('  → Permission으로 이동 (최초 실행)\n');
          return RoutePaths.permission;
        }

        // 3. 비로그인 상태 → 로그인 페이지로
        if (!isLoggedIn) {
          if (currentPath == RoutePaths.login) {
            print('  → Login 화면 유지\n');
            return null;
          }
          // 로그인 페이지로 이동
          print('  → Login으로 이동\n');
          return RoutePaths.login;
        }

        // 4. 약관 동의가 필요할 경우
        if (needsTerms) {
          if (currentPath == RoutePaths.termsAgreement ||
              currentPath == RoutePaths.termsDetail) {
            return null;
          }
          print('  → 약관 동의 화면으로 이동');
          return RoutePaths.termsAgreement;
        }

        // 4. 로그인 됨 & 최초 권한 확인 완료 상태
        final authScreens = [
          RoutePaths.splash,
          RoutePaths.permission,
          RoutePaths.login,
          RoutePaths.termsAgreement,
        ];

        // Auth/Permission 화면일 경우 메인 화면으로 이동
        if (authScreens.contains(currentPath)) {
          print('  → 메인 화면 이동\n');
          return RoutePaths.main;
        }

        // 5. 그 외 화면은 유지
        print('  → 현재 화면 유지\n');
        return null;
      },

      // 라우트 정의 (이하 동일)
      routes: [
        // Splash
        GoRoute(
          path: RoutePaths.splash,
          name: 'splash',
          builder: (context, state) => const SplashScreen(),
        ),

        // Permission
        GoRoute(
          path: RoutePaths.permission,
          name: 'permission',
          builder: (context, state) => const PermissionScreen(),
        ),

        // Login
        GoRoute(
          path: RoutePaths.login,
          name: 'login',
          builder: (context, state) => const LoginScreen(),
        ),

        // Terms
        GoRoute(
          path: RoutePaths.termsAgreement,
          name: 'terms_agreement',
          builder: (context, state) => const TermsAgreementScreen(),
        ),

        // Terms Detail
        // 예: /terms_detail?seq=1
        GoRoute(
          path: RoutePaths.termsDetail,
          name: 'terms_detail',
          builder: (context, state) {
            // 쿼리 파라미터 'seq' 추출 (없으면 -1 또는 기본값)
            final seqStr = state.uri.queryParameters['seq'];
            final initialSeq = int.tryParse(seqStr ?? '') ?? -1;

            return TermsDetailScreen(initialPolicySeq: initialSeq);
          },
        ),

        GoRoute(
          path: RoutePaths.test,
          name: 'test',
          builder: (context, state) => TestScreen(),
        ),

        GoRoute(
          path: RoutePaths.main,
          name: 'main',
          builder: (context, state) => const MainLayoutScreen(),
        ),

        // Home (ShellRoute로 감싸서 BottomNavigationBar 유지 가능)
        // GoRoute(
        //   path: RoutePaths.home,
        //   name: 'home',
        //   builder: (context, state) {
        //     final tabIndex = int.tryParse(
        //         state.uri.queryParameters['tab'] ?? '0'
        //     ) ?? 0;
        //     return HomeTab(initialTabIndex: tabIndex);
        //   },
        // ),

        // Profile
        GoRoute(
          path: RoutePaths.profile,
          name: 'profile',
          builder: (context, state) => const ProfileScreen(),
          routes: [
            // Profile Detail (중첩 라우트)
            GoRoute(
              path: ':userId', // /profile/:userId
              name: 'profileDetail',
              builder: (context, state) {
                final userId = int.parse(state.pathParameters['userId']!);
                return ProfileDetailScreen(userId: userId);
              },
            ),
          ],
        ),

        // Settings
        GoRoute(
          path: RoutePaths.settings,
          name: 'settings',
          builder: (context, state) => const SettingsScreen(),
        ),
      ],

      // 에러 페이지
      errorBuilder: (context, state) => Scaffold(
        appBar: AppBar(title: const Text('Error')),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 80, color: Colors.red),
              const SizedBox(height: 16),
              Text(
                '페이지를 찾을 수 없습니다',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 8),
              Text(
                state.uri.toString(),
                style: Theme.of(context).textTheme.bodySmall,
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () => context.go(RoutePaths.home),
                child: const Text('홈으로 돌아가기'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}