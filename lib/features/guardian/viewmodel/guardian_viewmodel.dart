import 'package:curemate/services/api_service.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';


class GuardianViewModel with ChangeNotifier {
  final ApiService _apiService = ApiService(); // ApiService 인스턴스

  final TextEditingController nameController = TextEditingController();
  final TextEditingController phoneController = TextEditingController();
  final TextEditingController birthController = TextEditingController();
  String gender = 'male';

  bool isLoading = false;

  void setIsLoading(bool value) {
    isLoading = value;
    notifyListeners();
  }

  void setGender(String newGender) {
    gender = newGender;
    notifyListeners();
  }

  String formatPhoneNumber(String value) {
    if (value.isEmpty) return '';
    final String cleanNumber = value.replaceAll(RegExp(r'[^0-9]'), '');
    if (cleanNumber.length == 11) {
      return '${cleanNumber.substring(0, 3)}-${cleanNumber.substring(3, 7)}-${cleanNumber.substring(7, 11)}';
    } else if (cleanNumber.length == 10) {
      return '${cleanNumber.substring(0, 3)}-${cleanNumber.substring(3, 6)}-${cleanNumber.substring(6, 10)}';
    }
    return cleanNumber;
  }

  Future<void> selectDate(BuildContext context) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      birthController.text = DateFormat('yyyy-MM-dd').format(picked);
      notifyListeners();
    }
  }

  Future<void> submitForm(BuildContext context) async {
    if (nameController.text.isEmpty ||
        phoneController.text.isEmpty ||
        birthController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('모든 필수 항목을 입력해주세요.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setIsLoading(true);
    try {
      final response = await _apiService.post(
        '/api/guardian/', // Node.js 서버의 엔드포인트
        data: {
          'NAME': nameController.text,
          'PHONE': phoneController.text,
          'BIRTH': birthController.text,
          'GENDER': gender,
        },
      );

      if (response.statusCode == 201 || response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('보호자 등록 성공'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.of(context).pop();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('등록 실패: ${response.data}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('에러 발생: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setIsLoading(false);
    }
  }

  void disposeControllers() {
    nameController.dispose();
    phoneController.dispose();
    birthController.dispose();
  }
}
