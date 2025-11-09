import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'notification_service.dart';

/// Set up Firebase Cloud Messaging for a given user
Future<void> setupFCM(String uid) async {
  // Ask permission (for iOS / Android 13+)
  await FirebaseMessaging.instance.requestPermission(
    alert: true,
    badge: true,
    sound: true,
  );

  // Get FCM token
  final token = await FirebaseMessaging.instance.getToken();
  if (token != null) {
    await FirebaseFirestore.instance.collection('users').doc(uid).set(
      {'fcmToken': token},
      SetOptions(merge: true),
    );
  }

  // Auto-refresh token if changed
  FirebaseMessaging.instance.onTokenRefresh.listen((newToken) async {
    await FirebaseFirestore.instance.collection('users').doc(uid).set(
      {'fcmToken': newToken},
      SetOptions(merge: true),
    );
  });

  // Foreground notifications
  FirebaseMessaging.onMessage.listen((RemoteMessage message) {
    final n = message.notification;
    if (n != null) NotificationService.show(n);
  });
}
