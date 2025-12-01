// lib/services/story_service.dart
import 'package:curemate/utils/logger.dart';

import '../features/story/model/story_model.dart';
import 'api_service.dart';

class StoryService {
  final ApiService _api = ApiService();

  /// 전체 공개된 뿌듯일지 목록을 불러옵니다.
  Future<List<StoryModel>> getPublicStoryList() async {
    Logger.d('[StoryService] 뿌듯일지 목록 API 호출 시작...');

    try {
      final response = await _api.post('/rest/story/selectPublicCureStoryList');

      if (response.data is Map<String, dynamic>) {
        final apiResponse = response.data as Map<String, dynamic>;

        if (apiResponse['code'] == '200' && apiResponse['data'] is List) {
          final List<dynamic> storyListJson = apiResponse['data'];
          Logger.d('[StoryService] API 성공, ${storyListJson.length}개의 데이터를 받았습니다.');
          return storyListJson.map((json) => StoryModel.fromJson(json)).toList();
        } else {
          Logger.e("[StoryService] 서버 응답 실패 - Code: ${apiResponse['code']}, Message: ${apiResponse['message']}");
          return [];
        }
      } else {
        Logger.e("[StoryService] API 응답 형식이 올바르지 않습니다. 받은 데이터: ${response.data}");
        return [];
      }
    } catch (e) {
      Logger.e("뿌듯일지 목록 로딩 실패: $e");
      return [];
    }
  }

  /// 특정 뿌듯일지의 댓글 목록을 불러옵니다.
  Future<List<CureFeedback>> getFeedbacks(int cureStorySeq) async {
    Logger.d('[StoryService] 댓글 목록 API 호출 시작, cureStorySeq: $cureStorySeq');
    try {
      final response = await _api.post(
        '/rest/story/selectCureFeedbackList',
        data: {
          "param": {
            "cureFeedbackTypeCmcd": "cure",
            "cureRefSeq": cureStorySeq,
          }
        },
      );

      if (response.data is Map<String, dynamic>) {
        final apiResponse = response.data as Map<String, dynamic>;
        if (apiResponse['code'] == '200' && apiResponse['data'] is List) {
          final List<dynamic> feedbackListJson = apiResponse['data'];
          Logger.d('[StoryService] 댓글 API 성공, ${feedbackListJson.length}개의 데이터를 받았습니다.');
          return feedbackListJson.map((json) => CureFeedback.fromJson(json)).toList();
        } else {
          Logger.e("[StoryService] 댓글 서버 응답 실패 - Code: ${apiResponse['code']}, Message: ${apiResponse['message']}");
          return [];
        }
      } else {
        Logger.e("[StoryService] 댓글 API 응답 형식이 올바르지 않습니다. 받은 데이터: ${response.data}");
        return [];
      }
    } catch (e) {
      Logger.e("댓글 목록 로딩 실패: $e");
      return [];
    }
  }
}
