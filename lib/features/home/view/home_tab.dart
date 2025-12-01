import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:curemate/features/widgets/common/bottom_nav_provider.dart';
import 'main_home_view.dart';
import 'cure_room_home_view.dart'; // 변경된 뷰 import

class HomeTab extends StatefulWidget {
  const HomeTab({super.key});

  @override
  State<HomeTab> createState() => _HomeTabState();
}

class _HomeTabState extends State<HomeTab> with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);

    final isMainMode = context.select<BottomNavProvider, bool>((p) => p.isMainMode);

    return Container(
      color: Colors.white,
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 300),
        child: isMainMode
            ? const MainHomeView()
            : const CureRoomHomeView(), // 큐어룸 뷰로 변경
      ),
    );
  }
}