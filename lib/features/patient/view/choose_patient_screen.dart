import 'package:curemate/app/route_observer.dart';
import 'package:curemate/app/theme/app_colors.dart';
import 'package:curemate/app/token_manager.dart';
import 'package:curemate/features/guardian/view/add_guardian_screen.dart';
import 'package:curemate/features/patient/view/add_patient_screen.dart';
import 'package:curemate/features/patient/view/main_screen.dart';
import 'package:curemate/features/patient/viewmodel/patient_viewmodel.dart';
import 'package:curemate/features/widgets/common/bottom_nav_provider.dart';
import 'package:curemate/features/widgets/common/header_provider.dart';
import 'package:curemate/features/widgets/common/widgets.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

class PatientSelectionScreen extends StatefulWidget {
  final bool showInviteCheck;
  const PatientSelectionScreen({super.key, this.showInviteCheck = false});

  @override
  State<PatientSelectionScreen> createState() => _PatientSelectionScreenState();
}

class _PatientSelectionScreenState extends State<PatientSelectionScreen>
    with RouteAware {
  bool _hasShownPopup = false;
  Map<String, dynamic>? _inviteData;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async{
      // _checkGuardianStatusAndShowPopup();//잠시 주석처리 (초대링크에서 자꾸 뜸)
      // _loadPatients();
      // ✅ 로그인 직후 한 번만 초대 토큰 체크
      if (widget.showInviteCheck) {
        await _checkInviteToken();
      }
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final route = ModalRoute.of(context);
    if (route is PageRoute) {
      routeObserver.subscribe(this, route);
    }
  }

  @override
  void dispose() {
    routeObserver.unsubscribe(this);
    super.dispose();
  }

  @override
  void didPopNext() {
    _loadPatients();
  }

  /// 🔹 보호자 등록 여부 확인 + 팝업
  Future<void> _checkGuardianStatusAndShowPopup() async {
    final patientVM = Provider.of<PatientViewModel>(context, listen: false);
    await patientVM.checkGuardianStatus();

    if (!mounted) return;
    if (!patientVM.isGuardianRegistered && !_hasShownPopup) {
      setState(() => _hasShownPopup = true);

      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => Dialog(
          insetPadding: const EdgeInsets.symmetric(horizontal: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: const SizedBox(height: 500, child: GuardianRegistrationPage()),
        ),
      );
    }
  }

  /// 🔹 환자 목록 불러오기
  Future<void> _loadPatients() async {
    final patientVM = Provider.of<PatientViewModel>(context, listen: false);
    await patientVM.fetchPatients();
  }

  /// 🔹 초대 토큰 서버 검증
  Future<void> _checkInviteToken() async {
    final token = TokenManager.inviteToken;
    if (token == null) return;

    final vm = Provider.of<PatientViewModel>(context, listen: false);
    try {
      final invite = await vm.fetchInviteByToken(token);
      debugPrint("===== 📩 서버에서 받은 초대 응답 =====");
      debugPrint(invite.toString());
      debugPrint("=================================");

      if (invite != null && invite['invite_status'] == 'PENDING') {
        setState(() => _inviteData = invite);

        // ✅ 초대 다이얼로그 띄우기
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _showInviteDialog(invite);
        });
      } else {
        TokenManager.clear();
      }
    } catch (e) {
      debugPrint("초대 검증 실패: $e");
      TokenManager.clear();
    }
  }

  /// 🔹 초대 다이얼로그
void _showInviteDialog(Map<String, dynamic> invite) {
  final inviterName = invite['inviter_name'] ?? '알 수 없음';
  final token = invite['invite_token'];

  final currentUser = Supabase.instance.client.auth.currentUser;

  showDialog(
    context: context,
    barrierDismissible: false,
    builder: (context) => AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: const Center(child: Text("📨 초대 알림")),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            "$inviterName님이 회원님을 환자로 초대했습니다.",
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),
          if (currentUser != null) ...[
            Text("현재 로그인 계정: ${currentUser.email}",
                style: const TextStyle(fontWeight: FontWeight.w500)),
            const SizedBox(height: 10),
            const Text("이 계정으로 초대를 수락하시겠습니까?",
                textAlign: TextAlign.center),
          ] else
            const Text("초대를 수락하려면 먼저 로그인해야 합니다."),
        ],
      ),
      actionsPadding: const EdgeInsets.all(16),
      actions: [
        if (currentUser != null) ...[
          // ✅ 수락 버튼
          ElevatedButton(
            onPressed: () async {
              final vm = Provider.of<PatientViewModel>(context, listen: false);
              await vm.acceptInvite(token);
              ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("초대를 수락했습니다.")));
              TokenManager.clear();
              setState(() => _inviteData = null);
              Navigator.pop(context);
              await vm.fetchPatients();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.mainBtn,
              foregroundColor: Colors.white,
            ),
            child: const Text("이 계정으로 수락"),
          ),
          const SizedBox(width: 12),
          // ❌ 다른 계정으로
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              await Supabase.instance.client.auth.signOut();
              // await GoogleSignIn().signOut(); 
              // TokenManager.clear();
              Navigator.pushReplacementNamed(context, "/login");
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text("다른 계정으로"),
          ),
        ] else
          ElevatedButton(
            onPressed: () {
              Navigator.pushReplacementNamed(context, "/login");
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.mainBtn,
              foregroundColor: Colors.white,
            ),
            child: const Text("로그인하기"),
          ),
      ],
    ),
  );
}



  @override
  Widget build(BuildContext context) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final header = Provider.of<HeaderProvider>(context, listen: false);
      header.setTitle('관리할 환자');
      header.setShowBackButton(false);
    });

    return Container( // 1. SafeArea를 Container로 감쌉니다.
        color: Colors.white, // 2. Container에 원하는 색상을 지정합니다.
        child: SafeArea(
            top: true,
            child: Scaffold(
              body: Column(
                children: [
                  const PatientScreenHeader(),
                  _buildSubheader(context),
                  Expanded(
                    child: Consumer<PatientViewModel>(
                      builder: (context, viewModel, child) {
                        if (viewModel.isLoading) {
                          return const Center(child: CircularProgressIndicator());
                        }
                        if (viewModel.errorMessage != null) {
                          return Center(child: Text('오류: ${viewModel.errorMessage}'));
                        }

                        return ListView(
                          children: [
                            if (viewModel.patients.isEmpty)
                              _buildEmptyPatientText()
                            else
                              ...viewModel.patients.map((p) => _buildPatientCard(
                                    context: context,
                                    patientId: p['id'],
                                    name: p['name'] ?? '이름 없음',
                                    details: _makeDetails(p),
                                    isMember: p['USER_ID'] != null,
                                    hasUpdates: false,
                                    profileImgUrl: p['profileImgUrl'],
                                  )),
                          ],
                        );
                      },
                    ),
                  ),
                ],
              ),
        ),
        ),
    );
  }

  /// 🔹 환자 없을 때 메시지
  Widget _buildEmptyPatientText() => Align(
        alignment: Alignment.topCenter,
        child: Padding(
          padding: const EdgeInsets.only(top: 70),
          child: Text(
            '등록된 환자가 없습니다.',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      );

  /// 🔹 환자 상세 문자열
  String _makeDetails(Map<String, dynamic> patient) {
    final list = <String>[];
    if (patient['gender'] != null && patient['gender'] != '-') {
      list.add(patient['gender']);
    }
    if (patient['age'] != null && patient['age'] != '') {
      list.add(patient['age'].toString());
    }
    if (patient['relationship'] != null &&
        patient['relationship'] != '관계 없음') {
      list.add(patient['relationship']);
    }
    return list.join(', ');
  }

  /// 🔹 환자 카드
 Widget _buildPatientCard({
  required BuildContext context,
  required int patientId,
  required String name,
  required String details,
  required bool isMember,
  required bool hasUpdates,
  String? profileImgUrl,
}) {
  final safeUrl = profileImgUrl?.isNotEmpty == true ? profileImgUrl : null;

  return GestureDetector(
    onTap: () {
      final nav = Provider.of<BottomNavProvider>(context, listen: false);
      // nav.setPatientId(patientId);

      Navigator.push(
        context,
        PageRouteBuilder(
          transitionDuration: Duration.zero,
          pageBuilder: (context, animation, secondaryAnimation) =>
              const MainPage(),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return child;
          },
        ),
      );
    },
    child: Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppColors.grey.withOpacity(0.2),
            spreadRadius: 0,
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Row(
        children: [
          // 👤 프로필 이미지
          CircleAvatar(
            radius: 32,
            backgroundImage:
                (safeUrl != null && safeUrl.isNotEmpty) ? NetworkImage(safeUrl) : null,
            backgroundColor: (safeUrl == null || safeUrl.isEmpty)
                ? AppColors.lightGrey
                : Colors.transparent,
            child: (safeUrl == null || safeUrl.isEmpty)
                ? const Icon(Icons.person, size: 32, color: Colors.grey)
                : null,
          ),
          const SizedBox(width: 16),

          // 📋 이름 + 상세정보
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.black,
                  ),
                ),
                Text(
                  details,
                  style: const TextStyle(
                    fontSize: 14,
                    color: AppColors.darkBlue,
                  ),
                ),
              ],
            ),
          ),

          // ✅ 회원 / 비회원 뱃지 + 업데이트 dot
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: isMember
                      ? AppColors.memberBg
                      : AppColors.nonMemberBg,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  isMember ? '회원' : '비회원',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: isMember
                        ? AppColors.blueBtnText
                        : AppColors.pinkBtnText,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  color: hasUpdates ? AppColors.blue : AppColors.lightGrey,
                  shape: BoxShape.circle,
                ),
              ),
            ],
          ),
        ],
      ),
    ),
  );
}

  /// 🔹 상단 서브헤더
  Widget _buildSubheader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const SizedBox(width: 40),
          SizedBox(
            width: 40,
            height: 40,
            child: FloatingActionButton(
              onPressed: () {
                _showAddPatientOptions(context);
              },
              backgroundColor: AppColors.mainBtn,
              foregroundColor: AppColors.white,
              child: const Icon(Icons.add),
            ),
          ),
        ],
      ),
    );
  }

  /// 🔹 환자 등록 옵션 BottomSheet
  void _showAddPatientOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                "환자 등록 방법 선택",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              ListTile(
                leading: const Icon(Icons.person_add_alt_1, color: AppColors.blue),
                title: const Text("직접 등록"),
                subtitle: const Text("환자 정보를 직접 입력하여 등록합니다."),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const AddPatientPage()),
                  );
                },
              ),
              ListTile(
                leading: const Icon(Icons.mail_outline, color: AppColors.mainBtn),
                title: const Text("초대하기"),
                subtitle: const Text("회원 환자를 초대하여 등록합니다."),
                onTap: () {
                  Navigator.pop(context);
                  _showInviteOptions(context);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  /// 🔹 초대 옵션 BottomSheet
  void _showInviteOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                "초대 방법 선택",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              ListTile(
                leading: const Icon(Icons.chat, color: Colors.yellow),
                title: const Text("카카오톡 초대하기"),
                subtitle: const Text("카카오톡으로 초대장을 전송합니다."),
                onTap: () {
                  Navigator.pop(context);
                  _inviteViaKakao();
                },
              ),
              ListTile(
                leading: const Icon(Icons.email, color: AppColors.mainBtn),
                title: const Text("이메일 초대하기"),
                subtitle: const Text("이메일 주소를 입력해 초대장을 전송합니다."),
                onTap: () {
                  Navigator.pop(context);
                  _showEmailInviteDialog(context);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _inviteViaKakao() async {
    const kakaoUrl = "kakaolink://send";
    const installUrl =
        "https://play.google.com/store/apps/details?id=com.kakao.talk";

    if (await canLaunchUrl(Uri.parse(kakaoUrl))) {
      await launchUrl(Uri.parse(kakaoUrl));
    } else {
      await launchUrl(Uri.parse(installUrl));
    }
  }

  void _showEmailInviteDialog(BuildContext context) {
    final TextEditingController emailController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("이메일 초대하기"),
          content: TextField(
            controller: emailController,
            decoration: const InputDecoration(
              labelText: "이메일 주소",
              border: OutlineInputBorder(),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("취소"),
            ),
            ElevatedButton(
              onPressed: () async {
                final email = emailController.text.trim();
                if (email.isNotEmpty) {
                  final patientVM =
                      Provider.of<PatientViewModel>(context, listen: false);
                  final patientId = patientVM.patients.isNotEmpty
                      ? patientVM.patients.first['id']
                      : null;

                  if (patientId != null) {
                    await patientVM.sendEmailInvite(email, patientId);
                  }
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("초대장이 전송되었습니다.")),
                  );
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.mainBtn,
                foregroundColor: Colors.white,
              ),
              child: const Text("전송"),
            ),
          ],
        );
      },
    );
  }
}
