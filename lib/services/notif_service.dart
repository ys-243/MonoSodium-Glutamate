import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

class NotificationService {
  NotificationService._();

  static final NotificationService instance = NotificationService._();

  final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();

  static const String _eventChannelId = 'event_reminders';
  static const String _eventChannelName = 'Event Reminders';
  static const String _eventChannelDescription =
      'Notifications for upcoming PlanNUS events';

  Future<void> initialize() async {
    // Initialise timezone information.
    tz.initializeTimeZones();

    // PlanNUS is currently intended for NUS users in Singapore.
    tz.setLocalLocation(tz.getLocation('Asia/Singapore'));

    const AndroidInitializationSettings androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const DarwinInitializationSettings iosSettings =
        DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );

    const InitializationSettings initializationSettings =
        InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _notifications.initialize(
      settings: initializationSettings,
      onDidReceiveNotificationResponse: _onNotificationTapped,
    );
  }

  void _onNotificationTapped(NotificationResponse response) {
    final String? eventId = response.payload;

    if (eventId == null || eventId.isEmpty) {
      return;
    }

    debugPrint('Notification opened for event: $eventId');

    /*
    You can later use eventId to open the selected event.

    For example:

    navigatorKey.currentState?.push(
      MaterialPageRoute(
        builder: (_) => EventDetailsScreen(eventId: eventId),
      ),
    );
    */
  }

  Future<bool> requestPermissions() async {
    bool androidGranted = true;
    bool iosGranted = true;

    final AndroidFlutterLocalNotificationsPlugin? androidPlugin =
        _notifications.resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();

    final bool? androidResult =
        await androidPlugin?.requestNotificationsPermission();

    if (androidResult != null) {
      androidGranted = androidResult;
    }

    final IOSFlutterLocalNotificationsPlugin? iosPlugin =
        _notifications.resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin>();

    final bool? iosResult = await iosPlugin?.requestPermissions(
      alert: true,
      badge: true,
      sound: true,
    );

    if (iosResult != null) {
      iosGranted = iosResult;
    }

    return androidGranted && iosGranted;
  }

  Future<void> showTestNotification() async {
    const NotificationDetails details = NotificationDetails(
      android: AndroidNotificationDetails(
        _eventChannelId,
        _eventChannelName,
        channelDescription: _eventChannelDescription,
        importance: Importance.max,
        priority: Priority.high,
      ),
      iOS: DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      ),
    );

    await _notifications.show(
      id: 999999,
      title: 'PlanNUS notifications enabled',
      body: 'You will now receive reminders for upcoming events.',
      notificationDetails: details,
      payload: 'test',
    );
  }

  Future<void> scheduleEventReminder({
    required String eventId,
    required String eventTitle,
    required DateTime eventStartTime,
    Duration reminderBefore = const Duration(hours: 1),
  }) async {
    final int notificationId = notificationIdForEvent(eventId);

    // Supabase usually returns timestamps in UTC.
    final tz.TZDateTime singaporeEventTime = tz.TZDateTime.from(
      eventStartTime.toUtc(),
      tz.local,
    );

    final tz.TZDateTime notificationTime =
        singaporeEventTime.subtract(reminderBefore);

    // Do not schedule reminders that have already passed.
    if (notificationTime.isBefore(tz.TZDateTime.now(tz.local))) {
      debugPrint(
        'Reminder not scheduled because the reminder time has passed.',
      );
      return;
    }

    const NotificationDetails details = NotificationDetails(
      android: AndroidNotificationDetails(
        _eventChannelId,
        _eventChannelName,
        channelDescription: _eventChannelDescription,
        importance: Importance.max,
        priority: Priority.high,
      ),
      iOS: DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      ),
    );

    // Cancel the previous reminder if this event was rescheduled.
    await cancelEventReminder(eventId);

    await _notifications.zonedSchedule(
      id: notificationId,
      title: 'Upcoming event',
      body: '$eventTitle starts in ${_formatDuration(reminderBefore)}.',
      scheduledDate: notificationTime,
      notificationDetails: details,
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      payload: eventId,
    );

    debugPrint(
      'Scheduled notification for $eventTitle at $notificationTime',
    );
  }

  Future<void> cancelEventReminder(String eventId) async {
    await _notifications.cancel(
      id: notificationIdForEvent(eventId),
    );
  }

  Future<void> cancelAllNotifications() async {
    await _notifications.cancelAll();
  }

  Future<List<PendingNotificationRequest>>
      getPendingNotifications() async {
    return _notifications.pendingNotificationRequests();
  }

  int notificationIdForEvent(String eventId) {
    /*
     * Creates the same positive notification ID for the same event UUID.
     * Using a stable ID means editing an event replaces its old reminder.
     */
    int hash = 0x811c9dc5;

    for (final int character in eventId.codeUnits) {
      hash ^= character;
      hash = (hash * 0x01000193) & 0x7fffffff;
    }

    return hash;
  }

  String _formatDuration(Duration duration) {
    if (duration.inDays >= 1) {
      return '${duration.inDays} day${duration.inDays == 1 ? '' : 's'}';
    }

    if (duration.inHours >= 1) {
      return '${duration.inHours} hour${duration.inHours == 1 ? '' : 's'}';
    }

    return '${duration.inMinutes} minute'
        '${duration.inMinutes == 1 ? '' : 's'}';
  }
}