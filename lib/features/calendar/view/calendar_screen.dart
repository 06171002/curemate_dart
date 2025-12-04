import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:curemate/app/theme/app_colors.dart';
import 'package:curemate/features/calendar/view/calendar_widget.dart';
import 'package:curemate/features/calendar/view/new_schedule_screen.dart';
import 'package:curemate/services/calendar_service.dart';
import 'package:provider/provider.dart';
import 'package:curemate/features/widgets/common/bottom_nav_provider.dart';
import 'package:curemate/features/calendar/model/calendar_model.dart';

class CalendarScreen extends StatefulWidget {
  const CalendarScreen({super.key});

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  CalendarFormat _calendarFormat = CalendarFormat.month;
  bool? _lastIsMainMode;
  int? _lastCureSeq;

  // 날짜별 이벤트를 저장할 Map
  Map<DateTime, List<Map<String, dynamic>>> _events = {};

  final CalendarService _calendarService = CalendarService();

  @override
  void initState() {
    super.initState();
    _selectedDay = _focusedDay;
    // 초기 로딩 (현재 월 데이터 조회)
    _fetchMonthlySchedules(_focusedDay);
  }

  // API 호출 함수
  Future<void> _fetchMonthlySchedules(DateTime date) async {
    // [1] Provider에서 현재 상태(모드, 큐어룸ID) 가져오기
    final navProvider = context.read<BottomNavProvider>();
    final bool isMainMode = navProvider.isMainMode;
    final int? cureSeq = navProvider.cureSeq;

    List<Map<String, dynamic>> schedules = [];

    try {
      if (!isMainMode && cureSeq != null) {
        // [CASE A] 큐어룸 모드: 선택된 큐어룸의 일정만 조회
        // API가 'yyyyMM' 형식의 문자열을 요구하므로 변환
        final String month = DateFormat('yyyyMM').format(date);

        // Service 호출 (List<CureCalendarModel> 반환됨)
        final List<CureCalendarModel> models =
        await _calendarService.getCureCalendarList(cureSeq, month);

        // 기존 UI 로직이 Map 구조를 사용하므로, Model을 Map으로 변환하여 통일
        schedules = models.map((e) => e.toJson()).toList();

      } else {
        // [CASE B] 메인 모드: 내 전체 일정 조회 (기존 로직)
        schedules = await _calendarService.getMonthlyScheduleList(date);
      }
    } catch (e) {
      print('일정 로드 실패: $e');
      // 에러 발생 시 빈 리스트로 유지
      schedules = [];
    }

    if (!mounted) return;

    // setState 내부 로직 수정
    setState(() {
      _events.clear();

      final firstDayOfMonth = DateTime(date.year, date.month, 1);
      final lastDayOfMonth = DateTime(date.year, date.month + 1, 0);

      // 이번 달의 날짜 수만큼 반복 (최대 31번)
      int daysInMonth = lastDayOfMonth.day;

      for (var data in schedules) {
        final scheduleInfo = data['schedule'];
        if (scheduleInfo == null) continue;

        DateTime? sStart;
        if (scheduleInfo['cureScheduleStartDttm'] != null) {
          sStart = DateTime.parse(scheduleInfo['cureScheduleStartDttm']);
        }
        if (sStart == null) continue;

        // 반복 종료일 체크
        DateTime? sStop;
        if (scheduleInfo['cureScheduleStopDttm'] != null) {
          sStop = DateTime.parse(scheduleInfo['cureScheduleStopDttm']);
        }
        String stopYn = scheduleInfo['cureScheduleStopYn'] ?? 'N';

        // 📅 이번 달 1일부터 말일까지 하루씩 돌면서 이 일정이 해당되는지 검사
        for (int i = 0; i < daysInMonth; i++) {
          DateTime targetDate = firstDayOfMonth.add(Duration(days: i));

          // 1. 반복 종료일 지났으면 패스
          if (stopYn == 'Y' && sStop != null) {
            // 시간까지 정확히 비교하려면 isAfter 사용
            if (targetDate.isAfter(sStop)) continue;
          }

          // 2. 날짜 매칭 확인 (_isScheduleOnDate 호출)
          if (_isScheduleOnDate(data, targetDate, sStart)) {
            final key = DateTime(targetDate.year, targetDate.month, targetDate.day);
            if (_events[key] == null) _events[key] = [];
            _events[key]!.add(data);
          }
        }
      }
    });
  }

  // ✅ [추가] 특정 날짜(targetDate)가 일정 규칙에 부합하는지 확인하는 함수
  bool _isScheduleOnDate(Map<String, dynamic> data, DateTime targetDate, DateTime sStart) {
    final schedule = data['schedule'];
    if (schedule == null) return false;

    String repeatYn = schedule['cureScheduleRepeatYn'] ?? 'N';
    String type = schedule['cureScheduleTypeCmcd'] ?? 'daily';

    // 1. 반복이 없는 경우: 날짜 범위 내에 있는지 확인
    if (repeatYn == 'N') {
      DateTime? sEnd = schedule['cureScheduleEndDttm'] != null
          ? DateTime.parse(schedule['cureScheduleEndDttm'])
          : sStart;

      // 시간 제거 (yyyy-MM-dd)
      DateTime start = DateTime(sStart.year, sStart.month, sStart.day);
      DateTime end = DateTime(sEnd.year, sEnd.month, sEnd.day);
      DateTime target = DateTime(targetDate.year, targetDate.month, targetDate.day);

      return !target.isBefore(start) && !target.isAfter(end);
    }

    // 2. 매일 반복
    if (type == 'daily') return true;

    // 3. 매주 반복 (요일 체크)
    if (type == 'weekly') {
      switch (targetDate.weekday) {
        case DateTime.monday: return schedule['cureScheduleMonYn'] == 'Y';
        case DateTime.tuesday: return schedule['cureScheduleTuesYn'] == 'Y';
        case DateTime.wednesday: return schedule['cureScheduleWednesYn'] == 'Y';
        case DateTime.thursday: return schedule['cureScheduleThursYn'] == 'Y';
        case DateTime.friday: return schedule['cureScheduleFriYn'] == 'Y';
        case DateTime.saturday: return schedule['cureScheduleSaturYn'] == 'Y';
        case DateTime.sunday: return schedule['cureScheduleSunYn'] == 'Y';
        default: return false;
      }
    }

    // 4. 매월 반복 (기간 체크 로직 추가)
    if (type == 'monthly') {
      // ① 일정의 기간(일수) 계산 (예: 12/4 ~ 12/8 = 4일 차이)
      DateTime? sEnd = schedule['cureScheduleEndDttm'] != null
          ? DateTime.parse(schedule['cureScheduleEndDttm'])
          : sStart;
      int durationDays = sEnd.difference(sStart).inDays;

      // ② "이번 달(targetDate의 월)"에서의 시작일 가상 생성
      // 예: target이 1월 5일이면 -> 가상 시작일은 1월 4일
      // (단, 31일 등 날짜가 없는 달 예외 처리 필요)
      try {
        DateTime virtualStart = DateTime(targetDate.year, targetDate.month, sStart.day);
        DateTime virtualEnd = virtualStart.add(Duration(days: durationDays));

        // ③ targetDate가 "가상 시작일 ~ 가상 종료일" 사이에 있는지 확인
        DateTime target = DateTime(targetDate.year, targetDate.month, targetDate.day);
        return !target.isBefore(virtualStart) && !target.isAfter(virtualEnd);
      } catch (e) {
        // 해당 월에 시작일(예: 31일)이 없는 경우 표시 안 함
        return false;
      }
    }

    // 5. 매년 반복
    if (type == 'yearly') {
      // 매월과 비슷하게 연도만 targetDate.year로 바꿔서 범위 체크하면 됩니다.
      DateTime? sEnd = schedule['cureScheduleEndDttm'] != null
          ? DateTime.parse(schedule['cureScheduleEndDttm'])
          : sStart;
      int durationDays = sEnd.difference(sStart).inDays;

      try {
        DateTime virtualStart = DateTime(targetDate.year, sStart.month, sStart.day);
        DateTime virtualEnd = virtualStart.add(Duration(days: durationDays));

        DateTime target = DateTime(targetDate.year, targetDate.month, targetDate.day);
        return !target.isBefore(virtualStart) && !target.isAfter(virtualEnd);
      } catch (e) {
        return false;
      }
    }

    return false;
  }
  // 선택된 날짜의 일정 리스트 가져오기
  List<Map<String, dynamic>> _getEventsForDay(DateTime day) {
    final key = DateTime(day.year, day.month, day.day);
    return _events[key] ?? [];
  }

  // [수정 1] 클래스 내부(build 메서드 위쪽)에 코드 변환 함수 추가
  String _mapCodeToLabel(String? code) {
    switch (code) {
      case 'treatment': return '진료';
      case 'medicine': return '복약';
      case 'test': return '검사';
      case 'etc': return '기타';
      default: return '기타'; // 혹은 code 그대로 반환 or '진료' 등 기본값
    }
  }

  // [수정] 날짜 파싱 강화 (공백 -> T 변환)
  String _calculateAlarmOption(String startDttmStr, String alarmDttmStr) {
    try {
      // "2025-12-04 09:00:00" -> "2025-12-04T09:00:00" 변환해야 파싱 성공
      DateTime start = DateTime.parse(startDttmStr.replaceAll(' ', 'T'));
      DateTime alarm = DateTime.parse(alarmDttmStr.replaceAll(' ', 'T'));

      Duration diff = start.difference(alarm);

      if (diff.inMinutes == 0) return '정각';
      if (diff.inMinutes == 5) return '5분 전';
      if (diff.inMinutes == 10) return '10분 전';
      if (diff.inMinutes == 30) return '30분 전';
      if (diff.inHours == 1) return '1시간 전';
      if (diff.inDays == 1) return '하루 전';

      return '10분 전';
    } catch (e) {
      print("알람 시간 계산 오류: $e"); // 디버깅용 로그
      return '10분 전';
    }
  }

  // [추가] 알람 타입 코드 변환 (sms -> SMS)
  String _mapAlarmTypeLabel(String? code) {
    if (code == 'sms') return 'SMS';
    if (code == 'email') return '이메일';
    return '푸시'; // 기본값
  }

  // [추가] 반복 코드 변환 함수 (daily -> 매일)
  String _mapRepeatCodeToOption(String? repeatYn, String? typeCode) {
    // 1. 반복 여부가 N이면 '반복 없음'
    if (repeatYn != 'Y') return '반복 없음';

    // 2. 반복 코드를 UI 텍스트로 변환
    switch (typeCode) {
      case 'daily': return '매일';
      case 'weekly': return '매주';
      case 'monthly': return '매월';
      case 'yearly': return '매년';
      default: return '반복 없음';
    }
  }

  IconData _getIconForType(String? typeCode) {
    switch (typeCode) {
      case 'medicine':
        return Icons.medication_outlined; // 약
      case 'treatment':
        return Icons.local_hospital_outlined; // 병원
      case 'test':
        return Icons.biotech_outlined; // 검사
      default:
        return Icons.event_note_outlined; // 기타
    }
  }

  // ✅ [추가] 시간 포맷팅 (예: 14:00 -> 오후 2:00)
  String _formatTime(String timeStr) {
    if (timeStr.length < 5) return timeStr;
    try {
      final dt = DateFormat('HH:mm').parse(timeStr.substring(0, 5));
      return DateFormat('a h:mm', 'ko').format(dt);
    } catch (e) {
      return timeStr;
    }
  }

  @override
  Widget build(BuildContext context) {
    // 1. Provider의 값 변경 감지 (구독)
    final navProvider = context.watch<BottomNavProvider>();
    final isMainMode = navProvider.isMainMode;
    final cureSeq = navProvider.cureSeq;

    // 2. 상태가 변경되었는지 확인 (모드가 바뀌었거나, 선택된 큐어룸이 바뀌었을 때)
    if (isMainMode != _lastIsMainMode || cureSeq != _lastCureSeq) {
      // 상태 동기화
      _lastIsMainMode = isMainMode;
      _lastCureSeq = cureSeq;

      // [중요] 빌드 도중에 setState나 비동기 함수를 바로 부르면 에러가 날 수 있으므로
      // 화면 그리기(build)가 끝난 직후에 실행되도록 예약
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _fetchMonthlySchedules(_focusedDay);
      });
    }
    final selectedEvents = _selectedDay != null ? _getEventsForDay(_selectedDay!) : [];

    return Scaffold(
      backgroundColor: AppColors.lightBackground,
      body: Column(
        children: [
          // 1. 달력 위젯 (데이터를 주입받음)
          CalendarWidget(
            focusedDay: _focusedDay,
            selectedDay: _selectedDay,
            calendarFormat: _calendarFormat,
            events: _events, // [중요] 조회한 데이터를 넘겨줌
            onPageChanged: (focusedDay) {
              _focusedDay = focusedDay;
              _fetchMonthlySchedules(focusedDay); // [중요] 월 변경 시 재조회
            },
            onDaySelected: (selectedDay, focusedDay) {
              setState(() {
                _selectedDay = selectedDay;
                _focusedDay = focusedDay;
              });
            },
          ),

          const SizedBox(height: 8),

          // 2. 하단 일정 리스트 (동일한 데이터를 사용)
          Expanded(
            child: selectedEvents.isEmpty
                ? Center(
              child: Text(
                _selectedDay != null
                    ? "${_selectedDay!.month}월 ${_selectedDay!.day}일 일정 없음"
                    : "날짜를 선택해주세요.",
                style: const TextStyle(color: Colors.grey, fontSize: 16),
              ),
            )
                : ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: selectedEvents.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final schedule = selectedEvents[index];

                // ✅ [수정] 변수 추출을 GestureDetector 위로 올립니다.
                final scheduleInfo = schedule['schedule'] ?? {};
                String startFullDttm = scheduleInfo['cureScheduleStartDttm'] ?? '';

                // 화면 표시 & onTap 양쪽에서 쓸 수 있도록 여기서 미리 계산
                String startTime = startFullDttm.length > 16
                    ? startFullDttm.substring(11, 16)
                    : '';

                return GestureDetector(
                  onTap: () {

                    String endFullDttm = scheduleInfo['cureScheduleEndDttm'] ?? '';

                    // 날짜와 시간을 분리 (데이터 형식이 "yyyy-MM-dd HH:mm:ss"라고 가정)
                    String startDate = startFullDttm.length >= 10 ? startFullDttm.substring(0, 10) : '';
                    String endDate = endFullDttm.length >= 10 ? endFullDttm.substring(0, 10) : '';
                    String endTime = endFullDttm.length > 16 ? endFullDttm.substring(11, 16) : '00:00';

                    // startTime이 비어있으면 기본값 처리 (NewScheduleScreen 전달용)
                    String startTimeForNav = startTime.isEmpty ? '00:00' : startTime;
                    // [추가] 알람 정보 처리 로직
                    // 백엔드 응답 구조에 따라 키 이름('alramList' 등) 확인 필요
                    List<dynamic> alramList = schedule['alramList'] ?? schedule['alrams'] ?? [];

                    bool isAlarmOn = false;
                    String alarmTime = '10분 전';
                    String alarmType = '푸시';

                    // 1. 리스트가 비어있지 않고, 첫 번째 아이템의 시간이 null이 아니어야 함
                    if (alramList.isNotEmpty && alramList.first['cureAlramDttm'] != null) {
                      isAlarmOn = true;
                      final firstAlarm = alramList.first;
                      String alarmDttm = firstAlarm['cureAlramDttm'] ?? '';

                      if (startFullDttm.isNotEmpty && alarmDttm.isNotEmpty) {
                        alarmTime = _calculateAlarmOption(startFullDttm, alarmDttm);
                      }
                      alarmType = _mapAlarmTypeLabel(firstAlarm['cureAlramTypeCmcd']);
                    }

                    // ▼▼▼ [추가] 반복 설정 변환 로직 ▼▼▼
                    String repeatOption = _mapRepeatCodeToOption(
                        scheduleInfo['cureScheduleRepeatYn'],
                        scheduleInfo['cureScheduleTypeCmcd']
                    );

                    // 매핑된 맵 생성
                    final Map<String, dynamic> mappedSchedule = {
                      // 수정 시 식별할 고유 ID (PK)
                      'schedule_seq': scheduleInfo['cureScheduleSeq'] ?? 0,
                      'cureCalendarSeq': schedule['cureCalendarSeq'],

                      // 화면에 표시될 텍스트
                      'title': schedule['cureCalendarNm'] ?? '',
                      'content': schedule['cureCalendarDesc'] ?? '',

                      // 날짜 및 시간
                      'start_date': startDate,
                      'end_date': endDate,
                      'start_time': startTime,
                      'end_time': endTime,
                      'isAlarmOn': isAlarmOn,
                      'alarmTime': alarmTime,
                      'alarmType': alarmType,

                      'repeatOption': repeatOption,

                      // 옵션들 (DB 값 'Y'/'N'을 bool로 변환하거나 그대로 전달 등 상황에 맞게)
                      'isAllDay': scheduleInfo['cureScheduleDayYn'] == 'Y',
                      // ▼ [핵심] 환자 정보 및 일정 유형 전달
                      // 백엔드 데이터에 'patientId' 필드가 있는지 꼭 확인하세요!
                      'patient_id': schedule['patientSeq'] ?? schedule['patientId'] ?? 0,
                      // 큐어룸 정보 (필요 시)
                      'cure_seq': schedule['cureSeq'] ?? navProvider.cureSeq,
                      // 일정 유형 (예: '진료', '복약' 등 텍스트가 정확해야 칩이 선택됨)
                      'schedule_type': _mapCodeToLabel(schedule['cureCalendarTypeCmcd']),
                    };

                    // [중요] 2. 수정 페이지로 이동
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => NewScheduleScreen(
                          selectedDateFromPreviousScreen: _selectedDay ?? DateTime.now(),
                          existingSchedule: mappedSchedule, // 변환된 데이터 전달
                        ),
                      ),
                    ).then((result) {
                      // 3. 수정 후 돌아왔을 때 목록 새로고침 (저장이 완료되면 true 반환됨)
                      if (result == true) {
                        _fetchMonthlySchedules(_focusedDay);
                      }
                    });
                  },
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.grey[50],
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey[200]!),
                    ),
                    child: Row(
                      children: [
                        // 왼쪽 아이콘 박스
                        Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            color: AppColors.lightBackground, // 연한 배경색
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(
                            _getIconForType(schedule['cureCalendarTypeCmcd']),
                            color: AppColors.mainBtn, // 포인트 색상
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: 16),

                        // 가운데 텍스트 (제목 & 시간)
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                schedule['cureCalendarNm'] ?? '제목 없음',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                  color: Colors.black87,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                startTime.isNotEmpty
                                    ? _formatTime(startTime)
                                    : '하루 종일',
                                style: const TextStyle(
                                  color: AppColors.darkBlue,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),

                        // 오른쪽 화살표 (선택 사항)
                        const Icon(
                          Icons.chevron_right,
                          color: Colors.grey,
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          final DateTime targetDate = _selectedDay ?? _focusedDay;
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => NewScheduleScreen(selectedDateFromPreviousScreen: targetDate),
            ),
          ).then((_) {
            // 돌아왔을 때 데이터 갱신 (일정 추가 후 목록 업데이트)
            _fetchMonthlySchedules(_focusedDay);
          });
        },
        backgroundColor: AppColors.mainBtn,
        shape: const CircleBorder(),
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}