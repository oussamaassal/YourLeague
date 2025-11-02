import 'package:cloud_firestore/cloud_firestore.dart' as fs;

class Stadium {
  final String id;
  final String name;
  final String city;
  final String address;
  final int capacity;
  final double pricePerHour;
  final String imageUrl;
  final String? userId; // Owner/creator of the stadium
  final fs.Timestamp createdAt;

  Stadium({
    required this.id,
    required this.name,
    required this.city,
    required this.address,
    required this.capacity,
    required this.pricePerHour,
    this.imageUrl = '',
    this.userId,
    required this.createdAt,
  });

  factory Stadium.fromJson(Map<String, dynamic> json) {
    return Stadium(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      city: json['city'] ?? '',
      address: json['address'] ?? '',
      capacity: json['capacity'] ?? 0,
      pricePerHour: (json['pricePerHour'] ?? json['price_per_hour'] ?? 0.0).toDouble(),
      imageUrl: json['imageUrl'] ?? '',
      userId: json['userId'],
      createdAt: json['createdAt'] ?? fs.Timestamp.now(),
    );
  }

  factory Stadium.fromFirestore(Map<String, dynamic> data, String id) {
    return Stadium(
      id: id,
      name: data['name'] ?? '',
      city: data['city'] ?? '',
      address: data['address'] ?? '',
      capacity: data['capacity'] ?? 0,
      pricePerHour: (data['pricePerHour'] ?? data['price_per_hour'] ?? 0.0).toDouble(),
      imageUrl: data['imageUrl'] ?? '',
      userId: data['userId'],
      createdAt: data['createdAt'] ?? fs.Timestamp.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'city': city,
      'address': address,
      'capacity': capacity,
      'pricePerHour': pricePerHour,
      'imageUrl': imageUrl,
      'userId': userId,
      'createdAt': createdAt,
    };
  }

  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      'city': city,
      'address': address,
      'capacity': capacity,
      'pricePerHour': pricePerHour,
      'imageUrl': imageUrl,
      'userId': userId,
      'createdAt': createdAt,
    };
  }
}
