import 'package:curemate/app/theme/app_colors.dart';
import 'package:curemate/features/patient/viewmodel/patient_viewmodel.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

const Color textPrimary = AppColors.black;

class AddPatientPage extends StatefulWidget {
  const AddPatientPage({super.key});

  @override
  State<AddPatientPage> createState() => _AddPatientPageState();
}

class _AddPatientPageState extends State<AddPatientPage> {
  // 상태 변수들
  DateTime? _selectedDate;
  String? _selectedGender;
  String? _selectedDrinking;
  String? _selectedSmoking;
  String? _selectedRelationship;
  String? _selectedRh;
  String? _selectedBloodTypeABO;
  final TextEditingController _otherRelationshipController = TextEditingController();

  // 필드 데이터를 위한 컨트롤러
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _emergencyPhoneController = TextEditingController();
  final TextEditingController _heightController = TextEditingController();
  final TextEditingController _weightController = TextEditingController();
  final TextEditingController _allergyController = TextEditingController();
  final TextEditingController _memoController = TextEditingController();

  @override
  void dispose() {
    _otherRelationshipController.dispose();
    _nameController.dispose();
    _phoneController.dispose();
    _emergencyPhoneController.dispose();
    _heightController.dispose();
    _weightController.dispose();
    _allergyController.dispose();
    _memoController.dispose();
    super.dispose();
  }

  // 생년월일 DatePicker를 띄우는 함수
  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime.now(),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
      locale: const Locale('ko', 'KR'),
      builder: (context, child) {
        return Theme(
          data: ThemeData.light().copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppColors.activeColor,
              onPrimary: Colors.white,
              onSurface: AppColors.black,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  // 전화번호에 하이픈을 추가하는 함수
  String? _formatPhoneNumber(String? number) {
    if (number == null || number.isEmpty) {
      return null;
    }
    // 숫자만 남기고 모든 문자 제거
    final String cleanNumber = number.replaceAll(RegExp(r'[^0-9]'), '');
    if (cleanNumber.length == 11) {
      return '${cleanNumber.substring(0, 3)}-${cleanNumber.substring(3, 7)}-${cleanNumber.substring(7, 11)}';
    } else if (cleanNumber.length == 10) {
      return '${cleanNumber.substring(0, 3)}-${cleanNumber.substring(3, 6)}-${cleanNumber.substring(6, 10)}';
    }
    return cleanNumber; // 하이픈을 붙일 수 없는 경우 원본 반환
  }

  @override
  Widget build(BuildContext context) {
    return Container( // 1. SafeArea를 Container로 감쌉니다.
        color: AppColors.white, // 2. Container에 원하는 색상을 지정합니다.
        child: SafeArea(
            top: true,
            child: Scaffold(
            appBar: AppBar(
              backgroundColor: AppColors.white,
              elevation: 0,
              leading: IconButton(
                icon: const Icon(Icons.arrow_back_ios, color: AppColors.activeColor),
                onPressed: () {
                  Navigator.pop(context);
                },
              ),
              title: const Text(
                '환자 등록',
                style: TextStyle(
                  color: AppColors.black,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              centerTitle: true,
              actions: const [
                SizedBox(width: 48),
              ],
            ),
            body: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.only(top: 16.0, bottom: 32.0),
                child: Column(
                  children: [
                    _buildFormSection(),
                    const SizedBox(height: 24),
                    _buildSubmitButton(),
                  ],
                ),
              ),
            ),
            )
        )
    );
  }

  Widget _buildFormSection() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16.0),
      padding: const EdgeInsets.all(24.0),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16.0),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          LayoutBuilder(
            builder: (context, constraints) {
              if (constraints.maxWidth > 600) {
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: _buildTextField('이름', '이름을 입력하세요', isRequired: true, controller: _nameController),
                    ),
                    const SizedBox(width: 24),
                    Expanded(
                      child: _buildRelationshipDropdown(),
                    ),
                  ],
                );
              } else {
                return Column(
                  children: [
                    _buildTextField('이름', '이름을 입력하세요', isRequired: true, controller: _nameController),
                    const SizedBox(height: 24),
                    _buildRelationshipDropdown(),
                  ],
                );
              }
            },
          ),
          if (_selectedRelationship == '기타') ...[
            const SizedBox(height: 24),
            _buildTextField('관계(기타)', '관계를 입력하세요', controller: _otherRelationshipController),
          ],
          const SizedBox(height: 24),
          _buildTextField('연락처', '번호만 입력해주세요', inputType: TextInputType.phone, controller: _phoneController, isNumberOnly: true),
          const SizedBox(height: 24),
          _buildTextField('긴급 연락처', '번호만 입력해주세요', inputType: TextInputType.phone, controller: _emergencyPhoneController, isNumberOnly: true),
          const SizedBox(height: 24),
          // 날짜 선택기 필드
          _buildDateField(context, '생년월일', isRequired: true),
          const SizedBox(height: 24),
          _buildRadioGroup('성별', ['남성', '여성'], _selectedGender, (String? value) {
            setState(() {
              _selectedGender = value;
            });
          }, isRequired: true),
          const SizedBox(height: 24),
          LayoutBuilder(
            builder: (context, constraints) {
              if (constraints.maxWidth > 600) {
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(child: _buildTextField('신장 (cm)', '예) 175', inputType: TextInputType.number, controller: _heightController)),
                    const SizedBox(width: 24),
                    Expanded(child: _buildTextField('체중 (kg)', '예) 70', inputType: TextInputType.number, controller: _weightController)),
                  ],
                );
              } else {
                return Column(
                  children: [
                    _buildTextField('신장 (cm)', '예) 175', inputType: TextInputType.number, controller: _heightController),
                    const SizedBox(height: 24),
                    _buildTextField('체중 (kg)', '예) 70', inputType: TextInputType.number, controller: _weightController),
                  ],
                );
              }
            },
          ),
          const SizedBox(height: 24),
          _buildBloodTypeSelection(),
          const SizedBox(height: 24),
          LayoutBuilder(
            builder: (context, constraints) {
              if (constraints.maxWidth > 600) {
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(child: _buildRadioGroup('음주 여부', ['예', '아니요'], _selectedDrinking, (String? value) {
                      setState(() {
                        _selectedDrinking = value;
                      });
                    })),
                    const SizedBox(width: 24),
                    Expanded(child: _buildRadioGroup('흡연 여부', ['예', '아니요'], _selectedSmoking, (String? value) {
                      setState(() {
                        _selectedSmoking = value;
                      });
                    })),
                  ],
                );
              } else {
                return Column(
                  children: [
                    _buildRadioGroup('음주 여부', ['예', '아니요'], _selectedDrinking, (String? value) {
                      setState(() {
                        _selectedDrinking = value;
                      });
                    }),
                    const SizedBox(height: 24),
                    _buildRadioGroup('흡연 여부', ['예', '아니요'], _selectedSmoking, (String? value) {
                      setState(() {
                        _selectedSmoking = value;
                      });
                    }),
                  ],
                );
              }
            },
          ),
          const SizedBox(height: 24),
          _buildTextField('알러지', '알러지 정보를 입력하세요', controller: _allergyController),
          const SizedBox(height: 24),
          _buildMemoField('메모', '환자에 대한 메모를 남겨주세요', controller: _memoController),
        ],
      ),
    );
  }

  Widget _buildRelationshipDropdown() {
    final List<String> relationships = ['부', '모', '본인', '형제/자매', '배우자', '자녀', '기타'];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildLabel('관계'),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          value: _selectedRelationship,
          isExpanded: true,
          decoration: InputDecoration(
            filled: true,
            fillColor: AppColors.white,
            contentPadding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12.0),
              borderSide: const BorderSide(color: AppColors.inputBorder, width: 1.0),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12.0),
              borderSide: const BorderSide(color: AppColors.inputBorder, width: 1.0),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12.0),
              borderSide: const BorderSide(color: AppColors.activeColor, width: 2.0),
            ),
          ),
          hint: Text(
            '관계를 선택하세요',
            style: TextStyle(color: AppColors.skyBlue.withOpacity(0.6), fontWeight: FontWeight.normal),
          ),
          items: relationships.map((String value) {
            return DropdownMenuItem<String>(
              value: value,
              child: Text(value, style: const TextStyle(color: AppColors.black, fontWeight: FontWeight.normal)),
            );
          }).toList(),
          onChanged: (String? newValue) {
            setState(() {
              _selectedRelationship = newValue;
              if (newValue != '기타') {
                _otherRelationshipController.clear();
              }
            });
          },
        ),
      ],
    );
  }

  Widget _buildTextField(String label, String placeholder, {bool isRequired = false, TextInputType inputType = TextInputType.text, TextEditingController? controller, bool isNumberOnly = false}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildLabel(label, isRequired),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          keyboardType: inputType,
          inputFormatters: isNumberOnly
              ? [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(11),
                ]
              : null,
          decoration: InputDecoration(
            hintText: placeholder,
            hintStyle: TextStyle(color: AppColors.skyBlue.withOpacity(0.6)),
            filled: true,
            fillColor: AppColors.white,
            contentPadding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12.0),
              borderSide: const BorderSide(color: AppColors.grey, width: 1.0),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12.0),
              borderSide: const BorderSide(color: AppColors.inputBorder, width: 1.0),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12.0),
              borderSide: const BorderSide(color: AppColors.activeColor, width: 2.0),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDateField(BuildContext context, String label, {bool isRequired = false}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildLabel(label, isRequired),
        const SizedBox(height: 8),
        TextFormField(
          controller: TextEditingController(
            text: _selectedDate == null
                ? ''
                : DateFormat('yyyy.MM.dd').format(_selectedDate!),
          ),
          readOnly: true,
          onTap: () => _selectDate(context),
          decoration: InputDecoration(
            hintText: '생년월일을 선택하세요',
            hintStyle: TextStyle(color: AppColors.skyBlue.withOpacity(0.6)),
            filled: true,
            fillColor: AppColors.white,
            contentPadding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12.0),
              borderSide: const BorderSide(color: AppColors.grey, width: 1.0),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12.0),
              borderSide: const BorderSide(color: AppColors.inputBorder, width: 1.0),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12.0),
              borderSide: const BorderSide(color: AppColors.activeColor, width: 2.0),
            ),
            suffixIcon: Icon(Icons.calendar_today, color: AppColors.skyBlue.withOpacity(0.6)),
          ),
        ),
      ],
    );
  }

  Widget _buildMemoField(String label, String placeholder, {TextEditingController? controller}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildLabel(label),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          maxLines: 4,
          minLines: 2,
          decoration: InputDecoration(
            hintText: placeholder,
            hintStyle: TextStyle(color: AppColors.skyBlue.withOpacity(0.6)),
            filled: true,
            fillColor: AppColors.white,
            contentPadding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12.0),
              borderSide: const BorderSide(color: AppColors.inputBorder, width: 1.0),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12.0),
              borderSide: const BorderSide(color: AppColors.inputBorder, width: 1.0),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12.0),
              borderSide: const BorderSide(color: AppColors.activeColor, width: 2.0),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildRadioGroup(String label, List<String> options, String? groupValue, Function(String?) onChanged, {bool isRequired = false}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildLabel(label, isRequired),
        const SizedBox(height: 8),
        Row(
          children: options.map((option) {
            return Row(
              children: [
                Radio<String>(
                  value: option,
                  groupValue: groupValue,
                  onChanged: onChanged,
                  activeColor: AppColors.activeColor,
                  fillColor: MaterialStateProperty.resolveWith<Color>((Set<MaterialState> states) {
                    if (states.contains(MaterialState.selected)) {
                      return AppColors.activeColor;
                    }
                    return Colors.grey;
                  }),
                ),
                Text(option, style: const TextStyle(color: AppColors.black)),
                const SizedBox(width: 16),
              ],
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildLabel(String text, [bool isRequired = false]) {
    return RichText(
      text: TextSpan(
        style: const TextStyle(
          fontSize: 14,
          color: AppColors.black,
          fontFamily: 'Noto Sans KR',
        ),
        children: [
          TextSpan(text: text),
          if (isRequired)
            const TextSpan(
              text: ' *',
              style: TextStyle(color: AppColors.error),
            ),
        ],
      ),
    );
  }

  Widget _buildBloodTypeSelection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildLabel('혈액형'),
        const SizedBox(height: 8),
        Row(
          children: [
            _buildToggleButton('Rh+', _selectedRh, (value) {
              setState(() {
                _selectedRh = value;
              });
            }),
            const SizedBox(width: 8),
            _buildToggleButton('Rh-', _selectedRh, (value) {
              setState(() {
                _selectedRh = value;
              });
            }),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            _buildToggleButton('A', _selectedBloodTypeABO, (value) {
              setState(() {
                _selectedBloodTypeABO = value;
              });
            }),
            const SizedBox(width: 8),
            _buildToggleButton('B', _selectedBloodTypeABO, (value) {
              setState(() {
                _selectedBloodTypeABO = value;
              });
            }),
            const SizedBox(width: 8),
            _buildToggleButton('O', _selectedBloodTypeABO, (value) {
              setState(() {
                _selectedBloodTypeABO = value;
              });
            }),
            const SizedBox(width: 8),
            _buildToggleButton('AB', _selectedBloodTypeABO, (value) {
              setState(() {
                _selectedBloodTypeABO = value;
              });
            }),
          ],
        ),
      ],
    );
  }

  Widget _buildToggleButton(String label, String? selectedValue, Function(String) onPressed) {
    final isSelected = selectedValue == label;
    return GestureDetector(
      onTap: () => onPressed(label),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.activeColor : AppColors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? AppColors.activeColor : AppColors.inputBorder,
            width: 1.5,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? AppColors.white : AppColors.black,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Widget _buildSubmitButton() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: SizedBox(
        width: double.infinity,
        child: Consumer<PatientViewModel>(
          builder: (context, viewModel, child) {
            return ElevatedButton(
              onPressed: viewModel.isLoading
                  ? null
                  : () async {
                      // 1. 필수 필드 검증 - '기타' 관계를 선택했을 때 관계(기타) 필드가 비어있는지 확인하는 로직 추가
                      if (_nameController.text.isEmpty ||
                          _selectedDate == null ||
                          _selectedGender == null ||
                          (_selectedRelationship == '기타' && _otherRelationshipController.text.isEmpty)) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('필수 항목(*)을 모두 입력해주세요.')),
                        );
                        return; // 함수 종료
                      }
                      
                      // 관계(기타) 필드를 포함한 최종 관계 값 설정
                      final String? finalRelationship = _selectedRelationship == '기타'
                          ? _otherRelationshipController.text.isNotEmpty
                              ? _otherRelationshipController.text
                              : null
                          : _selectedRelationship;

                      // 2. 환자 데이터 맵 생성 (DB 컬럼명과 일치하도록 수정)
                      // 전화번호를 하이픈이 포함된 형식으로 변환하여 저장
                      final String? formattedPhone = _formatPhoneNumber(_phoneController.text);
                      final String? formattedEmergencyPhone = _formatPhoneNumber(_emergencyPhoneController.text);

                      final Map<String, dynamic> patientData = {
                        'NAME': _nameController.text,
                        'PHONE': formattedPhone,
                        'EMERGENCY_CONTACT': formattedEmergencyPhone,
                        'BIRTH': DateFormat('yyyy-MM-dd').format(_selectedDate!),
                        'GENDER': _selectedGender,
                        
                        'RELATIONSHIP': finalRelationship, 
                        'HEIGHT': _heightController.text.isNotEmpty ? double.tryParse(_heightController.text) : null,
                        'WEIGHT': _weightController.text.isNotEmpty ? double.tryParse(_weightController.text) : null,
                        // 혈액형을 B+ 또는 A- 형식으로 올바르게 저장하도록 수정
                        'BLOOD_TYPE': (_selectedBloodTypeABO != null && _selectedRh != null)
                            ? '$_selectedBloodTypeABO${_selectedRh!.substring(2)}'
                            : null,
                        'DRINKING_YN': _selectedDrinking == '예',
                        'SMOKING_YN': _selectedSmoking == '예',
                        'ALLERGIES': _allergyController.text.isNotEmpty ? _allergyController.text : null,
                        'MEMO': _memoController.text.isNotEmpty ? _memoController.text : null,
                      };

                      // 3. ViewModel의 함수 호출
                      await viewModel.createPatient(patientData);

                      // 4. 결과에 따른 후속 처리
                      if (viewModel.errorMessage != null) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text(viewModel.errorMessage!)),
                        );
                        viewModel.clearError();
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('환자 등록에 성공했습니다!')),
                        );
                        Navigator.pop(context); // 성공 시 이전 화면으로 돌아가기
                      }
                    },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.activeColor,
                
                foregroundColor: AppColors.white,
                padding: const EdgeInsets.symmetric(vertical: 16.0),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12.0),
                ),
              ),
              child: viewModel.isLoading
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Text(
                      '등록하기',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
            );
          },
        ),
      ),
    );
  }
}
