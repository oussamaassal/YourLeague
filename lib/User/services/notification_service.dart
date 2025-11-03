import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import '../models/notification_model.dart';
import 'notification_storage_service.dart';

class NotificationService {
  NotificationService._internal();
  static final NotificationService instance = NotificationService._internal();

  final FlutterLocalNotificationsPlugin _plugin = FlutterLocalNotificationsPlugin();
  bool _initialized = false;

  Future<void> init() async {
    if (_initialized) return;

    // Web: local notifications via this plugin are not supported; gracefully skip.
    if (kIsWeb) {
      _initialized = true;
      return;
    }

    const AndroidInitializationSettings androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const DarwinInitializationSettings iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    final InitializationSettings initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
      macOS: iosSettings,
    );

    await _plugin.initialize(initSettings);
    
    // Demander les permissions explicitement
    await _requestPermissions();
    
    _initialized = true;
  }

  Future<void> _requestPermissions() async {
    if (kIsWeb) return;

    // Demander les permissions pour Android 13+
    await _plugin
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();

    // Demander les permissions pour iOS
    await _plugin
        .resolvePlatformSpecificImplementation<IOSFlutterLocalNotificationsPlugin>()
        ?.requestPermissions(
          alert: true,
          badge: true,
          sound: true,
        );
  }

  Future<bool> scheduleMatchReminder({
    required DateTime matchDateTime,
    required int notificationId,
    required String matchId,
    required String matchTitle,
    String title = 'Rappel de match',
    String? body,
    int reminderMinutes = 15,
  }) async {
    if (!_initialized) await init();

    // Skip on web (not supported in this build)
    if (kIsWeb) return false;

    final DateTime trigger = matchDateTime.subtract(Duration(minutes: reminderMinutes));
    if (trigger.isBefore(DateTime.now().add(const Duration(seconds: 5)))) {
      // Too close or already passed
      return false;
    }

    final String notificationBody = body ?? 'Ton match "$matchTitle" est dans $reminderMinutes min';

    const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      'matches_channel',
      'Matches Notifications',
      channelDescription: 'Notifications de rappel pour les matches',
      importance: Importance.high,
      priority: Priority.high,
      showWhen: true,
      enableVibration: true,
      playSound: true,
    );

    const DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    final NotificationDetails platformDetails = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
      macOS: iosDetails,
    );

    try {
      final tz.TZDateTime scheduled = tz.TZDateTime.from(trigger.toUtc(), tz.UTC);
      await _plugin.zonedSchedule(
        notificationId,
        title,
        notificationBody,
        scheduled,
        platformDetails,
        androidScheduleMode: AndroidScheduleMode.inexact,
        uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
        matchDateTimeComponents: DateTimeComponents.dateAndTime,
      );

      // Sauvegarder la notification dans l'historique
      final notification = NotificationModel(
        id: notificationId.toString(),
        title: title,
        body: notificationBody,
        scheduledTime: trigger,
        createdAt: DateTime.now(),
        matchId: matchId,
        matchTitle: matchTitle,
        type: NotificationType.matchReminder,
      );

      await NotificationStorageService.instance.saveNotification(notification);
      return true;
    } catch (e) {
      print('Erreur lors de la programmation de la notification: $e');
      return false;
    }
  }

  Future<void> cancelReminder(int notificationId) async {
    if (!_initialized) await init();
    await _plugin.cancel(notificationId);
    
    // Supprimer de l'historique
    await NotificationStorageService.instance.deleteNotification(notificationId.toString());
  }

  /// Récupère toutes les notifications de l'historique
  Future<List<NotificationModel>> getAllNotifications() async {
    return await NotificationStorageService.instance.getAllNotifications();
  }

  /// Récupère les notifications d'aujourd'hui
  Future<List<NotificationModel>> getTodayNotifications() async {
    return await NotificationStorageService.instance.getTodayNotifications();
  }

  /// Récupère les notifications en attente
  Future<List<NotificationModel>> getPendingNotifications() async {
    return await NotificationStorageService.instance.getPendingNotifications();
  }

  /// Vérifie si les permissions de notification sont accordées
  Future<bool> areNotificationsEnabled() async {
    if (kIsWeb) return false;
    
    final androidImplementation = _plugin.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
    if (androidImplementation != null) {
      final bool? granted = await androidImplementation.areNotificationsEnabled();
      return granted ?? false;
    }
    
    return true; // iOS permissions are handled during initialization
  }

  /// Ouvre les paramètres de notification de l'appareil
  Future<void> openNotificationSettings() async {
    // Cross-platform safe fallback: re-request permissions
    await _requestPermissions();
  }

  /// Marque une notification comme livrée
  Future<void> markAsDelivered(String notificationId) async {
    await NotificationStorageService.instance.markAsDelivered(notificationId);
  }

  /// Supprime toutes les notifications
  Future<void> clearAllNotifications() async {
    await NotificationStorageService.instance.clearAllNotifications();
  }
}