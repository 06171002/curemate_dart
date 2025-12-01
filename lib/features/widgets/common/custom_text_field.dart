import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:curemate/app/theme/app_colors.dart';

class CustomTextField extends StatelessWidget {
  final String label;
  final String? hint;
  final TextEditingController? controller;
  final bool isRequired;
  final TextInputType inputType;
  final bool readOnly;
  final VoidCallback? onTap;
  final IconData? suffixIcon;
  final int maxLines;
  final List<TextInputFormatter>? inputFormatters;
  final String? Function(String?)? validator;
  final ValueChanged<String>? onChanged;

  const CustomTextField({
    super.key,
    required this.label,
    this.hint,
    this.controller,
    this.isRequired = false, // 기본값 false
    this.inputType = TextInputType.text,
    this.readOnly = false,
    this.onTap,
    this.suffixIcon,
    this.maxLines = 1,
    this.inputFormatters,
    this.validator,
    this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 1. 라벨 영역 (필수 표시 * 포함)
        RichText(
          text: TextSpan(
            text: label,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: AppColors.textMainDark,
              fontFamily: 'Pretendard', // 앱 폰트 적용
            ),
            children: [
              if (isRequired)
                const TextSpan(
                  text: ' *',
                  style: TextStyle(color: AppColors.error),
                ),
            ],
          ),
        ),
        const SizedBox(height: 8),

        // 2. 입력 필드 영역
        TextFormField(
          controller: controller,
          keyboardType: inputType,
          readOnly: readOnly,
          onTap: onTap,
          maxLines: maxLines,
          inputFormatters: inputFormatters,
          onChanged: onChanged,
          style: const TextStyle(fontSize: 14, color: AppColors.black),
          // 유효성 검사 로직 (커스텀 validator가 없으면 기본 로직 사용)
          validator: validator ??
                  (value) {
                if (isRequired && (value == null || value.trim().isEmpty)) {
                  return '$label을(를) 입력해주세요.';
                }
                return null;
              },
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(
              color: AppColors.textSecondaryLight,
              fontSize: 14,
            ),
            filled: true,
            fillColor: AppColors.white,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 14,
            ),
            // 기본 테두리
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.inputBorder),
            ),
            // 활성화 시 테두리
            enabledBorder: const OutlineInputBorder(
              borderRadius: BorderRadius.all(Radius.circular(12)),
              borderSide: BorderSide(color: AppColors.inputBorder),
            ),
            // 포커스 시 테두리
            focusedBorder: const OutlineInputBorder(
              borderRadius: BorderRadius.all(Radius.circular(12)),
              borderSide: BorderSide(color: AppColors.activeColor, width: 2),
            ),
            // 에러 시 테두리
            errorBorder: const OutlineInputBorder(
              borderRadius: BorderRadius.all(Radius.circular(12)),
              borderSide: BorderSide(color: AppColors.error),
            ),
            suffixIcon: suffixIcon != null
                ? Icon(suffixIcon, color: AppColors.textSecondaryLight)
                : null,
          ),
        ),
      ],
    );
  }
}