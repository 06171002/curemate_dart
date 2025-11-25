// lib/features/auth/view/login_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';

import '../viewmodel/auth_viewmodel.dart';
import '../../../app/theme/app_colors.dart';
import '../../../routes/route_paths.dart';

final Color backgroundColor = const Color(0xFFF0F8FF);

class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<AuthViewModel>();

    // ✅ Stack을 사용하여 전체 화면 로딩 구현
    return Scaffold(
      backgroundColor: backgroundColor,
      body: Stack(
        children: [
          // 1. 기존 로그인 화면 내용
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                child: Container(
                  constraints: const BoxConstraints(maxWidth: 400),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24.0,
                    vertical: 32.0,
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _buildHeader(context),
                      const SizedBox(height: 40),
                      _buildDivider(context),
                      const SizedBox(height: 20),
                      _buildSocialLoginButtons(context, viewModel), // 버튼 항상 표시
                      const SizedBox(height: 32),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // 2. 전체 화면 로딩 오버레이 (isLoading일 때만 표시)
          if (viewModel.isLoading)
            Container(
              width: double.infinity,
              height: double.infinity,
              color: Colors.black.withOpacity(0.3), // 반투명 배경
              child: const Center(
                child: CircularProgressIndicator(
                  color: AppColors.mainBtn,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      children: [
        Text(
          'Cure Mate',
          textAlign: TextAlign.center,
          style: theme.textTheme.displaySmall?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Text(
          '당신의 건강 관리 파트너',
          textAlign: TextAlign.center,
          style: theme.textTheme.titleMedium?.copyWith(
            color: theme.colorScheme.secondary,
            fontWeight: FontWeight.normal,
          ),
        ),
      ],
    );
  }

  Widget _buildDivider(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      children: [
        const Expanded(child: Divider()),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Text(
            'SNS 계정으로 시작하기',
            style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.secondary),
          ),
        ),
        const Expanded(child: Divider()),
      ],
    );
  }

  // 버튼은 로딩 여부와 관계없이 항상 렌더링 (오버레이가 클릭 막음)
  Widget _buildSocialLoginButtons(BuildContext context, AuthViewModel viewModel) {
    final theme = Theme.of(context);
    final googleButtonTextColor = theme.brightness == Brightness.dark
        ? theme.colorScheme.onSurface
        : const Color(0xFF1F2937);

    return Column(
      children: [
        // Google
        ElevatedButton.icon(
          onPressed: () async {
            await viewModel.signInWithGoogle();
            if (viewModel.errorMessage != null && context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(viewModel.errorMessage!)),
              );
              viewModel.clearError();
            }
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: theme.colorScheme.surface,
            foregroundColor: googleButtonTextColor,
            elevation: 0,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            padding: const EdgeInsets.symmetric(vertical: 16),
            minimumSize: const Size(double.infinity, 56),
          ),
          icon: SvgPicture.asset('assets/svgs/ic_google.svg', width: 24, height: 24),
          label: Text('Google로 로그인',
              style: theme.textTheme.labelLarge?.copyWith(color: googleButtonTextColor)),
        ),
        const SizedBox(height: 12),

        // Kakao
        ElevatedButton.icon(
          icon: SvgPicture.asset('assets/svgs/ic_kakao.svg', width: 24, height: 24),
          label: const Text('카카오로 로그인'),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.kakaoYellow,
            foregroundColor: Colors.black.withOpacity(0.85),
            minimumSize: const Size(double.infinity, 56),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
            padding: const EdgeInsets.symmetric(vertical: 16),
          ),
          onPressed: () async {
            await viewModel.signInWithKakao();
          },
        ),
        const SizedBox(height: 12),

        // Naver
        ElevatedButton.icon(
          icon: SvgPicture.asset('assets/svgs/ic_naver.svg', width: 24, height: 24),
          label: const Text('네이버로 로그인'),
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF03C75A),
            foregroundColor: Colors.white,
            minimumSize: const Size(double.infinity, 56),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
            padding: const EdgeInsets.symmetric(vertical: 16),
          ),
          onPressed: () {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('네이버 로그인 준비 중입니다')),
            );
          },
        ),
      ],
    );
  }
}