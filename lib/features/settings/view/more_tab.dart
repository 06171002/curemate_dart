import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:curemate/routes/route_paths.dart';
import 'package:curemate/app/theme/app_colors.dart';
import 'package:curemate/features/auth/viewmodel/auth_viewmodel.dart';
import 'package:curemate/features/widgets/common/bottom_nav_provider.dart';
import 'package:curemate/features/test/view/test_screen.dart';

class MoreTab extends StatelessWidget {
  const MoreTab({super.key});

  @override
  Widget build(BuildContext context) {
    final authViewModel = context.watch<AuthViewModel>();

    const sectionTitleStyle = TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.bold,
        color: Colors.black87 // 너무 진한 검정 대신 부드러운 검정
    );

    return Container(
      // 배경색을 웜 크림(warmCream) 또는 라이트 그레이로 설정하면 은은한 흰색 카드가 돋보입니다.
      color: AppColors.lightBackground,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 1. 프로필 카드
            _buildProfileCard(context, authViewModel),
            const SizedBox(height: 24),

            // 2. 나의 활동 목록
            const Text("나의 활동 목록", style: sectionTitleStyle),
            const SizedBox(height: 12),
            _buildActivityCard(context),
            const SizedBox(height: 24),

            // 3. 메뉴 리스트
            _buildMenuItem(
              context,
              title: "개발자 테스트 페이지",
              icon: Icons.bug_report,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const TestScreen()),
                );
              },
            ),
            _buildMenuItem(
              context,
              title: "로그아웃",
              icon: Icons.logout,
              onTap: () async {
                final shouldLogout = await _showLogoutDialog(context);
                if (shouldLogout == true) {
                  // ignore: use_build_context_synchronously
                  context.read<BottomNavProvider>().reset();
                  await authViewModel.signOut();
                }
              },
            ),
            _buildMenuItem(
              context,
              title: "회원탈퇴",
              icon: Icons.person_off,
              textColor: AppColors.error,
              iconColor: AppColors.error,
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("회원탈퇴 기능은 준비 중입니다.")),
                );
              },
            ),

            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  // 🔹 프로필 카드 (은은한 그림자 적용)
  Widget _buildProfileCard(BuildContext context, AuthViewModel viewModel) {
    String formattedRegDate = "가입일 정보 없음";

    if (viewModel.customer?.regDttm != null) {
      try {
        DateTime regDate = DateTime.parse(viewModel.customer!.regDttm!);
        formattedRegDate = DateFormat('yyyy년 M월 d일 가입').format(regDate);
      } catch (e) {
        formattedRegDate = viewModel.customer!.regDttm!;
      }
    }

    return Card(
      elevation: 0.5, // ✅ 아주 살짝 띄움
      shadowColor: Colors.grey.withOpacity(0.2), // ✅ 그림자 색상을 매우 연하게
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        // side: BorderSide.none, // 테두리 없음
      ),
      margin: EdgeInsets.zero,
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 프로필 이미지 영역
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.lightGrey,
                    // 이미지는 깔끔하게 테두리 없이
                    image: (viewModel.profileImgUrl != null && viewModel.profileImgUrl!.isNotEmpty)
                        ? DecorationImage(
                      image: NetworkImage(viewModel.profileImgUrl!),
                      fit: BoxFit.cover,
                    )
                        : null,
                  ),
                  child: (viewModel.profileImgUrl == null || viewModel.profileImgUrl!.isEmpty)
                      ? const Icon(Icons.person, size: 40, color: AppColors.grey)
                      : null,
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Text(
                            viewModel.userName ?? "사용자",
                            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                          const Text("님", style: TextStyle(fontSize: 18)),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        viewModel.customer?.custNickname ?? "닉네임 없음",
                        style: const TextStyle(
                          fontSize: 14,
                          color: AppColors.mainBtn,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          const Icon(Icons.calendar_today, size: 14, color: Colors.grey),
                          const SizedBox(width: 6),
                          Text(
                            formattedRegDate,
                            style: const TextStyle(fontSize: 13, color: Colors.grey),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  context.push(RoutePaths.profileEdit);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.mainBtn,
                  foregroundColor: Colors.white,
                  elevation: 0, // 버튼은 플랫하게 유지
                  minimumSize: const Size.fromHeight(48),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
                child: const Text("내 정보 수정", style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // 🔹 활동 목록 카드 (은은한 그림자 적용)
  Widget _buildActivityCard(BuildContext context) {
    return Card(
      elevation: 0.5, // ✅ 아주 살짝 띄움
      shadowColor: Colors.grey.withOpacity(0.2), // ✅ 연한 그림자
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      margin: EdgeInsets.zero,
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 20),
        child: Row(
          children: [
            Expanded(
              child: _buildIconLabelButton(
                Icons.favorite,
                "좋아요",
                iconColor: AppColors.pinkIconColor,
              ),
            ),
            // 가운데 구분선은 아주 연하게
            Container(width: 1, height: 24, color: Colors.grey[200]),
            Expanded(
              child: _buildIconLabelButton(
                Icons.chat_bubble_outline,
                "댓글",
                iconColor: AppColors.mainBtn,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildIconLabelButton(IconData icon, String label, {Color? iconColor}) {
    return InkWell(
      onTap: () {},
      borderRadius: BorderRadius.circular(8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 26, color: iconColor ?? Colors.black87),
          const SizedBox(width: 8),
          Text(
            label,
            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }

  // 🔹 메뉴 리스트 아이템 (은은한 그림자 적용)
  Widget _buildMenuItem(
      BuildContext context, {
        required String title,
        required IconData icon,
        required VoidCallback onTap,
        Color? textColor,
        Color? iconColor,
      }) {
    return Card(
      elevation: 0.5, // ✅ 아주 살짝 띄움
      shadowColor: Colors.grey.withOpacity(0.1), // ✅ 더 연한 그림자 (리스트는 더 가볍게)
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      color: Colors.white,
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: (iconColor ?? AppColors.black).withOpacity(0.05),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: iconColor ?? AppColors.black, size: 20),
        ),
        title: Text(
          title,
          style: TextStyle(
            color: textColor ?? const Color(0xFF2D3436),
            fontWeight: FontWeight.w600,
            fontSize: 15,
          ),
        ),
        trailing: const Icon(Icons.chevron_right, color: Colors.grey, size: 20),
        onTap: onTap,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  Future<bool?> _showLogoutDialog(BuildContext context) {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('로그아웃', style: TextStyle(fontWeight: FontWeight.bold)),
        content: const Text('정말 로그아웃 하시겠습니까?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('취소', style: TextStyle(color: Colors.grey)),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: const Text('로그아웃'),
          ),
        ],
      ),
    );
  }
}