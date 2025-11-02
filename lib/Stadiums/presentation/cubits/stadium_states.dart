import '../../domain/entities/stadium.dart';

abstract class StadiumState {}

class StadiumInitial extends StadiumState {}

class StadiumLoading extends StadiumState {}

class StadiumLoaded extends StadiumState {
  final Stadium stadium;
  StadiumLoaded(this.stadium);
}

class StadiumsLoaded extends StadiumState {
  final List<Stadium> stadiums;
  StadiumsLoaded(this.stadiums);
}

class StadiumOperationSuccess extends StadiumState {
  final String message;
  StadiumOperationSuccess(this.message);
}

class StadiumError extends StadiumState {
  final String message;
  StadiumError(this.message);
}

