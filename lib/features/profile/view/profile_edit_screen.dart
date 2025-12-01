import 'dart:io';
import 'package:curemate/features/widgets/common/custom_profile_avatar.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:curemate/app/theme/app_colors.dart';
import 'package:curemate/features/auth/viewmodel/auth_viewmodel.dart';
import 'package:curemate/features/profile/viewmodel/profile_edit_viewmodel.dart';
import 'package:curemate/features/widgets/common/custom_text_field.dart';
import 'package:curemate/features/widgets/common/custom_radio_group.dart';

class ProfileEditScreen extends StatelessWidget {
  const ProfileEditScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => ProfileEditViewModel(),
      child: const _ProfileEditContent(),
    );
  }
}

class _ProfileEditContent extends StatefulWidget {
  const _ProfileEditContent();

  @override
  State<_ProfileEditContent> createState() => _ProfileEditContentState();
}

class _ProfileEditContentState extends State<_ProfileEditContent> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _nameController;
  late TextEditingController _nicknameController;
  late TextEditingController _phoneController;
  late TextEditingController _birthController;

  String _selectedGender = 'male';

  @override
  void initState() {
    super.initState();
    final authVm = context.read<AuthViewModel>();
    final customer = authVm.customer;

    context.read<ProfileEditViewModel>().init(customer);

    _nameController = TextEditingController(text: customer?.custNm ?? '');
    _nicknameController = TextEditingController(text: customer?.custNickname ?? '');
    _phoneController = TextEditingController(text: customer?.custMobile ?? '');
    _birthController = TextEditingController(text: customer?.custBirth ?? '');

    if (customer?.custGender != null) {
      _selectedGender = customer!.custGender!;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _nicknameController.dispose();
    _phoneController.dispose();
    _birthController.dispose();
    super.dispose();
  }

  Future<void> _pickBirthDate() async {
    DateTime initialDate = DateTime.now();
    if (_birthController.text.isNotEmpty) {
      try {
        // YYYY-MM-DD 또는 YYYYMMDD 등 파싱 시도
        String birthText = _birthController.text.replaceAll('-', '');
        if (birthText.length == 8) {
          initialDate = DateTime.parse(
              "${birthText.substring(0,4)}-${birthText.substring(4,6)}-${birthText.substring(6,8)}"
          );
        }
      } catch (_) {}
    }

    final picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppColors.mainBtn,
              onPrimary: AppColors.white,
              onSurface: AppColors.textMainDark,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        _birthController.text = DateFormat('yyyy-MM-dd').format(picked);
      });
    }
  }

  void _onSave() async {
    FocusScope.of(context).unfocus();

    if (_formKey.currentState!.validate()) {
      final success = await context.read<ProfileEditViewModel>().saveProfile(
        name: _nameController.text,
        nickname: _nicknameController.text,
        phone: _phoneController.text,
        birth: _birthController.text,
        gender: _selectedGender,
      );

      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('정보가 수정되었습니다.')),
        );
        
        await context.read<AuthViewModel>().fetchUserInfo();

        Navigator.pop(context);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<ProfileEditViewModel>();
    final authVm = context.watch<AuthViewModel>();

    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        backgroundColor: AppColors.lightBackground,
        appBar: AppBar(
          title: const Text('내 정보 수정', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
          backgroundColor: AppColors.lightBackground,
          elevation: 0,
          iconTheme: const IconThemeData(color: Colors.black),
          actions: [
            TextButton(
              onPressed: viewModel.isUploading ? null : _onSave,
              child: viewModel.isUploading
                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.mainBtn))
                  : const Text('저장', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.mainBtn)),
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
                // 프로필 이미지 영역
                Center(
                  child: Stack(
                    children: [
                      CustomProfileAvatar(
                        imageFile: viewModel.selectedImage, // 1순위: 새로 선택한 파일
                        imageUrl: authVm.profileImgUrl,     // 2순위: 기존 프로필 URL
                        radius: 50, // 지름 100
                        fallbackIcon: Icons.person,
                      ),
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: GestureDetector(
                          onTap: () => viewModel.pickImage(),
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: AppColors.white,
                              shape: BoxShape.circle,
                              border: Border.all(color: AppColors.inputBorder),
                              boxShadow: [
                                BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 4, offset: const Offset(0, 2)),
                              ],
                            ),
                            child: const Icon(Icons.camera_alt, size: 20, color: AppColors.textMainDark),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 32),

                // 1. 이름 (필수)
                CustomTextField(
                  label: '이름',
                  hint: '이름을 입력하세요',
                  controller: _nameController,
                  isRequired: true,
                ),
                const SizedBox(height: 24),

                // 2. 별명 (선택)
                CustomTextField(
                  label: '별명',
                  hint: '별명을 입력하세요',
                  controller: _nicknameController,
                ),
                const SizedBox(height: 24),

                // 3. 휴대폰 번호 (선택, 하이픈 없이 입력 가능)
                CustomTextField(
                  label: '휴대폰 번호',
                  hint: '01012345678 (- 없이 입력 가능)',
                  controller: _phoneController,
                  inputType: TextInputType.phone,
                ),
                const SizedBox(height: 24),

                // 4. 생년월일 (선택)
                CustomTextField(
                  label: '생년월일',
                  hint: 'YYYY-MM-DD',
                  controller: _birthController,
                  readOnly: true,
                  onTap: _pickBirthDate,
                  suffixIcon: Icons.calendar_today,
                ),
                const SizedBox(height: 24),

                // 5. 성별
                CustomRadioGroup<String>(
                  label: '성별',
                  groupValue: _selectedGender,
                  values: const ['male', 'female'],
                  itemLabels: const ['남성', '여성'],
                  onChanged: (value) {
                    if (value != null) {
                      setState(() {
                        _selectedGender = value;
                      });
                    }
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  DecorationImage? _getProfileImage(File? localFile, String? serverUrl) {
    if (localFile != null) {
      return DecorationImage(image: FileImage(localFile), fit: BoxFit.cover);
    }
    if (serverUrl != null && serverUrl.isNotEmpty) {
      return DecorationImage(image: NetworkImage(serverUrl), fit: BoxFit.cover);
    }
    return null;
  }

  Widget _buildGenderRadio(String label, String value) {
    return Row(
      children: [
        Radio<String>(
          value: value,
          groupValue: _selectedGender,
          activeColor: AppColors.mainBtn,
          onChanged: (val) {
            setState(() {
              _selectedGender = val!;
            });
          },
        ),
        Text(label, style: const TextStyle(fontSize: 16, color: AppColors.textMainDark)),
      ],
    );
  }
}