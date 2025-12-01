import 'package:flutter/material.dart';
import 'package:curemate/app/theme/app_colors.dart';

class CustomRadioGroup<T> extends StatelessWidget {
  final String? label;
  final T groupValue;
  final List<T> values;
  final List<String> itemLabels;
  final ValueChanged<T?> onChanged;
  final bool isRequired;
  final Axis direction;

  const CustomRadioGroup({
    super.key,
    this.label,
    required this.groupValue,
    required this.values,
    required this.itemLabels,
    required this.onChanged,
    this.isRequired = false,
    this.direction = Axis.horizontal,
  }) : assert(values.length == itemLabels.length, 'Values and Labels length must match');

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 1. 라벨 영역
        if (label != null) ...[
          RichText(
            text: TextSpan(
              text: label,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: AppColors.textMainDark,
                fontFamily: 'Pretendard',
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
        ],

        // 2. 라디오 그룹 영역
        RadioGroup<T>(
          groupValue: groupValue,
          onChanged: onChanged,
          child: Wrap(
            direction: direction,
            spacing: 16.0, // 아이템 간 가로 간격
            runSpacing: 8.0, // 아이템 간 세로 간격
            children: List.generate(values.length, (index) {
              return InkWell(
                // 터치 시 값 변경 (라벨 클릭 지원)
                onTap: () {
                  onChanged(values[index]);
                },
                borderRadius: BorderRadius.circular(4), // 터치 효과 둥글게
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Radio<T>(
                      value: values[index],
                      activeColor: AppColors.mainBtn,
                      visualDensity: const VisualDensity(
                        horizontal: VisualDensity.minimumDensity,
                        vertical: VisualDensity.minimumDensity,
                      ),
                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      itemLabels[index],
                      style: const TextStyle(
                        fontSize: 14,
                        color: AppColors.black,
                      ),
                    ),
                    // 터치 영역 확보를 위한 약간의 여백
                    const SizedBox(width: 4),
                  ],
                ),
              );
            }),
          ),
        ),
      ],
    );
  }
}