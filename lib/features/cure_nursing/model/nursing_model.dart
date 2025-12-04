class NursingCategoryModel {
  final String categoryCd;
  final String? parentCategoryCd;
  final String categoryNm;
  final String? iconNm;
  final int sortNo;
  final List<NursingCategoryModel> children;

  NursingCategoryModel({
    required this.categoryCd,
    this.parentCategoryCd,
    required this.categoryNm,
    this.iconNm,
    required this.sortNo,
    required this.children,
  });

  factory NursingCategoryModel.fromJson(Map<String, dynamic> json) {
    var childrenJson = json['children'] as List? ?? [];
    List<NursingCategoryModel> childrenList = childrenJson
        .map((i) => NursingCategoryModel.fromJson(i))
        .toList();

    return NursingCategoryModel(
      categoryCd: json['categoryCd'] ?? '',
      parentCategoryCd: json['parentCategoryCd'],
      categoryNm: json['categoryNm'] ?? '',
      iconNm: json['iconNm'],
      sortNo: json['sortNo'] ?? 0,
      children: childrenList,
    );
  }
}