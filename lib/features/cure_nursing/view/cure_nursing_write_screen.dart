import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:curemate/app/theme/app_colors.dart';
import 'package:curemate/features/cure_nursing/model/nursing_model.dart';
import 'package:curemate/features/cure_nursing/viewmodel/cure_nursing_viewmodel.dart';
// SDUI 관련 임포트
import 'package:curemate/common/sdui/view/sdui_renderer.dart';

class CureNursingWriteScreen extends StatelessWidget {
  const CureNursingWriteScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      // 화면 진입 시 카테고리 목록(Step 1용) 조회
      create: (_) => CureNursingViewModel()..fetchCategories(),
      child: const _CureNursingWriteContent(),
    );
  }
}

class _CureNursingWriteContent extends StatefulWidget {
  const _CureNursingWriteContent();

  @override
  State<_CureNursingWriteContent> createState() => _CureNursingWriteContentState();
}

class _CureNursingWriteContentState extends State<_CureNursingWriteContent> {
  int _currentStep = 0; // 0: 분류 선택, 1: 상세 입력

  NursingCategoryModel? _selectedMainCategory;
  NursingCategoryModel? _selectedSubCategory;
  DateTime _selectedTime = DateTime.now();

  // --- 이벤트 핸들러 ---

  void _onMainCategorySelected(NursingCategoryModel category) {
    setState(() {
      _selectedMainCategory = category;
    });
  }

  // ✅ 중분류 선택 시 -> SDUI 폼 데이터 로드
  Future<void> _onSubCategorySelected(BuildContext context, NursingCategoryModel subCategory) async {
    final viewModel = context.read<CureNursingViewModel>();

    setState(() {
      _selectedSubCategory = subCategory;
      _currentStep = 1; // Step 2로 이동
    });

    // 🚀 선택된 카테고리 코드(예: 'BP')로 서버에 폼 구성 요청
    await viewModel.loadSduiForm(subCategory.categoryCd);
  }

  void _handleBack() {
    if (_currentStep == 1) {
      // Step 2 -> Step 1 복귀 시 초기화
      setState(() {
        _currentStep = 0;
        _selectedSubCategory = null;
      });
      context.read<CureNursingViewModel>().clearSduiData();
    } else {
      Navigator.pop(context);
    }
  }

  Future<void> _pickTime() async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_selectedTime),
    );
    if (picked != null) {
      setState(() {
        final now = DateTime.now();
        _selectedTime = DateTime(now.year, now.month, now.day, picked.hour, picked.minute);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<CureNursingViewModel>();

    return PopScope(
      canPop: _currentStep == 0,
      onPopInvoked: (didPop) {
        if (!didPop) _handleBack();
      },
      child: Scaffold(
        backgroundColor: AppColors.lightBackground,
        appBar: _buildAppBar(),
        body: SafeArea(
          child: Column(
            children: [
              Expanded(
                // ✅ Step에 따라 화면 전환
                child: _currentStep == 0
                    ? _buildStep1CategorySelection(viewModel)
                    : _buildStep2SduiForm(viewModel),
              ),
              // 저장 버튼은 Step 2에서만 노출
              if (_currentStep == 1) _buildSaveButton(viewModel),
            ],
          ),
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      title: Text(
        _currentStep == 0
            ? '기록 분류 선택'
            : '${_selectedMainCategory?.categoryNm} > ${_selectedSubCategory?.categoryNm}',
        style: const TextStyle(color: AppColors.textMainDark, fontWeight: FontWeight.bold, fontSize: 18),
      ),
      backgroundColor: AppColors.white,
      elevation: 0,
      centerTitle: false,
      leading: IconButton(
        icon: Icon(_currentStep == 0 ? Icons.close : Icons.arrow_back_ios_new, color: AppColors.textMainDark),
        onPressed: _handleBack,
      ),
    );
  }

  // -----------------------------------------------------------------------
  // [Step 1] 분류 선택 화면 (기존 로직 유지)
  // -----------------------------------------------------------------------
  Widget _buildStep1CategorySelection(CureNursingViewModel viewModel) {
    if (viewModel.isLoadingCategories) {
      return const Center(child: CircularProgressIndicator());
    }

    // 1. 선택된 대분류가 없으면 첫 번째 것으로 초기화
    if (_selectedMainCategory == null && viewModel.categories.isNotEmpty) {
      _selectedMainCategory = viewModel.categories.first;
    }

    if (viewModel.categories.isEmpty) {
      return const Center(child: Text("카테고리 정보가 없습니다."));
    }

    final mainCategories = viewModel.categories;
    final subCategories = _selectedMainCategory?.children ?? [];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 대분류 선택 영역
        Container(
          width: double.infinity,
          color: AppColors.white,
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text("대분류", style: TextStyle(fontSize: 14, color: AppColors.textSecondaryLight, fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8.0,
                runSpacing: 8.0,
                children: mainCategories.map((category) {
                  final isSelected = _selectedMainCategory?.categoryCd == category.categoryCd;
                  return ChoiceChip(
                    label: Text(category.categoryNm),
                    selected: isSelected,
                    onSelected: (_) => _onMainCategorySelected(category),
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
              ),
            ],
          ),
        ),
        const Divider(height: 1, color: AppColors.inputBorder),
        // 중분류 선택 (그리드)
        Expanded(
          child: Container(
            color: AppColors.lightBackground,
            padding: const EdgeInsets.all(20),
            child: GridView.builder(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 1.5,
              ),
              itemCount: subCategories.length,
              itemBuilder: (context, index) {
                return _buildSubCategoryCard(context, subCategories[index], viewModel);
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSubCategoryCard(BuildContext context, NursingCategoryModel sub, CureNursingViewModel viewModel) {
    return InkWell(
      onTap: () => _onSubCategorySelected(context, sub),
      borderRadius: BorderRadius.circular(16),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [BoxShadow(color: AppColors.shadow, blurRadius: 4, offset: const Offset(0, 2))],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(viewModel.getIconForName(sub.iconNm), size: 32, color: AppColors.mainBtn),
            const SizedBox(height: 12),
            Text(sub.categoryNm, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.textMainDark)),
          ],
        ),
      ),
    );
  }

  // -----------------------------------------------------------------------
  // [Step 2] 상세 입력 화면 (🔥 SDUI 적용)
  // -----------------------------------------------------------------------
  Widget _buildStep2SduiForm(CureNursingViewModel viewModel) {
    if (viewModel.isLoadingForm) {
      return const Center(child: CircularProgressIndicator());
    }

    if (viewModel.sduiRootNode == null) {
      return const Center(child: Text("입력 양식을 불러올 수 없습니다."));
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 시간 선택 (공통 요소)
          _buildTimeInput(),
          const SizedBox(height: 24),

          // SDUI Renderer: 서버에서 받은 노드 트리를 그립니다.
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.inputBorder),
            ),
            // SDUI 렌더러 호출
            child: SduiRenderer(
                node: viewModel.sduiRootNode!,
                controller: viewModel.sduiController
            ),
          ),

          const SizedBox(height: 24),
          // 메모 등 공통 필드...
        ],
      ),
    );
  }

  Widget _buildTimeInput() {
    return GestureDetector(
      onTap: _pickTime,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: AppColors.white,
          border: Border.all(color: AppColors.inputBorder),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                DateFormat('HH:mm').format(_selectedTime),
                style: const TextStyle(fontSize: 14, color: AppColors.textMainDark),
              ),
            ),
            const Icon(Icons.access_time, color: AppColors.textSecondaryLight),
          ],
        ),
      ),
    );
  }

  Widget _buildSaveButton(CureNursingViewModel viewModel) {
    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: const BoxDecoration(
        color: AppColors.white,
        border: Border(top: BorderSide(color: AppColors.inputBorder)),
      ),
      child: SizedBox(
        width: double.infinity,
        height: 52,
        child: ElevatedButton(
          onPressed: () {
            // 저장 로직: SduiController의 데이터를 가져와서 저장
            viewModel.saveLog().then((_) {
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('저장되었습니다.')));
              Navigator.pop(context);
            });
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.mainBtn,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            elevation: 0,
          ),
          child: const Text('저장하기', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.white)),
        ),
      ),
    );
  }
}