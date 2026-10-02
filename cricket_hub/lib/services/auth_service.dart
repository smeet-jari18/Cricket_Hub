import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:google_sign_in/google_sign_in.dart';

import '../core/app_constants.dart';
import '../models/app_user.dart';

/// All Firebase Authentication calls live here.
/// Screens never talk to FirebaseAuth directly (clean separation).
class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn.instance;
  Future<void>? _googleSignInInitialization;

  /// Streams the logged-in user (null = logged out).
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  User? get currentUser => _auth.currentUser;

  Future<void> _ensureGoogleSignInInitialized() {
    return _googleSignInInitialization ??=
        _googleSignIn.initialize();
  }

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

      // Android can verify automatically; ensure the profile is created too.
      verificationCompleted: (PhoneAuthCredential credential) async {
        await _auth.signInWithCredential(credential);
        await _createUserDocumentIfMissing();
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
    if (kIsWeb) {
      // google_sign_in v7 requires its rendered button on web. Firebase Auth's
      // popup is the supported web flow for this app's custom button.
      await _auth.signInWithPopup(GoogleAuthProvider());
    } else {
      await _ensureGoogleSignInInitialized();
      final googleUser = await _googleSignIn.authenticate();
      final idToken = googleUser.authentication.idToken;
      if (idToken == null) {
        throw StateError('Google Sign-In did not return an ID token.');
      }

      final credential = GoogleAuthProvider.credential(idToken: idToken);
      await _auth.signInWithCredential(credential);
    }

    await _createUserDocumentIfMissing();
  }

  // ---------- USER DOCUMENT ----------

  String _playerNameKey(String name) =>
      name.trim().replaceAll(RegExp(r'\s+'), ' ').toLowerCase();

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
        'player_name_key': _playerNameKey(user.displayName ?? ''),
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
      'player_name_key': _playerNameKey(name),
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
    if (!kIsWeb && _googleSignInInitialization != null) {
      try {
        await _googleSignIn.signOut();
      } catch (_) {
        // Firebase Auth sign-out below is authoritative for the app session.
      }
    }
    await _auth.signOut();
  }
}
