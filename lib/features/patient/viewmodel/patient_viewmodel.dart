import 'package:curemate/services/patient_service.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';

class PatientViewModel with ChangeNotifier {
  final PatientService _patientService;

  PatientViewModel({PatientService? patientService})
      : _patientService = patientService ?? PatientService() {
    // 👇 ViewModel 생성될 때 구독 시작
    _subscribeRealtime();
  }

  bool _isLoading = false;
  String? _errorMessage;

  // 보호자 등록 여부
  bool _isGuardianRegistered = false;

  // ✅ 환자 목록 상태
  List<dynamic> _patients = [];
  List<dynamic> get patients => _patients;

  // ✅ 단일 환자 상태
  Map<String, dynamic>? _selectedPatient;
  Map<String, dynamic>? get selectedPatient => _selectedPatient;

  // ✅ 초대 목록 상태
  List<dynamic> _invites = [];
  List<dynamic> get invites => _invites;

  bool get isGuardianRegistered => _isGuardianRegistered;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  /// 👇 여기서 DB 변경 이벤트를 구독
   void _subscribeRealtime() {
  }

  /// 환자 등록 처리 함수 (상태 포함)
  Future<void> createPatient(Map<String, dynamic> patientData) async {
    _isLoading = true;
    notifyListeners();

    try {
      await _patientService.createPatient(patientData);
      _errorMessage = null;
    } on DioException catch (dioErr) {
      final data = dioErr.response?.data;
      if (data is Map && data['error'] != null) {
        _errorMessage = data['error'];
      } else {
        _errorMessage = dioErr.message ?? '네트워크 오류가 발생했습니다.';
      }
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// 보호자 등록 여부 확인 함수
  Future<void> checkGuardianStatus() async {
    _isLoading = true;
    notifyListeners();

    try {
      final isRegistered = await _patientService.isGuardianRegistered();
      _isGuardianRegistered = isRegistered;
      _errorMessage = null;
    } catch (e) {
      _isGuardianRegistered = false;
      _errorMessage = e is String ? e : '보호자 등록 여부 확인 중 오류가 발생했습니다.';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// 환자 목록 조회
  Future<void> fetchPatients() async {
    _isLoading = true;
    notifyListeners();

    try {
      // 1. 서비스에서 원본 데이터 리스트 가져오기
      final List<dynamic> rawList = await _patientService.getPatients();

      // 2. ✅ [핵심 수정] UI에서 사용하는 키 이름으로 변환 (Mapping)
      _patients = rawList.map((item) {
        return {
          // 화면(드롭다운 등)에서 사용하는 키 : 서버에서 내려준 키
          'patient_id': item['curePatientSeq'],
          'name': item['patientNm'],

          // 필요하다면 아래 정보들도 추가 매핑
          'birth': item['patientBirthday'],
          'gender': item['patientGenderCmnm'],
          'cure_seq': item['cureSeq'],
          // 원본 데이터도 유지하고 싶다면
          ...item,
        };
      }).toList();

      _errorMessage = null;
    } on DioException catch (dioErr) {
      final data = dioErr.response?.data;
      if (data is Map && data['error'] != null) {
        _errorMessage = data['error'];
      } else {
        _errorMessage = dioErr.message ?? '네트워크 오류가 발생했습니다.';
      }
      _patients = []; // 에러 시 초기화
    } catch (e) {
      _errorMessage = e.toString();
      _patients = []; // 에러 시 초기화
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// 단일 환자 조회
  Future<void> fetchPatientById(int patientId) async {
    _isLoading = true;
    notifyListeners();

    try {
      final result = await _patientService.getPatientById(patientId);
      _selectedPatient = result; // ✅ 조회한 환자 저장
      _errorMessage = null;
    } on DioException catch (dioErr) {
      final data = dioErr.response?.data;
      if (data is Map && data['error'] != null) {
        _errorMessage = data['error'];
      } else {
        _errorMessage = dioErr.message ?? '네트워크 오류가 발생했습니다.';
      }
      _selectedPatient = null;
    } catch (e) {
      _errorMessage = e.toString();
      _selectedPatient = null;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// 이메일 초대하기
  Future<void> sendEmailInvite(String email, int patientId,
      {String relationship = "보호자"}) async {
    _isLoading = true;
    notifyListeners();

    try {
      await _patientService.sendEmailInvite(
        email: email,
        patientId: patientId,
        relationship: relationship,
      );
      _errorMessage = null;
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// 🔹 초대 토큰으로 단일 초대 검증
  Future<Map<String, dynamic>?> fetchInviteByToken(String token) async {
    _isLoading = true;
    notifyListeners();

    try {
      final invite = await _patientService.getInviteByToken(token);
      if (invite != null) {
        _invites = [invite]; // ✅ 단일 초대만 보여줌
      }
      _errorMessage = null;
      return invite;
    } catch (e) {
      _errorMessage = e.toString();
      return null;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// 🔹 초대 수락
  Future<void> acceptInvite(String token) async {
    _isLoading = true;
    notifyListeners();

    try {
      await _patientService.acceptInvite(token);
      _invites.removeWhere((invite) => invite['invite_token'] == token);
      await fetchPatients(); // ✅ 환자 목록 갱신
      _errorMessage = null;
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// 🔹 초대 거절
  Future<void> rejectInvite(String token) async {
    _isLoading = true;
    notifyListeners();

    try {
      await _patientService.rejectInvite(token);
      _invites.removeWhere((invite) => invite['invite_token'] == token);
      _errorMessage = null;
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
