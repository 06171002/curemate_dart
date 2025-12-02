import 'package:curemate/features/calendar/model/calendar_schedule_model.dart';
import 'package:json_annotation/json_annotation.dart';

// 만약 build_runner를 사용하지 않는다면 아래 part 구문을 지우고
// 직접 fromJson/toJson을 구현하거나, 아래에 제가 작성한 수동 코드를 사용하세요.
// 여기서는 별도 라이브러리 없이 바로 쓸 수 있는 버전으로 제공합니다.

/// ✅ 캘린더 메인 모델 (t_cure_calendar 테이블 대응)
class CureCalendarModel {
  final int cureCalendarSeq;
  final int custSeq;
  final int cureSeq;
  final int? patientSeq; // XML insert문에 존재하므로 추가
  final String cureCalendarTypeCmcd;
  final String? cureCalendarTypeCmnm; // 공통코드명 (XML select절에 있음)
  final String cureCalendarNm;
  final String? cureCalendarDesc;
  final String releaseYn;

  // XML ResultMap의 <association property="schedule" ... /> 대응
  final CureCalendarScheduleModel? schedule;

  CureCalendarModel({
    required this.cureCalendarSeq,
    required this.custSeq,
    required this.cureSeq,
    this.patientSeq,
    required this.cureCalendarTypeCmcd,
    this.cureCalendarTypeCmnm,
    required this.cureCalendarNm,
    this.cureCalendarDesc,
    required this.releaseYn,
    this.schedule,
  });

  factory CureCalendarModel.fromJson(Map<String, dynamic> json) {
    return CureCalendarModel(
      cureCalendarSeq: json['cureCalendarSeq'] as int? ?? 0,
      custSeq: json['custSeq'] as int? ?? 0,
      cureSeq: json['cureSeq'] as int? ?? 0,
      patientSeq: json['patientSeq'] as int?,
      cureCalendarTypeCmcd: json['cureCalendarTypeCmcd'] as String? ?? '',
      cureCalendarTypeCmnm: json['cureCalendarTypeCmnm'] as String?,
      cureCalendarNm: json['cureCalendarNm'] as String? ?? '',
      cureCalendarDesc: json['cureCalendarDesc'] as String?,
      releaseYn: json['releaseYn'] as String? ?? 'N',
      schedule: json['schedule'] != null
          ? CureCalendarScheduleModel.fromJson(json['schedule'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'cureCalendarSeq': cureCalendarSeq,
      'custSeq': custSeq,
      'cureSeq': cureSeq,
      'patientSeq': patientSeq,
      'cureCalendarTypeCmcd': cureCalendarTypeCmcd,
      'cureCalendarTypeCmnm': cureCalendarTypeCmnm,
      'cureCalendarNm': cureCalendarNm,
      'cureCalendarDesc': cureCalendarDesc,
      'releaseYn': releaseYn,
      'schedule': schedule?.toJson(),
    };
  }
}

