import 'package:curemate/features/home/view/home_tab.dart';
import 'package:curemate/features/settings/view/more_tab.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:curemate/features/widgets/common/bottom_nav_provider.dart';
import 'package:curemate/app/theme/app_colors.dart';

class MainLayoutScreen extends StatefulWidget {
  const MainLayoutScreen({super.key});

  @override
  State<MainLayoutScreen> createState() => _MainLayoutScreenState();
}

class _MainLayoutScreenState extends State<MainLayoutScreen> {
  late PageController _pageController;

  @override
  void initState() {
    super.initState();
    final provider = context.read<BottomNavProvider>();
    _pageController = PageController(initialPage: provider.currentIndex);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final navProvider = context.watch<BottomNavProvider>();

    return Scaffold(
      // 1. 동적 헤더 (모드에 따라 변경됨)
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(60),
        child: _buildDynamicHeader(context, navProvider),
      ),

      // 2. 본문 (PageView로 탭 구현)
      body: PageView(
        controller: _pageController,
        physics: const BouncingScrollPhysics(),
        onPageChanged: (index) {
          // 스와이프 시 인덱스만 업데이트
          context.read<BottomNavProvider>().changeIndex(index);
        },
        children: [
          const HomeTab(),
          _buildPlaceholderTab("📖 뿌듯일지 (준비중)"),
          _buildPlaceholderTab("🏥 큐어룸 (환자 관리)"),
          _buildPlaceholderTab("📅 캘린더 (준비중)"),
          const MoreTab(),
        ],
      ),

      // 3. 하단 네비게이션
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: navProvider.currentIndex,
        onTap: (index) {
          // 홈 탭(0)을 눌렀는데, 이미 홈 탭이고, 환자 모드라면 -> 메인 모드로 복귀
          if (index == 0 && navProvider.currentIndex == 0 && navProvider.isPatientMode) {
            navProvider.clearPatient();
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('메인 모드로 전환되었습니다.'), duration: Duration(seconds: 1)),
            );
            return; // 페이지 이동 없음
          }

          // 그 외의 경우 해당 탭으로 이동
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
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: '홈'),
          BottomNavigationBarItem(icon: Icon(Icons.book), label: '뿌듯일지'),
          BottomNavigationBarItem(icon: Icon(Icons.local_hospital), label: '큐어룸'),
          BottomNavigationBarItem(icon: Icon(Icons.calendar_today), label: '캘린더'),
          BottomNavigationBarItem(icon: Icon(Icons.more_horiz), label: '더보기'),
        ],
      ),
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

  // ✅ 동적 헤더 빌더
  Widget _buildDynamicHeader(BuildContext context, BottomNavProvider provider) {
    return AppBar(
      elevation: 0,
      backgroundColor: Colors.white,
      centerTitle: false,
      automaticallyImplyLeading: false,
      // 모드에 따라 타이틀 변경 (로고 <-> 환자 정보)
      title: provider.isMainMode
          ? _buildMainLogo()
          : _buildPatientHeader(context, provider),
      actions: [
        IconButton(
          icon: const Icon(Icons.notifications_none, color: Colors.black),
          onPressed: () {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('알림 화면 (준비중)')),
            );
          },
        ),
        const SizedBox(width: 8),
      ],
    );
  }

  Widget _buildMainLogo() {
    return const Row(
      children: [
        Icon(Icons.health_and_safety, color: AppColors.mainBtn),
        SizedBox(width: 8),
        Text(
          'Cure Mate',
          style: TextStyle(
            color: AppColors.mainBtn,
            fontWeight: FontWeight.bold,
            fontSize: 22,
          ),
        ),
      ],
    );
  }

  // ✅ 환자 모드일 때 헤더
  Widget _buildPatientHeader(BuildContext context, BottomNavProvider provider) {
    // Provider에 저장된 환자 이름 가져오기 (없으면 기본값)
    final String patientName = provider.patientInfo?['name'] ?? '환자';

    return GestureDetector(
      onTap: () {
        _showPatientOptions(context, provider);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
        decoration: BoxDecoration(
          color: Colors.grey[100],
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircleAvatar(
              radius: 14,
              backgroundColor: AppColors.lightGrey,
              child: Icon(Icons.person, size: 18, color: Colors.grey),
            ),
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  '$patientName 환자',
                  style: const TextStyle(color: Colors.black, fontSize: 14, fontWeight: FontWeight.bold),
                ),
                const Text(
                  '탭하여 변경 ▾',
                  style: TextStyle(color: Colors.grey, fontSize: 10),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showPatientOptions(BuildContext context, BottomNavProvider provider) {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.home),
              title: const Text('메인 모드로 돌아가기'),
              onTap: () {
                provider.clearPatient(); // ✅ 메인 모드로 복귀
                Navigator.pop(context);
              },
            ),
            // 추후 환자 목록 리스트 추가 가능
          ],
        ),
      ),
    );
  }
}