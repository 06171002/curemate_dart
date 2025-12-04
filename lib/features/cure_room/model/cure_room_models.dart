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

  /// 권한 code: master / manager / user ...
  final String cureMemberGradeCmcd;

  /// 권한 이름: 방장 / 관리자 / 일반사용자 ...
  final String cureMemberGradeCmnm;

  /// 타입 code: guardian / caregiver / family / user ...
  final String cureMemberTypeCmcd;

  /// 타입 이름: 보호자 / 간병인 / 가족 / 일반 ...
  final String cureMemberTypeCmnm;

  final String exileYn;

  /// 서버에서 내려오는 memberProfile 그대로 저장
  final Map<String, dynamic>? memberProfile;

  final String custNm;
  final String custNickname;
  final int custMediaGroupSeq;
  final String withdrawYn;
  final String? withdrawDttm;

  CureMemberModel({
    required this.cureMemberSeq,
    required this.cureSeq,
    required this.custSeq,
    required this.cureMemberGradeCmcd,
    required this.cureMemberGradeCmnm,
    required this.cureMemberTypeCmcd,
    required this.cureMemberTypeCmnm,
    required this.exileYn,
    required this.memberProfile,
    required this.custNm,
    required this.custNickname,
    required this.custMediaGroupSeq,
    required this.withdrawYn,
    this.withdrawDttm,
  });

  factory CureMemberModel.fromJson(Map<String, dynamic> json) {
    // 🔹 혹시 snake_case로 내려와도 대응 (안 쓰면 제거해도 됨)
    String getStr(List<String> keys, {String defaultValue = ''}) {
      for (final k in keys) {
        final v = json[k];
        if (v != null) return v.toString();
      }
      return defaultValue;
    }

    int getInt(List<String> keys, {int defaultValue = 0}) {
      for (final k in keys) {
        final v = json[k];
        if (v is int) return v;
        if (v is String && v.isNotEmpty) {
          final parsed = int.tryParse(v);
          if (parsed != null) return parsed;
        }
      }
      return defaultValue;
    }

    Map<String, dynamic>? profileMap;
    if (json['memberProfile'] != null && json['memberProfile'] is Map) {
      profileMap = Map<String, dynamic>.from(json['memberProfile']);
    }

    return CureMemberModel(
      cureMemberSeq: getInt(['cureMemberSeq', 'cure_member_seq']),
      cureSeq: getInt(['cureSeq', 'cure_seq']),
      custSeq: getInt(['custSeq', 'cust_seq']),
      cureMemberGradeCmcd:
          getStr(['cureMemberGradeCmcd', 'cure_member_grade_cmcd']),
      cureMemberGradeCmnm:
          getStr(['cureMemberGradeCmnm', 'cure_member_grade_cmnm']),
      cureMemberTypeCmcd:
          getStr(['cureMemberTypeCmcd', 'cure_member_type_cmcd']),
      cureMemberTypeCmnm:
          getStr(['cureMemberTypeCmnm', 'cure_member_type_cmnm']),
      exileYn: getStr(['exileYn', 'exile_yn'], defaultValue: 'N'),
      memberProfile: profileMap,
      custNm: getStr(['custNm', 'cust_nm']),
      custNickname: getStr(['custNickname', 'cust_nickname']),
      custMediaGroupSeq:
          getInt(['custMediaGroupSeq', 'cust_media_group_seq']),
      withdrawYn: getStr(['withdrawYn', 'withdraw_yn'], defaultValue: 'N'),
      withdrawDttm: json['withdrawDttm'] ?? json['withdraw_dttm'],
    );
  }

  /// 닉네임 > 이름 우선 표시
  String get displayName =>
      (custNickname.isNotEmpty ? custNickname : custNm);

  /// 추방 여부
  bool get isExiled => exileYn == 'Y';

  /// 🔹 CurerModel과 동일한 규칙으로 프로필 이미지 URL 만들기
  String? get profileImgUrl {
    final profile = memberProfile;
    if (profile == null) return null;

    final list = profile['detailList'];
    if (list is! List || list.isEmpty) return null;

    final first = list.first as Map<String, dynamic>;

    // ✅ 우선 순위: detail > thumb > main
    final String? detail = first['mediaDetailUrl'];
    final String? thumb = first['mediaThumbUrl'];
    final String? main = first['mediaUrl'];

    final String? path = detail ?? thumb ?? main;
    if (path == null || path.isEmpty) return null;

    if (path.startsWith('http')) return path;
    return '${EnvConfig.BASE_URL}$path';
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

class CureInterestModel {
  final int cureInterestSeq;
  final int custSeq;
  final int cureSeq;
  final String custNm;
  final String custNickname;
  final int custMediaGroupSeq;
  final Map<String, dynamic>? interestProfile;
  final String withdrawYn; // 'Y'/'N'
  final String regDttm;

  CureInterestModel({
    required this.cureInterestSeq,
    required this.custSeq,
    required this.cureSeq,
    required this.custNm,
    required this.custNickname,
    required this.custMediaGroupSeq,
    required this.interestProfile,
    required this.withdrawYn,
    required this.regDttm,
  });

  factory CureInterestModel.fromJson(Map<String, dynamic> json) {
    return CureInterestModel(
      cureInterestSeq: json['cureInterestSeq'] ?? 0,
      custSeq: json['custSeq'] ?? 0,
      cureSeq: json['cureSeq'] ?? 0,
      custNm: (json['custNm'] ?? '').toString(),
      custNickname: (json['custNickname'] ?? '').toString(),
      custMediaGroupSeq: json['custMediaGroupSeq'] ?? 0,
      interestProfile: json['interestProfile'] as Map<String, dynamic>?,
      withdrawYn: (json['withdrawYn'] ?? '').toString(),
      regDttm: (json['regDttm'] ?? '').toString(),
    );
  }

  /// 닉네임 있으면 닉네임, 아니면 이름
  String get displayName =>
      custNickname.isNotEmpty ? custNickname : custNm;

  /// 탈퇴 여부
  bool get isWithdrawn => withdrawYn == 'Y';

  /// 프로필 이미지 URL (patient/customer랑 같은 규칙)
  String? get profileImgUrl {
    final profile = interestProfile;
    if (profile == null) return null;

    final detailList = profile['detailList'];
    if (detailList is! List || detailList.isEmpty) return null;

    final first = detailList.first as Map<String, dynamic>;
    final String? detail = first['mediaDetailUrl'];
    final String? thumb = first['mediaThumbUrl'];
    final String? main = first['mediaUrl'];

    final String? path = detail ?? thumb ?? main;
    if (path == null || path.isEmpty) return null;

    if (path.startsWith('http')) return path;
    return '${EnvConfig.BASE_URL}$path';
  }
}