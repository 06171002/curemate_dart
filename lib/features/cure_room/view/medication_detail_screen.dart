import 'package:curemate/app/theme/app_colors.dart';
import 'package:curemate/features/widgets/common/header_provider.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:curemate/services/cure_room_service.dart';
import 'package:flutter/services.dart';
import 'package:curemate/features/cure_room/model/cure_room_models.dart';

class MedicationDetailPage extends StatefulWidget {
  /// 등록 모드: false, 수정 모드: true
  final bool isEdit;

  /// 🔹 어떤 환자의 약인지
  final int curePatientSeq;
  /// 🔹 수정 모드일 때 편집할 약 그룹
  final CureMedicineGroupModel? group;


  const MedicationDetailPage({
    super.key,
    required this.curePatientSeq,
    this.isEdit = false,
    this.group, // ✅ 추가
  });

  @override
  State<MedicationDetailPage> createState() => _MedicationDetailPageState();
}

class _MedicationDetailPageState extends State<MedicationDetailPage> {
  final _service = CureRoomService();

  // 🔹 저장 중 상태
  bool _isSaving = false;

  // 약 그룹명
  final TextEditingController _groupNameController = TextEditingController();

  // 세부 약 입력 필드 묶음
  final List<_DetailMedicineField> _detailItems = [];

  @override
  void initState() {
    super.initState();

    // 🔹 수정 모드 + group 데이터가 있는 경우 → 기존 값 채우기
  if (widget.isEdit && widget.group != null) {
    final group = widget.group!;

    // 그룹명
    _groupNameController.text = group.patientMedicineNm;

    // 기존 세부 약 목록을 TextEditingController로 변환
    for (final d in group.details) {
      _detailItems.add(
        _DetailMedicineField(
          nameController: TextEditingController(
            text: d.cureMedicineNm,
          ),
          doseController: TextEditingController(
            text: d.cureMedicineVolume ?? '',
          ),
          quantityController: TextEditingController(
            text: d.cureMedicineQty?.toString() ?? '',
          ),
          detailSeq: d.curePatientMedicineDetailSeq,
        ),
      );
    }

    // 혹시라도 details가 비어있으면 기본 한 줄 넣어주기
    if (_detailItems.isEmpty) {
      _detailItems.add(
        _DetailMedicineField(
          nameController: TextEditingController(),
          doseController: TextEditingController(),
          quantityController: TextEditingController(),
        ),
      );
    }
  } else {
    // 🔹 신규 모드 → 기본 한 줄만
    _detailItems.add(
      _DetailMedicineField(
        nameController: TextEditingController(),
        doseController: TextEditingController(),
        quantityController: TextEditingController(),
      ),
    );
  }
}

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final header = Provider.of<HeaderProvider>(context, listen: false);
    header.setTitle(widget.isEdit ? '약 수정' : '약 등록');
    header.setShowBackButton(true);
  }

  @override
  void dispose() {
    _groupNameController.dispose();
    for (final item in _detailItems) {
      item.nameController.dispose();
      item.doseController.dispose();
      item.quantityController.dispose();
    }
    super.dispose();
  }

  // 공통 decoration
  InputDecoration _inputDecoration({String? hint}) {
    return InputDecoration(
      filled: true,
      fillColor: AppColors.white,
      border: OutlineInputBorder(
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
      TextInputType? keyboardType,
      List<TextInputFormatter>? inputFormatters,
    }) {
      return TextField(
        controller: controller,
        keyboardType: keyboardType,
        inputFormatters: inputFormatters,
        decoration: _inputDecoration(hint: hint),
        style: const TextStyle(color: AppColors.black, fontSize: 14),
      );
    }

  Widget _buildDetailSection(int index) {
    final item = _detailItems[index];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 약명
        Text('세부 약명', style: _labelStyle()),
        const SizedBox(height: 8),
        _buildTextField(item.nameController, hint: '예) 코데살페정'),
        const SizedBox(height: 16),

        // 용량 / 수량 한 줄
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('용량', style: _labelStyle()),
                  const SizedBox(height: 8),
                  _buildTextField(item.doseController, hint: '예) 6mg'),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('수량', style: _labelStyle()),
                  const SizedBox(height: 8),
                  _buildTextField(
                    item.quantityController,
                    hint: '예) 1', // ✅ 정 빼고 숫자만 예시
                    keyboardType: TextInputType.number,
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly, // ✅ 숫자만 입력 허용
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),

        const SizedBox(height: 12),

        if (_detailItems.length > 1)
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: () {
                setState(() => _detailItems.removeAt(index));
              },
              child: const Text(
                '이 세부 약 삭제',
                style: TextStyle(fontSize: 12, color: Colors.redAccent),
              ),
            ),
          ),
      ],
    );
  }

  Future<void> _handleComplete() async {
    if (_isSaving) return;

    FocusScope.of(context).unfocus();

    final groupName = _groupNameController.text.trim();

    if (groupName.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('약 그룹명을 입력해 주세요.')),
      );
      return;
    }

    // 🔹 세부약 리스트 만들기
    final List<Map<String, dynamic>> details = [];
    for (final detail in _detailItems) {
      final name = detail.nameController.text.trim();
      final qtyText = detail.quantityController.text.trim();
      final volumeText = detail.doseController.text.trim();

      if (name.isEmpty) continue; // 이름 없는 줄은 스킵

      // 수량은 int
      final int? qty = qtyText.isEmpty ? null : int.tryParse(qtyText);

      // 용량은 String
      final String? volume =
          volumeText.isEmpty ? null : volumeText;

      final Map<String, dynamic> row = {
        'cureMedicineNm': name,
        'cureMedicineQty': qty,
        'cureMedicineVolume': volume,
      };

      // 🔹 수정 모드 + 기존 세부 약이면 PK도 함께 전송
      if (widget.isEdit && detail.detailSeq != null) {
        row['curePatientMedicineDetailSeq'] = detail.detailSeq;
      }

      details.add(row);
    }

    if (details.isEmpty) {
      // 세부약 없이 그룹만 등록도 허용할 거면 이 체크는 빼도 됨
      // 지금은 그냥 경고만 주자 (일단 통과 허용)
      // ScaffoldMessenger.of(context).showSnackBar(
      //   const SnackBar(content: Text('최소 1개 이상의 세부 약을 입력해 주세요.')),
      // );
      // return;
    }

    setState(() => _isSaving = true);

    try {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('저장 중입니다...')),
      );

      // 🔹 수정 모드라면 이 페이지에 groupSeq를 넘겨받아야 함
      final int? groupSeqForEdit =
          widget.isEdit ? widget.group?.curePatientMedicineSeq : null;

      await _service.savePatientMedicineAll(
        curePatientMedicineSeq: groupSeqForEdit, // 수정이면 값, 신규면 null
        curePatientSeq: widget.curePatientSeq,
        patientMedicineNm: groupName,
        medicineDetails: details,
      );

      final message =
          widget.isEdit ? '약 정보가 수정되었습니다.' : '약 정보가 저장되었습니다.';

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message)),
      );

      if (Navigator.canPop(context)) {
        Navigator.pop(context, true);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('약 저장 중 오류가 발생했습니다.\n$e')),
      );
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  /// 🔹 상단 바 (뒤로가기 + 완료) — 병력 상세와 동일 스타일
  Widget _buildTopBar(BuildContext context) {
  final titleText = widget.isEdit ? '약 수정' : '약 등록';

  return Padding(
    padding: const EdgeInsets.fromLTRB(8, 12, 16, 0),
    child: SizedBox(
      height: 40,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // ⬅ 왼쪽 뒤로가기
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
                color: Colors.black, // ✅ 검정 아이콘 (프로필/병력과 통일)
              ),
            ),
          ),

          // 🔹 가운데 타이틀
          Expanded(
            child: Center(
              child: Text(
                titleText,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.black, // ✅ 검정 타이틀
                ),
              ),
            ),
          ),

          // ✔ 오른쪽 완료 버튼
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
                      : AppColors.skyBlue, // ✅ 액션 컬러만 하늘색
                ),
              ),
            ),
          ),
        ],
      ),
    ),
  );
}

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.lightBackground,
      body: SafeArea(
        child: Column(
          children: [
            // 🔹 상단바
            _buildTopBar(context),

            // 본문
            Expanded(
              child: SingleChildScrollView(
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // -------------------------
                    // 🔵 필수 입력 제목 (카드 밖)
                    // -------------------------
                    const Text(
                      '필수 입력',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: AppColors.black,
                      ),
                    ),
                    const SizedBox(height: 8),

                    // 필수 입력 카드
                    Card(
                      elevation: 3,
                      color: AppColors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('약 그룹명', style: _labelStyle()),
                            const SizedBox(height: 8),
                            _buildTextField(
                              _groupNameController,
                              hint: '예) 기침약, 식후 비타민',
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 24),

                    // -------------------------
                    // 🟣 선택 입력 제목 (카드 밖)
                    // -------------------------
                    const Text(
                      '선택 입력',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: AppColors.black,
                      ),
                    ),
                    const SizedBox(height: 8),

                    // 선택 입력 카드
                    Card(
                      elevation: 3,
                      color: AppColors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
                        child: Column(
                          children: [
                            for (int i = 0; i < _detailItems.length; i++) ...[
                              if (i > 0) ...[
                                const SizedBox(height: 16),
                                const Divider(height: 1),
                                const SizedBox(height: 16),
                              ],
                              _buildDetailSection(i),
                            ],
                            const SizedBox(height: 16),

                            // 세부 약 추가 버튼
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor:  Color(0xFFA0C4FF),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(24),
                                  ),
                                  padding: const EdgeInsets.symmetric(
                                      vertical: 14),
                                ),
                                onPressed: () {
                                  setState(() {
                                    _detailItems.add(
                                      _DetailMedicineField(
                                        nameController:
                                            TextEditingController(),
                                        doseController:
                                            TextEditingController(),
                                        quantityController:
                                            TextEditingController(),
                                      ),
                                    );
                                  });
                                },
                                child: const Text(
                                  '+ 세부 약 추가',
                                  style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// 세부 약 컨트롤러 묶음
class _DetailMedicineField {
  final TextEditingController nameController;
  final TextEditingController doseController;
  final TextEditingController quantityController;

  /// 🔹 수정 모드일 때 기존 세부 약의 PK
  final int? detailSeq;

  _DetailMedicineField({
    required this.nameController,
    required this.doseController,
    required this.quantityController,
    this.detailSeq,
  });
}
