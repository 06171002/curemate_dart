import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:curemate/services/media_service.dart';
import 'package:curemate/services/auth_service.dart';
import 'package:curemate/features/auth/model/customer_model.dart';

class ProfileEditViewModel with ChangeNotifier {
  final MediaService _mediaService = MediaService();
  final AuthService _authService = AuthService();
  final ImagePicker _picker = ImagePicker();

  CustomerModel? _currentUser;
  File? _selectedImage;
  bool _isUploading = false;

  CustomerModel? get currentUser => _currentUser;
  File? get selectedImage => _selectedImage;
  bool get isUploading => _isUploading;

  void init(CustomerModel? user) {
    _currentUser = user;
    _selectedImage = null;
  }

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

  Future<bool> saveProfile({
    required String name,
    required String nickname,
    required String phone,
    required String birth,
    required String gender,
  }) async {
    if (_currentUser == null) return false;

    _isUploading = true;
    notifyListeners();

    try {
      String? mediaGroupSeq;

      // 1. 이미지 업로드 (새로 선택한 경우만)
      if (_selectedImage != null) {
        final String subDir = _currentUser!.custSeq.toString();

        final result = await _mediaService.uploadFiles(
          files: [_selectedImage!],
          mediaType: "customer",
          subDirectory: subDir,
        );

        mediaGroupSeq = result['mediaGroupSeq']?.toString();
      }

      // 2. API 요청 데이터 구성
      // 날짜 변환: 1980-01-16 -> 19800116 (입력값이 없으면 빈 문자열 그대로 유지)
      final String formattedBirth = birth.replaceAll('-', '');

      // 전화번호 변환: 010-1234-5678 -> 01012345678 (입력값이 없거나, - 없이 입력해도 정상 처리)
      final String formattedPhone = phone.replaceAll('-', '');

      final Map<String, dynamic> updateData = {
        "custSeq": _currentUser!.custSeq,
        "custNm": name,
        "custMobile": formattedPhone,
        "custNickname": nickname,
        "custBirth": formattedBirth,
        "custGenderCmcd": gender,
      };

      // 이미지가 변경되었을 때만 mediaGroupSeq 포함
      if (mediaGroupSeq != null) {
        updateData["custMediaGroupSeq"] = int.parse(mediaGroupSeq);
      }

      // 3. 실제 API 호출
      print(">> 서버 전송 데이터: $updateData");
      await _authService.updateProfile(updateData);

      return true;
    } catch (e) {
      print("저장 실패: $e");
      return false;
    } finally {
      _isUploading = false;
      notifyListeners();
    }
  }
}