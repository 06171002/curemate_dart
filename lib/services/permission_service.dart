// lib/services/permission_service.dart

import 'package:permission_handler/permission_handler.dart';
import '../utils/logger.dart';

/// 앱 권한 관리 서비스
class PermissionService {
  static final PermissionService _instance = PermissionService._internal();
  factory PermissionService() => _instance;
  PermissionService._internal();

  /// 필수 권한 목록
  static const List<Permission> _requiredPermissions = [
    Permission.camera,
    Permission.microphone,
    Permission.photos,
    Permission.notification,
  ];

  /// 선택 권한 목록 (추후 추가 가능)
  static const List<Permission> _optionalPermissions = [
    // Permission.location,
    // Permission.bluetooth,
  ];

  /// 모든 필수 권한이 승인되었는지 확인
  Future<bool> areAllRequiredPermissionsGranted() async {
    Logger.d('필수 권한 상태 확인', tag: 'PERMISSION');

    for (final permission in _requiredPermissions) {
      final status = await permission.status;
      Logger.d(
        '${_getPermissionName(permission)}: ${status.name}',
        tag: 'PERMISSION',
      );

      if (!status.isGranted) {
        Logger.w(
          '${_getPermissionName(permission)} 권한이 거부됨',
          tag: 'PERMISSION',
        );
        return false;
      }
    }

    Logger.i('✅ 모든 필수 권한 승인됨', tag: 'PERMISSION');
    return true;
  }

  /// 필수 권한 요청
  Future<Map<Permission, PermissionStatus>> requestRequiredPermissions() async {
    Logger.section('필수 권한 요청');

    try {
      final statuses = await _requiredPermissions.request();

      Logger.d('권한 요청 결과:', tag: 'PERMISSION');
      statuses.forEach((permission, status) {
        Logger.d(
          '  ${_getPermissionName(permission)}: ${status.name}',
          tag: 'PERMISSION',
        );
      });

      Logger.sectionEnd();
      return statuses;
    } catch (e, stackTrace) {
      Logger.e(
        '권한 요청 실패',
        tag: 'PERMISSION',
        error: e,
        stackTrace: stackTrace,
      );
      Logger.sectionEnd();
      rethrow;
    }
  }

  /// 개별 권한 요청
  Future<PermissionStatus> requestPermission(Permission permission) async {
    Logger.d('${_getPermissionName(permission)} 권한 요청', tag: 'PERMISSION');

    try {
      final status = await permission.request();
      Logger.i(
        '${_getPermissionName(permission)} 권한 결과: ${status.name}',
        tag: 'PERMISSION',
      );
      return status;
    } catch (e, stackTrace) {
      Logger.e(
        '${_getPermissionName(permission)} 권한 요청 실패',
        tag: 'PERMISSION',
        error: e,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }

  /// 권한 상태 확인
  Future<PermissionStatus> checkPermission(Permission permission) async {
    return await permission.status;
  }

  /// 앱 설정 열기
  Future<bool> openAppSettings() async {
    Logger.d('앱 설정 화면 열기', tag: 'PERMISSION');
    return await openAppSettings();
  }

  /// 권한이 영구 거부되었는지 확인
  Future<bool> isPermissionPermanentlyDenied(Permission permission) async {
    final status = await permission.status;
    return status.isPermanentlyDenied;
  }

  /// 필수 권한 목록 반환
  List<PermissionInfo> getRequiredPermissions() {
    return _requiredPermissions.map((permission) {
      return PermissionInfo(
        permission: permission,
        name: _getPermissionName(permission),
        description: _getPermissionDescription(permission),
        icon: _getPermissionIcon(permission),
      );
    }).toList();
  }

  /// 선택 권한 목록 반환
  List<PermissionInfo> getOptionalPermissions() {
    return _optionalPermissions.map((permission) {
      return PermissionInfo(
        permission: permission,
        name: _getPermissionName(permission),
        description: _getPermissionDescription(permission),
        icon: _getPermissionIcon(permission),
      );
    }).toList();
  }

  /// 모든 권한 상태 출력 (디버깅용)
  Future<void> printAllPermissionStatus() async {
    Logger.section('모든 권한 상태');

    for (final permission in [..._requiredPermissions, ..._optionalPermissions]) {
      final status = await permission.status;
      Logger.d(
        '${_getPermissionName(permission)}: ${status.name}',
        tag: 'PERMISSION',
      );
    }

    Logger.sectionEnd();
  }

  // ═══════════════════════════════════════════════════════════
  // Private Helper Methods
  // ═══════════════════════════════════════════════════════════

  /// 권한 이름 반환
  String _getPermissionName(Permission permission) {
    if (permission == Permission.camera) return '카메라';
    if (permission == Permission.microphone) return '마이크';
    if (permission == Permission.photos) return '사진';
    if (permission == Permission.location) return '위치';
    if (permission == Permission.locationWhenInUse) return '위치 (사용 중)';
    if (permission == Permission.locationAlways) return '위치 (항상)';
    if (permission == Permission.bluetooth) return '블루투스';
    if (permission == Permission.bluetoothConnect) return '블루투스 연결';
    if (permission == Permission.notification) return '알림';
    if (permission == Permission.contacts) return '연락처';
    if (permission == Permission.storage) return '저장공간';
    return permission.toString().replaceAll('Permission.', '');
  }

  /// 권한 설명 반환
  String _getPermissionDescription(Permission permission) {
    if (permission == Permission.camera) {
      return '건강 기록 사진 촬영을 위해 필요합니다';
    }
    if (permission == Permission.microphone) {
      return '음성 메모 녹음을 위해 필요합니다';
    }
    if (permission == Permission.photos) {
      return '건강 기록 사진을 저장하고 불러오기 위해 필요합니다';
    }
    if (permission == Permission.location ||
        permission == Permission.locationWhenInUse) {
      return '주변 병원 찾기를 위해 필요합니다';
    }
    if (permission == Permission.bluetooth ||
        permission == Permission.bluetoothConnect) {
      return '건강 기기 연결을 위해 필요합니다';
    }
    if (permission == Permission.notification) {
      return '건강 알림을 받기 위해 필요합니다';
    }
    if (permission == Permission.contacts) {
      return '응급 연락처 설정을 위해 필요합니다';
    }
    if (permission == Permission.storage) {
      return '건강 기록 저장을 위해 필요합니다';
    }
    return '앱 기능 사용을 위해 필요합니다';
  }

  /// 권한 아이콘 반환
  String _getPermissionIcon(Permission permission) {
    if (permission == Permission.camera) return '📷';
    if (permission == Permission.microphone) return '🎤';
    if (permission == Permission.photos) return '🖼️';
    if (permission == Permission.location ||
        permission == Permission.locationWhenInUse ||
        permission == Permission.locationAlways) return '📍';
    if (permission == Permission.bluetooth ||
        permission == Permission.bluetoothConnect) return '📡';
    if (permission == Permission.notification) return '🔔';
    if (permission == Permission.contacts) return '👥';
    if (permission == Permission.storage) return '💾';
    return '🔐';
  }
}

/// 권한 정보 모델
class PermissionInfo {
  final Permission permission;
  final String name;
  final String description;
  final String icon;

  PermissionInfo({
    required this.permission,
    required this.name,
    required this.description,
    required this.icon,
  });

  @override
  String toString() {
    return 'PermissionInfo(name: $name, description: $description)';
  }
}