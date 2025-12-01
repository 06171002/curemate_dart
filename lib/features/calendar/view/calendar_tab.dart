import 'package:flutter/material.dart';

class CalendarTab extends StatelessWidget {
  const CalendarTab({super.key});

  @override
  Widget build(BuildContext context) {
    // TODO: 캘린더 기능 구현
    return Container(
      color: Colors.white,
      child: const Center(
        child: Text(
          "📅 캘린더 (준비중)",
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.grey),
        ),
      ),
    );
  }
}
