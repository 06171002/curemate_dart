import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import '../utils/logger.dart';

class DeviceService {
  static final DeviceService _instance = DeviceService._internal();
  factory DeviceService() => _instance;
  DeviceService._internal();

  static const String _deviceIdKey = 'device_uuid';

  /// 저장된 UUID(deviceId)를 가져오거나, 없으면 새로 생성하여 저장 후 반환
  Future<String> getDeviceId() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      String? deviceId = prefs.getString(_deviceIdKey);

      if (deviceId == null) {
        // UUID v4 생성
        var uuid = const Uuid();
        deviceId = uuid.v4();

        // 저장
        await prefs.setString(_deviceIdKey, deviceId);
        Logger.i('새로운 Device ID 생성됨: $deviceId', tag: 'DEVICE');
      } else {
        Logger.d('기존 Device ID 로드됨: $deviceId', tag: 'DEVICE');
      }

      return deviceId;
    } catch (e) {
      Logger.e('Device ID 처리 중 오류 발생', tag: 'DEVICE', error: e);
      // 오류 발생 시 임시로 랜덤 UUID 반환 (저장은 실패하더라도 진행 차단 방지)
      return const Uuid().v4();
    }
  }
}