//  lib/services/patient_service.dart

import 'package:dio/dio.dart';
import 'api_service.dart';

class PatientService {
  final ApiService _apiService;

  PatientService() : _apiService = ApiService();

  /// 환자 등록 API
  Future<Map<String, dynamic>> createPatient(Map<String, dynamic> patientData) async {
    try {
      final Response response = await _apiService.post('/api/patients', data: patientData);

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


  /// 환자 목록 조회 API
  Future<List<dynamic>> getPatients() async {
    try {
      final Response response = await _apiService.post('/rest/cure/patientList', data: {
        "param": {}
      },);

      if (response.statusCode == 200) {
        if (response.data['data'] != null) {
          return response.data['data'] as List<dynamic>;
        } else {
          return []; // 데이터가 없으면 빈 리스트 반환
        }
      } else {
        throw Exception('환자 조회 실패: ${response.data}');
      }
    } catch (e) {
      rethrow;
    }
  }

  // 보호자 등록 여부 체크 (환자 선택 페이지 속 팝업이라 여기에 정의함)
  Future<bool> isGuardianRegistered() async {
    try {
      final response = await _apiService.get('/api/guardian/status');

      if (response.statusCode == 200) {
        return response.data['registered'] as bool;
      } else {
        return false;
      }
    } catch (e) {
      print('보호자 등록 여부 확인 실패: $e');
      return false;
    }
  }
  /// 단일 환자 조회 API
  Future<Map<String, dynamic>?> getPatientById(int patientId) async {
    try {
      final Response response = await _apiService.get('/api/patients/$patientId');

      if (response.statusCode == 200) {
        return response.data as Map<String, dynamic>;
      } else if (response.statusCode == 404) {
        // 서버에서 "환자 없음" 처리한 경우
        return null;
      } else {
        throw Exception('환자 조회 실패: ${response.data}');
      }
    } on DioException catch (dioErr) {
      final data = dioErr.response?.data;
      if (data is Map && data['error'] != null) {
        throw data['error']; // 👈 문자열만 던짐
      }
      throw dioErr.message ?? '네트워크 오류가 발생했습니다.';
    } catch (e) {
      rethrow;
    }
  }

//이메일 초대하기
  Future<void> sendEmailInvite({
    required String email,
    required int patientId,
    String relationship = "보호자",
  }) async {
    try {
      final response = await _apiService.post('/api/patients/email', data: {
        'email': email,
        'patientId': patientId,
        'relationship': relationship,
      });

      if (response.statusCode != 200) {
        throw Exception('초대 실패: ${response.data}');
      }
    } on DioException catch (dioErr) {
      final data = dioErr.response?.data;
      if (data is Map && data['error'] != null) {
        throw data['error'];
      }
      throw dioErr.message ?? '네트워크 오류';
    }
  }


//  초대 토큰 검증
  Future<Map<String, dynamic>?> getInviteByToken(String token) async {
    try {
      final res = await _apiService.get("/api/patients/invites/$token"); // 서버에서 토큰으로 조회
      if (res.statusCode == 200) {
        return res.data as Map<String, dynamic>;
      }
      return null;
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) {
        return null; // 초대 없음
      }
      rethrow;
    }
  }
  /// 🔹 초대 수락 API
  Future<void> acceptInvite(String token) async {
    try {
      final response = await _apiService.post('/api/patients/invites/accept', data: {
        'token': token,
      });

      if (response.statusCode != 200) {
        throw Exception('초대 수락 실패: ${response.data}');
      }
    } catch (e) {
      rethrow;
    }
  }

  /// 🔹 초대 거절 API
  Future<void> rejectInvite(String token) async {
    try {
      final response = await _apiService.post('/api/patients/invites/reject', data: {
        'token': token,
      });

      if (response.statusCode != 200) {
        throw Exception('초대 거절 실패: ${response.data}');
      }
    } catch (e) {
      rethrow;
    }
  }


}