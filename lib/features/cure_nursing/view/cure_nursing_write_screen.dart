// lib/features/cure_nursing/view/cure_nursing_write_screen.dart

import 'package:flutter/material.dart';
import 'package:curemate/app/theme/app_colors.dart';
import 'package:curemate/features/widgets/common/custom_text_field.dart';

class CureNursingWriteScreen extends StatefulWidget {
  const CureNursingWriteScreen({super.key});

  @override
  State<CureNursingWriteScreen> createState() => _CureNursingWriteScreenState();
}

class _CureNursingWriteScreenState extends State<CureNursingWriteScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final List<String> _categories = ['바이탈', '식사', '배설', '활동/수면', '기타'];

  String _mealAmount = '전량';
  double _temperature = 36.5;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _categories.length, vsync: this);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,
      appBar: AppBar(
        title: const Text('일지 작성', style: TextStyle(color: AppColors.textMainDark, fontWeight: FontWeight.bold)),
        backgroundColor: AppColors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close, color: AppColors.textMainDark),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
            },
            child: const Text('저장', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.mainBtn)),
          )
        ],
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppColors.mainBtn,
          unselectedLabelColor: AppColors.textSecondaryLight,
          indicatorColor: AppColors.mainBtn,
          isScrollable: true,
          tabs: _categories.map((c) => Tab(text: c)).toList(),
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildVitalForm(),
          _buildMealForm(),
          _buildExcretionForm(),
          _buildActivityForm(),
          _buildEtcForm(),
        ],
      ),
    );
  }

  Widget _buildVitalForm() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          _buildTimePicker(),
          const SizedBox(height: 24),
          _buildSectionTitle("체온 (°C)"),
          Row(
            children: [
              Expanded(
                child: Slider(
                  value: _temperature,
                  min: 35.0,
                  max: 40.0,
                  divisions: 50,
                  activeColor: AppColors.mainBtn,
                  onChanged: (val) => setState(() => _temperature = val),
                ),
              ),
              Text(_temperature.toStringAsFixed(1), style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 24),
          Row(
            children: const [
              Expanded(child: CustomTextField(label: "수축기 혈압", hint: "120", inputType: TextInputType.number)),
              SizedBox(width: 16),
              Expanded(child: CustomTextField(label: "이완기 혈압", hint: "80", inputType: TextInputType.number)),
            ],
          ),
          const SizedBox(height: 24),
          const CustomTextField(label: "맥박 (회/분)", hint: "75", inputType: TextInputType.number),
          const SizedBox(height: 32),
          _buildCommonFields(),
        ],
      ),
    );
  }

  Widget _buildMealForm() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildTimePicker(),
          const SizedBox(height: 24),
          _buildSectionTitle("식사 유형"),
          Wrap(
            spacing: 8,
            children: ['아침', '점심', '저녁', '간식'].map((meal) {
              return ChoiceChip(
                label: Text(meal),
                selected: true,
                selectedColor: AppColors.mainBtn.withValues(alpha: 0.2),
                labelStyle: const TextStyle(color: AppColors.textMainDark),
                onSelected: (bool selected) {},
              );
            }).toList(),
          ),
          const SizedBox(height: 24),
          _buildSectionTitle("섭취량"),
          Container(
            decoration: BoxDecoration(
              color: AppColors.lightBackground,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: ['전량', '1/2', '소량', '금식'].map((amount) {
                final isSelected = _mealAmount == amount;
                return Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() => _mealAmount = amount),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        color: isSelected ? AppColors.mainBtn : Colors.transparent,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        amount,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: isSelected ? Colors.white : AppColors.textSecondaryLight,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 32),
          _buildCommonFields(),
        ],
      ),
    );
  }

  Widget _buildTimePicker() {
    return Row(
      children: [
        const Icon(Icons.access_time, color: AppColors.mainBtn),
        const SizedBox(width: 8),
        const Text("시간", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        const Spacer(),
        TextButton(
          onPressed: () {},
          child: const Text("오전 08:30", style: TextStyle(fontSize: 16, color: AppColors.textMainDark)),
        ),
      ],
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.textSecondaryLight)),
    );
  }

  Widget _buildCommonFields() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const CustomTextField(
          label: "메모",
          hint: "특이사항을 입력해주세요.",
          maxLines: 3,
        ),
        const SizedBox(height: 24),
        _buildSectionTitle("사진 첨부"),
        Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            color: AppColors.lightBackground,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.inputBorder),
          ),
          child: const Icon(Icons.camera_alt, color: AppColors.textSecondaryLight),
        ),
      ],
    );
  }

  Widget _buildExcretionForm() => const Center(child: Text("배설 폼 준비중"));
  Widget _buildActivityForm() => const Center(child: Text("활동 폼 준비중"));
  Widget _buildEtcForm() => const Center(child: Text("기타 폼 준비중"));
}