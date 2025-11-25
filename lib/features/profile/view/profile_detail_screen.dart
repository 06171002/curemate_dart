// lib/features/profile/view/profile_detail_screen.dart

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class ProfileDetailScreen extends StatefulWidget {
  final int userId;

  const ProfileDetailScreen({
    super.key,
    required this.userId,
  });

  @override
  State<ProfileDetailScreen> createState() => _ProfileDetailScreenState();
}

class _ProfileDetailScreenState extends State<ProfileDetailScreen> {
  bool _isLoading = true;
  Map<String, dynamic>? _userData;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    setState(() => _isLoading = true);

    try {
      // TODO: API 호출로 사용자 정보 조회
      await Future.delayed(const Duration(seconds: 1));

      // 샘플 데이터
      _userData = {
        'userId': widget.userId,
        'name': '사용자 ${widget.userId}',
        'email': 'user${widget.userId}@example.com',
        'phone': '010-1234-5678',
        'address': '서울시 강남구',
        'joinDate': '2024-01-01',
        'bio': '안녕하세요! 사용자 ${widget.userId}입니다.',
      };
    } catch (e) {
      print('사용자 정보 로드 실패: $e');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('프로필 상세 (ID: ${widget.userId})'),
        actions: [
          IconButton(
            icon: const Icon(Icons.share),
            onPressed: () {
              // 공유
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('프로필 공유')),
              );
            },
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _userData == null
          ? _buildErrorView()
          : _buildProfileDetail(),
    );
  }

  Widget _buildErrorView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, size: 80, color: Colors.red),
          const SizedBox(height: 16),
          const Text('사용자 정보를 불러올 수 없습니다'),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: _loadUserData,
            child: const Text('다시 시도'),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileDetail() {
    return RefreshIndicator(
      onRefresh: _loadUserData,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // 프로필 이미지
          Center(
            child: Stack(
              children: [
                CircleAvatar(
                  radius: 60,
                  backgroundColor: Theme.of(context).primaryColor.withOpacity(0.2),
                  child: Text(
                    _userData!['name'].substring(0, 1).toUpperCase(),
                    style: const TextStyle(
                      fontSize: 48,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: Colors.green,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2),
                    ),
                    child: const Icon(
                      Icons.check,
                      size: 16,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // 사용자 이름
          Center(
            child: Text(
              _userData!['name'],
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(height: 8),

          // Bio
          if (_userData!['bio'] != null)
            Center(
              child: Text(
                _userData!['bio'],
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.grey[600],
                ),
              ),
            ),
          const SizedBox(height: 24),

          // 상세 정보
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '상세 정보',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const Divider(height: 24),
                  _buildInfoRow(Icons.email, '이메일', _userData!['email']),
                  _buildInfoRow(Icons.phone, '전화번호', _userData!['phone']),
                  _buildInfoRow(Icons.location_on, '주소', _userData!['address']),
                  _buildInfoRow(Icons.calendar_today, '가입일', _userData!['joinDate']),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // 활동
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '활동',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const Divider(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildActivityItem('게시물', '15'),
                      _buildActivityItem('댓글', '42'),
                      _buildActivityItem('좋아요', '128'),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // 액션 버튼
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('메시지 보내기')),
                    );
                  },
                  icon: const Icon(Icons.message),
                  label: const Text('메시지'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('팔로우')),
                    );
                  },
                  icon: const Icon(Icons.person_add),
                  label: const Text('팔로우'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Colors.grey[600]),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: const TextStyle(fontSize: 14),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActivityItem(String label, String value) {
    return Column(
      children: [
        Text(
          value,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }
}
