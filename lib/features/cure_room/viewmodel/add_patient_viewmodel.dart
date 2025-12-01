// lib/features/cure_room/viewmodel/add_patient_viewmodel.dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import 'package:curemate/services/cure_room_service.dart';
import 'package:curemate/services/media_service.dart';

class AddPatientViewModel extends ChangeNotifier {
  final CureRoomService _cureRoomService = CureRoomService();
  final MediaService _mediaService = MediaService();
  final ImagePicker _picker = ImagePicker();

  bool isSaving = false;

  /// 프로필 이미지 (선택 사항)
  File? selectedImage;

  void setSaving(bool v) {
    isSaving = v;
    notifyListeners();
  }

  /// 이미지 선택 (등록/수정 공통)
  Future<void> pickImage() async {
    try {
      final XFile? pickedFile = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1080,
        maxHeight: 1080,
        imageQuality: 85,
      );

      if (pickedFile != null) {
        selectedImage = File(pickedFile.path);
        notifyListeners();
      }
    } catch (e) {
      debugPrint('환자 이미지 선택 오류: $e');
    }
  }

  // 🔹 [추가] 수정/등록 공통으로 쓸 “프로필 이미지 업로드 전용 함수”
  Future<int?> uploadPatientProfileImage({
    required int cureSeq,
  }) async {
    if (selectedImage == null) return null;

    try {
      final result = await _mediaService.uploadFiles(
        files: [selectedImage!],
        mediaType: "patient",
        subDirectory: cureSeq.toString(),
      );

      final mediaGroupSeqStr = result['mediaGroupSeq']?.toString();
      if (mediaGroupSeqStr == null) return null;

      return int.parse(mediaGroupSeqStr);
    } catch (e) {
      debugPrint('프로필 이미지 업로드 실패: $e');
      return null;
    }
  }

  

  /// 환자 저장 API 호출 (등록 + 수정 겸용)
  ///
  /// ✅ 필수: cureSeq, patientNm, patientBirthday
  /// ✅ 등록: curePatientSeq == null
  /// ✅ 수정: curePatientSeq != null
  Future<bool> savePatient({
    required int cureSeq,
    int? curePatientSeq,             // 👈 추가: 수정용 PK
    int? custSeq,                    // 회원인 환자면 세팅, 아니면 null
    required String patientNm,
    required String patientBirthday, // 'yyyy-MM-dd' 형태로 들어옴
    String? patientGenderCmcd,       // "man"/"woman"
    String? patientBloodTypeCmcd,    // "A+", "O-" 등
    int? patientWeight,
    int? patientHeight,
  }) async {
    try {
      setSaving(true);

      // 1) 생일을 API 형식(YYYYMMDD)으로 변환
      final birthForApi = patientBirthday.replaceAll('-', '');

      // 2) 이미지가 있으면 먼저 /rest/media/upload (mediaType: "patient")
      String? mediaGroupSeqStr;
      if (selectedImage != null) {
        final result = await _mediaService.uploadFiles(
          files: [selectedImage!],
          mediaType: "patient",
          subDirectory: cureSeq.toString(), // 또는 "1" 고정도 가능
        );

        mediaGroupSeqStr = result['mediaGroupSeq']?.toString();
      }

      // 3) mergeCurePatient에 넘길 데이터 구성
      final Map<String, dynamic> payload = {
        "cureSeq": cureSeq,
        "patientTypeCmcd": "manual", // 고정 값(수기등록)
        "custSeq": custSeq,
        "patientNm": patientNm,
        "patientBirthday": birthForApi,
        "patientGenderCmcd": patientGenderCmcd,
        "patientBloodTypeCmcd": patientBloodTypeCmcd,
        "patientWeight": patientWeight,
        "patientHeight": patientHeight,
      };

      // 👇 수정일 때만 PK 세팅
      if (curePatientSeq != null) {
        payload["curePatientSeq"] = curePatientSeq;
      }

      if (mediaGroupSeqStr != null) {
        payload["patientMediaGroupSeq"] = int.parse(mediaGroupSeqStr);
      }

      // 4) 실제 API 호출 (/rest/cure/mergeCurePatient)
      await _cureRoomService.saveCurePatient(payload);

      return true;
    } catch (e) {
      debugPrint('savePatient 실패: $e');
      return false;
    } finally {
      setSaving(false);
    }
  }
}
