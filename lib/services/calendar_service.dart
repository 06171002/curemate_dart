//  lib/services/calendar_service.dart

import 'package:dio/dio.dart';
import 'api_service.dart';
import 'package:intl/intl.dart';

class CalendarService {
  final ApiService _apiService;

  CalendarService() : _apiService = ApiService();

  // 일정추가
  Future<Map<String, dynamic>> createSchedule(Map<String, dynamic> createSchedule) async {
    try {
      final Response response = await _apiService.post(
        '/api/calendar/createSchedule',
        data: createSchedule,
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
}
