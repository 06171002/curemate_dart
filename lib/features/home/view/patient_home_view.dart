import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:curemate/features/widgets/common/bottom_nav_provider.dart';
import 'package:curemate/app/theme/app_colors.dart';

class PatientHomeView extends StatelessWidget {
  const PatientHomeView({super.key});

  @override
  Widget build(BuildContext context) {
    // Provider에서 현재 선택된 환자 정보 가져오기
    final provider = context.watch<BottomNavProvider>();
    final patientName = provider.patientInfo?['name'] ?? '이름 없음';

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.person_pin, size: 80, color: Colors.green),
          const SizedBox(height: 16),
          Text(
            '$patientName 님의 홈',
            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          const Text(
            '해당 환자의 일정, 복약 정보를 관리합니다.',
            style: TextStyle(color: Colors.grey),
          ),
          const SizedBox(height: 32),

          // ✅ 버튼 수정: 좌우 여백(padding) 추가 및 스타일 개선
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 48.0),
            child: OutlinedButton.icon(
              onPressed: () {
                // 메인 모드로 돌아가는 기능
                provider.clearPatient();
              },
              icon: const Icon(Icons.arrow_back),
              label: const Text('메인 모드로 돌아가기'),
              style: OutlinedButton.styleFrom(
                minimumSize: const Size.fromHeight(50), // 높이 고정
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                side: const BorderSide(color: AppColors.mainBtn), // 테두리 색상
                foregroundColor: AppColors.mainBtn, // 텍스트/아이콘 색상
              ),
            ),
          ),
        ],
      ),
    );
  }
}