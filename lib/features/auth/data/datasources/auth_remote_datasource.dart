import 'package:firebase_auth/firebase_auth.dart' as fb_auth;
import '../../../../core/constants/firestore_paths.dart';
import '../../../../core/errors/failures.dart';
import '../../../../services/firestore_service.dart';
import '../../domain/entities/user_entity.dart';
import '../models/user_model.dart';

/// WHY THIS FILE EXISTS (and how it differs from the Repository):
/// This class does the ACTUAL Firebase SDK calls - the "lowest level" of
/// the data layer. It knows about `firebase_auth` package types
/// (`fb_auth.User`, `fb_auth.FirebaseAuthException`) directly.
///
/// The Repository (next file) sits ABOVE this and is responsible for:
///   - converting fb_auth exceptions into our app's Failure types
///   - combining Auth + Firestore calls (e.g. "register" needs BOTH an
///     Auth account AND a Firestore profile document)
///
/// Splitting "raw Firebase calls" (datasource) from "combining + error
/// translation" (repository) keeps each class focused on one job. It also
/// means if you ever needed to swap `firebase_auth` for another auth
/// provider, only THIS file changes.
class AuthRemoteDatasource {
  final fb_auth.FirebaseAuth _auth;
  final FirestoreService _firestore;

  AuthRemoteDatasource({
    fb_auth.FirebaseAuth? auth,
    required FirestoreService firestore,
  })  : _auth = auth ?? fb_auth.FirebaseAuth.instance,
        _firestore = firestore;

  /// Stream of raw Firebase Auth user changes (null = logged out).
  /// `authStateChanges()` fires when login/logout happens.
  /// `userChanges()` ALSO fires when the user's email/profile changes within
  /// Firebase Auth itself (e.g. after email verification) - useful here.
  Stream<fb_auth.User?> get authStateChanges => _auth.userChanges();

  String? get currentUserId => _auth.currentUser?.uid;

  /// Fetches a user's Firestore profile document as a real-time stream.
  Stream<UserModel?> userProfileStream(String uid) {
    return _firestore
        .doc(FirestorePaths.users, uid)
        .snapshots()
        .map((snapshot) => snapshot.exists ? UserModel.fromFirestore(snapshot) : null);
  }

  Future<fb_auth.UserCredential> signInWithEmail({
    required String email,
    required String password,
  }) async {
    try {
      return await _auth.signInWithEmailAndPassword(email: email, password: password);
    } on fb_auth.FirebaseAuthException catch (e) {
      // Convert Firebase's cryptic error codes into messages a normal
      // person can understand. This is the "translation" mentioned above -
      // but notice it happens at the EDGE (datasource), close to where the
      // raw Firebase error is thrown, so nothing further up the chain ever
      // sees `FirebaseAuthException`.
      throw AuthFailure(_mapAuthError(e));
    }
  }

  Future<fb_auth.UserCredential> createAccount({
    required String email,
    required String password,
  }) async {
    try {
      return await _auth.createUserWithEmailAndPassword(email: email, password: password);
    } on fb_auth.FirebaseAuthException catch (e) {
      throw AuthFailure(_mapAuthError(e));
    }
  }

  /// Creates the Firestore profile document for a newly-registered user.
  /// This is SEPARATE from creating the Auth account (above) because they
  /// are two different systems: Firebase Auth stores "can this person log
  /// in?" while Firestore stores "what is this person's name/role/etc?"
  Future<void> createUserProfile(UserModel user) async {
    await _firestore.doc(FirestorePaths.users, user.uid).set(user.toMap());
  }

  Future<void> sendEmailVerification() async {
    await _auth.currentUser?.sendEmailVerification();
  }

  Future<void> sendPasswordResetEmail(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
    } on fb_auth.FirebaseAuthException catch (e) {
      throw AuthFailure(_mapAuthError(e));
    }
  }

  Future<void> signOut() async {
    await _auth.signOut();
  }

  /// Translates Firebase's internal error codes into friendly messages.
  ///
  /// WHY HARDCODE THESE STRINGS HERE INSTEAD OF SHOWING e.message DIRECTLY?
  /// Firebase's raw messages are written for DEVELOPERS, e.g.
  /// "The password is invalid or the user does not have a password."
  /// That's confusing and slightly alarming to an end user. Mapping known
  /// codes to friendly text is a small thing that makes the whole app feel
  /// more polished and trustworthy.
  String _mapAuthError(fb_auth.FirebaseAuthException e) {
    switch (e.code) {
      case 'user-not-found':
      case 'wrong-password':
      case 'invalid-credential':
        return 'Incorrect email or password.';
      case 'email-already-in-use':
        return 'An account with this email already exists.';
      case 'weak-password':
        return 'Please choose a stronger password (at least 8 characters).';
      case 'invalid-email':
        return 'Please enter a valid email address.';
      case 'user-disabled':
        return 'This account has been suspended. Contact support for help.';
      case 'too-many-requests':
        return 'Too many attempts. Please wait a moment and try again.';
      case 'network-request-failed':
        return 'No internet connection. Please check your network.';
      default:
        return 'Something went wrong. Please try again.';
    }
  }
}
