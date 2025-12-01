import 'package:curemate/app/theme/app_colors.dart';
import 'package:curemate/features/patient/view/medical_history_screen.dart';
import 'package:curemate/features/patient/view/medication_list_screen.dart';
import 'package:curemate/features/patient/view/patient_profile_screen.dart';
import 'package:curemate/features/patient/viewmodel/patient_viewmodel.dart';
import 'package:curemate/features/recording/view/recording_list.dart';
import 'package:curemate/features/widgets/common/bottom_nav_provider.dart';
import 'package:curemate/features/widgets/common/header_provider.dart';
import 'package:curemate/features/widgets/common/widgets.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class MainPage extends StatefulWidget {
  const MainPage({super.key});

  @override
  State<MainPage> createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final header = Provider.of<HeaderProvider>(context, listen: false);
      header.setTitle('Cure Mate');
      header.setShowBackButton(false);

      final nav = Provider.of<BottomNavProvider>(context, listen: false);
      nav.changeIndex(0);

      final patientId = nav.cureSeq;
      if (patientId != null) {
        Provider.of<PatientViewModel>(context, listen: false)
            .fetchPatientById(patientId);
      }
    });
  }

  final List<Map<String, dynamic>> scheduleItems = [
    {'title': '약: 아스피린', 'time': '오전 8:00', 'isDone': false},
    {'title': '약: 이부프로펜', 'time': '오전 10:00', 'isDone': true},
    {'title': '검진 예약', 'time': '오후 2:00', 'isDone': false},
    {'title': '약: 비타민D', 'time': '오후 5:00', 'isDone': false},
    {'title': '운동: 가벼운 스트레칭', 'time': '오후 8:00', 'isDone': true},
  ];

  bool _showAllSchedules = false;

  @override
  Widget build(BuildContext context) {
    final nav = Provider.of<BottomNavProvider>(context);
    final patientId = nav.cureSeq;

    return Container(
        color: AppColors.white, // Container에 색상 적용
        child: SafeArea(
          top: true, // top에 SafeArea 적용
          child: Scaffold(
            body: Column(
              children: [
                const PatientScreenHeader(isMainPage: true),
                Expanded(
                  child: Consumer<PatientViewModel>(
                    builder: (context, vm, child) {
                      if (vm.isLoading) {
                        return const Center(child: CircularProgressIndicator());
                      }

                      if (vm.errorMessage != null) {
                        return Center(child: Text('오류: ${vm.errorMessage}'));
                      }

                      if (patientId == null || vm.selectedPatient == null) {
                        return const Center(child: Text("환자 정보를 불러올 수 없습니다."));
                      }

                      final patient = vm.selectedPatient!;

                      return SingleChildScrollView(
                        child: Column(
                          children: [
                            _buildPatientInfoCard(patient),
                            _buildScheduleSection(),
                            _buildQuickActionButtons(),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          bottomNavigationBar: const PatientScreenBottomNavBar(),
        ),
      )
    );
  }

  /// 🔹 환자 정보 카드 (원조 디자인)
  Widget _buildPatientInfoCard(Map<String, dynamic> patient) {
    final name = patient['name'] ?? '이름 없음';
    final age = patient['age']?.toString() ?? '';
    final gender = patient['gender'] ?? '';
    final allergy = patient['allergy'] ?? '';
    final profileImgUrl = patient['profileImgUrl'];

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
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '환자 정보',
                  style: TextStyle(fontSize: 14, color: AppColors.darkBlue),
                ),
                const SizedBox(height: 4),
                Text(
                  name,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: AppColors.black,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  "$age, $gender${allergy.isNotEmpty ? ', $allergy' : ''}",
                  style: const TextStyle(fontSize: 14, color: AppColors.darkBlue),
                ),
                const SizedBox(height: 16),
                Align(
                  alignment: Alignment.centerLeft,
                  child: ElevatedButton(
                    onPressed: () {
                      final nav =
                          Provider.of<BottomNavProvider>(context, listen: false);
                      nav.changeIndex(-1);

                      Navigator.push(
                        context,
                        PageRouteBuilder(
                          transitionDuration: Duration.zero,
                          pageBuilder: (context, animation, secondaryAnimation) =>
                              PatientProfileScreen(patient: patient,),
                          transitionsBuilder:
                              (context, animation, secondaryAnimation, child) {
                            return child;
                          },
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.mainBtn,
                      foregroundColor: AppColors.white,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 15, vertical: 18),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    child: const Text(
                      '프로필 보기',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          // ✅ 프로필 이미지를 동그라미 고정 크기로
          SizedBox(
            width: 80,
            height: 80,
            child: ClipOval(
              child: profileImgUrl != null && profileImgUrl.isNotEmpty
                  ? Image.network(
                      profileImgUrl,
                      fit: BoxFit.cover,
                    )
                  : Container(
                      color: AppColors.lightGrey,
                      child: const Icon(Icons.person, size: 40),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  /// 🔹 일정 섹션
  Widget _buildScheduleSection() {
    final itemsToShow =
        _showAllSchedules ? scheduleItems : scheduleItems.take(3).toList();

    return Container(
      margin: const EdgeInsets.all(16),
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
            '오늘의 일정',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.black,
            ),
          ),
          const SizedBox(height: 8),
          ...itemsToShow.asMap().entries.map((entry) {
            int index = entry.key;
            var item = entry.value;
            return _buildScheduleItem(
              item['title'] as String,
              item['time'] as String,
              item['isDone'] as bool,
              (bool newValue) {
                setState(() {
                  scheduleItems[index]['isDone'] = newValue;
                });
              },
            );
          }).toList(),
          const SizedBox(height: 8),
          Center(
            child: TextButton(
              onPressed: () {
                setState(() {
                  _showAllSchedules = !_showAllSchedules;
                });
              },
              child: Text(
                _showAllSchedules ? '접기' : '펼쳐보기',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: AppColors.darkBlue,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildScheduleItem(
      String title, String time, bool isDone, ValueChanged<bool> onToggle) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: AppColors.white,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.lightGrey),
                ),
                child: Icon(
                  title.contains('약') ? Icons.calendar_month : Icons.event_note,
                  color: AppColors.iconColor,
                ),
              ),
              const SizedBox(width: 16),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: AppColors.black,
                    ),
                  ),
                  Text(
                    time,
                    style: const TextStyle(
                        fontSize: 14, color: AppColors.darkBlue),
                  ),
                ],
              ),
            ],
          ),
          Switch(
            value: isDone,
            onChanged: onToggle,
            activeColor: AppColors.activeColor,
            inactiveThumbColor: AppColors.white,
            inactiveTrackColor: AppColors.lightGrey,
          ),
        ],
      ),
    );
  }

  /// 🔹 빠른 실행 버튼
  Widget _buildQuickActionButtons() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildQuickActionButton(Icons.medical_services, '진료 목록', () {
            Navigator.push(
              context,
              PageRouteBuilder(
                transitionDuration: Duration.zero,
                pageBuilder: (context, animation, secondaryAnimation) =>
                    const RecordingListScreen(),
                transitionsBuilder:
                    (context, animation, secondaryAnimation, child) {
                  return child;
                },
              ),
            );
          }, iconColor: AppColors.pinkIconColor),
          _buildQuickActionButton(Icons.access_time_filled, '약 복용', () {
            Navigator.push(
              context,
              PageRouteBuilder(
                transitionDuration: Duration.zero,
                pageBuilder: (context, animation, secondaryAnimation) =>
                    const MedicationManagementPage(),
                transitionsBuilder:
                    (context, animation, secondaryAnimation, child) {
                  return child;
                },
              ),
            );
          }, iconColor: AppColors.yellowIconColor),
          _buildQuickActionButton(Icons.assignment, '병력 관리', () {
            Navigator.push(
              context,
              PageRouteBuilder(
                transitionDuration: Duration.zero,
                pageBuilder: (context, animation, secondaryAnimation) =>
                    const MedicalHistoryScreen(),
                transitionsBuilder:
                    (context, animation, secondaryAnimation, child) {
                  return child;
                },
              ),
            );
          }, iconColor: AppColors.greenIconColor),
        ],
      ),
    );
  }

  Widget _buildQuickActionButton(
    IconData icon,
    String text,
    VoidCallback onPressed, {
    Color iconColor = const Color.fromARGB(255, 136, 126, 201),
  }) {
    return Expanded(
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 4),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.lightGrey),
            boxShadow: [
              BoxShadow(
                color: AppColors.grey.withOpacity(0.1),
                spreadRadius: 1,
                blurRadius: 3,
                offset: const Offset(0, 1),
              ),
            ],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 32, color: iconColor),
              const SizedBox(height: 8),
              Text(
                text,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: AppColors.black,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
