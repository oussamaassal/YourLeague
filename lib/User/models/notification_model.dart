class NotificationModel {
  final String id;
  final String title;
  final String body;
  final DateTime scheduledTime;
  final DateTime createdAt;
  final String matchId;
  final String matchTitle;
  final bool isDelivered;
  final NotificationType type;

  NotificationModel({
    required this.id,
    required this.title,
    required this.body,
    required this.scheduledTime,
    required this.createdAt,
    required this.matchId,
    required this.matchTitle,
    this.isDelivered = false,
    this.type = NotificationType.matchReminder,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'body': body,
      'scheduledTime': scheduledTime.toIso8601String(),
      'createdAt': createdAt.toIso8601String(),
      'matchId': matchId,
      'matchTitle': matchTitle,
      'isDelivered': isDelivered,
      'type': type.toString(),
    };
  }

  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    return NotificationModel(
      id: json['id'],
      title: json['title'],
      body: json['body'],
      scheduledTime: DateTime.parse(json['scheduledTime']),
      createdAt: DateTime.parse(json['createdAt']),
      matchId: json['matchId'],
      matchTitle: json['matchTitle'],
      isDelivered: json['isDelivered'] ?? false,
      type: NotificationType.values.firstWhere(
        (e) => e.toString() == json['type'],
        orElse: () => NotificationType.matchReminder,
      ),
    );
  }

  NotificationModel copyWith({
    String? id,
    String? title,
    String? body,
    DateTime? scheduledTime,
    DateTime? createdAt,
    String? matchId,
    String? matchTitle,
    bool? isDelivered,
    NotificationType? type,
  }) {
    return NotificationModel(
      id: id ?? this.id,
      title: title ?? this.title,
      body: body ?? this.body,
      scheduledTime: scheduledTime ?? this.scheduledTime,
      createdAt: createdAt ?? this.createdAt,
      matchId: matchId ?? this.matchId,
      matchTitle: matchTitle ?? this.matchTitle,
      isDelivered: isDelivered ?? this.isDelivered,
      type: type ?? this.type,
    );
  }

  @override
  String toString() {
    return 'NotificationModel(id: $id, title: $title, scheduledTime: $scheduledTime, isDelivered: $isDelivered)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is NotificationModel && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}

enum NotificationType {
  matchReminder,
  matchUpdate,
  general,
}

extension NotificationTypeExtension on NotificationType {
  String get displayName {
    switch (this) {
      case NotificationType.matchReminder:
        return 'Rappel de match';
      case NotificationType.matchUpdate:
        return 'Mise à jour de match';
      case NotificationType.general:
        return 'Général';
    }
  }

  String get icon {
    switch (this) {
      case NotificationType.matchReminder:
        return '⏰';
      case NotificationType.matchUpdate:
        return '📢';
      case NotificationType.general:
        return '📱';
    }
  }
}