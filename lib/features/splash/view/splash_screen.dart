// lib/features/splash/view/splash_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../features/auth/viewmodel/auth_viewmodel.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeApp();
    });
  }

  Future<void> _initializeApp() async {
    print('\n🎬 [SPLASH] 앱 초기화 시작\n');
    final authViewModel = Provider.of<AuthViewModel>(context, listen: false);

    // 로그인 상태 확인
    await authViewModel.tryAutoLogin();

    // 최소 로딩 시간 (UX)
    await Future.delayed(const Duration(seconds: 1));

    print('🎬 [SPLASH] 앱 초기화 완료\n');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.healing,
              size: 100,
              color: Theme.of(context).primaryColor,
            ),
            const SizedBox(height: 24),
            const Text(
              'Cure Mate',
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 48),
            const CircularProgressIndicator(),
          ],
        ),
      ),
    );
  }
}