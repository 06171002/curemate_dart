import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:curemate/features/widgets/common/widgets.dart';

class CalendarWidget extends StatefulWidget {
  final Function(DateTime?, DateTime) onDaySelected;
  final DateTime focusedDay;
  final DateTime? selectedDay;
  final CalendarFormat calendarFormat;

  const CalendarWidget({
    Key? key,
    required this.onDaySelected,
    required this.focusedDay,
    this.selectedDay,
    required this.calendarFormat,
  }) : super(key: key);

  @override
  State<CalendarWidget> createState() => _CalendarWidgetState();
}

class _CalendarWidgetState extends State<CalendarWidget> {
  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOut,
      color: Colors.white60,
      child: TableCalendar(
        firstDay: DateTime(2000),
        lastDay: DateTime(2100),
        focusedDay: widget.focusedDay,
        selectedDayPredicate: (day) => isSameDay(widget.selectedDay, day),
        onDaySelected: widget.onDaySelected,
        locale: 'ko_KR',
        calendarFormat: widget.calendarFormat,
        daysOfWeekStyle: const DaysOfWeekStyle(
          weekendStyle: TextStyle(color: Colors.red, fontSize: 14), // 폰트 크기 14로 축소
          weekdayStyle: TextStyle(fontSize: 14),
        ),

        // [수정 3] 날짜 부분 폰트 크기 축소 (18 -> 14~16 권장)
        calendarStyle: CalendarStyle(
          todayDecoration: BoxDecoration(
            color: primaryColor.withOpacity(0.3),
            shape: BoxShape.circle,
          ),
          selectedDecoration: BoxDecoration(
            color: primaryColor,
            shape: BoxShape.circle,
          ),
          // 폰트 크기를 18에서 14~15 정도로 줄여야 작은 폰에서도 안 잘립니다.
          defaultTextStyle: const TextStyle(fontSize: 14),
          weekendTextStyle: const TextStyle(fontSize: 14, color: Colors.red),
          todayTextStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
          selectedTextStyle: const TextStyle(fontSize: 14, color: Colors.white),

          // 셀 내부 여백 조정 (글자가 클 경우 여백 때문에 잘릴 수 있음)
          cellMargin: const EdgeInsets.all(4.0),
        ),
        headerStyle: const HeaderStyle(
          formatButtonVisible: false,
          titleCentered: true,
          titleTextStyle: TextStyle(fontSize: 20, fontWeight: FontWeight.bold), // 헤더도 살짝 줄임
        ),
      ),
    );
  }
}