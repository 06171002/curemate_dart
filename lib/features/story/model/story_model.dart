// lib/features/story/model/story_model.dart

// 대댓글(replies)과 신규 필드를 포함하여 수정한 최종 모델입니다.

class StoryModel {
  final int cureStorySeq;
  final int cureSeq;
  final int custSeq;
  final String cureStoryDesc;
  final int storyMediaGroupSeq;
  final String releaseYn;
  final String feedbackYn;
  final String interestYn;
  final String delYn;
  final String regId;
  final String regDttm;
  final String updId;
  final String updDttm;

  final List<CureFeedback> feedbacks;
  final MediaGroup? storyProfile;
  final MediaGroup? cureProfile;
  final MediaGroup? custProfile;

  final String custNm;
  final String custNickname;
  final int custMediaGroupSeq;
  final String withdrawYn;
  final String withdrawDttm;
  final String cureNm;
  final String cureDesc;
  final int cureMediaGroupSeq;
  final int cheeringCount;
  final int feedbackCount;

  StoryModel({
    required this.cureStorySeq,
    required this.cureSeq,
    required this.custSeq,
    required this.cureStoryDesc,
    required this.storyMediaGroupSeq,
    required this.releaseYn,
    required this.feedbackYn,
    required this.interestYn,
    required this.delYn,
    required this.regId,
    required this.regDttm,
    required this.updId,
    required this.updDttm,
    required this.feedbacks,
    this.storyProfile,
    this.cureProfile,
    this.custProfile,
    required this.custNm,
    required this.custNickname,
    required this.custMediaGroupSeq,
    required this.withdrawYn,
    required this.withdrawDttm,
    required this.cureNm,
    required this.cureDesc,
    required this.cureMediaGroupSeq,
    required this.cheeringCount,
    required this.feedbackCount,
  });

  factory StoryModel.fromJson(Map<String, dynamic> json) {
    var feedbackList = json['feedbacks'] as List?;
    List<CureFeedback> feedbacks = feedbackList != null
        ? feedbackList.map((i) => CureFeedback.fromJson(i)).toList()
        : [];

    return StoryModel(
      cureStorySeq: json['cureStorySeq'] ?? 0,
      cureSeq: json['cureSeq'] ?? 0,
      custSeq: json['custSeq'] ?? 0,
      cureStoryDesc: json['cureStoryDesc'] ?? '',
      storyMediaGroupSeq: json['storyMediaGroupSeq'] ?? 0,
      releaseYn: json['releaseYn'] ?? 'N',
      feedbackYn: json['feedbackYn'] ?? 'N',
      interestYn: json['interestYn'] ?? 'N',
      delYn: json['delYn'] ?? 'N',
      regId: json['regId'] ?? '',
      regDttm: json['regDttm'] ?? '',
      updId: json['updId'] ?? '',
      updDttm: json['updDttm'] ?? '',
      feedbacks: feedbacks,
      storyProfile: json['storyProfile'] != null ? MediaGroup.fromJson(json['storyProfile']) : null,
      cureProfile: json['cureProfile'] != null ? MediaGroup.fromJson(json['cureProfile']) : null,
      custProfile: json['custProfile'] != null ? MediaGroup.fromJson(json['custProfile']) : null,
      custNm: json['custNm'] ?? '',
      custNickname: json['custNickname'] ?? '',
      custMediaGroupSeq: json['custMediaGroupSeq'] ?? 0,
      withdrawYn: json['withdrawYn'] ?? 'N',
      withdrawDttm: json['withdrawDttm'] ?? '',
      cureNm: json['cureNm'] ?? '',
      cureDesc: json['cureDesc'] ?? '',
      cureMediaGroupSeq: json['cureMediaGroupSeq'] ?? 0,
      cheeringCount: json['cheeringCount'] ?? 0,
      feedbackCount: json['feedbackCount'] ?? 0,
    );
  }
}

class CureFeedback {
  final int cureFeedbackSeq;
  final int custSeq;
  final String? cureFeedbackTypeCmcd;
  final String? cureFeedbackTypeCmnm;
  final int cureRefSeq;
  final int cureFeedbackRefSeq;
  final int feedbackMediaGroupSeq;
  final String cureFeedbackDesc;
  final String? delYn;
  final String? regId;
  final String regDttm;
  final String? updId;
  final String? updDttm;

  final String custNm;
  final String custNickname;
  final int custMediaGroupSeq;
  final String withdrawYn;
  final String? withdrawDttm;
  final String cheeringYn;
  final MediaGroup? custProfile;

  // 대댓글을 담기 위한 리스트
  List<CureFeedback> replies = [];

  CureFeedback({
    required this.cureFeedbackSeq,
    required this.custSeq,
    this.cureFeedbackTypeCmcd,
    this.cureFeedbackTypeCmnm,
    required this.cureRefSeq,
    required this.cureFeedbackRefSeq,
    required this.feedbackMediaGroupSeq,
    required this.cureFeedbackDesc,
    this.delYn,
    this.regId,
    required this.regDttm,
    this.updId,
    this.updDttm,
    required this.custNm,
    required this.custNickname,
    required this.custMediaGroupSeq,
    required this.withdrawYn,
    this.withdrawDttm,
    required this.cheeringYn,
    this.custProfile,
  });

  factory CureFeedback.fromJson(Map<String, dynamic> json) {
    return CureFeedback(
      cureFeedbackSeq: json['cureFeedbackSeq'] ?? 0,
      custSeq: json['custSeq'] ?? 0,
      cureFeedbackTypeCmcd: json['cureFeedbackTypeCmcd'],
      cureFeedbackTypeCmnm: json['cureFeedbackTypeCmnm'],
      cureRefSeq: json['cureRefSeq'] ?? 0,
      cureFeedbackRefSeq: json['cureFeedbackRefSeq'] ?? 0,
      feedbackMediaGroupSeq: json['feedbackMediaGroupSeq'] ?? 0,
      cureFeedbackDesc: json['cureFeedbackDesc'] ?? '',
      delYn: json['delYn'],
      regId: json['regId'],
      regDttm: json['regDttm'] ?? '',
      updId: json['updId'],
      updDttm: json['updDttm'],
      custNm: json['custNm'] ?? '',
      custNickname: json['custNickname'] ?? '',
      custMediaGroupSeq: json['custMediaGroupSeq'] ?? 0,
      withdrawYn: json['withdrawYn'] ?? 'N',
      withdrawDttm: json['withdrawDttm'],
      cheeringYn: json['cheeringYn'] ?? 'N',
      custProfile: json['custProfile'] != null ? MediaGroup.fromJson(json['custProfile']) : null,
    );
  }
}

class MediaGroup {
  final int mediaGroupSeq;
  final int mediaGroupDetailSeq;
  final String? mediaGroupAttr1;
  final String? mediaGroupAttr2;
  final String? mediaGroupAttr3;
  final List<MediaGroupDetail> detailList;
  final String? regId;
  final String? regDttm;
  final String? updId;
  final String? updDttm;
  final String? code;
  final String? msg;
  final String? physicsPath;
  final String? physicsUrl;

  MediaGroup({
    required this.mediaGroupSeq,
    required this.mediaGroupDetailSeq,
    this.mediaGroupAttr1,
    this.mediaGroupAttr2,
    this.mediaGroupAttr3,
    required this.detailList,
    this.regId,
    this.regDttm,
    this.updId,
    this.updDttm,
    this.code,
    this.msg,
    this.physicsPath,
    this.physicsUrl,
  });

  factory MediaGroup.fromJson(Map<String, dynamic> json) {
    var detailListJson = json['detailList'] as List?;
    List<MediaGroupDetail> details = detailListJson != null
        ? detailListJson.map((i) => MediaGroupDetail.fromJson(i)).toList()
        : [];

    return MediaGroup(
      mediaGroupSeq: json['mediaGroupSeq'] ?? 0,
      mediaGroupDetailSeq: json['mediaGroupDetailSeq'] ?? 0,
      mediaGroupAttr1: json['mediaGroupAttr1'],
      mediaGroupAttr2: json['mediaGroupAttr2'],
      mediaGroupAttr3: json['mediaGroupAttr3'],
      detailList: details,
      regId: json['regId'],
      regDttm: json['regDttm'],
      updId: json['updId'],
      updDttm: json['updDttm'],
      code: json['code'],
      msg: json['msg'],
      physicsPath: json['physicsPath'],
      physicsUrl: json['physicsUrl'],
    );
  }
}

class MediaGroupDetail {
  final int mediaGroupDetailSeq;
  final int mediaGroupSeq;
  final int displaySortNo;
  final String? mediaGroupDetailAttr1;
  final String? mediaGroupDetailAttr2;
  final String? mediaGroupDetailAttr3;
  final bool isActive;

  final String? physicsUrl;
  final String? mediaUrl;
  final String? mediaDetailUrl;
  final String? mediaThumbUrl;
  final String? mediaFullUrl;

  MediaGroupDetail({
    required this.mediaGroupDetailSeq,
    required this.mediaGroupSeq,
    required this.displaySortNo,
    this.mediaGroupDetailAttr1,
    this.mediaGroupDetailAttr2,
    this.mediaGroupDetailAttr3,
    required this.isActive,
    this.physicsUrl,
    this.mediaUrl,
    this.mediaDetailUrl,
    this.mediaThumbUrl,
    this.mediaFullUrl,
  });

  factory MediaGroupDetail.fromJson(Map<String, dynamic> json) {
    return MediaGroupDetail(
      mediaGroupDetailSeq: json['mediaGroupDetailSeq'] ?? 0,
      mediaGroupSeq: json['mediaGroupSeq'] ?? 0,
      displaySortNo: json['displaySortNo'] ?? 0,
      mediaGroupDetailAttr1: json['mediaGroupDetailAttr1'],
      mediaGroupDetailAttr2: json['mediaGroupDetailAttr2'],
      mediaGroupDetailAttr3: json['mediaGroupDetailAttr3'],
      isActive: json['isActive'] ?? false,
      physicsUrl: json['physicsUrl'],
      mediaUrl: json['mediaUrl'],
      mediaDetailUrl: json['mediaDetailUrl'],
      mediaThumbUrl: json['mediaThumbUrl'],
      mediaFullUrl: json['mediaFullUrl'],
    );
  }
}
