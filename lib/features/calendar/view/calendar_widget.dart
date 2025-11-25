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
        calendarStyle: CalendarStyle(
          todayDecoration: BoxDecoration(
            color: primaryColor.withOpacity(0.3), // primaryColor 정의 필요
            shape: BoxShape.circle,
          ),
          selectedDecoration: BoxDecoration(
            color: primaryColor, // primaryColor 정의 필요
            shape: BoxShape.circle,
          ),
          defaultTextStyle: TextStyle(fontSize: 18),
          weekendTextStyle: TextStyle(fontSize: 18, color: Colors.red),
          todayTextStyle: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          selectedTextStyle: TextStyle(fontSize: 18, color: Colors.white),
        ),
        headerStyle: const HeaderStyle(
          formatButtonVisible: false,
          titleCentered: true,
          titleTextStyle: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}