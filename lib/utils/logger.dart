// lib/utils/logger.dart

import 'package:flutter/foundation.dart';
import 'dart:convert';

/// 앱 전체에서 사용할 로거 유틸리티
///
/// 사용 예시:
/// ```dart
/// Logger.d('디버그 메시지');
/// Logger.i('정보 메시지');
/// Logger.w('경고 메시지');
/// Logger.e('에러 메시지', error: e, stackTrace: stackTrace);
/// Logger.json({'key': 'value'});
/// ```
class Logger {
  Logger._();

  /// Release 모드에서 로그 출력 여부
  static bool enableInRelease = false;

  /// 로그 출력 여부 확인
  static bool get _isEnabled {
    return kDebugMode || enableInRelease;
  }

  // ═══════════════════════════════════════════════════════════
  // 기본 로그 메서드
  // ═══════════════════════════════════════════════════════════

  /// 디버그 로그 (파란색)
  /// 개발 중 상세한 정보 추적용
  static void d(
      String message, {
        String? tag,
        dynamic data,
      }) {
    if (!_isEnabled) return;
    _log(
      level: LogLevel.debug,
      message: message,
      tag: tag,
      data: data,
    );
  }

  /// 정보 로그 (초록색)
  /// 일반적인 정보성 메시지
  static void i(
      String message, {
        String? tag,
        dynamic data,
      }) {
    if (!_isEnabled) return;
    _log(
      level: LogLevel.info,
      message: message,
      tag: tag,
      data: data,
    );
  }

  /// 경고 로그 (노란색)
  /// 주의가 필요한 상황
  static void w(
      String message, {
        String? tag,
        dynamic data,
      }) {
    if (!_isEnabled) return;
    _log(
      level: LogLevel.warning,
      message: message,
      tag: tag,
      data: data,
    );
  }

  /// 에러 로그 (빨간색)
  /// 에러 발생 시 사용
  static void e(
      String message, {
        String? tag,
        Object? error,
        StackTrace? stackTrace,
        dynamic data,
      }) {
    if (!_isEnabled) return;
    _log(
      level: LogLevel.error,
      message: message,
      tag: tag,
      error: error,
      stackTrace: stackTrace,
      data: data,
    );
  }

  // ═══════════════════════════════════════════════════════════
  // 특수 로그 메서드
  // ═══════════════════════════════════════════════════════════

  /// JSON 데이터 로그 (보기 좋게 포맷팅)
  static void json(
      dynamic data, {
        String? message,
        String? tag,
      }) {
    if (!_isEnabled) return;

    try {
      final encoder = JsonEncoder.withIndent('  ');
      final jsonString = encoder.convert(data);

      final header = message != null ? '$message\n' : '';
      _log(
        level: LogLevel.debug,
        message: '${header}JSON Data:',
        tag: tag,
        data: jsonString,
      );
    } catch (e) {
      _log(
        level: LogLevel.error,
        message: 'JSON 변환 실패',
        tag: tag,
        error: e,
        data: data.toString(),
      );
    }
  }

  /// HTTP 요청 로그
  static void httpRequest({
    required String method,
    required String url,
    Map<String, dynamic>? headers,
    dynamic body,
    String? tag,
  }) {
    if (!_isEnabled) return;

    final buffer = StringBuffer();
    buffer.writeln('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    buffer.writeln('🌐 HTTP REQUEST');
    buffer.writeln('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    buffer.writeln('Method: $method');
    buffer.writeln('URL: $url');

    if (headers != null && headers.isNotEmpty) {
      buffer.writeln('\nHeaders:');
      headers.forEach((key, value) {
        buffer.writeln('  $key: $value');
      });
    }

    if (body != null) {
      buffer.writeln('\nBody:');
      try {
        final encoder = JsonEncoder.withIndent('  ');
        final jsonString = encoder.convert(body);
        buffer.writeln(jsonString);
      } catch (e) {
        buffer.writeln(body.toString());
      }
    }

    buffer.writeln('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');

    _printLog(buffer.toString(), LogLevel.info, tag);
  }

  /// HTTP 응답 로그
  static void httpResponse({
    required int statusCode,
    required String url,
    Map<String, dynamic>? headers,
    dynamic body,
    Duration? duration,
    String? tag,
  }) {
    if (!_isEnabled) return;

    final buffer = StringBuffer();
    buffer.writeln('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    buffer.writeln('📥 HTTP RESPONSE');
    buffer.writeln('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    buffer.writeln('Status: $statusCode');
    buffer.writeln('URL: $url');

    if (duration != null) {
      buffer.writeln('Duration: ${duration.inMilliseconds}ms');
    }

    if (headers != null && headers.isNotEmpty) {
      buffer.writeln('\nHeaders:');
      headers.forEach((key, value) {
        buffer.writeln('  $key: $value');
      });
    }

    if (body != null) {
      buffer.writeln('\nBody:');
      try {
        final encoder = JsonEncoder.withIndent('  ');
        final jsonString = encoder.convert(body);
        buffer.writeln(jsonString);
      } catch (e) {
        buffer.writeln(body.toString());
      }
    }

    buffer.writeln('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');

    final level = statusCode >= 200 && statusCode < 300
        ? LogLevel.info
        : LogLevel.error;

    _printLog(buffer.toString(), level, tag);
  }

  /// 구분선 출력
  static void divider({String? message}) {
    if (!_isEnabled) return;

    final msg = message != null ? ' $message ' : '';
    final line = '━' * ((80 - msg.length) ~/ 2);
    debugPrint('$line$msg$line');
  }

  /// 섹션 시작
  static void section(String title) {
    if (!_isEnabled) return;

    debugPrint('\n┌${'─' * 78}┐');
    debugPrint('│ $title');
    debugPrint('└${'─' * 78}┘');
  }

  /// 섹션 종료
  static void sectionEnd() {
    if (!_isEnabled) return;
    debugPrint('${'─' * 80}\n');
  }

  // ═══════════════════════════════════════════════════════════
  // 내부 메서드
  // ═══════════════════════════════════════════════════════════

  static void _log({
    required LogLevel level,
    required String message,
    String? tag,
    Object? error,
    StackTrace? stackTrace,
    dynamic data,
  }) {
    final buffer = StringBuffer();

    // 아이콘과 레벨
    buffer.write(_getIcon(level));
    buffer.write(' ');

    // 태그
    if (tag != null) {
      buffer.write('[$tag] ');
    }

    // 메시지
    buffer.write(message);

    // 데이터
    if (data != null) {
      buffer.write('\n');
      if (data is String && data.length > 1000) {
        // 긴 문자열은 잘라서 표시
        buffer.write(data.substring(0, 1000));
        buffer.write('... (${data.length} characters)');
      } else {
        buffer.write(data);
      }
    }

    // 에러
    if (error != null) {
      buffer.write('\n');
      buffer.write('Error: $error');
    }

    // 스택 트레이스
    if (stackTrace != null) {
      buffer.write('\n');
      buffer.write('StackTrace:\n$stackTrace');
    }

    _printLog(buffer.toString(), level, tag);
  }

  static void _printLog(String message, LogLevel level, String? tag) {
    // ANSI 색상 코드 적용 (Android Studio, VS Code 터미널에서 작동)
    final coloredMessage = _applyColor(message, level);

    // 긴 메시지는 여러 줄로 분할 (Android Logcat 제한)
    final lines = coloredMessage.split('\n');
    for (final line in lines) {
      if (line.length <= 800) {
        debugPrint(line);
      } else {
        // 800자 이상이면 분할
        var start = 0;
        while (start < line.length) {
          final end = (start + 800).clamp(0, line.length);
          debugPrint(line.substring(start, end));
          start = end;
        }
      }
    }
  }

  static String _getIcon(LogLevel level) {
    switch (level) {
      case LogLevel.debug:
        return '🔍';
      case LogLevel.info:
        return '✅';
      case LogLevel.warning:
        return '⚠️';
      case LogLevel.error:
        return '❌';
    }
  }

  static String _applyColor(String message, LogLevel level) {
    if (!kDebugMode) return message;

    const reset = '\x1B[0m';
    String color;

    switch (level) {
      case LogLevel.debug:
        color = '\x1B[34m'; // Blue
        break;
      case LogLevel.info:
        color = '\x1B[32m'; // Green
        break;
      case LogLevel.warning:
        color = '\x1B[33m'; // Yellow
        break;
      case LogLevel.error:
        color = '\x1B[31m'; // Red
        break;
    }

    return '$color$message$reset';
  }
}

/// 로그 레벨
enum LogLevel {
  debug,
  info,
  warning,
  error,
}

// ═══════════════════════════════════════════════════════════
// 확장 메서드
// ═══════════════════════════════════════════════════════════

/// Object 확장 - 편리한 로깅
extension LoggableObject on Object {
  /// 이 객체를 로그로 출력
  void log({String? message, String? tag}) {
    Logger.d(
      message ?? toString(),
      tag: tag,
      data: this,
    );
  }

  /// 이 객체를 JSON 형태로 로그 출력
  void logJson({String? message, String? tag}) {
    Logger.json(
      this,
      message: message,
      tag: tag,
    );
  }
}

/// String 확장 - 편리한 로깅
extension LoggableString on String {
  /// 디버그 로그
  void logDebug({String? tag}) => Logger.d(this, tag: tag);

  /// 정보 로그
  void logInfo({String? tag}) => Logger.i(this, tag: tag);

  /// 경고 로그
  void logWarning({String? tag}) => Logger.w(this, tag: tag);

  /// 에러 로그
  void logError({String? tag, Object? error, StackTrace? stackTrace}) {
    Logger.e(this, tag: tag, error: error, stackTrace: stackTrace);
  }
}