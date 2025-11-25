import 'package:curemate/features/calendar/view/add_schedule_screen.dart';
import 'package:curemate/features/patient/view/choose_patient_screen.dart';
import 'package:curemate/features/patient/view/main_screen.dart';
import 'package:curemate/features/patient/view/my_page_screen.dart';
import 'package:curemate/features/recording/view/recording_screen.dart';
import 'package:curemate/features/test/view/test_screen.dart';
import 'package:flutter/material.dart';


// 이 파일은 헤더와 하단 네비게이션 바 컴포넌트만 포함합니다.
// 다른 파일에서 이 위젯들을 재사용할 수 있도록 클래스 형태로 분리했습니다.

import 'package:provider/provider.dart';
import 'header_provider.dart'; // 헤더 상태 Provider
import 'bottom_nav_provider.dart'; // BottomNavProvider

final Color primaryColor = const Color(0xFFA0C4FF);
final Color textPrimary = const Color(0xFF0E151B);
final Color textSecondary = const Color(0xFF4E7697);

class PatientScreenHeader extends StatelessWidget {
  final bool isMainPage; // 메인 페이지 여부

  const PatientScreenHeader({super.key, this.isMainPage = false});

  @override
  Widget build(BuildContext context) {
    final header = context.watch<HeaderProvider>();

    return Container(
      height: 60,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      color: Colors.white,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // 1️⃣ 왼쪽 버튼
          Align(
            alignment: Alignment.centerLeft,
            child: isMainPage
                ? IconButton(
                    icon: Icon(
                      Icons.switch_account,
                      color: primaryColor,
                      size: 24,
                    ),
                    onPressed: () {
                      // MaterialPageRoute를 PageRouteBuilder로 변경하여 애니메이션 제거
                      Navigator.push(
                        context,
                        PageRouteBuilder(
                          transitionDuration: Duration.zero,
                          pageBuilder:
                              (context, animation, secondaryAnimation) =>
                                  const PatientSelectionScreen(),
                          transitionsBuilder: (context, animation,
                              secondaryAnimation, child) {
                            return child;
                          },
                        ),
                      );
                    },
                  )
                : header.showBackButton
                    ? IconButton(
                        icon: Icon(
                          Icons.arrow_back_ios_new,
                          color: primaryColor,
                          size: 24,
                        ),
                        onPressed: () {
                          final nav = Provider.of<BottomNavProvider>(
                            context,
                            listen: false,
                          );
                          // nav.setIndexByPage(const Text('MainPage()'));
                          Navigator.of(context).pop();
                        },
                      )
                    : const SizedBox(),
          ),
          // 2️⃣ 타이틀
          Align(
            alignment: Alignment.center,
            child: Text(
              header.title,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: textPrimary,
              ),
            ),
          ),
          // 3️⃣ 오른쪽 설정 버튼
          if (header.showSettingButton)
            Align(
              alignment: Alignment.centerRight,
              child: IconButton(
                icon: Icon(
                  Icons.settings_outlined,
                  color: primaryColor,
                  size: 24,
                ),
                onPressed: () {
                  // MaterialPageRoute를 PageRouteBuilder로 변경하여 애니메이션 제거
                  Navigator.push(
                    context,
                    PageRouteBuilder(
                      transitionDuration: Duration.zero,
                      pageBuilder: (context, animation, secondaryAnimation) =>
                      const TestScreen(),
                      transitionsBuilder:
                          (context, animation, secondaryAnimation, child) {
                        return child;
                      },
                    ),
                  );
                },
              ),
            ),

        ],
      ),
    );
  }
}

class PatientScreenBottomNavBar extends StatelessWidget {
  const PatientScreenBottomNavBar({super.key});

  Widget _buildNavBarItem({
    required BuildContext context,
    required IconData icon,
    required String text,
    required int index,
    required VoidCallback onTap,
  }) {
    final provider = context.watch<BottomNavProvider>();
    bool isActive = provider.currentIndex == index;

    return Expanded(
      child: InkWell(
        onTap: () {
          if (!isActive) {
            provider.changeIndex(index);
            onTap(); // 페이지 이동은 다를 때만 실행
          }
        },
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: isActive ? primaryColor : textSecondary),
            Text(
              text,
              style: TextStyle(
                fontSize: 12,
                color: isActive ? primaryColor : textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
        color: Colors.white,
        child: SafeArea(
            top: true,
            child: Padding(
              padding: EdgeInsets.only(bottom: MediaQuery
                  .of(context)
                  .viewPadding
                  .bottom * 0.5), // 하단 패딩 줄이기
              child: Container(
                height: 60,
                decoration: BoxDecoration(
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.1),
                      spreadRadius: 1,
                      blurRadius: 5,
                      offset: const Offset(0, -3),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildNavBarItem(
                      context: context,
                      icon: Icons.home,
                      text: '홈',
                      index: 0,
                      onTap: () {
                        final nav = Provider.of<BottomNavProvider>(
                          context,
                          listen: false,
                        );
                        nav.changeIndex(0);
                        // MaterialPageRoute를 PageRouteBuilder로 변경
                        Navigator.pushReplacement(
                          context,
                          PageRouteBuilder(
                            transitionDuration: Duration.zero,
                            pageBuilder: (context, animation,
                                secondaryAnimation) => const MainPage(),
                            transitionsBuilder: (context, animation,
                                secondaryAnimation, child) {
                              return child;
                            },
                          ),
                        );
                      },
                    ),
                    _buildNavBarItem(
                      context: context,
                      icon: Icons.calendar_today,
                      text: '캘린더',
                      index: 1,
                      onTap: () {
                        final nav = Provider.of<BottomNavProvider>(
                          context,
                          listen: false,
                        );
                        nav.changeIndex(1);
                        // MaterialPageRoute를 PageRouteBuilder로 변경
                        Navigator.pushReplacement(
                          context,
                          PageRouteBuilder(
                            transitionDuration: Duration.zero,
                            pageBuilder: (context, animation,
                                secondaryAnimation) => const AddScheduleScreen(),
                            transitionsBuilder: (context, animation,
                                secondaryAnimation, child) {
                              return child;
                            },
                          ),
                        );
                      },
                    ),
                    _buildNavBarItem(
                      context: context,
                      icon: Icons.mic,
                      text: '녹음',
                      index: 2,
                      onTap: () {
                        final nav = Provider.of<BottomNavProvider>(
                          context,
                          listen: false,
                        );
                        nav.changeIndex(2);
                        // MaterialPageRoute를 PageRouteBuilder로 변경
                        Navigator.pushReplacement(
                          context,
                          PageRouteBuilder(
                            transitionDuration: Duration.zero,
                            pageBuilder: (context, animation,
                                secondaryAnimation) => const RecordingScreen(),
                            transitionsBuilder: (context, animation,
                                secondaryAnimation, child) {
                              return child;
                            },
                          ),
                        );
                      },
                    ),
                    _buildNavBarItem(
                      context: context,
                      icon: Icons.person,
                      text: 'My',
                      index: 3,
                      onTap: () {
                        // 'My' 탭을 눌렀을 때 MainPage로 이동
                        Navigator.pushReplacement(
                          context,
                          PageRouteBuilder(
                            // 애니메이션 지속 시간을 0으로 설정
                            transitionDuration: Duration.zero,
                            pageBuilder: (context, animation,
                                secondaryAnimation) =>
                            const MyPageScreen(),
                            transitionsBuilder: (context, animation,
                                secondaryAnimation, child) {
                              // 애니메이션 없이 새 화면을 바로 표시
                              return child;
                            },
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
            )
        )
    );
  }
}
