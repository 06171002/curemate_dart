import 'package:curemate/app/theme/app_colors.dart';
import 'package:curemate/features/cure_room/model/cure_room_models.dart';
import 'package:curemate/routes/route_paths.dart';
import 'package:curemate/services/cure_room_service.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class MedicationListScreen extends StatefulWidget {
  /// 🔹 어떤 환자의 약 목록인지
  final int curePatientSeq;

  /// 🔹 프로필 화면에서 미리 조회해온 약 그룹 리스트 (있으면 이걸 먼저 사용)
  final List<CureMedicineGroupModel>? initialGroups;

  const MedicationListScreen({
    super.key,
    required this.curePatientSeq,
    this.initialGroups,
  });

  @override
  State<MedicationListScreen> createState() => _MedicationListScreenState();
}

class _MedicationListScreenState extends State<MedicationListScreen> {
  final CureRoomService _service = CureRoomService();

  String _searchQuery = '';

  /// 🔹 서버에서 받아온 약 그룹 리스트
  List<CureMedicineGroupModel> _groups = [];

  /// 🔹 로딩/에러 상태
  bool _isLoading = false;
  String? _errorMessage;

  /// 🔹 그룹별 아코디언 펼침 상태 (key: curePatientMedicineSeq)
  final Map<int, bool> _expandedGroups = {};

  @override
  void initState() {
    super.initState();

    // ✅ 프로필 화면에서 이미 리스트를 받아온 경우 → 그걸 먼저 사용
    if (widget.initialGroups != null) {
      _groups = widget.initialGroups!;
      _isLoading = false;
    } else {
      // 만약 직접 들어온 경우(초기 리스트 없음)만 API 호출
      _loadMedicineGroups();
    }
  }

  Future<void> _loadMedicineGroups() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final list =
          await _service.getPatientMedicineList(widget.curePatientSeq);

      setState(() {
        _groups = list;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // 🔎 검색어 적용된 그룹/세부약 필터링
    final filteredGroups = _groups
        .map((g) {
          final filteredDetails = g.details.where((detail) {
            if (_searchQuery.isEmpty) return true;
            return detail.cureMedicineNm.contains(_searchQuery);
          }).toList();

          return CureMedicineGroupModel(
            curePatientMedicineSeq: g.curePatientMedicineSeq,
            curePatientSeq: g.curePatientSeq,
            patientMedicineNm: g.patientMedicineNm,
            details: filteredDetails,
          );
        })
        .toList();

    return SafeArea(
      child: Material(
        color: AppColors.lightBackground,
        child: Stack(
          children: [
            Column(
              children: [
                /// 🔹 상단 뒤로가기 + 가운데 제목
                _buildTopBar(),

                /// 🔹 검색바 + 안내 문구
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildSearchBar(),
                      const SizedBox(height: 17),
                      Text(
                        '세부 약 목록을 왼쪽으로 밀면 삭제할 수 있어요.',
                        style: TextStyle(
                          fontSize: 11,
                          color: AppColors.grey.withOpacity(0.9),
                        ),
                      ),
                    ],
                  ),
                ),

                /// 🔹 본문 영역
                Expanded(
                  child: _isLoading
                      ? const Center(child: CircularProgressIndicator())
                      : _errorMessage != null
                          ? _buildErrorState()
                          : (filteredGroups.isEmpty
                              ? _buildEmptyState()
                              : ListView.builder(
                                  padding: const EdgeInsets.fromLTRB(
                                      16, 0, 16, 96),
                                  itemCount: filteredGroups.length,
                                  itemBuilder: (context, index) {
                                    return _buildGroupTile(
                                        filteredGroups[index]);
                                  },
                                )),
                ),
              ],
            ),

            /// 🔹 Floating (+) 버튼 → 약 등록 페이지로 이동
            Positioned(
              bottom: 24,
              right: 24,
              child: GestureDetector(
                onTap: () async {
                  final result = await context.push(
                    RoutePaths.cureRoomMedicationDetail,
                    extra: {
                      'curePatientSeq': widget.curePatientSeq,
                      'isEdit': false, // 등록 모드
                    },
                  );

                  // 등록/수정 후 true 리턴 받으면 새로고침
                  if (result == true) {
                    _loadMedicineGroups(); // ✅ 이때만 API 다시 호출
                  }
                },
                child: Container(
                  width: 56,
                  height: 56,
                  decoration: const BoxDecoration(
                    color: Color(0xFFA0C4FF),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black26,
                        blurRadius: 8,
                        offset: Offset(0, 4),
                      ),
                    ],
                  ),
                  child: const Icon(Icons.add, color: Colors.white, size: 30),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ======================================================
  // 🔹 상단바(뒤로가기 + 가운데 제목)
  // ======================================================
  Widget _buildTopBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 12, 16, 4),
      child: SizedBox(
        height: 40,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // 🔹 왼쪽: 뒤로가기
            InkWell(
              onTap: () => context.pop(),
              borderRadius: BorderRadius.circular(20),
              child: const Padding(
                padding: EdgeInsets.symmetric(horizontal: 4, vertical: 8),
                child: Icon(
                  Icons.arrow_back_ios_new,
                  size: 20,
                  color: Colors.black, // ✅ 환자 프로필과 동일한 검정 아이콘
                ),
              ),
            ),

            // 🔹 가운데 제목
            const Expanded(
              child: Center(
                child: Text(
                  '복용 약',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.black, // ✅ 프로필 / 병력 타이틀과 동일
                  ),
                ),
              ),
            ),

            // 🔹 오른쪽 자리 맞추기용 (비어있는 영역)
            const SizedBox(width: 40),
          ],
        ),
      ),
    );
  }

  // ======================================================
  // 🔹 검색바
  // ======================================================
  Widget _buildSearchBar() {
    return Container(
      height: 44,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFF2F4F6), // 연회색 배경
        borderRadius: BorderRadius.circular(24),
      ),
      child: Row(
        children: [
          Icon(
            Icons.search,
            size: 20,
            color: AppColors.grey.withOpacity(0.7),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: TextField(
              decoration: const InputDecoration(
                hintText: "약 이름으로 검색",
                isDense: true,
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                filled: false,
                fillColor: Colors.transparent,
                contentPadding: EdgeInsets.zero,
              ),
              style: const TextStyle(
                fontSize: 14,
                color: AppColors.black,
              ),
              cursorColor: AppColors.blueTextSecondary,
              onChanged: (value) {
                setState(() {
                  _searchQuery = value.trim();
                });
              },
            ),
          ),
        ],
      ),
    );
  }

  // ======================================================
  // 🔹 에러 상태
  // ======================================================
  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline,
                size: 40, color: Colors.redAccent),
            const SizedBox(height: 8),
            Text(
              '약 정보를 불러오지 못했어요.\n$_errorMessage',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 13, color: AppColors.grey),
            ),
            const SizedBox(height: 12),
            TextButton(
              onPressed: _loadMedicineGroups,
              child: const Text('다시 시도'),
            ),
          ],
        ),
      ),
    );
  }

  // ======================================================
  // 🔹 그룹 카드 + 아코디언 + 더보기 액션
  // ======================================================
  Widget _buildGroupTile(CureMedicineGroupModel group) {
    final key = group.curePatientMedicineSeq;
    final bool isExpanded = _expandedGroups[key] ?? false;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.inputBorder),
      ),
      child: Column(
        children: [
          /// 🔸 헤더 영역 (카드 전체 탭 → 아코디언 열림/닫힘)
          InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: () {
              setState(() {
                _expandedGroups[key] = !isExpanded;
              });
            },
            child: Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              child: Row(
                children: [
                  /// 제목 / 개수
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          group.patientMedicineNm,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: AppColors.blueTextSecondary,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${group.details.length}개',
                          style: TextStyle(
                            fontSize: 12,
                            color: AppColors.grey.withOpacity(0.8),
                          ),
                        ),
                      ],
                    ),
                  ),

                  /// 🔸 더보기 팝업 메뉴 (수정 / 삭제)
                  PopupMenuButton<String>(
                    icon: Icon(
                      Icons.more_vert,
                      size: 20,
                      color: AppColors.grey.withOpacity(0.9),
                    ),
                    onSelected: (value) async {
                      if (value == 'edit') {
                        final result = await context.push(
                          RoutePaths.cureRoomMedicationDetail,
                          extra: {
                            'curePatientSeq': group.curePatientSeq,
                            'isEdit': true,
                            'group': group, // 🔹 이 그룹 전체를 넘김
                          },
                        );

                        if (result == true) {
                          _loadMedicineGroups();
                        }
                      } else if (value == 'delete') {
                        // 🔸 1) 삭제 확인 다이얼로그
                        final confirmed = await showDialog<bool>(
                          context: context,
                          builder: (context) {
                            return AlertDialog(
                              title: const Text('약 그룹 삭제'),
                              content: Text('"${group.patientMedicineNm}" 그룹을 삭제할까요?\n'
                                  '해당 그룹의 세부 약도 함께 삭제돼요.'),
                              actions: [
                                TextButton(
                                  onPressed: () =>
                                      Navigator.of(context).pop(false),
                                  child: const Text('취소'),
                                ),
                                TextButton(
                                  onPressed: () =>
                                      Navigator.of(context).pop(true),
                                  child: const Text(
                                    '삭제',
                                    style: TextStyle(color: Colors.redAccent),
                                  ),
                                ),
                              ],
                            );
                          },
                        );

                        if (confirmed != true) return;

                        try {
                          // 🔸 2) 서버에 삭제 요청
                          await _service.deletePatientMedicineGroup(
                              group.curePatientMedicineSeq);

                          // 🔸 3) 로컬 리스트에서도 제거
                          setState(() {
                            _groups.removeWhere(
                              (g) =>
                                  g.curePatientMedicineSeq ==
                                  group.curePatientMedicineSeq,
                            );
                            _expandedGroups
                                .remove(group.curePatientMedicineSeq);
                          });

                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('약 그룹이 삭제되었어요.')),
                          );
                        } catch (e) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                                content: Text('그룹 삭제 중 오류가 발생했어요.')),
                          );
                        }
                      }
                    },
                    itemBuilder: (context) => const [
                      PopupMenuItem(
                        value: 'edit',
                        child: Text('수정'),
                      ),
                      PopupMenuItem(
                        value: 'delete',
                        child: Text(
                          '삭제',
                          style: TextStyle(color: Colors.redAccent),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          /// 🔸 아코디언 내용 (약 리스트)
          if (isExpanded)
            Column(
              children: group.details
                  .map(
                    (item) => _buildMedicationRow(group, item),
                  )
                  .toList(),
            ),
        ],
      ),
    );
  }

  // ======================================================
  // 🔹 개별 약 Row
  // ======================================================
  Widget _buildMedicationRow(
    CureMedicineGroupModel group,
    CureMedicineDetailModel item,
  ) {
    return Dismissible(
      key: ValueKey(item.curePatientMedicineDetailSeq),
      direction: DismissDirection.endToStart, // 오른쪽 → 왼쪽 스와이프만
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        color: Colors.redAccent.withOpacity(0.9),
        child: const Icon(
          Icons.delete,
          color: Colors.white,
        ),
      ),

      // ✅ 스와이프 직전에 확인 (실수 방지)
      confirmDismiss: (direction) async {
        return await showDialog<bool>(
          context: context,
          builder: (context) {
            return AlertDialog(
              title: const Text('세부 약 삭제'),
              content: Text('"${item.cureMedicineNm}" 세부 약을 삭제할까요?'),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  child: const Text('취소'),
                ),
                TextButton(
                  onPressed: () => Navigator.of(context).pop(true),
                  child: const Text(
                    '삭제',
                    style: TextStyle(color: Colors.redAccent),
                  ),
                ),
              ],
            );
          },
        );
      },

      // ✅ 실제 삭제 처리
      onDismissed: (direction) async {
        try {
          await _service.deletePatientMedicineDetail(
            item.curePatientMedicineDetailSeq,
          );
        } catch (e) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('삭제 중 오류가 발생했어요.')),
          );
          return;
        }

        setState(() {
          final targetGroupIndex = _groups.indexWhere(
            (g) => g.curePatientMedicineSeq == group.curePatientMedicineSeq,
          );
          if (targetGroupIndex != -1) {
            final targetGroup = _groups[targetGroupIndex];
            targetGroup.details.removeWhere(
              (d) =>
                  d.curePatientMedicineDetailSeq ==
                  item.curePatientMedicineDetailSeq,
            );
          }
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('세부 약이 삭제되었습니다.')),
        );
      },

      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        margin: const EdgeInsets.symmetric(vertical: 2, horizontal: 8),
        decoration: BoxDecoration(
          color: AppColors.white, // ✅ 흰 배경 카드처럼 보이게
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: const Color(0xFFA0C4FF).withOpacity(0.2),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.medication_liquid,
                color: Color(0xFFA0C4FF),
                size: 22,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ✅ 1줄: 세부약명 + 용량 (예: "알약1 6mg")
                  Text(
                    _buildNameWithVolume(item),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppColors.blueTextSecondary,
                    ),
                  ),
                  const SizedBox(height: 2),

                  // ✅ 2줄: 수량만 (예: "1개")
                  Text(
                    _buildQtyText(item),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.grey,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 🔹 1줄 텍스트: "약이름 6mg" 형태로 만들어줌
  String _buildNameWithVolume(CureMedicineDetailModel item) {
    final name = item.cureMedicineNm;
    final volume = item.cureMedicineVolume;

    if (volume == null || volume.isEmpty) {
      return name;
    }
    return '$name $volume'; // 예: "알약1 6mg"
  }

  /// 🔹 2줄 텍스트: 수량만 표시 ("1개")
  String _buildQtyText(CureMedicineDetailModel item) {
    final qty = item.cureMedicineQty;

    if (qty == null) {
      return '-';
    }

    return '${qty}개'; // 여기서 "개" → 나중에 "정"으로 바꾸고 싶으면 여기만 수정하면 됨
  }

  // ======================================================
  // 🔹 리스트 비었을 때
  // ======================================================
  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 96,
              height: 96,
              decoration: BoxDecoration(
                color: const Color(0xFFA0C4FF).withOpacity(0.15),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.medication,
                size: 40,
                color: Color(0xFFA0C4FF),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              '등록된 약이 없어요',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: AppColors.blueTextSecondary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              "오른쪽 아래 '+' 버튼을 눌러\n복용 중인 약을 등록해보세요.",
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                color: AppColors.grey.withOpacity(0.9),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
