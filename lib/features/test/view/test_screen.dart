// lib/features/test/view/test_screen.dart (수정된 전체 코드)

import 'package:curemate/features/cure_room/model/curer_model.dart';
import 'package:curemate/features/widgets/common/bottom_nav_provider.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';

import '../../../app/locale/locale_provider.dart';
import '../../../app/theme/theme_provider.dart';
import '../../../l10n/app_localizations.dart';
import '../../../services/api_service.dart';
import '../../../routes/route_paths.dart';
import '../../auth/viewmodel/auth_viewmodel.dart';

class TestScreen extends StatelessWidget {
  const TestScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();
    final localeProvider = context.watch<LocaleProvider>();
    final navProvider = context.watch<BottomNavProvider>();
    final text = AppLocalizations.of(context)!;

    return Scaffold(
      /*appBar: AppBar(
        title: Text(text.testPageTitle),
        automaticallyImplyLeading: false,
      ),*/
      body: Column(
        children: [
          SafeArea(
            top: true,
            child: Container(
              child: Text(
                text.testPageTitle,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                ),
              ),
            )
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(16.0),
              children: [
                // ═══════════════════════════════════════════
                // ✅ 모드 전환 테스트 (환자 선택 시뮬레이션)
                // ═══════════════════════════════════════════
                _buildSectionTitle(context, '모드 전환 테스트'),

                Container(
                  padding: const EdgeInsets.all(12),
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: navProvider.isMainMode ? Colors.blue[50] : Colors.green[50],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: navProvider.isMainMode ? Colors.blue : Colors.green,
                    ),
                  ),
                  child: Text(
                    navProvider.isMainMode
                        ? '현재 상태: [메인 모드]'
                        : '현재 상태: [환자 모드] - ${navProvider.selectedCurer?.cureNm}',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: navProvider.isMainMode ? Colors.blue[800] : Colors.green[800],
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),

                _buildTestButton(
                  context,
                  icon: Icons.person_pin_circle,
                  label: '환자 선택 시뮬레이션 (홍길동)',
                  color: Colors.orange,
                  onPressed: () {
                    // ✅ Provider에 환자 정보 업데이트 -> 헤더 변경됨
                    // 큐어룸 선택 시뮬레이션 (더미 데이터 생성)
                    final dummyCurer = CurerModel(
                      cureSeq: 1,
                      custSeq: 100,
                      cureNm: '홍길동의 케어룸',
                      cureDesc: '홍길동 환자의 재활 및 약물 관리를 위한 공간입니다.',
                      regId: "100",
                      regDttm: '2024-01-01',
                    );

                    context.read<BottomNavProvider>().selectCurer(dummyCurer);

                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('환자 모드로 전환되었습니다 (헤더 확인)')),
                    );
                  },
                ),

                _buildTestButton(
                  context,
                  icon: Icons.home,
                  label: '메인 모드로 복귀',
                  color: Colors.grey,
                  onPressed: () {
                    // ✅ 초기화 -> 헤더 로고로 변경됨
                    context.read<BottomNavProvider>().clearCurer();
                  },
                ),

                const Divider(height: 32),
                // ═══════════════════════════════════════════
                // 화면 이동 버튼
                // ═══════════════════════════════════════════
                _buildSectionTitle(context, '화면 이동'),

                _buildTestButton(
                  context,
                  icon: Icons.home,
                  label: '홈 화면으로 이동',
                  onPressed: () {
                    context.go(RoutePaths.home);
                  },
                  color: Colors.blue,
                ),

                _buildTestButton(
                  context,
                  icon: Icons.person,
                  label: '프로필 화면으로 이동',
                  onPressed: () {
                    context.push(RoutePaths.profile);
                  },
                  color: Colors.purple,
                ),

                _buildTestButton(
                  context,
                  icon: Icons.home_outlined,
                  label: '홈 화면 (검색 탭)으로 이동',
                  onPressed: () {
                    context.go(RoutePaths.homeWithTab(1));
                  },
                  color: Colors.blueAccent,
                ),

                _buildTestButton(
                  context,
                  icon: Icons.person_outline,
                  label: '프로필 상세 (User ID: 1)',
                  onPressed: () {
                    context.push(RoutePaths.profileDetail(1));
                  },
                  color: Colors.deepPurple,
                ),

                const Divider(height: 32),

                // ═══════════════════════════════════════════
                // API 테스트
                // ═══════════════════════════════════════════
                _buildSectionTitle(context, 'API 테스트'),

                _buildTestButton(
                  context,
                  icon: Icons.monitor_heart,
                  label: '서버 헬스 체크',
                  onPressed: () async {
                    try {
                      final response = await ApiService().get(
                        '/rest/system/health',
                      );

                      if (context.mounted) {
                        showDialog(
                          context: context,
                          builder: (context) => AlertDialog(
                            title: const Text("Health Check 성공"),
                            content: Text("응답 데이터:\n${response.data}"),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(context),
                                child: const Text("확인"),
                              ),
                            ],
                          ),
                        );
                      }
                    } catch (e) {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text("헬스 체크 실패: $e"),
                            backgroundColor: Colors.red,
                          ),
                        );
                      }
                    }
                  },
                  color: Colors.teal,
                ),

                const Divider(height: 32),

                // ═══════════════════════════════════════════
                // 테마 & 언어 설정
                // ═══════════════════════════════════════════
                _buildSectionTitle(context, '테마 & 언어'),

                _buildTestButton(
                  context,
                  icon: themeProvider.isDarkMode ? Icons.wb_sunny : Icons.dark_mode,
                  label: themeProvider.isDarkMode
                      ? text.changeToLight
                      : text.changeToDark,
                  onPressed: () {
                    themeProvider.toggleTheme();
                  },
                  color: themeProvider.isDarkMode ? Colors.amber : Colors.black87,
                ),

                _buildTestButton(
                  context,
                  icon: Icons.language,
                  label: '${text.localeName == 'ko' ? '영어로 변경' : 'Switch to Korean'}',
                  onPressed: () {
                    final newLocale = localeProvider.locale.languageCode == 'ko'
                        ? const Locale('en')
                        : const Locale('ko');
                    localeProvider.setLocale(newLocale);
                  },
                  color: Colors.green,
                ),

                const Divider(height: 32),

                _buildSectionTitle(context, '화상통화'),

                _buildTestButton(
                  context,
                  icon: Icons.call,
                  label: '화상통화연결',
                  onPressed: () async {
                    final shouldLogout = await _showLogoutDialog(context);

                    if (shouldLogout == true) {
                      await context.read<AuthViewModel>().signOut();
                    }
                  },
                  color: Colors.indigo,
                ),
                const Divider(height: 32),

                // ═══════════════════════════════════════════
                // 기타
                // ═══════════════════════════════════════════
                _buildSectionTitle(context, '기타'),

                _buildTestButton(
                  context,
                  icon: Icons.logout,
                  label: text.logout,
                  onPressed: () async {
                    final shouldLogout = await _showLogoutDialog(context);

                    if (shouldLogout == true) {
                      await context.read<AuthViewModel>().signOut();
                    }
                  },
                  color: Colors.red,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // 섹션 타이틀 위젯 (✅ 색상 수정)
  Widget _buildSectionTitle(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.only(top: 8, bottom: 12),
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleMedium?.copyWith(
          fontWeight: FontWeight.bold,
          // ✅ 배경색과 대비가 강한 onBackground (소프트 차콜) 색상을 사용합니다.
          color: Theme.of(context).colorScheme.onBackground,
        ),
      ),
    );
  }

  Widget _buildTestButton(
      BuildContext context, {
        required IconData icon,
        required String label,
        required VoidCallback onPressed,
        Color? color,
      }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: ElevatedButton.icon(
        onPressed: onPressed,
        icon: Icon(icon),
        label: Text(label),
        style: ElevatedButton.styleFrom(
          minimumSize: const Size.fromHeight(54),
          backgroundColor: color,
          foregroundColor: Colors.white,
          alignment: Alignment.centerLeft,
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
          textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
      ),
    );
  }

  // 로그아웃 확인 다이얼로그
  Future<bool?> _showLogoutDialog(BuildContext context) {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('로그아웃'),
        content: const Text('정말 로그아웃 하시겠습니까?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('취소'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(
              foregroundColor: Colors.red,
            ),
            child: const Text('로그아웃'),
          ),
        ],
      ),
    );
  }
}