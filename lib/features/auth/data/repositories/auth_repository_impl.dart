import '../../domain/entities/user_entity.dart';
import '../../domain/repositories/auth_repository.dart';
import '../../../../core/errors/failures.dart';
import '../datasources/auth_remote_datasource.dart';
import '../models/user_model.dart';

class AuthRepositoryImpl implements AuthRepository {
  final AuthRemoteDatasource _datasource;

  AuthRepositoryImpl(this._datasource);

  @override
  String? get currentUserId => _datasource.currentUserId;

  @override
  Stream<UserEntity?> get currentUser {
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
    final credential = await _datasource.createAccount(email: email, password: password);
    final uid = credential.user!.uid;

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
