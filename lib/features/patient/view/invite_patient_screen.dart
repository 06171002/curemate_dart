import 'package:curemate/features/patient/view/email_invite_screen.dart';
import 'package:flutter/material.dart';
import 'package:curemate/app/theme/app_colors.dart';
import 'package:url_launcher/url_launcher.dart';

class InvitePatientPage extends StatelessWidget {
  const InvitePatientPage({super.key});

  Future<void> _inviteViaKakao() async {
    // TODO: kakao_flutter_sdk_share 연동
    const kakaoUrl = "kakaolink://send";
    const installUrl =
        "https://play.google.com/store/apps/details?id=com.kakao.talk";

    if (await canLaunchUrl(Uri.parse(kakaoUrl))) {
      await launchUrl(Uri.parse(kakaoUrl));
    } else {
      await launchUrl(Uri.parse(installUrl));
    }
  }

  void _goToEmailInvite(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const EmailInvitePage()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("환자 초대하기"),
        backgroundColor: AppColors.mainBtn,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ListTile(
              leading: const Icon(Icons.chat, color: Colors.yellow),
              title: const Text("카카오톡 초대하기"),
              subtitle: const Text("카카오톡으로 초대장을 전송합니다."),
              onTap: _inviteViaKakao,
            ),
            ListTile(
              leading: const Icon(Icons.email, color: AppColors.mainBtn),
              title: const Text("이메일 초대하기"),
              subtitle: const Text("이메일 주소를 입력해 초대장을 전송합니다."),
              onTap: () => _goToEmailInvite(context),
            ),
          ],
        ),
      ),
    );
  }
}
