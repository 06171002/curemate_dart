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
        shouldFillViewport: true,
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

        // ✅ [수정] 마커(점) 커스터마이징: 일정이 있으면 무조건 점 1개만 표시
        calendarBuilders: CalendarBuilders(
          markerBuilder: (context, date, events) {
            if (events.isNotEmpty) {
              return Positioned(
                bottom: 1,
                child: Container(
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.activeColor, // 또는 원하는 색상 (예: redAccent)
                  ),
                  width: 6.0,
                  height: 6.0,
                ),
              );
            }
            return null;
          },
          // 2. [추가] 오늘 날짜 동그라미 크기 조절
          todayBuilder: (context, date, _) {
            return Center(
              child: Container(
                width: 32.0, // 👈 여기서 크기를 조절하세요 (기본값보다 작게 설정됨)
                height: 32.0,
                decoration: BoxDecoration(
                  color: AppColors.mainBtn.withOpacity(0.5),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    '${date.day}',
                    style: const TextStyle(fontSize: 14.0, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            );
          },

          // 3. [추가] 선택된 날짜 동그라미 크기 조절
          selectedBuilder: (context, date, _) {
            return Center(
              child: Container(
                width: 32.0, // 👈 여기서 크기를 조절하세요
                height: 32.0,
                decoration: const BoxDecoration(
                  color: AppColors.mainBtn,
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    '${date.day}',
                    style: const TextStyle(fontSize: 14.0, color: Colors.white),
                  ),
                ),
              ),
            );
          },
        ),

        // 스타일 설정 (기존 코드 유지 및 보완)
        daysOfWeekStyle: const DaysOfWeekStyle(
          weekendStyle: TextStyle(color: Colors.red, fontSize: 14),
          weekdayStyle: TextStyle(fontSize: 14),
        ),
        calendarStyle: CalendarStyle(
          defaultTextStyle: const TextStyle(fontSize: 14),
          weekendTextStyle: const TextStyle(fontSize: 14, color: Colors.red),
          todayTextStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
          selectedTextStyle: const TextStyle(fontSize: 14, color: Colors.white),
          cellMargin: const EdgeInsets.all(4.0),

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