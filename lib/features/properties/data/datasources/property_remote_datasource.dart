import '../../domain/entities/user_entity.dart';
import '../../domain/repositories/auth_repository.dart';
import '../../../../core/errors/failures.dart';
import '../datasources/auth_remote_datasource.dart';
import '../models/user_model.dart';

// This class is the ANSWER to the contract defined in AuthRepository.
// It says "yes, I can provide every method that contract promised,
// using AuthRemoteDatasource underneath."
class AuthRepositoryImpl implements AuthRepository {
  final AuthRemoteDatasource _datasource;

  AuthRepositoryImpl(this._datasource);

  @override
  String? get currentUserId => _datasource.currentUserId;

  @override
  Stream<UserEntity?> get currentUser {
    // asyncExpand lets us switch from "stream of auth changes" to
    // "stream of that specific user's profile data."
    // Every time the logged-in user changes, we automatically start
    // listening to THEIR profile instead of the previous user's.
    return _datasource.authStateChanges.asyncExpand((fbUser) {
      if (fbUser == null) {
        return Stream.value(null);
      }
      return _datasource.userProfileStream(fbUser.uid);
    });
  }

  @override
  Future<UserEntity> login({required String email, required String password}) async {
    final credential = await _datasource.signInWithEmail(email: email, password: password);
    final uid = credential.user!.uid;

    final profile = await _datasource.userProfileStream(uid).first;

    if (profile == null) {
      // Edge case: an Auth account exists but no Firestore profile does.
      // This is its own Failure type now (see fix below).
      throw const ServerFailure(
        'Your account exists but your profile is incomplete. Please contact support.',
      );
    }

    return profile;
  }

  @override
  Future<UserEntity> register({
    required String fullName,
    required String email,
    required String phoneNumber,
    required String password,
    required AccountType accountType,
  }) async {
    // Step 1: create the Firebase Auth account (handles login credentials)
    final credential = await _datasource.createAccount(email: email, password: password);
    final uid = credential.user!.uid;

    // Step 2: create the Firestore profile document (handles app data)
    final newUser = UserModel(
      uid: uid,
      fullName: fullName,
      email: email,
      phoneNumber: phoneNumber,
      accountType: accountType,
      isEmailVerified: false,
      createdAt: DateTime.now(),
    );
    await _datasource.createUserProfile(newUser);

    // Step 3: send verification email (fire-and-forget)
    await _datasource.sendEmailVerification();

    return newUser;
  }

  @override
  Future<void> logout() => _datasource.signOut();

  @override
  Future<void> sendPasswordResetEmail(String email) => _datasource.sendPasswordResetEmail(email);

  @override
  Future<void> sendEmailVerification() => _datasource.sendEmailVerification();
}

// WHAT WAS WRONG BEFORE (explained):
// In a previous version, this was its own class:
//   class AuthFailureProfileMissing extends Exception { const AuthFailureProfileMissing(); }
//
// In recent Dart versions, `Exception` became an "interface class" — a
// special kind of class that Dart does NOT allow you to extend directly
// with `extends`. You can only `implement` it, and even then, plain
// `Exception` has no usable constructor to inherit from a `const` class.
//
// THE FIX: We removed that separate class entirely and instead throw our
// own `ServerFailure` (defined in core/errors/failures.dart), which
// extends OUR `Failure` class — not Dart's built-in `Exception`. This is
// also more consistent: now EVERY error in the app is one of our custom
// Failure types, and the UI only ever needs to handle that one family of
// error types instead of two different systems.
