import 'package:cloud_firestore/cloud_firestore.dart' as fs;
import '../errors/stadium_exceptions.dart';

class StadiumRental {
  final String id;
  final String stadiumId;
  final String stadiumName;
  final String? renterId; // User who rented the stadium
  final String? ownerId; // Stadium owner
  final fs.Timestamp rentalDateTime;
  final int hours;
  final String status; // 'pending', 'confirmed', 'cancelled'
  final fs.Timestamp createdAt;

  StadiumRental({
    required this.id,
    required this.stadiumId,
    required this.stadiumName,
    this.renterId,
    this.ownerId,
    required this.rentalDateTime,
    required this.hours,
    this.status = 'pending',
    required this.createdAt,
  }) {
    // Validation
    if (stadiumId.trim().isEmpty) {
      throw StadiumValidationException('Stadium ID cannot be empty');
    }
    if (stadiumName.trim().isEmpty) {
      throw StadiumValidationException('Stadium name cannot be empty');
    }
    if (hours <= 0 || hours > 24) {
      throw StadiumValidationException('Hours must be between 1 and 24');
    }
    if (!['pending', 'confirmed', 'cancelled'].contains(status)) {
      throw StadiumValidationException('Invalid status: $status');
    }
    
    final now = DateTime.now();
    final rentalDate = rentalDateTime.toDate();
    if (rentalDate.isBefore(now.subtract(const Duration(hours: 1)))) {
      throw StadiumValidationException('Rental date cannot be in the past');
    }
  }

  // Check if user is renter
  bool isRenter(String? userId) => renterId != null && renterId == userId;

  // Check if user is owner
  bool isOwner(String? userId) => ownerId != null && ownerId == userId;

  // Check if user can modify this rental
  bool canModify(String? userId) => isRenter(userId) || isOwner(userId);

  factory StadiumRental.fromJson(Map<String, dynamic> json) {
    return StadiumRental(
      id: json['id'] ?? '',
      stadiumId: json['stadiumId'] ?? '',
      stadiumName: json['stadiumName'] ?? '',
      renterId: json['renterId'],
      ownerId: json['ownerId'],
      rentalDateTime: json['rentalDateTime'] ?? fs.Timestamp.now(),
      hours: json['hours'] ?? 1,
      status: json['status'] ?? 'pending',
      createdAt: json['createdAt'] ?? fs.Timestamp.now(),
    );
  }

  factory StadiumRental.fromFirestore(Map<String, dynamic> data, String id) {
    return StadiumRental(
      id: id,
      stadiumId: data['stadiumId'] ?? '',
      stadiumName: data['stadiumName'] ?? '',
      renterId: data['renterId'],
      ownerId: data['ownerId'],
      rentalDateTime: data['rentalDateTime'] ?? fs.Timestamp.now(),
      hours: data['hours'] ?? 1,
      status: data['status'] ?? 'pending',
      createdAt: data['createdAt'] ?? fs.Timestamp.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'stadiumId': stadiumId,
      'stadiumName': stadiumName,
      'renterId': renterId,
      'ownerId': ownerId,
      'rentalDateTime': rentalDateTime,
      'hours': hours,
      'status': status,
      'createdAt': createdAt,
    };
  }

  Map<String, dynamic> toFirestore() {
    return {
      'stadiumId': stadiumId,
      'stadiumName': stadiumName,
      'renterId': renterId,
      'ownerId': ownerId,
      'rentalDateTime': rentalDateTime,
      'hours': hours,
      'status': status,
      'createdAt': createdAt,
    };
  }

  DateTime get rentalStartDate => rentalDateTime.toDate();
  DateTime get rentalEndDate => rentalStartDate.add(Duration(hours: hours));
}

