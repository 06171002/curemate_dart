import 'package:flutter/material.dart';
import 'package:curemate/app/theme/app_colors.dart';
import 'package:curemate/common/sdui/model/sdui_model.dart';
import 'package:curemate/common/sdui/controller/sdui_controller.dart';

class SduiSelect extends StatefulWidget {
  final SduiNode node;
  final SduiController controller;

  const SduiSelect({super.key, required this.node, required this.controller});

  @override
  State<SduiSelect> createState() => _SduiSelectState();
}

class _SduiSelectState extends State<SduiSelect> {
  // 단일 선택 값
  String? _singleValue;
  // 다중 선택 값 (CHECKBOX용)
  final List<String> _multiValues = [];

  late List<Map<String, dynamic>> _options;
  late String _renderType;

  @override
  void initState() {
    super.initState();
    _parseOptions();
    _loadInitialValue();
  }

  void _parseOptions() {
    // DB의 'options' JSON은 List<dynamic> 형태로 들어옴
    final rawOptions = widget.node.props['options'];
    if (rawOptions is List) {
      _options = rawOptions.map((e) => Map<String, dynamic>.from(e)).toList();
    } else {
      _options = [];
    }
    _renderType = widget.node.props['render_type'] ?? 'DROPDOWN';
  }

  void _loadInitialValue() {
    // 컨트롤러에 저장된 값이 있으면 불러옴 (없으면 null)
    final saved = widget.controller.formData[widget.node.nodeKey];

    if (_renderType == 'CHECKBOX') {
      if (saved is List) {
        _multiValues.addAll(saved.map((e) => e.toString()));
      }
    } else {
      _singleValue = saved?.toString();
    }
  }

  void _onSingleChanged(String? val) {
    setState(() => _singleValue = val);
    if (widget.node.nodeKey != null) {
      widget.controller.updateValue(widget.node.nodeKey!, val);
    }
  }

  void _onMultiChanged(String val, bool isSelected) {
    setState(() {
      if (isSelected) {
        _multiValues.add(val);
      } else {
        _multiValues.remove(val);
      }
    });
    if (widget.node.nodeKey != null) {
      widget.controller.updateValue(widget.node.nodeKey!, _multiValues);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (widget.node.label != null) ...[
          Text(widget.node.label!, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
          const SizedBox(height: 8),
        ],
        _buildBody(),
      ],
    );
  }

  Widget _buildBody() {
    switch (_renderType) {
      case 'CHIP':
        return _buildChipGroup();
      case 'CHECKBOX':
        return _buildCheckboxGroup();
      case 'RADIO':
        return _buildRadioGroup();
      case 'DROPDOWN':
      default:
        return _buildDropdown();
    }
  }

  // 1. CHIP (ChoiceChip)
  Widget _buildChipGroup() {
    return Wrap(
      spacing: 8.0,
      runSpacing: 8.0,
      children: _options.map((opt) {
        final label = opt['label'] ?? '';
        final value = opt['value'] ?? '';
        final isSelected = _singleValue == value;

        return ChoiceChip(
          label: Text(label),
          selected: isSelected,
          onSelected: (selected) {
            if (selected) _onSingleChanged(value);
          },
          selectedColor: AppColors.mainBtn,
          backgroundColor: AppColors.white,
          labelStyle: TextStyle(
            color: isSelected ? Colors.white : AppColors.textMainDark,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: BorderSide(color: isSelected ? Colors.transparent : AppColors.inputBorder),
          ),
          showCheckmark: false,
        );
      }).toList(),
    );
  }

  // 2. CHECKBOX (다중 선택)
  Widget _buildCheckboxGroup() {
    return Column(
      children: _options.map((opt) {
        final label = opt['label'] ?? '';
        final value = opt['value'] ?? '';
        final isChecked = _multiValues.contains(value);

        return CheckboxListTile(
          title: Text(label, style: const TextStyle(fontSize: 14)),
          value: isChecked,
          activeColor: AppColors.mainBtn,
          contentPadding: EdgeInsets.zero,
          controlAffinity: ListTileControlAffinity.leading,
          dense: true,
          onChanged: (val) => _onMultiChanged(value, val ?? false),
        );
      }).toList(),
    );
  }

  // 3. DROPDOWN
  Widget _buildDropdown() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: AppColors.white,
        border: Border.all(color: AppColors.inputBorder),
        borderRadius: BorderRadius.circular(8),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: _singleValue,
          hint: const Text("선택하세요"),
          isExpanded: true,
          items: _options.map((opt) {
            return DropdownMenuItem<String>(
              value: opt['value'],
              child: Text(opt['label']),
            );
          }).toList(),
          onChanged: _onSingleChanged,
        ),
      ),
    );
  }

  // 4. RADIO
  Widget _buildRadioGroup() {
    return Column(
      children: _options.map((opt) {
        final label = opt['label'] ?? '';
        final value = opt['value'] ?? '';

        return RadioListTile<String>(
          title: Text(label, style: const TextStyle(fontSize: 14)),
          value: value,
          groupValue: _singleValue,
          activeColor: AppColors.mainBtn,
          contentPadding: EdgeInsets.zero,
          dense: true,
          onChanged: _onSingleChanged,
        );
      }).toList(),
    );
  }
}