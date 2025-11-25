// lib/utils/hardware_checker.dart

import 'package:flutter/services.dart';
import 'logger.dart';

class HardwareChecker {
  static const MethodChannel _channel = MethodChannel('hardware_checker');

  /// 카메라가 있는지 확인
  static Future<bool> hasCamera() async {
    try {
      final result = await _channel.invokeMethod('hasCamera');
      Logger.d('카메라 하드웨어: ${result ? '있음' : '없음'}', tag: 'HARDWARE');
      return result as bool;
    } catch (e) {
      Logger.w('카메라 확인 실패, 있다고 가정', tag: 'HARDWARE');
      return true; // 기본값으로 있다고 가정
    }
  }

  /// 마이크가 있는지 확인
  static Future<bool> hasMicrophone() async {
    try {
      final result = await _channel.invokeMethod('hasMicrophone');
      Logger.d('마이크 하드웨어: ${result ? '있음' : '없음'}', tag: 'HARDWARE');
      return result as bool;
    } catch (e) {
      Logger.w('마이크 확인 실패, 있다고 가정', tag: 'HARDWARE');
      return true;
    }
  }
}