// lib/common/sdui/widgets/sdui_text_field.dart
import 'package:flutter/material.dart';
import 'package:curemate/app/theme/app_colors.dart'; // 공통 컬러 사용
import 'package:curemate/common/sdui/model/sdui_model.dart';
import 'package:curemate/common/sdui/controller/sdui_controller.dart';

class SduiTextField extends StatelessWidget {
  final SduiNode node;
  final SduiController controller;

  const SduiTextField({super.key, required this.node, required this.controller});

  @override
  Widget build(BuildContext context) {
    // Props 파싱
    final String hint = node.props['hint'] ?? '';
    final String suffixText = node.props['suffix_text'] ?? '';
    final String keyboardTypeStr = node.props['keyboard_type'] ?? 'TEXT';

    TextInputType keyboardType = TextInputType.text;
    if (keyboardTypeStr == 'NUMBER') {
      keyboardType = TextInputType.number;
    } else if (keyboardTypeStr == 'EMAIL') {
      keyboardType = TextInputType.emailAddress;
    }

    // 컨트롤러 연결 (Key가 없으면 임시 키 생성 방지)
    final textController = node.nodeKey != null
        ? controller.getTextController(node.nodeKey!)
        : null;

    return TextField(
      controller: textController,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        hintText: hint,
        suffixText: suffixText.isNotEmpty ? suffixText : null,
        filled: true,
        fillColor: AppColors.white,
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: AppColors.inputBorder),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: AppColors.inputBorder),
        ),
      ),
    );
  }
}