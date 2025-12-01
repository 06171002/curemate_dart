import 'package:flutter/material.dart';

class CureRoomTab extends StatelessWidget {
  const CureRoomTab({super.key});

  @override
  Widget build(BuildContext context) {
    // TODO: 큐어룸 기능 구현
    return Container(
      color: Colors.white,
      child: const Center(
        child: Text(
          "🏥 큐어룸 (준비중)",
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.grey),
        ),
      ),
    );
  }
}
