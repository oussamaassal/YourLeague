import '../entities/stadium_rental.dart';

abstract class RentalRepo {
  // Create rental
  Future<void> createRental(StadiumRental rental);

  // Read rentals
  Future<StadiumRental?> getRental(String rentalId);
  Future<List<StadiumRental>> getAllRentals();
  Future<List<StadiumRental>> getRentalsByStadium(String stadiumId);
  Future<List<StadiumRental>> getRentalsByRenter(String renterId);
  Future<List<StadiumRental>> getRentalsByOwner(String ownerId);
  Future<bool> hasConflict(String stadiumId, DateTime start, DateTime end);
  Stream<List<StadiumRental>> watchRentalsByStadium(String stadiumId);
  Stream<List<StadiumRental>> watchAllRentals();

  // Update rental
  Future<void> updateRental(StadiumRental rental);
  Future<void> updateRentalStatus(String rentalId, String status);

  // Delete rental
  Future<void> deleteRental(String rentalId);
}

