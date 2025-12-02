import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:curemate/app/theme/app_colors.dart';
import 'package:curemate/features/calendar/view/calendar_widget.dart';
import 'package:curemate/features/calendar/view/new_schedule_screen.dart';
import 'package:curemate/services/calendar_service.dart';

class CalendarScreen extends StatefulWidget {
  const CalendarScreen({super.key});

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  CalendarFormat _calendarFormat = CalendarFormat.month;

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
    // 1. 서비스 호출 (custSeq 전달)
    final schedules = await _calendarService.getMonthlyScheduleList(
      date,
    );

    if (!mounted) return;

    setState(() {
      _events.clear();

      for (var schedule in schedules) {
        // 2. 날짜 파싱 및 매핑
        // *주의*: 백엔드 응답 구조에 따라 키 이름('regDttm' vs 'scheduleStartDttm') 확인 필수
        // 여기서는 임시로 regDttm을 사용하거나, 현재 로직을 유지합니다.
        DateTime? evtDate;

        // 예시: 스케줄 시작 시간이 있다면 그것을 우선 사용
        if (schedule['cureScheduleStartDttm'] != null) {
          evtDate = DateTime.parse(schedule['cureScheduleStartDttm']);
        } else if (schedule['regDttm'] != null) {
          evtDate = DateTime.parse(schedule['regDttm']);
        }

        if (evtDate != null) {
          // 시간 정보를 제거하여 Key로 사용 (2025-12-02 00:00:00.000)
          final key = DateTime(evtDate.year, evtDate.month, evtDate.day);

          if (_events[key] == null) _events[key] = [];
          _events[key]!.add(schedule);
        }
      }
    });
  }

  // 선택된 날짜의 일정 리스트 가져오기
  List<Map<String, dynamic>> _getEventsForDay(DateTime day) {
    final key = DateTime(day.year, day.month, day.day);
    return _events[key] ?? [];
  }

  @override
  Widget build(BuildContext context) {
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
                return Container(
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
                        schedule['cureCalendarNm'] ?? '제목 없음', // 제목 필드명 확인
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        schedule['cureCalendarDesc'] ?? '',
                        style: const TextStyle(color: Colors.grey, fontSize: 14),
                      ),
                    ],
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