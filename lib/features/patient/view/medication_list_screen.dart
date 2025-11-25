import 'package:curemate/app/theme/app_colors.dart';
import 'package:curemate/features/widgets/common/bottom_nav_provider.dart';
import 'package:curemate/features/widgets/common/header_provider.dart';
import 'package:curemate/features/widgets/common/widgets.dart'; // 이 파일에 PatientScreenHeader와 PatientScreenBottomNavBar가 정의되어 있다고 가정합니다.
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';




// 더미 데이터
class Medication {
  final String name;
  final String dosage;
  final String purpose;
  final String duration;
  final String memo;
  final String status;
  final String disease; // <<--- 새로운 필드: 병명

  Medication({
    required this.name,
    required this.dosage,
    required this.purpose,
    required this.duration,
    required this.memo,
    required this.status,
    required this.disease, // <<--- 생성자에 추가
  });
}

final List<Medication> medicationList = [
  Medication(
    name: '아스피린',
    dosage: '100mg, 1일 1회',
    purpose: '혈액 희석제',
    duration: '2023-10-26 - 진행중',
    memo: '식사와 함께 복용하세요.',
    status: '복용중',
    disease: '고혈압', // <<--- 더미 데이터 추가
  ),
  Medication(
    name: '메트포르민',
    dosage: '500mg, 1일 2회',
    purpose: '당뇨병 관리',
    duration: '2023-01-15 - 진행중',
    memo: '복용 전 혈당 수치를 확인하세요.',
    status: '복용중',
    disease: '당뇨병', // <<--- 더미 데이터 추가
  ),
  Medication(
    name: '아목시실린',
    dosage: '250mg, 1일 3회',
    purpose: '감염 치료',
    duration: '2024-03-01 - 2024-03-10',
    memo: '처방된 약을 모두 복용하세요.',
    status: '완료됨',
    disease: '폐렴', // <<--- 더미 데이터 추가
  ),
];

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Cure Mate',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor:AppColors.white),
        fontFamily: 'NotoSansKR',
        useMaterial3: true,
      ),
      home: const MedicationManagementPage(),
    );
    
  }
}

class MedicationManagementPage extends StatefulWidget {
  const MedicationManagementPage({super.key});

  @override
  State<MedicationManagementPage> createState() =>
      _MedicationManagementPageState();
}

class _MedicationManagementPageState extends State<MedicationManagementPage> {
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final header = Provider.of<HeaderProvider>(context, listen: false);
    header.setTitle('복약 관리');
    header.setShowBackButton(true);

    final nav = Provider.of<BottomNavProvider>(context, listen: false);
    nav.changeIndex(1);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            const PatientScreenHeader(),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                child: Column(
                  children: medicationList.map((medication) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: MedicationCard(medication: medication),
                    );
                  }).toList(),
                ),
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          debugPrint('새 약물 추가');
        },
        backgroundColor: AppColors.mainBtn,
        shape: const CircleBorder(),
        elevation: 6,
        child: Icon(Icons.add, color: AppColors.white, size: 28),
      ),
      bottomNavigationBar: const PatientScreenBottomNavBar(),
    );
  }
}

class MedicationCard extends StatefulWidget {
  final Medication medication;

  const MedicationCard({super.key, required this.medication});

  @override
  State<MedicationCard> createState() => _MedicationCardState();
}

class _MedicationCardState extends State<MedicationCard> {
  late String _status;

  @override
  void initState() {
    super.initState();
    _status = widget.medication.status;
  }

  void _toggleStatus() {
    setState(() {
      if (_status == '복용중') {
        _status = '완료됨';
      } else {
        _status = '복용중';
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      color:AppColors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Stack(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        widget.medication.name,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: AppColors.black,
                        ),
                      ),
                    ),
                    _buildStatusToggleButton(_status),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  widget.medication.dosage,
                  style: const TextStyle(
                    fontSize: 14,
                    color: AppColors.deepDarkBlue,
                  ),
                ),
                const SizedBox(height: 8), // 병명 위 간격
                _buildRichText(
                  '병명: ',
                  widget.medication.disease,
                ), // <<--- 병명 추가
                const SizedBox(height: 4), // 병명과 목적 사이 간격
                _buildRichText('목적: ', widget.medication.purpose),
                const SizedBox(height: 4),
                _buildRichText('기간: ', widget.medication.duration),
                const SizedBox(height: 4),
                _buildRichText('메모: ', widget.medication.memo),
                const SizedBox(height: 30),
              ],
            ),
            Positioned(
              bottom: 0,
              right: 0,
              child: ElevatedButton.icon(
                onPressed: () {
                  debugPrint('${widget.medication.name} 수정');
                },
                icon: const Icon(Icons.edit, size: 16),
                label: const Text('수정', style: TextStyle(fontSize: 14)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.mainBtn,
                  foregroundColor: AppColors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(5),
                  ),
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 18,
                  ),
                  minimumSize: Size.zero,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusToggleButton(String status) {
    final bool isActive = status == '복용중';
    Color bgColor = isActive ? AppColors.nonMemberBg : AppColors.memberBg;
    Color textColor = isActive ? AppColors.pinkBtnText : AppColors.blueBtnText;

    return GestureDetector(
      onTap: _toggleStatus,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Text(
          status,
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.bold,
            color: textColor,
          ),
        ),
      ),
    );
  }

  Widget _buildRichText(String label, String value) {
    return RichText(
      text: TextSpan(
        style: const TextStyle(
          fontSize: 14,
          color: AppColors.deepDarkBlue,
          fontFamily: 'NotoSansKR',
        ),
        children: [
          TextSpan(
            text: label,
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              color: AppColors.black,
            ),
          ),
          TextSpan(text: value),
        ],
      ),
    );
  }
}
