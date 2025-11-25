import 'package:curemate/features/widgets/common/header_provider.dart';
import 'package:curemate/features/widgets/common/widgets.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Cure Mate - 녹음 요약',
      theme: ThemeData(
        colorScheme: ColorScheme.light(
          primary: const Color(0xFFA0C4FF),
          secondary: const Color(0xFFE6F0FF),
          background: const Color(0xFFF0F8FF),
          surface: const Color(0xFFFFFFFF),
          onPrimary: const Color(0xFFFFFFFF),
          onSecondary: const Color(0xFF000000),
          onBackground: const Color(0xFF0E151B),
          onSurface: const Color(0xFF0E151B),
        ),
        textTheme: const TextTheme(),
        useMaterial3: true,
      ),
      home: const RecordingSummaryScreen(),
    );
  }
}

// StatefulWidget으로 변경
class RecordingSummaryScreen extends StatefulWidget {
  const RecordingSummaryScreen({super.key});

  @override
  State<RecordingSummaryScreen> createState() => _RecordingSummaryScreenState();
}

class _RecordingSummaryScreenState extends State<RecordingSummaryScreen> {
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final header = Provider.of<HeaderProvider>(context, listen: false);
    header.setTitle('녹음 상세');
    header.setShowBackButton(true);
  }

  @override
  Widget build(BuildContext context) {
    final Color primaryColor = Theme.of(context).colorScheme.primary;
    final Color backgroundColor = Theme.of(context).colorScheme.background;
    final Color textPrimary = Theme.of(context).colorScheme.onBackground;
    final Color textSecondary = const Color(0xFF4E7697);
    final Color iconColor = primaryColor;
    final Color cardBg = Theme.of(context).colorScheme.surface;
    final Color editButtonBg = const Color(0xFF2563EB);
    final Color editButtonText = const Color(0xFFFFFFFF);
    final Color selectedNavColor = const Color(0xFF2563EB);
    final Color unselectedNavColor = const Color(0xFF000000);

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            PatientScreenHeader(),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildSummaryCard(
                      context,
                      title: '텍스트 변환',
                      contentWidget: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildConversationLine(
                            context,
                            speaker: '의사',
                            text: '안녕하세요, Cure Mate님. 오늘 어디가 불편해서 오셨나요?',
                            speakerColor: Colors.blue[600]!,
                          ),
                          _buildConversationLine(
                            context,
                            speaker: '나',
                            text: '네, 안녕하세요 의사 선생님. 요즘 계속 머리가 아파서 왔습니다.',
                            speakerColor: Colors.green[600]!,
                          ),
                          _buildConversationLine(
                            context,
                            speaker: '의사',
                            text: '언제부터 아프셨어요? 다른 증상은 없으신가요?',
                            speakerColor: Colors.blue[600]!,
                          ),
                        ],
                      ),
                      minHeight: 160,
                      isScrollable: true,
                    ),
                    const SizedBox(height: 24),
                    _buildSummaryCard(
                      context,
                      title: '요약',
                      contentWidget: Text(
                        '환자는 최근 지속적인 두통을 호소하며 내원함. 의사는 증상 발생 시점 및 다른 동반 증상에 대해 질문함.',
                        style: TextStyle(fontSize: 14, color: textPrimary),
                      ),
                      minHeight: 120,
                      isScrollable: false,
                    ),
                    const SizedBox(height: 24),
                    _buildSummaryCard(
                      context,
                      title: '메모',
                      contentWidget: Text(
                        '다음 진료 때 혈압 측정 결과 가져오기. 타이레놀 복용 후 효과 있었는지 확인.',
                        style: TextStyle(fontSize: 14, color: textPrimary),
                      ),
                      minHeight: 80,
                      hasEditButton: true,
                      editButtonBg: editButtonBg,
                      editButtonText: editButtonText,
                      isScrollable: false,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: PatientScreenBottomNavBar(),
    );
  }

  Widget _buildSummaryCard(
    BuildContext context, {
    required String title,
    required Widget contentWidget,
    required double minHeight,
    bool hasEditButton = false,
    Color? editButtonBg,
    Color? editButtonText,
    required bool isScrollable,
  }) {
    final Color cardBg = Theme.of(context).colorScheme.surface;
    final Color textPrimary = Theme.of(context).colorScheme.onBackground;

    Widget content = Container(
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(8),
      ),
      constraints: BoxConstraints(minHeight: minHeight),
      child: isScrollable
          ? SingleChildScrollView(child: contentWidget)
          : contentWidget,
    );

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.2),
            spreadRadius: 1,
            blurRadius: 5,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Stack(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: textPrimary,
                ),
              ),
              content,
            ],
          ),
          if (hasEditButton)
            Positioned(
              top: 0,
              right: 0,
              child: TextButton(
                style: TextButton.styleFrom(
                  backgroundColor: editButtonBg,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 4,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                onPressed: () {
                  // 수정 버튼 액션
                },
                child: Text(
                  '수정',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: editButtonText,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildConversationLine(
    BuildContext context, {
    required String speaker,
    required String text,
    required Color speakerColor,
  }) {
    final Color textPrimary = Theme.of(context).colorScheme.onBackground;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '$speaker:',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: speakerColor,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: TextStyle(fontSize: 14, color: textPrimary),
            ),
          ),
        ],
      ),
    );
  }
}
