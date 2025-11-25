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
  Future<bool> checkTermsNeeded() async {
    try {
      // API 엔드포인트 예시
      // final Response response = await _apiService.get('/api/terms/status');

      // final data = response.data['data'] as Map<String, dynamic>;
      // 이미 동의했으면 true -> 우리는 '필요한지'를 묻는 것이므로 반대로 리턴
      // final bool isAgreed = data['isAgreed'] ?? false;

      // return !isAgreed;
      return true;
    } catch (e) {
      // 에러 시 안전하게 동의 절차를 밟도록 하거나, 정책에 따라 false 처리
      print('약관 상태 확인 실패: $e');
      return true; // 일단 동의 필요하다고 가정 (보수적 접근)
    }
  }

  /// 약관 동의 전송
  Future<void> submitTermsAgreement({required bool locationAgreed, required bool marketingAgreed,}) async {
    try {
      await _apiService.post(
        '/api/terms/agree',
        data: {
          'locationTerm': locationAgreed,
          'marketingTerm': marketingAgreed,
          // 필요한 경우 약관 버전 ID 등을 함께 전송
        },
      );
    } catch (e) {
      throw Exception('약관 동의 전송 실패: $e');
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
  Future<List<PolicyModel>> getPolicyList() async {
    try {
      // 실제 API 호출: final response = await _apiService.get('/api/policies');

      await Future.delayed(const Duration(milliseconds: 500)); // 로딩 시뮬레이션

      // Mock Data
      final Map<String, dynamic> mockResponse = {
        "code": "200",
        "data": [
          {
            "policySeq": 1,
            "policyTypeCmcd": "ServicePolicy",
            "policyNm": "서비스 이용약관",
            "policyDesc": "<h3>제1조 (목적)</h3><p>본 약관은 서비스 이용에 대한...</p>",
            "policyVersion": "0.1",
            "requiredYn": "Y"
          },
          {
            "policySeq": 2,
            "policyTypeCmcd": "PrivacyPolicy",
            "policyNm": "개인정보 처리방침",
            "policyDesc": "<h3>제1조 (개인정보 수집)</h3><p>회사는 다음과 같은 정보를 수집합니다...</p>",
            "policyVersion": "0.1",
            "requiredYn": "Y"
          },
          {
            "policySeq": 3,
            "policyTypeCmcd": "LocationPolicy",
            "policyNm": "위치기반 서비스 이용약관",
            "policyDesc": "<h3>위치 정보 이용</h3><p>사용자의 위치를 기반으로...</p>",
            "policyVersion": "0.1",
            "requiredYn": "Y"
          },
          {
            "policySeq": 4,
            "policyTypeCmcd": "Marketing",
            "policyNm": "마케팅 정보 수신 동의",
            "policyDesc": "<p>이벤트 및 혜택 알림을 받으실 수 있습니다.</p>",
            "policyVersion": "0.1",
            "requiredYn": "N"
          },
          {
            "policySeq": 5,
            "policyTypeCmcd": "Notice",
            "policyNm": "단순 공지 (상세 없음)",
            "policyDesc": null, // 상세 내용 없음 테스트
            "policyVersion": "0.1",
            "requiredYn": "N"
          }
        ]
      };

      final List<dynamic> dataList = mockResponse['data'];
      return dataList.map((json) => PolicyModel.fromJson(json)).toList();

    } catch (e) {
      print('약관 목록 조회 실패: $e');
      return [];
    }
  }
}