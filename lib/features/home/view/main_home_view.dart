// lib/features/home/view/main_home_view.dart

import 'package:curemate/features/widgets/common/custom_profile_avatar.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:curemate/app/theme/app_colors.dart';
import 'package:curemate/routes/route_paths.dart';
import 'package:curemate/features/auth/viewmodel/auth_viewmodel.dart';
import 'package:curemate/features/cure_room/viewmodel/cure_room_list_viewmodel.dart';
import 'package:curemate/features/widgets/common/bottom_nav_provider.dart';
import 'package:curemate/features/cure_room/model/curer_model.dart';

class MainHomeView extends StatefulWidget {
  const MainHomeView({super.key});

  @override
  State<MainHomeView> createState() => _MainHomeViewState();
}

class _MainHomeViewState extends State<MainHomeView> {
  // ✅ 건강 팁 데이터 리스트
  final List<Map<String, dynamic>> _healthTips = [
    {
      'icon': Icons.local_drink_outlined,
      'color': Colors.blueAccent,
      'title': '수분 섭취의 중요성',
      'content': '하루 8잔의 물은 신진대사를 원활하게 합니다. 틈틈이 물을 마셔주세요!',
    },
    {
      'icon': Icons.directions_walk,
      'color': Colors.green,
      'title': '가벼운 산책하기',
      'content': '하루 30분 걷기는 심혈관 건강에 큰 도움이 됩니다. 햇볕을 쬐며 걸어보세요.',
    },
    {
      'icon': Icons.bedtime_outlined,
      'color': Colors.deepPurple,
      'title': '충분한 수면 취하기',
      'content': '하루 7-8시간의 수면은 면역력을 높이고 피로 회복에 필수적입니다.',
    },
    {
      'icon': Icons.sentiment_satisfied_alt,
      'color': Colors.orange,
      'title': '긍정적인 마음가짐',
      'content': '스트레스는 만병의 근원입니다. 하루 한 번 크게 웃어보세요!',
    },
  ];

  int _currentTipIndex = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<CureRoomListViewModel>().fetchCureRooms();
    });
  }

  @override
  Widget build(BuildContext context) {
    final authViewModel = context.watch<AuthViewModel>();
    final cureRoomViewModel = context.watch<CureRoomListViewModel>();

    return Container(
      // ✅ [수정 1] 배경색을 MoreTab과 동일하게 lightBackground로 변경
      color: AppColors.lightBackground,
      child: RefreshIndicator(
        onRefresh: () async {
          await context.read<CureRoomListViewModel>().fetchCureRooms();
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.symmetric(vertical: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildWelcomeHeader(authViewModel.userName ?? '사용자'),
              const SizedBox(height: 32),

              _buildSectionTitle('나의 큐어룸'),
              const SizedBox(height: 12),
              _buildCureRoomList(context, cureRoomViewModel),
              const SizedBox(height: 32),

              _buildSectionTitle('빠른 실행'),
              const SizedBox(height: 12),
              _buildQuickActions(context),
              const SizedBox(height: 32),

              _buildSectionTitle('오늘의 건강 팁'),
              const SizedBox(height: 12),
              _buildHealthTipSlider(),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  // ... (_buildWelcomeHeader, _buildCureRoomList 등 다른 메서드는 기존과 동일) ...
  Widget _buildWelcomeHeader(String userName) {
    // 기존 코드 유지
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text(
                '안녕하세요, ',
                style: TextStyle(
                  fontSize: 22,
                  color: AppColors.textMainDark,
                  fontWeight: FontWeight.normal,
                ),
              ),
              Text(
                '$userName님!',
                style: const TextStyle(
                  fontSize: 22,
                  color: AppColors.textMainDark,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          const Text(
            '오늘도 건강한 하루 보내세요 🌿',
            style: TextStyle(
              fontSize: 14,
              color: AppColors.textSecondaryLight,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCureRoomList(BuildContext context, CureRoomListViewModel viewModel) {
    // 기존 코드 유지
    if (viewModel.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (viewModel.cureRooms.isEmpty) {
      return _buildEmptyCureRoomCard(context);
    }
    return SizedBox(
      height: 160,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        scrollDirection: Axis.horizontal,
        itemCount: viewModel.cureRooms.length,
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemBuilder: (context, index) {
          final curer = viewModel.cureRooms[index];
          return _buildCureRoomCard(context, curer);
        },
      ),
    );
  }

  Widget _buildCureRoomCard(BuildContext context, CurerModel curer) {
    // 기존 코드 유지
    return InkWell(
      onTap: () {
        context.read<BottomNavProvider>().selectCurer(curer);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${curer.cureNm}으로 입장합니다.')),
        );
      },
      borderRadius: BorderRadius.circular(16),
      child: Container(
        width: 140,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.lightGrey),
          boxShadow: [
            BoxShadow(
              color: AppColors.shadow,
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            CustomProfileAvatar(
              imageUrl: curer.profileImgUrl,
              radius: 24, // 크기 지정
              fallbackIcon: Icons.healing, // 큐어룸은 healing 아이콘 사용
              backgroundColor: AppColors.memberBg, // 배경색 지정 (선택)
              iconColor: AppColors.mainBtn, // 아이콘 색상 지정 (선택)
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  curer.cureNm,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textMainDark,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  curer.cureDesc ?? '환자를 위한 공간',
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondaryLight,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyCureRoomCard(BuildContext context) {
    // 기존 코드 유지
    return GestureDetector(
      onTap: () => context.push(RoutePaths.addCureRoom),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 20),
        width: double.infinity,
        height: 120,
        decoration: BoxDecoration(
          color: AppColors.lightGrey, // Empty 카드는 lightGrey 유지 (배경과 구분됨)
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey[300]!, style: BorderStyle.solid),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: const [
            Icon(Icons.add_circle_outline, size: 32, color: Colors.grey),
            SizedBox(height: 8),
            Text(
              '새로운 큐어룸을 만들어보세요',
              style: TextStyle(color: Colors.grey, fontWeight: FontWeight.w600),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActions(BuildContext context) {
    // 기존 코드 유지
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: [
          Expanded(
            child: _buildActionButton(
              icon: Icons.add_home_work_outlined,
              label: '큐어룸 만들기',
              color: AppColors.mainBtn,
              onTap: () => context.push(RoutePaths.addCureRoom),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: _buildActionButton(
              icon: Icons.qr_code_scanner,
              label: '초대 코드 입력',
              color: AppColors.textMainDark,
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('초대 코드 입력 기능은 준비 중입니다.')),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    // 기존 코드 유지
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.lightGrey), // 흰색 버튼이므로 테두리 유지
          boxShadow: [
            BoxShadow(
              color: AppColors.shadow,
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 28),
            const SizedBox(height: 8),
            Text(
              label,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppColors.textMainDark,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHealthTipSlider() {
    return Column(
      children: [
        SizedBox(
          height: 140,
          child: PageView.builder(
            controller: PageController(viewportFraction: 0.9),
            itemCount: _healthTips.length,
            onPageChanged: (index) {
              setState(() {
                _currentTipIndex = index;
              });
            },
            itemBuilder: (context, index) {
              final tip = _healthTips[index];
              return _buildHealthTipCard(tip);
            },
          ),
        ),
        const SizedBox(height: 12),
        // 인디케이터
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(_healthTips.length, (index) {
            return AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              margin: const EdgeInsets.symmetric(horizontal: 4),
              width: _currentTipIndex == index ? 20 : 8,
              height: 8,
              decoration: BoxDecoration(
                color: _currentTipIndex == index
                    ? AppColors.mainBtn
                    : AppColors.grey.withValues(alpha: 0.3), // 살짝 진하게 수정
                borderRadius: BorderRadius.circular(4),
              ),
            );
          }),
        ),
      ],
    );
  }

  Widget _buildHealthTipCard(Map<String, dynamic> tip) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 6),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        // ✅ [수정 2] 카드를 흰색으로 변경하여 lightBackground 위에서 돋보이게 함
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppColors.shadow,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // 아이콘 배경을 살짝 넣어줌 (선택 사항)
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: (tip['color'] as Color).withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(tip['icon'] as IconData, color: tip['color'] as Color, size: 28),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  tip['title'] as String,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: AppColors.textMainDark,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  tip['content'] as String,
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppColors.textMainDark,
                    height: 1.3,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    // 기존 코드 유지
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: AppColors.textMainDark,
        ),
      ),
    );
  }
}