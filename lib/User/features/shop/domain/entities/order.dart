import 'package:cloud_firestore/cloud_firestore.dart' as fs;

class Order {
  final String id;
  final String userId;
  final List<Map<String, dynamic>> items; // [{productId, name, price, quantity}]
  final double totalAmount;
  final String status; // pending, processing, completed, cancelled
  final String shippingAddress;
  final fs.Timestamp createdAt;
  final fs.Timestamp? completedAt;

  Order({
    required this.id,
    required this.userId,
    required this.items,
    required this.totalAmount,
    required this.status,
    required this.shippingAddress,
    required this.createdAt,
    this.completedAt,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'items': items,
      'totalAmount': totalAmount,
      'status': status,
      'shippingAddress': shippingAddress,
      'createdAt': createdAt,
      'completedAt': completedAt,
    };
  }

  factory Order.fromJson(Map<String, dynamic> json) {
    return Order(
      id: json['id'],
      userId: json['userId'],
      items: List<Map<String, dynamic>>.from(json['items']),
      totalAmount: json['totalAmount'].toDouble(),
      status: json['status'],
      shippingAddress: json['shippingAddress'],
      createdAt: json['createdAt'],
      completedAt: json['completedAt'],
    );
  }
}

