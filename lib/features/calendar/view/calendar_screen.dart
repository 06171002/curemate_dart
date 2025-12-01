import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:curemate/app/theme/app_colors.dart'; // 색상 사용을 위해 import
import 'package:curemate/features/calendar/view/calendar_widget.dart';
// 일정 추가 화면 import (파일명이 new_schedule_screen.dart라면 그에 맞게 수정)
import 'package:curemate/features/calendar/view/new_schedule_screen.dart';

class CalendarScreen extends StatefulWidget {
  const CalendarScreen({super.key});

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  CalendarFormat _calendarFormat = CalendarFormat.month;

  @override
  Widget build(BuildContext context) {
    // Scaffold를 사용해야 floatingActionButton을 넣을 수 있습니다.
    return Scaffold(
      backgroundColor: Colors.white, // 배경색 명시
      body: Column(
        children: [
          CalendarWidget(
            focusedDay: _focusedDay,
            selectedDay: _selectedDay,
            calendarFormat: _calendarFormat,
            onDaySelected: (selectedDay, focusedDay) {
              setState(() {
                _selectedDay = selectedDay;
                _focusedDay = focusedDay;
              });
            },
          ),
          const Divider(height: 1, thickness: 1, color: Color(0xFFEEEEEE)),
          // 하단 리스트 영역
          Expanded(
            child: Center(
              child: Text(
                _selectedDay != null
                    ? "${_selectedDay!.month}월 ${_selectedDay!.day}일 일정 없음"
                    : "날짜를 선택해주세요.",
                style: const TextStyle(color: Colors.grey, fontSize: 16),
              ),
            ),
          ),
        ],
      ),

      // ✅ [핵심] 우측 하단 + 버튼 추가
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          final DateTime targetDate = _selectedDay ?? _focusedDay;
          // 버튼 클릭 시 일정 추가 페이지로 이동
          Navigator.push(
            context,
            MaterialPageRoute(
              // 파일명에 맞는 클래스를 사용하세요 (AddScheduleScreen 혹은 NewScheduleScreen)
              builder: (context) => NewScheduleScreen(selectedDateFromPreviousScreen: targetDate,),
            ),
          );
        },
        backgroundColor: AppColors.mainBtn, // 앱 테마 색상 (보라색)
        shape: const CircleBorder(),        // 원형 모양
        elevation: 4,                       // 그림자 효과
        child: const Icon(Icons.add, color: Colors.white, size: 28), // + 아이콘
      ),
    );
  }
}