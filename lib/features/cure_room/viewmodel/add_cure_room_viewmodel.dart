// lib/features/cure_room/viewmodel/add_cure_room_viewmodel.dart

import 'dart:io';
import 'package:curemate/features/cure_room/model/curer_model.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:curemate/services/media_service.dart';
import 'package:curemate/services/cure_room_service.dart';
import 'package:curemate/features/auth/viewmodel/auth_viewmodel.dart'; // 사용자 정보(custSeq) 참조용

class AddCureRoomViewModel with ChangeNotifier {
  final MediaService _mediaService = MediaService();
  final CureRoomService _cureRoomService = CureRoomService();
  final ImagePicker _picker = ImagePicker();

  File? _selectedImage;
  bool _isUploading = false;
  String? _errorMessage;

  File? get selectedImage => _selectedImage;
  bool get isUploading => _isUploading;
  String? get errorMessage => _errorMessage;

  // 이미지 선택
  Future<void> pickImage() async {
    try {
      final XFile? pickedFile = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1080,
        maxHeight: 1080,
        imageQuality: 85,
      );

      if (pickedFile != null) {
        _selectedImage = File(pickedFile.path);
        notifyListeners();
      }
    } catch (e) {
      print("이미지 선택 오류: $e");
    }
  }

  // 큐어룸 저장 (이미지 업로드 포함)
  Future<CurerModel?> createCureRoom({
    required int userCustSeq, // 로그인한 사용자의 시퀀스 (이미지 경로용)
    required String name,
    required String description,
    required bool isPublic, // releaseYn
  }) async {
    _isUploading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      String? mediaGroupSeq;

      // 1. 이미지가 선택되었다면 업로드 수행
      if (_selectedImage != null) {
        // subDirectory는 사용자 시퀀스를 사용 (프로필과 동일 로직)
        final String subDir = userCustSeq.toString();

        final result = await _mediaService.uploadFiles(
          files: [_selectedImage!],
          mediaType: "cureRoom", // 큐어룸 전용 미디어 타입으로 지정
          subDirectory: subDir,
        );

        mediaGroupSeq = result['mediaGroupSeq']?.toString();
      }

      // 2. API 요청 데이터 구성
      final Map<String, dynamic> payload = {
        "cureNm": name,
        "cureDesc": description,
        "cureMediaGroupSeq": mediaGroupSeq != null ? int.parse(mediaGroupSeq) : null,
        "releaseYn": isPublic ? "Y" : "N",
        // "cureSeq": null // 추가이므로 null 또는 생략
      };

      // 3. 저장 API 호출
      final CurerModel newCurer = await _cureRoomService.saveCureRoom(payload);

      return newCurer;
    } catch (e) {
      _errorMessage = e.toString();
      return null;
    } finally {
      _isUploading = false;
      notifyListeners();
    }
  }
}