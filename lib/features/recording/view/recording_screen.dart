// lib/features/recording/view/recording_screen.dart
import 'dart:async';
import 'dart:math';

import 'package:curemate/app/theme/app_colors.dart';
import 'package:curemate/features/patient/view/main_screen.dart';
import 'package:curemate/features/recording/view/convert_recording.dart';
import 'package:curemate/features/widgets/common/bottom_nav_provider.dart';
import 'package:curemate/features/widgets/common/header_provider.dart';
import 'package:curemate/features/widgets/common/widgets.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class RecordingScreen extends StatefulWidget {
  const RecordingScreen({super.key});

  @override
  State<RecordingScreen> createState() => _RecordingScreenState();
}

enum RecordingState { initial, recording, finished }

class _RecordingScreenState extends State<RecordingScreen> {
  bool _isConsented = false;
  RecordingState _recordingState = RecordingState.initial;
  Timer? _timer;
  int _seconds = 0;
  List<double> _barHeights = List.generate(14, (index) => 4.0);
  final Random _random = Random();

  @override
  void initState() {
    super.initState();

    // 위젯의 빌드가 완료된 후 콜백을 실행
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<HeaderProvider>(context, listen: false)
        ..setTitle('녹음')
        ..setShowBackButton(true);
      Provider.of<BottomNavProvider>(context, listen: false).changeIndex(2);
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _toggleRecording() {
    if (_recordingState == RecordingState.initial) {
      setState(() {
        _recordingState = RecordingState.recording;
        _seconds = 0;
      });
      _startTimer();
      _startBarAnimation();
    } else if (_recordingState == RecordingState.recording) {
      setState(() {
        _recordingState = RecordingState.finished;
      });
      _stopTimer();
    }
  }

  void _saveRecording() {
    Navigator.push(
      context,
      PageRouteBuilder(
        // 애니메이션 지속 시간을 0으로 설정
        transitionDuration: Duration.zero,
        pageBuilder: (context, animation, secondaryAnimation) =>
            const ConvertRecordingPage(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          // 애니메이션 없이 새 화면을 바로 표시
          return child;
        },
      ),
    );
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() => _seconds++);
    });
  }

  void _stopTimer() {
    _timer?.cancel();
    setState(() {
      _barHeights = List.generate(14, (index) => 4.0);
    });
  }

  void _startBarAnimation() {
    Timer.periodic(const Duration(milliseconds: 150), (timer) {
      if (_recordingState != RecordingState.recording) {
        timer.cancel();
        return;
      }
      setState(() {
        _barHeights = List.generate(
          14,
              (index) => _random.nextDouble() * 50 + 10,
        );
      });
    });
  }

  String _formatTime(int seconds) {
    final hours = (seconds ~/ 3600).toString().padLeft(2, '0');
    final minutes = ((seconds % 3600) ~/ 60).toString().padLeft(2, '0');
    final secs = (seconds % 60).toString().padLeft(2, '0');
    return '$hours:$minutes:$secs';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    final isRecording = _recordingState == RecordingState.recording;
    final isFinished = _recordingState == RecordingState.finished;

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            const PatientScreenHeader(),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    const SizedBox(height: 60),
                    Text(
                      '녹음 주의사항',
                      style: theme.textTheme.titleLarge,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '진료 녹음은 반드시 의사의 동의를 얻고 시작해주세요.',
                      textAlign: TextAlign.center,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: scheme.secondary,
                      ),
                    ),
                    const SizedBox(height: 32),

                    Icon(
                      isRecording ? Icons.mic_off : Icons.mic,
                      size: 100,
                      color: isRecording ? AppColors.error : scheme.primary,
                    ),
                    const SizedBox(height: 24),

                    if (_recordingState == RecordingState.initial)
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Checkbox(
                            value: _isConsented,
                            onChanged: (newValue) =>
                                setState(() => _isConsented = newValue ?? false),
                            activeColor: scheme.primary,
                          ),
                          Text('동의를 얻었습니다.', style: theme.textTheme.bodyLarge),
                        ],
                      ),
                    const SizedBox(height: 24),

                    // 버튼은 Theme에서 통일된 ElevatedButtonTheme 사용
                    SizedBox(
                      width: 200,
                      child: ElevatedButton(
                        onPressed: isFinished
                            ? _saveRecording
                            : (_isConsented ? _toggleRecording : null),
                        style: isRecording
                            ? ElevatedButton.styleFrom(backgroundColor: AppColors.error)
                            : null, // 기본 스타일은 Theme 적용
                        child: Text(
                          isFinished
                              ? '녹음 저장하기'
                              : (isRecording ? '녹음 중지' : '녹음 시작'),
                        ),
                      ),
                    ),

                    const SizedBox(height: 20),
                    Text(
                      _formatTime(_seconds),
                      style: theme.textTheme.headlineMedium,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      isRecording
                          ? '녹음 중...'
                          : isFinished
                          ? '녹음이 완료되었습니다. 저장해주세요.'
                          : '녹음을 시작하려면 버튼을 누르세요',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: scheme.secondary,
                      ),
                    ),

                    const SizedBox(height: 32),
                    SizedBox(
                      height: 60,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: List.generate(14, (index) {
                          return AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            width: 5,
                            height: _barHeights[index],
                            margin: const EdgeInsets.symmetric(horizontal: 3),
                            decoration: BoxDecoration(
                              color: scheme.primary,
                              borderRadius: BorderRadius.circular(4),
                            ),
                          );
                        }),
                      ),
                    ),
                    const SizedBox(height: 120),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: const PatientScreenBottomNavBar(),
    );
  }
}
