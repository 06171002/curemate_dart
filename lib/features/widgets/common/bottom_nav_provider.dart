import 'package:flutter/material.dart';
import 'package:curemate/features/cure_room/model/curer_model.dart'; // 모델 import

class BottomNavProvider with ChangeNotifier {
  int _currentIndex = 0;

  // 모드 상태 관리 (null이면 메인 모드, 값이 있으면 큐어룸 모드)
  CurerModel? _selectedCurer;

  int get currentIndex => _currentIndex;
  CurerModel? get selectedCurer => _selectedCurer;

  // 편의용 getter
  int? get cureSeq => _selectedCurer?.cureSeq;
  String? get cureName => _selectedCurer?.cureNm;

  // 현재 모드 확인 Helper
  bool get isMainMode => _selectedCurer == null;
  bool get isCureMode => _selectedCurer != null;

  // ✅ [추가] 데이터 변경 감지용 변수
  DateTime _lastScheduleUpdate = DateTime.now();
  DateTime get lastScheduleUpdate => _lastScheduleUpdate;

  // ✅ [추가] 갱신 알림 메서드
  void notifyScheduleUpdate() {
    _lastScheduleUpdate = DateTime.now();
    notifyListeners(); // 이걸 호출하면 이 Provider를 보고 있는 모든 화면이 rebuild 됨
  }

  // 탭 변경 (순수하게 인덱스만 변경)
  void changeIndex(int index) {
    _currentIndex = index;
    notifyListeners();
  }

  // 큐어룸 선택 (모드 전환)
  void selectCurer(CurerModel curer) {
    _selectedCurer = curer;
    notifyListeners();
  }

  // 메인 모드로 복귀 (큐어룸 정보 초기화)
  void clearCurer() {
    _selectedCurer = null;
    notifyListeners();
  }

  void reset() {
    _currentIndex = 0;
    _selectedCurer = null;
    notifyListeners();
  }
}