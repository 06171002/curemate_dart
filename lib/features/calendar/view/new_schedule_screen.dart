// lib/features/calendar/view/new_schedule_screen.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:curemate/features/widgets/common/header_provider.dart';
import 'package:curemate/features/widgets/common/widgets.dart';
import 'package:curemate/services/calendar_service.dart';
import '../../../app/theme/app_colors.dart';

class NewScheduleScreen extends StatefulWidget {

  final DateTime selectedDateFromPreviousScreen; // 선택된 날짜를 받을 파라미터
  final int patientId;
  final Map<String, dynamic>? existingSchedule;  // ★ 수정 모드를 위한 데이터 (Nullable)

  const NewScheduleScreen({
    super.key,
    required this.selectedDateFromPreviousScreen, // 생성자에서 날짜를 받도록 함
    required this.patientId,
    this.existingSchedule, // ★ 생성자에 추가
  });

  @override
  State<NewScheduleScreen> createState() => _NewScheduleScreenState();
}

class _NewScheduleScreenState extends State<NewScheduleScreen> {
  String? _selectedScheduleType; // 선택된 일정 종류를 저장할 변수
  final List<String> _scheduleTypes = ['진료', '검사', '상담', '기타']; // 선택 옵션 리스트

  final _formKey = GlobalKey<FormState>();
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _contentController = TextEditingController();
  DateTime? _selectedDate;
  TimeOfDay? _selectedTime;

  bool _isLoading = false;

  final CalendarService _calendarService = CalendarService();

  // ★ 수정 모드인지 확인하는 변수
  bool get _isEditing => widget.existingSchedule != null;

  @override
  void initState() {
    super.initState();

    if (_isEditing) {
      // --- 수정 모드일 때 데이터 채우기 ---
      final schedule = widget.existingSchedule!;
      _titleController.text = schedule['title'] ?? '';
      _contentController.text = schedule['content'] ?? '';
      _selectedScheduleType = schedule['schedule_type'];

      // 날짜와 시간 파싱
      _selectedDate = DateTime.parse(schedule['schedule_date']);
      final timeParts = (schedule['schedule_time'] as String).split(':');
      _selectedTime = TimeOfDay(
        hour: int.parse(timeParts[0]),
        minute: int.parse(timeParts[1]),
      );
    } else {
      _selectedDate = widget.selectedDateFromPreviousScreen;
      _selectedTime = TimeOfDay.now();
    }

    print('NewScheduleScreen에 전달된 patientId: ${widget.patientId}');

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        final header = Provider.of<HeaderProvider>(context, listen: false);
        header.setTitle(_isEditing ? '일정 수정' : '새 일정 추가');
        header.setShowBackButton(true);
        header.setSettingButton(false);
      }
    });
  }

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  Future<void> _pickDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  Future<void> _pickTime(BuildContext context) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime ?? TimeOfDay.now(),
    );
    if (picked != null && picked != _selectedTime) {
      setState(() {
        _selectedTime = picked;
      });
    }
  }

  void _saveSchedule() async{
    if (!_formKey.currentState!.validate()) {
      return;
    }

    // 이미 로딩 중이면 중복 실행 방지
    if (_isLoading) {
      return;
    }

    setState(() {
      _isLoading = true; // 로딩 시작
    });

    try {
      // API로 보낼 데이터 준비
      String title = _titleController.text;
      String content = _contentController.text;
      String scheduleType = _selectedScheduleType!;
      String date = DateFormat('yyyy-MM-dd').format(_selectedDate!);
      String time = '${_selectedTime!.hour.toString().padLeft(2, '0')}:${_selectedTime!.minute.toString().padLeft(2, '0')}';

      if(_isEditing) {
        final int scheduleSeq = widget.existingSchedule!['schedule_seq'];

        // 2. 서비스 함수에 ID와 body 데이터를 분리하여 전달합니다.
        final response = await _calendarService.updateSchedule(
          scheduleSeq, // URL 파라미터로 전달될 ID
          {
            // req.body로 전달될 데이터 맵
            'title': title,
            'content': content,
            'scheduleType': scheduleType,
            'scheduleDate': date,
            'scheduleTime': time,
          },
        );

      } else {
        // --- 여기서 API 호출 ---
        final response = await _calendarService.createSchedule({
          'patientId': widget.patientId,
          'title': title,
          'content': content,
          'scheduleType': scheduleType,
          'scheduleDate': date, // 날짜 전달
          'scheduleTime': time, // 시간 전달
        });

        print('일정 저장 성공 (API 호출 완료):');
        print('환자 ID: ${widget.patientId}');
        print('제목: $title');
        print('종류: $scheduleType');
        print('설명: $content');
        print('날짜: $date');
        print('시간: $time');
      }

      // UI가 마운트된 상태인지 확인 후 스낵바 표시 및 화면 전환
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('일정이 성공적으로 ${ _isEditing ? '수정' : '저장' }되었습니다.')),
        );
        // 저장 성공 후 이전 화면으로 돌아가기
        Navigator.pop(context, true);
      }

    } catch (e) {
      // API 호출 실패 시 에러 처리
      print('일정 저장 실패: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('일정 저장에 실패했습니다: $e')),
        );
      }
    } finally {
      // API 호출 성공/실패 여부와 관계 없이 로딩 상태 해제
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _showDeleteConfirmDialog() async {
    // 사용자가 정말로 삭제할 것인지 확인하는 대화 상자를 표시합니다.
    return showDialog<void>(
      context: context,
      barrierDismissible: false, // 대화 상자 바깥을 탭해도 닫히지 않음
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('일정 삭제'),
          content: const SingleChildScrollView(
            child: ListBody(
              children: <Widget>[
                Text('정말로 이 일정을 삭제하시겠습니까?'),
                Text('삭제된 데이터는 복구할 수 없습니다.'),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('취소'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              style: TextButton.styleFrom(
                  foregroundColor: Colors.red), // 삭제 버튼 텍스트 색상
              child: const Text('삭제'),
              onPressed: () {
                Navigator.of(context).pop(); // 대화 상자 닫기
                _deleteSchedule(); // 삭제 함수 호출
              },
            ),
          ],
        );
      },
    );
  }

  void _deleteSchedule() async {
    // 수정 모드가 아니거나, 기존 스케줄 데이터가 없으면 실행하지 않음
    if (!_isEditing || widget.existingSchedule == null) return;

    setState(() {
      _isLoading = true; // 로딩 시작
    });

    try {
      // 삭제할 스케줄의 고유 ID 가져오기
      final int scheduleSeq = widget.existingSchedule!['schedule_seq'];
      // 서비스의 deleteSchedule 함수 호출
      await _calendarService.deleteSchedule(scheduleSeq);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('일정이 성공적으로 삭제되었습니다.')),
        );
        // 삭제 성공 후 이전 화면으로 돌아가기 (true를 전달하여 이전 화면 갱신 유도)
        Navigator.pop(context, true);
      }
    } catch (e) {
      print('일정 삭제 실패: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('일정 삭제에 실패했습니다: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false; // 로딩 종료
        });
      }
    }
  }


  @override
  Widget build(BuildContext context) {

    return Container(
      color: AppColors.white,
      child: SafeArea(
        top: true, // top에 SafeArea 적용
        child: Scaffold(
          resizeToAvoidBottomInset: false,
          body: Column(
            children: [
              // --- Header ---
              PatientScreenHeader(), // Column의 첫 번째 자식으로 헤더 배치
              // --- 나머지 내용 (스크롤 가능 영역) ---
              Expanded(
                child: Container(
                  padding: const EdgeInsets.only(left: 16.0, right:16.0, top: 8.0), // 상단과 좌우 여백
                  child: Container(
                    decoration: BoxDecoration(
                      color: AppColors.white,
                      borderRadius: BorderRadius.circular(16.0),
                    ),
                    child: Form(
                      key: _formKey,
                      child: ListView(
                        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0), // ListView 자체에 패딩 적용 (상단 패딩 조절)
                        children: <Widget>[
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  _selectedDate == null
                                      ? '날짜 선택'
                                      : '날짜: ${DateFormat('yyyy년 MM월 dd일').format(_selectedDate!)}',
                                  style: const TextStyle(fontSize: 16),
                                ),
                              ),
                              TextButton(
                                onPressed: () => _pickDate(context),
                                child: const Text('날짜 변경'),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  _selectedTime == null
                                      ? '시간 선택'
                                      : '시간: ${_selectedTime!.format(context)}',
                                  style: const TextStyle(fontSize: 16),
                                ),
                              ),
                              TextButton(
                                onPressed: () => _pickTime(context),
                                child: const Text('시간 변경'),
                              ),
                            ],
                          ),
                          const SizedBox(height: 20), // 위젯 간 간격 조정
                          DropdownButtonFormField<String>(
                            decoration: const InputDecoration(
                              labelText: '일정 종류',
                              border: OutlineInputBorder(),
                            ),
                            value: _selectedScheduleType, // 현재 선택된 값
                            hint: const Text('일정 종류를 선택하세요'), // 아무것도 선택되지 않았을 때 표시될 텍스트
                            isExpanded: true, // 드롭다운 버튼을 가로로 확장
                            items: _scheduleTypes.map((String value) {
                              return DropdownMenuItem<String>(
                                value: value,
                                child: Text(value),
                              );
                            }).toList(),
                            onChanged: (String? newValue) {
                              setState(() {
                                _selectedScheduleType = newValue;
                              });
                            },
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return '일정 종류를 선택해주세요.';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 20),
                          TextFormField(
                            controller: _titleController,
                            decoration: const InputDecoration(
                              labelText: '제목',
                              border: OutlineInputBorder(),
                              hintText: '일정 제목을 입력하세요',
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return '제목을 입력해주세요.';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 20),
                          TextFormField(
                            controller: _contentController,
                            decoration: const InputDecoration(
                              labelText: '내용 (선택 사항)',
                              border: OutlineInputBorder(),
                              hintText: '일정에 대한 설명을 입력하세요',
                              alignLabelWithHint: true,
                            ),
                            maxLines: 5,
                            keyboardType: TextInputType.multiline,
                          ),
                          const SizedBox(height: 30),
                          ElevatedButton(
                            onPressed: _saveSchedule,
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 16.0),
                            ),
                            child: _isLoading
                                ? const CircularProgressIndicator()
                                : Text(
                              _isEditing ? '수정하기' : '저장하기', // 모드에 따라 버튼 텍스트 변경
                              style: const TextStyle(fontSize: 16),
                            ),
                          ),
                          if (_isEditing) ...[
                            const SizedBox(height: 10), // 버튼 사이의 간격
                            ElevatedButton(
                              onPressed: _isLoading ? null : _showDeleteConfirmDialog, // 로딩 중 비활성화
                              style: ElevatedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(vertical: 16.0),
                                backgroundColor: AppColors.activeBtn, // 삭제 버튼은 위험을 나타내는 붉은색으로 지정
                                foregroundColor: AppColors.error,
                              ),
                              child: const Text(
                                '삭제하기',
                                style: TextStyle(fontSize: 16),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  )
                )
              ),
            ],
          )
        ),
      )
    );
  }
}
