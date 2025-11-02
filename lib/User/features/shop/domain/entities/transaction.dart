import 'package:cloud_firestore/cloud_firestore.dart' as fs;

class Transaction {
  final String id;
  final String userId;
  final String orderId;
  final String type; // purchase, refund, exchange
  final double amount;
  final String paymentMethod; // credit_card, paypal, etc.
  final String status; // pending, completed, failed
  final fs.Timestamp createdAt;
  final String? transactionId; // external transaction ID

  Transaction({
    required this.id,
    required this.userId,
    required this.orderId,
    required this.type,
    required this.amount,
    required this.paymentMethod,
    required this.status,
    required this.createdAt,
    this.transactionId,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'orderId': orderId,
      'type': type,
      'amount': amount,
      'paymentMethod': paymentMethod,
      'status': status,
      'createdAt': createdAt,
      'transactionId': transactionId,
    };
  }

  factory Transaction.fromJson(Map<String, dynamic> json) {
    return Transaction(
      id: json['id'],
      userId: json['userId'],
      orderId: json['orderId'],
      type: json['type'],
      amount: json['amount'].toDouble(),
      paymentMethod: json['paymentMethod'],
      status: json['status'],
      createdAt: json['createdAt'],
      transactionId: json['transactionId'],
    );
  }
}

