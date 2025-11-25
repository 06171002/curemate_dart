import 'package:flutter/material.dart';

class BottomNavProvider with ChangeNotifier {
  int _currentIndex = 0;

  // 모드 상태 관리 (null이면 메인 모드, 값이 있으면 환자 모드)
  int? _patientId;
  Map<String, dynamic>? _patientInfo; // 선택된 환자 정보 (이름, 성별 등)

  int get currentIndex => _currentIndex;
  int? get patientId => _patientId;
  Map<String, dynamic>? get patientInfo => _patientInfo;

  // 현재 모드 확인 Helper
  bool get isMainMode => _patientId == null;
  bool get isPatientMode => _patientId != null;

  // 탭 변경 (순수하게 인덱스만 변경)
  void changeIndex(int index) {
    _currentIndex = index;
    notifyListeners();
  }

  // 환자 선택 (모드 전환)
  void selectPatient(int id, Map<String, dynamic> info) {
    _patientId = id;
    _patientInfo = info;
    notifyListeners();
  }

  // 메인 모드로 복귀 (환자 정보 초기화)
  void clearPatient() {
    _patientId = null;
    _patientInfo = null;
    notifyListeners();
  }
}