import 'package:flutter/material.dart';
import 'package:curemate/app/theme/app_colors.dart';
class EmailInvitePage extends StatefulWidget {
  const EmailInvitePage({super.key});

  @override
  State<EmailInvitePage> createState() => _EmailInvitePageState();
}

class _EmailInvitePageState extends State<EmailInvitePage> {
  final TextEditingController _emailController = TextEditingController();

  Future<void> _sendInvite() async {
    final email = _emailController.text.trim();
    if (email.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("이메일을 입력해주세요.")),
      );
      return;
    }

    // TODO: 서버 API 연결
    print("📨 서버에 초대 요청: $email");

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("초대장이 전송되었습니다.")),
    );
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("이메일 초대하기")),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: _emailController,
                decoration: const InputDecoration(
                  labelText: "이메일 주소",
                  border: OutlineInputBorder(),
                ),
              ),
            ),
            const SizedBox(width: 8),
            ElevatedButton(
              onPressed: _sendInvite,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.mainBtn,
                foregroundColor: Colors.white,
              ),
              child: const Text("전송"),
            ),
          ],
        ),
      ),
    );
  }
}
