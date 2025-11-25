class PolicyModel {
  final int policySeq;
  final String policyTypeCmcd;
  final String policyNm; // 제목
  final String? policyDesc; // 내용 (HTML)
  final String policyVersion;
  final String requiredYn; // "Y" or "N"

  PolicyModel({
    required this.policySeq,
    required this.policyTypeCmcd,
    required this.policyNm,
    this.policyDesc,
    required this.policyVersion,
    required this.requiredYn,
  });

  // JSON 파싱
  factory PolicyModel.fromJson(Map<String, dynamic> json) {
    return PolicyModel(
      policySeq: json['policySeq'],
      policyTypeCmcd: json['policyTypeCmcd'] ?? '',
      policyNm: json['policyNm'] ?? '',
      policyDesc: json['policyDesc'],
      policyVersion: json['policyVersion'] ?? '',
      requiredYn: json['requiredYn'] ?? 'N',
    );
  }

  // 필수 여부 헬퍼
  bool get isRequired => requiredYn == 'Y';

  // 상세 내용 존재 여부 (화살표 표시용)
  bool get hasDetail => policyDesc != null && policyDesc!.isNotEmpty;
}