import 'package:cloud_firestore/cloud_firestore.dart' as fs;

class Review {
  final String id;
  final String productId;
  final String userId;
  final String? userName;
  final int rating;
  final String comment;
  final String? imageUrl;
  final fs.Timestamp createdAt;

  Review({
    required this.id,
    required this.productId,
    required this.userId,
    this.userName,
    required this.rating,
    required this.comment,
    this.imageUrl,
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
      'imageUrl': imageUrl,
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
      imageUrl: json['imageUrl'],
      createdAt: json['createdAt'],
    );
  }
}

