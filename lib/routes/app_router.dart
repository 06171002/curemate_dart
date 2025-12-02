// lib/routes/app_router.dart

import 'package:curemate/features/auth/model/policy_model.dart';
import 'package:curemate/features/auth/view/terms_agreement_screen.dart';
import 'package:curemate/features/auth/view/terms_detail_screen.dart';
import 'package:curemate/features/cure_room/view/add_cure_room_screen.dart';
import 'package:curemate/features/cure_room/view/settings_screen.dart';
import 'package:curemate/features/main_layout/view/main_layout_screen.dart';
import 'package:curemate/features/profile/view/profile_edit_screen.dart';
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


import 'package:curemate/features/cure_room/view/patient_profile_screen.dart';
import 'package:curemate/features/cure_room/view/medical_history_screen.dart';
import 'package:curemate/features/cure_room/view/medical_detail_screen.dart';
import 'package:curemate/features/cure_room/view/medication_list_screen.dart';
import 'package:curemate/features/cure_room/view/medication_detail_screen.dart';
import 'package:curemate/features/cure_room/view/add_patient_screen.dart';
import 'package:curemate/features/cure_room/model/cure_room_models.dart';


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

        GoRoute(
          path: RoutePaths.profile,
          name: 'profile',
          builder: (context, state) => const ProfileScreen(),
          routes: [
            // ✅ [중요] 'edit'을 ':userId'보다 먼저 정의해야 합니다.
            // 그렇지 않으면 'edit'이라는 문자열을 userId(int)로 파싱하려다 에러가 발생합니다.
            GoRoute(
              path: 'edit', // /profile/edit
              name: 'profileEdit',
              builder: (context, state) => const ProfileEditScreen(),
            ),

            // Profile Detail
            GoRoute(
              path: ':userId', // /profile/:userId
              name: 'profileDetail',
              builder: (context, state) {
                // 이제 userId가 숫자가 아닌 경우(예: 잘못된 접근)에 대한 방어 코드도 있으면 좋습니다.
                final userIdStr = state.pathParameters['userId']!;
                final userId = int.tryParse(userIdStr);

                if (userId == null) {
                  // 숫자가 아니면 에러 페이지나 리스트로 보냄
                  return const Scaffold(body: Center(child: Text("잘못된 사용자 ID입니다.")));
                }

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

        
        // ===============================
        //  CureRoom 관련 라우트들 추가
        // ===============================

        // 프로필 (환자 정보 카드에서 들어가는 화면)
        GoRoute(
  path: RoutePaths.cureRoomPatientProfile,
  name: 'cure_room_patient_profile',
  builder: (context, state) {
    final extra = state.extra as Map<String, dynamic>?;

    if (extra == null || extra['patient'] == null) {
      return const Scaffold(
        body: Center(child: Text('환자 정보가 없습니다.')),
      );
    }

    final patient = extra['patient'] as CurePatientModel;
    final profileImgUrl = extra['profileImgUrl'] as String?;

    return PatientProfileScreen(
      patient: patient,
      profileImgUrl: profileImgUrl,
    );
  },
),
        GoRoute(
          path: RoutePaths.addCureRoom,
          name: 'add_cure_room',
          builder: (context, state) => const AddCureRoomScreen(),
        ),

         GoRoute(
          path: RoutePaths.cureRoomAddPatient,
          name: 'cure_room_add_patient',
          builder: (context, state) => const AddPatientScreen(),
        ),

        // 병력 목록 (병력 관리 그리드 화면)
        GoRoute(
          path: RoutePaths.cureRoomMedicalHistory,
          name: 'cure_room_medical_history',
          builder: (context, state) {
            final extra = state.extra as Map<String, dynamic>?;
            final patient = extra?['patient'] as CurePatientModel?;

            if (patient == null) {
              return const Scaffold(
                body: Center(child: Text('환자 정보가 없습니다.')),
              );
            }

            return MedicalHistoryScreen(patient: patient);
          },
        ),
        // 병력 상세/추가
        GoRoute(
          path: RoutePaths.cureRoomMedicalHistoryDetail,
          name: 'cure_room_medical_history_detail',
          builder: (context, state) {
            final extra = state.extra as Map<String, dynamic>?;

            final isNew = (extra?['isNew'] as bool?) ?? false;
            final curePatientSeq = extra?['curePatientSeq'] as int?;
            final disease = extra?['disease'] as CureDiseaseModel?; // ✅ 모델 받기

            if (curePatientSeq == null) {
              return const Scaffold(
                body: Center(child: Text('환자 ID가 없습니다.')),
              );
            }

            return MedicalHistoryDetailPage(
              isNew: isNew,
              curePatientSeq: curePatientSeq,
              disease: disease, // ✅ 여기로 전달
            );
          },
        ),

        // 복용 약 목록
        GoRoute(
          path: RoutePaths.cureRoomMedications,
          name: 'cure_room_medications',
          builder: (context, state) {
            final extra = state.extra as Map<String, dynamic>?;

            if (extra == null || extra['curePatientSeq'] == null) {
              return const Scaffold(
                body: Center(child: Text('환자 정보가 없어요 (curePatientSeq 필요)')),
              );
            }

            final int curePatientSeq = extra['curePatientSeq'] as int;
            final List<CureMedicineGroupModel>? groups =
                extra['medicineGroups'] as List<CureMedicineGroupModel>?;

            return MedicationListScreen(
              curePatientSeq: curePatientSeq,
              initialGroups: groups,
            );
          },
        ),

        // 복용 약 추가/수정
        GoRoute(
          path: RoutePaths.cureRoomMedicationDetail,
          name: 'cureRoomMedicationDetail',
          builder: (context, state) {
            final extra = state.extra as Map<String, dynamic>?;

            final int curePatientSeq = extra?['curePatientSeq'] as int;
            final bool isEdit = extra?['isEdit'] as bool? ?? false;

            return MedicationDetailPage(
              curePatientSeq: curePatientSeq,
              isEdit: isEdit,
               group: extra?['group'] as CureMedicineGroupModel?,  // 🔹 추가
            );
          },
        ),


        //큐어룸 설정페이지
       GoRoute(
        path: RoutePaths.cureRoomSettings,
        name: 'cure_room_settings',
        builder: (context, state) {
          final detail = state.extra as CureRoomDetailModel?;

          if (detail == null) {
            return const Scaffold(
              body: Center(child: Text('큐어룸 정보가 없습니다.')),
            );
          }

          return CureRoomSettingsScreen(cureRoom: detail);
        },
      ),

      ],
        // ===============================
        //  CureRoom 관련 라우트들 끝
        // ===============================



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