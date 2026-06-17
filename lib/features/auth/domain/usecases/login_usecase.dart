import '../entities/user_entity.dart';
import '../repositories/auth_repository.dart';

// A use case wraps ONE action the user can take.
// This one handles "log in."
//
// Even though it looks simple now, the use case is where you'd add
// business rules — things like "normalize the email before sending it."
class LoginUsecase {
  final AuthRepository _repository;

  LoginUsecase(this._repository);

  // The `call` method means you can use this class like a function:
  // `await loginUsecase(email: ..., password: ...)`
  Future<UserEntity> call({
    required String email,
    required String password,
  }) async {
    // Clean up the email before sending to Firebase.
    // "John@GMAIL.COM " becomes "john@gmail.com" — avoids confusing errors.
    final normalizedEmail = email.trim().toLowerCase();

    return _repository.login(email: normalizedEmail, password: password);
  }
}
