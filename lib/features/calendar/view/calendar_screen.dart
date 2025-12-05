import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:curemate/app/theme/app_colors.dart';
import 'package:curemate/features/calendar/view/calendar_widget.dart';
import 'package:curemate/features/calendar/view/new_schedule_screen.dart';
import 'package:curemate/services/calendar_service.dart';
import 'package:provider/provider.dart';
import 'package:curemate/features/widgets/common/bottom_nav_provider.dart';
import 'package:curemate/features/calendar/model/calendar_model.dart';

class CalendarScreen extends StatefulWidget {
  const CalendarScreen({super.key});

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  final CalendarFormat _calendarFormat = CalendarFormat.month;

  // 달력 확장 상태 관리
  bool _isCalendarExpanded = false;

  bool? _lastIsMainMode;
  int? _lastCureSeq;

  Map<DateTime, List<Map<String, dynamic>>> _events = {};
  final CalendarService _calendarService = CalendarService();

  @override
  void initState() {
    super.initState();
    _selectedDay = _focusedDay;
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final navProvider = context.watch<BottomNavProvider>();
    final isMainMode = navProvider.isMainMode;
    final cureSeq = navProvider.cureSeq;

    if (_lastIsMainMode != isMainMode || _lastCureSeq != cureSeq) {
      _lastIsMainMode = isMainMode;
      _lastCureSeq = cureSeq;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _fetchMonthlySchedules(_focusedDay);
      });
    }
  }

  Future<void> _fetchMonthlySchedules(DateTime date) async {
    final navProvider = context.read<BottomNavProvider>();
    final bool isMainMode = navProvider.isMainMode;
    final int? cureSeq = navProvider.cureSeq;
    List<Map<String, dynamic>> schedules = [];

    try {
      if (!isMainMode && cureSeq != null) {
        final String month = DateFormat('yyyyMM').format(date);
        final List<CureCalendarModel> models =
        await _calendarService.getCureCalendarList(cureSeq, month);
        schedules = models.map((e) => e.toJson()).toList();
      } else {
        schedules = await _calendarService.getMonthlyScheduleList(date);
      }
    } catch (e) {
      print('일정 로드 실패: $e');
      schedules = [];
    }

    if (!mounted) return;

    setState(() {
      _events.clear();
      final firstDayOfMonth = DateTime(date.year, date.month, 1);
      final lastDayOfMonth = DateTime(date.year, date.month + 1, 0);
      int daysInMonth = lastDayOfMonth.day;

      for (var data in schedules) {
        final scheduleInfo = data['schedule'];
        if (scheduleInfo == null) continue;
        DateTime? sStart;
        if (scheduleInfo['cureScheduleStartDttm'] != null) {
          sStart = DateTime.parse(scheduleInfo['cureScheduleStartDttm']);
        }
        if (sStart == null) continue;
        DateTime? sStop;
        if (scheduleInfo['cureScheduleStopDttm'] != null) {
          sStop = DateTime.parse(scheduleInfo['cureScheduleStopDttm']);
        }
        String stopYn = scheduleInfo['cureScheduleStopYn'] ?? 'N';

        for (int i = 0; i < daysInMonth; i++) {
          DateTime targetDate = firstDayOfMonth.add(Duration(days: i));
          if (stopYn == 'Y' && sStop != null) {
            if (targetDate.isAfter(sStop)) continue;
          }
          if (_isScheduleOnDate(data, targetDate, sStart)) {
            final key = DateTime(targetDate.year, targetDate.month, targetDate.day);
            if (_events[key] == null) _events[key] = [];
            _events[key]!.add(data);
          }
        }
      }
      _events.forEach((date, scheduleList) {
        scheduleList.sort((a, b) {
          final startA = a['schedule']?['cureScheduleStartDttm'] ?? '';
          final startB = b['schedule']?['cureScheduleStartDttm'] ?? '';
          return startA.compareTo(startB);
        });
      });
    });
  }

  bool _isScheduleOnDate(Map<String, dynamic> data, DateTime targetDate, DateTime sStart) {
    final schedule = data['schedule'];
    if (schedule == null) return false;
    String repeatYn = schedule['cureScheduleRepeatYn'] ?? 'N';
    String type = schedule['cureScheduleTypeCmcd'] ?? 'daily';

    if (type != 'daily') {
      final DateTime startDateOnly = DateTime(sStart.year, sStart.month, sStart.day);
      if (targetDate.isBefore(startDateOnly)) return false;
    }
    if (repeatYn == 'N') {
      DateTime? sEnd = schedule['cureScheduleEndDttm'] != null
          ? DateTime.parse(schedule['cureScheduleEndDttm'])
          : sStart;
      DateTime start = DateTime(sStart.year, sStart.month, sStart.day);
      DateTime end = DateTime(sEnd.year, sEnd.month, sEnd.day);
      DateTime target = DateTime(targetDate.year, targetDate.month, targetDate.day);
      return !target.isBefore(start) && !target.isAfter(end);
    }
    if (type == 'daily') return true;
    if (type == 'weekly') {
      switch (targetDate.weekday) {
        case DateTime.monday: return schedule['cureScheduleMonYn'] == 'Y';
        case DateTime.tuesday: return schedule['cureScheduleTuesYn'] == 'Y';
        case DateTime.wednesday: return schedule['cureScheduleWednesYn'] == 'Y';
        case DateTime.thursday: return schedule['cureScheduleThursYn'] == 'Y';
        case DateTime.friday: return schedule['cureScheduleFriYn'] == 'Y';
        case DateTime.saturday: return schedule['cureScheduleSaturYn'] == 'Y';
        case DateTime.sunday: return schedule['cureScheduleSunYn'] == 'Y';
        default: return false;
      }
    }
    if (type == 'monthly' || type == 'yearly') return true;
    return false;
  }

  List<Map<String, dynamic>> _getEventsForDay(DateTime day) {
    final key = DateTime(day.year, day.month, day.day);
    return _events[key] ?? [];
  }

  String _mapCodeToLabel(String? code) {
    switch (code) {
      case 'treatment': return '진료';
      case 'medicine': return '복약';
      case 'test': return '검사';
      case 'etc': return '기타';
      default: return '기타';
    }
  }

  String _calculateAlarmOption(String startDttmStr, String alarmDttmStr) {
    try {
      DateTime start = DateTime.parse(startDttmStr.replaceAll(' ', 'T'));
      DateTime alarm = DateTime.parse(alarmDttmStr.replaceAll(' ', 'T'));
      Duration diff = start.difference(alarm);
      if (diff.inMinutes <= 0) return '정각';
      if (diff.inMinutes == 5) return '5분 전';
      if (diff.inMinutes == 10) return '10분 전';
      if (diff.inMinutes == 30) return '30분 전';
      if (diff.inHours == 1) return '1시간 전';
      if (diff.inDays == 1) return '하루 전';
      return '10분 전';
    } catch (e) {
      return '10분 전';
    }
  }

  String _mapAlarmTypeLabel(String? code) {
    if (code == 'sms') return 'SMS';
    if (code == 'email') return '이메일';
    return '푸시';
  }

  String _mapRepeatCodeToOption(String? repeatYn, String? typeCode) {
    if (repeatYn != 'Y') return '반복 없음';
    switch (typeCode) {
      case 'daily': return '매일';
      case 'weekly': return '매주';
      case 'monthly': return '매월';
      case 'yearly': return '매년';
      default: return '반복 없음';
    }
  }

  @override
  Widget build(BuildContext context) {
    final navProvider = context.read<BottomNavProvider>();
    final selectedEvents = _selectedDay != null ? _getEventsForDay(_selectedDay!) : [];

    return LayoutBuilder(
      builder: (context, constraints) {
        final screenHeight = constraints.maxHeight;
        final double minListHeight = _isCalendarExpanded ? 0 : screenHeight - 120;
        final double calendarHeight = _isCalendarExpanded ? screenHeight : 450.0;

        return Scaffold(
          backgroundColor: AppColors.lightBackground,

          // ✅ [핵심 1] NotificationListener 로직 수정
          body: NotificationListener<ScrollNotification>(
            onNotification: (notification) {

              // 1. 확장 (Expand) 감지
              // - 사용자가 손으로 당기고 있고 (dragDetails != null)
              // - 스크롤이 위쪽 한계선을 넘어서 당겨졌을 때 (pixels < -50)
              if (notification.metrics.pixels < -200 &&
                  notification is ScrollUpdateNotification &&
                  notification.dragDetails != null &&
                  !_isCalendarExpanded) {
                setState(() {
                  _isCalendarExpanded = true;
                });
              }

              // 2. 축소 (Shrink) 감지
              // - 이미 확장된 상태이고
              // - 사용자가 손으로 밀어 올리고 있고 (dragDetails != null)
              // - ✅ [수정됨] 스크롤 위치가 0보다 클 때만 (pixels > 0) 축소
              //   (이렇게 해야 당기다가 손가락이 살짝 위로 가는 '떨림'이나 '반동'을 무시함)
              if (_isCalendarExpanded &&
                  notification is ScrollUpdateNotification &&
                  notification.metrics.pixels > 10 && // 0보다 조금 여유를 둠
                  notification.scrollDelta! > 0 &&
                  notification.dragDetails != null) {
                setState(() {
                  _isCalendarExpanded = false;
                });
              }
              return false;
            },
            child: CustomScrollView(
              physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
              slivers: [
                SliverAppBar(
                  automaticallyImplyLeading: false,
                  backgroundColor: AppColors.lightBackground,
                  expandedHeight: calendarHeight,
                  pinned: false,
                  floating: false,

                  // 확장 상태에서도 stretch를 유지하면 더 자연스러울 수 있음
                  stretch: true,

                  flexibleSpace: FlexibleSpaceBar(
                    stretchModes: const [StretchMode.zoomBackground],
                    background: Container(
                      color: AppColors.lightBackground,
                      padding: const EdgeInsets.only(bottom: 20),
                      alignment: _isCalendarExpanded ? Alignment.center : Alignment.bottomCenter,
                      child: Container(
                        margin: const EdgeInsets.symmetric(horizontal: 16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: const BorderRadius.vertical(bottom: Radius.circular(24)),
                          boxShadow: [
                            BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4)),
                          ],
                        ),
                        // [중요] CalendarWidget의 shouldFillViewport: true가 설정되어 있어야 함
                        child: CalendarWidget(
                          focusedDay: _focusedDay,
                          selectedDay: _selectedDay,
                          calendarFormat: _calendarFormat,
                          events: _events,
                          onPageChanged: (focusedDay) {
                            _focusedDay = focusedDay;
                            _fetchMonthlySchedules(focusedDay);
                          },
                          onDaySelected: (selectedDay, focusedDay) {
                            setState(() {
                              _selectedDay = selectedDay;
                              _focusedDay = focusedDay;
                            });
                          },
                        ),
                      ),
                    ),
                  ),
                ),

                if (_selectedDay != null)
                  SliverPersistentHeader(
                    pinned: true,
                    delegate: _StickyHeaderDelegate(
                      child: Container(
                        color: AppColors.lightBackground,
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                        child: Row(
                          children: [
                            Text(
                              "${_selectedDay!.month}월 ${_selectedDay!.day}일",
                              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textMainDark),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              "${selectedEvents.length}개의 일정",
                              style: const TextStyle(fontSize: 14, color: AppColors.textSecondaryLight),
                            ),
                            const Spacer(),
                            if (_isCalendarExpanded)
                              IconButton(
                                icon: const Icon(Icons.keyboard_arrow_up, color: AppColors.textSecondaryLight),
                                onPressed: () => setState(() => _isCalendarExpanded = false),
                              )
                          ],
                        ),
                      ),
                      minHeight: 50.0,
                      maxHeight: 50.0,
                    ),
                  ),

                SliverToBoxAdapter(
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    height: _isCalendarExpanded ? 0 : null,
                    constraints: BoxConstraints(minHeight: _isCalendarExpanded ? 0 : minListHeight),
                    child: _isCalendarExpanded
                        ? const SizedBox.shrink()
                        : (selectedEvents.isEmpty
                        ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.event_note, size: 48, color: Colors.grey[300]),
                          const SizedBox(height: 12),
                          const Text("등록된 일정이 없습니다.", style: TextStyle(color: Colors.grey)),
                        ],
                      ),
                    )
                        : Column(
                      children: selectedEvents.map((schedule) {
                        return Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: _buildTimelineItem(schedule, navProvider),
                        );
                      }).toList(),
                    )),
                  ),
                ),
                const SliverToBoxAdapter(child: SizedBox(height: 80)),
              ],
            ),
          ),

          floatingActionButton: FloatingActionButton(
            onPressed: () {
              final DateTime targetDate = _selectedDay ?? _focusedDay;
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => NewScheduleScreen(selectedDateFromPreviousScreen: targetDate),
                ),
              ).then((_) => _fetchMonthlySchedules(_focusedDay));
            },
            backgroundColor: AppColors.mainBtn,
            shape: const CircleBorder(),
            child: const Icon(Icons.add, color: Colors.white, size: 28),
          ),
        );
      },
    );
  }

  Widget _buildTimelineItem(Map<String, dynamic> schedule, BottomNavProvider navProvider) {
    // ... (기존 코드 동일)
    final scheduleInfo = schedule['schedule'] ?? {};
    String startFullDttm = scheduleInfo['cureScheduleStartDttm'] ?? '';
    String startTime = startFullDttm.length > 16 ? startFullDttm.substring(11, 16) : '';
    String typeLabel = _mapCodeToLabel(schedule['cureCalendarTypeCmcd']);
    String title = schedule['cureCalendarNm'] ?? '제목 없음';

    return GestureDetector(
      onTap: () => _navigateToEditScreen(schedule, navProvider),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 55,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(startTime.isNotEmpty ? startTime : 'All Day', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.textMainDark)),
                  const SizedBox(height: 8),
                  Expanded(child: Container(width: 2, margin: const EdgeInsets.only(right: 4), color: AppColors.inputBorder)),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [BoxShadow(color: AppColors.shadow.withOpacity(0.5), blurRadius: 6, offset: const Offset(0, 2))],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(color: AppColors.memberBg, borderRadius: BorderRadius.circular(6)),
                      child: Text(typeLabel, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.mainBtn)),
                    ),
                    const SizedBox(height: 8),
                    Text(title, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.textMainDark)),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _navigateToEditScreen(Map<String, dynamic> schedule, BottomNavProvider navProvider) {
    // ... (기존 코드 동일)
    final scheduleInfo = schedule['schedule'] ?? {};
    String startFullDttm = scheduleInfo['cureScheduleStartDttm'] ?? '';
    String endFullDttm = scheduleInfo['cureScheduleEndDttm'] ?? '';
    String startDate = startFullDttm.length >= 10 ? startFullDttm.substring(0, 10) : '';
    String endDate = endFullDttm.length >= 10 ? endFullDttm.substring(0, 10) : '';
    String startTime = startFullDttm.length > 16 ? startFullDttm.substring(11, 16) : '00:00';
    String endTime = endFullDttm.length > 16 ? endFullDttm.substring(11, 16) : '00:00';

    List<dynamic> alramList = schedule['alramList'] ?? schedule['alrams'] ?? [];
    bool isAlarmOn = false;
    String alarmTime = '10분 전';
    String alarmType = '푸시';

    if (alramList.isNotEmpty && alramList.first['cureAlramDttm'] != null) {
      isAlarmOn = true;
      final firstAlarm = alramList.first;
      String alarmDttm = firstAlarm['cureAlramDttm'] ?? '';
      if (startFullDttm.isNotEmpty && alarmDttm.isNotEmpty) {
        alarmTime = _calculateAlarmOption(startFullDttm, alarmDttm);
      }
      alarmType = _mapAlarmTypeLabel(firstAlarm['cureAlramTypeCmcd']);
    }

    String repeatOption = _mapRepeatCodeToOption(
        scheduleInfo['cureScheduleRepeatYn'],
        scheduleInfo['cureScheduleTypeCmcd']
    );

    final Map<String, dynamic> mappedSchedule = {
      'schedule_seq': scheduleInfo['cureScheduleSeq'] ?? 0,
      'cureCalendarSeq': schedule['cureCalendarSeq'],
      'title': schedule['cureCalendarNm'] ?? '',
      'content': schedule['cureCalendarDesc'] ?? '',
      'start_date': startDate,
      'end_date': endDate,
      'start_time': startTime,
      'end_time': endTime,
      'isAlarmOn': isAlarmOn,
      'alarmTime': alarmTime,
      'alarmType': alarmType,
      'repeatOption': repeatOption,
      'isAllDay': scheduleInfo['cureScheduleDayYn'] == 'Y',
      'patient_id': schedule['patientSeq'] ?? schedule['patientId'] ?? 0,
      'cure_seq': schedule['cureSeq'] ?? navProvider.cureSeq,
      'schedule_type': _mapCodeToLabel(schedule['cureCalendarTypeCmcd']),
    };

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => NewScheduleScreen(
          selectedDateFromPreviousScreen: _selectedDay ?? DateTime.now(),
          existingSchedule: mappedSchedule,
        ),
      ),
    ).then((result) {
      if (result == true) {
        _fetchMonthlySchedules(_focusedDay);
      }
    });
  }
}

// ... (_StickyHeaderDelegate 클래스 유지)
class _StickyHeaderDelegate extends SliverPersistentHeaderDelegate {
  final Widget child;
  final double minHeight;
  final double maxHeight;

  _StickyHeaderDelegate({
    required this.child,
    required this.minHeight,
    required this.maxHeight,
  });

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    return SizedBox.expand(child: child);
  }

  @override
  double get maxExtent => maxHeight;

  @override
  double get minExtent => minHeight;

  @override
  bool shouldRebuild(_StickyHeaderDelegate oldDelegate) {
    return maxHeight != oldDelegate.maxHeight ||
        minHeight != oldDelegate.minHeight ||
        child != oldDelegate.child;
  }
}