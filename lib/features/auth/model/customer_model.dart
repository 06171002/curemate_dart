// lib/features/auth/model/customer_model.dart

import 'package:curemate/config/EnvConfig.dart';

class CustomerModel {
  final int custSeq;
  final String custNm;         // 이름
  final String? custNickname;  // 닉네임
  final String? custEmail;     // 이메일
  final String? custMobile;    // 휴대폰 번호
  final String? custBirth;     // 생년월일 (YYYYMMDD)
  final String? custGender;    // 성별 (female/male)
  final String? custAge;       // 나이
  final String? profileImgUrl; // 프로필 이미지 경로
  final String? regDttm;       // 가입일

  // 편의상 로그인 직후 객체 생성 시 활용할 수 있도록 포함했습니다.
  final String? accessToken;
  final String? refreshToken;

  CustomerModel({
    required this.custSeq,
    required this.custNm,
    this.custNickname,
    this.custEmail,
    this.custMobile,
    this.custBirth,
    this.custGender,
    this.custAge,
    this.profileImgUrl,
    this.regDttm,
    this.accessToken,
    this.refreshToken,
  });

  factory CustomerModel.fromJson(Map<String, dynamic> json) {
    // 1. 프로필 이미지 URL 추출 로직
    String? imgUrl;
    if (json['custProfile'] != null) {
      final profile = json['custProfile'];
      if (profile['detailList'] != null && (profile['detailList'] as List).isNotEmpty) {
        // 첫 번째 이미지의 mediaUrl 사용
        imgUrl = profile['detailList'][0]['mediaUrl'];

        if (imgUrl != null && !imgUrl.startsWith('http')) {
          imgUrl = '${EnvConfig.BASE_URL}$imgUrl';
        }
      }
    }

    return CustomerModel(
      custSeq: (json['custSeq'] as num?)?.toInt() ?? 0,
      custNm: json['custNm'] ?? '',
      custNickname: json['custNickname'],
      custEmail: json['custEmail'],
      custMobile: json['custMobile'],
      custBirth: json['custBirth'],
      custGender: json['custGenderCmcd'], // 예: "female"
      custAge: json['custAge'],
      profileImgUrl: imgUrl,
      regDttm: json['regDttm'],
      accessToken: json['accessToken'],
      refreshToken: json['refreshToken'],
    );
  }

  // 객체를 JSON으로 변환 (필요시 사용)
  Map<String, dynamic> toJson() {
    return {
      'custSeq': custSeq,
      'custNm': custNm,
      'custNickname': custNickname,
      'custEmail': custEmail,
      'custMobile': custMobile,
      'custBirth': custBirth,
      'custGenderCmcd': custGender,
      'custAge': custAge,
      'profileImgUrl': profileImgUrl, // 저장 시에는 단순화된 키로 저장
      'regDttm': regDttm,
    };
  }
}