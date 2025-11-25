import 'package:curemate/features/patient/view/medical_detail_screen.dart';
import 'package:curemate/features/recording/view/recording_detail.dart';
import 'package:curemate/features/widgets/common/header_provider.dart';
import 'package:curemate/features/widgets/common/widgets.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

final Color bgColor = const Color(0xFFF0F8FF);

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Cure Mate - 녹음 파일 목록',
      theme: ThemeData(
        colorScheme: ColorScheme.light(
          primary: const Color(0xFFA0C4FF),
          secondary: const Color(0xFFE6F0FF),
          background: const Color(0xFFF0F8FF),
        ),
        textTheme: const TextTheme(
          bodyLarge: TextStyle(fontFamily: 'Noto Sans KR'),
          bodyMedium: TextStyle(fontFamily: 'Noto Sans KR'),
          titleLarge: TextStyle(fontFamily: 'Lexend'),
          titleMedium: TextStyle(fontFamily: 'Lexend'),
        ),
        useMaterial3: true,
      ),
      home: const RecordingListScreen(),
    );
  }
}

//  StatefulWidget 변경
class RecordingListScreen extends StatefulWidget {
  const RecordingListScreen({super.key});

  @override
  State<RecordingListScreen> createState() => _RecordingListScreenState();
}

class _RecordingListScreenState extends State<RecordingListScreen> {
  final Color textPrimary = const Color(0xFF0E151B);
  final Color textSecondary = const Color(0xFF4E7697);
  final Color iconColor = const Color(0xFFA0C4FF);
  final Color cardBg = const Color(0xFFFFFFFF);

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final header = Provider.of<HeaderProvider>(context, listen: false);
    header.setTitle('녹음 목록');
    header.setShowBackButton(true);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            const PatientScreenHeader(),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildMonthSection(context, '2023년 10월', [
                      _buildRecordingItem(
                        context,
                        '진료 녹음 1',
                        '2023년 10월 27일 14:30',
                        '12:34',
                        isLast: false,
                      ),
                      _buildRecordingItem(
                        context,
                        '진료 녹음 2',
                        '2023년 10월 20일 10:15',
                        '08:12',
                        isLast: false,
                      ),
                      _buildRecordingItem(
                        context,
                        '진료 녹음 3',
                        '2023년 10월 13일 16:00',
                        '15:58',
                        isLast: true,
                      ),
                    ]),
                    const SizedBox(height: 24),
                    _buildMonthSection(context, '2023년 9월', [
                      _buildRecordingItem(
                        context,
                        '진료 녹음 4',
                        '2023년 9월 28일 11:00',
                        '05:20',
                        isLast: false,
                      ),
                      _buildRecordingItem(
                        context,
                        '진료 녹음 5',
                        '2023년 9월 15일 09:45',
                        '21:05',
                        isLast: true,
                      ),
                    ]),
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

  Widget _buildMonthSection(
    BuildContext context,
    String title,
    List<Widget> items,
  ) {
    return Column(
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
        const SizedBox(height: 12),
        Container(
          decoration: BoxDecoration(
            color: cardBg,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withOpacity(0.1),
                spreadRadius: 1,
                blurRadius: 5,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: ListView(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            children: items,
          ),
        ),
      ],
    );
  }

  Widget _buildRecordingItem(
    BuildContext context,
    String title,
    String date,
    String duration, {
    required bool isLast,
  }) {
    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          PageRouteBuilder(
            // 애니메이션 지속 시간을 0으로 설정
            transitionDuration: Duration.zero,
            pageBuilder: (context, animation, secondaryAnimation) =>
                const RecordingSummaryScreen(),
            transitionsBuilder: (context, animation, secondaryAnimation, child) {
              // 애니메이션 없이 새 화면을 바로 표시
              return child;
            },
          ),
        );
      },
      child: Container(
        padding: const EdgeInsets.all(16.0),
        decoration: BoxDecoration(
          border: isLast
              ? null
              : Border(bottom: BorderSide(color: Colors.grey[100]!)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: textPrimary,
                    fontFamily: 'Noto Sans KR',
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  date,
                  style: TextStyle(
                    fontSize: 14,
                    color: textSecondary,
                    fontFamily: 'Noto Sans KR',
                  ),
                ),
              ],
            ),
            Row(
              children: [
                Text(
                  duration,
                  style: TextStyle(fontSize: 14, color: textSecondary),
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: Icon(Icons.play_arrow, color: iconColor),
                  onPressed: () {
                    // Play button action
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
