import 'package:cloud_firestore/cloud_firestore.dart' as fs;
import 'package:firebase_auth/firebase_auth.dart';
import '../domain/entities/stadium_rental.dart';
import '../domain/repos/rental_repo.dart';

class FirebaseRentalRepo implements RentalRepo {
  final fs.FirebaseFirestore _firestore = fs.FirebaseFirestore.instance;
  final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;

  @override
  Future<void> createRental(StadiumRental rental) async {
    try {
      final currentUser = _firebaseAuth.currentUser;
      final rentalData = rental.toFirestore();
      
      // Add renterId if available
      if (currentUser != null && rentalData['renterId'] == null) {
        rentalData['renterId'] = currentUser.uid;
      }

      await _firestore.collection('stadium_rentals').doc(rental.id).set(rentalData);
    } catch (e) {
      throw Exception('Failed to create rental: $e');
    }
  }

  @override
  Future<StadiumRental?> getRental(String rentalId) async {
    try {
      final doc = await _firestore.collection('stadium_rentals').doc(rentalId).get();
      if (doc.exists) {
        return StadiumRental.fromFirestore(doc.data()!, doc.id);
      }
      return null;
    } catch (e) {
      throw Exception('Failed to get rental: $e');
    }
  }

  @override
  Future<List<StadiumRental>> getAllRentals() async {
    try {
      final snapshot = await _firestore
          .collection('stadium_rentals')
          .orderBy('createdAt', descending: true)
          .get();
      return snapshot.docs
          .map((doc) => StadiumRental.fromFirestore(doc.data(), doc.id))
          .toList();
    } catch (e) {
      throw Exception('Failed to get rentals: $e');
    }
  }

  @override
  Future<List<StadiumRental>> getRentalsByStadium(String stadiumId) async {
    try {
      final snapshot = await _firestore
          .collection('stadium_rentals')
          .where('stadiumId', isEqualTo: stadiumId)
          .get();
      // Sort in memory to avoid requiring composite index
      final rentals = snapshot.docs
          .map((doc) => StadiumRental.fromFirestore(doc.data(), doc.id))
          .toList();
      rentals.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return rentals;
    } catch (e) {
      throw Exception('Failed to get rentals by stadium: $e');
    }
  }

  @override
  Future<List<StadiumRental>> getRentalsByRenter(String renterId) async {
    try {
      final snapshot = await _firestore
          .collection('stadium_rentals')
          .where('renterId', isEqualTo: renterId)
          .get();
      // Sort in memory to avoid requiring composite index
      final rentals = snapshot.docs
          .map((doc) => StadiumRental.fromFirestore(doc.data(), doc.id))
          .toList();
      rentals.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return rentals;
    } catch (e) {
      throw Exception('Failed to get rentals by renter: $e');
    }
  }

  @override
  Future<List<StadiumRental>> getRentalsByOwner(String ownerId) async {
    try {
      final snapshot = await _firestore
          .collection('stadium_rentals')
          .where('ownerId', isEqualTo: ownerId)
          .get();
      // Sort in memory to avoid requiring composite index
      final rentals = snapshot.docs
          .map((doc) => StadiumRental.fromFirestore(doc.data(), doc.id))
          .toList();
      rentals.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return rentals;
    } catch (e) {
      throw Exception('Failed to get rentals by owner: $e');
    }
  }

  @override
  Future<bool> hasConflict(String stadiumId, DateTime start, DateTime end) async {
    try {
      final snapshot = await _firestore
          .collection('stadium_rentals')
          .where('stadiumId', isEqualTo: stadiumId)
          .where('status', whereIn: ['pending', 'confirmed'])
          .get();

      for (final doc in snapshot.docs) {
        final rental = StadiumRental.fromFirestore(doc.data(), doc.id);
        final existingStart = rental.rentalStartDate;
        final existingEnd = rental.rentalEndDate;
        
        // Check for overlap
        final overlap = start.isBefore(existingEnd) && end.isAfter(existingStart);
        if (overlap) return true;
      }
      return false;
    } catch (e) {
      throw Exception('Failed to check conflict: $e');
    }
  }

  @override
  Stream<List<StadiumRental>> watchRentalsByStadium(String stadiumId) {
    try {
      return _firestore
          .collection('stadium_rentals')
          .where('stadiumId', isEqualTo: stadiumId)
          .snapshots()
          .map((snapshot) {
            final rentals = snapshot.docs
                .map((doc) => StadiumRental.fromFirestore(doc.data(), doc.id))
                .toList();
            // Sort in memory to avoid requiring composite index
            rentals.sort((a, b) => b.createdAt.compareTo(a.createdAt));
            return rentals;
          });
    } catch (e) {
      throw Exception('Failed to watch rentals by stadium: $e');
    }
  }

  @override
  Stream<List<StadiumRental>> watchAllRentals() {
    try {
      return _firestore
          .collection('stadium_rentals')
          .orderBy('createdAt', descending: true)
          .snapshots()
          .map((snapshot) => snapshot.docs
              .map((doc) => StadiumRental.fromFirestore(doc.data(), doc.id))
              .toList());
    } catch (e) {
      throw Exception('Failed to watch rentals: $e');
    }
  }

  @override
  Future<void> updateRental(StadiumRental rental) async {
    try {
      await _firestore
          .collection('stadium_rentals')
          .doc(rental.id)
          .update(rental.toFirestore());
    } catch (e) {
      throw Exception('Failed to update rental: $e');
    }
  }

  @override
  Future<void> updateRentalStatus(String rentalId, String status) async {
    try {
      await _firestore
          .collection('stadium_rentals')
          .doc(rentalId)
          .update({'status': status});
    } catch (e) {
      throw Exception('Failed to update rental status: $e');
    }
  }

  @override
  Future<void> deleteRental(String rentalId) async {
    try {
      await _firestore.collection('stadium_rentals').doc(rentalId).delete();
    } catch (e) {
      throw Exception('Failed to delete rental: $e');
    }
  }
}

