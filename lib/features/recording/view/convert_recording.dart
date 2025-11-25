import 'package:curemate/features/widgets/common/header_provider.dart';
import 'package:curemate/features/widgets/common/widgets.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class ConvertRecordingPage extends StatefulWidget {
  const ConvertRecordingPage({super.key});

  @override
  State<ConvertRecordingPage> createState() => _ConvertRecordingPageState();
}

class _ConvertRecordingPageState extends State<ConvertRecordingPage> {
  final List<Map<String, String>> messages = [
    {'role': '의사', 'text': '안녕하세요, Cure Mate님. 오늘 어디가 불편해서 오셨나요?'},
    {'role': '나', 'text': '네, 안녕하세요 의사 선생님. 요즘 계속 머리가 아파서 왔습니다.'},
    {'role': '의사', 'text': '언제부터 아프셨어요? 다른 증상은 없으신가요?'},
  ];

  final String summaryText = '환자는 요즘 계속 머리가 아파서 병원에 방문했습니다. 의사는 언제부터 아팠는지, 다른 증상은 없는지 물어보았습니다.';

  String _activeTab = '텍스트 변환';

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final header = Provider.of<HeaderProvider>(context, listen: false);
    header.setTitle('녹음 상세');
    header.setShowBackButton(true);
  }

  @override
  Widget build(BuildContext context) {
    final Color primaryColor = Color(0xFFA0C4FF);
    final Color textPrimary = Theme.of(context).colorScheme.onBackground;
    final Color textSecondary = const Color(0xFF4E7697);

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            const PatientScreenHeader(),
            Expanded(
              child: Stack(
                children: [
                  SingleChildScrollView(
                    padding: const EdgeInsets.only(bottom: 100),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        children: [
                          _buildPlayerCard(),
                          const SizedBox(height: 24),
                          _buildTranscriptCard(textPrimary, primaryColor),
                        ],
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: 16,
                    left: 16,
                    right: 16,
                    child: Row(
                      children: [
                        _buildActionButton('메모', primaryColor),
                        _buildActionButton('취소', primaryColor),
                        _buildActionButton('저장', primaryColor),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: const PatientScreenBottomNavBar(),
    );
  }

  Widget _buildActionButton(String text, Color primaryColor) {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4.0),
        child: ElevatedButton(
          onPressed: () {},
          style: ButtonStyle(
            backgroundColor: MaterialStateProperty.resolveWith<Color>(
              (states) =>
                  states.contains(MaterialState.pressed) ? primaryColor : Colors.white,
            ),
            foregroundColor: MaterialStateProperty.resolveWith<Color>(
              (states) =>
                  states.contains(MaterialState.pressed) ? Colors.white : primaryColor,
            ),
            side: MaterialStateProperty.all(BorderSide(color: primaryColor)),
            shape: MaterialStateProperty.all(
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            padding: MaterialStateProperty.all(const EdgeInsets.symmetric(vertical: 12)),
          ),
          child: Text(
            text,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
          ),
        ),
      ),
    );
  }

  Widget _buildPlayerCard() {
    final Color primaryColor = const Color(0xFFA0C4FF);
    final Color textPrimary = Theme.of(context).colorScheme.onBackground;
    final Color textSecondary = const Color(0xFF4E7697);

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('진료 녹음 1.m4a',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: textPrimary)),
              Text('10:45', style: TextStyle(fontSize: 14, color: textSecondary)),
            ],
          ),
          const SizedBox(height: 12),
          Stack(
            alignment: Alignment.centerLeft,
            children: [
              Container(
                height: 8,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              Container(
                width: MediaQuery.of(context).size.width * 0.3,
                height: 8,
                decoration: BoxDecoration(
                  color: primaryColor,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              Positioned(
                left: MediaQuery.of(context).size.width * 0.3 - 8,
                child: Container(
                  height: 16,
                  width: 16,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.grey[400]!),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton(
                icon: const Icon(Icons.fast_rewind, size: 32),
                color: Colors.grey[600],
                onPressed: () {},
              ),
              const SizedBox(width: 16),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: primaryColor,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: primaryColor.withOpacity(0.4),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: const Icon(Icons.play_arrow, color: Colors.white, size: 32),
              ),
              const SizedBox(width: 16),
              IconButton(
                icon: const Icon(Icons.fast_forward, size: 32),
                color: Colors.grey[600],
                onPressed: () {},
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTranscriptCard(Color textPrimary, Color primaryColor) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: InkWell(
                  onTap: () => setState(() => _activeTab = '텍스트 변환'),
                  child: _buildTab('텍스트 변환', _activeTab == '텍스트 변환', primaryColor),
                ),
              ),
              Expanded(
                child: InkWell(
                  onTap: () => setState(() => _activeTab = '요약'),
                  child: _buildTab('요약', _activeTab == '요약', primaryColor),
                ),
              ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: _activeTab == '텍스트 변환'
                ? Column(
                    children: messages
                        .map((msg) => _buildMessage(msg['role']!, msg['text']!, textPrimary))
                        .toList(),
                  )
                : Text(summaryText, style: TextStyle(color: textPrimary)),
          ),
        ],
      ),
    );
  }

  Widget _buildTab(String title, bool isActive, Color primaryColor) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: isActive ? primaryColor : Colors.transparent,
            width: 2.0,
          ),
        ),
      ),
      child: Text(
        title,
        textAlign: TextAlign.center,
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: isActive ? primaryColor : Colors.grey[500],
        ),
      ),
    );
  }

  Widget _buildMessage(String role, String text, Color textPrimary) {
    bool isMine = role == '나';
    final Color avatarBgColor = isMine ? const Color(0xFFD1FAE5) : const Color(0xFFDBEAFE);
    final Color avatarTextColor = isMine ? const Color(0xFF10B981) : const Color(0xFF3B82F6);
    final Color messageBgColor = isMine ? const Color(0xFFF0FDF4) : const Color(0xFFEFF6FF);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: isMine ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!isMine) _buildAvatar(role, avatarBgColor, avatarTextColor),
          const SizedBox(width: 12),
          Container(
            constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.65),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: messageBgColor,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(text, style: TextStyle(color: textPrimary)),
          ),
          const SizedBox(width: 12),
          if (isMine) _buildAvatar(role, avatarBgColor, avatarTextColor),
        ],
      ),
    );
  }

  Widget _buildAvatar(String role, Color bgColor, Color textColor) {
    return Container(
      width: 40,
      height: 40,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        role,
        style: TextStyle(fontWeight: FontWeight.bold, color: textColor),
      ),
    );
  }
}
