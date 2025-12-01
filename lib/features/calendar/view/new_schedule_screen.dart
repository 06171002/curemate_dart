import 'package:flutter/cupertino.dart'; // iOS 스타일 피커 사용을 위해 필수
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:curemate/features/widgets/common/header_provider.dart';
import 'package:curemate/features/widgets/common/widgets.dart';
import 'package:curemate/services/calendar_service.dart';
import 'package:curemate/features/patient/viewmodel/patient_viewmodel.dart';
import '../../../app/theme/app_colors.dart';

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
  String _selectedScheduleType = '진료';
  final List<String> _scheduleTypes = ['진료', '복약', '검사', '기타'];
  DateTime? _selectedDate;
  String? _selectedTime;
  String _repeatOption = '반복 없음';
  late DateTime _startDate;
  late DateTime _endDate;
  late String _startTime;
  late String _endTime;
  bool _isAllDay = false; // 종일 여부

  // 30분 단위 시간 리스트 생성 (00:00 ~ 23:30)
  final List<String> _timeOptions = List.generate(48, (index) {
    final hour = index ~/ 2;
    final minute = (index % 2) * 30;
    return '${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}';
  });

// 반복 주기 옵션 리스트
  final List<String> _repeatOptions = ['반복 없음', '매일', '매주', '매월', '매년'];

  final _formKey = GlobalKey<FormState>();
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _contentController = TextEditingController();

  // 날짜와 시간을 하나로 관리 (CupertinoDatePicker용)
  late DateTime _selectedDateTime;

  // UI 확장/축소 상태 관리 변수
  bool _isDateExpanded = false;   // 날짜/시간 피커 확장 여부
  bool _isRepeatExpanded = false; // 반복 옵션 확장 여부

  // 옵션들
  bool _isPublic = true;

  // 알람 관련
  bool _isAlarmOn = false;
  String _alarmType = '푸시';
  final List<String> _alarmTypes = ['푸시', 'SMS', '이메일'];
  String _alarmTime = '10분 전';
  final List<String> _alarmTimeOptions = ['정각', '5분 전', '10분 전', '30분 전', '1시간 전', '하루 전'];

  bool _isLoading = false;
  final CalendarService _calendarService = CalendarService();

  bool get _isEditing => widget.existingSchedule != null;

  @override
  void initState() {
    super.initState();

    // 환자 목록 불러오기 및 헤더 설정
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<PatientViewModel>().fetchPatients();
    });

    final now = DateTime.now();

    // 초기 데이터 설정
    if (_isEditing) {
      _initEditData();
    } else {
      _startDate = widget.selectedDateFromPreviousScreen;
      _endDate = widget.selectedDateFromPreviousScreen;

      // 시간 기본값: 현재 시간(30분 단위 절삭) ~ 1시간 뒤
      int minute = now.minute >= 30 ? 30 : 0;
      final startDt = DateTime(now.year, now.month, now.day, now.hour, minute);
      final endDt = startDt.add(const Duration(hours: 1));

      _startTime = "${startDt.hour.toString().padLeft(2, '0')}:${startDt.minute.toString().padLeft(2, '0')}";
      _endTime = "${endDt.hour.toString().padLeft(2, '0')}:${endDt.minute.toString().padLeft(2, '0')}";
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    // 화면이 그려지기 직전에 헤더 정보를 업데이트합니다.
    final header = Provider.of<HeaderProvider>(context, listen: false);
    header.setTitle(_isEditing ? '일정 수정' : '새 일정 추가');
    header.setShowBackButton(true);
    header.setSettingButton(false);
  }

  void _initEditData() {
    final schedule = widget.existingSchedule!;
    _titleController.text = schedule['title'] ?? '';
    _contentController.text = schedule['content'] ?? '';
    _selectedScheduleType = schedule['schedule_type'] ?? '진료';

    // [변경] 날짜와 시간을 분리해서 저장
    try {
      _startDate = DateTime.parse(schedule['start_date']);
      _endDate = DateTime.parse(schedule['end_date']);

      // 종일 일정 여부 확인 (DB에 isAllDay 컬럼이 있다고 가정)
      _isAllDay = schedule['isAllDay'] == 1 || schedule['isAllDay'] == true;

      if (!_isAllDay) {
        _startTime = schedule['start_time'] ?? "09:00";
        _endTime = schedule['end_time'] ?? "10:00";
      } else {
        // 종일일 경우 시간은 임의값 설정
        _startTime = "00:00";
        _endTime = "23:59";
      }
    } catch (e) {
      // 파싱 실패 시 기본값
      _startDate = DateTime.now();
      _endDate = DateTime.now();
      _startTime = "09:00";
      _endTime = "10:00";
    }

    if (schedule.containsKey('patient_id')) {
      _selectedPatientId = schedule['patient_id'];
    }

    // 서버에 저장된 추가 필드가 있다면 여기서 바인딩 (예시)
    // _isPublic = schedule['isPublic'] ?? true;
    // _repeatOption = schedule['repeatOption'] ?? '반복 없음';
    // _isAlarmOn = schedule['isAlarmOn'] ?? false;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  // --- 하단 모달 (알람 종류/시간 선택용) - 수정됨 ---
  void _showSelectionModal(String title, List<String> options, String currentVal, Function(String) onSelected) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      isScrollControlled: true, // 높이 유동적
      builder: (context) {
        return SingleChildScrollView( // [중요] 스크롤 추가
          child: Container(
            padding: EdgeInsets.only(
                top: 16,
                bottom: MediaQuery.of(context).padding.bottom + 16 // 하단 안전 영역 확보
            ),
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
    if (!_formKey.currentState!.validate()) return;
    if (_selectedPatientId == null && !_isEditing) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('환자를 선택해주세요.')));
      return;
    }
    if (_isLoading) return;

    setState(() => _isLoading = true);

    try {
      String title = _titleController.text;
      String content = _contentController.text;

      // DateTime에서 날짜(yyyy-MM-dd)와 시간(HH:mm) 포맷팅
      String startDateStr = DateFormat('yyyy-MM-dd').format(_startDate);
      String endDateStr = DateFormat('yyyy-MM-dd').format(_endDate);

      final Map<String, dynamic> scheduleData = {
        'title': title,
        'content': content,
        'scheduleType': _selectedScheduleType,
        'startDate': startDateStr, // 시작일
        'endDate': endDateStr,     // 종료일
        'isAllDay': _isAllDay,     // 종일 여부
        'startTime': _isAllDay ? null : _startTime, // 종일이면 시간 null 혹은 무시
        'endTime': _isAllDay ? null : _endTime,
        'isPublic': _isPublic,
        'repeatOption': _repeatOption,
        'isAlarmOn': _isAlarmOn,
        'alarmType': _isAlarmOn ? _alarmType : null,
        'alarmTime': _isAlarmOn ? _alarmTime : null,
      };

      if (!_isEditing) {
        scheduleData['patientId'] = _selectedPatientId;
        await _calendarService.createSchedule(scheduleData);
      } else {
        final int scheduleSeq = widget.existingSchedule!['schedule_seq'];
        await _calendarService.updateSchedule(scheduleSeq, scheduleData);
      }

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
    // 삭제 확인 다이얼로그 (필요 시 구현)
    // _deleteSchedule 호출
  }

  void _deleteSchedule() async {
    // 삭제 로직 (필요 시 구현)
  }

  // 날짜 선택 (isStart: 시작일인지 여부)
  Future<void> _pickDate(bool isStart) async {
    final DateTime initial = isStart ? _startDate : _endDate;
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );

    if (picked != null) {
      setState(() {
        if (isStart) {
          _startDate = picked;
          // 시작일이 종료일보다 늦으면 종료일도 시작일로 맞춤
          if (_startDate.isAfter(_endDate)) {
            _endDate = picked;
          }
        } else {
          _endDate = picked;
          // 종료일이 시작일보다 빠르면 시작일도 종료일로 맞춤
          if (_endDate.isBefore(_startDate)) {
            _startDate = picked;
          }
        }
      });
    }
  }

  // 2. 시간 선택 (30분 단위 바텀 시트) - 수정됨
  void _pickTime(bool isStart) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Container(
          height: 300, // 고정 높이 설정
          padding: const EdgeInsets.only(top: 20),
          child: Column(
            children: [
              Text(isStart ? "시작 시간" : "종료 시간", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
              const SizedBox(height: 10),
              Expanded( // [중요] 남은 공간을 리스트뷰가 모두 차지하도록 함
                child: ListView.builder(
                  itemCount: _timeOptions.length,
                  itemBuilder: (context, index) {
                    return ListTile(
                      title: Center(child: Text(_timeOptions[index])),
                      onTap: () {
                        setState(() {
                          if (isStart) {
                            _startTime = _timeOptions[index];
                          } else {
                            _endTime = _timeOptions[index];
                          }
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

  // 3. 반복 주기 선택 (바텀 시트) - 수정됨
  void _pickRepeat() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      isScrollControlled: true, // 내용에 따라 높이 유동적 조절
      builder: (context) {
        return SingleChildScrollView( // [중요] 스크롤 가능하게 변경
          child: Container(
            // SafeArea를 적용하여 하단 네비게이션 바와 겹치지 않게 함
            padding: EdgeInsets.only(
                top: 20,
                bottom: MediaQuery.of(context).padding.bottom + 20
            ),
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
                    });
                    Navigator.pop(context);
                  },
                )).toList(),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final patientViewModel = context.watch<PatientViewModel>();

    return Scaffold(
      backgroundColor: AppColors.white,
      body: SafeArea(
        child: Column(
          children: [
            PatientScreenHeader(), // 커스텀 헤더
            Expanded(
              child: Form(
                key: _formKey,
                child: ListView(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  children: [
                    // 1. 환자 선택 (신규 등록 시에만 표시)
                    if (!_isEditing) ...[
                      _buildSectionLabel('환자 선택'),
                      Container(
                        decoration: _boxDecoration(),
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButtonFormField<int>(
                            decoration: const InputDecoration(border: InputBorder.none, prefixIcon: Icon(Icons.person, color: Colors.grey)),
                            value: _selectedPatientId,
                            hint: const Text('일정을 등록할 환자를 선택하세요'),
                            items: patientViewModel.patients.map((patient) {
                              final int pId = patient['patient_id'] ?? patient['id'];
                              final String pName = patient['name'] ?? '이름 없음';
                              return DropdownMenuItem<int>(value: pId, child: Text(pName));
                            }).toList(),
                            onChanged: (value) => setState(() => _selectedPatientId = value),
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                    ],

                    // 2. 일정 유형
                    _buildSectionLabel('일정 유형'),
                    Container(
                      width: double.infinity,
                      decoration: _boxDecoration(),
                      padding: const EdgeInsets.all(16),
                      child: Wrap(
                        spacing: 8, runSpacing: 8,
                        children: _scheduleTypes.map((type) {
                          final isSelected = _selectedScheduleType == type;
                          return ChoiceChip(
                            label: Text(type, style: TextStyle(color: isSelected ? Colors.white : Colors.black87, fontWeight: isSelected ? FontWeight.bold : FontWeight.normal)),
                            selected: isSelected,
                            selectedColor: AppColors.mainBtn,
                            backgroundColor: Colors.grey[200],
                            onSelected: (bool selected) { if (selected) setState(() => _selectedScheduleType = type); },
                          );
                        }).toList(),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // 3. 일정 상세 (제목/내용)
                    _buildSectionLabel('일정 상세'),
                    Container(
                      decoration: _boxDecoration(),
                      child: Column(
                        children: [
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                            child: TextFormField(
                              controller: _titleController,
                              decoration: const InputDecoration(hintText: '제목을 입력하세요', border: InputBorder.none, labelText: '제목', floatingLabelBehavior: FloatingLabelBehavior.always),
                              validator: (v) => v!.isEmpty ? '제목을 입력해주세요' : null,
                            ),
                          ),
                          _buildDivider(),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                            child: TextFormField(
                              controller: _contentController,
                              decoration: const InputDecoration(hintText: '메모를 입력하세요 (선택 사항)', border: InputBorder.none, labelText: '내용', floatingLabelBehavior: FloatingLabelBehavior.always),
                              maxLines: 3, minLines: 1,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    // 4. 상세 설정 (공개/날짜/반복/알람)
                    _buildSectionLabel('상세 설정'),
                    Container(
                      width: double.infinity,
                      decoration: _boxDecoration(), // 기존 섹션들과 동일한 디자인 적용
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // [상단 영역] 날짜, 시간, 반복 설정 (여백 필요)
                          Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Column(
                              children: [
                                // (1) 날짜 선택 (시작 ~ 종료)
                                Row(
                                  children: [
                                    Expanded(
                                      child: _buildSelectionBox(
                                        label: "시작일",
                                        value: "${_startDate.year}.${_startDate.month}.${_startDate.day}",
                                        hint: "시작일",
                                        icon: Icons.calendar_today_outlined,
                                        onTap: () => _pickDate(true),
                                      ),
                                    ),
                                    const Padding(
                                      padding: EdgeInsets.symmetric(horizontal: 8.0, vertical: 24),
                                      child: Text("~", style: TextStyle(fontSize: 20, color: Colors.grey)),
                                    ),
                                    Expanded(
                                      child: _buildSelectionBox(
                                        label: "종료일",
                                        value: "${_endDate.year}.${_endDate.month}.${_endDate.day}",
                                        hint: "종료일",
                                        icon: Icons.calendar_today_outlined,
                                        onTap: () => _pickDate(false),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 16),

                                // (2) 종일 체크박스
                                Row(
                                  children: [
                                    SizedBox(
                                      height: 24,
                                      width: 24,
                                      child: Checkbox(
                                        value: _isAllDay,
                                        activeColor: AppColors.mainBtn,
                                        onChanged: (val) {
                                          setState(() {
                                            _isAllDay = val ?? false;
                                          });
                                        },
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    const Text("종일 설정", style: TextStyle(fontSize: 14)),
                                  ],
                                ),

                                // (3) 시간 선택 (종일 아닐 때만 노출)
                                if (!_isAllDay) ...[
                                  const SizedBox(height: 16),
                                  Row(
                                    children: [
                                      Expanded(
                                        child: _buildSelectionBox(
                                          label: "시작 시간",
                                          value: _startTime,
                                          hint: "00:00",
                                          icon: Icons.access_time,
                                          onTap: () => _pickTime(true),
                                        ),
                                      ),
                                      const Padding(
                                        padding: EdgeInsets.symmetric(horizontal: 8.0, vertical: 24),
                                        child: Text("~", style: TextStyle(fontSize: 20, color: Colors.grey)),
                                      ),
                                      Expanded(
                                        child: _buildSelectionBox(
                                          label: "종료 시간",
                                          value: _endTime,
                                          hint: "00:00",
                                          icon: Icons.access_time,
                                          onTap: () => _pickTime(false),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],

                                const SizedBox(height: 24),

                                // (4) 반복 설정
                                _buildSelectionBox(
                                  label: "반복",
                                  value: _repeatOption,
                                  hint: "반복 주기를 선택하세요",
                                  icon: Icons.repeat,
                                  onTap: _pickRepeat,
                                ),
                              ],
                            ),
                          ),

                          // 구분선 (상단 설정과 하단 토글 설정 분리)
                          _buildDivider(),

                          // (5) 공개 여부
                          SwitchListTile(
                            title: const Text('공개 여부', style: TextStyle(fontSize: 14)),
                            value: _isPublic,
                            activeColor: AppColors.mainBtn,
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                            onChanged: (val) => setState(() => _isPublic = val),
                            secondary: const Icon(Icons.visibility_outlined, color: Colors.grey),
                          ),

                          _buildDivider(),

                          // (6) 알람 설정
                          SwitchListTile(
                            title: const Text('알람 설정', style: TextStyle(fontSize: 14)),
                            value: _isAlarmOn,
                            activeColor: AppColors.mainBtn,
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                            onChanged: (val) => setState(() => _isAlarmOn = val),
                            secondary: const Icon(Icons.notifications_none, color: Colors.grey),
                          ),

                          // 알람 세부 옵션 (켜졌을 때만 표시)
                          if (_isAlarmOn) ...[
                            _buildDivider(),
                            ListTile(
                              contentPadding: const EdgeInsets.only(left: 56, right: 16),
                              title: const Text('알람 종류', style: TextStyle(fontSize: 14)),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(_alarmType, style: const TextStyle(color: AppColors.mainBtn, fontSize: 14)),
                                  const SizedBox(width: 4),
                                  const Icon(Icons.chevron_right, color: Colors.grey, size: 20),
                                ],
                              ),
                              onTap: () => _showSelectionModal('알람 종류 선택', _alarmTypes, _alarmType, (val) => setState(() => _alarmType = val)),
                            ),
                            _buildDivider(),
                            ListTile(
                              contentPadding: const EdgeInsets.only(left: 56, right: 16),
                              title: const Text('알람 시간', style: TextStyle(fontSize: 14)),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(_alarmTime, style: const TextStyle(color: AppColors.mainBtn, fontSize: 14)),
                                  const SizedBox(width: 4),
                                  const Icon(Icons.chevron_right, color: Colors.grey, size: 20),
                                ],
                              ),
                              onTap: () => _showSelectionModal('알람 시간 선택', _alarmTimeOptions, _alarmTime, (val) => setState(() => _alarmTime = val)),
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(height: 40),

                    // 저장 버튼
                    ElevatedButton(
                      onPressed: _saveSchedule,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.mainBtn,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        elevation: 0,
                      ),
                      child: _isLoading
                          ? const CircularProgressIndicator(color: Colors.white)
                          : Text(_isEditing ? '수정 완료' : '일정 등록', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    ),

                    // 삭제 버튼 (수정 모드일 때만)
                    if (_isEditing) ...[
                      const SizedBox(height: 12),
                      TextButton(
                          onPressed: _isLoading ? null : _showDeleteConfirmDialog,
                          style: TextButton.styleFrom(foregroundColor: Colors.red),
                          child: const Text('이 일정 삭제')
                      ),
                    ],
                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --- UI 헬퍼 메서드 ---
  Widget _buildSectionLabel(String label) {
    return Padding(
        padding: const EdgeInsets.only(left: 4, bottom: 8),
        child: Text(label, style: TextStyle(color: Colors.grey[600], fontSize: 13, fontWeight: FontWeight.w600))
    );
  }

  BoxDecoration _boxDecoration() {
    return BoxDecoration(
        color: AppColors.lightBackground,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 2))]
    );
  }

  Widget _buildDivider() {
    return const Divider(height: 1, thickness: 1, indent: 16, endIndent: 16, color: Color(0xFFF0F0F0));
  }

  // 공통 디자인의 선택 박스 위젯 (메서드로 분리)
  Widget _buildSelectionBox({
    required String label,
    required String value,
    required String hint,
    required VoidCallback onTap,
    required IconData icon,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)), // 라벨
        const SizedBox(height: 8),
        GestureDetector(
          onTap: onTap, // 클릭 시 실행될 함수
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey.shade400), // 테두리 색상
              borderRadius: BorderRadius.circular(8), // 둥근 모서리
              color: Colors.white, // 배경색
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  value.isEmpty ? hint : value,
                  style: TextStyle(
                    color: value.isEmpty ? Colors.grey : Colors.black,
                    fontSize: 16,
                  ),
                ),
                Icon(icon, color: Colors.grey),
              ],
            ),
          ),
        ),
      ],
    );
  }
}