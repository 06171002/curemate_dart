// lib/features/permission/view/permission_screen.dart (수정된 전체 코드)

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:permission_handler/permission_handler.dart' as ph;
import '../../../routes/route_paths.dart';

import '../../../app/theme/app_colors.dart';
import '../../../services/permission_service.dart';
import '../../../features/auth/viewmodel/auth_viewmodel.dart';
import '../../../utils/hardware_checker.dart';
import '../../../utils/logger.dart';

class PermissionScreen extends StatefulWidget {
  const PermissionScreen({super.key});

  @override
  State<PermissionScreen> createState() => _PermissionScreenState();
}

class _PermissionScreenState extends State<PermissionScreen> {
  final PermissionService _permissionService = PermissionService();

  // 필요한 권한 목록
  late List<PermissionInfo> _requiredPermissions;

  // 상태 변수
  bool _isLoading = true; // 최초 로딩 상태 (권한 요청 중)
  bool _hasCamera = true;
  bool _hasMicrophone = true;

  // 권한 요청 후 상태 (UI에 반영)
  bool _isAllGranted = false;

  @override
  void initState() {
    super.initState();
    _requiredPermissions = _permissionService.getRequiredPermissions();

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await _checkHardware();
      // ✅ 화면 진입과 동시에 권한 요청 시작
      await _checkAndRequestPermissions();
      await _checkInitialPermissionStatus(); // 권한 요청 후 상태 업데이트
    });
  }

  // 초기 권한 상태 확인 (버튼 활성화/비활성화 목적)
  Future<void> _checkInitialPermissionStatus() async {
    final isGranted = await _permissionService.areAllRequiredPermissionsGranted();
    if (mounted) {
      setState(() {
        _isAllGranted = isGranted;
        _isLoading = false; // 권한 요청 완료 후 로딩 해제
      });
    }
  }

  // 하드웨어 체크 및 로깅 (기존과 동일)
  Future<void> _checkHardware() async {
    _hasCamera = await HardwareChecker.hasCamera();
    _hasMicrophone = await HardwareChecker.hasMicrophone();
    if (!mounted) return;
    // ... (기존 로깅 및 스낵바 로직) ...
  }

  // ✅ 권한 요청 처리 함수 (화면 진입 시 자동 호출)
  Future<void> _checkAndRequestPermissions() async {
    Logger.section('최초 권한 요청 시작');

    // 1. 현재 모든 권한이 허용되었는지 확인
    final isGranted = await _permissionService.areAllRequiredPermissionsGranted();

    if (isGranted) {
      // 이미 모두 허용된 경우, 로딩 해제 후 UI 업데이트
      Logger.i('이미 모든 권한이 허용됨', tag: 'PERMISSION_SCREEN');
      if (mounted) {
        setState(() {
          _isAllGranted = true;
          _isLoading = false;
        });
      }
      return;
    }

    // 2. 권한 요청
    if (mounted) setState(() => _isLoading = true);

    try {
      final statuses = await _permissionService.requestRequiredPermissions();
      final allGrantedAfterRequest = statuses.values.every((status) => status.isGranted);

      if (mounted) {
        setState(() {
          _isAllGranted = allGrantedAfterRequest;
        });

        if (!allGrantedAfterRequest) {
          final hasPermanentlyDenied = statuses.entries.any((entry) => entry.value.isPermanentlyDenied);
          if (hasPermanentlyDenied) {
            _showSettingsDialog();
          }
        }
      }
    } catch (e) {
      Logger.e('권한 요청 에러: $e', tag: 'PERMISSION_SCREEN');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('권한 요청 중 오류 발생: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false; // 요청 완료 후 버튼 활성화
        });
      }
    }
  }

  // ✅ 완료 처리 및 홈 화면 이동 로직 (버튼 클릭 시)
  Future<void> _completeAndGoNext() async {
    // 1. 최초 확인 완료 상태 저장
    final authViewModel = Provider.of<AuthViewModel>(context, listen: false);
    await authViewModel.completeInitialPermissionCheck();

    // 2. 홈 화면으로 이동 (권한 부여 여부와 관계 없음)
    if (mounted) context.go(RoutePaths.test);
  }

  // 영구 거부 시 설정으로 이동 다이얼로그
  void _showSettingsDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('권한 설정 안내'),
        content: const Text('일부 권한이 영구적으로 거부되었습니다. 해당 기능을 사용하려면 설정에서 권한을 허용해야 합니다.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('확인'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _permissionService.openAppSettings();
            },
            child: const Text('설정으로 이동'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        // 빈 AppBar (예시 화면처럼 상단 여백)
        backgroundColor: Colors.white,
        elevation: 0,
        toolbarHeight: 0,
      ),
      body: Container(
        color: AppColors.white,
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 40.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // 1. 시작하기 전에
                Text(
                  '시작하기 전에',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '더 나은 서비스 이용을 위해\n동의가 필요한 내용을 확인해주세요.',
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: AppColors.darkBlue,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 50),

                // 2. 권한 목록
                Expanded(
                  child: ListView(
                    physics: const NeverScrollableScrollPhysics(), // 스크롤 방지
                    padding: EdgeInsets.zero,
                    children: _buildPermissionItems(context),
                  ),
                ),

                // 3. 시작하기 버튼 (항상 하단에 고정)
                _buildStartButton(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ✅ 권한 항목 빌더 (예시 화면 디자인 적용)
  List<Widget> _buildPermissionItems(BuildContext context) {
    // 예시 화면처럼 3개의 항목을 나열합니다.
    return [
      _buildPermissionCard(
        context,
        icon: Icons.mic_none,
        iconColor: AppColors.greenIconColor,
        name: '음성 기록',
        description: '진료 녹음 및 기록을 위해 필요합니다.',
        isGranted: _hasMicrophone && _isAllGranted, // 마이크 권한에 따라 상태 표시 (대표)
      ),
      const SizedBox(height: 30),
      _buildPermissionCard(
        context,
        icon: Icons.camera_alt_outlined,
        iconColor: AppColors.pinkIconColor,
        name: '사진 및 카메라',
        description: '진료 기록 사진 첨부 및 촬영을 위해 필요합니다.',
        isGranted: _hasCamera && _isAllGranted, // 카메라 권한에 따라 상태 표시 (대표)
      ),
      const SizedBox(height: 30),
      _buildPermissionCard(
        context,
        icon: Icons.notifications_none,
        iconColor: AppColors.iconColor,
        name: '알림',
        description: '복약 및 일정 알림을 위해 필요합니다.',
        isGranted: _isAllGranted, // 알림 권한은 현재 목록에 없지만 예시를 위해 포함 (대표)
      ),
    ];
  }

  Widget _buildPermissionCard(
      BuildContext context, {
        required IconData icon,
        required Color iconColor,
        required String name,
        required String description,
        required bool isGranted,
      }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: iconColor.withOpacity(0.2),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: iconColor, size: 24),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                name,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppColors.blueTextSecondary,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                description,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.skyBlue,
                ),
              ),
            ],
          ),
        ),
        // ✅ 권한 부여 상태 아이콘 (선택적으로 표시 가능)
        // Icon(
        //   isGranted ? Icons.check_circle : Icons.remove_circle_outline,
        //   color: isGranted ? Colors.green : Colors.grey,
        // ),
      ],
    );
  }

  // ✅ 시작하기 버튼 빌더
  Widget _buildStartButton() {
    return ElevatedButton(
      onPressed: _isLoading ? null : _completeAndGoNext,
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.greenIconColor, // 예시 이미지 색상에 근접하게 변경
        foregroundColor: AppColors.white,
        padding: const EdgeInsets.symmetric(vertical: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        elevation: 0,
      ),
      child: _isLoading
          ? const CircularProgressIndicator(color: Colors.white)
          : const Text(
        'Cure Mate 시작하기',
        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _buildPermissionItem(PermissionInfo info) {
    // 하드웨어 미감지 시 해당 항목 제외 (기존 로직 유지)
    if ((info.permission == ph.Permission.camera && !_hasCamera) ||
        (info.permission == ph.Permission.microphone && !_hasMicrophone)) {
      return const SizedBox.shrink();
    }
    // 이 메서드는 _buildPermissionItems에서 더 상세한 UI로 대체되어 사용되지 않습니다.
    return const SizedBox.shrink();
  }
}