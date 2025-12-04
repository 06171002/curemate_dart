import 'package:dio/dio.dart';
import 'package:curemate/services/api_service.dart';
import 'package:curemate/common/sdui/model/sdui_model.dart';

class SduiService {
  final ApiService _apiService = ApiService();

  /// 화면 코드로 UI 구성을 조회합니다.
  Future<SduiNode?> getScreen(String screenCd) async {
    try {
      // GET 요청: /api/sdui/screen/NURSING_WRITE
      final Response response = await _apiService.get('/api/sdui/screen/$screenCd');

      // 응답 처리 (서버의 공통 응답 구조에 맞춤)
      final Map<String, dynamic> body = response.data;

      if (body['code'] == '200' && body['data'] != null) {
        return SduiNode.fromJson(body['data']);
      } else {
        print('SDUI 조회 실패: ${body['message']}');
        return null;
      }
    } catch (e) {
      print('SDUI 네트워크 오류: $e');
      return null;
    }
  }
}