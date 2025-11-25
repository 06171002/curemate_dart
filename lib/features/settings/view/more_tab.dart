// lib/features/settings/view/more_tab.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:curemate/app/theme/app_colors.dart';
import 'package:curemate/features/auth/viewmodel/auth_viewmodel.dart';
import 'package:curemate/features/test/view/test_screen.dart'; // 테스트 페이지 import

class MoreTab extends StatelessWidget {
  const MoreTab({super.key});

  @override
  Widget build(BuildContext context) {
    final authViewModel = context.watch<AuthViewModel>();

    // 섹션 타이틀 스타일
    const sectionTitleStyle = TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.bold,
        color: Colors.black
    );

    return Container(
      color: const Color(0xFFF5F5F5), // 배경색 (연한 회색)
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
            _buildActivityCard(),
            const SizedBox(height: 32),

            // 3. [개발자용] 테스트 페이지 이동 (임시) - 디자인 통일 및 위치 이동
            _buildActionButton(
              "개발자 테스트 페이지",
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const TestScreen()),
                );
              },
              textColor: Colors.grey[700], // 임시 메뉴임을 나타내는 회색
              icon: Icons.bug_report, // 아이콘 추가 (선택 사항)
            ),
            const SizedBox(height: 12),

            // 4. 로그아웃
            _buildActionButton(
                "로그아웃",
                onTap: () async {
                  await authViewModel.signOut();
                  // signOut 후 라우터가 로그인 페이지로 리다이렉트 처리함
                }
            ),
            const SizedBox(height: 12),

            // 5. 회원탈퇴 (위험 작업이므로 빨간색 처리)
            _buildActionButton(
              "회원탈퇴",
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("회원탈퇴 기능은 준비 중입니다.")),
                );
              },
              textColor: AppColors.error, // 빨간색 텍스트 적용
            ),

            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  // 🔹 프로필 카드 위젯
  Widget _buildProfileCard(BuildContext context, AuthViewModel viewModel) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          // 상단: 아바타 + 이름 + 날짜
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 아바타
              Container(
                width: 64,
                height: 64,
                decoration: const BoxDecoration(
                  color: Color(0xFFE1F5FE), // 연한 하늘색 배경
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.person, size: 40, color: Color(0xFF81D4FA)),
              ),
              const SizedBox(width: 16),

              // 정보
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
                    const Text(
                      "불꽃또리", // 닉네임 (임시)
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.blue,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    const Row(
                      children: [
                        Icon(Icons.calendar_today, size: 16, color: Colors.black),
                        SizedBox(width: 6),
                        Text(
                          "2021년 4월 3일 가입", // 가입일 (임시)
                          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // 하단: 내 정보 수정 버튼
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("내 정보 수정")),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFEEF6FF), // 아주 연한 하늘색
                foregroundColor: Colors.black,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
              child: const Text("내 정보 수정", style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
    );
  }

  // 🔹 활동 목록 카드
  Widget _buildActivityCard() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: _buildIconLabelButton(
              Icons.favorite, // 꽉 찬 하트로 변경 (선택 사항)
              "좋아요",
              iconColor: Colors.redAccent, // ✅ 빨간색 적용
            ),
          ),
          Container(width: 1, height: 24, color: Colors.grey[300]), // 구분선
          Expanded(
            child: _buildIconLabelButton(
              Icons.chat_bubble_outline,
              "댓글",
              iconColor: Colors.blueAccent, // ✅ 파란색 적용
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildIconLabelButton(IconData icon, String label, {Color? iconColor}) {
    return InkWell(
      onTap: () {},
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 28, color: iconColor ?? Colors.black87),
          const SizedBox(width: 8),
          Text(
            label,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  // 🔹 공통 버튼 위젯 (흰색 박스 형태)
  Widget _buildActionButton(
      String text, {
        required VoidCallback onTap,
        Color? textColor,
        IconData? icon, // 아이콘 지원 추가
      }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.03),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (icon != null) ...[
              Icon(icon, size: 20, color: textColor ?? Colors.black),
              const SizedBox(width: 8),
            ],
            Text(
              text,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: textColor ?? Colors.black, // 색상 커스텀 가능
              ),
            ),
          ],
        ),
      ),
    );
  }
}