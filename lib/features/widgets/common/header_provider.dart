import 'package:flutter/material.dart';

class HeaderProvider with ChangeNotifier {
  String _title = '';
  bool _showBackButton = true;
  bool _showSettingButton = true;

  String get title => _title;
  bool get showBackButton => _showBackButton;
  bool get showSettingButton => _showSettingButton;

  void setTitle(String newTitle) {
    _title = newTitle;
    notifyListeners();
  }

  void setShowBackButton(bool value) {
    _showBackButton = value;
    notifyListeners();
  }

  void setSettingButton(bool value) {
    _showSettingButton = value;
    notifyListeners();
  }
}
