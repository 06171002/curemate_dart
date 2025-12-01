import 'package:curemate/features/widgets/common/bottom_nav_provider.dart';
import 'package:curemate/features/widgets/common/custom_profile_avatar.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:curemate/app/theme/app_colors.dart';
import 'package:curemate/features/auth/viewmodel/auth_viewmodel.dart';
import 'package:curemate/features/cure_room/viewmodel/add_cure_room_viewmodel.dart';
import 'package:curemate/features/widgets/common/custom_text_field.dart';

class AddCureRoomScreen extends StatelessWidget {
  const AddCureRoomScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => AddCureRoomViewModel(),
      child: const _AddCureRoomContent(),
    );
  }
}

class _AddCureRoomContent extends StatefulWidget {
  const _AddCureRoomContent();

  @override
  State<_AddCureRoomContent> createState() => _AddCureRoomContentState();
}

class _AddCureRoomContentState extends State<_AddCureRoomContent> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _descController = TextEditingController();
  bool _isPublic = false;

  @override
  void dispose() {
    _nameController.dispose();
    _descController.dispose();
    super.dispose();
  }

  void _onSave() async {
    FocusScope.of(context).unfocus();

    if (!_formKey.currentState!.validate()) return;

    final viewModel = context.read<AddCureRoomViewModel>();
    final authViewModel = context.read<AuthViewModel>();
    final custSeq = authViewModel.custSeq;

    if (custSeq == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("사용자 정보를 찾을 수 없습니다.")),
      );
      return;
    }

    final newCurer = await viewModel.createCureRoom(
      userCustSeq: custSeq,
      name: _nameController.text,
      description: _descController.text,
      isPublic: _isPublic,
    );

    if (newCurer != null && mounted) {
      //  생성된 큐어룸을 선택 상태로 설정 (모드 변경)
      context.read<BottomNavProvider>().selectCurer(newCurer);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("${newCurer.cureNm} 큐어룸이 생성되었습니다.")),
      );

      Navigator.pop(context);

    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("생성 실패: ${viewModel.errorMessage}")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<AddCureRoomViewModel>();

    return Scaffold(
      backgroundColor: AppColors.lightBackground,
      appBar: AppBar(
        title: const Text(
          '큐어룸 만들기',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        backgroundColor: AppColors.lightBackground,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
        actions: [
          TextButton(
            onPressed: viewModel.isUploading ? null : _onSave,
            child: viewModel.isUploading
                ? const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                  strokeWidth: 2, color: AppColors.mainBtn),
            )
                : const Text(
              '저장',
              style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppColors.mainBtn),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. 큐어룸 대표 이미지
              Center(
                child: Stack(
                  children: [
                    CustomProfileAvatar(
                      imageFile: viewModel.selectedImage, // 뷰모델의 선택된 파일 전달
                      radius: 50, // 지름 100을 위해 반지름 50 설정
                      fallbackIcon: Icons.healing, // 큐어룸 아이콘
                    ),
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: GestureDetector(
                        onTap: viewModel.isUploading ? null : viewModel.pickImage,
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: AppColors.white,
                            shape: BoxShape.circle,
                            border: Border.all(color: AppColors.inputBorder),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.1),
                                blurRadius: 4,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: const Icon(Icons.camera_alt,
                              size: 20, color: AppColors.textMainDark),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),

              // 2. 큐어룸 이름 (필수 표시 적용)
              CustomTextField(
                label: '큐어룸 이름',
                hint: '예) 우리 가족 건강방',
                controller: _nameController,
                isRequired: true,
              ),
              const SizedBox(height: 24),

              // 3. 소개글
              CustomTextField(
                label: '소개글',
                hint: '큐어룸에 대한 간단한 소개를 적어주세요.\n#태그 #환영합니다',
                controller: _descController,
                maxLines: 3,
              ),
              const SizedBox(height: 24),

              // 4. 공개 여부
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
                      Text('공개 설정',
                          style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textMainDark)),
                      SizedBox(height: 4),
                      Text('검색 결과에 큐어룸을 노출합니다.',
                          style: TextStyle(
                              fontSize: 12, color: AppColors.textSecondaryLight)),
                    ],
                  ),
                  Switch(
                    value: _isPublic,
                    activeThumbColor: AppColors.mainBtn,
                    onChanged: (value) {
                      setState(() {
                        _isPublic = value;
                      });
                    },
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}