import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as data;
import 'package:timezone/timezone.dart' as tz;

class NotificationService {
  static final NotificationService _instance = NotificationService._();
  factory NotificationService() => _instance;
  NotificationService._();
  final _plugin = FlutterLocalNotificationsPlugin();
  Future<void>? _initializing;
  bool get supported =>
      !kIsWeb &&
      (defaultTargetPlatform == TargetPlatform.android ||
          defaultTargetPlatform == TargetPlatform.iOS);
  Future<void> init() async {
    if (!supported) {
      throw StateError(
          'Нагадування доступні у застосунку для Android та iPhone.');
    }
    return _initializing ??= _init();
  }

  Future<void> _init() async {
    try {
      data.initializeTimeZones();
      const darwin = DarwinInitializationSettings(
          requestAlertPermission: false,
          requestBadgePermission: false,
          requestSoundPermission: false);
      await _plugin.initialize(
          settings: const InitializationSettings(
              android: AndroidInitializationSettings('ic_notification'),
              iOS: darwin));
    } catch (_) {
      _initializing = null;
      rethrow;
    }
  }

  Future<void> _zone() async {
    final id = await const MethodChannel('dialect_duel/device')
        .invokeMethod<String>('timezone');
    if (id == null) {
      throw StateError('Не вдалося визначити часовий пояс телефону.');
    }
    tz.setLocalLocation(tz.getLocation(id));
  }

  Future<bool> requestPermissions() async {
    await init();
    if (defaultTargetPlatform == TargetPlatform.iOS) {
      return await _plugin
              .resolvePlatformSpecificImplementation<
                  IOSFlutterLocalNotificationsPlugin>()
              ?.requestPermissions(alert: true, badge: true, sound: true) ??
          false;
    }
    return await _plugin
            .resolvePlatformSpecificImplementation<
                AndroidFlutterLocalNotificationsPlugin>()
            ?.requestNotificationsPermission() ??
        false;
  }

  Future<bool> permissionsGranted() async {
    await init();
    if (defaultTargetPlatform == TargetPlatform.iOS) {
      final permissions = await _plugin
          .resolvePlatformSpecificImplementation<
              IOSFlutterLocalNotificationsPlugin>()
          ?.checkPermissions();
      return permissions?.isEnabled ?? false;
    }
    return await _plugin
            .resolvePlatformSpecificImplementation<
                AndroidFlutterLocalNotificationsPlugin>()
            ?.areNotificationsEnabled() ??
        false;
  }

  Future<void> scheduleDailyReminder(int hour, int minute) async {
    await init();
    if (!await permissionsGranted()) {
      throw StateError(
          'Сповіщення вимкнені в системних налаштуваннях телефона.');
    }
    await _zone();
    final now = tz.TZDateTime.now(tz.local);
    var next =
        tz.TZDateTime(tz.local, now.year, now.month, now.day, hour, minute);
    if (!next.isAfter(now)) {
      next = tz.TZDateTime(
          tz.local, now.year, now.month, now.day + 1, hour, minute);
    }
    // Reusing ID replaces only this reminder, preserving any future notification types.
    await _plugin.zonedSchedule(
        id: 0,
        title: 'П’ять хвилин для англійської',
        body: 'Повтори слова або спробуй коротку розмову. Твоя практика чекає.',
        scheduledDate: next,
        notificationDetails: const NotificationDetails(
            android: AndroidNotificationDetails(
                'daily_practice_channel', 'Щоденна практика',
                channelDescription: 'Нагадування про англійську',
                importance: Importance.defaultImportance,
                priority: Priority.defaultPriority),
            iOS: DarwinNotificationDetails()),
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        matchDateTimeComponents: DateTimeComponents.time);
  }

  Future<void> cancelAll() async {
    await init();
    await _plugin.cancel(id: 0);
  }
}
