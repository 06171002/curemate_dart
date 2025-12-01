// ignore_for_file: prefer_const_constructors, prefer_const_literals_to_create_immutables

import 'package:curemate/app/theme/app_colors.dart';
import 'package:curemate/features/cure_room/model/cure_room_models.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:curemate/routes/route_paths.dart';
import 'package:curemate/services/cure_room_service.dart';
import 'package:curemate/features/cure_room/view/update_patient_screen.dart';
import 'dart:io'; 

// 🔹 수정 화면 import
import 'package:curemate/features/cure_room/view/update_patient_screen.dart';

class PatientProfileScreen extends StatefulWidget {
  final CurePatientModel patient;
  final String? profileImgUrl; // 필요하면 홈에서 extra로 덮어쓰기용

  const PatientProfileScreen({
    super.key,
    required this.patient,
    this.profileImgUrl,
  });

  @override
  State<PatientProfileScreen> createState() => _PatientProfileScreenState();
}

class _PatientProfileScreenState extends State<PatientProfileScreen> {
  final CureRoomService _service = CureRoomService();

  // 🔹 추가: 화면에서 쓸 환자 상태
  CurePatientModel? _patient;
  bool _isLoading = false;

  bool _updated = false; // ✅ 수정 여부 플래그 추가
  File? _localProfileImage;

 @override
  void initState() {
    super.initState();
    // 처음엔 라우터에서 넘어온 값으로 세팅
    _patient = widget.patient;
  }

  // 생일을 수정 화면용 "yyyy-MM-dd"로 포맷
  String? _formatBirthdayForEdit(String? yyyymmdd) {
    if (yyyymmdd == null || yyyymmdd.length != 8) return null;
    return '${yyyymmdd.substring(0, 4)}-'
           '${yyyymmdd.substring(4, 6)}-'
           '${yyyymmdd.substring(6, 8)}';
  } 

  @override
  Widget build(BuildContext context) {
    // 🔹 항상 state에 있는 환자 기준으로 그림
    final patient = _patient ?? widget.patient;
    // 🔹 새로 조회된 _patient의 profileImgUrl를 최우선으로 사용
final profileImgUrl = patient.profileImgUrl ?? widget.profileImgUrl;

    return Container(
      color: AppColors.lightBackground,
      child: SafeArea(
        child: DefaultTextStyle(
          // 이 화면 전체의 기본 텍스트 스타일
          style: const TextStyle(
            fontSize: 14,
            color: AppColors.blueTextSecondary,
          ),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                /// 🔹 상단 뒤로가기 + 제목
                Padding(
                  padding: const EdgeInsets.fromLTRB(8, 12, 16, 0),
                  child: SizedBox(
                    height: 40,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        // 왼쪽 뒤로가기 버튼
                        Align(
                          alignment: Alignment.centerLeft,
                          child: IconButton(
                            icon: const Icon(
                              Icons.arrow_back_ios_new,
                              size: 20,
                              color: Colors.black, // 메인색 위라 흰색이 잘 보임
                            ),
                            onPressed: () {
                               context.pop(_updated);
                            },
                          ),
                        ),

                        // 가운데 제목
                        const Center(
                          child: Text(
                            '환자 프로필',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Colors.black,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                /// 🔹 프로필 카드
                _buildProfileCard(patient, profileImgUrl),

                /// 🔹 기본 정보 카드
                _buildBasicInfoCard(patient, profileImgUrl),

                /// 🔹 병력 카드
                _buildHistoryCard(patient),

                /// 🔹 복용 약 카드
                _buildMedicationCard(patient),

                const SizedBox(height: 16),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // 🔸 생년월일을 폼용 "yyyy-MM-dd"로 변환
  String? _formatBirthdayForForm(String? yyyymmdd) {
    if (yyyymmdd == null || yyyymmdd.isEmpty) return null;

    // 혹시 중간에 - 가 들어있어도 숫자만 추출
    final digits = yyyymmdd.replaceAll(RegExp(r'[^0-9]'), '');
    if (digits.length != 8) return null;

    return '${digits.substring(0, 4)}-'
        '${digits.substring(4, 6)}-'
        '${digits.substring(6, 8)}';
  }

  // ======================================================
  // 🔹 프로필 카드
  // ======================================================
    Widget _buildProfileCard(CurePatientModel patient, String? profileImgUrl) {
    final name = patient.patientNm;
    final heroTag = 'patientProfile_${patient.curePatientSeq}';

    // 👇 우선순위: 로컬 파일 > 서버 URL
    ImageProvider? imageProvider;
    if (_localProfileImage != null) {
      imageProvider = FileImage(_localProfileImage!);
    } else if (profileImgUrl != null && profileImgUrl.isNotEmpty) {
      imageProvider = NetworkImage(profileImgUrl);
    }

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppColors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 5,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        children: [
          GestureDetector(
            onTap: () {
              // 전체 화면 확대는 일단 서버 URL 기준으로 (원래대로)
              if (profileImgUrl == null || profileImgUrl.isEmpty) return;

              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => _FullScreenProfileImage(
                    imageUrl: profileImgUrl,
                    heroTag: heroTag,
                  ),
                ),
              );
            },
            child: Hero(
              tag: heroTag,
              child: CircleAvatar(
                radius: 48,
                backgroundImage: imageProvider,
                backgroundColor: imageProvider == null
                    ? AppColors.lightGrey
                    : Colors.transparent,
                child: imageProvider == null
                    ? const Icon(Icons.person, size: 48, color: Colors.grey)
                    : null,
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            name.isNotEmpty ? name : '이름 없음',
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: AppColors.blueTextSecondary,
            ),
          ),
        ],
      ),
    );
  }

  // ======================================================
  // 🔹 기본 정보 카드
  // ======================================================
  Widget _buildBasicInfoCard(CurePatientModel patient, String? profileImgUrl) {
    final ageText = _buildAgeText(patient.patientBirthday);
    final gender = _genderLabel(patient.patientGenderCmcd);
    final bloodType = patient.patientBloodTypeCmcd ?? '미등록';
    final height = patient.patientHeight?.toString() ?? '-';
    final weight = patient.patientWeight?.toString() ?? '-';

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppColors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 5,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '기본 정보',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: AppColors.blueTextSecondary,
            ),
          ),
          const SizedBox(height: 12),

          _buildInfoRow('나이', ageText),
          _buildInfoRow('성별', gender),
          _buildInfoRow('혈액형', bloodType),
          _buildInfoRow('신장', height == '-' ? '-' : '$height cm'),
          _buildInfoRow('체중', weight == '-' ? '-' : '$weight kg'),

          const SizedBox(height: 16),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4.0),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () async {
                  try {
                    // 🔹 1) 단건 조회 (수정 폼 초기값용)
                    final curePatient = await _service.getCurePatient(
                      patient.curePatientSeq,
                    );

                    if (!mounted) return;

                    // 🔹 2) 수정 화면으로 이동 + 결과 기다리기 (bool 말고 dynamic/Map 받기)
                    final result = await Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => UpdatePatientScreen(
                          patientSeq: curePatient.curePatientSeq,
                          initialName: curePatient.patientNm,
                          initialBirthday:
                              _formatBirthdayForForm(curePatient.patientBirthday),
                          initialGender: curePatient.patientGenderCmcd ?? 'man',
                          initialBloodType: curePatient.patientBloodTypeCmcd,
                          initialWeight: curePatient.patientWeight,
                          initialHeight: curePatient.patientHeight,
                          initialImageFile: null,
                          initialImageUrl: profileImgUrl ?? curePatient.profileImgUrl,
                        ),
                      ),
                    );

                    // 🔹 3) 수정 화면에서 Map({ updated: true, localImageFile })로 넘어온 경우만 처리
                    if (result is Map && result['updated'] == true) {
                      // 수정 후 최신 데이터 다시 조회
                      final refreshed = await _service.getCurePatient(
                        patient.curePatientSeq,
                      );

                      if (!mounted) return;

                      setState(() {
                        _patient = refreshed;
                        _updated = true;

                        final file = result['localImageFile'];
                        if (file is File) {
                          _localProfileImage = file; // 👈 로컬 파일 캐시
                        }
                      });
                    }
                  } catch (e) {
                    if (!mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('환자 정보를 불러오지 못했어요.\n$e'),
                      ),
                    );
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Color(0xFFA0C4FF),
                  foregroundColor: AppColors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                  elevation: 0,
                ),
                child: const Text(
                  '정보 수정',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// 🔸 라벨 + 값 한 줄
  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        children: [
          SizedBox(
            width: 70,
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 14,
                color: AppColors.skyBlue,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: AppColors.blueTextSecondary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// 🔸 나이 텍스트 (yyyyMMdd → 한국식 나이)
  String _buildAgeText(String? yyyymmdd) {
    if (yyyymmdd == null || yyyymmdd.length < 4) {
      return '미등록';
    }

    final year = int.tryParse(yyyymmdd.substring(0, 4));
    if (year == null) return '미등록';

    final now = DateTime.now();
    final age = now.year - year + 1; // 한국식 +1
    return '$age세';
  }

  /// 🔸 성별 코드 → 한글
  String _genderLabel(String? code) {
    switch (code) {
      case 'female':
      case 'F':
      case 'woman':
        return '여성';
      case 'male':
      case 'M':
      case 'man':
        return '남성';
      default:
        return '미등록';
    }
  }

  // ======================================================
  // 🔹 병력 카드
  // ======================================================
  Widget _buildHistoryCard(CurePatientModel patient) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppColors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 5,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text(
            '병력',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: AppColors.blueTextSecondary,
            ),
          ),
          TextButton(
            onPressed: () {
              context.push(
                RoutePaths.cureRoomMedicalHistory,
                extra: {
                  'patient': patient,
                },
              );
            },
            style: TextButton.styleFrom(
              padding: EdgeInsets.zero,
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            child: const Text(
              '관리 >',
              style: TextStyle(
                fontSize: 14,
                color: AppColors.skyBlue,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ======================================================
  // 🔹 복용 약 카드
  // ======================================================
  Widget _buildMedicationCard(CurePatientModel patient) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppColors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 5,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text(
            '복용 약',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: AppColors.blueTextSecondary,
            ),
          ),
          TextButton(
            onPressed: () async {
              try {
                // 🔸 1) 여기서 API 한 번 조회
                final List<CureMedicineGroupModel> groups =
                    await _service.getPatientMedicineList(
                  patient.curePatientSeq,
                );

                if (!mounted) return;

                // 🔸 2) 조회한 결과를 extra로 넘기면서 화면 이동
                context.push(
                  RoutePaths.cureRoomMedications,
                  extra: {
                    'curePatientSeq': patient.curePatientSeq,
                    'medicineGroups': groups,
                  },
                );
              } catch (e) {
                if (!mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('약 정보를 불러오지 못했어요.\n$e'),
                  ),
                );
              }
            },
            style: TextButton.styleFrom(
              padding: EdgeInsets.zero,
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            child: const Text(
              '관리 >',
              style: TextStyle(
                fontSize: 14,
                color: AppColors.skyBlue,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _FullScreenProfileImage extends StatelessWidget {
  final String imageUrl;
  final String heroTag;

  const _FullScreenProfileImage({
    Key? key,
    required this.imageUrl,
    required this.heroTag,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final double size = MediaQuery.of(context).size.width; // 화면 너비 = 정사각형 한 변

    return GestureDetector(
      // 바탕 아무데나 탭해도 닫히게
      onTap: () => Navigator.of(context).pop(),
      child: Scaffold(
        backgroundColor: Colors.black,
        body: SafeArea(
          child: Stack(
            children: [
              // 가운데 정사각형 프로필 (카톡 같은 느낌)
              Center(
                child: Hero(
                  tag: heroTag,
                  child: InteractiveViewer(
                    minScale: 1.0,
                    maxScale: 4.0,
                    child: SizedBox(
                      width: size,
                      height: size, // ✅ 정사각형 고정
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(0),
                        child: Image.network(
                          imageUrl,
                          fit: BoxFit.cover, // ✅ 가운데 기준으로 꽉 채우고 잘라내기
                        ),
                      ),
                    ),
                  ),
                ),
              ),

              // 왼쪽 위 닫기 아이콘
              Positioned(
                top: 8,
                left: 8,
                child: IconButton(
                  icon: const Icon(
                    Icons.close,
                    color: Colors.white,
                    size: 24,
                  ),
                  onPressed: () {
               Navigator.of(context).pop(); // 또는 context.pop();
              },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
