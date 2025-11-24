import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flux/data/models/habit.dart';
import 'package:flux/data/models/habit_entry.dart';
import 'package:flux/core/services/storage_service.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz;

class NotificationService {
  static final FlutterLocalNotificationsPlugin _notifications = FlutterLocalNotificationsPlugin();
  static bool _initialized = false;

  // Initialize the notification service
  static Future<void> initialize() async {
    if (_initialized) return;

    tz.initializeTimeZones();

    const AndroidInitializationSettings androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const DarwinInitializationSettings iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );
    const WindowsInitializationSettings windowsSettings = WindowsInitializationSettings(
      appName: 'Flux',
      appUserModelId: 'com.wisamidris.flux',
      guid: '5340cfef-f460-4f74-b4c7-a5965ca84726',
    );
    const LinuxInitializationSettings linuxSettings = LinuxInitializationSettings(defaultActionName: 'default');

    const InitializationSettings settings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
      macOS: iosSettings,
      windows: windowsSettings,
      linux: linuxSettings,
    );

    await _notifications.initialize(settings, onDidReceiveNotificationResponse: _onNotificationTap);

    _initialized = true;
  }

  // Handle notification taps
  static void _onNotificationTap(NotificationResponse response) {
    final payload = response.payload;
    if (payload != null) {
      // Parse payload and handle action
      final parts = payload.split('|');
      if (parts.length >= 2) {
        final action = parts[0];
        final habitId = parts[1];

        switch (action) {
          case 'log_success':
            _handleQuickLog(habitId, true);
            break;
          case 'log_skip':
            _handleQuickLog(habitId, false);
            break;
          case 'open_habit':
            // This would typically navigate to the habit detail screen
            break;
        }
      }
    }
  }

  // Handle quick logging from notification
  static Future<void> _handleQuickLog(String habitId, bool success) async {
    try {
      final habits = await StorageService.loadAll();
      final habit = habits.firstWhere((h) => h.id == habitId);

      // Create entry based on action
      final entry = HabitEntry(
        dayNumber: habit.getNextDayNumber(),
        date: DateTime.now(),
        count: success ? 1 : 0,
        isSkipped: !success,
        notes: success ? 'Quick logged from notification' : 'Skipped from notification',
      );

      habit.entries.add(entry);
      await StorageService.save(habit);

      // Show confirmation notification
      await showInstantNotification(
        title: success ? 'Logged! 🎉' : 'Skipped',
        body: '${habit.name} has been ${success ? 'completed' : 'skipped'} for today',
      );
    } catch (e) {
      debugPrint('Error in quick log: $e');
    }
  }

  // Request permissions
  static Future<bool> requestPermissions() async {
    if (Platform.isAndroid) {
      final status = await Permission.notification.request();
      return status.isGranted;
    } else if (Platform.isIOS) {
      final result = await _notifications
          .resolvePlatformSpecificImplementation<IOSFlutterLocalNotificationsPlugin>()
          ?.requestPermissions(alert: true, badge: true, sound: true);
      return result ?? false;
    }
    return true;
  }

  // Schedule a habit reminder
  static Future<void> scheduleHabitReminder(Habit habit) async {
    try {
      // Ensure the service is initialized
      if (!_initialized) {
        await initialize();
      }

      if (!habit.hasReminder || habit.reminderHour == null || habit.reminderMinute == null) {
        return;
      }

      await cancelHabitReminder(habit.id);

      final now = DateTime.now();
      var scheduledDate = DateTime(now.year, now.month, now.day, habit.reminderHour!, habit.reminderMinute!);

      // If the time has passed today, schedule for tomorrow
      if (scheduledDate.isBefore(now)) {
        scheduledDate = scheduledDate.add(const Duration(days: 1));
      }

      final androidDetails = AndroidNotificationDetails(
        'habit_reminders',
        'Habit Reminders',
        channelDescription: 'Reminders for your habits',
        importance: Importance.high,
        priority: Priority.high,
        actions: [
          AndroidNotificationAction(
            'log_success',
            'Mark Done',
            icon: DrawableResourceAndroidBitmap('@drawable/ic_check'),
          ),
          AndroidNotificationAction('log_skip', 'Skip', icon: DrawableResourceAndroidBitmap('@drawable/ic_skip')),
        ],
      );

      const iosDetails = DarwinNotificationDetails(presentAlert: true, presentBadge: true, presentSound: true);

      final details = NotificationDetails(android: androidDetails, iOS: iosDetails);

      final motivationalMessage = habit.getRandomMotivationalMessage();

      await _notifications.zonedSchedule(
        habit.id.hashCode,
        'Time for ${habit.name}! 🎯',
        motivationalMessage,
        tz.TZDateTime.from(scheduledDate, tz.local),
        details,
        payload: 'open_habit|${habit.id}',
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        matchDateTimeComponents: DateTimeComponents.time,
      );
    } catch (e) {
      debugPrint('Error scheduling habit reminder: $e');
    }
  }

  // Cancel habit reminder
  static Future<void> cancelHabitReminder(String habitId) async {
    await _notifications.cancel(habitId.hashCode);
  }

  // Schedule all active habit reminders
  static Future<void> scheduleAllReminders(List<Habit> habits) async {
    for (final habit in habits) {
      if (!habit.isArchived && !habit.isPaused && habit.hasReminder) {
        await scheduleHabitReminder(habit);
      }
    }
  }

  // Show instant notification
  static Future<void> showInstantNotification({required String title, required String body, String? payload}) async {
    try {
      // Ensure the service is initialized
      if (!_initialized) {
        await initialize();
      }

      const androidDetails = AndroidNotificationDetails(
        'instant_notifications',
        'Instant Notifications',
        channelDescription: 'Immediate notifications',
        importance: Importance.high,
        priority: Priority.high,
      );

      const iosDetails = DarwinNotificationDetails(presentAlert: true, presentBadge: true, presentSound: true);

      const details = NotificationDetails(android: androidDetails, iOS: iosDetails);

      await _notifications.show(DateTime.now().millisecondsSinceEpoch ~/ 1000, title, body, details, payload: payload);
    } catch (e) {
      debugPrint('Error showing instant notification: $e');
    }
  }

  // Show achievement notification with confetti
  static Future<void> showAchievementNotification({required String title, required String body}) async {
    try {
      // Ensure the service is initialized
      if (!_initialized) {
        await initialize();
      }

      final androidDetails = AndroidNotificationDetails(
        'achievements',
        'Achievements',
        channelDescription: 'Achievement notifications',
        importance: Importance.high,
        priority: Priority.high,
        sound: RawResourceAndroidNotificationSound('achievement'),
        enableVibration: true,
        vibrationPattern: Int64List.fromList([0, 1000, 500, 1000]),
      );

      const iosDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
        sound: 'achievement.aiff',
      );

      final details = NotificationDetails(android: androidDetails, iOS: iosDetails);

      await _notifications.show(DateTime.now().millisecondsSinceEpoch ~/ 1000, title, body, details);
    } catch (e) {
      debugPrint('Error showing achievement notification: $e');
    }
  }

  // Show streak milestone notification
  static Future<void> showStreakMilestoneNotification(Habit habit) async {
    if (!habit.isStreakMilestone()) return;

    final message = habit.getMilestoneMessage();

    await showAchievementNotification(title: 'Streak Milestone! 🔥', body: '${habit.name}: $message');
  }

  // Show motivational notification for missed habits
  static Future<void> showMotivationalNotification(Habit habit) async {
    final messages = [
      "Don't break the chain! ${habit.name} is waiting for you 💪",
      "You've got this! Complete ${habit.name} today ⭐",
      "Small steps, big results! Time for ${habit.name} 🚀",
      "Your future self will thank you! Do ${habit.name} now 🌟",
      "Consistency beats perfection! ${habit.name} awaits 🎯",
    ];

    messages.shuffle();

    await showInstantNotification(title: 'Gentle Reminder 🤗', body: messages.first, payload: 'open_habit|${habit.id}');
  }

  // Location-based notifications (requires location permissions)
  static Future<void> setupLocationReminder(Habit habit) async {
    if (habit.reminderLatitude == null || habit.reminderLongitude == null) {
      return;
    }

    // Check location permission
    final permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      final newPermission = await Geolocator.requestPermission();
      if (newPermission == LocationPermission.denied) {
        return;
      }
    }

    // This is a simplified version - in a full implementation,
    // you'd set up geofencing or periodic location checks
    final currentPosition = await Geolocator.getCurrentPosition();
    final distance = Geolocator.distanceBetween(
      currentPosition.latitude,
      currentPosition.longitude,
      habit.reminderLatitude!,
      habit.reminderLongitude!,
    );

    final radius = habit.reminderRadius ?? 100; // Default 100m radius

    if (distance <= radius) {
      await showInstantNotification(
        title: 'Location Reminder 📍',
        body: 'You\'re near your ${habit.locationReminder} location! Time for ${habit.name}?',
        payload: 'open_habit|${habit.id}',
      );
    }
  }

  // Daily summary notification
  static Future<void> showDailySummary(List<Habit> habits) async {
    final dueToday = habits.where((h) => h.isDueToday() && !h.isArchived && !h.isPaused).length;
    final completed = habits.where((h) {
      final today = DateTime.now();
      final todayEntries = h.entries.where(
        (e) =>
            e.date.year == today.year && e.date.month == today.month && e.date.day == today.day && h.isPositiveDay(e),
      );
      return todayEntries.isNotEmpty;
    }).length;

    if (dueToday == 0) return;

    final remaining = dueToday - completed;
    String body;

    if (remaining == 0) {
      body = '🎉 Amazing! You\'ve completed all your habits today!';
    } else if (completed == 0) {
      body = '🎯 You have $dueToday habits to complete today. Let\'s get started!';
    } else {
      body = '👍 Great progress! $completed done, $remaining remaining.';
    }

    await showInstantNotification(title: 'Daily Summary', body: body);
  }

  // Show level up notification
  static Future<void> showLevelUpNotification(Habit habit, int newLevel) async {
    await showAchievementNotification(
      title: 'Level Up! 🎉',
      body: '${habit.name} reached Level $newLevel! Keep up the great work!',
    );
  }

  // Cancel all notifications
  static Future<void> cancelAllNotifications() async {
    await _notifications.cancelAll();
  }
}
