import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:curemate/features/widgets/common/bottom_nav_provider.dart';
import 'package:curemate/app/theme/app_colors.dart';

class MainHomeView extends StatelessWidget {
  const MainHomeView({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.dashboard, size: 80, color: AppColors.mainBtn),
          const SizedBox(height: 16),
          const Text(
            '메인 홈 화면',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          const Text(
            '등록된 모든 환자의 요약을 볼 수 있습니다.',
            style: TextStyle(color: Colors.grey),
          ),
          const SizedBox(height: 32),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 48.0), // 좌우 여백을 넉넉히 줌
            child: ElevatedButton.icon(
              onPressed: () {
                // 테스트 페이지와 동일한 기능: 환자 선택 시뮬레이션 (모드 전환)
                context.read<BottomNavProvider>().selectPatient(
                  1, // ID
                  {'id': 1, 'name': '홍길동', 'age': 30, 'gender': '남'}, // Info Map
                );

                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('환자 모드로 전환되었습니다.')),
                );
              },
              icon: const Icon(Icons.person_pin_circle),
              label: const Text('환자 선택 시뮬레이션'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.mainBtn,
                foregroundColor: Colors.white,
                minimumSize: const Size.fromHeight(50), // 높이 고정
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 2, // 살짝 그림자 추가
              ),
            ),
          ),
        ],
      ),
    );
  }
}