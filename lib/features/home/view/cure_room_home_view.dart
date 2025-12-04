import 'package:curemate/app/theme/app_colors.dart';
// 이 파일에서는 직접 화면을 push하지 않으니 아래 import들은 사실상 필요 없음.
// go_router 라우트 설정 쪽에서 사용하고 있을 거라면 거기서 import 해주면 됨.
// import 'package:curemate/features/cure_room/view/patient_profile_screen.dart';
// import 'package:curemate/features/patient/view/medical_history_screen.dart';
// import 'package:curemate/features/patient/view/medication_list_screen.dart';
// import 'package:curemate/features/recording/view/recording_list.dart';

import 'package:curemate/features/widgets/common/bottom_nav_provider.dart';
import 'package:curemate/features/widgets/common/header_provider.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:curemate/routes/route_paths.dart';
import 'package:curemate/features/widgets/common/custom_profile_avatar.dart';
import 'package:intl/intl.dart';

// ✅ 모델 import
import 'package:curemate/features/cure_room/model/cure_room_models.dart';
import 'package:curemate/features/cure_room/model/curer_model.dart';
import 'package:curemate/features/calendar/model/calendar_schedule_model.dart';
import 'package:curemate/features/calendar/model/calendar_model.dart';

// ✅ 서비스 import
import 'package:curemate/services/cure_room_service.dart';
import 'package:curemate/services/calendar_service.dart';

class CureRoomHomeView extends StatefulWidget {
  const CureRoomHomeView({super.key});

  @override
  State<CureRoomHomeView> createState() => _CureRoomHomeViewState();
}

class _CureRoomHomeViewState extends State<CureRoomHomeView> {
  // -----------------------------
  // ✅ 상태 변수들
  // -----------------------------
  final CureRoomService _cureRoomService = CureRoomService();

  CureRoomDetailModel? _cureRoomDetail; // /rest/cure/cureRoom 결과
  CurePatientModel? _patient; // patients[0]

  bool _isLoading = true;
  String? _errorMessage;

  int? _lastLoadedCureSeq;

  // 일정을 담을 변수 (기존 scheduleItems 대신 사용하거나 매핑)
  List<CureCalendarModel> _allMonthSchedules = [];
  List<CureCalendarModel> _todaySchedules = [];

  final CalendarService _calendarService = CalendarService();

  /// 👉 오늘 일정 (지금은 더미 데이터 비활성화)
  final List<Map<String, dynamic>> scheduleItems = [
    // {'title': '약: 아스피린', 'time': '오전 8:00', 'isDone': false},
    // {'title': '약: 이부프로펜', 'time': '오전 10:00', 'isDone': true},
    // {'title': '검진 예약', 'time': '오후 2:00', 'isDone': false},
    // {'title': '약: 비타민D', 'time': '오후 5:00', 'isDone': false},
    // {'title': '운동: 가벼운 스트레칭', 'time': '오후 8:00', 'isDone': true},
  ];

  bool _showAllSchedules = false;

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final header = Provider.of<HeaderProvider>(context, listen: false);
      header.setTitle('큐어룸 홈');
      header.setShowBackButton(false);

      // 🔥 최초 진입 시 한 번은 무조건 로드
      _loadCureRoom();
      _loadDailySchedule();

    });
  }

  // ✅ 일정 목록 조회 및 오늘 일정 필터링
  Future<void> _loadDailySchedule() async {
    final nav = Provider.of<BottomNavProvider>(context, listen: false);
    final int? cureSeq = nav.cureSeq;
    if (cureSeq == null) return;

    try {
      final now = DateTime.now();
      final String currentMonth = DateFormat('yyyyMM').format(now); // 예: 202405

      // 1. API 호출 (CureSeq + CalendarMonth)
      // CalendarService 등에 selectCureCalendarList에 대응하는 메소드가 있다고 가정
      // 파라미터: cureSeq, calendarMonth
      final List<CureCalendarModel> result =
      await _calendarService.getCureCalendarList(cureSeq, currentMonth);

      // 2. 오늘 날짜에 해당하는 것만 필터링
      final todayList = result.where((calendar) {
        final schedule = calendar.schedule; // 모델 구조에 따라 접근 경로 확인 필요
        if (schedule == null) return false;

        return _isScheduleOnDate(schedule, now);
      }).toList();

      setState(() {
        _allMonthSchedules = result;
        _todaySchedules = todayList;

        // 화면 표시용 더미 리스트 교체 (UI 바인딩용)
        scheduleItems.clear();
        for (var item in _todaySchedules) {
          scheduleItems.add({
            'title': item.cureCalendarNm,
            'time': _formatTime(item.schedule?.cureScheduleStartDttm), // 시간 포맷팅 필요
            'isDone': false, // 수행 여부 데이터가 있다면 연동
          });
        }
      });
    } catch (e) {
      print('일정 로드 실패: $e');
    }
  }

  // ✅ 특정 날짜(date)가 스케줄에 포함되는지 확인하는 로직
  bool _isScheduleOnDate(CureCalendarScheduleModel schedule, DateTime date) {
    // 1. 날짜 범위 체크 (Start ~ End)
    final start = DateTime.tryParse(schedule.cureScheduleStartDttm ?? '');
    final end = DateTime.tryParse(schedule.cureScheduleEndDttm ?? '');

    if (start == null || end == null) return false;

    // 시간 제거 후 날짜만 비교 (yyyy-MM-dd)
    final targetDate = DateTime(date.year, date.month, date.day);
    final startDate = DateTime(start.year, start.month, start.day);
    final endDate = DateTime(end.year, end.month, end.day);

    if (targetDate.isBefore(startDate) || targetDate.isAfter(endDate)) {
      return false;
    }

    // 2. 반복 여부 체크
    if (schedule.cureScheduleRepeatYn == 'N') {
      // 반복 없으면 날짜 범위 안에 있으면 True (보통 당일치기)
      return true;
    } else {
      // ✅ [수정] 매일 반복(daily)인 경우 요일 체크 없이 통과
      if (schedule.cureScheduleTypeCmcd == 'daily') {
        return true;
      }
      // 반복 있으면 요일 체크
      // weekday: 1(월) ~ 7(일)
      switch (date.weekday) {
        case DateTime.monday: return schedule.cureScheduleMonYn == 'Y';
        case DateTime.tuesday: return schedule.cureScheduleTuesYn == 'Y';
        case DateTime.wednesday: return schedule.cureScheduleWednesYn == 'Y';
        case DateTime.thursday: return schedule.cureScheduleThursYn == 'Y';
        case DateTime.friday: return schedule.cureScheduleFriYn == 'Y';
        case DateTime.saturday: return schedule.cureScheduleSaturYn == 'Y';
        case DateTime.sunday: return schedule.cureScheduleSunYn == 'Y';
      }
    }
    return false;
  }

  String _formatTime(String? dateTimeStr) {
    if (dateTimeStr == null) return '';
    // DB값이 '2024-05-20 14:00:00' 형태라고 가정 시 파싱 후 시간만 리턴
    try {
      final dt = DateTime.parse(dateTimeStr);
      return DateFormat('a h:mm', 'ko').format(dt); // 예: 오후 2:00
    } catch (e) {
      return '';
    }
  }

  // -----------------------------
  // ✅ 헬퍼 함수들
  // -----------------------------

  /// yyyyMMdd → 대략적인 나이 계산 (한국식 +1)
  int? _calculateAge(String? yyyymmdd) {
    if (yyyymmdd == null || yyyymmdd.length < 4) return null;
    final year = int.tryParse(yyyymmdd.substring(0, 4));
    if (year == null) return null;

    final now = DateTime.now();
    return now.year - year + 1;
  }

  /// 성별 코드 → 한글
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
        return '성별 미등록';
    }
  }

  // 큐어룸 단건 조회 API 호출
  Future<void> _loadCureRoom() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final nav = Provider.of<BottomNavProvider>(context, listen: false);
      final int? cureSeq = nav.cureSeq;

      if (cureSeq == null) {
        setState(() {
          _errorMessage = '선택된 큐어룸이 없습니다.\n(하단 네비에서 큐어룸을 먼저 선택해주세요)';
          _isLoading = false;
          _lastLoadedCureSeq = null;
        });
        return;
      }

      final CureRoomDetailModel detail =
      await _cureRoomService.getCureRoom(cureSeq);

      final CurePatientModel? firstPatient =
      detail.patients.isNotEmpty ? detail.patients.first : null;

      setState(() {
        _cureRoomDetail = detail;
        _patient = firstPatient;
        _isLoading = false;
        _lastLoadedCureSeq = cureSeq; // ✅ 지금 로드한 큐어룸 번호 기억
      });
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }

  // -----------------------------
  // ✅ 화면 빌드
  // -----------------------------
  @override
  Widget build(BuildContext context) {
    final nav = Provider.of<BottomNavProvider>(context);

    // 🔹 현재 선택된 큐어룸 번호
    final int? currentCureSeq = nav.cureSeq;

    // 🔹 선택된 큐어룸이 바뀌었거나, 아직 한 번도 로드 안 했으면 API 다시 호출
    if (currentCureSeq != null && currentCureSeq != _lastLoadedCureSeq && !_isLoading) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _loadCureRoom();
        _loadDailySchedule();
      });
    }

    // 로딩 중
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    // 에러 화면
    if (_errorMessage != null) {
      return Center(
        child: Text(
          '큐어룸 정보를 불러오지 못했습니다.\n$_errorMessage',
          textAlign: TextAlign.center,
        ),
      );
    }

    // 🔹 큐어룸 이름: API 응답 > BottomNavProvider.selectedCurer > 기본값
    final String cureNm =
        _cureRoomDetail?.cure.cureNm ?? nav.cureName ?? '큐어룸명';

    final bool hasPatient = _patient != null;
    final bool hasSchedule = hasPatient && scheduleItems.isNotEmpty;

    return LayoutBuilder(
      builder: (context, constraints) {
        return Container(
          width: constraints.maxWidth,
          height: constraints.maxHeight, // ✅ 헤더~네비 사이 전체를 꽉 채움
          color: AppColors.lightBackground,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                hasPatient && _patient != null
                    ? _buildPatientInfoCard(_patient!)
                    : _buildEmptyPatientCard(),
                hasSchedule
                    ? _buildScheduleSectionWithItems()
                    : _buildEmptyScheduleSection(),
                _buildQuickActionButtons(),
                const SizedBox(height: 16),
              ],
            ),
          ),
        );
      },
    );
  }


  // -----------------------------
  // ✅ 환자 카드들
  // -----------------------------

  /// 환자 있음 버전
  Widget _buildPatientInfoCard(CurePatientModel patient) {
    final name = patient.patientNm;
    final age = _calculateAge(patient.patientBirthday);
    final gender = _genderLabel(patient.patientGenderCmcd);
    final allergy = ''; // TODO: 나중에 알레르기 정보 생기면 연결

    // 🔹 프로필 이미지: 환자 프로필 > (없으면 큐어룸 이미지 > 없으면 null)
    final profileImgUrl =
        patient.profileImgUrl ?? _cureRoomDetail?.cure.profileImgUrl;



    return Container(
      margin: const EdgeInsets.fromLTRB(16, 40, 16, 16),
      padding: const EdgeInsets.all(20),
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
          // 🔹 프로필 영역 (아이콘 + 텍스트)
          Row(
            crossAxisAlignment: CrossAxisAlignment.center, // ✅ 세로 중앙 정렬
            children: [
              // 왼쪽: 동그란 프로필 (MoreTab 프로필 카드 느낌)
              CustomProfileAvatar(
                key: ValueKey(profileImgUrl),  // ↔ 이미지 URL 바뀌면 강제로 다시 그림
                imageUrl: profileImgUrl,
                radius: 36,                    // 36 * 2 = 72 (예전과 같음)
                fallbackIcon: Icons.person,
              ),
              const SizedBox(width: 16),

              // 오른쪽: 텍스트 정보
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 🔽 맨 위 여백 제거해서 중앙 정렬 느낌 더 맞춤
                    const Text(
                      '환자 정보',
                      style: TextStyle(
                        fontSize: 14,
                        color: AppColors.darkBlue,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      name,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppColors.black,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      "${age != null ? '$age세' : '나이 미등록'}, $gender${allergy.isNotEmpty ? ', $allergy' : ''}",
                      style: const TextStyle(
                        fontSize: 13,
                        color: AppColors.darkBlue,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 20),

          // 🔹 하단: 전체 폭 버튼 (MoreTab의 "내 정보 수정" 버튼 느낌)
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () async {
                // 프로필 화면 갔다가
                final bool? result = await context.push<bool>(
                  RoutePaths.cureRoomPatientProfile,
                  extra: {
                    'patient': patient,
                    'profileImgUrl': profileImgUrl,
                  },
                );

                // ✅ 수정/삭제가 일어난 경우에만 리로드
                if (result == true) {
                  _loadCureRoom();
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFA0C4FF), // 큐어룸 톤 유지
                foregroundColor: Colors.white,
                elevation: 0,
                minimumSize: const Size.fromHeight(48),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
              child: const Text(
                '프로필 보기',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
  /// 환자 없음 기본 카드
  /// 환자 없음 기본 카드 (환자 카드와 거의 동일 레이아웃)
  Widget _buildEmptyPatientCard() {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 40, 16, 16),
      padding: const EdgeInsets.all(20),
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
          // 🔹 프로필 + 텍스트 영역 (환자 카드와 동일 레이아웃)
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // 왼쪽: 동그란 기본 프로필 아이콘
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.lightGrey,
                ),
                child: Icon(
                  Icons.person,
                  size: 42,
                  color: AppColors.grey,
                ),
              ),
              const SizedBox(width: 16),

              // 오른쪽: 텍스트 영역
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    Text(
                      '환자 정보',
                      style: TextStyle(
                        fontSize: 14,
                        color: AppColors.darkBlue,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      '등록된 환자가 없습니다.',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: AppColors.black,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 20),

          // 🔹 전체 폭 버튼 (위 환자카드의 "프로필 보기"랑 스타일 맞춤)
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () async {
                final result = await context.push(RoutePaths.cureRoomAddPatient);

                // AddPatientScreen에서 성공 시 true를 넘겨주면 여기에서만 리로드
                if (result == true) {
                  _loadCureRoom();
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFA0C4FF),
                foregroundColor: Colors.white,
                elevation: 0,
                minimumSize: const Size.fromHeight(48),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
              child: const Text(
                '환자 등록',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // -----------------------------
  // ✅ 일정 카드들
  // -----------------------------

  /// 일정 있음 버전
  Widget _buildScheduleSectionWithItems() {
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
          // 상단 타이틀
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: const [
              Text(
                '오늘의 일정',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.black,
                ),
              ),
              Icon(
                Icons.calendar_today_outlined,
                size: 20,
                color: AppColors.darkBlue,
              ),
            ],
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

  /// 일정 없음 기본 카드
  Widget _buildEmptyScheduleSection() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      constraints: const BoxConstraints(
        minHeight: 180,
      ),
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
        children: const [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '오늘의 일정',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.black,
                ),
              ),
              Icon(
                Icons.calendar_today_outlined,
                size: 20,
                color: AppColors.darkBlue,
              ),
            ],
          ),
          SizedBox(height: 24),
          Center(
            child: Padding(
              padding: EdgeInsets.symmetric(vertical: 8.0),
              child: Text(
                '오늘 등록된 일정이 없습니다.',
                style: TextStyle(
                  fontSize: 14,
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
      String title,
      String time,
      bool isDone,
      ValueChanged<bool> onToggle,
      ) {
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
                      fontSize: 14,
                      color: AppColors.darkBlue,
                    ),
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

  // -----------------------------
  // ✅ 빠른 실행 버튼
  // -----------------------------
  Widget _buildQuickActionButtons() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildQuickActionButton(
            Icons.medical_services,
            '진료 목록',
                () {
              // ✅ go_router로 진료 목록 이동
              // context.push(RoutePaths.cureRoomRecordingList);
            },
            iconColor: AppColors.pinkIconColor,
          ),
          _buildQuickActionButton(
            Icons.book,
            '뿌듯 일지',
                () {
              // ✅ go_router로 뿌듯일지 이동
              //context.push(RoutePaths.cureRoomProudDiary);
            },
            iconColor: AppColors.yellowIconColor,
          ),
          _buildQuickActionButton(
            Icons.assignment,
            '증상 일지',
                () {
              // ✅ go_router로 증상일지 이동
              //context.push(RoutePaths.cureRoomMedicalHistory);
            },
            iconColor: AppColors.greenIconColor,
          ),
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
