import 'package:curemate/app/theme/app_colors.dart';
import 'package:curemate/features/widgets/common/header_provider.dart';
import 'package:flutter/material.dart';
import 'package:curemate/features/widgets/common/widgets.dart';
import 'package:provider/provider.dart';

class PatientProfileScreen extends StatefulWidget {
  final Map<String, dynamic> patient; // 🔹 단일 환자 데이터

  const PatientProfileScreen({
    super.key,
    required this.patient,
  });

  @override
  State<PatientProfileScreen> createState() => _PatientProfileScreenState();
}

class _PatientProfileScreenState extends State<PatientProfileScreen> {
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final header = Provider.of<HeaderProvider>(context, listen: false);
    header.setTitle('환자 프로필');
    header.setShowBackButton(true);
  }

  @override
  Widget build(BuildContext context) {
    final patient = widget.patient;

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            const PatientScreenHeader(),

            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _buildProfileCard(patient),
                    _buildInfoSection(patient),
                    _buildMemoSection(
                      label: '알러지',
                      value: patient['allergies'] ?? '없음',
                    ),
                    _buildMemoSection(
                      label: '메모',
                      value: patient['memo'] ?? '메모가 없습니다.',
                    ),
                  ],
                ),
              ),
            ),

            const PatientScreenBottomNavBar(),
          ],
        ),
      ),
    );
  }

  /// 🔹 프로필 카드
  Widget _buildProfileCard(Map<String, dynamic> patient) {
    final profileImgUrl = patient['profileImgUrl'] ?? '';
    final name = patient['name'] ?? '이름 없음';
    final relationship = patient['relationship'] ?? '미등록';

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
        // 🔹 프로필 이미지
        CircleAvatar(
          radius: 48,
          backgroundImage: (profileImgUrl.isNotEmpty)
              ? NetworkImage(profileImgUrl)
              : null,
          backgroundColor: profileImgUrl.isEmpty
              ? AppColors.lightGrey
              : Colors.transparent,
          child: profileImgUrl.isEmpty
              ? const Icon(Icons.person, size: 48, color: Colors.grey)
              : null,
        ),
          const SizedBox(height: 16),
          Text(
            name,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: AppColors.blueTextSecondary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            relationship,
            style: const TextStyle(fontSize: 16, color: AppColors.skyBlue),
          ),
        ],
      ),
    );
  }

  /// 🔹 상세 정보 섹션
  Widget _buildInfoSection(Map<String, dynamic> patient) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: GridView.count(
        crossAxisCount: 2,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        childAspectRatio: 2.5,
        children: [
          _buildInfoGridItem(
            label: '긴급 연락처',
            value: patient['emergency_contact'] ?? '없음',
          ),
          _buildInfoGridItem(
            label: '생년월일',
            value: patient['birth'] ?? '미등록',
          ),
          _buildInfoGridItem(
            label: '성별',
            value: patient['gender'] ?? '미등록',
          ),
          _buildInfoGridItem(
            label: '신장',
            value: patient['height'] != null ? '${patient['height']} cm' : '미등록',
          ),
          _buildInfoGridItem(
            label: '체중',
            value: patient['weight'] != null ? '${patient['weight']} kg' : '미등록',
          ),
          _buildInfoGridItem(
            label: '혈액형',
            value: patient['blood_type'] ?? '미등록',
          ),
          _buildInfoGridItem(
            label: '음주',
            value: (patient['drinking_yn'] == true || patient['drinking_yn'] == 'Y')
                ? '예'
                : '아니요',
          ),
          _buildInfoGridItem(
            label: '흡연',
            value: (patient['smoking_yn'] == true || patient['smoking_yn'] == 'Y')
                ? '예'
                : '아니요',
          ),
        ],
      ),
    );
  }

  Widget _buildInfoGridItem({required String label, required String value}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 14, color: AppColors.skyBlue)),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
            color: AppColors.blueTextSecondary,
          ),
        ),
      ],
    );
  }

  /// 🔹 메모/알러지 섹션
  Widget _buildMemoSection({required String label, required String value}) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontSize: 14, color: AppColors.skyBlue)),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: AppColors.blueTextSecondary,
            ),
          ),
        ],
      ),
    );
  }
}
