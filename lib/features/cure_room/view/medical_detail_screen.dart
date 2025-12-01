import 'package:curemate/app/theme/app_colors.dart';
import 'package:curemate/features/cure_room/model/cure_room_models.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:curemate/services/cure_room_service.dart';

class MedicalHistoryDetailPage extends StatefulWidget {
  final bool isNew;
  final int curePatientSeq;          // 어떤 환자의 병력인지
  final CureDiseaseModel? disease;   // 수정 모드일 때 넘겨받는 병력

  const MedicalHistoryDetailPage({
    super.key,
    required this.curePatientSeq,
    this.disease,
    this.isNew = false,
  });

  @override
  State<MedicalHistoryDetailPage> createState() =>
      _MedicalHistoryDetailPageState();
}

class _MedicalHistoryDetailPageState extends State<MedicalHistoryDetailPage> {
  final _service = CureRoomService(); 

  late bool _isEditing;
  bool _isSaving = false;

  final TextEditingController _diseaseNameController =
      TextEditingController();

  String _type = '현재병력'; // 병력 유형 (과거병력 / 현재병력 / 가족력)

  final TextEditingController _memoController = TextEditingController();

  DateTime? _startDate;
  DateTime? _recoveryDate;

  late TextEditingController _startDateController;
  late TextEditingController _recoveryDateController;

  // 🔹 날짜 필드용 포커스 노드
  final FocusNode _startDateFocusNode = FocusNode();
  final FocusNode _recoveryDateFocusNode = FocusNode();

  // 🔹 여기서는 더 이상 서비스 직접 호출 안 함 (바깥에서 API 끝내고 들어옴)

  @override
  void initState() {
    super.initState();

    _isEditing = true;

    // 🔹 컨트롤러 먼저 생성
    _startDateController = TextEditingController();
    _recoveryDateController = TextEditingController();

    if (widget.isNew || widget.disease == null) {
      // ✅ 신규 모드: 기본값만 세팅
      _diseaseNameController.text = '';
      _memoController.text = '';
      _type = '현재병력';
      _startDate = null;
      _recoveryDate = null;
    } else {
      // ✅ 수정 모드: 이미 extra로 넘겨받은 disease를 바로 세팅
      final d = widget.disease!;
      _diseaseNameController.text = d.curePatientDiseaseNm;
      _type = _mapCodeToType(d.curePatientDiseaseTypeCmcd);
      _memoController.text = d.diseaseDesc ?? '';

      _startDate = _parseApiDate(d.diseaseStartDt);
      _recoveryDate = _parseApiDate(d.diseaseEndDt);
    }

    _syncDateControllers();
  }

  /// 컨트롤러 텍스트를 DateTime 값과 동기화
  void _syncDateControllers() {
    _startDateController.text = _startDate != null
        ? DateFormat('yyyy-MM-dd').format(_startDate!)
        : '';
    _recoveryDateController.text = _recoveryDate != null
        ? DateFormat('yyyy-MM-dd').format(_recoveryDate!)
        : '';
  }

  @override
  void dispose() {
    _startDateController.dispose();
    _recoveryDateController.dispose();
    _diseaseNameController.dispose();
    _memoController.dispose();
    _startDateFocusNode.dispose();
    _recoveryDateFocusNode.dispose();
    super.dispose();
  }

  // yyyyMMdd 또는 DateTime.parse 가능한 문자열 → DateTime?
DateTime? _parseApiDate(String? date) {
  if (date == null) return null;

  final s = date.toString().trim();  // 🔹 공백 제거
  if (s.isEmpty) return null;

  try {
    // 1) yyyymmdd (20251105) 형식
    if (RegExp(r'^\d{8}$').hasMatch(s)) {
      final year = int.parse(s.substring(0, 4));
      final month = int.parse(s.substring(4, 6));
      final day = int.parse(s.substring(6, 8));
      return DateTime(year, month, day);
    }

    // 2) 그 외는 DateTime.parse 에 맡김
    //    2025-11-05, 2025-11-05 13:48:40 등
    return DateTime.parse(s);
  } catch (e) {
    debugPrint('⚠️ date parse 실패: "$s"  $e');
    return null;
  }
}

  // DateTime? → yyyyMMdd or null (API용)
  String? _formatApiDate(DateTime? date) {
    if (date == null) return null;
    return DateFormat('yyyyMMdd').format(date);
  }

  // 화면에서 선택한 한글 타입 → API 코드
  String _mapTypeToCode(String type) {
    switch (type) {
      case '현재병력':
        return 'current';
      case '과거병력':
        return 'past';
      case '가족력':
        return 'family'; // 👉 백엔드 코드값이 다르면 여기만 수정
      default:
        return 'current';
    }
  }

  // API 코드 → 화면 표시용 한글
  String _mapCodeToType(String code) {
    switch (code) {
      case 'current':
        return '현재병력';
      case 'past':
        return '과거병력';
      case 'family':
        return '가족력';
      default:
        return '현재병력';
    }
  }

  Future<void> _pickDate(BuildContext context, bool isStart) async {
    if (!_isEditing) return;

    DateTime initialDate =
        isStart ? (_startDate ?? DateTime.now()) : (_recoveryDate ?? DateTime.now());

    final picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime(1900),
      lastDate: DateTime(2100),
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: const ColorScheme.light(primary: AppColors.activeColor),
          textButtonTheme: TextButtonThemeData(
            style: TextButton.styleFrom(foregroundColor: AppColors.activeColor),
          ),
        ),
        child: child!,
      ),
    );

    if (picked != null) {
      setState(() {
        if (isStart) {
          _startDate = picked;
        } else {
          _recoveryDate = picked;
        }
        _syncDateControllers();
      });

      // 🔹 두 날짜가 다 있으면 바로 관계 검사
      _validateDateRangeOnChange();
    }
  }

  void _validateDateRangeOnChange() {
    if (_startDate == null || _recoveryDate == null) return;

    final start = DateTime(_startDate!.year, _startDate!.month, _startDate!.day);
    final end = DateTime(_recoveryDate!.year, _recoveryDate!.month, _recoveryDate!.day);

    if (end.isBefore(start)) {
      // 잘못된 조합 → 완치일 리셋 + 안내 + 포커스
      setState(() {
        _recoveryDate = null;
        _recoveryDateController.text = '';
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('완치일은 발병일 이후 날짜여야 합니다.'),
          duration: Duration(seconds: 2),
        ),
      );

      // 완치일 필드에 포커스 주기
      FocusScope.of(context).requestFocus(_recoveryDateFocusNode);
    }
  }

  InputDecoration _inputDecoration({String? hint, Widget? suffixIcon}) {
    return InputDecoration(
      filled: true,
      fillColor: AppColors.white,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.inputBorder, width: 1.0),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.inputBorder, width: 1.0),
      ),
      disabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.inputBorder, width: 1.0),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.activeColor, width: 2.0),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      hintText: hint,
      hintStyle: const TextStyle(color: AppColors.activeBtn, fontSize: 14),
      suffixIcon: suffixIcon,
    );
  }

  TextStyle _labelStyle() => const TextStyle(
        fontWeight: FontWeight.w600,
        color: AppColors.skyBlue,
        fontSize: 14,
      );

  Widget _buildTextField(
    TextEditingController controller, {
    String? hint,
    int maxLines = 1,
  }) {
    return TextField(
      controller: controller,
      enabled: _isEditing && !_isSaving,
      maxLines: maxLines,
      decoration: _inputDecoration(hint: hint),
      style: const TextStyle(
        color: AppColors.black,
        fontSize: 14,
      ),
      textAlignVertical:
          maxLines > 1 ? TextAlignVertical.top : TextAlignVertical.center,
    );
  }

  Widget _buildDropdown<T>(
    T value,
    List<DropdownMenuItem<T>> items,
    ValueChanged<T?>? onChanged,
  ) {
    return DropdownButtonFormField<T>(
      value: value,
      decoration: _inputDecoration(),
      onChanged: (_isEditing && !_isSaving) ? onChanged : null,
      items: items,
      style: const TextStyle(
        color: AppColors.black,
        fontSize: 14,
      ),
      dropdownColor: AppColors.white,
      icon: (_isEditing && !_isSaving)
          ? const Icon(Icons.arrow_drop_down, color: Colors.black54)
          : const SizedBox.shrink(),
      isExpanded: true,
      selectedItemBuilder: (BuildContext context) {
        return items.map((item) {
          return Align(
            alignment: Alignment.centerLeft,
            child: Text(
              item.value.toString(),
              style: const TextStyle(
                color: AppColors.black,
                fontSize: 14,
              ),
            ),
          );
        }).toList();
      },
    );
  }

  Widget _buildDatePickerField(String label, bool isStart) {
    final controller =
        isStart ? _startDateController : _recoveryDateController;

    final bool isCurrentType = _mapTypeToCode(_type) == 'current';
    final bool disabledByType = !isStart && isCurrentType;
    final bool enabled = _isEditing && !_isSaving && !disabledByType;

    final focusNode =
        isStart ? _startDateFocusNode : _recoveryDateFocusNode;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: _labelStyle()),
        const SizedBox(height: 8),
        GestureDetector(
          onTap: () {
            if (!enabled && disabledByType) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('현재 병력은 완치일을 입력하지 않습니다.'),
                  duration: Duration(seconds: 2),
                ),
              );
              return;
            }
            if (enabled) {
              _pickDate(context, isStart);
            }
          },
          child: AbsorbPointer(
            child: TextField(
              controller: controller,
              focusNode: focusNode,
              readOnly: true,
              enabled: enabled,
              decoration: _inputDecoration(
                hint: '날짜 선택',
                suffixIcon: enabled
                    ? const Icon(
                        Icons.calendar_today,
                        color: AppColors.activeColor,
                      )
                    : null,
              ),
              style: TextStyle(
                color: enabled ? AppColors.black : AppColors.grey,
                fontSize: 14,
              ),
            ),
          ),
        ),
      ],
    );
  }

  /// 상단 완료 버튼 → API 호출 + pop
  Future<void> _handleComplete() async {
    if (_isSaving) return;

    FocusScope.of(context).unfocus();

    final diseaseName = _diseaseNameController.text.trim();
    if (diseaseName.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('질병명을 입력해주세요.')),
      );
      return;
    }

    // 👉 타입 코드 미리 구해두기
    final typeCode = _mapTypeToCode(_type);

    // 👉 날짜들 "날짜만" 비교하도록 정규화
    DateTime? start = _startDate != null
        ? DateTime(_startDate!.year, _startDate!.month, _startDate!.day)
        : null;
    DateTime? end = _recoveryDate != null
        ? DateTime(_recoveryDate!.year, _recoveryDate!.month, _recoveryDate!.day)
        : null;

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    // 1) 미래 날짜 방지
    if (start != null && start.isAfter(today)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('발병일은 오늘 이후로 선택할 수 없습니다.')),
      );
      return;
    }

    if (end != null && end.isAfter(today)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('완치일은 오늘 이후로 선택할 수 없습니다.')),
      );
      return;
    }

    // 3) 타입별 규칙
    if (typeCode == 'current') {
      // 현재병력인데 완치일이 들어간 경우
      if (end != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('현재 병력에는 완치일을 입력하지 않습니다.')),
        );
        return;
      }
    }

    if (typeCode == 'past') {
      // 과거병력인데 완치일이 없는 경우
      if (end == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('과거 병력은 완치일을 입력해야 합니다.')),
        );
        return;
      }
    }

    if (typeCode == 'family') {
      // 선택 규칙: 가족력에 완치일만 있는 상태 막기
      if (end != null && start == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('가족력에 완치일을 입력하려면 발병일도 함께 입력해주세요.')),
        );
        return;
      }
    }

    // 👉 여기까지 통과하면 실제 저장 시작
    setState(() => _isSaving = true);

     try {
  final payload = <String, dynamic>{
    'curePatientSeq': widget.curePatientSeq,
    'curePatientDiseaseNm': diseaseName,
    'curePatientDiseaseTypeCmcd': typeCode,
    'curedYn': end != null ? 'Y' : 'N',
    'diseaseStartDt': _formatApiDate(start),
    'diseaseEndDt': _formatApiDate(end),
    'diseaseDesc': _memoController.text.trim().isEmpty
        ? null
        : _memoController.text.trim(),
  };

  // ✅ 수정일 때는 seq 포함해서 보내기
  if (!widget.isNew && widget.disease != null) {
    payload['curePatientDiseaseSeq'] =
        widget.disease!.curePatientDiseaseSeq;
  }

  // ✅ 실제 저장 호출
  await _service.savePatientDisease(payload);

  // ✅ 여기서 true를 넘겨주고 목록으로 돌아감
  if (Navigator.canPop(context)) {
    Navigator.pop(context, true);
  }
} catch (e) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text('저장 중 오류가 발생했습니다: $e')),
  );
} finally {
  if (mounted) {
    setState(() => _isSaving = false);
  }
}
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.lightBackground,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
        
              /// 상단 바 (뒤로가기 + 완료)
            _buildTopBar(context),

            /// 본문
            Expanded(
              child: GestureDetector(
                behavior: HitTestBehavior.translucent,
                onTap: () {
                  FocusScope.of(context).unfocus();
                },
                child: SingleChildScrollView(
                  keyboardDismissBehavior:
                      ScrollViewKeyboardDismissBehavior.onDrag,
                  padding: const EdgeInsets.all(20),
                  child: Card(
                    color: AppColors.white,
                    elevation: 4,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // 질병명
                          Text('질병명', style: _labelStyle()),
                          const SizedBox(height: 8),
                          _buildTextField(_diseaseNameController),
                          const SizedBox(height: 20),

                          // 병력 유형
                          Text('병력 유형', style: _labelStyle()),
                          const SizedBox(height: 8),
                          _buildDropdown<String>(
                            _type,
                            const [
                              DropdownMenuItem(
                                value: '과거병력',
                                child: Text('과거병력'),
                              ),
                              DropdownMenuItem(
                                value: '현재병력',
                                child: Text('현재병력'),
                              ),
                              DropdownMenuItem(
                                value: '가족력',
                                child: Text('가족력'),
                              ),
                            ],
                            (val) {
                              if (val != null) {
                                setState(() {
                                  _type = val;

                                  // 🔹 현재병력 선택 시 완치일 비우기
                                  if (_mapTypeToCode(_type) == 'current') {
                                    _recoveryDate = null;
                                    _recoveryDateController.text = '';
                                  }
                                });
                              }
                            },
                          ),

                          const SizedBox(height: 20),

                          // 날짜 (발병일 / 완치일)
                          Row(
                            children: [
                              Expanded(
                                child: _buildDatePickerField('발병일', true),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: _buildDatePickerField('완치일', false),
                              ),
                            ],
                          ),
                          const SizedBox(height: 20),

                          // 메모
                          Text('메모', style: _labelStyle()),
                          const SizedBox(height: 8),
                          _buildTextField(_memoController, maxLines: 4),
                          const SizedBox(height: 10),
                          const Text(
                            '치료 과정에서 기억해두고 싶은 내용이나, 추가로 전달하고 싶은 정보를 자유롭게 적어주세요.',
                            style: TextStyle(
                              fontSize: 12,
                              color: AppColors.skyBlue,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

   /// 🔹 상단 바 (뒤로가기 + 완료) — 병력 목록 화면과 동일한 라인 정렬
  Widget _buildTopBar(BuildContext context) {
  final String title = widget.isNew ? '병력 등록' : '병력 수정';

  return Padding(
    padding: const EdgeInsets.fromLTRB(8, 12, 16, 0),
    child: SizedBox(
      height: 40,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // 🔹 왼쪽: 뒤로가기
          InkWell(
            onTap: _isSaving
                ? null
                : () {
                    if (Navigator.canPop(context)) {
                      Navigator.pop(context);
                    }
                  },
            borderRadius: BorderRadius.circular(20),
            child: const Padding(
              padding: EdgeInsets.symmetric(horizontal: 4, vertical: 8),
              child: Icon(
                Icons.arrow_back_ios_new,
                size: 20,
                color: Colors.black, // ✅ 환자 프로필 / 복용 약과 같은 검정
              ),
            ),
          ),

          // 🔹 가운데: 타이틀
          Expanded(
            child: Center(
              child: Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.black, // ✅ 동일한 타이틀 컬러
                ),
              ),
            ),
          ),

          // 🔹 오른쪽: 완료 버튼 (텍스트)
          InkWell(
            onTap: _isSaving ? null : _handleComplete,
            borderRadius: BorderRadius.circular(20),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
              child: Text(
                _isSaving ? '저장중...' : '완료',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: _isSaving
                      ? AppColors.grey
                      : AppColors.skyBlue, // ✅ 액션 컬러만 포인트 컬러
                ),
              ),
            ),
          ),
        ],
      ),
    ),
  );
}

}
