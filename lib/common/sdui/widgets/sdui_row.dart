// lib/common/sdui/widgets/sdui_row.dart
import 'package:flutter/material.dart';
import '../model/sdui_model.dart';
import '../controller/sdui_controller.dart';
import '../view/sdui_renderer.dart';

class SduiRow extends StatelessWidget {
  final SduiNode node;
  final SduiController controller;

  const SduiRow({super.key, required this.node, required this.controller});

  @override
  Widget build(BuildContext context) {
    final double spacing = (node.props['spacing'] ?? 0).toDouble();

    final childrenWidgets = node.children!.map((childNode) {
      // Row 내부의 입력 필드는 보통 꽉 채우는 게 이쁘므로 Expanded 처리
      // (필요 시 props로 제어 가능)
      return Expanded(
        child: SduiRenderer(node: childNode, controller: controller),
      );
    }).toList();

    final List<Widget> childrenWithSpacing = [];
    for (int i = 0; i < childrenWidgets.length; i++) {
      childrenWithSpacing.add(childrenWidgets[i]);
      if (i < childrenWidgets.length - 1 && spacing > 0) {
        childrenWithSpacing.add(SizedBox(width: spacing));
      }
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: childrenWithSpacing,
    );
  }
}