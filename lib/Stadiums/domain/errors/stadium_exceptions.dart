/// Custom exceptions for Stadium feature

class StadiumException implements Exception {
  final String message;
  StadiumException(this.message);

  @override
  String toString() => message;
}

class StadiumValidationException extends StadiumException {
  StadiumValidationException(super.message);
}

class StadiumPermissionException extends StadiumException {
  StadiumPermissionException(super.message);
}

class StadiumNotFoundException extends StadiumException {
  StadiumNotFoundException(super.message);
}

class StadiumConflictException extends StadiumException {
  StadiumConflictException(super.message);
}

class StadiumImageException extends StadiumException {
  StadiumImageException(super.message);
}

