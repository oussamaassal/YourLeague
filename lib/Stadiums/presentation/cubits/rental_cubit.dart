import 'package:cloud_firestore/cloud_firestore.dart' as fs;
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/entities/stadium_rental.dart';
import '../../domain/repos/rental_repo.dart';
import 'rental_states.dart';

class RentalCubit extends Cubit<RentalState> {
  final RentalRepo rentalRepo;

  RentalCubit({required this.rentalRepo}) : super(RentalInitial());

  // Create rental
  Future<void> createRental({
    required String stadiumId,
    required String stadiumName,
    required DateTime rentalDateTime,
    required int hours,
    String? renterId,
    String? ownerId,
  }) async {
    try {
      emit(RentalLoading());

      // Check for conflicts first
      final endDateTime = rentalDateTime.add(Duration(hours: hours));
      final hasConflict = await rentalRepo.hasConflict(
        stadiumId,
        rentalDateTime,
        endDateTime,
      );

      if (hasConflict) {
        emit(RentalConflictDetected('This time slot is already booked'));
        return;
      }

      final rental = StadiumRental(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        stadiumId: stadiumId,
        stadiumName: stadiumName,
        renterId: renterId,
        ownerId: ownerId,
        rentalDateTime: fs.Timestamp.fromDate(rentalDateTime),
        hours: hours,
        status: 'pending',
        createdAt: fs.Timestamp.now(),
      );

      await rentalRepo.createRental(rental);
      emit(RentalOperationSuccess('Rental created successfully'));
    } catch (e) {
      emit(RentalError('Failed to create rental: $e'));
    }
  }

  // Get single rental
  Future<void> getRental(String rentalId) async {
    try {
      emit(RentalLoading());
      final rental = await rentalRepo.getRental(rentalId);
      if (rental != null) {
        emit(RentalLoaded(rental));
      } else {
        emit(RentalError('Rental not found'));
      }
    } catch (e) {
      emit(RentalError('Failed to get rental: $e'));
    }
  }

  // Get all rentals
  Future<void> getAllRentals() async {
    try {
      emit(RentalLoading());
      final rentals = await rentalRepo.getAllRentals();
      emit(RentalsLoaded(rentals));
    } catch (e) {
      emit(RentalError('Failed to get rentals: $e'));
    }
  }

  // Get rentals by stadium
  Future<void> getRentalsByStadium(String stadiumId) async {
    try {
      emit(RentalLoading());
      final rentals = await rentalRepo.getRentalsByStadium(stadiumId);
      emit(RentalsLoaded(rentals));
    } catch (e) {
      emit(RentalError('Failed to get rentals: $e'));
    }
  }

  // Get rentals by renter
  Future<void> getRentalsByRenter(String renterId) async {
    try {
      emit(RentalLoading());
      final rentals = await rentalRepo.getRentalsByRenter(renterId);
      emit(RentalsLoaded(rentals));
    } catch (e) {
      emit(RentalError('Failed to get rentals: $e'));
    }
  }

  // Get rentals by owner
  Future<void> getRentalsByOwner(String ownerId) async {
    try {
      emit(RentalLoading());
      final rentals = await rentalRepo.getRentalsByOwner(ownerId);
      emit(RentalsLoaded(rentals));
    } catch (e) {
      emit(RentalError('Failed to get rentals: $e'));
    }
  }

  // Check for conflicts
  Future<bool> checkConflict(String stadiumId, DateTime start, DateTime end) async {
    try {
      return await rentalRepo.hasConflict(stadiumId, start, end);
    } catch (e) {
      emit(RentalError('Failed to check conflict: $e'));
      return true; // Assume conflict if error
    }
  }

  // Watch rentals by stadium (stream)
  Stream<List<StadiumRental>> watchRentalsByStadium(String stadiumId) {
    return rentalRepo.watchRentalsByStadium(stadiumId);
  }

  // Watch all rentals (stream)
  Stream<List<StadiumRental>> watchAllRentals() {
    return rentalRepo.watchAllRentals();
  }

  // Update rental
  Future<void> updateRental(StadiumRental rental) async {
    try {
      emit(RentalLoading());
      await rentalRepo.updateRental(rental);
      emit(RentalOperationSuccess('Rental updated successfully'));
    } catch (e) {
      emit(RentalError('Failed to update rental: $e'));
    }
  }

  // Update rental status
  Future<void> updateRentalStatus(String rentalId, String status) async {
    try {
      emit(RentalLoading());
      await rentalRepo.updateRentalStatus(rentalId, status);
      emit(RentalOperationSuccess('Rental status updated successfully'));
    } catch (e) {
      emit(RentalError('Failed to update rental status: $e'));
    }
  }

  // Delete rental
  Future<void> deleteRental(String rentalId) async {
    try {
      emit(RentalLoading());
      await rentalRepo.deleteRental(rentalId);
      emit(RentalOperationSuccess('Rental deleted successfully'));
    } catch (e) {
      emit(RentalError('Failed to delete rental: $e'));
    }
  }
}

