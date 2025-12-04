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

    setState(() {
      _events.clear();

      for (var data in schedules) {
        // 백엔드에서 내려준 구조에 따라 schedule 객체 접근
        final scheduleInfo = data['schedule'];

        DateTime? evtDate;

        // 날짜 파싱 로직
        if (scheduleInfo != null && scheduleInfo['cureScheduleStartDttm'] != null) {
          evtDate = DateTime.parse(scheduleInfo['cureScheduleStartDttm']);
        } else if (data['regDttm'] != null) {
          // 스케줄 정보가 없을 때 예외처리
          evtDate = DateTime.parse(data['regDttm']);
        }

        if (evtDate != null) {
          // 시간 정보를 제거하여 Key로 사용 (yyyy-MM-dd 00:00:00)
          final key = DateTime(evtDate.year, evtDate.month, evtDate.day);

          if (_events[key] == null) _events[key] = [];
          _events[key]!.add(data);
        }
      }
    });
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
      backgroundColor: Colors.white,
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

          const Divider(height: 1, thickness: 1, color: Color(0xFFEEEEEE)),

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

                return GestureDetector(
                  onTap: () {
                    // [중요] 1. CalendarScreen의 데이터를 NewScheduleScreen 형식에 맞게 변환
                    final scheduleInfo = schedule['schedule'] ?? {};

                    // 날짜/시간 문자열 파싱 (예: "2025-05-05 14:00:00")
                    String startFullDttm = scheduleInfo['cureScheduleStartDttm'] ?? '';
                    String endFullDttm = scheduleInfo['cureScheduleEndDttm'] ?? '';

                    // 날짜와 시간을 분리 (데이터 형식이 "yyyy-MM-dd HH:mm:ss"라고 가정)
                    String startDate = startFullDttm.length >= 10 ? startFullDttm.substring(0, 10) : '';
                    String startTime = startFullDttm.length > 16 ? startFullDttm.substring(11, 16) : '00:00';
                    String endDate = endFullDttm.length >= 10 ? endFullDttm.substring(0, 10) : '';
                    String endTime = endFullDttm.length > 16 ? endFullDttm.substring(11, 16) : '00:00';

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
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          schedule['cureCalendarNm'] ?? '제목 없음',
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          schedule['cureCalendarDesc'] ?? '',
                          style: const TextStyle(color: Colors.grey, fontSize: 14),
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