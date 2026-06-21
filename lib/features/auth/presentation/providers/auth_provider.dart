import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/errors/failures.dart';
import '../../../../services/firestore_service.dart';
import '../../data/datasources/auth_remote_datasource.dart';
import '../../data/repositories/auth_repository_impl.dart';
import '../../domain/entities/user_entity.dart';
import '../../domain/repositories/auth_repository.dart';
import '../../domain/usecases/login_usecase.dart';
import '../../domain/usecases/register_usecase.dart';

/// ============================================================
/// THIS FILE IS THE "WIRING DIAGRAM" FOR THE AUTH FEATURE.
/// ============================================================
///
/// Every other file we wrote (entities, repositories, usecases, datasources,
/// models) is just a CLASS DEFINITION - a blueprint. Nothing actually runs
/// until something CREATES INSTANCES of these classes and connects them
/// together. That's what this file does, using Riverpod `Provider`s.
///
/// Read this file top to bottom - it tells the story of how a button tap on
/// the Login screen eventually becomes a Firestore read.

/// 1. The lowest-level service - talks to Firestore directly.
final firestoreServiceProvider = Provider<FirestoreService>((ref) {
  return FirestoreService();
});

/// 2. The datasource - talks to Firebase Auth + uses the Firestore service.
/// `ref.watch(firestoreServiceProvider)` means: "give me the
/// FirestoreService instance from provider #1 above."
final authRemoteDatasourceProvider = Provider<AuthRemoteDatasource>((ref) {
  return AuthRemoteDatasource(firestore: ref.watch(firestoreServiceProvider));
});

/// 3. The repository - implements the abstract AuthRepository contract.
///
/// NOTICE THE RETURN TYPE: `Provider<AuthRepository>` (the ABSTRACT type),
/// not `Provider<AuthRepositoryImpl>`. Everything ABOVE this line in the
/// app only ever asks for "an AuthRepository" - it doesn't know or care
/// that the actual object is an AuthRepositoryImpl using Firebase. This is
/// the line where Clean Architecture's "dependency inversion" actually
/// happens in code: concrete implementation details flow INTO this
/// provider, but only the ABSTRACT contract flows OUT.
final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepositoryImpl(ref.watch(authRemoteDatasourceProvider));
});

/// 4. Use cases - one provider per use case, each depending on the
/// repository above.
final loginUsecaseProvider = Provider<LoginUsecase>((ref) {
  return LoginUsecase(ref.watch(authRepositoryProvider));
});

final registerUsecaseProvider = Provider<RegisterUsecase>((ref) {
  return RegisterUsecase(ref.watch(authRepositoryProvider));
});

/// 5. THE MAIN AUTH STATE STREAM.
///
/// This is what the rest of the app actually "watches" to know: "is anyone
/// logged in, and if so, who are they (including their role)?"
///
/// WHY StreamProvider: Because `authRepository.currentUser` is a Stream
/// (defined back in the AuthRepository contract). StreamProvider
/// automatically handles the loading/data/error states for us. Any widget
/// that does `ref.watch(currentUserProvider)` will automatically rebuild
/// the INSTANT the user logs in, logs out, or their profile data changes -
/// with zero manual listener code in the widget.
final currentUserProvider = StreamProvider<UserEntity?>((ref) {
  return ref.watch(authRepositoryProvider).currentUser;
});

/// 6. A convenience provider: just the user's ID (or null), derived from #5.
///
/// WHY HAVE THIS SEPARATELY? Many other providers (favorites, bookings,
/// chat) only need the user's ID, not their full profile. By depending on
/// THIS provider instead of `currentUserProvider`, those other providers
/// only rebuild when the ID actually changes (login/logout) - not every
/// time some unrelated field on the profile (like profilePhotoUrl) updates.
/// This is a small performance optimization that becomes meaningful once
/// many providers depend on "who is logged in."
final currentUserIdProvider = Provider<String?>((ref) {
  return ref.watch(authRepositoryProvider).currentUserId;
});

/// 7. THE AUTH ACTIONS NOTIFIER - handles login/register/logout button presses.
///
/// WHY AsyncNotifier AND NOT JUST CALLING THE USECASE DIRECTLY FROM THE UI?
/// Because login/register are ASYNC operations that can be loading, succeed,
/// or fail - and the UI needs to REACT to all three (show a spinner, show
/// an error message, navigate away on success). AsyncNotifier gives us
/// `state` that is automatically one of AsyncLoading / AsyncData / AsyncError,
/// and the UI can use `.when(...)` to handle all three cases declaratively.
class AuthActionsNotifier extends AsyncNotifier<void> {
  @override
  Future<void> build() async {
    // Nothing to do on initial build - this notifier doesn't hold ongoing
    // state, it just performs actions. `AsyncNotifier<void>` is a
    // lightweight way to get loading/error tracking for "fire an action"
    // use cases like this.
  }

  Future<void> login({required String email, required String password}) async {
    // Setting state to loading causes any UI watching this provider to show
    // a spinner (via AsyncValue.loading()).
    state = const AsyncLoading();

    // `AsyncValue.guard` runs the function and automatically wraps the
    // result: if it succeeds, state becomes AsyncData; if it throws, state
    // becomes AsyncError with that exception attached. This is the
    // recommended Riverpod pattern - it means we don't need a manual
        // try/catch here.
    state = await AsyncValue.guard(() async {
      await ref.read(loginUsecaseProvider).call(email: email, password: password);
      // We don't need to return/store anything - currentUserProvider
      // (provider #5) will automatically update once Firebase Auth's
      // state changes, which is what the UI actually watches for
      // navigation.
    });
  }

  Future<void> register({
    required String fullName,
    required String email,
    required String phoneNumber,
    required String password,
    required String confirmPassword,
    required AccountType accountType,
  }) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      await ref.read(registerUsecaseProvider).call(
            fullName: fullName,
            email: email,
            phoneNumber: phoneNumber,
            password: password,
            confirmPassword: confirmPassword,
            accountType: accountType,
          );
    });
  }

  Future<void> logout() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() => ref.read(authRepositoryProvider).logout());
  }

  Future<void> sendPasswordReset(String email) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => ref.read(authRepositoryProvider).sendPasswordResetEmail(email.trim().toLowerCase()),
    );
  }
}

final authActionsProvider = AsyncNotifierProvider<AuthActionsNotifier, void>(() {
  return AuthActionsNotifier();
});

String failureMessage(Object error) {
  if (error is Failure) return error.message;
  return error.toString();
}
