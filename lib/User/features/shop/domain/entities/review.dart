import 'package:cloud_firestore/cloud_firestore.dart' as fs;

class Review {
  final String id;
  final String productId;
  final String userId;
  final String? userName; // Optional, for display purposes
  final int rating; // 1-5 stars
  final String comment;
  final fs.Timestamp createdAt;

  Review({
    required this.id,
    required this.productId,
    required this.userId,
    this.userName,
    required this.rating,
    required this.comment,
    required this.createdAt,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'productId': productId,
      'userId': userId,
      'userName': userName,
      'rating': rating,
      'comment': comment,
      'createdAt': createdAt,
    };
  }

  factory Review.fromJson(Map<String, dynamic> json) {
    return Review(
      id: json['id'],
      productId: json['productId'],
      userId: json['userId'],
      userName: json['userName'],
      rating: json['rating'],
      comment: json['comment'] ?? '',
      createdAt: json['createdAt'],
    );
  }
}

