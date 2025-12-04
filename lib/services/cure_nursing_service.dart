import 'package:curemate/services/api_service.dart';
import 'package:curemate/features/cure_nursing/model/nursing_model.dart';

class CureNursingService {
  final ApiService _apiService = ApiService();

  Future<List<NursingCategoryModel>> getCategoryList() async {
    try {
      final response = await _apiService.post('/rest/nursing/selectCategoryList');

      final data = response.data;
      if (data != null && data['code'] == "200") {
        final List<dynamic> list = data['data'] ?? [];
        return list.map((json) => NursingCategoryModel.fromJson(json)).toList();
      }
      return [];
    } catch (e) {
      print('간병 카테고리 조회 실패: $e');
      return [];
    }
  }
}