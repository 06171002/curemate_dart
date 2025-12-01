import 'package:curemate/app/theme/app_colors.dart';
import 'package:curemate/features/cure_room/model/cure_room_models.dart';
import 'package:curemate/services/cure_room_service.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:curemate/routes/route_paths.dart';

class MedicalHistoryScreen extends StatefulWidget {
  final CurePatientModel patient; // ✅ 특정 환자 정보

  const MedicalHistoryScreen({
    super.key,
    required this.patient,
  });

  @override
  State<MedicalHistoryScreen> createState() => _MedicalHistoryScreenState();
}

class _MedicalHistoryScreenState extends State<MedicalHistoryScreen> {
  final _service = CureRoomService();

  List<CureDiseaseModel> _diseases = [];
  bool _isLoading = false;
  String? _errorMessage;

  // 🔹 선택 모드 관련 상태
  bool _isSelectionMode = false;
  final Set<int> _selectedSeqs = {}; // curePatientDiseaseSeq 저장

  // 🔹 검색어 상태
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadDiseases();
  }

  Future<void> _loadDiseases() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final list = await _service.getPatientDiseaseList(
        widget.patient.curePatientSeq,
      );

      setState(() {
        _diseases = list;
      });
    } catch (e) {
      setState(() {
        _errorMessage = '병력 목록을 불러오는 중 오류가 발생했습니다.\n$e';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  /// 🔹 삭제 확인 다이얼로그
  Future<bool> _confirmDelete(BuildContext context) async {
    if (_selectedSeqs.isEmpty) return false;

    return await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('삭제하시겠어요?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('취소'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text(
                  '삭제',
                  style: TextStyle(color: Colors.redAccent),
                ),
              ),
            ],
          ),
        ) ??
        false;
  }

  /// 🔹 실제 삭제 처리 (API 호출 + 목록 갱신)
  Future<void> _deleteSelected() async {
    if (_selectedSeqs.isEmpty) return;

    try {
      // ✅ 실제 API에 맞게 수정해서 사용하면 됨
      // 예시) 하나씩 삭제하는 API가 있을 경우:
      for (final seq in _selectedSeqs) {
        await _service.deletePatientDisease(seq); // TODO: 메서드명 네 서비스에 맞게 수정
      }

      await _loadDiseases();

      if (!mounted) return;

      setState(() {
        _isSelectionMode = false;
        _selectedSeqs.clear();
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('선택한 병력이 삭제되었습니다.')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('삭제 중 오류가 발생했습니다: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // 🔹 먼저 body 위젯을 만든다
    Widget body;

    if (_isLoading) {
  body = const Center(
    child: CircularProgressIndicator(),
  );
} else if (_errorMessage != null) {
  body = Center(
    child: Column(
      mainAxisSize: MainAxisSize.min, // 👈 여기로 옮기기
      children: [
        Text(
          _errorMessage!,
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: AppColors.blueTextSecondary,
            fontSize: 13,
          ),
        ),
        const SizedBox(height: 12),
        OutlinedButton(
          onPressed: _loadDiseases,
          child: const Text('다시 시도'),
        ),
      ],
    ),
  );
} else {
  // ✅ 검색어 기준으로 필터링
  final query = _searchQuery.trim();
  final List<CureDiseaseModel> filteredDiseases = query.isEmpty
      ? _diseases
      : _diseases.where((d) {
          final name = d.curePatientDiseaseNm;
          final desc = (d.diseaseDesc ?? '');
          return name.contains(query) || desc.contains(query);
        }).toList();

  // ✅ 아무 병력도 없을 때 (등록 0개 + 검색결과 0개)
  if (filteredDiseases.isEmpty) {
    body = _buildEmptyState();
  }
  // ✅ 병력이 하나 이상 있을 때만 섹션들 보여주기
  else {
    // 코드값 기준으로 분류 (필터된 리스트 기준)
    final currentHistory = filteredDiseases
        .where((d) => d.curePatientDiseaseTypeCmcd == 'current')
        .toList();
    final pastHistory = filteredDiseases
        .where((d) => d.curePatientDiseaseTypeCmcd == 'past')
        .toList();
    final familyHistory = filteredDiseases
        .where((d) => d.curePatientDiseaseTypeCmcd == 'family')
        .toList();

    body = SingleChildScrollView(
      padding: const EdgeInsets.symmetric(
        horizontal: 16,
        vertical: 24,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (currentHistory.isNotEmpty)
            _buildHistorySection('현재 병력', currentHistory),
          if (currentHistory.isNotEmpty) const SizedBox(height: 24),

          if (pastHistory.isNotEmpty)
            _buildHistorySection('과거 병력', pastHistory),
          if (pastHistory.isNotEmpty) const SizedBox(height: 24),

          if (familyHistory.isNotEmpty)
            _buildHistorySection('가족력', familyHistory),

          const SizedBox(height: 80),
        ],
      ),
    );
  }
}

    // 🔹 여기서부터 Scaffold 로 감싸줌 (SnackBar 때문에)
    return Scaffold(
      backgroundColor: AppColors.lightBackground,
      body: SafeArea(
        child: DefaultTextStyle(
          style: const TextStyle(
            fontSize: 14,
            color: AppColors.blueTextSecondary,
          ),
          child: Stack(
            children: [
              /// 🔹 본문
              Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildTopBar(context),

              // 🔹 병력 검색바
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                  child: _buildSearchBar(),
                ),

                  Expanded(child: body),
                ],
              ),

              /// 🔹 오른쪽 아래 + 버튼 → 신규 병력 추가
              if (!_isSelectionMode) // ⭐ 선택 모드일 땐 숨기기
                Positioned(
                  bottom: 24,
                  right: 24,
                  child: GestureDetector(
                    onTap: () async {
                      final result = await context.push(
                        RoutePaths.cureRoomMedicalHistoryDetail,
                        extra: {
                          'isNew': true,
                          'curePatientSeq': widget.patient.curePatientSeq,
                          'disease': null,
                        },
                      );

                      if (!mounted) return;

                      // ✅ 상세에서 Navigator.pop(context, true); 했을 때만
                      if (result == true) {
                        await _loadDiseases(); // 1) 목록 새로고침

                        // 2) 바로 여기서 스낵바
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('병력이 저장되었습니다.')),
                        );
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
                      child: const Icon(
                        Icons.add,
                        color: Colors.white,
                        size: 30,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  /// 🔹 상단 바 (뒤로가기 / 취소 + 타이틀 + 선택/삭제)
  Widget _buildTopBar(BuildContext context) {
  return Padding(
    padding: const EdgeInsets.fromLTRB(8, 12, 16, 0),
    child: SizedBox(
      height: 40,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // 🔹 왼쪽: 뒤로가기 / 취소
          InkWell(
            onTap: () {
              if (_isSelectionMode) {
                setState(() {
                  _isSelectionMode = false;
                  _selectedSeqs.clear();
                });
              } else {
                if (Navigator.canPop(context)) {
                  Navigator.pop(context);
                }
              }
            },
            borderRadius: BorderRadius.circular(20),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
              child: _isSelectionMode
                  ? const Text(
                      '취소',
                      style: TextStyle(
                        color: Colors.black, // ✅ 프로필 타이틀처럼 검정
                        fontSize: 14,
                      ),
                    )
                  : const Icon(
                      Icons.arrow_back_ios_new,
                      size: 20,
                      color: Colors.black, // ✅ 프로필 상단 아이콘과 동일
                    ),
            ),
          ),

          // 🔹 가운데 타이틀
          Expanded(
            child: Center(
              child: Text(
                _isSelectionMode
                    ? (_selectedSeqs.isEmpty
                        ? '병력 선택'
                        : '병력 선택 (${_selectedSeqs.length}개)')
                    : '병력',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.black, // ✅ 환자 프로필 타이틀과 동일
                ),
              ),
            ),
          ),

          // 🔹 오른쪽: 선택 / 삭제
          InkWell(
            onTap: () async {
              if (_isSelectionMode) {
                if (_selectedSeqs.isEmpty) return;

                final ok = await _confirmDelete(context);
                if (!ok) return;
                await _deleteSelected();
              } else {
                if (_diseases.isEmpty) return;
                setState(() {
                  _isSelectionMode = true;
                  _selectedSeqs.clear();
                });
              }
            },
            borderRadius: BorderRadius.circular(20),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
              child: Text(
                _isSelectionMode ? '삭제' : '선택',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: _isSelectionMode
                      ? (_selectedSeqs.isEmpty
                          ? AppColors.grey
                          : Colors.redAccent)
                      : (_diseases.isEmpty
                          ? AppColors.grey
                          : AppColors.skyBlue), // ✅ 관리 >랑 비슷한 포인트 색
                ),
              ),
            ),
          ),
        ],
      ),
    ),
  );
}

// 🔹 병력 검색바 (복용 약 검색바와 동일 스타일)
Widget _buildSearchBar() {
  return Container(
    height: 44,
    padding: const EdgeInsets.symmetric(horizontal: 12),
    decoration: BoxDecoration(
      color: const Color(0xFFF2F4F6), // 연회색 배경 (약 화면과 동일)
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
              hintText: "병명 또는 메모로 검색",
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
                _searchQuery = value;
              });
            },
          ),
        ),
      ],
    ),
  );
}

  /// 🔹 섹션별 제목 + 리스트 (CureDiseaseModel 기반)
  Widget _buildHistorySection(
    String title,
    List<CureDiseaseModel> items,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: AppColors.blueTextSecondary,
          ),
        ),
        const SizedBox(height: 12),
        Column(
          children: items
              .map(
                (disease) => _buildHistoryListItem(disease),
              )
              .toList(),
        ),
      ],
    );
  }

  /// 🔹 한 줄짜리 아이템 (CureDiseaseModel → UI)
  Widget _buildHistoryListItem(CureDiseaseModel disease) {
    final isFamily = disease.curePatientDiseaseTypeCmcd == 'family';
    final isCured = disease.curedYn == 'Y';
    final bool isSelected =
        _selectedSeqs.contains(disease.curePatientDiseaseSeq);

    Color statusColor = AppColors.statusOngoing;
    String statusText = isCured ? '완치' : '진행중';

    if (isCured) statusColor = AppColors.statusDone;

    // 날짜 포맷
    final start = _formatDate(disease.diseaseStartDt);
    final end = _formatDate(disease.diseaseEndDt);

    String subtitleLine;
    if (start == null && end == null) {
      subtitleLine = isFamily ? '가족력' : '발병일 정보 없음';
    } else if (start != null && end != null) {
      subtitleLine = '$start ~ $end';
    } else if (start != null) {
      subtitleLine = '$start 시작';
    } else {
      subtitleLine = '완치일: $end';
    }

    final String descLine = (disease.diseaseDesc ?? '').trim();

    void toggleSelect() {
      setState(() {
        if (isSelected) {
          _selectedSeqs.remove(disease.curePatientDiseaseSeq);
        } else {
          _selectedSeqs.add(disease.curePatientDiseaseSeq);
        }
      });
    }

    return GestureDetector(
      onTap: () async {
        if (_isSelectionMode) {
          // 🔹 선택 모드에서는 선택/해제만
          toggleSelect();
          return;
        }

        // 🔹 일반 모드에서는 상세/수정 화면으로 이동
        try {
          final detail = await _service.getPatientDisease(
            disease.curePatientDiseaseSeq,
          );

          final result = await context.push(
            RoutePaths.cureRoomMedicalHistoryDetail,
            extra: {
              'isNew': false,
              'curePatientSeq': widget.patient.curePatientSeq,
              'disease': detail,
            },
          );

          if (!mounted) return;

          if (result == true) {
            await _loadDiseases();

            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('병력이 수정되었습니다.')),
            );
          }
        } catch (e) {
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('병력 정보를 불러오는 중 오류가 발생했습니다: $e'),
            ),
          );
        }
      },
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 6),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: AppColors.grey.withOpacity(0.06),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
          border: Border.all(
            color: isSelected
                ? AppColors.skyBlue
                : AppColors.lightGrey.withOpacity(0.7),
            width: isSelected ? 1.4 : 0.7,
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            /// 🔹 선택 모드일 때 왼쪽 체크 동그라미
            if (_isSelectionMode) ...[
              GestureDetector(
                onTap: toggleSelect,
                child: Container(
                  margin: const EdgeInsets.only(right: 8, top: 6),
                  width: 20,
                  height: 20,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: isSelected
                          ? AppColors.skyBlue
                          : AppColors.lightGrey,
                      width: 2,
                    ),
                    color:
                        isSelected ? AppColors.skyBlue : Colors.transparent,
                  ),
                  child: isSelected
                      ? const Icon(Icons.check, size: 14, color: Colors.white)
                      : null,
                ),
              ),
            ],

            /// 왼쪽 아이콘
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: AppColors.medicineBtn,
                borderRadius: BorderRadius.circular(999),
              ),
              child: Icon(
                isFamily ? Icons.family_restroom : Icons.healing,
                size: 20,
                color: AppColors.blueTextSecondary,
              ),
            ),
            const SizedBox(width: 12),

            /// 가운데 텍스트들
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 병명
                  Text(
                    disease.curePatientDiseaseNm,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: AppColors.blueTextSecondary,
                    ),
                  ),
                  const SizedBox(height: 4),

                  // 날짜 요약
                  Text(
                    subtitleLine,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 11,
                      color: AppColors.blueTextSecondary,
                    ),
                  ),

                  // 메모 요약
                  if (descLine.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(
                      descLine,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 11,
                        color: AppColors.grey,
                      ),
                    ),
                  ],
                ],
              ),
            ),

            const SizedBox(width: 8),

            /// 오른쪽 상태 뱃지
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 8,
                vertical: 3,
              ),
              decoration: BoxDecoration(
                color: statusColor.withOpacity(0.12),
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text(
                statusText,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: statusColor,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// yyyyMMdd → yyyy-MM-dd
  String? _formatDate(String? raw) {
    if (raw == null || raw.isEmpty) return null;
    try {
      // 서버에서 2025-11-24 13:48:40 이런 형식도 올 수 있으면 여기서 한 번 방어
      if (raw.length == 8 && RegExp(r'^\d{8}$').hasMatch(raw)) {
        final year = int.parse(raw.substring(0, 4));
        final month = int.parse(raw.substring(4, 6));
        final day = int.parse(raw.substring(6, 8));
        final dt = DateTime(year, month, day);
        return '${dt.year.toString().padLeft(4, '0')}-'
            '${dt.month.toString().padLeft(2, '0')}-'
            '${dt.day.toString().padLeft(2, '0')}';
      }

      final dt = DateTime.parse(raw);
      return '${dt.year.toString().padLeft(4, '0')}-'
          '${dt.month.toString().padLeft(2, '0')}-'
          '${dt.day.toString().padLeft(2, '0')}';
    } catch (_) {
      return raw; // 파싱 실패하면 그냥 원본 표시
    }
  }

  // 🔹 병력 비어 있을 때 화면 (약 리스트 empty와 비슷한 스타일)
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
              color: const Color(0xFFA0C4FF).withOpacity(0.15), // 복용 약과 동일
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.healing, // 👈 여기만 아이콘 변경 (약은 Icons.medication)
              size: 40,
              color: Color(0xFFA0C4FF), // 복용 약과 동일
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            '등록된 병력이 없어요',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppColors.blueTextSecondary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            "오른쪽 아래 '+' 버튼을 눌러\n병력을 등록해보세요.",
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
