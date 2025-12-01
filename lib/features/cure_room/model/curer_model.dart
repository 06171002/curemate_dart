import 'package:curemate/config/EnvConfig.dart';

class CurerModel {
  final int cureSeq;
  final int custSeq;
  final String cureNm;
  final int? cureMediaGroupSeq;
  final String? cureDesc;
  final String releaseYn;
  final String useYn;
  final String? regId;
  final String regDttm;
  final String? updId;
  final String? updDttm;
  final String? profileImgUrl;

  CurerModel({
    required this.cureSeq,
    required this.custSeq,
    required this.cureNm,
    this.cureMediaGroupSeq,
    this.cureDesc,
    this.releaseYn = 'Y',
    this.useYn = 'Y',
    this.regId,
    required this.regDttm,
    this.updId,
    this.updDttm,
    this.profileImgUrl,
  });

  factory CurerModel.fromJson(Map<String, dynamic> json) {
    // 1. 프로필 이미지 URL 추출 로직
    String? imgUrl;
    if (json['cureProfile'] != null) {
      final profile = json['cureProfile'];
      // 리스트 안에 있는지 확인
      if (profile is Map &&
          profile['detailList'] != null &&
          (profile['detailList'] as List).isNotEmpty) {

        final detail = profile['detailList'][0];
        imgUrl = detail['mediaUrl'];

        if (imgUrl != null && !imgUrl.startsWith('http')) {
          imgUrl = '${EnvConfig.BASE_URL}$imgUrl';
        }
      }
    }

    return CurerModel(
      // API 응답 키(camelCase)와 DB 컬럼명(snake_case) 모두 대응하도록 처리
      cureSeq: json['cureSeq'] ?? json['cure_seq'] ?? 0,
      custSeq: json['custSeq'] ?? json['cust_seq'] ?? 0,
      cureNm: json['cureNm'] ?? json['cure_nm'] ?? '',

      // ✅ cureMediaGroupSeq 매핑 추가
      cureMediaGroupSeq: json['cureMediaGroupSeq'] ?? json['mediaGroupSeq'] ?? json['media_group_seq'],

      cureDesc: json['cureDesc'] ?? json['cure_desc'],
      releaseYn: json['releaseYn'] ?? json['release_yn'] ?? 'Y',
      useYn: json['useYn'] ?? json['use_yn'] ?? 'Y',

      // ✅ 타입을 안전하게 String으로 변환
      regId: json['regId']?.toString() ?? json['reg_id']?.toString(),
      regDttm: json['regDttm'] ?? json['reg_dttm'] ?? '',
      updId: json['updId']?.toString() ?? json['upd_id']?.toString(),
      updDttm: json['updDttm'] ?? json['upd_dttm'],

      profileImgUrl: imgUrl,
    );
  }

// 필요시 toJson 구현...
}