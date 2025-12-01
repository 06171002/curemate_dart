// lib/features/story/viewmodel/story_viewmodel.dart

import 'package:curemate/utils/logger.dart';
import 'package:flutter/material.dart';
import '../../../services/story_service.dart';
import '../model/story_model.dart';

class StoryViewModel extends ChangeNotifier {
  final StoryService _storyService = StoryService();

  List<StoryModel> _stories = [];
  List<StoryModel> get stories => _stories;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  bool _isFetchingComments = false;
  bool get isFetchingComments => _isFetchingComments;

  StoryViewModel() {
    fetchPublicStories();
  }

  Future<void> fetchPublicStories() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _stories = await _storyService.getPublicStoryList();
    } catch (e) {
      final errorMsg = "데이터를 불러오는 데 실패했습니다: $e";
      _errorMessage = errorMsg;
      Logger.e(errorMsg);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // 특정 뿌듯일지의 댓글 목록을 계층 구조로 변환하여 불러오는 메서드
  Future<List<CureFeedback>> fetchFeedbacks(int cureStorySeq) async {
    _isFetchingComments = true;
    notifyListeners();

    try {
      Logger.d('[StoryViewModel] 댓글 목록($cureStorySeq) 가져오기 시작');
      final flatList = await _storyService.getFeedbacks(cureStorySeq);
      Logger.d('[StoryViewModel] 평평한 댓글 목록(${flatList.length}개) 가져오기 성공');

      // 계층 구조로 변환하는 로직
      final Map<int, CureFeedback> feedbackMap = {};
      final List<CureFeedback> topLevelFeedbacks = [];

      // 모든 댓글을 Map에 저장
      for (var feedback in flatList) {
        feedbackMap[feedback.cureFeedbackSeq] = feedback;
      }

      // 대댓글을 부모의 replies 리스트에 추가
      for (var feedback in flatList) {
        if (feedback.cureFeedbackRefSeq != 0) {
          final parent = feedbackMap[feedback.cureFeedbackRefSeq];
          parent?.replies.add(feedback);
        } else {
          topLevelFeedbacks.add(feedback);
        }
      }

      Logger.d('[StoryViewModel] 계층형 댓글 구조 변환 완료, 최상위 댓글: ${topLevelFeedbacks.length}개');
      return topLevelFeedbacks;

    } catch (e) {
      Logger.e('[StoryViewModel] 댓글 목록 가져오기 실패: $e');
      return []; // 에러 시 빈 리스트 반환
    } finally {
      _isFetchingComments = false;
      notifyListeners();
    }
  }
}
