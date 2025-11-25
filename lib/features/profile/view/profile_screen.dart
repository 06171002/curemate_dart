// lib/features/profile/view/profile_screen.dart

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../auth/viewmodel/auth_viewmodel.dart';
import '../../../routes/route_paths.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final authViewModel = context.watch<AuthViewModel>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('프로필'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              // 설정 화면으로 이동
            },
          ),
        ],
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // 프로필 헤더
            Card(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    CircleAvatar(
                      radius: 50,
                      backgroundColor: Theme.of(context).primaryColor.withOpacity(0.2),
                      child: Text(
                        authViewModel.userName?.substring(0, 1).toUpperCase() ?? 'U',
                        style: const TextStyle(
                          fontSize: 40,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      authViewModel.userName ?? '사용자',
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    if (authViewModel.userEmail != null) ...[
                      const SizedBox(height: 8),
                      Text(
                        authViewModel.userEmail!,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                    const SizedBox(height: 16),
                    ElevatedButton.icon(
                      onPressed: () {
                        // 프로필 수정
                      },
                      icon: const Icon(Icons.edit),
                      label: const Text('프로필 수정'),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
        
            // 통계
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildStatItem(context, '게시물', '24'),
                    _buildStatItem(context, '팔로워', '128'),
                    _buildStatItem(context, '팔로잉', '89'),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
        
            // 메뉴 리스트
            _buildMenuItem(
              context,
              icon: Icons.person,
              title: '내 정보',
              onTap: () {
                // custSeq를 사용하여 프로필 상세로 이동
                if (authViewModel.custSeq != null) {
                  context.push(RoutePaths.profileDetail(authViewModel.custSeq!));
                }
              },
            ),
            _buildMenuItem(
              context,
              icon: Icons.favorite,
              title: '즐겨찾기',
              onTap: () {},
            ),
            _buildMenuItem(
              context,
              icon: Icons.bookmark,
              title: '저장된 게시물',
              onTap: () {},
            ),
            _buildMenuItem(
              context,
              icon: Icons.history,
              title: '활동 기록',
              onTap: () {},
            ),
            const Divider(height: 32),
            _buildMenuItem(
              context,
              icon: Icons.help,
              title: '도움말',
              onTap: () {},
            ),
            _buildMenuItem(
              context,
              icon: Icons.info,
              title: '정보',
              onTap: () {},
            ),
            _buildMenuItem(
              context,
              icon: Icons.logout,
              title: '로그아웃',
              textColor: Colors.red,
              onTap: () async {
                final shouldLogout = await _showLogoutDialog(context);
                if (shouldLogout == true) {
                  await authViewModel.signOut();
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(BuildContext context, String label, String value) {
    return Column(
      children: [
        Text(
          value,
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }

  Widget _buildMenuItem(
      BuildContext context, {
        required IconData icon,
        required String title,
        required VoidCallback onTap,
        Color? textColor,
      }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Icon(icon, color: textColor),
        title: Text(
          title,
          style: TextStyle(color: textColor),
        ),
        trailing: const Icon(Icons.chevron_right),
        onTap: onTap,
      ),
    );
  }

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