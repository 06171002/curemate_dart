//  lib/services/calendar_service.dart

import 'package:dio/dio.dart';
import 'api_service.dart';
import 'package:intl/intl.dart';
import 'package:curemate/features/calendar/model/calendar_model.dart';

class CalendarService {
  final ApiService _apiService;

  CalendarService() : _apiService = ApiService();

  // [통합] 일정 등록 및 수정 (mergeCalendarAll 호출)
  Future<void> saveSchedule(Map<String, dynamic> inputData) async {
    final String typeCode = _mapTypeToCode(inputData['scheduleType']);
    final String scheduleRepeatCode = _mapRepeatToScheduleType(inputData['repeatOption']);
    final String repeatYn = inputData['repeatOption'] == '반복 없음' ? 'N' : 'Y';

    // 시간 포맷팅
    String startDttm = "${inputData['startDate']} ${inputData['startTime']}:00";
    String endDttm = "${inputData['endDate']} ${inputData['endTime']}:00";

    if (inputData['isAllDay'] == true) {
      startDttm = "${inputData['startDate']} 00:00:00";
      endDttm = "${inputData['endDate']} 23:59:59";
    }

    // [핵심] 백엔드 VO 구조에 맞춘 Request Body 생성
    final Map<String, dynamic> requestBody = {
      "param": {
        // 수정일 경우 PK(cureCalendarSeq)가 있어야 함 (없으면 0)
        "cureCalendarSeq": inputData['cureCalendarSeq'] ?? 0,

        "patientSeq": inputData['patientId'],
        "cureCalendarTypeCmcd": typeCode,
        "cureCalendarNm": inputData['title'],
        "cureCalendarDesc": inputData['content'],
        "releaseYn": inputData['isPublic'] ? "Y" : "N",
        "cureSeq": inputData['cureSeq'],
        "cureScheduleDayYn": inputData['isAllDay'] ? "Y" : "N",

        // 상세 스케줄 정보
        "schedule": {
          "cureScheduleStartDttm": startDttm,
          "cureScheduleEndDttm": endDttm,
          "cureScheduleDayYn": inputData['isAllDay'] ? "Y" : "N",
          "cureScheduleRepeatYn": repeatYn,
          "cureScheduleTypeCmcd": scheduleRepeatCode
        },

        // 알람 정보
        "alrams": inputData['isAlarmOn'] ? [
          {
            "cureAlramDttm": _calculateAlarmTime(startDttm, inputData['alarmTime']),
            "cureAlramTypeCmcd": _mapAlarmType(inputData['alarmType'])
          }
        ] : []
      }
    };

    try {
      // 등록/수정 모두 이 엔드포인트 하나로 처리됨 (ID 유무로 백엔드가 판단)
      final response = await _apiService.post('/rest/calendar/mergeCalendarAll', data: requestBody);

      if (response.statusCode != 200) {
        throw Exception("일정 저장 실패: ${response.statusMessage}");
      }
    } catch (e) {
      print("Save Schedule Error: $e");
      rethrow;
    }
  }

  String _mapRepeatToScheduleType(String? option) {
    if (option == null) return 'daily'; // 기본값

    switch (option) {
      case '반복 없음':
      case '매일':
        return 'daily';
      case '매주':
        return 'weekly';
      case '매월':
        return 'monthly';
      case '매년':
        return 'yearly';
      default:
        return 'daily';
    }
  }

  // 일정 타입 매핑
  String _mapTypeToCode(String type) {
    switch (type) {
      case '진료': return 'treatment';
      case '복약': return 'medicine';
      case '검사': return 'test';
      case '기타': return 'etc';
      case 'personal': return 'personal';
      default: return 'etc';
    }
  }

  // 알람 타입 매핑 (필요하다면)
  String _mapAlarmType(String type) {
    // 서버 코드값에 맞춰 수정 (예: 푸시 -> push, SMS -> sms)
    if (type == '푸시') return 'push';
    if (type == 'SMS') return 'sms';
    if (type == '이메일') return 'email';
    return 'push';
  }

  String _calculateAlarmTime(String startDttmStr, String option) {
    try {
      DateTime startDttm = DateTime.parse(startDttmStr);
      Duration subtractDuration = const Duration(minutes: 0);

      if (option.contains('5분')) subtractDuration = const Duration(minutes: 5);
      else if (option.contains('10분')) subtractDuration = const Duration(minutes: 10);
      else if (option.contains('30분')) subtractDuration = const Duration(minutes: 30);
      else if (option.contains('1시간')) subtractDuration = const Duration(hours: 1);
      else if (option.contains('하루')) subtractDuration = const Duration(days: 1);

      DateTime alarmTime = startDttm.subtract(subtractDuration);

      // 서버 포맷에 맞게 반환 (yyyy-MM-dd HH:mm:ss)
      return DateFormat('yyyy-MM-dd HH:mm:ss').format(alarmTime);
    } catch (e) {
      print("알람 시간 계산 오류: $e");
      return startDttmStr; // 오류 시 시작 시간 그대로 반환
    }
  }

  // 일정조회
  Future<List<Map<String, dynamic>>> getSchedulesByDate(int patientId, DateTime date) async {
    // 1. DateTime 객체를 'yyyy-MM-dd' 형식의 문자열로 변환합니다.
    final dateString = DateFormat('yyyy-MM-dd').format(date);

    try {
      // 2. GET 요청에 쿼리 파라미터로 patientId와 date를 전달합니다.
      final String pathWithQuery = '/api/calendar/searchSchedule?patientId=$patientId&date=$dateString';
      final Response response = await _apiService.get(pathWithQuery);

      // 3. 응답 데이터가 List 형태일 것으로 예상하고 그대로 반환합니다.
      if (response.data is List) {
        return List<Map<String, dynamic>>.from(response.data);
      } else {
        // 예상치 못한 형식의 응답이 오면 빈 리스트를 반환합니다.
        return [];
      }
    } on DioException catch (dioErr) {
      final data = dioErr.response?.data;
      if (data is Map && data['error'] != null) {
        throw data['error'];
      }
      throw dioErr.message ?? '네트워크 오류가 발생했습니다.';
    } catch (e) {
      // 그 외 예외 처리
      print('일정 조회 중 알 수 없는 오류 발생: $e');
      throw '일정을 불러오는 데 실패했습니다.';
    }
  }

  // 일정수정
  Future<Map<String, dynamic>> updateSchedule(int scheduleSeq,Map<String, dynamic> updateSchedule) async {
    try {
      final Response response = await _apiService.post(
        '/api/calendar/updateSchedule/$scheduleSeq',
        data: updateSchedule,
      );

      // 정상 응답
      return response.data as Map<String, dynamic>;
    } on DioException catch (dioErr) {
      // 서버가 내려준 에러 메시지 추출
      final data = dioErr.response?.data;
      if (data is Map && data['error'] != null) {
        throw data['error']; // 👈 문자열만 던짐
      }
      throw dioErr.message ?? '네트워크 오류가 발생했습니다.';
    }
  }

  // 일정삭제
  Future<Map<String, dynamic>> deleteSchedule(int scheduleSeq) async {
    try {
      final Response response = await _apiService.delete(
          '/api/calendar/deleteSchedule/$scheduleSeq'
      );

      // 정상 응답
      return response.data as Map<String, dynamic>;
    } on DioException catch (dioErr) {
      // 서버가 내려준 에러 메시지 추출
      final data = dioErr.response?.data;
      if (data is Map && data['error'] != null) {
        throw data['error']; // 👈 문자열만 던짐
      }
      throw dioErr.message ?? '네트워크 오류가 발생했습니다.';
    }
  }

  // [추가] 월별 일정 목록 조회 (특정 사용자 필터링 가능)
  Future<List<Map<String, dynamic>>> getMonthlyScheduleList(DateTime date, {int? targetCustSeq}) async {
    // 1. "YYYYMM" 형식으로 변환 (Backend Mapper가 이 형식을 기대함)
    final String yearMonth = DateFormat('yyyyMM').format(date);

    // 2. 요청 파라미터 구성
    final Map<String, dynamic> requestBody = {
      "param": {
        "calendarMonth": yearMonth,
        // targetCustSeq가 있으면 onlyCustSeq로 전달하여 해당 유저의 일정만 필터링
        if (targetCustSeq != null) "onlyCustSeq": targetCustSeq,
      }
    };

    try {
      // 3. POST 요청 (/rest/calendar/selectCureCalendarList)
      final response = await _apiService.post('/rest/calendar/selectCureCalendarList', data: requestBody);

      // 4. 응답 처리 (ApiVo 구조에 따라 data 필드 추출)
      if (response.statusCode == 200 && response.data['data'] != null) {
        return List<Map<String, dynamic>>.from(response.data['data']);
      } else {
        return [];
      }
    } catch (e) {
      print('월별 일정 조회 실패: $e');
      // 필요 시 빈 리스트 반환 혹은 에러 rethrow
      return [];
    }
  }

  /// ✅ [추가] 큐어룸 캘린더 목록 조회 (월별)
  /// - cureSeq: 큐어룸 시퀀스
  /// - month: 조회할 월 (yyyyMM 형식, 예: "202405")
  Future<List<CureCalendarModel>> getCureCalendarList(int cureSeq, String month) async {
    // 1. 요청 파라미터 구성 (Backend ApiVo 구조에 맞춤)
    final Map<String, dynamic> requestBody = {
      "param": {
        "cureSeq": cureSeq,
        "calendarMonth": month,
        // 필요시 "onlyCustSeq": ... 추가 가능
      }
    };

    try {
      // 2. API 호출
      final response = await _apiService.post(
        '/rest/calendar/selectCureCalendarList',
        data: requestBody,
      );

      // 3. 응답 처리
      // RestCalendarController에서 ApiVo.makeApiResponse로 감싸서 리턴하므로 'data' 필드 확인
      if (response.statusCode == 200 && response.data['data'] != null) {
        final List<dynamic> list = response.data['data'];

        // JSON 리스트를 모델 리스트로 변환
        return list.map((json) => CureCalendarModel.fromJson(json)).toList();
      } else {
        return [];
      }
    } catch (e) {
      print('getCureCalendarList 오류: $e');
      // 에러 발생 시 빈 리스트 반환 (또는 rethrow)
      return [];
    }
  }
}
