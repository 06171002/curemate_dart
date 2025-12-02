//  lib/services/calendar_service.dart

import 'package:dio/dio.dart';
import 'api_service.dart';
import 'package:intl/intl.dart';

class CalendarService {
  final ApiService _apiService;

  CalendarService() : _apiService = ApiService();

  Future<void> createSchedule(Map<String, dynamic> inputData) async {
    // inputData 예시:
    // {
    //   'patientId': 123,
    //   'scheduleType': '진료',
    //   'title': '감기 진료',
    //   'content': '내과 방문',
    //   'startDate': '2023-10-25',
    //   'startTime': '09:00',
    //   'endDate': '2023-10-25',
    //   'endTime': '10:00',
    //   'isAllDay': false,
    //   'isAlarmOn': true,
    //   'alarmType': 'push',
    //   'alarmTime': '10분 전'
    // }

    final String typeCode = _mapTypeToCode(inputData['scheduleType']);

    // 2. [추가] 스케줄 반복 타입(daily, weekly 등) 매핑
    final String scheduleRepeatCode = _mapRepeatToScheduleType(inputData['repeatOption']);

    // 3. [추가] 반복 여부(Y/N) 설정 (반복 없음이면 N, 나머지는 Y)
    //    만약 '매일'도 반복으로 본다면 '반복 없음'만 N으로 처리
    final String repeatYn = inputData['repeatOption'] == '반복 없음' ? 'N' : 'Y';

    // 날짜+시간 합치기 (YYYY-MM-DD HH:mm:ss 형태 권장)
    String startDttm = "${inputData['startDate']} ${inputData['startTime']}:00";
    String endDttm = "${inputData['endDate']} ${inputData['endTime']}:00";

    if (inputData['isAllDay'] == true) {
      startDttm = "${inputData['startDate']} 00:00:00";
      endDttm = "${inputData['endDate']} 23:59:59";
    }

    // 서버로 보낼 데이터 구조 (CureCalendarVo 구조에 맞춤)
    final Map<String, dynamic> requestBody = {
      "param": {
        // 1. 기본 정보 (t_cure_calendar)
        "patientSeq": inputData['patientId'],    // 환자 ID
        "cureCalendarTypeCmcd": typeCode,        // 일정 타입 (treatment, medicine...)
        "cureCalendarNm": inputData['title'],    // 제목
        "cureCalendarDesc": inputData['content'],// 내용
        "releaseYn": "Y",                        // 공개 여부 (기본값)
        "cureSeq": inputData['cureSeq'],

        // 2. 상세 스케줄 정보 (t_cure_calendar_schedule)
        "schedule": {
          "cureScheduleStartDttm": startDttm,
          "cureScheduleEndDttm": endDttm,
          "cureScheduleDayYn": inputData['isAllDay'] ? "Y" : "N",
          "cureScheduleRepeatYn": repeatYn, // 반복 로직 구현 시 수정 필요
          "cureScheduleTypeCmcd": scheduleRepeatCode
        },

        // 3. 알람 정보 (t_cure_calendar_alram) - 리스트 형태
        "alrams": inputData['isAlarmOn'] ? [
          {
            // 알람 시간 계산 로직
            "cureAlramDttm": _calculateAlarmTime(startDttm, inputData['alarmTime']),
            "cureAlramTypeCmcd": _mapAlarmType(inputData['alarmType']) // push, sms 등 매핑 필요 시 처리
          }
        ] : []
      }
    };

    try {
      final response = await _apiService.post('/rest/calendar/mergeCalendarAll', data: requestBody);

      // 성공 처리 (필요시)
      if (response.statusCode != 200) {
        throw Exception("일정 등록 실패: ${response.statusMessage}");
      }
    } catch (e) {
      // 에러 로그 출력 또는 재던지기
      print("Create Schedule Error: $e");
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
}
