import 'dart:async';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:go_router/go_router.dart';
import '../../features/notifications/data/repositories/notification_repository.dart';
import '../network/api_client.dart';

@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  try {
    await Firebase.initializeApp();
  } catch (_) {
    // Firebase credentials may not be configured in local dev environment
  }
}

class PushNotificationService extends ChangeNotifier {
  PushNotificationService({
    required this.apiClient,
    NotificationRepository? notificationRepository,
  }) : _repository = notificationRepository ??
            NotificationRepositoryImpl(apiClient: apiClient);

  final ApiClient apiClient;
  final NotificationRepository _repository;
  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  GoRouter? _router;
  bool _firebaseAvailable = false;
  String? _currentDeviceToken;
  int? _pendingDeepLinkTicketId;
  int _unreadCount = 0;
  StreamSubscription<String>? _tokenRefreshSub;
  StreamSubscription<RemoteMessage>? _foregroundMessageSub;
  StreamSubscription<RemoteMessage>? _messageOpenedAppSub;

  int get unreadCount => _unreadCount;
  String? get currentDeviceToken => _currentDeviceToken;

  static const AndroidNotificationChannel _androidChannel =
      AndroidNotificationChannel(
    'helpdesk_notifications_channel',
    'Helpdesk Notifications',
    description: 'Real-time notifications for ticket creation and resolution',
    importance: Importance.high,
  );

  void attachRouter(GoRouter router) {
    _router = router;
    _consumePendingDeepLinkIfPossible();
  }

  Future<void> initialize() async {
    await _initLocalNotifications();

    try {
      await Firebase.initializeApp();
      _firebaseAvailable = true;
    } catch (e) {
      _firebaseAvailable = false;
      debugPrint(
        'PushNotificationService: Firebase not configured ($e). Running in local/in-app notification mode.',
      );
      return;
    }

    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
    await requestNotificationPermissions();

    // Handle foreground messages -> show local notification + refresh unread badge
    _foregroundMessageSub = FirebaseMessaging.onMessage.listen((message) {
      _showForegroundNotification(message);
      refreshUnreadCount();
    });

    // Handle background push tap -> deep-link to ticket detail screen
    _messageOpenedAppSub =
        FirebaseMessaging.onMessageOpenedApp.listen(_handleRemoteMessageTap);

    // Handle terminated state launch tap -> deep-link to ticket detail screen
    try {
      final initialMessage =
          await FirebaseMessaging.instance.getInitialMessage();
      if (initialMessage != null) {
        _handleRemoteMessageTap(initialMessage);
      }
    } catch (_) {}

    // Listen to FCM token refreshes and re-register with POST /api/devices
    // ignore: deprecated_member_use
    _tokenRefreshSub =
        // ignore: deprecated_member_use
        FirebaseMessaging.instance.onTokenRefresh.listen((newToken) async {
      _currentDeviceToken = newToken;
      await _registerTokenWithBackend(newToken);
    });
  }

  Future<void> _initLocalNotifications() async {
    if (kIsWeb) return;
    try {
      const androidSettings =
          AndroidInitializationSettings('@mipmap/ic_launcher');
      const darwinSettings = DarwinInitializationSettings(
        requestAlertPermission: true,
        requestBadgePermission: true,
        requestSoundPermission: true,
      );
      const initSettings = InitializationSettings(
        android: androidSettings,
        iOS: darwinSettings,
        macOS: darwinSettings,
      );

      await _localNotifications.initialize(
        settings: initSettings,
        onDidReceiveNotificationResponse: (NotificationResponse response) {
          final payload = response.payload;
          if (payload != null && payload.isNotEmpty) {
            final ticketId = int.tryParse(payload);
            if (ticketId != null) {
              _navigateToTicket(ticketId);
            }
          }
        },
      );

      final androidPlugin =
          _localNotifications.resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>();
      await androidPlugin?.createNotificationChannel(_androidChannel);
    } catch (e) {
      debugPrint('Local notifications initialization warning: $e');
    }
  }

  Future<void> requestNotificationPermissions() async {
    if (kIsWeb) return;
    try {
      if (_firebaseAvailable) {
        await FirebaseMessaging.instance.requestPermission(
          alert: true,
          badge: true,
          sound: true,
          provisional: false,
        );
        await FirebaseMessaging.instance
            .setForegroundNotificationPresentationOptions(
          alert: true,
          badge: true,
          sound: true,
        );
      }
      final androidPlugin =
          _localNotifications.resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>();
      await androidPlugin?.requestNotificationsPermission();
    } catch (e) {
      debugPrint('Notification permission request warning: $e');
    }
  }

  Future<void> _showForegroundNotification(RemoteMessage message) async {
    if (kIsWeb) return;
    final notification = message.notification;
    final title =
        notification?.title ?? message.data['title']?.toString() ?? 'Helpdesk';
    final body = notification?.body ?? message.data['message']?.toString() ?? '';
    final ticketId = message.data['ticketId']?.toString() ?? '';

    try {
      await _localNotifications.show(
        id: message.hashCode,
        title: title,
        body: body,
        notificationDetails: NotificationDetails(
          android: AndroidNotificationDetails(
            _androidChannel.id,
            _androidChannel.name,
            channelDescription: _androidChannel.description,
            importance: Importance.high,
            priority: Priority.high,
            icon: '@mipmap/ic_launcher',
          ),
          iOS: const DarwinNotificationDetails(
            presentAlert: true,
            presentBadge: true,
            presentSound: true,
          ),
        ),
        payload: ticketId,
      );
    } catch (e) {
      debugPrint('Foreground local notification display warning: $e');
    }
  }

  void _handleRemoteMessageTap(RemoteMessage message) {
    final rawTicketId = message.data['ticketId']?.toString();
    final ticketId = rawTicketId != null ? int.tryParse(rawTicketId) : null;
    if (ticketId != null) {
      _navigateToTicket(ticketId);
      return;
    }
    final link = message.data['link']?.toString();
    if (link != null && link.startsWith('/tickets/')) {
      final parsed = int.tryParse(link.replaceFirst('/tickets/', ''));
      if (parsed != null) {
        _navigateToTicket(parsed);
      }
    }
  }

  void _navigateToTicket(int ticketId) {
    if (_router != null) {
      _router!.push('/tickets/$ticketId');
    } else {
      _pendingDeepLinkTicketId = ticketId;
    }
  }

  void _consumePendingDeepLinkIfPossible() {
    if (_router != null && _pendingDeepLinkTicketId != null) {
      final target = _pendingDeepLinkTicketId!;
      _pendingDeepLinkTicketId = null;
      Future.microtask(() => _router?.push('/tickets/$target'));
    }
  }

  Future<void> onUserAuthenticated() async {
    await refreshUnreadCount();
    await registerCurrentDeviceToken();
    _consumePendingDeepLinkIfPossible();
  }

  Future<void> registerCurrentDeviceToken() async {
    if (!_firebaseAvailable) return;
    try {
      // ignore: deprecated_member_use
      final token = await FirebaseMessaging.instance.getToken();
      if (token != null && token.isNotEmpty) {
        _currentDeviceToken = token;
        await _registerTokenWithBackend(token);
      }
    } catch (e) {
      debugPrint('Failed to fetch/register FCM token: $e');
    }
  }

  Future<void> _registerTokenWithBackend(String token) async {
    try {
      await _repository.registerDeviceToken(
        token: token,
        platform: _resolvePlatformString(),
      );
    } catch (e) {
      debugPrint('Backend device token registration skipped/failed: $e');
    }
  }

  Future<void> onUserLogout() async {
    final tokenToRemove = _currentDeviceToken;
    if (tokenToRemove != null && tokenToRemove.isNotEmpty) {
      try {
        await _repository.unregisterDeviceToken(tokenToRemove);
      } catch (_) {}
    } else if (_firebaseAvailable) {
      try {
        // ignore: deprecated_member_use
        final token = await FirebaseMessaging.instance.getToken();
        if (token != null && token.isNotEmpty) {
          await _repository.unregisterDeviceToken(token);
        }
      } catch (_) {}
    }
    _unreadCount = 0;
    notifyListeners();
  }

  Future<void> refreshUnreadCount() async {
    try {
      _unreadCount = await _repository.getUnreadCount();
      notifyListeners();
    } catch (_) {}
  }

  String _resolvePlatformString() {
    if (kIsWeb) return 'WEB';
    switch (defaultTargetPlatform) {
      case TargetPlatform.iOS:
      case TargetPlatform.macOS:
        return 'IOS';
      case TargetPlatform.android:
      default:
        return 'ANDROID';
    }
  }

  @override
  void dispose() {
    _tokenRefreshSub?.cancel();
    _foregroundMessageSub?.cancel();
    _messageOpenedAppSub?.cancel();
    super.dispose();
  }
}
