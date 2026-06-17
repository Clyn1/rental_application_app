/// WHY THIS FILE EXISTS:
/// When something goes wrong (no internet, Firebase rejects a write, a
/// document doesn't exist), we don't want to show the user a raw technical
/// error like "FirebaseException: PERMISSION_DENIED [cloud_firestore/permission-denied]".
///
/// Instead, every error gets converted into one of these simple "Failure"
/// types with a human-readable message. The UI layer only ever needs to
/// know about THESE classes - it never needs to know what Firebase's
/// internal exceptions look like. This is what makes the domain/presentation
/// layers independent of Firebase (Clean Architecture in action).
library;

abstract class Failure {
  final String message;
  const Failure(this.message);
}

class ServerFailure extends Failure {
  const ServerFailure([super.message = 'Something went wrong. Please try again.']);
}

class NetworkFailure extends Failure {
  const NetworkFailure([super.message = 'No internet connection. Please check your network.']);
}

class AuthFailure extends Failure {
  const AuthFailure(super.message);
}

class NotFoundFailure extends Failure {
  const NotFoundFailure([super.message = 'The requested item could not be found.']);
}

class ValidationFailure extends Failure {
  const ValidationFailure(super.message);
}

class PermissionFailure extends Failure {
  const PermissionFailure([super.message = "You don't have permission to do that."]);
}
