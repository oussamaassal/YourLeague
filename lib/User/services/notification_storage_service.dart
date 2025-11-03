import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/notification_model.dart';

class NotificationStorageService {
  static const String _notificationsKey = 'notifications_history';
  static NotificationStorageService? _instance;
  
  NotificationStorageService._();
  
  static NotificationStorageService get instance {
    _instance ??= NotificationStorageService._();
    return _instance!;
  }

  /// Sauvegarde une notification dans l'historique
  Future<void> saveNotification(NotificationModel notification) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final notifications = await getAllNotifications();
      
      // Ajouter la nouvelle notification au début de la liste
      notifications.insert(0, notification);
      
      // Limiter à 100 notifications maximum
      if (notifications.length > 100) {
        notifications.removeRange(100, notifications.length);
      }
      
      final jsonList = notifications.map((n) => n.toJson()).toList();
      await prefs.setString(_notificationsKey, jsonEncode(jsonList));
    } catch (e) {
      print('Erreur lors de la sauvegarde de la notification: $e');
    }
  }

  /// Récupère toutes les notifications de l'historique
  Future<List<NotificationModel>> getAllNotifications() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = prefs.getString(_notificationsKey);
      
      if (jsonString == null) return [];
      
      final jsonList = jsonDecode(jsonString) as List;
      return jsonList
          .map((json) => NotificationModel.fromJson(json))
          .toList();
    } catch (e) {
      print('Erreur lors de la récupération des notifications: $e');
      return [];
    }
  }

  /// Marque une notification comme livrée
  Future<void> markAsDelivered(String notificationId) async {
    try {
      final notifications = await getAllNotifications();
      final index = notifications.indexWhere((n) => n.id == notificationId);
      
      if (index != -1) {
        notifications[index] = notifications[index].copyWith(isDelivered: true);
        
        final prefs = await SharedPreferences.getInstance();
        final jsonList = notifications.map((n) => n.toJson()).toList();
        await prefs.setString(_notificationsKey, jsonEncode(jsonList));
      }
    } catch (e) {
      print('Erreur lors de la mise à jour de la notification: $e');
    }
  }

  /// Supprime une notification de l'historique
  Future<void> deleteNotification(String notificationId) async {
    try {
      final notifications = await getAllNotifications();
      notifications.removeWhere((n) => n.id == notificationId);
      
      final prefs = await SharedPreferences.getInstance();
      final jsonList = notifications.map((n) => n.toJson()).toList();
      await prefs.setString(_notificationsKey, jsonEncode(jsonList));
    } catch (e) {
      print('Erreur lors de la suppression de la notification: $e');
    }
  }

  /// Supprime toutes les notifications
  Future<void> clearAllNotifications() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_notificationsKey);
    } catch (e) {
      print('Erreur lors de la suppression de toutes les notifications: $e');
    }
  }

  /// Récupère les notifications par type
  Future<List<NotificationModel>> getNotificationsByType(NotificationType type) async {
    final allNotifications = await getAllNotifications();
    return allNotifications.where((n) => n.type == type).toList();
  }

  /// Récupère les notifications non livrées
  Future<List<NotificationModel>> getPendingNotifications() async {
    final allNotifications = await getAllNotifications();
    return allNotifications.where((n) => !n.isDelivered).toList();
  }

  /// Récupère les notifications d'aujourd'hui
  Future<List<NotificationModel>> getTodayNotifications() async {
    final allNotifications = await getAllNotifications();
    final today = DateTime.now();
    
    return allNotifications.where((n) {
      final notificationDate = n.createdAt;
      return notificationDate.year == today.year &&
             notificationDate.month == today.month &&
             notificationDate.day == today.day;
    }).toList();
  }
}