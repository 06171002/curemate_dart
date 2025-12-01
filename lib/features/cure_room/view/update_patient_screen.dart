// lib/features/cure_room/view/update_patient_screen.dart
import 'dart:io';

import 'package:curemate/services/cure_room_service.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

import 'package:curemate/app/theme/app_colors.dart';
import 'package:curemate/features/widgets/common/bottom_nav_provider.dart';
import 'package:curemate/features/cure_room/viewmodel/add_patient_viewmodel.dart';

// ↑ 이미지 선택/selectedImage 재사용 용도로 일단 AddPatientViewModel 사용
// TODO: 나중에 필요하면 UpdatePatientViewModel로 분리해도 됨.

// 공통 위젯
import 'package:curemate/features/widgets/common/custom_profile_avatar.dart';
import 'package:curemate/features/widgets/common/custom_text_field.dart';
import 'package:curemate/features/widgets/common/custom_radio_group.dart';

class UpdatePatientScreen extends StatelessWidget {
  /// 수정할 환자 기본 정보 (필요한 것만 받도록 설계)
  final int patientSeq;
  final String initialName;
  final String? initialBirthday; // "yyyy-MM-dd" 형식 가정
  final String initialGender; // "man" / "woman"
  final String? initialBloodType; // 예: "A+", "O-", null
  final int? initialWeight;
  final int? initialHeight;

  // 프로필 이미지 (선택 사항)
  final File? initialImageFile;
  final String? initialImageUrl;

  const UpdatePatientScreen({
    super.key,
    required this.patientSeq,
    required this.initialName,
    this.initialBirthday,
    required this.initialGender,
    this.initialBloodType,
    this.initialWeight,
    this.initialHeight,
    this.initialImageFile,
    this.initialImageUrl,
  });

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      // ❗️지금은 AddPatientViewModel 재사용 (이미지 선택/상태 때문)
      create: (_) => AddPatientViewModel(),
      child: _UpdatePatientContent(
        patientSeq: patientSeq,
        initialName: initialName,
        initialBirthday: initialBirthday,
        initialGender: initialGender,
        initialBloodType: initialBloodType,
        initialWeight: initialWeight,
        initialHeight: initialHeight,
        initialImageFile: initialImageFile,
        initialImageUrl: initialImageUrl,
      ),
    );
  }
}

class _UpdatePatientContent extends StatefulWidget {
  final int patientSeq;
  final String initialName;
  final String? initialBirthday;
  final String initialGender;
  final String? initialBloodType;
  final int? initialWeight;
  final int? initialHeight;
  final File? initialImageFile;
  final String? initialImageUrl;

  const _UpdatePatientContent({
    super.key,
    required this.patientSeq,
    required this.initialName,
    this.initialBirthday,
    required this.initialGender,
    this.initialBloodType,
    this.initialWeight,
    this.initialHeight,
    this.initialImageFile,
    this.initialImageUrl,
  });

  @override
  State<_UpdatePatientContent> createState() => _UpdatePatientContentState();
}

class _UpdatePatientContentState extends State<_UpdatePatientContent> {
  final _formKey = GlobalKey<FormState>();

  // 🔹 추가
  final CureRoomService _cureRoomService = CureRoomService();
  bool _isSaving = false;

  late TextEditingController _nameController;
  late TextEditingController _birthController;
  late TextEditingController _weightController;
  late TextEditingController _heightController;

  String _selectedGender = 'man';
  String _selectedRh = 'plus'; // 'plus' => '+', 'minus' => '-'
  String _selectedAbo = 'A';   // 'A', 'B', 'O', 'AB'

  @override
  void initState() {
    super.initState();

    _nameController = TextEditingController(text: widget.initialName);
    _birthController = TextEditingController(
      text: widget.initialBirthday ?? '',
    );
    _weightController = TextEditingController(
      text: widget.initialWeight?.toString() ?? '',
    );
    _heightController = TextEditingController(
      text: widget.initialHeight?.toString() ?? '',
    );

    // 성별 초기값
    _selectedGender = widget.initialGender;

    // 혈액형 초기값 파싱 ("A+", "O-" 등)
    if (widget.initialBloodType != null &&
        widget.initialBloodType!.isNotEmpty) {
      final bt = widget.initialBloodType!;
      // 마지막 글자가 + 또는 - 라고 가정
      final last = bt[bt.length - 1];
      final abo = bt.substring(0, bt.length - 1); // "A", "B", "AB", "O"

      if (last == '+') {
        _selectedRh = 'plus';
      } else if (last == '-') {
        _selectedRh = 'minus';
      }

      if (abo == 'A' || abo == 'B' || abo == 'O' || abo == 'AB') {
        _selectedAbo = abo;
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _birthController.dispose();
    _weightController.dispose();
    _heightController.dispose();
    super.dispose();
  }

  Future<void> _pickBirthDate() async {
    DateTime initialDate = DateTime.now();

    if (_birthController.text.isNotEmpty) {
      try {
        final t = _birthController.text.replaceAll('-', '');
        if (t.length == 8) {
          initialDate = DateTime.parse(
            '${t.substring(0, 4)}-${t.substring(4, 6)}-${t.substring(6, 8)}',
          );
        }
      } catch (_) {}
    }

    final picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFFA0C4FF),
              onPrimary: AppColors.white,
              onSurface: AppColors.textMainDark,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        _birthController.text = DateFormat('yyyy-MM-dd').format(picked);
      });
    }
  }

  Future<void> _onUpdate() async {
  FocusScope.of(context).unfocus();

  if (!_formKey.currentState!.validate()) return;

  final nav = context.read<BottomNavProvider>();
  final vm  = context.read<AddPatientViewModel>(); // 👈 이미지 / 업로드용

  final int? cureSeq = nav.cureSeq;
  if (cureSeq == null) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('선택된 큐어룸이 없습니다. 다시 시도해주세요.')),
    );
    return;
  }

  final int? weight = _weightController.text.isEmpty
      ? null
      : int.tryParse(_weightController.text);
  final int? height = _heightController.text.isEmpty
      ? null
      : int.tryParse(_heightController.text);

  final String? bloodType =
      _selectedAbo.isEmpty ? null : '$_selectedAbo${_selectedRh == 'plus' ? '+' : '-'}';

  // 🔹 등록과 동일하게 문자열만 넘기고, 실제 변환은 saveCurePatient에서 처리
  final String birthdayText = _birthController.text; // "yyyy-MM-dd"

  setState(() {
    _isSaving = true;
  });

  try {
    int? mediaGroupSeq;

    // 🔹 새 프로필 이미지를 선택한 경우에만 업로드
    if (vm.selectedImage != null) {
      mediaGroupSeq = await vm.uploadPatientProfileImage(
        cureSeq: cureSeq,
      );
    }

    // 🔹 환자 정보 수정 API 호출
    await _cureRoomService.updateCurePatient(
      curePatientSeq: widget.patientSeq,
      cureSeq: cureSeq,
      patientNm: _nameController.text,
      patientBirthday: birthdayText, // saveCurePatient에서 YYYYMMDD로 정리됨
      patientGenderCmcd: _selectedGender,
      patientBloodTypeCmcd: bloodType,
      patientWeight: weight,
      patientHeight: height,
      patientMediaGroupSeq: mediaGroupSeq, // 👈 여기!
    );

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('환자 정보가 수정되었습니다.')),
    );
    Navigator.pop(context, {
      'updated': true,
      'localImageFile': vm.selectedImage, // 새로 선택한 이미지(File?) 없으면 null
    });
  } catch (e) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('환자 정보 수정에 실패했습니다.\n$e')),
    );
  } finally {
    if (mounted) {
      setState(() {
        _isSaving = false;
      });
    }
  }
}
  @override
  Widget build(BuildContext context) {
    final vm = context.watch<AddPatientViewModel>();

    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        backgroundColor: AppColors.white,
        appBar: AppBar(
          title: const Text(
            '환자 정보 수정',
            style: TextStyle(
              color: Colors.black,
              fontWeight: FontWeight.bold,
            ),
          ),
          backgroundColor: AppColors.white,
          elevation: 0,
          iconTheme: const IconThemeData(color: Colors.black),
          actions: [
            TextButton(
              onPressed: _isSaving ? null : _onUpdate,
              child: _isSaving
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Color(0xFFA0C4FF),
                      ),
                    )
                  : const Text(
                      '저장',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFFA0C4FF),
                      ),
                    ),
            ),
          ],
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 프로필 이미지: 새로 선택한 이미지 > 기존 local 파일 > 기존 URL
                Center(
                  child: Stack(
                    children: [
                      CustomProfileAvatar(
                        imageFile: vm.selectedImage ?? widget.initialImageFile,
                        imageUrl: widget.initialImageUrl,
                        radius: 50,
                      ),
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: GestureDetector(
                          onTap: () => vm.pickImage(),
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: AppColors.white,
                              shape: BoxShape.circle,
                              border: Border.all(color: AppColors.inputBorder),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.1),
                                  blurRadius: 4,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: const Icon(
                              Icons.camera_alt,
                              size: 20,
                              color: AppColors.textMainDark,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 32),

                // 이름
                CustomTextField(
                  label: '환자 이름',
                  hint: '이름을 입력하세요',
                  controller: _nameController,
                  isRequired: true,
                ),
                const SizedBox(height: 24),

                // 생년월일
                CustomTextField(
                  label: '생년월일',
                  hint: 'YYYY-MM-DD',
                  controller: _birthController,
                  readOnly: true,
                  suffixIcon: Icons.calendar_today,
                  onTap: _pickBirthDate,
                  isRequired: true,
                ),
                const SizedBox(height: 24),

                // 성별
                CustomRadioGroup<String>(
                  label: '성별',
                  groupValue: _selectedGender,
                  values: const ['man', 'woman'],
                  itemLabels: const ['남성', '여성'],
                  onChanged: (val) {
                    if (val == null) return;
                    setState(() {
                      _selectedGender = val;
                    });
                  },
                  isRequired: true,
                ),
                const SizedBox(height: 24),

                // 혈액형
                _buildBloodTypeSection(),
                const SizedBox(height: 24),

                // 체중
                CustomTextField(
                  label: '체중 (kg)',
                  hint: '예: 75',
                  controller: _weightController,
                  inputType: TextInputType.number,
                ),
                const SizedBox(height: 24),

                // 키
                CustomTextField(
                  label: '키 (cm)',
                  hint: '예: 180',
                  controller: _heightController,
                  inputType: TextInputType.number,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // -----------------------------
  // 혈액형 UI (Add 화면과 동일하게)
  // -----------------------------

  Widget _buildLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.bold,
          color: AppColors.textMainDark,
        ),
      ),
    );
  }

  Widget _buildRadioChip({
    required String label,
    required String value,
    required String groupValue,
    required ValueChanged<String> onChanged,
  }) {
    final bool selected = value == groupValue;

    return InkWell(
      onTap: () => onChanged(value),
      borderRadius: BorderRadius.circular(10),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: selected
              ? Color(0xFFA0C4FF).withOpacity(0.15)
              : const Color(0xFFF3F6FA),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: selected ? const Color(0xFFA0C4FF) : AppColors.inputBorder,
            width: selected ? 2 : 1,
          ),
          boxShadow: selected
              ? [
                  BoxShadow(
                    color: Color(0xFFA0C4FF).withOpacity(0.2),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ]
              : [],
        ),
        child: Text(
          label,
          style: const TextStyle(
            fontSize: 15,
            // ✅ 선택 여부 상관 없이 글자색 고정
            fontWeight: FontWeight.w500,
            color: AppColors.textMainDark,
          ),
        ),
      ),
    );
  }

  Widget _buildBloodTypeSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildLabel('혈액형'),
        const SizedBox(height: 8),

        const Text(
          'Rh 선택',
          style: TextStyle(
            fontSize: 12,
            color: AppColors.textSecondaryLight,
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            _buildRadioChip(
              label: 'Rh+',
              value: 'plus',
              groupValue: _selectedRh,
              onChanged: (v) {
                setState(() => _selectedRh = v);
              },
            ),
            _buildRadioChip(
              label: 'Rh-',
              value: 'minus',
              groupValue: _selectedRh,
              onChanged: (v) {
                setState(() => _selectedRh = v);
              },
            ),
          ],
        ),

        const SizedBox(height: 16),

        const Text(
          'ABO 선택',
          style: TextStyle(
            fontSize: 12,
            color: AppColors.textSecondaryLight,
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            _buildRadioChip(
              label: 'A',
              value: 'A',
              groupValue: _selectedAbo,
              onChanged: (v) {
                setState(() => _selectedAbo = v);
              },
            ),
            _buildRadioChip(
              label: 'B',
              value: 'B',
              groupValue: _selectedAbo,
              onChanged: (v) {
                setState(() => _selectedAbo = v);
              },
            ),
            _buildRadioChip(
              label: 'O',
              value: 'O',
              groupValue: _selectedAbo,
              onChanged: (v) {
                setState(() => _selectedAbo = v);
              },
            ),
            _buildRadioChip(
              label: 'AB',
              value: 'AB',
              groupValue: _selectedAbo,
              onChanged: (v) {
                setState(() => _selectedAbo = v);
              },
            ),
          ],
        ),
      ],
    );
  }
}
