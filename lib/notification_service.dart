import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz_data;

enum ReminderRepeatMode { none, daily, weekly }

class NotificationService {
  static const String _windowsAppName = 'RPG To-Do List';
  static const String _windowsAppUserModelId = 'Saijer.RPGToDoList.App';
  static const String _windowsGuid = '5b5ef079-0e34-4f9a-9d62-8d8fbc1677ac';

  static final NotificationService _instance = NotificationService._();
  factory NotificationService() => _instance;
  NotificationService._();

  final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();
  bool _initialized = false;
  bool? _permissionsGranted;
  Future<bool>? _permissionRequestInFlight;
  int _permissionRequestGeneration = 0;

  Future<void> init() async {
    if (_initialized) return;

    tz_data.initializeTimeZones();
    await _configureLocalTimezone();

    const androidSettings = AndroidInitializationSettings(
      '@mipmap/ic_launcher',
    );
    const macOSSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );
    const iOSSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );
    const windowsSettings = WindowsInitializationSettings(
      appName: _windowsAppName,
      appUserModelId: _windowsAppUserModelId,
      guid: _windowsGuid,
    );
    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iOSSettings,
      macOS: macOSSettings,
      windows: windowsSettings,
    );

    await _notifications.initialize(
      settings: initSettings,
      onDidReceiveNotificationResponse: (response) {},
    );
    _initialized = true;
  }

  Future<void> _configureLocalTimezone() async {
    try {
      final timezone = await FlutterTimezone.getLocalTimezone();
      tz.setLocalLocation(tz.getLocation(timezone.identifier));
    } catch (_) {
      tz.setLocalLocation(tz.getLocation('UTC'));
    }
  }

  Future<bool> requestPermissions() async {
    final cached = _permissionsGranted;
    if (cached != null) return cached;

    final inFlight = _permissionRequestInFlight;
    if (inFlight != null) return inFlight;

    final request = _requestPermissionsUnlocked();
    final generation = _permissionRequestGeneration;
    _permissionRequestInFlight = request;
    try {
      final granted = await request;
      if (generation == _permissionRequestGeneration) {
        _permissionsGranted = granted;
      }
      return granted;
    } finally {
      if (identical(_permissionRequestInFlight, request)) {
        _permissionRequestInFlight = null;
      }
    }
  }

  void invalidatePermissionCache() {
    _permissionRequestGeneration++;
    _permissionsGranted = null;
    _permissionRequestInFlight = null;
  }

  Future<bool> _requestPermissionsUnlocked() async {
    final android = _notifications
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();
    final iOS = _notifications
        .resolvePlatformSpecificImplementation<
          IOSFlutterLocalNotificationsPlugin
        >();
    final macOS = _notifications
        .resolvePlatformSpecificImplementation<
          MacOSFlutterLocalNotificationsPlugin
        >();
    final windows = _notifications
        .resolvePlatformSpecificImplementation<
          FlutterLocalNotificationsWindows
        >();

    bool granted = false;

    if (android != null) {
      final notificationsGranted =
          await android.requestNotificationsPermission() ?? false;
      final canScheduleExact =
          await android.canScheduleExactNotifications() ?? true;
      final exactGranted = canScheduleExact
          ? true
          : await android.requestExactAlarmsPermission() ?? false;
      granted = notificationsGranted && exactGranted;
    }

    if (iOS != null) {
      granted =
          await iOS.requestPermissions(alert: true, badge: true, sound: true) ??
          false;
    }

    if (macOS != null) {
      granted =
          await macOS.requestPermissions(
            alert: true,
            badge: true,
            sound: true,
          ) ??
          false;
    }

    if (windows != null) {
      granted = true;
    }

    return granted;
  }

  @visibleForTesting
  bool? get debugCachedPermissions => _permissionsGranted;

  @visibleForTesting
  void debugSetPermissionCache(bool? granted) {
    _permissionsGranted = granted;
  }

  Future<void> scheduleRepeatingTask({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledTime,
    ReminderRepeatMode repeatMode = ReminderRepeatMode.none,
  }) async {
    var scheduledDate = tz.TZDateTime.from(scheduledTime, tz.local);
    final now = tz.TZDateTime.now(tz.local);
    if (!scheduledDate.isAfter(now)) {
      final originalScheduledDate = scheduledDate;
      scheduledDate = now.add(const Duration(minutes: 1));
      if (kDebugMode) {
        debugPrint(
          'Repeating notification $id was scheduled in the past '
          '($originalScheduledDate); rescheduled to $scheduledDate '
          'with repeat mode ${repeatMode.name}.',
        );
      }
    }

    await _notifications.zonedSchedule(
      id: id,
      title: title,
      body: body,
      scheduledDate: scheduledDate,
      notificationDetails: _taskNotificationDetails(
        channelDescription: 'Уведомления о повторяющихся квестах',
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      matchDateTimeComponents: switch (repeatMode) {
        ReminderRepeatMode.daily => DateTimeComponents.time,
        ReminderRepeatMode.weekly => DateTimeComponents.dayOfWeekAndTime,
        ReminderRepeatMode.none => null,
      },
    );
  }

  Future<void> scheduleTaskReminder({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledTime,
  }) async {
    final tzTime = tz.TZDateTime.from(scheduledTime, tz.local);

    await _notifications.zonedSchedule(
      id: id,
      title: title,
      body: body,
      scheduledDate: tzTime,
      notificationDetails: _taskNotificationDetails(
        channelDescription: 'Уведомления о квестах',
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
    );
  }

  Future<void> cancelNotification(int id) async {
    await _notifications.cancel(id: id);
  }

  Future<void> cancelAllNotifications() async {
    await _notifications.cancelAll();
  }

  Future<void> showInstantNotification({
    required int id,
    required String title,
    required String body,
  }) async {
    await _notifications.show(
      id: id,
      title: title,
      body: body,
      notificationDetails: _taskNotificationDetails(
        channelDescription: 'Уведомления о квестах',
      ),
    );
  }

  NotificationDetails _taskNotificationDetails({
    required String channelDescription,
  }) {
    return NotificationDetails(
      android: AndroidNotificationDetails(
        'task_reminders',
        'Напоминания о квестах',
        channelDescription: channelDescription,
        importance: Importance.high,
        priority: Priority.high,
        icon: '@mipmap/ic_launcher',
      ),
      iOS: const DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      ),
      macOS: const DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      ),
      windows: const WindowsNotificationDetails(),
    );
  }
}
