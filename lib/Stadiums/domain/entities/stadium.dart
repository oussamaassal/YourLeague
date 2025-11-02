import 'package:cloud_firestore/cloud_firestore.dart' as fs;
import '../errors/stadium_exceptions.dart';

class Stadium {
  final String id;
  final String name;
  final String city;
  final String address;
  final int capacity;
  final double pricePerHour;
  final List<String> imageUrls; // Multiple images support
  final String? userId; // Owner/creator of the stadium
  final double? latitude; // For map integration
  final double? longitude; // For map integration
  final String? phoneNumber; // Contact info
  final String? description; // Additional details
  final fs.Timestamp createdAt;

  Stadium({
    required this.id,
    required this.name,
    required this.city,
    required this.address,
    required this.capacity,
    required this.pricePerHour,
    this.imageUrls = const [],
    this.userId,
    this.latitude,
    this.longitude,
    this.phoneNumber,
    this.description,
    required this.createdAt,
  }) {
    // Validation
    if (name.trim().isEmpty) {
      throw StadiumValidationException('Stadium name cannot be empty');
    }
    if (city.trim().isEmpty) {
      throw StadiumValidationException('City cannot be empty');
    }
    if (address.trim().isEmpty) {
      throw StadiumValidationException('Address cannot be empty');
    }
    if (capacity <= 0) {
      throw StadiumValidationException('Capacity must be greater than 0');
    }
    if (pricePerHour < 0) {
      throw StadiumValidationException('Price per hour cannot be negative');
    }
    if (latitude != null && (latitude! < -90 || latitude! > 90)) {
      throw StadiumValidationException('Latitude must be between -90 and 90');
    }
    if (longitude != null && (longitude! < -180 || longitude! > 180)) {
      throw StadiumValidationException('Longitude must be between -180 and 180');
    }
  }

  // Get primary image (first image or empty string)
  String get imageUrl => imageUrls.isNotEmpty ? imageUrls.first : '';

  // Check if user is owner
  bool isOwner(String? userId) => this.userId != null && this.userId == userId;

  factory Stadium.fromJson(Map<String, dynamic> json) {
    // Handle both single imageUrl and multiple imageUrls for backward compatibility
    List<String> imageUrls = [];
    if (json['imageUrls'] != null) {
      imageUrls = List<String>.from(json['imageUrls']);
    } else if (json['imageUrl'] != null && json['imageUrl'].toString().isNotEmpty) {
      imageUrls = [json['imageUrl']];
    }

    return Stadium(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      city: json['city'] ?? '',
      address: json['address'] ?? '',
      capacity: json['capacity'] ?? 0,
      pricePerHour: (json['pricePerHour'] ?? json['price_per_hour'] ?? 0.0).toDouble(),
      imageUrls: imageUrls,
      userId: json['userId'],
      latitude: json['latitude']?.toDouble(),
      longitude: json['longitude']?.toDouble(),
      phoneNumber: json['phoneNumber'],
      description: json['description'],
      createdAt: json['createdAt'] ?? fs.Timestamp.now(),
    );
  }

  factory Stadium.fromFirestore(Map<String, dynamic> data, String id) {
    // Handle both single imageUrl and multiple imageUrls for backward compatibility
    List<String> imageUrls = [];
    if (data['imageUrls'] != null) {
      imageUrls = List<String>.from(data['imageUrls']);
    } else if (data['imageUrl'] != null && data['imageUrl'].toString().isNotEmpty) {
      imageUrls = [data['imageUrl']];
    }

    return Stadium(
      id: id,
      name: data['name'] ?? '',
      city: data['city'] ?? '',
      address: data['address'] ?? '',
      capacity: data['capacity'] ?? 0,
      pricePerHour: (data['pricePerHour'] ?? data['price_per_hour'] ?? 0.0).toDouble(),
      imageUrls: imageUrls,
      userId: data['userId'],
      latitude: data['latitude']?.toDouble(),
      longitude: data['longitude']?.toDouble(),
      phoneNumber: data['phoneNumber'],
      description: data['description'],
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
      'imageUrls': imageUrls,
      'imageUrl': imageUrl, // Keep for backward compatibility
      'userId': userId,
      'latitude': latitude,
      'longitude': longitude,
      'phoneNumber': phoneNumber,
      'description': description,
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
      'imageUrls': imageUrls,
      'imageUrl': imageUrl, // Keep for backward compatibility
      'userId': userId,
      'latitude': latitude,
      'longitude': longitude,
      'phoneNumber': phoneNumber,
      'description': description,
      'createdAt': createdAt,
    };
  }
}
