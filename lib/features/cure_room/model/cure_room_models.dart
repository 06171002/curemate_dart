// lib/features/cure_room/model/cure_room_models.dart //단건 조회 api의 data들을 표현

import 'curer_model.dart';
import 'package:curemate/config/EnvConfig.dart';

class CurePatientModel {
  final int curePatientSeq;
  final int cureSeq;
  final String patientTypeCmcd;
  final int? custSeq;
  final String patientNm;
  final String patientBirthday;
  final String? patientGenderCmcd;
  final String? patientBloodTypeCmcd;
  final int? patientWeight;
  final int? patientHeight;
  final String regId;
  final String regDttm;
  final String updId;
  final String updDttm;

   // 🔹 MediaGroup처럼 내려오는 patientProfile
  final Map<String, dynamic>? patientProfile;

  // 나중에 실제 데이터 들어올 때를 대비해서 리스트도 정의
  final List<CureMedicineGroupModel> medicines;
  final List<CureDiseaseModel> diseases;

  CurePatientModel({
    required this.curePatientSeq,
    required this.cureSeq,
    required this.patientTypeCmcd,
    this.custSeq,
    required this.patientNm,
    required this.patientBirthday,
    this.patientGenderCmcd,
    this.patientBloodTypeCmcd,
    this.patientWeight,
    this.patientHeight,
    required this.regId,
    required this.regDttm,
    required this.updId,
    required this.updDttm,
    this.patientProfile,   
    this.medicines = const [],
    this.diseases = const [],
  });

  factory CurePatientModel.fromJson(Map<String, dynamic> json) {
    final medicinesJson = json['medicines'] as List? ?? [];
    final diseasesJson = json['diseases'] as List? ?? [];

    return CurePatientModel(
      curePatientSeq: json['curePatientSeq'] ?? 0,
      cureSeq: json['cureSeq'] ?? 0,
      patientTypeCmcd: json['patientTypeCmcd'] ?? '',
      custSeq: json['custSeq'],
      patientNm: json['patientNm'] ?? '',
      patientBirthday: json['patientBirthday'] ?? '',
      patientGenderCmcd: json['patientGenderCmcd'],
      patientBloodTypeCmcd: json['patientBloodTypeCmcd'],
      patientWeight: json['patientWeight'],
      patientHeight: json['patientHeight'],
      regId: json['regId'] ?? '',
      regDttm: json['regDttm'] ?? '',
      updId: json['updId'] ?? '',
      updDttm: json['updDttm'] ?? '',
      patientProfile: json['patientProfile'] as Map<String, dynamic>?, 
      medicines: medicinesJson
          .map((e) => CureMedicineGroupModel.fromJson(e))
          .toList(),
      diseases:
          diseasesJson.map((e) => CureDiseaseModel.fromJson(e)).toList(),
    );
  }
   /// 🔹 CustomerModel과 완전히 같은 방식으로 URL 뽑기
String? get profileImgUrl {
  final profile = patientProfile;
  if (profile == null) return null;

  final List<dynamic>? detailList = profile['detailList'];
  if (detailList == null || detailList.isEmpty) return null;

  final first = detailList.first as Map<String, dynamic>;

  // (기존처럼) detail > thumb > main
  String? path =
      first['mediaDetailUrl'] ?? first['mediaThumbUrl'] ?? first['mediaUrl'];

  if (path == null || path.isEmpty) return null;

  // 🔧 만약 `_detail` 들어있으면 잘라서 원본으로 강제
  if (path.contains('_detail')) {
    path = path.replaceFirst('_detail', '');
  }

  if (!path.startsWith('http')) {
    path = '${EnvConfig.BASE_URL}$path';
  }

  return path;
}
}

class CureMemberModel {
  final int cureMemberSeq;
  final int cureSeq;
  final int custSeq;
  final String cureMemberGradeCmcd;
  final String cureMemberTypeCmcd;
  final String exileYn;
  final String regId;
  final String regDttm;
  final String updId;
  final String updDttm;

  CureMemberModel({
    required this.cureMemberSeq,
    required this.cureSeq,
    required this.custSeq,
    required this.cureMemberGradeCmcd,
    required this.cureMemberTypeCmcd,
    required this.exileYn,
    required this.regId,
    required this.regDttm,
    required this.updId,
    required this.updDttm,
  });

  factory CureMemberModel.fromJson(Map<String, dynamic> json) {
    return CureMemberModel(
      cureMemberSeq: json['cureMemberSeq'] ?? 0,
      cureSeq: json['cureSeq'] ?? 0,
      custSeq: json['custSeq'] ?? 0,
      cureMemberGradeCmcd: json['cureMemberGradeCmcd'] ?? '',
      cureMemberTypeCmcd: json['cureMemberTypeCmcd'] ?? '',
      exileYn: json['exileYn'] ?? 'N',
      regId: json['regId'] ?? '',
      regDttm: json['regDttm'] ?? '',
      updId: json['updId'] ?? '',
      updDttm: json['updDttm'] ?? '',
    );
  }
}

class CureRoomDetailModel {
  final CurerModel cure;
  final List<CurePatientModel> patients;
  final List<CureMemberModel> members;

  CureRoomDetailModel({
    required this.cure,
    required this.patients,
    required this.members,
  });

  factory CureRoomDetailModel.fromJson(Map<String, dynamic> json) {
    final patientsJson = json['patients'] as List? ?? [];
    final membersJson = json['members'] as List? ?? [];

    return CureRoomDetailModel(
      // cure 정보는 json 루트에 있으니까 그대로 CurerModel로 파싱
      cure: CurerModel.fromJson(json),
      patients: patientsJson
          .map((e) => CurePatientModel.fromJson(e as Map<String, dynamic>))
          .toList(),
      members: membersJson
          .map((e) => CureMemberModel.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}

class CureMedicineGroupModel {
  final int curePatientMedicineSeq;
  final int curePatientSeq;
  final String patientMedicineNm;

  final List<CureMedicineDetailModel> details;

  CureMedicineGroupModel({
    required this.curePatientMedicineSeq,
    required this.curePatientSeq,
    required this.patientMedicineNm,
    this.details = const [],
  });

  factory CureMedicineGroupModel.fromJson(Map<String, dynamic> json) {
    // 🔹 여기! 백엔드 필드명은 medicineDetails
    final detailsJson = json['medicineDetails'] as List? ?? [];

    return CureMedicineGroupModel(
      curePatientMedicineSeq: json['curePatientMedicineSeq'] ?? 0,
      curePatientSeq: json['curePatientSeq'] ?? 0,
      patientMedicineNm: json['patientMedicineNm'] ?? '',
      details: detailsJson
          .map((e) => CureMedicineDetailModel.fromJson(e))
          .toList(),
    );
  }
}

class CureMedicineDetailModel {
  final int curePatientMedicineDetailSeq;
  final int curePatientMedicineSeq;
  final String cureMedicineNm;
  final int? cureMedicineQty;
  final String? cureMedicineVolume;

  CureMedicineDetailModel({
    required this.curePatientMedicineDetailSeq,
    required this.curePatientMedicineSeq,
    required this.cureMedicineNm,
    this.cureMedicineQty,
    this.cureMedicineVolume,
  });

  factory CureMedicineDetailModel.fromJson(Map<String, dynamic> json) {
    return CureMedicineDetailModel(
      curePatientMedicineDetailSeq:
          json['curePatientMedicineDetailSeq'] ?? 0,
      curePatientMedicineSeq: json['curePatientMedicineSeq'] ?? 0,
      cureMedicineNm: json['cureMedicineNm'] ?? '',
      cureMedicineQty: json['cureMedicineQty'] is int
          ? json['cureMedicineQty'] as int
          : int.tryParse(json['cureMedicineQty']?.toString() ?? ''),
      // 🔹 volume은 무조건 String으로 변환
      cureMedicineVolume: json['cureMedicineVolume']?.toString(),
    );
  }
}

class CureDiseaseModel {
  final int curePatientDiseaseSeq;
  final int curePatientSeq;
  final String curePatientDiseaseNm;
  final String curePatientDiseaseTypeCmcd;
  final String curedYn;
  final String? diseaseStartDt;
  final String? diseaseEndDt;
  final String? diseaseDesc;

  CureDiseaseModel({
    required this.curePatientDiseaseSeq,
    required this.curePatientSeq,
    required this.curePatientDiseaseNm,
    required this.curePatientDiseaseTypeCmcd,
    required this.curedYn,
    this.diseaseStartDt,
    this.diseaseEndDt,
    this.diseaseDesc,
  });

  factory CureDiseaseModel.fromJson(Map<String, dynamic> json) {
    return CureDiseaseModel(
      curePatientDiseaseSeq: json['curePatientDiseaseSeq'] ?? 0,
      curePatientSeq: json['curePatientSeq'] ?? 0,
      curePatientDiseaseNm: json['curePatientDiseaseNm'] ?? '',
      curePatientDiseaseTypeCmcd:
          json['curePatientDiseaseTypeCmcd'] ?? '',
      curedYn: json['curedYn'] ?? 'N',
      diseaseStartDt: json['diseaseStartDt']?.toString(),
      diseaseEndDt: json['diseaseEndDt']?.toString(),
      diseaseDesc: json['diseaseDesc'],
    );
  }
}