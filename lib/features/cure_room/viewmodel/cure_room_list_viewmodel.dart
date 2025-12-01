// lib/features/cure_room/viewmodel/cure_room_list_viewmodel.dart

import 'package:flutter/material.dart';
import 'package:curemate/services/cure_room_service.dart';
import 'package:curemate/features/cure_room/model/curer_model.dart';

class CureRoomListViewModel with ChangeNotifier {
  final CureRoomService _service = CureRoomService();

  List<CurerModel> _cureRooms = [];
  bool _isLoading = false;
  String? _errorMessage;

  List<CurerModel> get cureRooms => _cureRooms;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  // 목록 조회
  Future<void> fetchCureRooms() async {
    _isLoading = true;
    _errorMessage = null;
    // 데이터 변경 알림을 줄이면 빌드 최적화에 도움이 되지만, 로딩 표시를 위해 호출
    notifyListeners();

    try {
      // Service의 getCureRoomList가 List<CurerModel>을 반환하도록 수정되었거나,
      // 여기서 변환 로직을 수행해야 합니다.
      // (Service 업데이트 코드에서 List<dynamic>을 반환했다면 아래와 같이 변환)
      final result = await _service.getCureRoomList();
      _cureRooms = List<CurerModel>.from(result);
    } catch (e) {
      _errorMessage = "큐어룸 목록을 불러오는데 실패했습니다.";
      print('CureRoom List Error: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // 목록 초기화 (로그아웃 등 필요시)
  void clear() {
    _cureRooms = [];
    notifyListeners();
  }
}