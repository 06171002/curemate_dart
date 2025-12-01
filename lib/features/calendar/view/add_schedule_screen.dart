import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:table_calendar/table_calendar.dart'; // table_calendar import
import 'package:curemate/features/widgets/common/header_provider.dart';
import 'package:curemate/features/widgets/common/widgets.dart'; // PatientScreenHeader, PatientScreenBottomNavBar 등
import 'package:curemate/features/calendar/view/new_schedule_screen.dart';
import 'package:curemate/services/calendar_service.dart';
import 'package:intl/intl.dart';

import '../../../app/theme/app_colors.dart';
import '../../widgets/common/bottom_nav_provider.dart';

// CalendarWidget은 TableCalendar를 직접 사용하거나 래핑한 위젯이라고 가정합니다.
// 만약 CalendarWidget이 별도의 파일에 있다면, 아래 TableCalendar 부분을 해당 위젯으로 대체하고
// selectedDayPredicate, onDaySelected 등의 속성을 CalendarWidget에 맞게 전달해야 합니다.
// 여기서는 AddScheduleScreen 내에 TableCalendar를 직접 사용하는 형태로 작성합니다.

class AddScheduleScreen extends StatefulWidget {
  const AddScheduleScreen({super.key});

  @override
  State<AddScheduleScreen> createState() => _AddScheduleScreenState();
}

class _AddScheduleScreenState extends State<AddScheduleScreen> {
  CalendarFormat _calendarFormat = CalendarFormat.month;
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay; // 현재 UI에 선택된 것으로 표시될 날짜

  final CalendarService _calendarService = CalendarService();
  bool _isLoadingSchedules = false; // 일정 로딩 상태
  List<Map<String, dynamic>> _selectedDaySchedules = [];

  @override
  void initState() {
    super.initState();
    _selectedDay = _focusedDay; // 초기에는 포커스된 날짜를 선택된 날짜로 설정

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _setHeaderForThisScreen();
        // 화면이 처음 로드될 때 오늘 날짜의 일정을 불러옵니다.
        _fetchSchedulesForDay(_selectedDay!);
      }
    });
  }

  // --- ▼▼▼ 3. 일정 데이터를 불러오는 함수 추가 ▼▼▼ ---
  Future<void> _fetchSchedulesForDay(DateTime day) async {
    // 현재 선택된 환자 ID 가져오기
    final patientId = Provider.of<BottomNavProvider>(context, listen: false).cureSeq;
    if (patientId == null) {
      // 환자가 선택되지 않았으면 목록을 비우고 종료
      if (mounted) setState(() => _selectedDaySchedules = []);
      return;
    }

    if (mounted) setState(() => _isLoadingSchedules = true);

    try {
      final schedules = await _calendarService.getSchedulesByDate(patientId, day);

      if (mounted) {
        setState(() {
          _selectedDaySchedules = schedules;
        });
      }
    } catch (e) {
      print('일정 로딩 실패: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('$e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoadingSchedules = false);
    }
  }

  // 헤더를 이 화면에 맞게 설정하는 로직을 별도 메서드로 분리
  void _setHeaderForThisScreen() {
    final header = Provider.of<HeaderProvider>(context, listen: false);
    header.setTitle('일정 관리');
    header.setShowBackButton(true);
    // AddScheduleScreen에서는 설정 버튼이 필요하다면 true로 설정
    header.setSettingButton(true); // 또는 false, 이 화면의 정책에 따름
  }

  void _navigateToNewScheduleScreen() {
    // _selectedDay가 null일 경우를 대비하여 기본값(오늘 날짜)을 사용
    final DateTime dateToSend = _selectedDay ?? DateTime.now();
    final nav = Provider.of<BottomNavProvider>(context, listen: false);
    final patientId = nav.cureSeq;

    if (patientId == null) {
      // 사용자에게 환자를 먼저 선택하라는 메시지를 보여줍니다.
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('일정을 추가할 환자를 먼저 선택해주세요.')),
      );
      return; // 함수 실행을 여기서 중단합니다.
    }


    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => NewScheduleScreen(
          selectedDateFromPreviousScreen: dateToSend,
        ),
      ),
    ).then((result) {
      // NewScheduleScreen이 닫힌 후 이 코드가 실행됩니다.
      // result에는 Navigator.pop(context, result)으로 전달된 값이 들어옵니다.

      // 화면이 위젯 트리에 아직 마운트되어 있는지 먼저 확인합니다.
      if (!mounted) return;

      // 1. result가 true인지 확인합니다 (저장이 성공적으로 완료되었는지).
      if (result == true) {
        print('새 일정 저장 완료. 목록을 새로고침합니다.');

        // 2. 현재 선택된 날짜의 일정 목록을 다시 불러옵니다.
        _fetchSchedulesForDay(_selectedDay!);
      }

      // 3. 화면으로 돌아온 후에는 항상 헤더를 이 화면에 맞게 다시 설정합니다.
      //    이 코드는 result가 true이든 아니든 (즉, 저장을 했든 그냥 뒤로가기를 했든) 실행됩니다.
      _setHeaderForThisScreen();
    });
  }

  void _navigateToEditScheduleScreen(Map<String, dynamic> scheduleData) {
    final nav = Provider.of<BottomNavProvider>(context, listen: false);
    final patientId = nav.cureSeq;

    if (patientId == null) {
      // 사용자에게 환자를 먼저 선택하라는 메시지를 보여줍니다.
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('일정을 추가할 환자를 먼저 선택해주세요.')),
      );
      return; // 함수 실행을 여기서 중단합니다.
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => NewScheduleScreen(
          selectedDateFromPreviousScreen: _selectedDay!,
          existingSchedule: scheduleData, // ★ 기존 일정 데이터를 전달
        ),
      ),
    ).then((result) {
      // 수정 화면에서 돌아왔을 때 목록을 새로고침
      if (result == true) {
        _fetchSchedulesForDay(_selectedDay!);
      }

      _setHeaderForThisScreen();

    });

  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.white, // Container에 색상 적용
      child: SafeArea(
        top: true, // top에 SafeArea 적용
        child: Scaffold(
          resizeToAvoidBottomInset: false, // 키보드가 올라와도 레이아웃을 조정하지 않음
          body: Column(
            children: [
              // --- Header ---
              PatientScreenHeader(), // isMainPage 프롭이 필요하다면 추가

              // --- 달력 위젯 ---
              _buildCalendar(),

              Expanded(
                child: _buildScheduleList(), // 일정조회
              ),
            ],
          ),
          bottomNavigationBar: PatientScreenBottomNavBar(), // 하단 네비게이션 바가 있다면
          floatingActionButton: Container(
            width: 40, // 버튼의 가로 크기
            height: 40, // 버튼의 세로 크기
            child: FloatingActionButton(
              onPressed: _navigateToNewScheduleScreen,
              tooltip: '새 일정 추가',
              backgroundColor: AppColors.mainBtn,
              foregroundColor: AppColors.white,
              child: const Icon(Icons.add),
            ),
          ),
          floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
        ),
      ),
    );
  }

  // 달력세팅
  Widget _buildCalendar() {
    return Container(
      padding: const EdgeInsets.only(left: 16.0, right:16.0, top: 8.0),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.white, // 배경색은 decoration 안에서 지정
          borderRadius: BorderRadius.circular(16.0), // 둥근 모서리 적용
        ),
        child: TableCalendar(
          locale: 'ko_KR',
          firstDay: DateTime.utc(1900, 1, 1),
          lastDay: DateTime.utc(2999, 12, 31),
          focusedDay: _focusedDay,
          calendarFormat: _calendarFormat,
          selectedDayPredicate: (day) {
            return isSameDay(_selectedDay, day);
          },
          onDaySelected: (selectedDayFromCalendar, focusedDayFromCalendar) {
            // 동일 날짜를 선택해도 재조회되도록 수정
            setState(() {
              _selectedDay = selectedDayFromCalendar;
              _focusedDay = focusedDayFromCalendar;
            });
            _fetchSchedulesForDay(selectedDayFromCalendar);
          },
          onFormatChanged: (format) {
            if (_calendarFormat != format) {
              setState(() {
                _calendarFormat = format;
              });
            }
          },
          onPageChanged: (focusedDay) {
            // 페이지가 변경될 때 포커스된 날짜만 업데이트
            setState(() {
              _focusedDay = focusedDay;
            });
          },
          headerStyle: const HeaderStyle(
            formatButtonVisible: false,
            titleCentered: true,
          ),
          calendarStyle: const CalendarStyle(
            todayDecoration: BoxDecoration(
              color: Colors.amber,
              shape: BoxShape.circle,
            ),
            selectedDecoration: BoxDecoration(
              color: Colors.blueAccent,
              shape: BoxShape.circle,
            ),
          ),
        ),
      ),
    );
  }

  // 일정목록
  Widget _buildScheduleList() {
    if (_isLoadingSchedules) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_selectedDaySchedules.isEmpty) {
      return const Center(
        child: Text(
          '해당 날짜에 등록된 일정이 없습니다.',
          style: TextStyle(color: AppColors.grey),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16.0),
      itemCount: _selectedDaySchedules.length,
      itemBuilder: (context, index) {
        final schedule = _selectedDaySchedules[index];

        final scheduleType = schedule['schedule_type'] as String?;
        final title = schedule['title'] as String?;
        final content = schedule['content'] as String?;
        final timeString = schedule['schedule_time'] as String?;
        final creatorName = schedule['creator_name'] as String?;
        final updaterName = schedule['updater_name'] as String?; // <-- 수정자 이름 추출
        final updateAt = schedule['update_at'] as String?; // <-- 수정 여부 판단을 위해 update_at 추출

        String formattedTime = '';
        if (timeString != null) {
          try {
            final parsedTime = DateFormat('HH:mm:ss').parse(timeString);
            formattedTime = DateFormat('HH:mm').format(parsedTime);
          } catch (e) {
            if (timeString.length >= 5) {
              formattedTime = timeString.substring(0, 5);
            } else {
              formattedTime = timeString;
            }
          }
        }

        IconData _getIconForScheduleType(String? type) {
          switch (type) {
            case '진료':
              return Icons.medical_services;
            case '검사':
              return Icons.health_and_safety;
            case '상담':
              return Icons.supervisor_account; // 상담에 더 적합한 아이콘
            case '기타':
              return Icons.pending; // 'etc' 아이콘은 없으므로 'pending' 또는 다른 아이콘 사용
            default:
              return Icons.event; // 기본 아이콘
          }
        }

        // 간단한 ListTile로 일정 표시 (커스텀 위젯으로 만들어도 좋습니다)
        return InkWell(
          onTap: () {
            _navigateToEditScheduleScreen(schedule);
          },
          child: Card(
            elevation: 2, // 카드에 약간의 그림자 효과 추가
            margin: const EdgeInsets.only(bottom: 12.0),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 12.0),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 왼쪽: 아이콘과 시간
                  Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const SizedBox(height: 8),
                      Icon(
                        _getIconForScheduleType(scheduleType),
                        color: AppColors.mainBtn,
                        size: 20,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        formattedTime,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: AppColors.darkTextSecondary,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(width: 16),
                  // 오른쪽: 주요 내용
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // 제목
                        Text(
                          title ?? '제목 없음',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        // 내용
                        Text(
                          content ?? '내용 없음',
                          style: const TextStyle(color: AppColors.grey),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 8),
                        // 등록자 정보
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            if (updateAt != null)
                              Text(
                                '수정자: ${updaterName ?? '정보 없음'}',
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: AppColors.grey,
                                ),
                              )
                            // 수정된 적이 없으면 등록자 정보를 표시
                            else
                              Text(
                                '등록자: ${creatorName ?? '정보 없음'}',
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: AppColors.grey,
                                ),
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

bool isSameDay(DateTime? a, DateTime? b) {
  if (a == null || b == null) {
    return false;
  }
  return a.year == b.year && a.month == b.month && a.day == b.day;
}

