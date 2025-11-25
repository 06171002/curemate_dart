class Validators {
  static String? validateEmail(String email) {
    if (email.isEmpty) return "이메일을 입력해주세요.";
    final regex = RegExp(r'^[^@]+@[^@]+\.[^@]+');
    if (!regex.hasMatch(email)) return "올바른 이메일 형식이 아닙니다.";
    return null;
  }

  static String? validatePassword(String password) {
    if (password.isEmpty) return "비밀번호를 입력해주세요.";
    if (password.length < 6) return "비밀번호는 최소 6자 이상이어야 합니다.";
    return null;
  }

  static String? validatePasswordConfirm(String password, String confirm) {
    if (confirm.isEmpty) return "비밀번호 확인을 입력해주세요.";
    if (password != confirm) return "비밀번호가 일치하지 않습니다.";
    return null;
  }
}
