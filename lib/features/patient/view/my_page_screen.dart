import 'package:flutter/material.dart';

class MyPageScreen extends StatelessWidget {
  const MyPageScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("마이페이지"),
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // 🔹 내 정보 카드
          _buildProfileCard(),

          const SizedBox(height: 20),

          // 🔹 내 역할 및 관리 대상
          _buildSectionTitle("내 역할 & 연결"),
          _buildRoleAndConnections(),

          const SizedBox(height: 20),

          // 🔹 보호자/환자 관리
          _buildSectionTitle("연결 관리"),
          _buildConnectionActions(context),

          const SizedBox(height: 20),

          // 🔹 앱 설정
          _buildSectionTitle("환경설정"),
          _buildSettings(),
        ],
      ),
    );
  }

  /// 프로필 카드
  Widget _buildProfileCard() {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 3,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            const CircleAvatar(
              radius: 32,
              backgroundImage: NetworkImage(
                  "https://via.placeholder.com/150"), // TODO: 사용자 프로필 이미지
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text("홍길동",
                      style:
                          TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const Text("보호자 / user@example.com",
                      style: TextStyle(color: Colors.grey)),
                  const SizedBox(height: 8),
                  ElevatedButton(
                    onPressed: () {
                      // TODO: 내 정보 수정 이동
                    },
                    child: const Text("내 정보 수정"),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 섹션 타이틀
  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Text(
        title,
        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
      ),
    );
  }

  /// 내 역할 및 환자/보호자 연결
  Widget _buildRoleAndConnections() {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 2,
      child: Column(
        children: [
          ListTile(
            leading: const Icon(Icons.person),
            title: const Text("내 역할"),
            subtitle: const Text("보호자"),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () {
              // TODO: 역할 세부 정보 페이지
            },
          ),
          const Divider(height: 1),
          ListTile(
            leading: const Icon(Icons.group),
            title: const Text("관리하는 환자"),
            subtitle: const Text("김철수, 이영희"),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () {
              // TODO: 환자 목록 이동
            },
          ),
          const Divider(height: 1),
          ListTile(
            leading: const Icon(Icons.person),
            title: const Text("연결된 보호자"),
            subtitle: const Text("2명"),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () {
              // TODO: 보호자 목록 이동
            },
          ),
        ],
      ),
    );
  }

  /// 보호자/환자 관리 액션
  Widget _buildConnectionActions(BuildContext context) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 2,
      child: Column(
        children: [
          ListTile(
            leading: const Icon(Icons.mail_outline, color: Colors.blue),
            title: const Text("보호자 초대하기"),
            onTap: () {
              // TODO: 이메일 초대 다이얼로그
            },
          ),
          const Divider(height: 1),
          ListTile(
            leading: const Icon(Icons.person_add_alt_1, color: Colors.green),
            title: const Text("환자 추가 등록"),
            onTap: () {
              // TODO: 환자 등록 페이지 이동
            },
          ),
        ],
      ),
    );
  }

  /// 앱 설정
  Widget _buildSettings() {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 2,
      child: Column(
        children: [
          SwitchListTile(
            value: true, // TODO: Provider에서 다크모드 값 가져오기
            onChanged: (val) {
              // TODO: 다크모드 토글
            },
            title: const Text("다크 모드"),
            secondary: const Icon(Icons.dark_mode),
          ),
          const Divider(height: 1),
          ListTile(
            leading: const Icon(Icons.language),
            title: const Text("언어 설정"),
            onTap: () {
              // TODO: 언어 설정 페이지
            },
          ),
          const Divider(height: 1),
          ListTile(
            leading: const Icon(Icons.info_outline),
            title: const Text("앱 정보"),
            subtitle: const Text("버전 1.0.0"),
          ),
          const Divider(height: 1),
          ListTile(
            leading: const Icon(Icons.logout, color: Colors.red),
            title: const Text("로그아웃"),
            onTap: () {
              // TODO: 로그아웃 처리
            },
          ),
        ],
      ),
    );
  }
}
