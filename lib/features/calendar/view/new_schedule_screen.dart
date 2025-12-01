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
  final List<String> _scheduleTypes = ['진료', '검사', '상담', '재활', '기타'];

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
  String _repeatOption = '반복 없음';
  final List<String> _repeatOptions = ['반복 없음', '매일', '매주', '매월'];

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
      if (mounted) {
        final header = Provider.of<HeaderProvider>(context, listen: false);
        header.setTitle(_isEditing ? '일정 수정' : '새 일정 추가');
        header.setShowBackButton(true);
        header.setSettingButton(false);
      }
    });

    // 초기 데이터 설정
    if (_isEditing) {
      _initEditData();
    } else {
      // 새 일정: 이전 화면에서 선택한 날짜 + 현재 시간 조합
      final now = DateTime.now();
      _selectedDateTime = DateTime(
        widget.selectedDateFromPreviousScreen.year,
        widget.selectedDateFromPreviousScreen.month,
        widget.selectedDateFromPreviousScreen.day,
        now.hour,
        now.minute,
      );
    }
  }

  void _initEditData() {
    final schedule = widget.existingSchedule!;
    _titleController.text = schedule['title'] ?? '';
    _contentController.text = schedule['content'] ?? '';
    _selectedScheduleType = schedule['schedule_type'] ?? '진료';

    // DB 데이터(문자열)를 DateTime으로 파싱
    try {
      final datePart = DateTime.parse(schedule['schedule_date']);
      final timeParts = (schedule['schedule_time'] as String).split(':');
      _selectedDateTime = DateTime(
        datePart.year,
        datePart.month,
        datePart.day,
        int.parse(timeParts[0]),
        int.parse(timeParts[1]),
      );
    } catch (e) {
      _selectedDateTime = DateTime.now(); // 파싱 실패 시 현재 시간
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

  // --- 하단 모달 (알람 종류/시간 선택용) ---
  void _showSelectionModal(String title, List<String> options, String currentVal, Function(String) onSelected) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.all(16.0),
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
      String date = DateFormat('yyyy-MM-dd').format(_selectedDateTime);
      String time = DateFormat('HH:mm').format(_selectedDateTime);

      final Map<String, dynamic> scheduleData = {
        'title': title,
        'content': content,
        'scheduleType': _selectedScheduleType,
        'scheduleDate': date,
        'scheduleTime': time,
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
                      decoration: _boxDecoration(),
                      child: Column(
                        children: [
                          // 공개 여부
                          SwitchListTile(
                            title: const Text('공개 여부'),
                            value: _isPublic,
                            activeColor: AppColors.mainBtn,
                            onChanged: (val) => setState(() => _isPublic = val),
                            secondary: const Icon(Icons.visibility, color: Colors.grey),
                          ),
                          _buildDivider(),

                          // --- 날짜 및 시간 (인라인 피커) ---
                          ListTile(
                            leading: const Icon(Icons.calendar_today, color: Colors.grey),
                            title: const Text('날짜 및 시간'),
                            trailing: Text(
                              DateFormat('yyyy.MM.dd (E) HH:mm', 'ko_KR').format(_selectedDateTime),
                              style: const TextStyle(color: AppColors.mainBtn, fontWeight: FontWeight.bold),
                            ),
                            onTap: () {
                              setState(() {
                                _isDateExpanded = !_isDateExpanded;
                                if (_isDateExpanded) _isRepeatExpanded = false; // 다른 피커 닫기
                              });
                            },
                          ),
                          if (_isDateExpanded)
                            SizedBox(
                              height: 200,
                              child: CupertinoDatePicker(
                                mode: CupertinoDatePickerMode.dateAndTime,
                                initialDateTime: _selectedDateTime,
                                onDateTimeChanged: (DateTime newDateTime) {
                                  setState(() => _selectedDateTime = newDateTime);
                                },
                                use24hFormat: true,
                              ),
                            ),

                          _buildDivider(),

                          // --- 반복 주기 (인라인 리스트) ---
                          ListTile(
                            leading: const Icon(Icons.repeat, color: Colors.grey),
                            title: const Text('반복 주기'),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(_repeatOption, style: const TextStyle(color: Colors.grey)),
                                const SizedBox(width: 4),
                                Icon(_isRepeatExpanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down, color: Colors.grey),
                              ],
                            ),
                            onTap: () {
                              setState(() {
                                _isRepeatExpanded = !_isRepeatExpanded;
                                if (_isRepeatExpanded) _isDateExpanded = false;
                              });
                            },
                          ),
                          if (_isRepeatExpanded)
                            Container(
                              color: Colors.grey[50], // 하위 메뉴 배경색 구분
                              child: Column(
                                children: _repeatOptions.map((option) {
                                  return RadioListTile<String>(
                                    title: Text(option, style: const TextStyle(fontSize: 14)),
                                    value: option,
                                    groupValue: _repeatOption,
                                    activeColor: AppColors.mainBtn,
                                    dense: true,
                                    onChanged: (val) {
                                      setState(() {
                                        _repeatOption = val!;
                                        // _isRepeatExpanded = false; // 선택 후 닫으려면 주석 해제
                                      });
                                    },
                                  );
                                }).toList(),
                              ),
                            ),

                          _buildDivider(),

                          // --- 알람 설정 (토글) ---
                          SwitchListTile(
                            title: const Text('알람 설정'),
                            value: _isAlarmOn,
                            activeColor: AppColors.mainBtn,
                            onChanged: (val) => setState(() => _isAlarmOn = val),
                            secondary: const Icon(Icons.notifications_none, color: Colors.grey),
                          ),

                          // 알람 켜졌을 때만 보이는 하위 옵션
                          if (_isAlarmOn) ...[
                            _buildDivider(),
                            // 알람 종류
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
                            // 알람 시간
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
}