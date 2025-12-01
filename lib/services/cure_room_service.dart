import 'package:curemate/features/cure_room/model/curer_model.dart';
import 'package:dio/dio.dart';
import 'package:curemate/services/api_service.dart';
import 'package:curemate/features/cure_room/model/curer_model.dart';
import 'package:curemate/features/cure_room/model/cure_room_models.dart';

class CureRoomService {
  static final CureRoomService _instance = CureRoomService._internal();
  factory CureRoomService() => _instance;

  final ApiService _apiService;

  CureRoomService._internal() : _apiService = ApiService();

  

  /// 0. 큐어룸 단건 조회  👉 이제 Model 반환!
  Future<CureRoomDetailModel> getCureRoom(int cureSeq) async {
    final Response response = await _apiService.post(
      '/rest/cure/cureRoom',
      data: {
        'param': {
          'cureSeq': cureSeq,
        },
      },
    );

    final data = response.data['data'];

    if (data is Map<String, dynamic>) {
      return CureRoomDetailModel.fromJson(data);
    } else {
      throw Exception('cureRoom 응답 형식이 올바르지 않습니다. data: $data');
    }
  }

  /// 1. 환자 병력 목록 조회
  Future<List<CureDiseaseModel>> getPatientDiseaseList(int curePatientSeq) async {
  final Response response = await _apiService.post(
    '/rest/cure/curePatientDiseaseList',
    data: {
      'param': {
        'curePatientSeq': curePatientSeq,
      },
    },
  );

  final data = response.data['data'];

  List<dynamic> rawList;
  if (data is List) {
    rawList = data;
  } else if (data is Map && data['list'] is List) {
    rawList = data['list'];
  } else {
    return [];
  }

  return rawList
      .map((e) => CureDiseaseModel.fromJson(e as Map<String, dynamic>))
      .toList();
}

/// 🔹 병력 단건 조회
  Future<CureDiseaseModel> getPatientDisease(int curePatientDiseaseSeq) async {
    final Response response = await _apiService.post(
      '/rest/cure/curePatientDisease',
      data: {
        'param': {
          'curePatientDiseaseSeq': curePatientDiseaseSeq,
        },
      },
    );

    final data = response.data['data'];

    if (data is Map<String, dynamic>) {
      return CureDiseaseModel.fromJson(data);
    } else {
      throw Exception('curePatientDisease 응답 형식이 올바르지 않습니다. data: $data');
    }
  }
  

  /// 2. 병력 등록/수정
  Future<void> savePatientDisease(Map<String, dynamic> payload) async {
    await _apiService.post(
      '/rest/cure/mergeCurePatientDisease',
      data: {
        'param': payload,
      },
    );
  }

  /// 3. 병력 삭제
  Future<void> deletePatientDisease(int curePatientDiseaseSeq) async {
    await _apiService.post(
      '/rest/cure/deleteCurePatientDisease',
      data: {
        'param': {
          'curePatientDiseaseSeq': curePatientDiseaseSeq,
        },
      },
    );
  }

  /// 4. 복용약 목록 조회 (그룹 + 상세)
   Future<List<CureMedicineGroupModel>> getPatientMedicineList(int curePatientSeq) async {
    final Response response = await _apiService.post(
      '/rest/cure/curePatientMedicineList',
      data: {
        'param': {
          'curePatientSeq': curePatientSeq,
        },
      },
    );

    final data = response.data['data'];

    if (data is List) {
      return data
          .map((e) => CureMedicineGroupModel.fromJson(e as Map<String, dynamic>))
          .toList();
    } else if (data is Map && data['list'] is List) {
      // 혹시 나중에 { data: { list: [...] } } 형태로 바뀔 수도 있으니까 방어 코드
      return (data['list'] as List)
          .map((e) => CureMedicineGroupModel.fromJson(e as Map<String, dynamic>))
          .toList();
    }

    return [];
  }

 

  /// 🔹 약 그룹 + 세부약을 한 번에 저장 (신규/수정 모두)
Future<void> savePatientMedicineAll({
  int? curePatientMedicineSeq, // 수정일 때만 값 있음
  required int curePatientSeq,
  required String patientMedicineNm,
  required List<Map<String, dynamic>> medicineDetails,
}) async {
  final payload = {
    'curePatientMedicineSeq': curePatientMedicineSeq, // null이면 신규
    'curePatientSeq': curePatientSeq,
    'patientMedicineNm': patientMedicineNm,
    'medicineDetails': medicineDetails,
  };

  final Response response = await _apiService.post(
    '/rest/cure/mergeCurePatientMedicineAll',
    data: {
      'param': payload,
    },
  );

  // 필요하면 여기서 code 체크해도 되고,
  // 지금은 에러나면 DioException으로 올라올 거라 따로 안 해도 됨.
}

  /// 6. 약 그룹 삭제
  Future<void> deletePatientMedicineGroup(int curePatientMedicineSeq) async {
    await _apiService.post(
      '/rest/cure/deleteCurePatientMedicine',
      data: {
        'param': {
          'curePatientMedicineSeq': curePatientMedicineSeq,
        },
      },
    );
  }

  /// 7. 개별 약 저장
  Future<void> savePatientMedicineDetail(Map<String, dynamic> payload) async {
    await _apiService.post(
      '/rest/cure/mergeCurePatientMedicineDetail',
      data: {
        'param': payload,
      },
    );
  }

  /// 8. 개별 약 삭제
  Future<void> deletePatientMedicineDetail(int curePatientMedicineDetailSeq) async {
    await _apiService.post(
      '/rest/cure/deleteCurePatientMedicineDetail',
      data: {
        'param': {
          'curePatientMedicineDetailSeq': curePatientMedicineDetailSeq,
        },
      },
    );
  }

  /// 9. 큐어룸 환자 등록/수정
Future<void> saveCurePatient(Map<String, dynamic> param) async {
  try {
    // 🔹 원본 param 건들지 말고 복사해서 사용
    final Map<String, dynamic> apiParam = Map<String, dynamic>.from(param);

    // 🔹 생일이 문자열이면 YYYYMMDD 형식으로 강제 변환
    final rawBirthday = apiParam['patientBirthday'];
    if (rawBirthday is String && rawBirthday.isNotEmpty) {
      apiParam['patientBirthday'] = rawBirthday.replaceAll('-', '');
    }

    final Response response = await _apiService.post(
      '/rest/cure/mergeCurePatient',
      data: {
        'param': apiParam,
      },
    );

    if (response.statusCode != 200) {
      throw Exception('환자 저장 실패: ${response.statusCode}');
    }

  } on DioException catch (dioErr) {
    final data = dioErr.response?.data;
    if (data is Map && data['message'] != null) {
      throw Exception(data['message']);
    }
    throw Exception(dioErr.message ?? '환자 저장 중 오류가 발생했습니다.');
  } catch (e) {
    rethrow;
  }
}
/// 🔹 환자 단건 조회
Future<CurePatientModel> getCurePatient(int curePatientSeq) async {
  final Response response = await _apiService.post(
    '/rest/cure/curePatient',
    data: {
      'param': {
        'curePatientSeq': curePatientSeq,
      },
    },
  );

  final data = response.data['data'];

  if (data is Map<String, dynamic>) {
    return CurePatientModel.fromJson(data);
  } else {
    throw Exception('curePatient 응답 형식이 올바르지 않습니다. data: $data');
  }
}

/// ✅ 환자 정보 수정
Future<void> updateCurePatient({
  required int curePatientSeq,    // 수정 대상 환자 PK
  required int cureSeq,
  required String patientNm,
  String? patientBirthday,        // "yyyy-MM-dd" 또는 "yyyyMMdd"
  String? patientGenderCmcd,      // "man" / "woman" 등
  String? patientBloodTypeCmcd,   // "A+", "O-" ...
  int? patientWeight,
  int? patientHeight,
  int? patientMediaGroupSeq,      // 👈 [추가] 프로필 이미지 그룹
}) async {
  final param = <String, dynamic>{
    'curePatientSeq': curePatientSeq,
    'cureSeq': cureSeq,
    'patientNm': patientNm,
    'patientBirthday': patientBirthday,
    'patientGenderCmcd': patientGenderCmcd,
    'patientBloodTypeCmcd': patientBloodTypeCmcd,
    'patientWeight': patientWeight,
    'patientHeight': patientHeight,
  };

  // 👇 새 이미지가 있으면 같이 보냄
  if (patientMediaGroupSeq != null) {
    param['patientMediaGroupSeq'] = patientMediaGroupSeq;
  }

  await saveCurePatient(param);
}

  /// 큐어룸 목록 조회
  Future<List<CurerModel>> getCureRoomList() async {
    try {
      final Response response = await _apiService.post(
        '/rest/cure/cureRoomList',
        data: {
          'param': {},
          'map': {
            'infoYn': true, // 요청하신 payload 구조 반영
          }
        },
      );

      final responseData = response.data as Map<String, dynamic>;

      // 응답 구조가 { code, message, data: [...] } 또는 { data: { list: [...] } } 인지 확인 필요
      // 일반적인 리스트 반환 구조로 가정하여 작성합니다.
      final List<dynamic> list = responseData['data'] ?? [];

      return list.map((json) => CurerModel.fromJson(json)).toList();
    } catch (e) {
      print('큐어룸 목록 조회 실패: $e');
      rethrow;
    }
  }

  /// 큐어룸 생성
  Future<CurerModel> saveCureRoom(Map<String, dynamic> payload) async {
    try {
      final Response response = await _apiService.post(
        '/rest/cure/mergeCureRoom',
        data: {
          'param': payload,
        },
      );

      final responseData = response.data as Map<String, dynamic>;
      final data = responseData['data'];

      if (responseData['code'] == '200' && data != null) {
        return CurerModel.fromJson(data);
      } else {
        throw Exception('큐어룸 생성 실패: ${responseData['message'] ?? '데이터 없음'}');
      }
    } catch (e) {
      print('큐어룸 저장 실패: $e');
      rethrow;
    }
  }
}
