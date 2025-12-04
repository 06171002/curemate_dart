import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:curemate/features/widgets/common/custom_text_field.dart'; // 공통 텍스트 필드
import 'package:curemate/services/calendar_service.dart';
import 'package:curemate/features/patient/viewmodel/patient_viewmodel.dart';
import '../../../app/theme/app_colors.dart';
import 'package:provider/provider.dart';
import 'package:curemate/features/widgets/common/bottom_nav_provider.dart';


enum ScheduleCategory { personal, patient }

class NewScheduleScreen extends StatefulWidget {
  final DateTime selectedDateFromPreviousScreen;
  final Map<String, dynamic>? existingSchedule;

  const NewScheduleScreen({
    super.key,
    required this.selectedDateFromPreviousScreen,
    this.existingSchedule,
  });

  @override
  State<NewScheduleScreen> createState() => _NewScheduleScreenState();
}

class _NewScheduleScreenState extends State<NewScheduleScreen> {
  // --- 상태 변수 ---
  int? _selectedPatientId;
  int? _selectedCureSeq;
  String _selectedScheduleType = '진료';
  final List<String> _scheduleTypes = ['진료', '복약', '검사', '기타'];

  String _repeatOption = '반복 없음';
  final List<String> _repeatOptions = ['반복 없음', '매일', '매주', '매월', '매년'];

  // [추가] 반복 종료일 관련 변수
  DateTime? _repeatEndDate; // 반복 종료 날짜
  bool _isRepeatNoEnd = true; // '계속 반복(종료일 없음)' 여부
  final TextEditingController _repeatEndDateController = TextEditingController(); // 표시용 컨트롤러

  late DateTime _startDate;
  late DateTime _endDate;
  late String _startTime;
  late String _endTime;
  bool _isAllDay = false;

  // 30분 단위 시간 리스트
  final List<String> _timeOptions = List.generate(48, (index) {
    final hour = index ~/ 2;
    final minute = (index % 2) * 30;
    return '${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}';
  });

  final _formKey = GlobalKey<FormState>();

  // 컨트롤러
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _contentController = TextEditingController();

  // 날짜/시간 표시용 컨트롤러 (readOnly CustomTextField용)
  final TextEditingController _startDateController = TextEditingController();
  final TextEditingController _endDateController = TextEditingController();
  final TextEditingController _startTimeController = TextEditingController();
  final TextEditingController _endTimeController = TextEditingController();
  final TextEditingController _repeatController = TextEditingController();

  // 옵션들
  bool _isPublic = true;
  bool _isAlarmOn = false;
  String _alarmType = '푸시';
  final List<String> _alarmTypes = ['푸시', 'SMS', '이메일'];
  String _alarmTime = '10분 전';
  final List<String> _alarmTimeOptions = ['정각', '5분 전', '10분 전', '30분 전', '1시간 전', '하루 전'];

  bool _isLoading = false;
  final CalendarService _calendarService = CalendarService();

  bool get _isEditing => widget.existingSchedule != null;

  ScheduleCategory _selectedCategory = ScheduleCategory.personal;

  @override
  void initState() {
    super.initState();

    // 환자 목록 불러오기
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<PatientViewModel>().fetchPatients();
    });

    _initData();
  }

  void _initData() {
    final now = DateTime.now();

    if (_isEditing) {
      final schedule = widget.existingSchedule!;
      _titleController.text = schedule['title'] ?? '';
      _contentController.text = schedule['content'] ?? '';
      _selectedScheduleType = schedule['schedule_type'] ?? '진료';
      _isPublic = schedule['is_public'] ?? true; // DB 필드명 확인 필요

      try {
        _startDate = DateTime.parse(schedule['start_date']);
        _endDate = DateTime.parse(schedule['end_date']);
        _isAllDay = schedule['isAllDay'] == 1 || schedule['isAllDay'] == true;

        if (!_isAllDay) {
          _startTime = schedule['start_time'] ?? "09:00";
          _endTime = schedule['end_time'] ?? "10:00";
        } else {
          _startTime = "00:00";
          _endTime = "23:59";
        }
      } catch (e) {
        _startDate = DateTime.now();
        _endDate = DateTime.now();
        _startTime = "09:00";
        _endTime = "10:00";
      }

      // ▼ [수정] 환자 ID가 있으면 '환자 일정' 모드로 자동 전환하고 ID 설정
      if (schedule.containsKey('patient_id') && schedule['patient_id'] != null && schedule['patient_id'] != 0) {
        _selectedPatientId = schedule['patient_id'];
        _selectedCategory = ScheduleCategory.patient; // ★ 핵심: 카테고리를 '환자'로 변경
      } else {
        _selectedCategory = ScheduleCategory.personal;
      }

      // ▼ [추가] 알람 정보 초기화 코드
      if (schedule.containsKey('isAlarmOn')) {
        _isAlarmOn = schedule['isAlarmOn'];
        _alarmTime = schedule['alarmTime'] ?? '10분 전';
        _alarmType = schedule['alarmType'] ?? '푸시';
      }

      // ▼▼▼ [추가] 반복 설정 값 받기 ▼▼▼
      if (schedule.containsKey('repeatOption')) {
        _repeatOption = schedule['repeatOption'];
      }

      // [추가] cure_seq 값 받기
      if (schedule.containsKey('cure_seq')) {
        _selectedCureSeq = schedule['cure_seq'];
      }

      if (schedule.containsKey('patient_id')) {
        _selectedPatientId = schedule['patient_id'];
      }

      // [추가] 반복 종료일 데이터 로딩
      if (schedule['repeatEndDate'] != null) {
        _repeatEndDate = DateTime.parse(schedule['repeatEndDate']);
        _isRepeatNoEnd = false; // 종료일 있음
      } else {
        _isRepeatNoEnd = true; // 계속 반복
        _repeatEndDate = null;
      }

    } else {
      // 신규 등록
      _startDate = widget.selectedDateFromPreviousScreen;
      _endDate = widget.selectedDateFromPreviousScreen;

      int minute = now.minute >= 30 ? 30 : 0;
      final startDt = DateTime(now.year, now.month, now.day, now.hour, minute);
      final endDt = startDt.add(const Duration(hours: 1));

      _startTime = "${startDt.hour.toString().padLeft(2, '0')}:${startDt.minute.toString().padLeft(2, '0')}";
      _endTime = "${endDt.hour.toString().padLeft(2, '0')}:${endDt.minute.toString().padLeft(2, '0')}";

      // 신규 등록 시 기본값: 반복 종료일 없음(계속 반복)
      _isRepeatNoEnd = true;
      _repeatEndDate = DateTime.now().add(const Duration(days: 365)); // UI상 보여줄 기본값 정도
    }

    _updateDateTimeControllers();
  }

  void _updateDateTimeControllers() {
    _startDateController.text = DateFormat('yyyy-MM-dd').format(_startDate);
    _endDateController.text = DateFormat('yyyy-MM-dd').format(_endDate);
    _startTimeController.text = _startTime;
    _endTimeController.text = _endTime;
    _repeatController.text = _repeatOption;

    // [추가] 반복 종료일 컨트롤러 업데이트
    if (_repeatEndDate != null) {
      _repeatEndDateController.text = DateFormat('yyyy-MM-dd').format(_repeatEndDate!);
    } else {
      _repeatEndDateController.text = "";
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    _startDateController.dispose();
    _endDateController.dispose();
    _startTimeController.dispose();
    _endTimeController.dispose();
    _repeatController.dispose();
    super.dispose();
  }

  // --- 날짜/시간 선택 로직 ---
  Future<void> _pickDate(bool isStart) async {
    final DateTime initial = isStart ? _startDate : _endDate;
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
      builder: (context, child) {
        return Theme(
          data: ThemeData.light().copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppColors.mainBtn, // 선택 색상
              onPrimary: Colors.white,
              onSurface: AppColors.textMainDark,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        if (isStart) {
          _startDate = picked;
          if (_startDate.isAfter(_endDate)) {
            _endDate = picked;
          }
        } else {
          _endDate = picked;
          if (_endDate.isBefore(_startDate)) {
            _startDate = picked;
          }
        }
        _updateDateTimeControllers();
      });
    }
  }

  void _pickTime(bool isStart) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) {
        return Container(
          height: 300,
          padding: const EdgeInsets.only(top: 20),
          child: Column(
            children: [
              Text(isStart ? "시작 시간" : "종료 시간", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
              const SizedBox(height: 10),
              Expanded(
                child: ListView.builder(
                  itemCount: _timeOptions.length,
                  itemBuilder: (context, index) {
                    return ListTile(
                      title: Center(child: Text(_timeOptions[index])),
                      onTap: () {
                        setState(() {
                          if (isStart) _startTime = _timeOptions[index];
                          else _endTime = _timeOptions[index];
                          _updateDateTimeControllers();
                        });
                        Navigator.pop(context);
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _pickRepeat() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text("반복 설정", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
              const SizedBox(height: 10),
              ..._repeatOptions.map((option) => ListTile(
                title: Center(child: Text(option)),
                onTap: () {
                  setState(() {
                    _repeatOption = option;
                    _updateDateTimeControllers();
                  });
                  Navigator.pop(context);
                },
              )),
            ],
          ),
        );
      },
    );
  }

  void _showSelectionModal(String title, List<String> options, String currentVal, Function(String) onSelected) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      isScrollControlled: true,
      builder: (context) {
        return SingleChildScrollView(
          child: Container(
            padding: EdgeInsets.only(top: 16, bottom: MediaQuery.of(context).padding.bottom + 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Padding(
                  padding: const EdgeInsets.only(bottom: 16.0),
                  child: Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                ),
                ...options.map((option) => ListTile(
                  title: Text(option),
                  trailing: option == currentVal ? const Icon(Icons.check, color: AppColors.mainBtn) : null,
                  onTap: () {
                    onSelected(option);
                    Navigator.pop(context);
                  },
                )),
              ],
            ),
          ),
        );
      },
    );
  }

  // --- 저장 로직 ---
  void _saveSchedule() async {
    final navProvider = context.read<BottomNavProvider>();
    final bool isMainMode = navProvider.isMainMode;

    if (!_formKey.currentState!.validate()) return;
    if (_selectedPatientId == null && !_isEditing && _selectedCategory != ScheduleCategory.personal) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('환자를 선택해주세요.')));
      return;
    }
    if (_isLoading) return;

    setState(() => _isLoading = true);

    try {
      String startDateStr = DateFormat('yyyy-MM-dd').format(_startDate);
      String endDateStr = DateFormat('yyyy-MM-dd').format(_endDate);

      // ====================================================
      // [1] 반복 주기(int) 및 요일 플래그(Y/N) 계산 로직 추가
      // ====================================================
      int repeatCycle = 0; // DB: cure_schedule_repeat (int)
      String monYn = 'N';
      String tueYn = 'N';
      String wedYn = 'N';
      String thuYn = 'N';
      String friYn = 'N';
      String satYn = 'N';
      String sunYn = 'N';

      // 반복이 설정된 경우
      if (_repeatOption != '반복 없음') {
        repeatCycle = 1; // 기본적으로 '매'주, '매'일 이므로 주기는 1로 설정

        if (_repeatOption == '매일') {
          // 매일이면 모든 요일 Y
          monYn = 'Y'; tueYn = 'Y'; wedYn = 'Y'; thuYn = 'Y'; friYn = 'Y'; satYn = 'Y'; sunYn = 'Y';
        }
        else if (_repeatOption == '매주') {
          // 매주면 '시작일'의 요일을 찾아 해당 요일만 Y로 설정
          // _startDate.weekday: 1(월) ~ 7(일)
          switch (_startDate.weekday) {
            case 1: monYn = 'Y'; break;
            case 2: tueYn = 'Y'; break;
            case 3: wedYn = 'Y'; break;
            case 4: thuYn = 'Y'; break;
            case 5: friYn = 'Y'; break;
            case 6: satYn = 'Y'; break;
            case 7: sunYn = 'Y'; break;
          }
        }
        // '매월', '매년'은 보통 요일 플래그를 쓰지 않고 날짜(일)를 기준으로 하므로 N 유지
      }

      // [중요] 반복 종료일 처리 로직
      String stopYn = 'N'; // 기본: 반복 종료일 없음
      String? stopDttmStr;

      if (_repeatOption != '반복 없음') {
        if (_isRepeatNoEnd) {
          stopYn = 'N';
          // SQL 쿼리상 BETWEEN 조건에 걸리게 하려면 아주 먼 미래 날짜를 넣어주는게 안전합니다.
          stopDttmStr = "4999-12-31 23:59:59";
        } else {
          stopYn = 'Y';
          // 사용자가 지정한 날짜의 끝 시간으로 설정
          if (_repeatEndDate != null) {
            stopDttmStr = "${DateFormat('yyyy-MM-dd').format(_repeatEndDate!)} 23:59:59";
          }
        }
      } else {
        // 반복이 아닐 경우, stopDttm은 해당 일정의 종료일과 같게 설정하거나 null
        stopYn = 'Y';
        stopDttmStr = _isAllDay ? "$endDateStr 23:59:59" : "$endDateStr $_endTime:00";
      }

      // [추가] 반복 코드 매핑 (한글 -> 코드)
      // 서버가 한글('매일')을 그대로 받는지, 코드('DAILY')를 받는지 확인 필요.
      // 보통은 코드로 변환해서 보냅니다. 예시:
      String repeatCode = '';
      switch(_repeatOption) {
        case '매일': repeatCode = 'DAILY'; break;
        case '매주': repeatCode = 'WEEKLY'; break;
        case '매월': repeatCode = 'MONTHLY'; break;
        case '매년': repeatCode = 'YEARLY'; break;
        default: repeatCode = ''; // 반복 없음
      }

      // ====================================================
      // [3] 전송 데이터 맵 구성
      // ====================================================
      final Map<String, dynamic> scheduleData = {
        'cureCalendarSeq': widget.existingSchedule?['cureCalendarSeq'] ?? 0,
        'title': _titleController.text,
        'content': _contentController.text,
        'scheduleType': _selectedScheduleType,

        // --- 기본 일정 ---
        'startDate': startDateStr,
        'endDate': endDateStr,
        'startTime': _isAllDay ? "00:00" : _startTime,
        'endTime': _isAllDay ? "23:59" : _endTime,
        'isAllDay': _isAllDay,

        // --- 반복 정보 (DB 컬럼 매핑) ---
        'cureScheduleRepeatYn': _repeatOption == '반복 없음' ? 'N' : 'Y',

        // [수정] DB의 int형 컬럼에 맞춰 정수값 전달
        'cureScheduleRepeat': repeatCycle,

        // [중요] 계산된 요일 플래그 전달
        'cureScheduleMonYn': monYn,
        'cureScheduleTuesYn': tueYn,
        'cureScheduleWednesYn': wedYn,
        'cureScheduleThursYn': thuYn,
        'cureScheduleFriYn': friYn,
        'cureScheduleSaturYn': satYn,
        'cureScheduleSunYn': sunYn,

        // 종료일 관련
        'cureScheduleStopYn': stopYn,
        'cureScheduleStopDttm': stopDttmStr,

        // --- 기타 ---
        'isPublic': _isPublic,
        'isAlarmOn': _isAlarmOn,
        'alarmType': _isAlarmOn ? _alarmType : null,
        'alarmTime': _isAlarmOn ? _alarmTime : null,
      };

      // 2. 환자/개인 일정 분기 로직 (cureSeq, patientId 설정)
      if (_selectedCategory == ScheduleCategory.personal) {
        scheduleData['cureSeq'] = 0;
        scheduleData['patientId'] = 0;
      } else {
        if (isMainMode) {
          scheduleData['cureSeq'] = _selectedCureSeq;
          scheduleData['patientId'] = _selectedPatientId;
        } else {
          scheduleData['cureSeq'] = navProvider.cureSeq;
          scheduleData['patientId'] = 0; // 필요 시 수정
        }
      }

      // 3. 서비스 호출 (통합된 메서드 하나만 사용)
      await _calendarService.saveSchedule(scheduleData);

      if (mounted) {
        Navigator.pop(context, true);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('일정이 ${_isEditing ? '수정' : '저장'}되었습니다.')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('저장 실패: $e')));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _showDeleteConfirmDialog() async {
    // 삭제 확인 다이얼로그 구현 (필요 시)
  }

  // [추가] 반복 종료일 선택 함수
  Future<void> _pickRepeatEndDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _repeatEndDate ?? _startDate.add(const Duration(days: 30)),
      firstDate: _startDate, // 시작일보다 전일 수 없음
      lastDate: DateTime(2100),
      builder: (context, child) {
        return Theme(
          data: ThemeData.light().copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppColors.mainBtn,
              onPrimary: Colors.white,
              onSurface: AppColors.textMainDark,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        _repeatEndDate = picked;
        _isRepeatNoEnd = false; // 날짜를 선택했으므로 '계속 반복' 아님
        _updateDateTimeControllers();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // [1] Provider에서 정보 가져오기 (매개변수로 안 넘겨도 됨!)
    final navProvider = context.watch<BottomNavProvider>();
    final bool isMainMode = navProvider.isMainMode;
    final int? currentCureSeq = navProvider.cureSeq;
    final String? currentCureName = navProvider.cureName;

    final patientViewModel = context.watch<PatientViewModel>();

    return Scaffold(
      backgroundColor: AppColors.white, // 배경색 통일 (AddPatientPage와 동일)
      appBar: AppBar(
        backgroundColor: AppColors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: AppColors.textMainDark),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          _isEditing ? '일정 수정' : '일정 추가',
          style: const TextStyle(
            color: AppColors.textMainDark,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // ------------------------------------------------
                // 1. [신규] 일정 카테고리 선택 (라디오 버튼)
                // ------------------------------------------------
                if (!_isEditing) ...[
                  Row(
                    children: [
                      Expanded(
                        child: RadioListTile<ScheduleCategory>(
                          title: const Text('개인 일정', style: TextStyle(fontSize: 14)),
                          value: ScheduleCategory.personal,
                          groupValue: _selectedCategory,
                          contentPadding: EdgeInsets.zero,
                          activeColor: AppColors.mainBtn,
                          onChanged: (value) => setState(() => _selectedCategory = value!),
                        ),
                      ),
                      Expanded(
                        child: RadioListTile<ScheduleCategory>(
                          title: const Text('환자 일정', style: TextStyle(fontSize: 14)),
                          value: ScheduleCategory.patient,
                          groupValue: _selectedCategory,
                          contentPadding: EdgeInsets.zero,
                          activeColor: AppColors.mainBtn,
                          onChanged: (value) => setState(() => _selectedCategory = value!),
                        ),
                      ),
                    ],
                  ),
                  const Divider(height: 32, thickness: 1, color: AppColors.lightGrey),
                ],

                // ------------------------------------------------
                // 2. [조건부 UI] 환자 일정 선택 시에만 표시되는 항목들
                // ------------------------------------------------
                if (_selectedCategory == ScheduleCategory.patient) ...[

                  // A. 대상 선택 영역
                  if (isMainMode) ...[
                    // [메인 모드] -> 환자를 직접 선택해야 함
                    _buildSectionLabel('대상 환자'),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<int>(
                      decoration: _inputDecoration(), // 아래 헬퍼 함수 사용
                      value: _selectedPatientId,
                      hint: const Text('환자를 선택하세요', style: TextStyle(color: AppColors.textSecondaryLight, fontSize: 14)),
                      items: patientViewModel.patients.map((patient) {
                        final int pId = patient['patient_id'] ?? patient['id'];
                        final String pName = patient['name'] ?? '이름 없음';
                        return DropdownMenuItem<int>(value: pId, child: Text(pName));
                      }).toList(),
                      onChanged: _isEditing ? null : (value) {
                        setState(() {
                          _selectedPatientId = value;
                          // 선택된 환자에서 cureSeq 찾기
                          final selectedPatient = patientViewModel.patients.firstWhere(
                                (element) => (element['patient_id'] ?? element['id']) == value,
                            orElse: () => {},
                          );
                          _selectedCureSeq = selectedPatient['cure_seq'] ?? selectedPatient['cureSeq'];
                        });
                      },
                    ),
                  ],
                  const SizedBox(height: 24),

                  // B. 일정 유형 (진료/복약 등) -> 환자 일정일 때만 표시
                  _buildSectionLabel('일정 유형'),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 10,
                    children: _scheduleTypes.map((type) {
                      final isSelected = _selectedScheduleType == type;
                      return ChoiceChip(
                        label: Text(
                          type,
                          style: TextStyle(
                            color: isSelected ? Colors.white : AppColors.textMainDark,
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                          ),
                        ),
                        selected: isSelected,
                        selectedColor: AppColors.mainBtn,
                        backgroundColor: AppColors.lightGrey,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                          side: BorderSide(color: isSelected ? Colors.transparent : AppColors.inputBorder),
                        ),
                        onSelected: (bool selected) {
                          if (selected) setState(() => _selectedScheduleType = type);
                        },
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 24),
                ],

                // 2. 일정 제목
                CustomTextField(
                  label: '제목',
                  hint: '일정 제목을 입력하세요',
                  controller: _titleController,
                  isRequired: true,
                ),
                const SizedBox(height: 24),

                // 4. 날짜 및 시간 선택
                Row(
                  children: [
                    Expanded(
                      child: CustomTextField(
                        label: '시작일',
                        controller: _startDateController,
                        readOnly: true,
                        onTap: () => _pickDate(true),
                        suffixIcon: Icons.calendar_today_outlined,
                      ),
                    ),
                    if (!_isAllDay) ...[
                      const SizedBox(width: 12),
                      Expanded(
                        child: CustomTextField(
                          label: '시간',
                          controller: _startTimeController,
                          readOnly: true,
                          onTap: () => _pickTime(true),
                          suffixIcon: Icons.access_time,
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: CustomTextField(
                        label: '종료일',
                        controller: _endDateController,
                        readOnly: true,
                        onTap: () => _pickDate(false),
                        suffixIcon: Icons.calendar_today_outlined,
                      ),
                    ),
                    if (!_isAllDay) ...[
                      const SizedBox(width: 12),
                      Expanded(
                        child: CustomTextField(
                          label: '시간',
                          controller: _endTimeController,
                          readOnly: true,
                          onTap: () => _pickTime(false),
                          suffixIcon: Icons.access_time,
                        ),
                      ),
                    ],
                  ],
                ),

                // 종일 설정 체크박스
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Checkbox(
                      value: _isAllDay,
                      activeColor: AppColors.mainBtn,
                      onChanged: (val) => setState(() => _isAllDay = val ?? false),
                    ),
                    const Text("종일 설정", style: TextStyle(fontSize: 14)),
                  ],
                ),
                const SizedBox(height: 12),

                // 5. 반복 설정
                CustomTextField(
                  label: '반복',
                  controller: _repeatController,
                  readOnly: true,
                  onTap: _pickRepeat,
                  suffixIcon: Icons.repeat,
                ),
                const SizedBox(height: 24),

                // [추가] 반복 종료 설정 (반복이 설정된 경우에만 표시)
                if (_repeatOption != '반복 없음') ...[
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.lightGrey, // 연한 회색 배경 추천
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('반복 종료', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            // '계속 반복' 라디오 버튼
                            Expanded(
                              child: RadioListTile<bool>(
                                title: const Text('계속 반복', style: TextStyle(fontSize: 14)),
                                value: true,
                                groupValue: _isRepeatNoEnd,
                                contentPadding: EdgeInsets.zero,
                                activeColor: AppColors.mainBtn,
                                onChanged: (val) {
                                  setState(() {
                                    _isRepeatNoEnd = val!;
                                    _repeatEndDate = null; // 날짜 초기화
                                    _updateDateTimeControllers();
                                  });
                                },
                              ),
                            ),
                            // '날짜 지정' 라디오 버튼
                            Expanded(
                              child: RadioListTile<bool>(
                                title: const Text('날짜 지정', style: TextStyle(fontSize: 14)),
                                value: false,
                                groupValue: _isRepeatNoEnd,
                                contentPadding: EdgeInsets.zero,
                                activeColor: AppColors.mainBtn,
                                onChanged: (val) {
                                  setState(() {
                                    _isRepeatNoEnd = val!;
                                    // 기본값 세팅
                                    _repeatEndDate ??= _endDate.add(const Duration(days: 30));
                                    _updateDateTimeControllers();
                                  });
                                },
                              ),
                            ),
                          ],
                        ),
                        // 날짜 지정 선택 시에만 DatePicker 표시
                        if (!_isRepeatNoEnd)
                          GestureDetector(
                            onTap: _pickRepeatEndDate,
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                border: Border.all(color: AppColors.inputBorder),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    _repeatEndDateController.text.isEmpty
                                        ? '종료일 선택'
                                        : _repeatEndDateController.text,
                                    style: TextStyle(
                                      color: _repeatEndDateController.text.isEmpty ? Colors.grey : Colors.black,
                                    ),
                                  ),
                                  const Icon(Icons.calendar_today, size: 18, color: Colors.grey),
                                ],
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                ],

                // 6. 내용 (메모)
                CustomTextField(
                  label: '내용',
                  hint: '상세 내용을 입력하세요 (선택)',
                  controller: _contentController,
                  maxLines: 4,
                ),
                const SizedBox(height: 24),

                // 7. 추가 옵션 (공개 여부, 알람) - SwitchListTile 사용 시 스타일 조정
                Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.inputBorder),
                    color: AppColors.white,
                  ),
                  child: Column(
                    children: [
                      SwitchListTile(
                        title: const Text('공개 여부', style: TextStyle(fontSize: 14, color: AppColors.textMainDark)),
                        value: _isPublic,
                        activeColor: AppColors.mainBtn,
                        onChanged: (val) => setState(() => _isPublic = val),
                        secondary: const Icon(Icons.visibility_outlined, color: AppColors.textSecondaryLight),
                      ),
                      const Divider(height: 1, indent: 16, endIndent: 16),
                      SwitchListTile(
                        title: const Text('알람 설정', style: TextStyle(fontSize: 14, color: AppColors.textMainDark)),
                        value: _isAlarmOn,
                        activeColor: AppColors.mainBtn,
                        onChanged: (val) => setState(() => _isAlarmOn = val),
                        secondary: const Icon(Icons.notifications_none, color: AppColors.textSecondaryLight),
                      ),
                      if (_isAlarmOn) ...[
                        const Divider(height: 1, indent: 16, endIndent: 16),
                        ListTile(
                          title: const Text('알람 종류', style: TextStyle(fontSize: 14)),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(_alarmType, style: const TextStyle(color: AppColors.mainBtn)),
                              const Icon(Icons.chevron_right, size: 20, color: Colors.grey),
                            ],
                          ),
                          onTap: () => _showSelectionModal('알람 종류', _alarmTypes, _alarmType, (v) => setState(() => _alarmType = v)),
                        ),
                        ListTile(
                          title: const Text('알람 시간', style: TextStyle(fontSize: 14)),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(_alarmTime, style: const TextStyle(color: AppColors.mainBtn)),
                              const Icon(Icons.chevron_right, size: 20, color: Colors.grey),
                            ],
                          ),
                          onTap: () => _showSelectionModal('알람 시간', _alarmTimeOptions, _alarmTime, (v) => setState(() => _alarmTime = v)),
                        ),
                      ]
                    ],
                  ),
                ),
                const SizedBox(height: 40),

                // 8. 버튼 영역 (수정 모드일 땐 반반, 신규일 땐 꽉 채우기)
                if (_isEditing)
                  Row(
                    children: [
                      // [삭제 버튼] - 50%
                      Expanded(
                        child: ElevatedButton(
                          onPressed: _isLoading ? null : _showDeleteConfirmDialog,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.white, // 배경색 (흰색)
                            foregroundColor: AppColors.error, // 글자색 (빨간색)
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                              side: const BorderSide(color: AppColors.error), // 테두리 (선택 사항)
                            ),
                            elevation: 0,
                          ),
                          child: const Text(
                            '삭제',
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12), // 버튼 사이 간격

                      // [수정 완료 버튼] - 50%
                      Expanded(
                        child: ElevatedButton(
                          onPressed: _isLoading ? null : _saveSchedule,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.mainBtn,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            elevation: 0,
                          ),
                          child: _isLoading
                              ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                              : const Text('수정 완료', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
                        ),
                      ),
                    ],
                  )
                else
                // [일정 등록 버튼] - 100% (신규 등록 시)
                  ElevatedButton(
                    onPressed: _isLoading ? null : _saveSchedule,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.mainBtn,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      elevation: 0,
                    ),
                    child: _isLoading
                        ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                        : const Text('일정 등록', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
                  ),

                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSectionLabel(String label) {
    return Text(
        label,
        style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.bold,
          color: AppColors.textMainDark,
          fontFamily: 'Pretendard',
        )
    );
  }

  // 스타일 헬퍼 함수
  InputDecoration _inputDecoration() {
    return InputDecoration(
      filled: true,
      fillColor: AppColors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.inputBorder)),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.inputBorder)),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.activeColor, width: 2)),
    );
  }
}