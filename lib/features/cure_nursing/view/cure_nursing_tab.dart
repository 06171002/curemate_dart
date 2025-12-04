import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:curemate/app/theme/app_colors.dart';
import 'cure_nursing_write_screen.dart'; // 작성 화면 import

// 요약 아이템 모델
class SummaryItem {
  final String id;
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  SummaryItem(this.id, this.label, this.value, this.icon, this.color);
}

// 로그 아이템 모델
class LogItem {
  final String time;
  final String category;
  final String content;
  final List<String> tags;
  final String? vitalInfo;
  final bool isAlert;

  LogItem({
    required this.time,
    required this.category,
    required this.content,
    required this.tags,
    this.vitalInfo,
    this.isAlert = false,
  });
}

class CureNursingTab extends StatefulWidget {
  const CureNursingTab({super.key});

  @override
  State<CureNursingTab> createState() => _CureNursingTabState();
}

class _CureNursingTabState extends State<CureNursingTab> {
  DateTime _selectedDate = DateTime.now();

  // --- 필터 상태 변수 ---
  bool _showOnlyAlerts = false;
  bool _showEmptySlots = false;
  String _searchTagQuery = "";
  final Set<String> _selectedCategories = {};

  final List<String> _allCategories = ['활력징후', '식사', '배설', '투약', '활동'];

  // 상단 요약 데이터
  final List<SummaryItem> _allMetrics = [
    SummaryItem("temp", "체온", "36.5°C", Icons.thermostat, Colors.orange),
    SummaryItem("bp", "혈압", "120/80", Icons.favorite, Colors.redAccent),
    SummaryItem("meal", "식사", "양호", Icons.restaurant, Colors.green),
    SummaryItem("toilet", "배설", "1회", Icons.wc, Colors.blue),
    SummaryItem("sugar", "혈당", "110", Icons.bloodtype, Colors.purple),
    SummaryItem("weight", "체중", "60kg", Icons.monitor_weight, Colors.indigo),
  ];

  // 선택된 요약 항목 ID (기본 4개)
  final Set<String> _selectedMetricIds = {"temp", "bp", "meal", "toilet"};

  // 더미 로그 데이터
  final List<LogItem> _logs = [
    LogItem(time: "08:00", category: "식사", content: "아침 식사 전량 섭취.", tags: ["아침"]),
    LogItem(time: "08:30", category: "투약", content: "식후 혈압약 복용함.", tags: ["약 복용"]),
    LogItem(time: "10:30", category: "활력징후", content: "혈압이 조금 높게 측정됨.", vitalInfo: "135/90", tags: ["혈압"], isAlert: true),
    LogItem(time: "12:00", category: "식사", content: "점심 식사 반 정도 드심.", tags: ["점심"]),
    LogItem(time: "14:00", category: "활동", content: "거실 걷기 운동 20분.", tags: ["운동"]),
    LogItem(time: "15:00", category: "간식", content: "사과 1/2쪽 섭취", tags: ["간식"]),
    LogItem(time: "18:00", category: "식사", content: "저녁 식사 전량 섭취", tags: ["저녁"]),
    LogItem(time: "20:00", category: "투약", content: "저녁약 복용", tags: ["약 복용"]),
  ];

  Future<void> _pickDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppColors.mainBtn,
              onPrimary: Colors.white,
              onSurface: AppColors.textMainDark,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  // --- 통합 설정 모달 (필터 + 설정) ---
  void _showSettingsModal() {
    // 1. [초기화] 모달 열릴 때 현재 상태를 임시 변수에 복사 (적용 전 상태)
    bool tempShowOnlyAlerts = _showOnlyAlerts;
    bool tempShowEmptySlots = _showEmptySlots;
    String tempSearchTagQuery = _searchTagQuery;
    Set<String> tempSelectedCategories = Set.from(_selectedCategories);
    Set<String> tempSelectedMetricIds = Set.from(_selectedMetricIds);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        // 2. [상태 관리] 모달 내부 UI 갱신을 위한 StatefulBuilder
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setModalState) {
            return DraggableScrollableSheet(
              initialChildSize: 0.85,
              minChildSize: 0.5,
              maxChildSize: 0.95,
              builder: (_, scrollController) {
                return Container(
                  decoration: const BoxDecoration(
                    color: AppColors.white,
                    borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                  ),
                  child: DefaultTabController(
                    length: 2,
                    child: Column(
                      children: [
                        // --- 헤더 (핸들바 + 제목 + 닫기) ---
                        Center(
                          child: Container(
                            margin: const EdgeInsets.only(top: 12, bottom: 8),
                            width: 40,
                            height: 4,
                            decoration: BoxDecoration(
                              color: AppColors.grey.withValues(alpha: 0.3),
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          child: Row(
                            children: [
                              const Text(
                                "기록 설정",
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.textMainDark,
                                ),
                              ),
                              const Spacer(),
                              // 닫기 버튼 (저장 안 함)
                              IconButton(
                                icon: const Icon(Icons.close, color: AppColors.textMainDark),
                                onPressed: () => Navigator.pop(context),
                              ),
                            ],
                          ),
                        ),

                        // --- 탭 바 (디자인 수정됨) ---
                        TabBar(
                          labelColor: AppColors.mainBtn,
                          unselectedLabelColor: AppColors.textSecondaryLight,
                          labelStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),

                          // ✅ [디자인 수정] 인디케이터 색상 및 두께 조절
                          indicatorColor: AppColors.mainBtn,
                          indicatorWeight: 2.0, // 선 두께를 얇게 (기존 3 -> 2)
                          indicatorSize: TabBarIndicatorSize.tab, // 탭 전체 너비 사용

                          // ✅ [수정 1] 구분선 디자인 적용
                          dividerHeight: 1,
                          dividerColor: const Color(0xFFF5F5F5), // 또는 AppColors.lightGrey

                          // ✅ [수정 2] MaterialStateProperty -> WidgetStateProperty 로 변경
                          overlayColor: WidgetStateProperty.all(AppColors.mainBtn.withValues(alpha: 0.1)),
                          tabs: const [
                            Tab(text: "필터"),
                            Tab(text: "설정"),
                          ],
                        ),
                        // const Divider(height: 1, color: Color(0xFFF5F5F5)),

                        // --- 탭 내용 (임시 변수 사용 및 변경) ---
                        Expanded(
                          child: TabBarView(
                            children: [
                              // 탭 1: 필터
                              _buildFilterTab(
                                scrollController: scrollController,
                                tempSelectedCategories: tempSelectedCategories,
                                tempSearchTagQuery: tempSearchTagQuery,
                                onCategoryChanged: (category) {
                                  setModalState(() {
                                    if (tempSelectedCategories.contains(category)) {
                                      tempSelectedCategories.remove(category);
                                    } else {
                                      tempSelectedCategories.add(category);
                                    }
                                  });
                                },
                                onQueryChanged: (val) {
                                  setModalState(() => tempSearchTagQuery = val);
                                },
                                onReset: () {
                                  setModalState(() {
                                    tempSelectedCategories.clear();
                                    tempSearchTagQuery = "";
                                  });
                                },
                              ),

                              // 탭 2: 설정
                              _buildSettingsTab(
                                scrollController: scrollController,
                                tempShowOnlyAlerts: tempShowOnlyAlerts,
                                tempShowEmptySlots: tempShowEmptySlots,
                                tempSelectedMetricIds: tempSelectedMetricIds,
                                onAlertToggle: (val) {
                                  setModalState(() => tempShowOnlyAlerts = val);
                                },
                                onEmptySlotToggle: (val) {
                                  setModalState(() => tempShowEmptySlots = val);
                                },
                                onMetricToggle: (id) {
                                  setModalState(() {
                                    if (tempSelectedMetricIds.contains(id)) {
                                      if (tempSelectedMetricIds.length > 1) {
                                        tempSelectedMetricIds.remove(id);
                                      }
                                    } else {
                                      tempSelectedMetricIds.add(id);
                                    }
                                  });
                                },
                              ),
                            ],
                          ),
                        ),

                        // --- 하단 버튼 (적용하기) ---
                        Padding(
                          padding: EdgeInsets.fromLTRB(
                            20,
                            10,
                            20,
                            20 + MediaQuery.of(context).padding.bottom,
                          ),
                          child: SizedBox(
                            width: double.infinity,
                            height: 52,
                            child: ElevatedButton(
                              // ✅ [로직 수정] 여기서만 실제 상태(setState) 업데이트
                              onPressed: () {
                                setState(() {
                                  _showOnlyAlerts = tempShowOnlyAlerts;
                                  _showEmptySlots = tempShowEmptySlots;
                                  _searchTagQuery = tempSearchTagQuery;
                                  _selectedCategories.clear();
                                  _selectedCategories.addAll(tempSelectedCategories);
                                  _selectedMetricIds.clear();
                                  _selectedMetricIds.addAll(tempSelectedMetricIds);
                                });
                                Navigator.pop(context);
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.mainBtn,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                elevation: 0,
                              ),
                              child: const Text(
                                '적용하기',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.white,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            );
          },
        );
      },
    );
  }

  // --- 탭 1: 필터 화면 ---
  Widget _buildFilterTab({
    required ScrollController scrollController,
    required Set<String> tempSelectedCategories,
    required String tempSearchTagQuery,
    required Function(String) onCategoryChanged,
    required Function(String) onQueryChanged,
    required VoidCallback onReset,
  }) {
    // 텍스트 필드 컨트롤러 초기값 설정 (커서 튐 방지)
    final TextEditingController textController = TextEditingController(text: tempSearchTagQuery);
    textController.selection = TextSelection.fromPosition(TextPosition(offset: textController.text.length));

    return ListView(
      controller: scrollController,
      padding: const EdgeInsets.all(20),
      children: [
        _buildSectionTitle("카테고리 선택"),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _allCategories.map((category) {
            final isSelected = tempSelectedCategories.contains(category);
            return _buildSelectableButton(
              label: category,
              isSelected: isSelected,
              onTap: () => onCategoryChanged(category),
            );
          }).toList(),
        ),
        const SizedBox(height: 32),

        _buildSectionTitle("태그 검색"),
        const SizedBox(height: 12),
        TextField(
          controller: textController,
          onChanged: onQueryChanged,
          decoration: InputDecoration(
            hintText: "태그 입력 (예: 기침, 두통)",
            hintStyle: const TextStyle(color: AppColors.textSecondaryLight),
            prefixIcon: const Icon(Icons.search, color: AppColors.textSecondaryLight),
            filled: true,
            fillColor: AppColors.lightBackground,
            contentPadding: const EdgeInsets.symmetric(horizontal: 16),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
          ),
        ),

        const SizedBox(height: 32),
        Center(
          child: TextButton.icon(
            onPressed: onReset,
            icon: const Icon(Icons.refresh, size: 18, color: AppColors.textSecondaryLight),
            label: const Text("필터 초기화", style: TextStyle(color: AppColors.textSecondaryLight)),
          ),
        ),
      ],
    );
  }

  // --- 탭 2: 설정 화면 ---
  Widget _buildSettingsTab({
    required ScrollController scrollController,
    required bool tempShowOnlyAlerts,
    required bool tempShowEmptySlots,
    required Set<String> tempSelectedMetricIds,
    required Function(bool) onAlertToggle,
    required Function(bool) onEmptySlotToggle,
    required Function(String) onMetricToggle,
  }) {
    return ListView(
      controller: scrollController,
      padding: const EdgeInsets.all(20),
      children: [
        _buildSectionTitle("보기 옵션"),
        const SizedBox(height: 12),
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          title: const Text("⚠️ 특이사항(Alert)만 보기", style: TextStyle(fontWeight: FontWeight.w500)),
          value: tempShowOnlyAlerts,
          activeColor: AppColors.mainBtn,
          onChanged: onAlertToggle,
        ),
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          title: const Text("⏱️ 빈 시간대 포함하여 보기", style: TextStyle(fontWeight: FontWeight.w500)),
          subtitle: const Text("기록이 없는 시간도 30분 단위로 표시합니다.", style: TextStyle(fontSize: 12, color: AppColors.textSecondaryLight)),
          value: tempShowEmptySlots,
          activeColor: AppColors.mainBtn,
          onChanged: onEmptySlotToggle,
        ),

        const SizedBox(height: 32),

        _buildSectionTitle("상단 요약 정보 선택"),
        const Text("대시보드에 표시할 항목을 선택해주세요.", style: TextStyle(fontSize: 13, color: AppColors.textSecondaryLight)),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _allMetrics.map((item) {
            final isSelected = tempSelectedMetricIds.contains(item.id);
            return _buildSelectableButton(
              label: item.label,
              isSelected: isSelected,
              onTap: () => onMetricToggle(item.id),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(title, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.textMainDark));
  }

  Widget _buildSelectableButton({required String label, required bool isSelected, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.mainBtn : AppColors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? AppColors.mainBtn : AppColors.inputBorder,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : AppColors.textSecondaryLight,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            fontSize: 14,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final displayMetrics = _allMetrics.where((item) => _selectedMetricIds.contains(item.id)).toList();

    return Scaffold(
      primary: false,
      backgroundColor: AppColors.lightBackground,
      body: CustomScrollView(
        slivers: [
          // 1. 날짜 헤더 (스크롤 시 위로 사라짐)
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.only(top: 8.0, bottom: 4.0),
              child: _buildDateHeader(),
            ),
          ),

          // 2. 요약 대시보드 (SliverAppBar)
          SliverAppBar(
            pinned: true,
            floating: false,
            backgroundColor: AppColors.lightBackground,
            elevation: 0,
            toolbarHeight: 60.0, // 접혔을 때 최소 높이
            expandedHeight: 100.0, // 펼쳐졌을 때 최대 높이
            flexibleSpace: LayoutBuilder(
              builder: (BuildContext context, BoxConstraints constraints) {
                final top = constraints.biggest.height;
                // 비율 계산 (1.0: 펼침 ~ 0.0: 접힘)
                final expandRatio = (top - 60.0) / (100.0 - 60.0);
                final clampedRatio = expandRatio.clamp(0.0, 1.0);

                return _buildAnimatedDailySummary(context, displayMetrics, clampedRatio);
              },
            ),
          ),

          // 3. 타임라인 리스트
          _buildSliverTimelineList(),
        ],
      ),

      // ✅ 연필 아이콘 (Icons.edit)
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const CureNursingWriteScreen()),
          );
        },
        backgroundColor: AppColors.mainBtn,
        shape: const CircleBorder(),
        child: const Icon(Icons.edit, color: Colors.white, size: 28),
      ),
    );
  }

  Widget _buildDateHeader() {
    final dateStr = DateFormat('M월 d일 EEEE', 'ko_KR').format(_selectedDate);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              _buildCircleArrowButton(
                icon: Icons.chevron_left,
                onTap: () => setState(() => _selectedDate = _selectedDate.subtract(const Duration(days: 1))),
              ),
              const SizedBox(width: 12),
              GestureDetector(
                onTap: _pickDate,
                child: Row(
                  children: [
                    Text(
                      dateStr,
                      style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: AppColors.textMainDark, letterSpacing: -0.5),
                    ),
                    const SizedBox(width: 2),
                    const Icon(Icons.arrow_drop_down, color: AppColors.textMainDark, size: 24),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              _buildCircleArrowButton(
                icon: Icons.chevron_right,
                onTap: () => setState(() => _selectedDate = _selectedDate.add(const Duration(days: 1))),
              ),
            ],
          ),
          Stack(
            children: [
              _buildCircleArrowButton(
                icon: Icons.tune_rounded,
                onTap: _showSettingsModal,
              ),
              if (_showOnlyAlerts || _selectedCategories.isNotEmpty || _showEmptySlots || _searchTagQuery.isNotEmpty)
                Positioned(
                  right: 0, top: 0,
                  child: Container(width: 10, height: 10, decoration: const BoxDecoration(color: AppColors.error, shape: BoxShape.circle)),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCircleArrowButton({required IconData icon, required VoidCallback onTap}) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: AppColors.white,
            border: Border.all(color: AppColors.inputBorder),
            boxShadow: [BoxShadow(color: AppColors.shadow, blurRadius: 4, offset: const Offset(0, 2))],
          ),
          child: Icon(icon, size: 20, color: AppColors.textSecondaryLight),
        ),
      ),
    );
  }

  // ✅ [수정] 요약 대시보드 애니메이션 및 아이콘 사라짐 처리 개선
  Widget _buildAnimatedDailySummary(BuildContext context, List<SummaryItem> metrics, double expandRatio) {
    // 1. 아이콘 투명도 계산 (더 빠르게 사라지게 설정)
    // expandRatio가 0.7 이하로 내려가면 투명도가 급격히 떨어져 0이 됨
    final double iconOpacity = ((expandRatio - 0.7) / 0.3).clamp(0.0, 1.0);

    // 2. 아이콘 크기 계산 (투명도가 0이면 크기도 0으로 만듦)
    final double iconSize = iconOpacity > 0 ? 36.0 * expandRatio : 0.0;

    // 3. 아이콘 컨테이너의 패딩과 마진도 같이 줄임
    final double iconPadding = iconOpacity > 0 ? 4.0 : 0.0;
    final double iconMargin = iconOpacity > 0 ? 4.0 : 0.0;

    final double screenWidth = MediaQuery.of(context).size.width;
    final double cardWidth = screenWidth - 32;
    final double itemWidth = metrics.length > 4 ? cardWidth / 4.5 : cardWidth / 4;

    return Center(
      child: Container(
        // 상단 마진: 펼쳐졌을 때 12, 접혔을 때 8 (미세 조정)
        margin: EdgeInsets.fromLTRB(16, 8 + (4 * expandRatio), 16, 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: AppColors.shadow,
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          padding: EdgeInsets.zero,
          itemCount: metrics.length,
          separatorBuilder: (context, index) => Container(
              width: 1,
              // 구분선 높이: 접혔을 때 10, 펼쳐졌을 때 26
              margin: EdgeInsets.symmetric(vertical: 10 + (16 * expandRatio)),
              color: AppColors.lightGrey
          ),
          itemBuilder: (context, index) {
            final item = metrics[index];
            return SizedBox(
              width: itemWidth,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // 아이콘 영역 (Opacity가 0이면 아예 공간을 차지하지 않도록 처리)
                  if (iconOpacity > 0.0)
                    Opacity(
                      opacity: iconOpacity,
                      child: Container(
                        height: iconSize,
                        width: iconSize,
                        padding: EdgeInsets.all(iconPadding),
                        margin: EdgeInsets.only(bottom: iconMargin),
                        decoration: BoxDecoration(
                          color: item.color.withValues(alpha: 0.1),
                          shape: BoxShape.circle,
                        ),
                        child: FittedBox(child: Icon(item.icon, color: item.color)),
                      ),
                    ),

                  // 라벨 (접혔을 때도 보임)
                  Text(
                    item.label,
                    style: const TextStyle(fontSize: 11, color: AppColors.textSecondaryLight),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),

                  // 값 (접혔을 때도 보임)
                  Text(
                    item.value,
                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.textMainDark),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildSliverTimelineList() {
    final filteredLogs = _logs.where((item) {
      if (_showOnlyAlerts && !item.isAlert) return false;
      if (_selectedCategories.isNotEmpty && !_selectedCategories.contains(item.category)) return false;
      if (_searchTagQuery.isNotEmpty) {
        bool hasTag = item.tags.any((tag) => tag.contains(_searchTagQuery));
        if (!hasTag) return false;
      }
      return true;
    }).toList();

    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      sliver: SliverList(
        delegate: SliverChildBuilderDelegate(
              (context, index) {
            if (index == filteredLogs.length + (_showEmptySlots ? 1 : 0)) {
              return const SizedBox(height: 120);
            }

            if (_showEmptySlots && index == 0) {
              return _buildEmptySlotItem("00:00 ~ 08:00");
            }

            final realIndex = _showEmptySlots ? index - 1 : index;
            if (realIndex < 0) return const SizedBox.shrink();

            final item = filteredLogs[realIndex];
            return _buildTimelineItem(item);
          },
          childCount: filteredLogs.length + (_showEmptySlots ? 1 : 0) + 1,
        ),
      ),
    );
  }

  Widget _buildEmptySlotItem(String timeRange) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[300]!, style: BorderStyle.solid),
      ),
      child: Row(
        children: [
          const Icon(Icons.history_toggle_off, size: 20, color: Colors.grey),
          const SizedBox(width: 8),
          Text("$timeRange 기록 없음", style: const TextStyle(color: Colors.grey, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  Widget _buildTimelineItem(LogItem item) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 50,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(item.time, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.textMainDark)),
                const SizedBox(height: 8),
                Expanded(child: Container(width: 2, margin: const EdgeInsets.only(right: 6), color: AppColors.inputBorder)),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Container(
              margin: const EdgeInsets.only(bottom: 24),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.white,
                borderRadius: BorderRadius.circular(16),
                border: item.isAlert ? Border.all(color: AppColors.error.withValues(alpha: 0.5)) : null,
                boxShadow: [BoxShadow(color: AppColors.shadow, blurRadius: 8, offset: const Offset(0, 4))],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: item.isAlert ? AppColors.nonMemberBg : AppColors.memberBg,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(item.category, style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: item.isAlert ? AppColors.error : AppColors.mainBtn)),
                      ),
                      const Spacer(),
                      if (item.vitalInfo != null)
                        Text(item.vitalInfo!, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: item.isAlert ? AppColors.error : AppColors.textMainDark)),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(item.content, style: const TextStyle(fontSize: 14, color: AppColors.textMainDark, height: 1.5)),
                  if (item.tags.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 6,
                      runSpacing: 4,
                      children: item.tags.map((tag) => Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(color: AppColors.lightGrey, borderRadius: BorderRadius.circular(4)),
                        child: Text("#$tag", style: TextStyle(fontSize: 11, color: AppColors.textSecondaryLight.withValues(alpha: 0.8))),
                      )).toList(),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}