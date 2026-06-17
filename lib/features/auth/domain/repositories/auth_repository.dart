import '../entities/user_entity.dart';

// This is an ABSTRACT class — it's a contract/promise, not actual code.
// It says: "whoever implements me MUST provide these exact methods."
//
// Think of it like a job description. The domain layer DEFINES the job.
// The data layer (AuthRepositoryImpl) is the person WHO DOES the job.
//
// WHY SPLIT IT LIKE THIS?
// Our screens will depend on THIS abstract type, not on the Firebase
// implementation. So if we test our screens, we can swap in a fake
// "FakeAuthRepository" that returns made-up data instantly.
abstract class AuthRepository {
  // A stream is a real-time "river" of data. Every time login/logout
  // happens, this river delivers the new user (or null if logged out).
  // Screens that watch this automatically update themselves.
  Stream<UserEntity?> get currentUser;

  // Returns just the user's ID string (or null if logged out).
  // Many features only need the ID, not the full user object.
  String? get currentUserId;

  Future<UserEntity> login({
    required String email,
    required String password,
  });

  Future<UserEntity> register({
    required String fullName,
    required String email,
    required String phoneNumber,
    required String password,
    required AccountType accountType,
  });

  Future<void> logout();

  Future<void> sendPasswordResetEmail(String email);

  Future<void> sendEmailVerification();
}
