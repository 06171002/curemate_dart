// lib/features/main_layout/widget/cure_room_drawer.dart

import 'package:curemate/features/widgets/common/custom_profile_avatar.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:curemate/app/theme/app_colors.dart';
import 'package:curemate/routes/route_paths.dart';
import 'package:curemate/features/widgets/common/bottom_nav_provider.dart';
import 'package:curemate/features/cure_room/viewmodel/cure_room_list_viewmodel.dart';

class CureRoomDrawer extends StatefulWidget {
  const CureRoomDrawer({super.key});

  @override
  State<CureRoomDrawer> createState() => _CureRoomDrawerState();
}

class _CureRoomDrawerState extends State<CureRoomDrawer> {

  @override
  void initState() {
    super.initState();
    // 드로어가 생성될 때 목록을 갱신합니다.
    // (이미 로드된 데이터가 있다면 스킵하는 로직을 ViewModel에 추가할 수도 있습니다)
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<CureRoomListViewModel>().fetchCureRooms();
    });
  }

  @override
  Widget build(BuildContext context) {
    final navProvider = context.watch<BottomNavProvider>();
    // 큐어룸 목록 뷰모델 감지
    final listViewModel = context.watch<CureRoomListViewModel>();

    return Drawer(
      backgroundColor: Colors.white,
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ✅ Drawer Header
            Container(
              height: 120,
              decoration: const BoxDecoration(color: AppColors.mainBtn),
              padding: const EdgeInsets.fromLTRB(20, 20, 10, 20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Column(
                    mainAxisAlignment: MainAxisAlignment.end,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
                      Text(
                        '큐어룸 선택',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        '입장할 큐어룸을 선택해주세요.',
                        style: TextStyle(color: Colors.white70, fontSize: 13),
                      ),
                    ],
                  ),
                  Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () {
                        Navigator.pop(context); // 드로어 닫기
                        context.push(RoutePaths.addCureRoom).then((_) {
                          // 돌아왔을 때 목록 갱신 (큐어룸 추가 후)
                          if (mounted) {
                            context.read<CureRoomListViewModel>().fetchCureRooms();
                          }
                        });
                      },
                      borderRadius: BorderRadius.circular(30),
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        child: const Icon(
                          Icons.add_circle_outline,
                          color: Colors.white,
                          size: 32,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // ✅ 큐어룸 목록
            Expanded(
              child: listViewModel.isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : listViewModel.cureRooms.isEmpty
                  ? _buildEmptyState()
                  : ListView.builder(
                padding: EdgeInsets.zero,
                itemCount: listViewModel.cureRooms.length,
                itemBuilder: (context, index) {
                  final curer = listViewModel.cureRooms[index];
                  final isSelected = navProvider.selectedCurer?.cureSeq == curer.cureSeq;

                  return ListTile(
                    leading: CustomProfileAvatar(
                      imageUrl: curer.profileImgUrl,
                      radius: 20, // ListTile에 맞는 크기
                      fallbackIcon: Icons.healing,
                      backgroundColor: AppColors.memberBg,
                      iconColor: AppColors.mainBtn,
                    ),
                    title: Text(
                      curer.cureNm,
                      style: TextStyle(
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                        color: isSelected ? AppColors.mainBtn : Colors.black87,
                      ),
                    ),
                    subtitle: curer.cureDesc != null && curer.cureDesc!.isNotEmpty
                        ? Text(
                      curer.cureDesc!,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 12, color: Colors.grey),
                    )
                        : null,
                    selected: isSelected,
                    selectedTileColor: AppColors.mainBtn.withValues(alpha: 0.1),
                    onTap: () {
                      navProvider.selectCurer(curer);
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('${curer.cureNm}으로 전환되었습니다.')),
                      );
                    },
                  );
                },
              ),
            ),
            const Divider(height: 1),
            // 메인 모드로 돌아가기 버튼
            ListTile(
              leading: const Icon(Icons.home, color: AppColors.mainBtn),
              title: const Text(
                '메인 홈으로 돌아가기',
                style: TextStyle(color: AppColors.mainBtn, fontWeight: FontWeight.bold),
              ),
              onTap: () {
                navProvider.clearCurer();
                Navigator.pop(context);
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: const [
          Icon(Icons.meeting_room_outlined, size: 48, color: AppColors.lightGrey),
          SizedBox(height: 16),
          Text(
            "참여 중인 큐어룸이 없습니다.",
            style: TextStyle(color: Colors.grey),
          ),
        ],
      ),
    );
  }
}