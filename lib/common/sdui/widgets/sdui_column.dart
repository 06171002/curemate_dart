// lib/common/sdui/widgets/sdui_column.dart
import 'package:flutter/material.dart';
import 'package:curemate/common/sdui/model/sdui_model.dart';
import 'package:curemate/common/sdui/controller/sdui_controller.dart';
import 'package:curemate/common/sdui/view/sdui_renderer.dart';

class SduiColumn extends StatelessWidget {
  final SduiNode node;
  final SduiController controller;

  const SduiColumn({super.key, required this.node, required this.controller});

  @override
  Widget build(BuildContext context) {
    final double spacing = (node.props['spacing'] ?? 0).toDouble();

    // 자식 위젯들 생성
    final List<SduiNode> safeChildren = node.children ?? [];

    final childrenWidgets = safeChildren.map((childNode) {
      return SduiRenderer(node: childNode, controller: controller);
    }).toList();

    // 간격(Spacing) 추가 로직
    final List<Widget> childrenWithSpacing = [];
    for (int i = 0; i < childrenWidgets.length; i++) {
      childrenWithSpacing.add(childrenWidgets[i]);
      if (i < childrenWidgets.length - 1 && spacing > 0) {
        childrenWithSpacing.add(SizedBox(height: spacing));
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: childrenWithSpacing,
    );
  }
}