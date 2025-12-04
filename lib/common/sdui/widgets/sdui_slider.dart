import 'package:flutter/material.dart';
import 'package:curemate/app/theme/app_colors.dart';
import 'package:curemate/common/sdui/model/sdui_model.dart';
import 'package:curemate/common/sdui/controller/sdui_controller.dart';

class SduiSlider extends StatefulWidget {
  final SduiNode node;
  final SduiController controller;

  const SduiSlider({super.key, required this.node, required this.controller});

  @override
  State<SduiSlider> createState() => _SduiSliderState();
}

class _SduiSliderState extends State<SduiSlider> {
  double _currentValue = 0.0;
  late double _min;
  late double _max;
  late int _divisions;

  @override
  void initState() {
    super.initState();
    _parseProps();

    // 초기값 로드 (컨트롤러에 저장된 값 or 최소값)
    final savedVal = widget.controller.formData[widget.node.nodeKey];
    _currentValue = savedVal != null
        ? double.tryParse(savedVal.toString()) ?? _min
        : _min;

    // 초기값도 컨트롤러에 세팅 (저장 시 누락 방지)
    if (widget.node.nodeKey != null) {
      widget.controller.updateValue(widget.node.nodeKey!, _currentValue);
    }
  }

  void _parseProps() {
    final props = widget.node.props;
    _min = (props['min'] ?? 0).toDouble();
    _max = (props['max'] ?? 100).toDouble();

    // divisions(눈금)가 없으면 1단위로 자동 계산, 너무 많으면 null(부드럽게)
    if (props['divisions'] != null) {
      _divisions = props['divisions'];
    } else {
      // 예: 35~42도 -> 범위 7 -> 0.1단위면 70칸
      double range = _max - _min;
      _divisions = range <= 10 ? (range * 10).toInt() : range.toInt();
    }
  }

  @override
  Widget build(BuildContext context) {
    final label = widget.node.label ?? '';
    final unit = widget.node.props['unit'] ?? '';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 라벨 + 현재값 표시
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(label, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
              Text(
                '${_currentValue.toStringAsFixed(1)} $unit',
                style: const TextStyle(color: AppColors.mainBtn, fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ),

        SliderTheme(
          data: SliderTheme.of(context).copyWith(
            activeTrackColor: AppColors.mainBtn,
            thumbColor: AppColors.mainBtn,
            inactiveTrackColor: AppColors.lightGrey,
            trackHeight: 4.0,
          ),
          child: Slider(
            value: _currentValue,
            min: _min,
            max: _max,
            divisions: _divisions > 0 ? _divisions : null,
            label: _currentValue.toStringAsFixed(1),
            onChanged: (val) {
              setState(() => _currentValue = val);
              if (widget.node.nodeKey != null) {
                widget.controller.updateValue(widget.node.nodeKey!, val);
              }
            },
          ),
        ),
      ],
    );
  }
}