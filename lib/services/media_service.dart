import 'dart:convert';
import 'dart:io';
import 'package:dio/dio.dart';
import 'package:curemate/services/api_service.dart';

class MediaService {
  static final MediaService _instance = MediaService._internal();
  factory MediaService() => _instance;
  MediaService._internal();

  final ApiService _apiService = ApiService();

  /// 공통 파일 업로드 함수
  /// [subDirectory]: 하위 디렉토리 경로 (프로필의 경우 custSeq)
  Future<Map<String, dynamic>> uploadFiles({
    required List<File> files,
    required String mediaType,
    String? mediaGroupSeq,
    String? subDirectory, // ✅ 추가됨
    Map<String, String>? attributes,
  }) async {
    try {
      // 1. 메타데이터(JSON) 생성 - 요청하신 포맷에 맞춤
      final Map<String, dynamic> metaData = {
        "mediaType": mediaType,
        "uploadType": (mediaGroupSeq != null && mediaGroupSeq.isNotEmpty) ? "M" : "N",
        "mediaGroupSeq": mediaGroupSeq ?? "",
        "subDirectory": subDirectory ?? "", // ✅ custSeq가 여기에 들어감
        "mediaAttr1": attributes?['attr1'] ?? "",
        "mediaAttr2": attributes?['attr2'] ?? "",
        "mediaAttr3": attributes?['attr3'] ?? "",
        "deleteFiles": [], // ✅ 빈 배열 명시
      };

      // 2. FormData 생성
      final formData = FormData();

      // fields에 JSON 추가
      formData.fields.add(MapEntry(
        "media",
        jsonEncode(metaData),
      ));

      // 파일 데이터 추가
      for (var file in files) {
        String fileName = file.path.split(Platform.pathSeparator).last;
        formData.files.add(MapEntry(
          "files",
          await MultipartFile.fromFile(
            file.path,
            filename: fileName,
          ),
        ));
      }

      // 3. API 전송
      final response = await _apiService.post(
        '/rest/media/upload',
        data: formData,
      );

      if (response.statusCode == 200) {
        return response.data['data'] ?? {};
      } else {
        throw Exception('업로드 실패: ${response.statusCode}');
      }
    } catch (e) {
      rethrow;
    }
  }
}