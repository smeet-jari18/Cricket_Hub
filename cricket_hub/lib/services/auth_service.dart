import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../core/app_constants.dart';
import '../models/app_user.dart';

/// All Firebase Authentication calls live here.
/// Screens never talk to FirebaseAuth directly (clean separation).
class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  /// Streams the logged-in user (null = logged out).
  /// Screens listen to this to decide which page to show.
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  User? get currentUser => _auth.currentUser;

  // ---------- PHONE (OTP) LOGIN ----------

  /// Step 1: send the OTP to this phone number.
  /// [onCodeSent] gives the verificationId to the OTP screen.
  Future<void> sendOtp({
    required String phoneNumber,
    required void Function(String verificationId) onCodeSent,
    required void Function(String message) onError,
  }) async {
    await _auth.verifyPhoneNumber(
      phoneNumber: phoneNumber.trim(),
      timeout: const Duration(seconds: 60),

      // Android auto-reads the SMS sometimes — log the user in directly.
      verificationCompleted: (PhoneAuthCredential credential) async {
        await _auth.signInWithCredential(credential);
      },

      verificationFailed: (FirebaseAuthException e) {
        onError(e.message ?? 'Phone verification failed. Try again.');
      },

      codeSent: (String verificationId, int? resendToken) {
        onCodeSent(verificationId);
      },

      codeAutoRetrievalTimeout: (String verificationId) {},
    );
  }

  /// Step 2: check the 6-digit code the user typed.
  Future<void> verifyOtp({
    required String verificationId,
    required String smsCode,
  }) async {
    final credential = PhoneAuthProvider.credential(
      verificationId: verificationId,
      smsCode: smsCode.trim(),
    );
    await _auth.signInWithCredential(credential);
    await _createUserDocumentIfMissing();
  }

  // ---------- GOOGLE LOGIN ----------

  Future<void> signInWithGoogle() async {
    final GoogleSignInAccount? googleUser = await GoogleSignIn().signIn();
    if (googleUser == null) return; // user closed the popup

    final GoogleSignInAuthentication googleAuth =
        googleUser.authentication;

    final credential = GoogleAuthProvider.credential(
      accessToken: googleAuth.accessToken,
      idToken: googleAuth.idToken,
    );

    await _auth.signInWithCredential(credential);
    await _createUserDocumentIfMissing();
  }

  // ---------- USER DOCUMENT ----------

  /// First time login -> create an empty `users/{uid}` document.
  /// The Profile Setup screen then fills in the name and role.
  Future<void> _createUserDocumentIfMissing() async {
    final user = _auth.currentUser;
    if (user == null) return;

    final doc = await _db.collection(AppConstants.usersCol).doc(user.uid).get();
    if (!doc.exists) {
      await doc.reference.set({
        'phone_number': user.phoneNumber ?? '',
        'display_name': user.displayName ?? '',
        'avatar_url': user.photoURL ?? '',
        'role': 'player',
        'batting_style': '',
        'bowling_style': '',
        'created_at': FieldValue.serverTimestamp(),
      });
    }
  }

  /// Called by Profile Setup screen after the user enters their details.
  Future<void> completeProfile({
    required String name,
    required String battingStyle,
    required String bowlingStyle,
  }) async {
    final user = _auth.currentUser;
    if (user == null) return;

    await _db.collection(AppConstants.usersCol).doc(user.uid).update({
      'display_name': name.trim(),
      'batting_style': battingStyle,
      'bowling_style': bowlingStyle,
    });
  }

  /// Fetch a user profile as a stream (live updates).
  Stream<AppUser?> userDocStream(String uid) {
    return _db.collection(AppConstants.usersCol).doc(uid).snapshots().map(
          (snap) => snap.exists ? AppUser.fromMap(uid, snap.data()!) : null,
        );
  }

  Future<void> signOut() async {
    await GoogleSignIn().signOut().catchError((_) {});
    await _auth.signOut();
  }
}
