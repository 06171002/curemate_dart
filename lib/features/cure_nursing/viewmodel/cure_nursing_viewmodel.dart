import 'package:curemate/utils/logger.dart';
import 'package:flutter/material.dart';
import 'package:curemate/app/theme/app_colors.dart';
import 'package:curemate/features/cure_nursing/model/nursing_model.dart';
import 'package:curemate/services/cure_nursing_service.dart';
// SDUI 추가
import 'package:curemate/common/sdui/model/sdui_model.dart';
import 'package:curemate/common/sdui/service/sdui_service.dart';
import 'package:curemate/common/sdui/controller/sdui_controller.dart';

class CureNursingViewModel with ChangeNotifier {
  final CureNursingService _nursingService = CureNursingService();
  final SduiService _sduiService = SduiService();

  // SDUI 입력 상태 관리 컨트롤러
  final SduiController sduiController = SduiController();

  // Step 1: 카테고리 목록
  List<NursingCategoryModel> _categories = [];
  List<NursingCategoryModel> get categories => _categories;
  bool _isLoadingCategories = false;
  bool get isLoadingCategories => _isLoadingCategories;

  // Step 2: SDUI 폼 노드
  SduiNode? _sduiRootNode;
  SduiNode? get sduiRootNode => _sduiRootNode;
  bool _isLoadingForm = false;
  bool get isLoadingForm => _isLoadingForm;

  // --- Step 1 관련 메서드 ---
  Future<void> fetchCategories() async {
    _isLoadingCategories = true;
    notifyListeners();
    try {
      _categories = await _nursingService.getCategoryList();
    } finally {
      _isLoadingCategories = false;
      notifyListeners();
    }
  }

  // --- Step 2 관련 메서드 ---
  Future<void> loadSduiForm(String categoryCode) async {
    _isLoadingForm = true;
    _sduiRootNode = null; // 이전 폼 제거
    sduiController.dispose(); // 이전 입력값 초기화 (필요시 새로 생성 로직 추가)
    notifyListeners();

    try {
      // 카테고리 코드(BP, BT 등)와 일치하는 화면(Screen)을 요청
      _sduiRootNode = await _sduiService.getScreen(categoryCode);
    } catch (e) {
      print("SDUI 폼 로드 실패: $e");
    } finally {
      _isLoadingForm = false;
      notifyListeners();
    }
  }

  void clearSduiData() {
    _sduiRootNode = null;
    notifyListeners();
  }

  Future<void> saveLog() async {
    if (_sduiRootNode == null) return;

    // 1. Controller에게 "서버용 데이터(변환된 데이터)를 줘"라고 요청
    //    내부적으로 [nodeKey -> dataKey] 매핑 및 [Nested Object] 변환 수행
    final Map<String, dynamic> payload = sduiController.getSubmitData(_sduiRootNode!);

    // 2. 변환된 최종 데이터 로그 출력
    Logger.i('============== [서버 전송 데이터 (Final)] ==============');
    if (payload.isEmpty) {
      Logger.w('전송할 유효 데이터가 없습니다. (입력값이 없거나 dataKey 매핑 누락)');
    } else {
      // 여기서 찍히는 로그가 실제 서버로 날아가는 구조와 동일합니다.
      Logger.json(payload, message: "Request Body");
    }
    Logger.i('====================================================');

    // 3. 실제 서버 전송 (주석 해제 후 사용)
    /*
    bool success = await _nursingService.saveLog(payload);
    if (success) {
      // 성공 처리
    }
    */
  }

  // 기존 아이콘 매핑 로직 유지 (flutter_iconpicker 고려 필요)
  IconData getIconForName(String? iconNm) {
    switch (iconNm) {
    // --- 대분류 아이콘 ---
      case 'monitor_heart': return Icons.monitor_heart; // 활력징후, 맥박
      case 'medication': return Icons.medication;       // 투약/처치, 필요시 투약
      case 'restaurant': return Icons.restaurant;       // 섭취, 식사
      case 'wc': return Icons.wc;                       // 배설
      case 'healing': return Icons.healing;             // 증상
      case 'directions_walk': return Icons.directions_walk; // 활동, 운동/재활

    // --- 중분류 (활력징후) ---
      case 'thermostat': return Icons.thermostat;       // 체온
      case 'favorite_border': return Icons.favorite_border; // 혈압
      case 'bloodtype': return Icons.bloodtype;         // 혈당
      case 'air': return Icons.air;                     // 산소포화도
      case 'monitor_weight': return Icons.monitor_weight; // 체중

    // --- 중분류 (투약) ---
      case 'alarm': return Icons.alarm;                 // 정기 투약
      case 'medical_services': return Icons.medical_services; // 의료 처치

    // --- 중분류 (섭취) ---
      case 'local_drink': return Icons.local_drink;     // 수분
      case 'set_meal': return Icons.set_meal;           // 간식/영양

    // --- 중분류 (배설) ---
      case 'water_drop': return Icons.water_drop;       // 소변
      case 'layers': return Icons.layers;               // 대변

    // --- 중분류 (증상) ---
      case 'mood_bad': return Icons.mood_bad;           // 통증
      case 'back_hand': return Icons.back_hand;         // 피부
      case 'psychology': return Icons.psychology;       // 심리/인지
      case 'edit_note': return Icons.edit_note;         // 기타 증상

    // --- 중분류 (활동) ---
      case 'bedtime': return Icons.bedtime;             // 수면
      case 'warning_amber': return Icons.warning_amber; // 사고

    // 기본값 (매핑 안 된 경우)
      default: return Icons.edit;
    }
  }
}