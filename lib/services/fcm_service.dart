// lib/services/fcm_service.dart

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart'; // 👈 패키지 import
import '../firebase_options.dart';
import '../utils/logger.dart';

// ⚠️ 백그라운드 핸들러 (최상위 함수 필수)
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  Logger.i('백그라운드 메시지 수신: ${message.messageId}', tag: 'FCM');
}

class FcmService {
  static final FcmService _instance = FcmService._internal();
  factory FcmService() => _instance;
  FcmService._internal();

  final FirebaseMessaging _messaging = FirebaseMessaging.instance;

  // 🔔 로컬 알림 플러그인 인스턴스
  final FlutterLocalNotificationsPlugin _localNotifications = FlutterLocalNotificationsPlugin();

  /// 1. 서비스 초기화 (앱 시작 시 호출)
  Future<void> initialize() async {
    // 권한 상태 확인 (로그용)
    await _checkPermissionStatus();

    // 🔔 로컬 알림 채널 설정 (Android 필수)
    await _setupLocalNotification();

    // 핸들러 등록
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
    FirebaseMessaging.onMessage.listen(_onForegroundMessage);
    FirebaseMessaging.onMessageOpenedApp.listen(_onMessageOpenedApp);

    // 종료 상태에서 클릭 확인
    final initialMessage = await _messaging.getInitialMessage();
    if (initialMessage != null) {
      _onMessageOpenedApp(initialMessage);
    }

    Logger.i('FCM Service 초기화 완료', tag: 'FCM');
  }

  /// 2. 로컬 알림 설정 (포그라운드에서 알림 띄우기 위해 필요)
  Future<void> _setupLocalNotification() async {
    // Android 채널 생성
    const AndroidNotificationChannel channel = AndroidNotificationChannel(
      'high_importance_channel', // id
      'High Importance Notifications', // title
      description: 'This channel is used for important notifications.', // description
      importance: Importance.max,
    );

    final AndroidFlutterLocalNotificationsPlugin? androidPlugin =
    _localNotifications.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();

    await androidPlugin?.createNotificationChannel(channel);

    // 초기화 설정
    const AndroidInitializationSettings initializationSettingsAndroid =
    AndroidInitializationSettings('@mipmap/ic_launcher'); // 앱 아이콘

    const DarwinInitializationSettings initializationSettingsIOS =
    DarwinInitializationSettings();

    const InitializationSettings initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: initializationSettingsIOS,
    );

    await _localNotifications.initialize(initializationSettings);
  }

  /// 3. 권한 상태 확인
  Future<void> _checkPermissionStatus() async {
    NotificationSettings settings = await _messaging.getNotificationSettings();
    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      Logger.i('알림 권한 상태: 허용됨', tag: 'FCM');
    } else {
      Logger.w('알림 권한 상태: ${settings.authorizationStatus.name}', tag: 'FCM');
    }
  }

  /// 4. 토큰 가져오기
  Future<String?> getToken() async {
    try {
      String? token = await _messaging.getToken();
      Logger.i('FCM Token 발급: $token', tag: 'FCM');
      return token;
    } catch (e) {
      Logger.e('FCM 토큰 가져오기 실패', tag: 'FCM', error: e);
      return null;
    }
  }

  /// 5. 포그라운드 메시지 처리 (앱 켜져 있을 때)
  void _onForegroundMessage(RemoteMessage message) {
    Logger.i('포그라운드 메시지 수신: ${message.notification?.title}', tag: 'FCM');

    RemoteNotification? notification = message.notification;
    AndroidNotification? android = message.notification?.android;

    // 알림 데이터가 있으면 로컬 알림 띄우기
    if (notification != null && android != null) {
      _localNotifications.show(
        notification.hashCode,
        notification.title,
        notification.body,
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'high_importance_channel',
            'High Importance Notifications',
            icon: '@mipmap/ic_launcher',
            importance: Importance.max,
            priority: Priority.high,
          ),
          iOS: DarwinNotificationDetails(
            presentAlert: true,
            presentBadge: true,
            presentSound: true,
          ),
        ),
      );
    }
  }

  /// 6. 알림 클릭 처리
  void _onMessageOpenedApp(RemoteMessage message) {
    Logger.i('알림 클릭으로 앱 실행: ${message.messageId}', tag: 'FCM');
    // TODO: 필요한 경우 라우터(GoRouter 등)를 사용하여 특정 페이지로 이동
    // 예: context.go('/notifications');
  }
}