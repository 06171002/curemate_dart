import 'package:curemate/features/cure_nursing/view/cure_nursing_tab.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:curemate/app/theme/app_colors.dart';
import 'package:curemate/features/widgets/common/bottom_nav_provider.dart';
import 'package:curemate/features/main_layout/widget/cure_room_drawer.dart';
import 'package:curemate/features/home/view/home_tab.dart';
import 'package:curemate/features/settings/view/more_tab.dart';
import 'package:curemate/routes/route_paths.dart'; 
import 'package:go_router/go_router.dart';
import 'package:curemate/services/cure_room_service.dart';

import '../../story/view/story_tab.dart';
import 'package:curemate/features/calendar/view/calendar_screen.dart';

class MainLayoutScreen extends StatefulWidget {
  const MainLayoutScreen({super.key});

  @override
  State<MainLayoutScreen> createState() => _MainLayoutScreenState();
}

class _MainLayoutScreenState extends State<MainLayoutScreen> {
  final PageController _pageController = PageController();
  // ✅ Scaffold 상태 제어를 위한 GlobalKey
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final CureRoomService _cureRoomService = CureRoomService();

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final navProvider = context.watch<BottomNavProvider>();

    return Scaffold(
      key: _scaffoldKey, // ✅ Key 연결 확인
      backgroundColor: Colors.white,
      drawer: const CureRoomDrawer(),
      body: Column(
        children: [
          SafeArea(
            top: true,
            child: _buildDynamicHeader(context, navProvider),
          ),
          Expanded(
            child: PageView(
              controller: _pageController,
              physics: const BouncingScrollPhysics(),
              onPageChanged: (index) {
                context.read<BottomNavProvider>().changeIndex(index);
              },
              children: [
                const HomeTab(),
                const CalendarScreen(),
                const CureNursingTab(), // _buildPlaceholderTab("📝 증상일지 (준비중)"),
                const StoryTab(), // 뿌듯일지
                const MoreTab(),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: navProvider.currentIndex,
        onTap: (index) {
          if (index == 0 && navProvider.currentIndex == 0 && navProvider.isCureMode) {
            navProvider.clearCurer();
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('메인 모드로 전환되었습니다.'), duration: Duration(seconds: 1)),
            );
            return;
          }
          navProvider.changeIndex(index);
          _pageController.jumpToPage(index);
        },
        type: BottomNavigationBarType.fixed,
        backgroundColor: Colors.white,
        selectedItemColor: AppColors.mainBtn,
        unselectedItemColor: Colors.grey,
        selectedFontSize: 12,
        unselectedFontSize: 12,
        elevation: 8,
        items: [
          BottomNavigationBarItem(
            icon: Icon(navProvider.isCureMode ? Icons.local_hospital : Icons.home_filled),
            label: navProvider.isCureMode ? '큐어룸' : '홈',
          ),
          const BottomNavigationBarItem(icon: Icon(Icons.calendar_today), label: '캘린더'),
          const BottomNavigationBarItem(icon: Icon(Icons.edit_note), label: '증상일지'),
          const BottomNavigationBarItem(icon: Icon(Icons.book), label: '뿌듯일지'),
          const BottomNavigationBarItem(icon: Icon(Icons.more_horiz), label: '더보기'),
        ],
      ),
    );
  }

  Widget _buildDynamicHeader(BuildContext context, BottomNavProvider provider) {
    return AppBar(
      elevation: 0,
      backgroundColor: Colors.white,
      centerTitle: false,
      automaticallyImplyLeading: false,
      // 타이틀 영역 전체 터치 시 드로어 열기
      title: GestureDetector(
        onTap: () {
          _scaffoldKey.currentState?.openDrawer();
        },
        behavior: HitTestBehavior.opaque,
        child: provider.isMainMode
            ? _buildMainLogo()
            : _buildCurerHeader(context, provider),
      ),
      actions: [
        // ✅ Row로 묶어 아이콘 간 간격을 정밀 제어합니다.
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // 1. 알림 아이콘
            _buildCustomActionIcon(

              icon: Icons.notifications_none,
              onTap: () {
               // 알림 화면 이동 로직
              },
            ),

            // 2. 설정 아이콘 (큐어룸 모드일 때만)
            if (provider.isCureMode) ...[
              _buildCustomActionIcon(
                icon: Icons.settings_outlined,
                onTap: () async {
                  final curer = provider.selectedCurer;
                  if (curer == null) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('선택된 큐어룸이 없습니다.')),
                    );
                    return;
                  }

                  final int cureSeq = curer.cureSeq; // ✅ 선택된 큐어룸 ID

                  try {
                    // 1) 큐어룸 단건 조회
                    final cureRoomData = await _cureRoomService.getCureRoom(cureSeq);
                    if (!context.mounted) return;

                    // 2) 설정 화면으로 이동 + 현재 공개 여부(bool)를 결과로 받기
                    final bool? isPublic = await context.push<bool>(
                      RoutePaths.cureRoomSettings,
                      extra: cureRoomData,
                    );

                    // 3) 사용자가 설정 화면에서 돌아올 때 값이 넘어온 경우만 처리
                   if (isPublic != null) {
                      // immutable하게 새 curer 만들기
                      final updatedCurer = curer.copyWith(
                        releaseYn: isPublic ? 'Y' : 'N',
                      );

                      // Provider에 반영 (화면들 리빌드)
                      provider.selectCurer(updatedCurer);
                    }

                  } catch (e) {
                    if (!context.mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('큐어룸 정보를 불러오지 못했어요: $e')),
                    );
                  }
                },
              ),
            ],

            // 오른쪽 끝 여백 (화면 가장자리와의 간격)
            const SizedBox(width: 16),
          ],
        ),
      ],
    );
  }

  Widget _buildCustomActionIcon({
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20), // 터치 시 원형 물결 효과
        child: Padding(
          padding: const EdgeInsets.all(6.0), // 🟢 이 값을 조절하여 아이콘 간격을 제어하세요 (작을수록 가까워짐)
          child: Icon(icon, color: AppColors.black, size: 24),
        ),
      ),
    );
  }

  Widget _buildMainLogo() {
    return const Row(
      children: [
        Text(
          'Curemate',
          style: TextStyle(
            color: AppColors.mainBtn,
            fontFamily: 'Pretendard',
            fontWeight: FontWeight.w900,
            fontSize: 22,
            letterSpacing: -0.5,
          ),
        ),
        SizedBox(width: 4),
        Icon(Icons.chevron_right, color: AppColors.mainBtn, size: 24),
      ],
    );
  }

  Widget _buildCurerHeader(BuildContext context, BottomNavProvider provider) {
    final curer = provider.selectedCurer;
    final String cureName = curer?.cureNm ?? '큐어룸';
    final String? profileUrl = curer?.profileImgUrl;
    final bool hasImage = profileUrl != null && profileUrl.isNotEmpty;

    return Row(
      children: [
        // ✅ 이미지 로드 에러 방지 처리
        CircleAvatar(
          radius: 16,
          backgroundColor: AppColors.lightGrey,
          // 이미지가 있을 때만 NetworkImage 사용
          backgroundImage: hasImage ? NetworkImage(profileUrl!) : null,
          // 이미지 로드 실패 시 호출 (SocketException 등 방지)
          onBackgroundImageError: hasImage
              ? (exception, stackTrace) {
            print('헤더 이미지 로드 실패: $exception');
          } : null,
          // 이미지가 없을 때만 아이콘 표시
          child: !hasImage
              ? const Icon(Icons.healing, size: 18, color: AppColors.grey)
              : null,
        ),
        const SizedBox(width: 8),

        Flexible(
          child: Text(
            cureName,
            style: const TextStyle(color: Colors.black, fontSize: 16, fontWeight: FontWeight.bold),
            overflow: TextOverflow.ellipsis,
          ),
        ),
        const SizedBox(width: 4),
        const Icon(Icons.chevron_right, color: Colors.black, size: 20),
      ],
    );
  }

  Widget _buildPlaceholderTab(String title) {
    return Container(
      color: Colors.white,
      child: Center(
        child: Text(
          title,
          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.grey),
        ),
      ),
    );
  }
}