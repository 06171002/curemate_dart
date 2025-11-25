import 'package:curemate/app/theme/app_colors.dart';
import 'package:curemate/features/widgets/common/header_provider.dart';
import 'package:curemate/features/widgets/common/widgets.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';



// Medication 클래스 정의
class Medication {
  final String name;
  final String dosage;
  final String purpose;
  final String duration;
  final String memo;
  final String status;
  final String disease; // 병명 필드 추가

  Medication({
    required this.name,
    required this.dosage,
    required this.purpose,
    required this.duration,
    required this.memo,
    required this.status,
    required this.disease,
  });
}

// 더미 약물 리스트
final List<Medication> _currentMedications = [
  Medication(
    name: '아스피린',
    dosage: '100mg, 1일 1회',
    purpose: '혈액 희석제',
    duration: '2023-10-26 - 진행중',
    memo: '식사와 함께 복용하세요.',
    status: '복용중',
    disease: '고혈압',
  ),
  Medication(
    name: '메트포르민',
    dosage: '500mg, 1일 2회',
    purpose: '당뇨병 관리',
    duration: '2023-01-15 - 진행중',
    memo: '복용 전 혈당 수치를 확인하세요.',
    status: '복용중',
    disease: '당뇨병',
  ),
  Medication(
    name: '리피토',
    dosage: '20mg, 1일 1회',
    purpose: '고지혈증 치료제',
    duration: '2024-03-01 - 진행중',
    memo: '취침 전 복용하세요.',
    status: '복용중',
    disease: '고지혈증',
  ),
  Medication(
    name: '타이레놀',
    dosage: '500mg, 필요시',
    purpose: '해열진통제',
    duration: '단기 복용',
    memo: '두통 발생 시 복용.',
    status: '복용완료',
    disease: '두통',
  ),
];



class MedicalHistoryDetailPage extends StatefulWidget {
  final bool isEditing;
  final bool isNew;

  const MedicalHistoryDetailPage({
    super.key,
    this.isEditing = false,
    this.isNew = false,
  });

  @override
  State<MedicalHistoryDetailPage> createState() =>
      _MedicalHistoryDetailPageState();
}

class _MedicalHistoryDetailPageState extends State<MedicalHistoryDetailPage> {
  late bool _isEditing; // 이 변수가 편집 모드 여부를 결정합니다.

  // 모든 TextEditingController 초기화 시 기본 더미 데이터 설정
  final TextEditingController _diseaseNameController = TextEditingController(
    text: '고혈압',
  );
  String _type = '현재병력';
  final TextEditingController _relationshipController = TextEditingController(
    text: '부',
  ); // 가족력 예시
  final TextEditingController _symptomsController = TextEditingController(
    text: '특별한 증상 없음. 정기적인 혈압 측정 시 높게 나옴.',
  );
  final TextEditingController _progressionStageController =
      TextEditingController(text: '1기');
  final TextEditingController _hospitalController = TextEditingController(
    text: '미래병원',
  );
  final TextEditingController _treatmentController = TextEditingController(
    text: '혈압약 복용 (아침 식후 1정)',
  );
  final TextEditingController _memoController = TextEditingController(
    text: '매일 아침 혈압 측정 및 기록 필요. 짠 음식 피하기.',
  );

  String _status = '진행중';
  DateTime? _startDate = DateTime.parse('2020-05-10');
  DateTime? _recoveryDate; // 완치일은 초기 데이터 없음

  late TextEditingController _startDateController;
  late TextEditingController _recoveryDateController;

  // 이 병력과 관련된 약물 리스트
  late List<Medication> _medicationsForThisHistory;

  @override
  void initState() {
    super.initState();
    _isEditing = widget.isNew ? true : widget.isEditing;

    if (widget.isNew) {
      // 새 기록일 때는 모든 필드를 비우고, 약물 리스트도 비어있습니다.
      _diseaseNameController.text = '';
      _relationshipController.text = '';
      _symptomsController.text = '';
      _progressionStageController.text = '';
      _hospitalController.text = '';
      _treatmentController.text = '';
      _memoController.text = '';
      _startDate = null;
      _recoveryDate = null;
      _type = '현재병력';
      _status = '진행중';
      _medicationsForThisHistory = []; // 새 기록일 때는 약물 리스트가 비어있음
    } else {
      // 기존 기록을 조회/수정하는 경우
      // 여기에 실제 데이터를 불러오는 로직이 필요하며, 현재는 더미 데이터를 사용합니다.
      _medicationsForThisHistory =
          _currentMedications; // 기존 기록에는 더미 약물 데이터가 있다고 가정

      if (_type != '가족력') {
        _relationshipController.text = '';
      }
    }

    _startDateController = TextEditingController(
      text: _startDate != null
          ? DateFormat('yyyy-MM-dd').format(_startDate!)
          : '',
    );
    _recoveryDateController = TextEditingController(
      text: _recoveryDate != null
          ? DateFormat('yyyy-MM-dd').format(_recoveryDate!)
          : '',
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final header = Provider.of<HeaderProvider>(context, listen: false);
    header.setTitle('병력 상세');
    header.setShowBackButton(true);
  }

  @override
  void dispose() {
    _startDateController.dispose();
    _recoveryDateController.dispose();
    _diseaseNameController.dispose();
    _relationshipController.dispose();
    _symptomsController.dispose();
    _progressionStageController.dispose();
    _hospitalController.dispose();
    _treatmentController.dispose();
    _memoController.dispose();
    super.dispose();
  }

  Future<void> _pickDate(BuildContext context, bool isStart) async {
    if (!_isEditing) return; // 편집 모드일 때만 날짜 선택기 활성화

    DateTime initialDate = isStart
        ? (_startDate ?? DateTime.now())
        : (_recoveryDate ?? DateTime.now());
    final picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime(1900),
      lastDate: DateTime(2100),
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: ColorScheme.light(primary: AppColors.activeColor),
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
          _startDateController.text = DateFormat('yyyy-MM-dd').format(picked);
        } else {
          _recoveryDate = picked;
          _recoveryDateController.text = DateFormat(
            'yyyy-MM-dd',
          ).format(picked);
        }
      });
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

  // 일반 텍스트 필드 빌더 (enabled 속성을 _isEditing에 따라 제어)
  Widget _buildTextField(
    TextEditingController controller, {
    String? hint,
    int maxLines = 1,
  }) {
    return TextField(
      controller: controller,
      enabled: _isEditing,
      maxLines: maxLines,
      decoration: _inputDecoration(hint: hint),
      style: TextStyle(
        color: _isEditing ? AppColors.black : AppColors.black,
        fontSize: 14,
      ),
      textAlignVertical: maxLines > 1
          ? TextAlignVertical.top
          : TextAlignVertical.center,
    );
  }

  // 드롭다운 필드 빌더 (onChanged를 _isEditing에 따라 제어하여 수정 불가하게 함)
  Widget _buildDropdown<T>(
    T value,
    List<DropdownMenuItem<T>> items,
    ValueChanged<T?>? onChanged,
  ) {
    return DropdownButtonFormField<T>(
      value: value,
      decoration: _inputDecoration(),
      onChanged: _isEditing ? onChanged : null,
      items: items,
      style: TextStyle(
        color: _isEditing ? AppColors.black : AppColors.black,
        fontSize: 14,
      ),
      dropdownColor: AppColors.white,
      icon: _isEditing
          ? const Icon(Icons.arrow_drop_down, color: Colors.black54)
          : const SizedBox.shrink(),
      isExpanded: true,
      selectedItemBuilder: (BuildContext context) {
        return items.map((item) {
          return Align(
            alignment: Alignment.centerLeft,
            child: Text(
              item.value.toString(),
              style: TextStyle(
                color: _isEditing ? AppColors.black : AppColors.black,
                fontSize: 14,
              ),
            ),
          );
        }).toList();
      },
    );
  }

  // 날짜 선택 필드 빌더 (onTap을 _isEditing에 따라 제어하여 수정 불가하게 함)
  Widget _buildDatePickerField(String label, bool isStart) {
    final controller = isStart ? _startDateController : _recoveryDateController;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: _labelStyle()),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          readOnly: true, // 항상 읽기 전용
          enabled: _isEditing, // _isEditing 값에 따라 활성화/비활성화
          onTap: _isEditing
              ? () => _pickDate(context, isStart)
              : null, // _isEditing이 true일 때만 탭 가능
          decoration: _inputDecoration(
            hint: '날짜 선택',
            suffixIcon: _isEditing
                ? const Icon(Icons.calendar_today, color: AppColors.activeColor)
                : null,
          ),
          style: TextStyle(
            color: _isEditing ? AppColors.black : AppColors.black,
            fontSize: 14,
          ),
        ),
      ],
    );
  }

  // 복용 약물 리스트를 보여주는 위젯 (수정 불가, 각 약물별 파란 보더 사각형)
  Widget _buildMedicationList() {
    if (_medicationsForThisHistory.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 8.0),
        child: Text(
          '등록된 복용 약물이 없습니다.',
          style: TextStyle(color: AppColors.skyBlue, fontSize: 14),
        ),
      );
    }
    return Wrap(
      spacing: 8.0, // 가로 간격
      runSpacing: 8.0, // 세로 간격
      children: _medicationsForThisHistory.map((med) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: AppColors.medicineBtn,
            border: Border.all(
              color: AppColors.activeColor.withOpacity(0.5),
              width: 1.0,
            ),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            med.name,
            style: TextStyle(
              fontSize: 14,
              color: AppColors.black,
              fontWeight: FontWeight.w500,
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildButtonRow() {
  // 새 기록 등록 모드
  if (widget.isNew) {
    return SizedBox(
      width: double.infinity,
      height: 48,
      child: ElevatedButton(
        onPressed: _isEditing
            ? () {
                // 새 기록 저장 로직
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('새 기록이 저장되었습니다')),
                );
                setState(() {
                  _isEditing = false; // 저장 후 조회 모드
                });
              }
            : null,
        style: ElevatedButton.styleFrom(
          backgroundColor: _isEditing ? AppColors.activeColor : const Color.fromARGB(255, 255, 255, 255),
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 0,
        ),
        child: const Text(
          '저장',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
      ),
    );
  }

  // 기존 기록 조회/수정 모드
  return Row(
    children: [
      Expanded(
        child: SizedBox(
          height: 48,
          child: ElevatedButton(
            onPressed: !_isEditing
                ? () {
                    // 수정 버튼 클릭 시
                    setState(() {
                      _isEditing = true; // 수정 모드
                    });
                  }
                : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: !_isEditing ?  AppColors.activeBtn : AppColors.activeColor,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 0,
            ),
            child: const Text(
              '수정',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
          ),
        ),
      ),
      const SizedBox(width: 16),
      Expanded(
        child: SizedBox(
          height: 48,
          child: ElevatedButton(
            onPressed: _isEditing
                ? () {
                    // 저장 버튼 클릭 시
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('기록이 수정되었습니다')),
                    );
                    setState(() {
                      _isEditing = false; // 저장 후 조회 모드
                    });
                  }
                : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: _isEditing ? AppColors.activeColor : AppColors.activeBtn,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 0,
            ),
            child: const Text(
              '저장',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
          ),
        ),
      ),
    ],
  );
}


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            PatientScreenHeader(),
            Expanded(
              child: SingleChildScrollView(
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
                            DropdownMenuItem(value: '가족력', child: Text('가족력')),
                          ],
                          (val) {
                            if (val != null) {
                              setState(() {
                                _type = val;
                                if (_type != '가족력')
                                  _relationshipController.text = '';
                              });
                            }
                          },
                        ),
                        if (_type == '가족력') ...[
                          const SizedBox(height: 20),
                          // 관계
                          Text('관계', style: _labelStyle()),
                          const SizedBox(height: 8),
                          _buildTextField(
                            _relationshipController,
                            hint: '예: 부, 모',
                          ),
                        ],
                        const SizedBox(height: 20),

                        // 증상 요약
                        Text('증상 요약', style: _labelStyle()),
                        const SizedBox(height: 8),
                        _buildTextField(_symptomsController, maxLines: 4),
                        const SizedBox(height: 20),

                        // 발병일 / 완치일
                        Row(
                          children: [
                            Expanded(child: _buildDatePickerField('발병일', true)),
                            const SizedBox(width: 16),
                            Expanded(
                              child: _buildDatePickerField('완치일', false),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),

                        // 상태 / 진행 단계
                        Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('상태', style: _labelStyle()),
                                  const SizedBox(height: 8),
                                  _buildDropdown<String>(
                                    _status,
                                    const [
                                      DropdownMenuItem(
                                        value: '진행중',
                                        child: Text('진행중'),
                                      ),
                                      DropdownMenuItem(
                                        value: '완치',
                                        child: Text('완치'),
                                      ),
                                    ],
                                    (val) {
                                      if (val != null) _status = val;
                                    },
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('진행 단계', style: _labelStyle()),
                                  const SizedBox(height: 8),
                                  _buildTextField(
                                    _progressionStageController,
                                    hint: '예: 1기, 초기',
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),

                        // 병원명
                        Text('병원명', style: _labelStyle()),
                        const SizedBox(height: 8),
                        _buildTextField(_hospitalController),
                        const SizedBox(height: 20),

                        // 치료 방법
                        Text('치료 방법', style: _labelStyle()),
                        const SizedBox(height: 8),
                        _buildTextField(_treatmentController, maxLines: 3),
                        const SizedBox(height: 20),

                        // 메모
                        Text('메모', style: _labelStyle()),
                        const SizedBox(height: 8),
                        _buildTextField(_memoController, maxLines: 4),
                        const SizedBox(height: 30),

                        // MARK: 복용 약 섹션 (수정 모드일 때만 표시하며, 새 기록 등록 시에는 표시하지 않음)
                        if (!widget.isNew) ...[
                          Text('복용 약', style: _labelStyle()),
                          const SizedBox(height: 8),
                          _buildMedicationList(), // 약물 리스트는 수정 불가, 이름만 나열, 각 약물별 박스
                          const SizedBox(height: 30),
                        ],

                        // 하단 버튼 (등록/수정 모드에 따라 다름)
                        _buildButtonRow(),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: PatientScreenBottomNavBar(),
    );
  }
}
