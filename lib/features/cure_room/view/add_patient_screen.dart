// lib/features/cure_room/view/add_patient_screen.dart
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

import 'package:curemate/app/theme/app_colors.dart';
import 'package:curemate/features/widgets/common/bottom_nav_provider.dart';
import 'package:curemate/features/cure_room/viewmodel/add_patient_viewmodel.dart';

// ✅ 공통 위젯 import
import 'package:curemate/features/widgets/common/custom_profile_avatar.dart';
import 'package:curemate/features/widgets/common/custom_text_field.dart';
import 'package:curemate/features/widgets/common/custom_radio_group.dart';

class AddPatientScreen extends StatelessWidget {
  const AddPatientScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => AddPatientViewModel(),
      child: const _AddPatientContent(),
    );
  }
}

class _AddPatientContent extends StatefulWidget {
  const _AddPatientContent();

  @override
  State<_AddPatientContent> createState() => _AddPatientContentState();
}

class _AddPatientContentState extends State<_AddPatientContent> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _nameController;
  late TextEditingController _birthController;
  late TextEditingController _weightController;
  late TextEditingController _heightController;

  /// 성별 코드 (API 예: "man", "woman")
  String _selectedGender = 'man';

  /// 혈액형 선택: Rh(+/-) + ABO
  String _selectedRh = 'plus'; // 'plus' => '+', 'minus' => '-'
  String _selectedAbo = 'A';   // 'A', 'B', 'O', 'AB'

  @override
  void initState() {
    super.initState();

    _nameController = TextEditingController();
    _birthController = TextEditingController();
    _weightController = TextEditingController();
    _heightController = TextEditingController();
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
              '${t.substring(0, 4)}-${t.substring(4, 6)}-${t.substring(6, 8)}');
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

  Future<void> _onSave() async {
    FocusScope.of(context).unfocus();

    if (!_formKey.currentState!.validate()) return;

    final nav = context.read<BottomNavProvider>();
    final vm = context.read<AddPatientViewModel>();

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

    // Rh(+/-) + ABO 조합해서 "A+" / "O-" 형식으로 만들기
    final String? bloodType =
        _selectedAbo.isEmpty ? null : '$_selectedAbo${_selectedRh == 'plus' ? '+' : '-'}';

    // 🔹 custSeq는 지금 구조에서는 별도 입력이 없으니 null로 둠
    final success = await vm.savePatient(
      cureSeq: cureSeq,
      patientNm: _nameController.text,
      patientBirthday: _birthController.text,
      patientGenderCmcd: _selectedGender,
      patientBloodTypeCmcd: bloodType,
      patientWeight: weight,
      patientHeight: height,
    );

    if (!mounted) return;

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('환자가 등록되었습니다.')),
      );
      Navigator.pop(context, true); // ✅ true 넘기기
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('환자 등록에 실패했습니다. 다시 시도해주세요.')),
      );
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
            '환자 등록',
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
              onPressed: vm.isSaving ? null : _onSave,
              child: vm.isSaving
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
                // ✅ 공통 프로필 아바타 사용
                Center(
                  child: Stack(
                    children: [
                      CustomProfileAvatar(
                        imageFile: vm.selectedImage,
                        imageUrl: null, // 추후 서버 이미지 있으면 여기로
                        radius: 50,     // 100px
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

                // ✅ 2. 환자 이름 (필수)
                CustomTextField(
                  label: '환자 이름',
                  hint: '이름을 입력하세요',
                  controller: _nameController,
                  isRequired: true,
                ),
                const SizedBox(height: 24),

                // ✅ 3. 생년월일 (필수)
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

                // ✅ 4. 성별 (공통 라디오 그룹)
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

                // 5. 혈액형 (Rh + ABO 버튼) - 그대로 유지
                _buildBloodTypeSection(),
                const SizedBox(height: 24),

                // ✅ 6. 체중
                CustomTextField(
                  label: '체중 (kg)',
                  hint: '예: 75',
                  controller: _weightController,
                  inputType: TextInputType.number,
                ),
                const SizedBox(height: 24),

                // ✅ 7. 키
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

  // 🔹 혈액형 공통 아님 → 기존 로직 그대로 유지

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
            color: selected ? Color(0xFFA0C4FF) : AppColors.inputBorder,
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
          style: TextStyle(
            fontSize: 15,
            fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
            color:  AppColors.textMainDark,
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

        // 🔹 Rh 선택 영역
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

        // 🔹 ABO 선택 영역
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
