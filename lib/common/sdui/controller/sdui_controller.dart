import 'package:flutter/material.dart';
import 'package:curemate/common/sdui/model/sdui_model.dart';

class SduiController {
  // 폼 데이터 저장소 (Key: node_key, Value: 입력값)
  final Map<String, dynamic> _formData = {};

  // 텍스트 필드용 컨트롤러 캐싱
  final Map<String, TextEditingController> _textControllers = {};

  // 데이터 가져오기 (Raw Data)
  Map<String, dynamic> get formData => _formData;

  // 값 업데이트
  void updateValue(String key, dynamic value) {
    _formData[key] = value;
  }

  // 텍스트 컨트롤러 가져오기
  TextEditingController getTextController(String key, {String initialValue = ''}) {
    if (!_textControllers.containsKey(key)) {
      _textControllers[key] = TextEditingController(text: initialValue);
      _textControllers[key]!.addListener(() {
        updateValue(key, _textControllers[key]!.text);
      });
    }
    return _textControllers[key]!;
  }

  // 리소스 해제
  void dispose() {
    for (var controller in _textControllers.values) {
      controller.dispose();
    }
    _textControllers.clear();
    _formData.clear();
  }

  // ===========================================================================
  // 데이터 변환 로직 (Client -> Server)
  // 입력된 Raw Data를 Server용 Data Key 구조(Nested 포함)로 변환하여 반환
  // ===========================================================================
  Map<String, dynamic> getSubmitData(SduiNode rootNode) {
    // 1. Key 매핑 정보 수집 (nodeKey -> dataKey)
    final Map<String, String> keyMap = {};
    _collectKeyMappings(rootNode, keyMap);

    // 2. 데이터 변환 (Flatten -> Nested & Mapped)
    final Map<String, dynamic> payload = {};

    _formData.forEach((nodeKey, value) {
      // dataKey가 정의된 필드만 변환 (없으면 해당 필드는 서버로 보내지 않음 or nodeKey 그대로 전송)
      // 여기서는 dataKey가 있는 것만 유효한 데이터로 간주합니다.
      if (keyMap.containsKey(nodeKey)) {
        final String serverKey = keyMap[nodeKey]!;
        _setNestedValue(payload, serverKey, value);
      }
    });

    return payload;
  }

  /// (내부 함수) 재귀적으로 노드를 돌면서 매핑 정보 수집
  void _collectKeyMappings(SduiNode node, Map<String, String> map) {
    if (node.nodeKey != null && node.dataBindingKey != null) {
      map[node.nodeKey!] = node.dataBindingKey!;
    }
    if (node.children != null) {
      for (var child in node.children!) {
        _collectKeyMappings(child, map);
      }
    }
  }

  /// (내부 함수) 점(.)으로 구분된 키를 구조화된 Map으로 변환 (Deep Merge)
  void _setNestedValue(Map<String, dynamic> map, String path, dynamic value) {
    List<String> keys = path.split('.');
    Map<String, dynamic> current = map;

    for (int i = 0; i < keys.length - 1; i++) {
      String key = keys[i];
      if (!current.containsKey(key) || current[key] is! Map) {
        current[key] = <String, dynamic>{};
      }
      current = current[key];
    }
    current[keys.last] = value;
  }
}