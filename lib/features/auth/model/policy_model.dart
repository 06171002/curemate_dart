class PolicyModel {
  final int policySeq;
  final String policyTypeCmcd;
  final String policyNm; // 제목
  final String? policyDesc; // 내용 (HTML)
  final String policyVersion;
  final String requiredYn; // "Y" or "N"
  final String? policyDescYn;

  PolicyModel({
    required this.policySeq,
    required this.policyTypeCmcd,
    required this.policyNm,
    this.policyDesc,
    required this.policyVersion,
    required this.requiredYn,
    this.policyDescYn,
  });

  // JSON 파싱
  factory PolicyModel.fromJson(Map<String, dynamic> json) {
    return PolicyModel(
      policySeq: json['policySeq'] as int,
      policyTypeCmcd: json['policyTypeCmcd'] ?? '',
      policyNm: json['policyNm'] ?? '',
      policyDesc: json['policyDesc'], // 목록 조회 시 null일 수 있음
      policyVersion: json['policyVersion'] ?? '',
      requiredYn: json['requiredYn'] ?? 'N',
      policyDescYn: json['policyDescYn'] ?? json['policy_desc_yn'] ?? 'N',
    );
  }

  // 필수 여부 헬퍼
  bool get isRequired => requiredYn == 'Y';

  // 상세 내용 존재 여부 (상세 API가 별도라면 목록에서는 false일 수 있음)
  bool get hasDetail {
    // 1순위: API에서 명시적으로 내려준 Y/N 플래그 확인
    if (policyDescYn != null && policyDescYn!.isNotEmpty) {
      return policyDescYn == 'Y';
    }
    // 2순위: 플래그가 없다면 기존처럼 본문 내용 유무로 판단 (하위 호환)
    return policyDesc != null && policyDesc!.isNotEmpty;
  }
}