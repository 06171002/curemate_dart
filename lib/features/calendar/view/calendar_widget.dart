import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:curemate/app/theme/app_colors.dart'; // 색상 정의 파일

class CalendarWidget extends StatelessWidget {
  final Function(DateTime, DateTime) onDaySelected;
  final Function(DateTime) onPageChanged; // [추가] 월 변경 시 부모에게 알림
  final DateTime focusedDay;
  final DateTime? selectedDay;
  final CalendarFormat calendarFormat;
  final Map<DateTime, List<Map<String, dynamic>>> events; // [추가] 외부에서 받는 이벤트 데이터

  const CalendarWidget({
    Key? key,
    required this.onDaySelected,
    required this.onPageChanged,
    required this.focusedDay,
    this.selectedDay,
    required this.calendarFormat,
    required this.events,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOut,
      color: Colors.white, // 배경색
      child: TableCalendar(
        firstDay: DateTime(2000),
        lastDay: DateTime(2100),
        focusedDay: focusedDay,
        daysOfWeekHeight: 30.0,
        selectedDayPredicate: (day) => isSameDay(selectedDay, day),
        onDaySelected: onDaySelected,
        onPageChanged: onPageChanged, // 월 변경 시 호출
        locale: 'ko_KR',
        calendarFormat: calendarFormat,

        // [이벤트 로더] 부모로부터 받은 events 맵을 사용하여 점 표시
        eventLoader: (day) {
          // 시/분/초를 제거한 날짜 키 생성
          final key = DateTime(day.year, day.month, day.day);
          return events[key] ?? [];
        },

        // 스타일 설정 (기존 코드 유지 및 보완)
        daysOfWeekStyle: const DaysOfWeekStyle(
          weekendStyle: TextStyle(color: Colors.red, fontSize: 14),
          weekdayStyle: TextStyle(fontSize: 14),
        ),
        calendarStyle: CalendarStyle(
          todayDecoration: BoxDecoration(
            color: AppColors.mainBtn.withOpacity(0.5), // AppColors 사용 권장
            shape: BoxShape.circle,
          ),
          selectedDecoration: const BoxDecoration(
            color: AppColors.mainBtn,
            shape: BoxShape.circle,
          ),
          defaultTextStyle: const TextStyle(fontSize: 14),
          weekendTextStyle: const TextStyle(fontSize: 14, color: Colors.red),
          todayTextStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
          selectedTextStyle: const TextStyle(fontSize: 14, color: Colors.white),
          cellMargin: const EdgeInsets.all(4.0),

          // 마커(점) 스타일
          markerDecoration: const BoxDecoration(
            color: Colors.redAccent, // 점 색상
            shape: BoxShape.circle,
          ),
        ),
        headerStyle: const HeaderStyle(
          formatButtonVisible: false,
          titleCentered: true,
          titleTextStyle: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}