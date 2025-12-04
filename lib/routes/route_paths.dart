// lib/routes/route_paths.dart

class RoutePaths {
  // Private constructor
  RoutePaths._();

  // Auth
  static const String splash = '/';
  static const String permission = '/permission';
  static const String login = '/login';
  static const String termsAgreement = '/terms_agreement';
  static const String termsDetail = '/terms_detail';

  // Main
  static const String test = '/test';
  static const String main = '/main';
  static const String home = '/home';
  static const String profile = '/profile';
  static const String settings = '/settings';
  static const String profileEdit = '/profile/edit';

  // Profile 상세 (동적 경로)
  static String profileDetail(int userId) => '/profile/$userId';

  // 쿼리 파라미터 헬퍼
  static String homeWithTab(int tabIndex) => '/home?tab=$tabIndex';

  // 약관 상세 헬퍼
  static String termsDetailWithSeq(int seq) => '/terms_detail?seq=$seq';

  // CureRoom 홈 
  static const String cureRoomPatientProfile = '/cure_room/patient_profile';
  // static const String cureRoomRecordingList  = '/cure_room/recordings';   예시들입니다.
  // static const String cureRoomProudDiary     = '/cure_room/proud_diary';     
  // static const String cureRoomMedicalHistory = '/cure_room/medical_history';
  static const String cureRoomAddPatient = '/cure_room/add_patient'; //환자 등록
  static const String addCureRoom = '/cure_room/add'; // 큐어룸 생성 화면

  //병력관리
  static const String cureRoomMedicalHistory = '/cure-room/medical-history';
  //병력 수정추가
   static const String cureRoomMedicalHistoryDetail = '/cure-room/medical-history/detail';
  //복용약관리
  static const String cureRoomMedications    = '/cure-room/medications';
  //복용약 수정추가
  static const String cureRoomMedicationDetail = '/cure-room/medications/detail';

  //큐어룸 설정페이지
   static const String cureRoomSettings = '/cure-room/settings'; 

  //멤버관리 페이지
  static const memberManage = '/cure-room/member-manage';
}

