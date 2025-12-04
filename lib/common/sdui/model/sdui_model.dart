class SduiNode {
  final int? nodeSeq;
  final int? parentNodeSeq;
  final String? nodeTypeCd;      // 예: COLUMN, SELECT, INPUT_TEXT
  final String? nodeKey;         // 화면 내부 식별용 키
  final String? dataBindingKey;  // 실제 데이터 저장 시 사용할 키 (DB 컬럼 매핑 등)
  final String? label;
  final Map<String, dynamic> props;

  // 자식 노드 리스트 (재귀 구조)
  final List<SduiNode>? children;

  SduiNode({
    this.nodeSeq,
    this.parentNodeSeq,
    this.nodeTypeCd,
    this.nodeKey,
    this.dataBindingKey,
    this.label,
    this.props = const {},
    this.children,
  });

  factory SduiNode.fromJson(Map<String, dynamic> json) {
    return SduiNode(
      nodeSeq: json['nodeSeq'],
      parentNodeSeq: json['parentNodeSeq'],

      // [수정] 백엔드 응답 키값 변경 반영
      nodeTypeCd: json['nodeTypeCd'],
      nodeKey: json['nodeKey'],
      dataBindingKey: json['dataBindingKey'],

      label: json['label'],

      // props가 null일 경우 빈 Map으로 초기화하여 Null Safety 보장
      props: json['props'] != null ? Map<String, dynamic>.from(json['props']) : {},

      // 자식 노드가 있을 경우 재귀적으로 파싱
      children: (json['children'] as List<dynamic>?)
          ?.map((e) => SduiNode.fromJson(e))
          .toList(),
    );
  }

  // 디버깅이나 직렬화가 필요할 때 사용
  Map<String, dynamic> toJson() {
    return {
      'nodeSeq': nodeSeq,
      'parentNodeSeq': parentNodeSeq,
      'nodeTypeCd': nodeTypeCd,
      'nodeKey': nodeKey,
      'dataBindingKey': dataBindingKey,
      'label': label,
      'props': props,
      'children': children?.map((e) => e.toJson()).toList(),
    };
  }
}