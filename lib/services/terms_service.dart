// lib/services/terms_service.dart

import 'package:curemate/features/auth/model/policy_model.dart';
import 'package:dio/dio.dart';
import 'api_service.dart';

class TermsService {
  static final TermsService _instance = TermsService._internal();
  factory TermsService() => _instance;

  final ApiService _apiService;

  TermsService._internal() : _apiService = ApiService();

  /// 약관 동의 필요 여부 확인
  /// [custSeq] : 사용자 시퀀스
  /// 반환값: true(동의 필요), false(동의 불필요 - 목록 0개)
  Future<bool> checkTermsNeeded() async {
    try {
      // 1. 미동의 약관 목록 조회 (기존 getPolicyList 활용)
      final policies = await getPolicyList();

      // 2. 목록이 비어있으면(0개) false, 있으면 true 반환
      return policies.isNotEmpty;
    } catch (e) {
      print('약관 상태 확인 실패: $e');
      // 에러 발생 시 안전하게 동의가 필요한 상태로 간주하여 true 반환
      // (무한 루프 방지를 위해 상황에 따라 false로 처리할 수도 있음)
      return true;
    }
  }

  /// 약관 동의 전송 API
  /// [consentList] : {custSeq, consentIndCmcd, policySeq, consentYn} 형태의 리스트
  Future<void> submitTermsAgreement(List<Map<String, dynamic>> consentList) async {
    try {
      final Response response = await _apiService.post(
        '/rest/customer/updateConsent',
        data: {
          'param': consentList,
        },
      );

      final responseData = response.data as Map<String, dynamic>;

      // 응답 코드 확인 (성공이 아닐 경우 에러 처리)
      if (responseData['code'] != '200') {
        throw Exception('약관 동의 처리 실패: ${responseData['message'] ?? responseData['detail']}');
      }
    } on DioException catch (dioErr) {
      final data = dioErr.response?.data;
      if (data is Map && data['message'] != null) {
        throw data['message'];
      }
      throw dioErr.message ?? '약관 동의 전송 중 오류가 발생했습니다.';
    } catch (e) {
      rethrow;
    }
  }

  /// 약관 상세 내용
  Future<Map<String, String>> getTermsContent(String type) async {
    // API 연동 시: return await _apiService.get('/api/terms/$type');

    await Future.delayed(const Duration(milliseconds: 300)); // 로딩 흉내

    if (type == 'LOCATION') {
      return {
        'title': '위치 기반 서비스 이용약관',
        'content': '''
          <h3>제 1 조 (목적)</h3>
          <p>본 약관은 <b>Cure Mate</b>가 제공하는 위치 기반 서비스의 이용 조건 및 절차를 규정합니다.</p>
          <br>
          <h3>제 2 조 (이용 내용)</h3>
          <p>1. 회사는 사용자의 위치를 이용하여 주변 병원 찾기 기능을 제공합니다.</p>
          <p>2. 사용자의 위치 정보는 해당 기능 제공 목적으로만 사용되며 저장되지 않습니다.</p>
        '''
      };
    } else if (type == 'MARKETING') {
      return {
        'title': '마케팅 정보 수신 동의',
        'content': '''
          <p>이벤트, 혜택 등 다양한 정보를 <b>앱 푸시 알림</b>으로 받아보실 수 있습니다.</p>
          <ul>
            <li>맞춤형 건강 정보 제공</li>
            <li>신규 기능 업데이트 알림</li>
            <li>제휴 병원 할인 혜택 안내</li>
          </ul>
          <p style="color: grey; font-size: 12px;">* 수신 동의를 거부하셔도 기본 서비스 이용에는 제한이 없습니다.</p>
        '''
      };
    } else {
      return {'title': '약관', 'content': '<p>내용을 불러올 수 없습니다.</p>'};
    }
  }

  /// 약관 목록 조회
  Future<List<PolicyModel>> getPolicyList({bool isDetail = false}) async {
    try {
      final Response response = await _apiService.post(
        '/rest/customer/selectNonConsent',
        data: {
          "param": {
            "detailYn": isDetail ? "Y" : "N"
          }
        },
      );

      final responseData = response.data as Map<String, dynamic>;

      if (responseData['code'] != '200') {
        throw Exception('약관 조회 실패: ${responseData['message']}');
      }

      final List<dynamic> dataList = responseData['data'] ?? [];
      return dataList.map((json) => PolicyModel.fromJson(json)).toList();

    } on DioException catch (dioErr) {
      final data = dioErr.response?.data;
      if (data is Map && data['message'] != null) {
        throw data['message'];
      }
      throw dioErr.message ?? '약관 목록을 불러오는 중 오류가 발생했습니다.';
    } catch (e) {
      rethrow;
    }
  }
}