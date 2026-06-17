import '../entities/user_entity.dart';
import '../repositories/auth_repository.dart';
import '../../../../core/errors/failures.dart';

// This use case handles "register a new account."
// It does MORE than login because there are more rules to check.
class RegisterUsecase {
  final AuthRepository _repository;

  RegisterUsecase(this._repository);

  Future<UserEntity> call({
    required String fullName,
    required String email,
    required String phoneNumber,
    required String password,
    required String confirmPassword,
    required AccountType accountType,
  }) async {
    // Check each rule BEFORE talking to Firebase.
    // This gives instant feedback and saves a network round-trip.
    if (fullName.trim().isEmpty) {
      throw const ValidationFailure('Please enter your full name.');
    }

    if (password != confirmPassword) {
      throw const ValidationFailure('Passwords do not match.');
    }

    if (password.length < 8) {
      throw const ValidationFailure('Password must be at least 8 characters.');
    }

    final phoneRegex = RegExp(r'^\+\d{9,15}$');
    if (!phoneRegex.hasMatch(phoneNumber.trim())) {
      throw const ValidationFailure(
        'Enter a valid phone number with country code. Example: +254712345678',
      );
    }

    return _repository.register(
      fullName: fullName.trim(),
      email: email.trim().toLowerCase(),
      phoneNumber: phoneNumber.trim(),
      password: password,
      accountType: accountType,
    );
  }
}