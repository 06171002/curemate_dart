/// ✅ 캘린더 스케줄 상세 모델 (t_cure_calendar_schedule 테이블 대응)
class CureCalendarScheduleModel {
  final int cureScheduleSeq;
  final int cureCalendarSeq;
  final String? cureScheduleStartDttm;
  final String? cureScheduleEndDttm;
  final String? cureScheduleDayYn; // 종일 여부
  final String? cureScheduleTypeCmcd;
  final String? cureScheduleRepeatYn; // 반복 여부 (Y/N)
  final String? cureScheduleRepeat; // 반복 주기

  // 요일별 반복 여부 (이 필드들이 있어야 요일 필터링 가능)
  final String? cureScheduleMonYn;
  final String? cureScheduleTuesYn;
  final String? cureScheduleWednesYn;
  final String? cureScheduleThursYn;
  final String? cureScheduleFriYn;
  final String? cureScheduleSaturYn;
  final String? cureScheduleSunYn;

  final String? cureScheduleStopYn;
  final String? cureScheduleStopDttm;

  CureCalendarScheduleModel({
    required this.cureScheduleSeq,
    required this.cureCalendarSeq,
    this.cureScheduleStartDttm,
    this.cureScheduleEndDttm,
    this.cureScheduleDayYn,
    this.cureScheduleTypeCmcd,
    this.cureScheduleRepeatYn,
    this.cureScheduleRepeat,
    this.cureScheduleMonYn,
    this.cureScheduleTuesYn,
    this.cureScheduleWednesYn,
    this.cureScheduleThursYn,
    this.cureScheduleFriYn,
    this.cureScheduleSaturYn,
    this.cureScheduleSunYn,
    this.cureScheduleStopYn,
    this.cureScheduleStopDttm,
  });

  factory CureCalendarScheduleModel.fromJson(Map<String, dynamic> json) {
    return CureCalendarScheduleModel(
      cureScheduleSeq: json['cureScheduleSeq'] as int? ?? 0,
      cureCalendarSeq: json['cureCalendarSeq'] as int? ?? 0,
      cureScheduleStartDttm: json['cureScheduleStartDttm'] as String?,
      cureScheduleEndDttm: json['cureScheduleEndDttm'] as String?,
      cureScheduleDayYn: json['cureScheduleDayYn'] as String?,
      cureScheduleTypeCmcd: json['cureScheduleTypeCmcd'] as String?,
      cureScheduleRepeatYn: json['cureScheduleRepeatYn'] as String?,
      cureScheduleRepeat: json['cureScheduleRepeat'] as String?,

      // 요일별 컬럼 매핑
      cureScheduleMonYn: json['cureScheduleMonYn'] as String?,
      cureScheduleTuesYn: json['cureScheduleTuesYn'] as String?,
      cureScheduleWednesYn: json['cureScheduleWednesYn'] as String?,
      cureScheduleThursYn: json['cureScheduleThursYn'] as String?,
      cureScheduleFriYn: json['cureScheduleFriYn'] as String?,
      cureScheduleSaturYn: json['cureScheduleSaturYn'] as String?,
      cureScheduleSunYn: json['cureScheduleSunYn'] as String?,

      cureScheduleStopYn: json['cureScheduleStopYn'] as String?,
      cureScheduleStopDttm: json['cureScheduleStopDttm'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'cureScheduleSeq': cureScheduleSeq,
      'cureCalendarSeq': cureCalendarSeq,
      'cureScheduleStartDttm': cureScheduleStartDttm,
      'cureScheduleEndDttm': cureScheduleEndDttm,
      'cureScheduleDayYn': cureScheduleDayYn,
      'cureScheduleTypeCmcd': cureScheduleTypeCmcd,
      'cureScheduleRepeatYn': cureScheduleRepeatYn,
      'cureScheduleRepeat': cureScheduleRepeat,
      'cureScheduleMonYn': cureScheduleMonYn,
      'cureScheduleTuesYn': cureScheduleTuesYn,
      'cureScheduleWednesYn': cureScheduleWednesYn,
      'cureScheduleThursYn': cureScheduleThursYn,
      'cureScheduleFriYn': cureScheduleFriYn,
      'cureScheduleSaturYn': cureScheduleSaturYn,
      'cureScheduleSunYn': cureScheduleSunYn,
      'cureScheduleStopYn': cureScheduleStopYn,
      'cureScheduleStopDttm': cureScheduleStopDttm,
    };
  }
}