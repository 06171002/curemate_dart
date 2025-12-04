import 'package:flutter/material.dart';
import 'package:curemate/common/sdui/model/sdui_model.dart';
import 'package:curemate/common/sdui/controller/sdui_controller.dart';
import 'package:curemate/common/sdui/widgets/sdui_column.dart';
import 'package:curemate/common/sdui/widgets/sdui_row.dart';
import 'package:curemate/common/sdui/widgets/sdui_text_field.dart';
import 'package:curemate/common/sdui/widgets/sdui_slider.dart';
import 'package:curemate/common/sdui/widgets/sdui_select.dart';

class SduiRenderer extends StatelessWidget {
  final SduiNode node;
  final SduiController controller;

  const SduiRenderer({
    super.key,
    required this.node,
    required this.controller,
  });

  @override
  Widget build(BuildContext context) {
    switch (node.nodeTypeCd) {
      case 'COLUMN':
      case 'SECTION':
      case 'TAB_ITEM':
        return SduiColumn(node: node, controller: controller);

      case 'ROW':
        return SduiRow(node: node, controller: controller);

      case 'TEXT_FIELD':
      case 'DUAL_NUMBER': // (DB 데이터에 있다면)
        return SduiTextField(node: node, controller: controller); // 필요시 별도 위젯 분리

      case 'SLIDER':
        return SduiSlider(node: node, controller: controller);

      case 'SELECT': // RADIO, CHECKBOX, CHIP 등 통합
        return SduiSelect(node: node, controller: controller);

      case 'DISPLAY': // 텍스트 표시용
        return Text(node.label ?? '', style: const TextStyle(fontSize: 14));

      case 'RADIO_GROUP':
        // TODO: SduiRadioGroup 위젯 구현 필요
        return Text("[Radio Placeholder: ${node.label}]");

      default:
        return Container(
          padding: const EdgeInsets.all(8),
          color: Colors.red[50],
          child: Text('구현되지 않은 타입: ${node.nodeTypeCd}'),
        );
    }
  }
}