import 'package:curemate/features/guardian/viewmodel/guardian_viewmodel.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:curemate/app/theme/app_colors.dart';

class GuardianRegistrationPage extends StatelessWidget {
  const GuardianRegistrationPage({super.key});

  @override
  Widget build(BuildContext context) {
    final viewModel = Provider.of<GuardianViewModel>(context);

    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(
          maxHeight: 600,
          maxWidth: 400,
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              const Text(
                '보호자 정보 등록',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Expanded(
                child: Scrollbar(
                  thumbVisibility: true,
                  radius: const Radius.circular(8),
                  thickness: 8,
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Column(
                      children: [
                        _buildFormGroup(
                          label: '이름',
                          isRequired: true,
                          child: TextFormField(
                            controller: viewModel.nameController,
                            decoration: _inputDecoration('이름을 입력하세요'),
                          ),
                        ),
                        const SizedBox(height: 16),
                        _buildFormGroup(
                          label: '연락처',
                          isRequired: true,
                          child: TextFormField(
                            controller: viewModel.phoneController,
                            keyboardType: TextInputType.phone,
                            inputFormatters: [
                              FilteringTextInputFormatter.digitsOnly,
                              LengthLimitingTextInputFormatter(11),
                            ],
                            onChanged: (value) {
                              final formatted = viewModel.formatPhoneNumber(value);
                              viewModel.phoneController.value = viewModel.phoneController.value.copyWith(
                                text: formatted,
                                selection: TextSelection.collapsed(offset: formatted.length),
                              );
                            },
                            decoration: _inputDecoration('번호만 입력해주세요'),
                          ),
                        ),
                        const SizedBox(height: 16),
                        _buildFormGroup(
                          label: '생년월일',
                          isRequired: true,
                          child: TextFormField(
                            controller: viewModel.birthController,
                            readOnly: true,
                            onTap: () => viewModel.selectDate(context),
                            decoration: _inputDecoration('생년월일 선택'),
                          ),
                        ),
                        const SizedBox(height: 16),
                        _buildFormGroup(
                          label: '성별',
                          isRequired: true,
                          child: Row(
                            children: [
                              _buildRadioOption('남성', '남성', viewModel),
                              const SizedBox(width: 16),
                              _buildRadioOption('여성', '여성', viewModel),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                height: 48,
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: viewModel.isLoading ? null : () => viewModel.submitForm(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.mainBtn,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  child: viewModel.isLoading
                      ? const CircularProgressIndicator(color: Colors.white, strokeWidth: 2)
                      : const Text('등록하기', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFormGroup({required String label, required Widget child, bool isRequired = false}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(label, style: const TextStyle(fontSize: 14)),
            if (isRequired) const Text(' *', style: TextStyle(color: Colors.red)),
          ],
        ),
        const SizedBox(height: 8),
        child,
      ],
    );
  }

  Widget _buildRadioOption(String label, String value, GuardianViewModel viewModel) {
    return Row(
      children: [
        Radio<String>(
          value: value,
          groupValue: viewModel.gender,
          onChanged: (newVal) => viewModel.setGender(newVal!),
          activeColor: AppColors.mainBtn,
        ),
        Text(label),
      ],
    );
  }

  InputDecoration _inputDecoration(String hint) {
    return InputDecoration(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      hintText: hint,
      filled: true,
      fillColor: Colors.white,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: AppColors.mainBtn, width: 2),
      ),
    );
  }
}
