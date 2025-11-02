import '../../domain/entities/stadium_rental.dart';

abstract class RentalState {}

class RentalInitial extends RentalState {}

class RentalLoading extends RentalState {}

class RentalLoaded extends RentalState {
  final StadiumRental rental;
  RentalLoaded(this.rental);
}

class RentalsLoaded extends RentalState {
  final List<StadiumRental> rentals;
  RentalsLoaded(this.rentals);
}

class RentalConflictDetected extends RentalState {
  final String message;
  RentalConflictDetected(this.message);
}

class RentalOperationSuccess extends RentalState {
  final String message;
  RentalOperationSuccess(this.message);
}

class RentalError extends RentalState {
  final String message;
  RentalError(this.message);
}

