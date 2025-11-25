import 'package:curemate/app/theme/app_colors.dart';
import 'package:curemate/features/widgets/common/header_provider.dart';
import 'package:flutter/material.dart';
import 'package:curemate/features/patient/view/medical_detail_screen.dart';
import 'package:curemate/features/widgets/common/widgets.dart'; // PatientScreenHeader, PatientScreenBottomNavBar 등이 여기에 정의되어 있다고 가정합니다.
import 'package:provider/provider.dart';


// ----------------- 모델 -----------------
class HistoryItem {
  final int id;
  final String name;
  final String date;
  final String status;
  final String type;
  final String symptoms;
  final String? recoveryDate;
  final String? familyRelation;

  HistoryItem({
    required this.id,
    required this.name,
    required this.date,
    required this.status,
    required this.type,
    required this.symptoms,
    this.recoveryDate,
    this.familyRelation,
  });
}

// ----------------- 메인 화면 -----------------
class MedicalHistoryScreen extends StatefulWidget {
  const MedicalHistoryScreen({super.key});

  @override
  State<MedicalHistoryScreen> createState() => _MedicalHistoryScreenState();
}

class _MedicalHistoryScreenState extends State<MedicalHistoryScreen> {
  final List<HistoryItem> historyItems = [
    HistoryItem(
      id: 1,
      name: '고혈압',
      date: '2020-05-10',
      status: '진행중',
      type: '현재병력',
      symptoms: '특별한 증상 없음',
    ),
    HistoryItem(
      id: 2,
      name: '독감',
      date: '2022-12-15',
      status: '완치',
      type: '과거병력',
      symptoms: '고열, 기침, 인후통',
      recoveryDate: '2023-01-05',
    ),
    HistoryItem(
      id: 3,
      name: '당뇨병',
      date: '미상',
      status: '진행중',
      type: '가족력',
      symptoms: '',
      familyRelation: '부',
    ),
    HistoryItem(
      id: 4,
      name: '천식',
      date: '2023-08-01',
      status: '진행중',
      type: '현재병력',
      symptoms: '숨 가쁨, 기침, 쌕쌕거림',
    ),
    HistoryItem(
      id: 5,
      name: '폐렴',
      date: '2021-06-20',
      status: '완치',
      type: '가족력',
      symptoms: '기침, 발열, 가래',
      recoveryDate: '2021-07-15',
      familyRelation: '모',
    ),
  ];

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final header = Provider.of<HeaderProvider>(context, listen: false);
    header.setTitle('병력 관리');
    header.setShowBackButton(true);
  }

  @override
  Widget build(BuildContext context) {
    final List<HistoryItem> currentHistory = historyItems
        .where((item) => item.type == '현재병력')
        .toList();
    final List<HistoryItem> pastHistory = historyItems
        .where((item) => item.type == '과거병력')
        .toList();
    final List<HistoryItem> familyHistory = historyItems
        .where((item) => item.type == '가족력')
        .toList();

    return Scaffold(
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 공통 헤더
            const PatientScreenHeader(),

            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 24,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (currentHistory.isNotEmpty)
                      _buildHistorySection(
                        '현재 병력',
                        currentHistory,
                        '현재병력',
                      ), // 타입 추가
                    const SizedBox(height: 20),
                    if (pastHistory.isNotEmpty)
                      _buildHistorySection(
                        '과거 병력',
                        pastHistory,
                        '과거병력',
                      ), // 타입 추가
                    const SizedBox(height: 20),
                    if (familyHistory.isNotEmpty)
                      _buildHistorySection(
                        '가족력',
                        familyHistory,
                        '가족력',
                      ), // 타입 추가
                    const SizedBox(height: 24),
                    _buildAddButton(context),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: const PatientScreenBottomNavBar(),
    );
  }

  // title 옆에 아이콘을 추가하도록 type 매개변수 추가 (아이콘 표시 부분 주석 처리됨)
  Widget _buildHistorySection(
    String title,
    List<HistoryItem> items,
    String type,
  ) {
    // IconData iconData; // 아이콘 데이터 변수 (주석 처리)
    // Color iconColor; // 아이콘 색상 변수 (주석 처리)

    // if (type == '현재병력') { // 조건부 아이콘 설정 로직 (주석 처리)
    //   iconData = Icons.local_hospital;
    //   iconColor = AppColors.activeColor;
    // } else if (type == '과거병력') {
    //   iconData = Icons.history;
    //   iconColor = accentPurple;
    // } else { // 가족력
    //   iconData = Icons.groups;
    //   iconColor = accentPink;
    // }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Row( // 아이콘과 텍스트를 함께 표시하기 위해 Row 사용 (주석 처리)
        //   children: [
        //     Icon( // 아이콘 위젯 (주석 처리)
        //       iconData,
        //       color: iconColor,
        //       size: 24, // 아이콘 크기 조절
        //     ),
        //     const SizedBox(width: 8), // 아이콘과 텍스트 사이 간격 (주석 처리)
        Text(
          // 제목 텍스트만 표시
          title,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: AppColors.blueTextSecondary,
          ),
        ),
        //   ],
        // ),
        const SizedBox(height: 12),
        // GridView를 사용하여 한 줄에 3개씩 배치
        GridView.builder(
          physics:
              const NeverScrollableScrollPhysics(), // SingleChildScrollView와 함께 사용
          shrinkWrap: true, // GridView의 크기를 내용물에 맞게 조절
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3, // 한 줄에 3개 아이템
            crossAxisSpacing: 10, // 가로 간격
            mainAxisSpacing: 10, // 세로 간격
            childAspectRatio: 0.9, // 아이템의 가로세로 비율 (조절 필요, 내용에 따라 유동적으로 조정)
          ),
          itemCount: items.length,
          itemBuilder: (context, index) {
            return _buildHistoryCard(items[index]);
          },
        ),
      ],
    );
  }

  Widget _buildHistoryCard(HistoryItem item) {
    Color statusColor = AppColors.statusOngoing;
    if (item.status == '완치') statusColor = AppColors.statusDone;
    if (item.status == '주의') statusColor = AppColors.statusWarning;

    return InkWell(
      onTap: () {
        Navigator.push(
  context,
  PageRouteBuilder(
    // 애니메이션 지속 시간을 0으로 설정
    transitionDuration: Duration.zero,
    pageBuilder: (context, animation, secondaryAnimation) =>
        MedicalHistoryDetailPage(isNew: false),
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      // 애니메이션 없이 새 화면을 바로 표시
      return child;
    },
  ),
);
      },
      borderRadius: BorderRadius.circular(16),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: AppColors.grey.withOpacity(0.08),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        padding: const EdgeInsets.all(12), // 패딩을 줄여서 카드 크기 조절
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center, // 텍스트를 중앙으로
          children: [
            Text(
              item.name,
              textAlign: TextAlign.center, // 텍스트 중앙 정렬
              style: TextStyle(
                fontSize: 14, // 폰트 크기 조절
                fontWeight: FontWeight.bold,
                color: AppColors.blueTextSecondary,
              ),
              maxLines: 2, // 두 줄까지 표시 가능하도록
              overflow: TextOverflow.ellipsis, // 넘치면 ...으로 표시
            ),
            if (item.type == '가족력' && item.familyRelation != null)
              Padding(
                padding: const EdgeInsets.only(top: 4.0),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 1,
                  ), // 패딩 조절
                  decoration: BoxDecoration(
                    color: AppColors.nonMemberBg,
                    borderRadius: BorderRadius.circular(10), // 보더 반경 조절
                  ),
                  child: Text(
                    '${item.familyRelation}', // 관계만 표시
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 10, // 폰트 크기 조절
                      fontWeight: FontWeight.w500,
                      color:AppColors.pinkBtnText,
                    ),
                  ),
                ),
              ),
            // 가족력이 아닐 때만 발병일/완치일 표시
            if (item.type != '가족력')
              Padding(
                padding: const EdgeInsets.only(top: 4.0), // 상단 여백 추가
                child: Text(
                  (item.recoveryDate != null && item.status == '완치')
                      ? '${item.date} ~ ${item.recoveryDate}' // 발병일 ~ 완치일
                      : '${item.date} 시작', // 발병일만 표시
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 10,
                    color: AppColors.blueTextSecondary,
                  ), // 폰트 크기 조절
                  maxLines: 1, // 한 줄만 표시
                  overflow: TextOverflow.ellipsis, // 넘치면 ...으로 표시
                ),
              ),
            // 상태 텍스트
            const SizedBox(height: 4), // 간격 조절
            Text(
              item.status,
              style: TextStyle(
                fontSize: 10,
                color: statusColor,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAddButton(BuildContext context) {
    return ElevatedButton(
      onPressed: () {

        Navigator.push(
  context,
  PageRouteBuilder(
    // 애니메이션 지속 시간을 0으로 설정
    transitionDuration: Duration.zero,
    pageBuilder: (context, animation, secondaryAnimation) =>
        MedicalHistoryDetailPage(isNew: true),
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      // 애니메이션 없이 새 화면을 바로 표시
      return child;
    },
  ),
);
      },
      style: ElevatedButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        backgroundColor: AppColors.activeColor,
        foregroundColor: AppColors.white, // 텍스트/아이콘 색상 추가 (ElevatedButton 기본 설정)
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: const [
          Icon(Icons.add, size: 20),
          SizedBox(width: 8),
          Text(
            '새 병력 추가',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
}
