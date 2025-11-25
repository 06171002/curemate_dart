// lib/features/home/view/home_tab.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:curemate/features/widgets/common/bottom_nav_provider.dart';
import 'main_home_view.dart';
import 'patient_home_view.dart';

class HomeTab extends StatefulWidget {
  const HomeTab({super.key});

  @override
  State<HomeTab> createState() => _HomeTabState();
}

class _HomeTabState extends State<HomeTab> with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true; // 탭 이동 시 상태 유지

  @override
  Widget build(BuildContext context) {
    super.build(context); // 필수 호출

    // Provider의 모드 상태를 구독하여 화면 전환
    final isMainMode = context.select<BottomNavProvider, bool>((p) => p.isMainMode);

    return Container(
      color: Colors.white,
      // AnimatedSwitcher를 사용하면 화면 전환 시 부드러운 페이드 효과를 줄 수 있습니다.
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 300),
        child: isMainMode
            ? const MainHomeView()
            : const PatientHomeView(),
      ),
    );
  }
}